package ModDotaLib.Net
{

	import flash.net.Socket;
	// Buffer stuff
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	// Networking Events
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import flash.errors.IOError;

	internal class DNSQuery extends Socket
	{
		private var hostname:String;
		private var cback:Function;
		private var querytype:int;
		private var checkProgress:Boolean = false;
		private var response:ByteArray;
		private static var queryid:int = 1;
		public function DNSQuery(hostname:String, qtype:int, callback:Function):void
		{
			super();
			//trace('DNS: in DNSQuery Constructor');
			this.hostname = hostname;
			this.cback = callback;
			this.querytype = qtype;
			this.response = new ByteArray();
			this.response.endian = Endian.BIG_ENDIAN;
			//trace('DNS: attaching events');
			addEventListener(Event.CLOSE, onClosed);
			addEventListener(flash.events.ProgressEvent.SOCKET_DATA, onProgressed);
			addEventListener(IOErrorEvent.IO_ERROR, onError);
			//trace('DNS: constructed DNSQuery');
		}
		public function runQuery():void
		{
			//trace('DNS: establishing connection');
			addEventListener(Event.CONNECT, SendDNSRequest);
			connect('8.8.8.8',53);
			//trace('DNS: ran connect');
		}
		private function SendDNSRequest():void
		{
			//trace('DNS: in SendDNSRequest');
			removeEventListener(Event.CONNECT, SendDNSRequest);
			checkProgress = true;
			var buff:ByteArray = new ByteArray();
			// network order handling
			buff.endian = Endian.BIG_ENDIAN;
			//identification number
			buff.writeShort(queryid++);
			//one byte among this next set
			var temp:int = 0;
			// Query/Response Flag
			temp |=  0 << 7;
			// OpCode - 4 bits
			temp |=  0 << 3;
			// Authoritative Answer flag
			temp |=  0 << 2;
			// Truncated Message flag
			temp |=  0 << 1;
			// Recursion desired flag
			temp |=  1 << 0;

			buff.writeByte(temp);
			//one byte among this next set
			temp = 0;
			// Recursion Available flag
			temp |=  0 << 7;
			// z
			temp |=  0 << 6;
			// Authenticated Data flag
			temp |=  0 << 5;
			// Checking Disabled flag
			temp |=  0 << 4;
			// Response Code - 4 bits
			temp |=  0 << 0;
			buff.writeByte(temp);
			// Number of question entries
			buff.writeShort(1);
			// Number of answer entries
			buff.writeShort(0);
			// Number of authority entries
			buff.writeShort(0);
			// Number of resource entities
			buff.writeShort(0);

			// That's it for the header; now we need to do the body

			buff.writeBytes(HostNameToDNSString(this.hostname));

			// and we need to specify the question type
			buff.writeShort(querytype);
			// Specify that we're doing an internet query
			buff.writeShort(1);

			// TCP-based DNS queries require first sending the query length
			var buff2 = new ByteArray();
			buff2.endian = Endian.BIG_ENDIAN;
			buff2.writeShort(buff.length);
			writeBytes(buff2);
			// This flush doesn't actually work
			flush();
			// Now we can send the actual query
			writeBytes(buff);
			flush();

			//trace('DNS: sent DNS request');
		}
		private function onProgressed( event:ProgressEvent ):void
		{
			if (checkProgress)
			{
				if (event.bytesLoaded == 0)
				{
					checkProgress = false;
					close();
					handleResponse();
				}
				else
				{
					readBytes(response, response.length);
				}
			}
		}
		// The response has been acquired; handle it
		private function handleResponse():void
		{
			//jump back to the start of response
			response.position = 0;
			//trace("DNS: handling response");
			//header data
			//trace("DNS: response length is "+response.length);

			//trace("DNS RESPONSE:");
			var len:int = response.readUnsignedShort();
			var id:int = response.readUnsignedShort();
			var flags:int = response.readUnsignedShort();
			//trace("response contains:");
			var q_count = response.readUnsignedShort();
			var ans_count = response.readUnsignedShort();
			var auth_count = response.readUnsignedShort();
			var add_count = response.readUnsignedShort();
			//trace("Questions: "+q_count);
			//trace("Answers: "+ans_count);
			//trace("Authorities: "+auth_count);
			//trace("Resources: "+add_count);
			var retval:Array = new Array();
			var i:int;
			for (i = 0; i<q_count; i++)
			{
				//read questions
				var entry_ques_name:String = ReadName(response);
				var entry_ques_type:int = response.readUnsignedShort();
				var entry_ques_class:int = response.readUnsignedShort();
				//trace("Question Entry for "+entry_ques_name+", type "+entry_ques_type+", class "+entry_ques_class);
			}
			for (i = 0; i<ans_count; i++)
			{
				//read answer
				var entry_ans_name:String = ReadNameRR(response);
				//trace("got name of "+entry_ans_name);
				var entry_type:int = response.readUnsignedShort();
				var entry_class:int = response.readUnsignedShort();
				var entry_ttl:int = response.readUnsignedInt();
				var entry_data_len:int = response.readUnsignedShort();
				//trace("body is "+entry_type +" "+entry_class+" "+entry_ttl+" "+entry_data_len);
				var entry_data:ByteArray = new ByteArray();
				response.readBytes(entry_data,0,entry_data_len);
				if (entry_type == 1)
				{// 'A' record
					var entry_ans_data_val=(""+entry_data[0]+"."+entry_data[1]+"."+entry_data[2]+"."+entry_data[3]);
					retval.push(new DNSEntry(entry_ans_name,entry_type,entry_ans_data_val));
				}
				//trace("Answer Entry for "+entry_ans_name);
			}
			for (i = 0; i<auth_count; i++)
			{
				//read authority
				// we're going to assume this is 0
			}
			for (i = 0; i<add_count; i++)
			{
				//read resource
				// we're going to assume this is 0
			}
			// Add the response to the DNS cache
			D2DNSClient.addToDNSCache(this.hostname,this.querytype,retval);
			// Call the callback with the response
			this.cback(retval);
			// Allow this DNSQuery to be cleaned up by the GC
			D2DNSClient.allowCleanup(this);
		}
		private function ReadName(from:ByteArray):String
		{
			var ret:String = "";
			var cur:int = from.readUnsignedByte();
			while (cur != 0)
			{
				ret = ret + from.readUTFBytes(cur);
				cur = from.readUnsignedByte();
				if (cur != 0)
				{
					ret = ret + ".";
				}
			}
			return ret;
		}
		private function ReadNameRR(from:ByteArray):String
		{
			//save the old position
			var savedpos:int = from.position;
			var cur:int = from.readUnsignedShort();
			if ((cur & 49152) == 49152)
			{
				//this means that it's an offset-labelled address
				var offset = cur ^ 49152;
				from.position = offset + 2;// the +2 is because of the length prefix in TCP DNS
				var ret:String = ReadName(from);
				from.position = savedpos + 2;// go back to whence we game, but after the pointer
				return ret;
			}
			else
			{
				//not a pointer, so just go as usual
				from.position = from.position - 2;
				return ReadName(from);
			}
		}
		private static function HostNameToDNSString(dotname:String):ByteArray
		{
			var output:ByteArray = new ByteArray();
			while (dotname.length > 0)
			{
				var len = dotname.indexOf('.');
				if (len <= 0)
				{
					len = dotname.length;
				}
				output.writeByte(len);
				output.writeUTFBytes(dotname.substr(0,len));
				dotname = dotname.substr(len+1);// omit the dot
			}
			output.writeByte(0);
			return output;
		}
		private function onError(event:IOErrorEvent):void
		{
			trace("DNS: IO Error: " + event);
		}
		private function onClosed():void
		{
			trace("DNS: Socket closed by remote host");
		}
	}
}