package  {
	import flash.events.Event;
	
	public class MGEvent extends Event{
		public static const JSON:String = "mg-json";
		public static const BINARY:String = "mg-binary";
		public static const CLOSED:String = "mg-closed";
		public static const ERROR:String = "mg-error";
		public static const AUTH_SUCCESS:String = "mg-authsuccess";
		public static const ROLE_CHANGE:String = "mg-rolechange";
		public static const USER_DISCONNECTED:String = "mg-disconnected";
		public static const USER_JOINCHANNEL:String = "mg-joinchannel";
		public static const USER_LEAVECHANNEL:String = "mg-leavechannel";
		
		
		public var object:Object;
		public var typeCode:uint;
		
		public function MGEvent(eventType:String, obj:Object, typeCode:uint = 4){
			super(eventType);
			
			this.object = obj;
			this.typeCode = typeCode;
		}
	}
}
