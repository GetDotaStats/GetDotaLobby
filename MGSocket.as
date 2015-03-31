package {
	import flash.display.MovieClip;

	//import some stuff from the valve lib
	import ValveLib.Globals;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.net.LocalConnection;
	import com.adobe.serialization.json.JSONEncoder;
	import com.adobe.serialization.json.JSONDecoder;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import com.adobe.crypto.SHA256;
	
	public class MGSocket extends EventDispatcher{
		public static const PING:uint = 0;
		public static const PING_NOCLOSE:uint = 1;
		public static const SYSTEM_JSON:uint = 2;
		public static const SYSTEM_BINARY:uint = 3;
		public static const GAME_JSON:uint = 4;
		public static const GAME_BINARY:uint = 5;
		public static const BIG_JSON:uint = 0xFE00;
		public static const BIG_BINARY:uint = 0xFF00;
		
		public static const ROLE_USER:int = 0;
		public static const ROLE_MODERATOR:int = 2;
		public static const ROLE_OWNER:int = 3;
		public static const ROLE_ADMIN:int = 4;
		
		public var socket:Socket;
		public var socketReady:Boolean = false;
		public var socketInit:Boolean = false;
		private var pingTimer:Timer;
		private var id:int = -1;
		private var userName:String = "";
		private var authToken:String = null;
		
		public var curObj:Object = null;
		private var sendQueue:Array = new Array();
		private var curBytes:ByteArray = new ByteArray();
		private var curType:uint = 0;
		private var curLen:uint = 0;
		private var newPacket:Boolean = true;
		private var remaining:int = 4;
		
		private var curPing:Number = -1;
		private var pingSendTime:Number = 0;
		private var nonceStr:String = null;
		
		private var lastPacket:Number;
		
		
		public function MGSocket() : void {
			trace("[MGSocket] MGSocket Constructed!");
			socket = new Socket();
		}
		
		public function connect(ip:String, port:int, id:int, userName:String, authToken:String = null){
			trace("[MGSocket] Connecting to " + ip + ":" + port);
			this.id = id;
			this.userName = userName;
			this.authToken = authToken;
			socket.addEventListener(Event.CONNECT, socketConnect);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, dataRead);
			socket.connect(ip, port);
			
			lastPacket = new Date().time;
		}
		
		public function close(){
			socket.removeEventListener(Event.CONNECT, socketConnect);
			socket.removeEventListener(ProgressEvent.SOCKET_DATA, dataRead);
			try{
				socket.close();
			}catch(e:Error){
				trace(e);
			}
			
			socketReady = false;
			
			if (pingTimer != null){
				pingTimer.stop();
				pingTimer.removeEventListener(TimerEvent.TIMER, timerPing);
				pingTimer = null;
			}
			
		}
		
		private function socketConnect(e:Event){
			trace("[MGSocket] CONNECTED");
			socketReady = true;
			socket.removeEventListener(Event.CONNECT, socketConnect);
			
			writeJSON({type:"connect", userID:id, userName:userName}, SYSTEM_JSON);
			write(new ByteArray(), PING_NOCLOSE);
			
			pingTimer = new Timer(20000,0);
			pingTimer.addEventListener(TimerEvent.TIMER, timerPing);
			pingTimer.start();
			
			dispatchEvent(e);
		}
		
		private function timerPing(e:TimerEvent){
			if (socketReady){
				var now = new Date().time;
				
				if (now - lastPacket <= 40000)
					write(new ByteArray(), PING_NOCLOSE);
				else{
					dispatchEvent(new MGEvent(MGEvent.CLOSED, {type:"close", error:"Connection not responding.  The server may be down or unreachable currently."}, SYSTEM_JSON));
					pingTimer.stop();
					pingTimer.removeEventListener(TimerEvent.TIMER, timerPing);
					pingTimer = null;
				}
			}
			else if (pingTimer != null){
				pingTimer.stop();
				pingTimer.removeEventListener(TimerEvent.TIMER, timerPing);
				pingTimer = null;
			}
		}
		
		public function getPing() : Number{
			return curPing;
		}
		
		private function dataRead(e:Event) {
			var pos:uint = 0;
			var data:ByteArray = new ByteArray();
			socket.readBytes(data, 0, data.bytesAvailable);
			var left:uint = data.length;
			
			//trace("Data Read: " + left);
			
			while (pos != data.length){
				//trace("pos: " + pos + " -- " + data.length);
				//trace("remaining: " + remaining + " -- " + left);
				if (newPacket){
					//trace("header is not done");
					// header is not done
					if (left < remaining){
						// not enough for header
						curBytes.writeBytes(data, pos, data.length - pos);
						remaining -= data.length;
						return;
					}
					
					curBytes.writeBytes(data, pos, remaining);
					pos += remaining;
					left -= remaining;
					
					curBytes.position = 0;
					var header:uint = curBytes.readUnsignedInt();
					//trace("header: 0x" + header.toString(16));
					
					if (header >= 0xFE000000){
						curType = (header & 0xFF000000) >>> 16;
				    	curLen = header & 0x00FFFFFF;
					}
					else{
  				    	curType = (header & 0xFFFF0000) >>> 16;
				    	curLen = header & 0x0000FFFF;
					}
					
					curBytes = new ByteArray();
					remaining = curLen;
					newPacket = false;
					
					if (remaining == 0){
						// packet is done
						remaining = 4;
						
						// emit
						messageReceived(curType, curLen, curBytes);
						
						curLen = 0;
						curType = 0;
						curBytes = new ByteArray();
						newPacket = true;
					}
				}
				else{
					if (left >= remaining){
						// packet is done
						curBytes.writeBytes(data, pos, remaining);
						pos += remaining;
						left -= remaining;
						remaining = 4;
						
						// emit
						curBytes.position = 0;
						messageReceived(curType, curLen, curBytes);
						
						newPacket = true;
						curLen = 0;
						curType = 0;
						curBytes = new ByteArray();
					}
					else{
						curBytes.writeBytes(data, pos, left);
						remaining -= left;
						pos += left;
					}
				}
			}
		}
		
		private function messageReceived(type:uint, len:uint, data:ByteArray){
			var json:String;
			var obj:Object;
			lastPacket = new Date().time;
			
			switch(type){
				case PING:
					curPing = new Date().time - pingSendTime;
					trace("[MGSocket] PING: " + curPing);
					return;
					break;
				case PING_NOCLOSE:
					curPing = new Date().time - pingSendTime;
					trace("[MGSocket] PING_NOCLOSE: " + curPing);
					return;
					break;
				
				case SYSTEM_JSON:
					trace("[MGSocket] SYSTEM_JSON");
					json = data.readUTFBytes(data.length);
					trace("[MGSocket] " + json);
					obj = new JSONDecoder(json, true).getValue();
					
					if (obj.hasOwnProperty("type")){
						switch(obj.type){
							case "close":
								close();
								dispatchEvent(new MGEvent(MGEvent.CLOSED, obj, type));
								break;
							case "error":
								dispatchEvent(new MGEvent(MGEvent.ERROR, obj, type));
								break;
							case "disconnected":
								dispatchEvent(new MGEvent(MGEvent.USER_DISCONNECTED, obj, type));
								break;
							case "joinChannel":
								dispatchEvent(new MGEvent(MGEvent.USER_JOINCHANNEL, obj, type));
								break;
							case "leaveChannel":
								dispatchEvent(new MGEvent(MGEvent.USER_LEAVECHANNEL, obj, type));
								break;
							case "authSuccess":
								dispatchEvent(new MGEvent(MGEvent.AUTH_SUCCESS, obj, type));
								break;
							case "roleChange":
								dispatchEvent(new MGEvent(MGEvent.ROLE_CHANGE, obj, type));
								break;
							case "nonce":
								nonceStr = json;
								if (authToken != null){
									var mac:String = SHA256.hash(authToken + nonceStr + authToken);
									writeJSON({type:"auth", auth:mac}, SYSTEM_JSON);
								}
								break;
						}
					}
					
					break;
				case GAME_JSON:
					trace("[MGSocket] GAME_JSON");
					json = data.readUTFBytes(data.length);
					trace("[MGSocket] " + json);
					obj = new JSONDecoder(json, true).getValue();
					
					dispatchEvent(new MGEvent(MGEvent.JSON, obj, type));
					break;
				case BIG_JSON:
					trace("[MGSocket] BIG_JSON");
					json = data.readUTFBytes(data.length);
					trace("[MGSocket] " + json);
					obj = new JSONDecoder(json, true).getValue();
					
					dispatchEvent(new MGEvent(MGEvent.JSON, obj, type));
					break;
				
				case SYSTEM_BINARY:
					trace("[MGSocket] SYSTEM_BINARY");
					dispatchEvent(new MGEvent(MGEvent.BINARY, data, type));
					break;
				case GAME_BINARY:
					trace("[MGSocket] GAME_BINARY");
					dispatchEvent(new MGEvent(MGEvent.BINARY, data, type));
					break;
				case BIG_BINARY:
					trace("[MGSocket] BIG_BINARY");
					break;
				default:
					trace("messageReceived: 0x" + type.toString(16) + " -- " + len + " -- " + data.length); 
					break;
			}
		}
		
		public function writeJSON(obj:Object, type:uint = GAME_JSON){
			var json:String = new JSONEncoder( obj ).getString();
			trace("[MGSocket] writeJSON -- " + json);
			
			var ba:ByteArray = new ByteArray();
			ba.writeUTFBytes(json);
			write(ba, type);
		}
		
		public function write(ba:ByteArray, type:uint = GAME_JSON){
			var header:uint = type << 16;
			header += ba.length;
			
			if (!socketReady){
				trace("Socket Not Ready.  Not executing the command.");
				return;
			}
			
			var tba:ByteArray = new ByteArray();
			tba.writeUnsignedInt(header);
			tba.writeBytes(ba, 0, ba.length);
			
			if (type == PING_NOCLOSE || type == PING){
				pingSendTime = new Date().time;;
			}
			
			try{
				socket.writeBytes(tba, 0, tba.length);
				socket.flush();
			}catch(err:Error){
				trace(err);
			}
		}
	}
	
	
}