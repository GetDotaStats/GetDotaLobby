/*
Implementation of a basic version of the DNS protocol, since
that's a fundamental thing that doesn't work out of the box
*/

package ModDotaLib.Net
{
	public class D2DNSClient
	{
		public static const DNS_RECTYPE_A:int = 1;
		public static const DNS_RECTYPE_NS:int = 2;
		public static const DNS_RECTYPE_CNAME:int = 5;
		public static const DNS_RECTYPE_SOA:int = 6;
		public static const DNS_RECTYPE_PTR:int = 12;
		public static const DNS_RECTYPE_MX:int = 15;
		// cache dns responses
		private static var dnscache:Object = new Object();
		// current requests
		private static var currentrequests:Array = new Array();
		public static function D2DNSQuery(hostname:String, callback:Function, querytype:int = DNS_RECTYPE_A):void
		{
			if (dnscache["" + querytype + " " + hostname])
			{
				//cached query
				callback(dnscache[""+querytype+" "+hostname]);
			}
			else
			{
				//uncached query, need to do lookup
				var queryobject:DNSQuery = new DNSQuery(hostname,querytype,callback);
				queryobject.runQuery();
				currentrequests.push(queryobject);
			}
		}
		internal static function addToDNSCache(hostname:String, querytype:int, entr:Array):void
		{
			dnscache["" + querytype + " " + hostname] = entr;
		}
		internal static function allowCleanup(entr:DNSQuery):void
		{
			currentrequests = currentrequests.filter(function(obj:Object, index:int, array:Array):Boolean
				{
					return obj != this;
				},entr);
		}
	}
}