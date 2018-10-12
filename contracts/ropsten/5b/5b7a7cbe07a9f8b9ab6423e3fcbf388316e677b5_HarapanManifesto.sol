pragma solidity ^0.4.17;

contract HarapanManifesto{
	struct Manifesto {
		string ManifestoCategory;
		string ManifestoAction;
		uint CompletionDate;
		bool Broken;
		bool Completed;
	}
	
	mapping (uint => Manifesto) private manifestos;
	
	address owner;
	mapping(address => bool) public Admins;
	uint manifestoCount;
	uint deletedCount;
	
	constructor(){
		owner = msg.sender;
		manifestoCount = 0;
	}
	
	modifier ownerOnly {
		require(msg.sender == owner);
		_;
	}
	
	modifier adminOrOwnerOnly {
		require(msg.sender == owner || IsAdmin(msg.sender));
		_;
	}
	
	function AddAdmin(address _address) public ownerOnly {
		Admins[_address] = true;
	}
	
	function IsAdmin(address _address) returns (bool) {
		return Admins[_address];
	}
	
	function InitializeManifesto(string manifestoCategory, string manifestoAction, uint CompletionDate, bool Broken, bool Completed) public ownerOnly {
		manifestos[manifestoCount].ManifestoCategory = manifestoCategory;
		manifestos[manifestoCount].ManifestoAction = manifestoAction;
		manifestos[manifestoCount].CompletionDate = CompletionDate;
		manifestos[manifestoCount].Broken = Broken;
		manifestos[manifestoCount].Completed = Completed;
		manifestoCount++;
	}
	
	function InsertManifesto(string manifestoCategory, string manifestoAction) public adminOrOwnerOnly {
		manifestos[manifestoCount].ManifestoCategory = manifestoCategory;
		manifestos[manifestoCount].ManifestoAction = manifestoAction;
		manifestos[manifestoCount].CompletionDate = 0;
		manifestos[manifestoCount].Broken = false;
		manifestos[manifestoCount].Completed = false;
		manifestoCount++;
	}
	
	function GetManifestoByCategory(string category) public view returns (string){
	    string memory ret = "\x5B";
	    string memory manifestoCategory;
	    
		for(uint i = 0; i < manifestoCount; i++){
		    manifestoCategory = manifestos[i].ManifestoCategory;
			if(compareStrings(manifestoCategory,category)){
			    ret = strConcat(ret,"Id:",uint2str(i)," , ");
			    ret = strConcat(ret,"ManifestoAction:",manifestos[i].ManifestoAction," , ");
			    ret = strConcat(ret,"CompletionDate:",uint2str(manifestos[i].CompletionDate)," , ");
			    ret = strConcat(ret,"Broken:",bool2str(manifestos[i].Broken)," , ");
			    ret = strConcat(ret,"Completed:",bool2str(manifestos[i].Completed)," ; ");
			}
		}
		
		ret = strConcat(ret, "\x5D");
		return ret;
	}
	
	function GetManifestoById(uint id) public view returns (string manifestoCategory, 
							  string manifestoAction,
							  uint completionDate, 
							  bool broken, 
							  bool completed){
		return(manifestos[id].ManifestoCategory,
			   manifestos[id].ManifestoAction,
			   manifestos[id].CompletionDate,
			   manifestos[id].Broken,
			   manifestos[id].Completed);
	}
	
	function ManifestoCount() public view returns (uint){
		return manifestoCount - 1 ;
	} 
	
	function UpdateManifesto(uint id, bool broken, bool completed) ownerOnly public  returns (bool, bool, uint){
		manifestos[id].Broken = broken;
		manifestos[id].Completed= completed;
		
		if(completed){
			manifestos[id].CompletionDate = now;
		}
		
		return (broken, completed, id);
	}
	
	function DeleteContract() ownerOnly public{
		selfdestruct(owner);
	}
	
	function bool2str(bool i) internal pure returns (string){
	    if(i) return "true";
	    else return "false";
	}
	
	function uint2str(uint i) internal pure returns (string){
    if (i == 0) return "0";
    uint j = i;
    uint length;
    while (j != 0){
        length++;
        j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint k = length - 1;
    while (i != 0){
        bstr[k--] = byte(48 + i % 10);
        i /= 10;
    }
    return string(bstr);
}
    
    function compareStrings (string a, string b) view returns (bool){
       return keccak256(a) == keccak256(b);
   }
    
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    
    function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }
    
    function strConcat(string _a, string _b, string _c) internal returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }
    
    function strConcat(string _a, string _b) internal returns (string) {
        return strConcat(_a, _b, "", "", "");
    }
}