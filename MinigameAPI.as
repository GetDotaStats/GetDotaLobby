package  {
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.display.Loader;
	import flash.net.Socket;
	import flash.events.Event;
	import com.adobe.crypto.SHA1;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.ByteArray;
	
	import ValveLib.Globals;
	import flash.geom.Point;
	import flash.events.ProgressEvent;
	
	public class MinigameAPI implements IMinigameAPI{
		private static const salt:String = "";
		private var minigameID:String = "";
		private var DEBUG:Boolean = false;
		private var gameName:String = "";
		private var lx:Object = null;
		private var data:Object = null;
		private var uid:String = null;
		private var currentLocalization:Object = null;
		private var language:String = null;
		
		private var container:MovieClip;
		private var panel:MovieClip;
		private var indent:MovieClip;
		private var outer:MovieClip;
		private var minigame:Minigame;
		private var title:TextField;
		private var closeButton:MovieClip;
		
		public function MinigameAPI(minigame:Minigame, container:MovieClip, panel:MovieClip, indent:MovieClip, 
									outer:MovieClip, title:TextField, closeButton:MovieClip, lx:Object, 
									gameName:String, debug:Boolean, uid:String, language:String = "english") {
			this.minigame = minigame;
			this.container = container;
			this.panel = panel;
			this.indent = indent;
			this.outer = outer;
			this.title = title;
			this.closeButton = closeButton;
			this.uid = uid;
			this.language = language;
			
			this.minigameID = minigame.minigameID;
			
			this.lx = lx;
			this.gameName = gameName;
			this.DEBUG = debug;
			
			
			this.currentLocalization = Globals.instance.GameInterface.LoadKVFile('resource/flash3/minigames/' + gameName + '/minigame_english.txt');
			if (currentLocalization.Tokens == null){
				currentLocalization.Tokens = new Object();
				log("No localization tokens found for minigame_english.txt");
			}
			if (language != "english"){
				var lang:Object = Globals.instance.GameInterface.LoadKVFile('resource/flash3/minigames/' + gameName + '/minigame_' + language + '.txt');
				if (lang.Tokens != null){
					for (var token:String in lang.Tokens){
						currentLocalization.Tokens[token] = lang.Tokens[token];
					}
				}
				else{
					log("No localization tokens found for minigame_" + language + ".txt");
				}
			}
		}
		
		public function getData() : Object{
			if (data == null){
				data = Globals.instance.GameInterface.LoadKVFile('resource/flash3/minigames/' + gameName + '/data.kv');
			}
			
			return data;
		}
		public function saveData() : void{
			if (data == null){
				log("saveData called with no data");
			}
			Globals.instance.GameInterface.SaveKVFile(data, 'resource/flash3/minigames/' + gameName + '/data.kv', gameName);
		}
		
		public function resizeGameWindow(wid:Number = -1, hei:Number = -1) : void {
			if (wid == -1)
				wid = minigame.width;
			if (hei == -1)
				hei = minigame.height;
			panel.width = wid + 15;
			panel.height = hei + 15;
			
			indent.width = wid + 14;
			
			outer.height = hei + 35;
			outer.width = wid + 18;
			
			title.width = wid + 18;
			
			closeButton.x = wid + 12;
		}
		
		public function repositionGameWindow(xpos:Number = -1000, ypos:Number = -1000) : void {
			var screenWidth:Number = lx.screenWidth;
			var screenHeight:Number = lx.screenHeight;
			var correctedRatio:Number = lx.correctedRatio;
			
			if (xpos == -1000){
				xpos = screenWidth / 2 - container.width / 2;// * correctedRatio;
			}
			else if (xpos > 0 && xpos < 1){
				xpos = screenWidth * xpos;
			}
			
			if (ypos == -1000){
				ypos = screenHeight / 2 - container.height / 2;// * correctedRatio;
			}
			else if (ypos > 0 && ypos < 1){
				ypos = screenHeight * ypos;
			}
			
			container.x = xpos;
			container.y = ypos;
		}
		
		public function updateTitle() : void {
			title.text = translate(minigame.title);
		}
		
		public function closeMinigame() : void {
			lx.closeMinigame();
		}
		
		public function translate(str:String) : String{
			if (str.charAt(0) != "#")
				return str;
				
			var token:String = str.substr(1);
			var translated:String = currentLocalization.Tokens[token];
			if (translated != null)
				return translated;
			
			translated = Globals.instance.GameInterface.Translate(str);
			if (translated != "")
				return translated;
			return str;
		}
		
		public function updateLeaderboard(leaderboard:String, value:Number) : void {
			if (DEBUG) {
				log("DEBUG on, not sending leaderboard info: " + leaderboard + " -- " + value);
				return;
			}
			
			var username:String = Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.Player.PlayerNameIngame.text;
			var msg:Object = {minigameID:minigameID, leaderboard:leaderboard, value:value, userID32:uid, userName:username, type:"HIGHSCORE"};
			var encodedJSON:String = GetDotaLobby.encode(msg);
			log("Leaderboard message: " + encodedJSON);
			msg["hmac"] = SHA1.hash(salt + encodedJSON);
			encodedJSON = GetDotaLobby.encode(msg);

			var socket:Socket = new Socket();

			var leaderboardConnect:Function = (function(json:String, socket:Socket) {
				return function(e:Event){
					socket.removeEventListener(Event.CONNECT, leaderboardConnect);
					trace("writing leaderboard socket: " + json);
					try{
						var ba:ByteArray = new ByteArray();
						var len:uint = ba.length;
						
						ba = new ByteArray();
						ba.writeUTF(json);
						trace(ba.length);
		
						socket.writeBytes(ba, 0, ba.length);
						socket.flush();
						
						var fun:Function = function(te:TimerEvent){
							socket.close();
						};
						var timer:Timer = new Timer(500, 1);
						timer.addEventListener(TimerEvent.TIMER, fun);
						timer.start();
					}catch(err:Error){
						trace(err);
					}
				};
			})(encodedJSON, socket);

			trace("CONNECTING");
			socket.connect("176.31.182.87", 4450);
			socket.addEventListener(Event.CONNECT, leaderboardConnect);
		}
		
		public function getLeaderboardTop(leaderboard:String, callback:Function) : void {
			if (DEBUG) {
				log("DEBUG on, not pulling leaderboard info: " + leaderboard);
				callback(GetDotaLobby.decode('[{"user_id32":55321338,"highscore_value":6151},{"user_id32":16784953,"highscore_value":6780},{"user_id32":102929866,"highscore_value":7656},{"user_id32":189606512,"highscore_value":7685},{"user_id32":119671710,"highscore_value":7704},{"user_id32":88242363,"highscore_value":7817},{"user_id32":68903670,"highscore_value":7888},{"user_id32":38943671,"highscore_value":7919},{"user_id32":201543448,"highscore_value":8135},{"user_id32":62945735,"highscore_value":8367},{"user_id32":101661666,"highscore_value":8517},{"user_id32":17659180,"highscore_value":8546},{"user_id32":89763128,"highscore_value":8561},{"user_id32":50906605,"highscore_value":8672},{"user_id32":97717801,"highscore_value":8717},{"user_id32":32720905,"highscore_value":8719},{"user_id32":199290730,"highscore_value":8760},{"user_id32":212226522,"highscore_value":8801},{"user_id32":145282485,"highscore_value":9000}]'));
				return;
			}
			
			var msg:Object = {minigameID:minigameID, leaderboard:leaderboard, type:"LEADERBOARD"};
			var encodedJSON:String = GetDotaLobby.encode(msg);

			var socket:Socket = new Socket();

			var leaderboardConnect:Function = (function(json:String, socket:Socket) {
				return function(e:Event){
					socket.removeEventListener(Event.CONNECT, leaderboardConnect);
					
					var responseMsg:String = "";
					var done:Boolean = false;
					
					var dataRead:Function = function(prog:ProgressEvent){
						if (done)
							return;
							
						var str:String = socket.readUTFBytes(socket.bytesAvailable);
						responseMsg += str;
						//trace(responseMsg);
						
						try{
							//var body:String = responseMsg.substr(responseMsg.indexOf("\r\n\r\n")+4);
							//trace(body);
							var obj:Object = GetDotaLobby.decode(responseMsg);
							done = true;
							try{
								if (obj.hasOwnProperty('jsonData')){
									callback(obj.jsonData);
								}
								else{
									callback(obj);
								}
							}catch(ee:Error){
								log('Leaderboard callback error -- ' + ee);
							}
							
							var fun:Function = function(te:TimerEvent){
								socket.close();
							};
							var timer:Timer = new Timer(500, 1);
							timer.addEventListener(TimerEvent.TIMER, fun);
							timer.start();
						}catch(eee:Error){trace(eee);}
					};
					
					socket.addEventListener(ProgressEvent.SOCKET_DATA, dataRead);
					
					trace("writing leaderboard socket: " + json);
					try{
						var ba:ByteArray = new ByteArray();
						var len:uint = ba.length;
						
						ba = new ByteArray();
						ba.writeUTF(json);
						trace(ba.length);
		
						socket.writeBytes(ba, 0, ba.length);
						socket.flush();
						
					}catch(err:Error){
						trace(err);
					}
				};
			})(encodedJSON, socket);

			trace("CONNECTING");
			socket.connect("176.31.182.87", 4450);
			socket.addEventListener(Event.CONNECT, leaderboardConnect);
		}
		
		public function getUserID() : String {
			return uid;
		}
		
		public function log(obj:Object) : void {
			lx.traceLX("[" + gameName + "]" + obj.toString());
		}
	}
	
}
