/*
Implementation of a basic version of the HTTP protocol, allowing POST
and GET requests to a webserver from within the dota 2 UI. All data is
returned asynchronously.

Author: Perry
*/
package dota2Net {
	import flash.net.Socket;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import com.adobe.serialization.json.JSONDecoder;

	public class D2HTTPSocket extends Socket {
		//public settings
		public var ignoreHeaders:Boolean;
		
		//host name and IP
		private var hostName:String;
		private var hostIP:String;
		
		//default http port
		private var port:int = 80;
		
		//internal variables
		private var currentJob:Object = null;
		private var isConnected:Boolean = false;
		private var checkProgress:Boolean = false;
		private var responseMsg:String = "";
		private var callback:Function = null;
		
		private var path:String;
		private var data:String;
		private var postContentType:String;
		
		private var TYPE_POST:int = 1;
		private var TYPE_GET:int = 2;
		private var httpQueue:Array = new Array();
		
		private var closeTimer:Timer;
		private var closeCount:int = 0;
		private var closeMax:int = 60;
		
		private var checkFunction:Function = null;
		
		public static var jsonComplete:Function = function(msg:String, event:ProgressEvent) : Boolean{
			if (msg.indexOf("\r\n\r\n")){
				try{
					var body:String = msg.substr(msg.indexOf("\r\n\r\n")+4);
					decode(body);
				}catch(e:Error){ 
					return false;
				}
				return true;
			}
			return false;
		};
		
		public static var totalZeroComplete:Function = function(msg:String, event:ProgressEvent) : Boolean{
			if (event.bytesLoaded == 0) {
				return true;
			}
			return false;
		};
		
		
		//===========PUBLIC SECTION - INTERFACE ============
		//constructor
		public function D2HTTPSocket( hostname:String, hostip:String, ignoreHeaders:Boolean = true ) : void {
			super();
			this.hostName = hostname;
			this.hostIP = hostip;
			
			this.ignoreHeaders = ignoreHeaders;
			
			//register events
			//addEventListener(Event.CONNECT, onConnected);
			addEventListener(ProgressEvent.SOCKET_DATA, onProgressed);
			addEventListener(Event.CLOSE, onClosed);
			
			closeTimer = new Timer(50,0);
			closeTimer.addEventListener(TimerEvent.TIMER, checkClose);			
		}
		
		//Send a POST request with some data to the specified path
		//Parameters:	path:String - The path of the page to send the request to
		//				data:String - The data to send with the POST request
		//				callback:Function - Callback that is executed once data is returned (optional but recommended)
		//              contentType:String - The Content-Type header to be used (optional)
		public function postDataAsync( path:String, data:String, callback:Function = null, checkFunction:Function = null, contentType:String = 'application/x-www-form-urlencoded' ) : void {
			if (checkFunction == null)
				this.checkFunction = D2HTTPSocket.jsonComplete;
			else
				this.checkFunction = checkFunction;
				
			if (this.currentJob != null){
				httpQueue.push({"type":TYPE_POST, "path":path, "data":data, "callback":callback, "contentType":contentType, "checkFunction":this.checkFunction});
				return;
			}
			
			//connect
				
			trace('opening socket');
			this.currentJob = {"type":TYPE_POST, "path":path, "data":data, "callback":callback, "contentType":contentType, "checkFunction":this.checkFunction};
			connect( hostIP, port );
			
			this.path = path;
			this.data = data;
			this.postContentType = contentType;
			this.callback = callback;
			
			
			//check if the socket is connected
			addEventListener(Event.CONNECT, postDataCallback);
		}
		
		//Send a GET request for some data
		//Parameters:	path:String - The path of the page to send the request to
		//				callback:Function - Callback that is executed once data is returned
		public function getDataAsync( path:String, callback:Function, checkFunction:Function = null) : void {
			if (checkFunction == null)
				this.checkFunction = D2HTTPSocket.jsonComplete;
			else
				this.checkFunction = checkFunction;
				
			if (this.currentJob != null){
				httpQueue.push({"type":TYPE_GET, "path":path, "data":null, "callback":callback, "checkFunction":this.checkFunction});
				return;
			}
			
			//connect
			this.currentJob = {"type":TYPE_GET, "path":path, "data":null, "callback":callback, "checkFunction":this.checkFunction};
			connect( hostIP, port );
			
			this.path = path;
			this.callback = callback;
			
			
			//check if the socket is connected
			addEventListener(Event.CONNECT, getDataCallback);
		}
		
		//====== PRIVATE SECTION - INTERNAL WORKINGS ===========
		
		private function checkClose(e:TimerEvent): void{
			closeCount++;
			if (closeCount >= closeMax){
				onClosed(e);
			}
		}
		
		private function postDataCallback() : void {
			removeEventListener(Event.CONNECT, postDataCallback);
			
			//reset response message
			responseMsg = "";
			//check progress on the response
			checkProgress = true;
			
			//Write data to socket
			writeStrToSocket("POST /"+path+" HTTP/1.0\r\n");
			writeStrToSocket("Host: "+hostName+"\r\n");
			writeStrToSocket("Content-Type: "+postContentType+"\r\n");
			writeStrToSocket("Content-Length: "+data.length+"\r\n\r\n");
			writeStrToSocket(data);
			flush();
		}
		
		private function getDataCallback() : void {
			removeEventListener(Event.CONNECT, getDataCallback);
			//reset response message
			responseMsg = "";
			//check progress on the response
			checkProgress = true;
			closeTimer.start();
			
			//Write data to socket
			writeStrToSocket("GET /"+path+" HTTP/1.0\r\n");
			writeStrToSocket("Host: "+hostName+"\r\n\r\n");	
			//writeStrToSocket("Connection: keep-alive\r\n");
			//writeStrToSocket("User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36\r\n");	
			//writeStrToSocket("Accept-Language: en-US,en;q=0.8\r\n")
			//writeStrToSocket("Accept-Encoding: gzip, deflate, sdch\r\n");
			//writeStrToSocket("Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\r\n\r\n")
			flush();
		}
		
		//Handle connection event
		private function onConnected( event:Event ) : void {
			isConnected = true;
		}
		
		private function onClosed (event:Event) : void {
			checkProgress = false;
			close();
			//return data to the callback if it exists
			if (callback != null) {
				//check if we got a correct response
				//trace("RESPONSE MSG: " + responseMsg);
				var statusCode = parseInt(responseMsg.split("\r\n")[0].split(" ")[1]);
				
				var msg:String = responseMsg.substr(responseMsg.indexOf("\r\n\r\n")+4);
				
				//call the callback with the status and the
				//response message
				try{
					callback( statusCode, msg );
				}
				catch(e:Error){
					trace(e.getStackTrace());
				}
			}
			
			closeTimer.reset();
			closeCount = 0;
			this.currentJob = null;
			checkQueue();
		}
		//Handle progress event
		private function onProgressed( event:ProgressEvent ) : void {
			if (checkProgress) {
				readSocket();
				
				if (this.checkFunction(responseMsg, event)){
					onClosed(event);
				}
				/*check for empty progress events
				if (event.bytesLoaded == 0) {
					//stop checking progress
					checkProgress = false;
					close();
					
					//return data to the callback if it exists
					if (callback != null) {
						//check if we got a correct response
						trace("RESPONSE MSG: " + responseMsg);
						var statusCode = parseInt(responseMsg.split("\r\n")[0].split(" ")[1]);
						
						var msg:String = responseMsg.substr(responseMsg.indexOf("\r\n\r\n")+4);
						
						//call the callback with the status and the
						//response message
						try{
							callback( statusCode, msg );
						}
						catch(e:Error){
							trace(e.getStackTrace());
						}
					}
					
					this.currentJob = null;
					checkQueue();
				} else {
					//if there is data available, read it
					readSocket();
				}*/
			}
		}
		
		private function checkQueue(){
			trace("queuelen: " + this.httpQueue.length);
			if (this.httpQueue.length == 0)
				return;
				
			trace("popping queue");
			this.currentJob = this.httpQueue.shift();
			
			if (this.currentJob.type == TYPE_GET){
				//connect
				connect( hostIP, port );
				
				this.path = this.currentJob.path;
				this.callback = this.currentJob.callback;
				this.checkFunction = this.currentJob.checkFunction;
				
				//check if the socket is connected
				addEventListener(Event.CONNECT, getDataCallback);
			}
			else if (this.currentJob.type == TYPE_POST){
				//connect
				trace('opening socket');
				connect( hostIP, port );
				
				this.path = this.currentJob.path;
				this.data = this.currentJob.data;
				this.postContentType = this.currentJob.contentType;
				this.callback = this.currentJob.callback;
				this.checkFunction = this.currentJob.checkFunction;
				
				//check if the socket is connected
				addEventListener(Event.CONNECT, postDataCallback);
			}
		}
		
		//Read string data from the socket
		private function readSocket() : void {
			var str:String = readUTFBytes(bytesAvailable);
			responseMsg += str;
			//trace("PROGRESSED -- " + bytesAvailable);
			//trace("PROGRESSED -- " + str);
			closeCount = 0;
		}
		
		//Write string data to the socket
		private function writeStrToSocket(str:String) : void {
			//Try writing data to the socket, otherwise output the error
			try {
				writeUTFBytes(str);
			}
			catch(e:IOError) {
				trace(e);
			}
		}
		
		// JSON decoder
        private static function decode( s:String, strict:Boolean = true ):* {
            return new JSONDecoder( s, strict ).getValue();
        }
	}
}