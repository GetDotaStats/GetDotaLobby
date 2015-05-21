package ModDotaLib.Net
{
	// Buffer stuff
	import flash.utils.ByteArray;

	// Networking Events
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import scaleform.clik.interfaces.IDataProvider;
	import scaleform.clik.data.DataProvider;

	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import flash.net.Socket;

	public class Console
	{
		private var conn:Socket;
		private var sourceversion:Number;

		// This object represents the console from the perspective of the other
		// flash code. Should be very nice and easy to use; we only currently
		// expose the ability to run commands.
		public function Console():void
		{
			trace("CREATING SOCKET CONNECTION");
			this.sourceversion = GetSourceEngineVersion();
			switch (sourceversion)
			{
				case 1 :
					trace("making s1 console connection...");
					this.conn = new Socket("127.0.0.1",28999);
					break;
				case 2 :
					trace("making s2 console connection...");
					this.conn = new Socket("127.0.0.1",29000);
					break;
			}
		}

		public function RunCommand(command:String):void
		{
			trace("ATTEMPTING TO RUN COMMAND "+command);
			var buff:ByteArray = new ByteArray();
			switch (sourceversion)
			{
				case 1 :
					// netcon is very simple
					buff.writeUTFBytes(command);
					// CR (\r)
					buff.writeByte(13);
					// LF (\n)
					buff.writeByte(10);
					break;
				case 2 :
					// CMND
					buff.writeUTFBytes("CMND");
					// Version (0x00d20000)
					buff.writeUnsignedInt(13762560);
					// Length (including header and null terminator)
					buff.writeUnsignedInt(command.length+12+1);
					// Command
					buff.writeUTFBytes(command);
					// Null terminator
					buff.writeByte(0);
					break;
			}
			// Whatever we made, we should send
			this.conn.writeBytes(buff, 0, buff.length);
			this.conn.flush();
		}

		// Determine the source engine version used; ideally,
		// this should allow us to transparently have a single
		// socket interface. There's likely some way of determining
		// which version we're in dynamically.
		private function GetSourceEngineVersion():int
		{
			return 2;
		}
	}
}
