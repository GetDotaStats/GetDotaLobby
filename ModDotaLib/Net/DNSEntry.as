package ModDotaLib.Net
{
	public class DNSEntry
	{
		public var hostname:String;
		public var recordtype:int;
		public var response:String;
		public function DNSEntry(h:String, rt:int, rs:String) {
			this.hostname = h;
			this.recordtype = rt;
			this.response = rs;
		}
	}
}