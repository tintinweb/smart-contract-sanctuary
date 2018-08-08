contract blockchaincertified2{
	struct certifieddata
    {
		address setaddress;
		uint id;
		string settitle;
		string setdata;
		uint savetime;
    }
    uint createtime;
	address public masteraddress;
	//all data
	//=======
	mapping (uint => certifieddata) public allcertifieddata;
	uint public allcertifieddatacount = 0;
	//=======
	
	event savelog(string savestr);
	
	function () payable {
	    savelog("payable");
	    masteraddress.transfer(msg.value);
	    string memory allstr = "thanks!";
	    string memory allstr2 = strConcat(allstr,AddresstoAsciiString(msg.sender));
	    savelog(allstr2);
    }
	
	function getBalance() constant returns(uint256){
      return this.balance;
	}
	
	function blockchaincertified()
    {
        createtime = uint(now);
		masteraddress = msg.sender;
	}
	
	function getcertifieddatacount() public constant returns (uint)
    {
		return allcertifieddatacount;
    }
	
	function addcertifieddata(string settitle,string setdata,string logstr) public returns (uint)
    {
		certifieddata memory addcertifieddata;
		allcertifieddatacount++;
		addcertifieddata.setaddress = msg.sender;
		addcertifieddata.id = allcertifieddatacount;
		addcertifieddata.settitle = settitle;
		addcertifieddata.setdata = setdata;
		addcertifieddata.savetime = uint(now);
		allcertifieddata[allcertifieddatacount-1] = addcertifieddata;
		savelog(getcertifieddata(allcertifieddatacount));
		savelog(logstr);
		return allcertifieddatacount;
    }
	
	function getcertifieddata(uint id) constant returns (string)
    {
		string memory allstr;
		string memory allstr2;
		if(id>0)
		{
			certifieddata retcertifieddata = allcertifieddata[id-1];
			allstr = AddresstoAsciiString(retcertifieddata.setaddress);
			allstr2 = strConcat(allstr,",");
        	allstr = strConcat(allstr2,uintToString(retcertifieddata.id));
			allstr2 = strConcat(allstr,",");
			allstr = strConcat(allstr2,retcertifieddata.settitle);
			allstr2 = strConcat(allstr,",");
			allstr = strConcat(allstr2,retcertifieddata.setdata);
			allstr2 = strConcat(allstr,",");
			allstr = strConcat(allstr2,uintToString(retcertifieddata.savetime));
		}
		return allstr;
    }
	
	function strConcat(string _a, string _b) constant returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        
        string memory abcde = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
       
        return string(babcde);
    }
	
	function char(byte b) constant returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
	
	function AddresstoAsciiString(address x) constant returns (string) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
	
	function uintToString(uint v) constant returns (string) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i] = byte(48 + remainder);
            i++;
            if(i>=maxlength)
            {
                break;
            }
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];
        }
        string memory str = string(s);
        return str;
    }
}