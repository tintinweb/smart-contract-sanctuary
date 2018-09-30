pragma solidity ^0.4.0;

contract AgmoLeaderboardYeah {

    struct Leaderboard {
        string name;
        uint score;
    }
    address owner;
    Leaderboard[] leaderboards;

    constructor () {
        owner = msg.sender;
    }
    
    function DeleteContract() ownerOnly public{
        selfdestruct(owner);
    }
    
    modifier ownerOnly {
       require(msg.sender == owner);
       _;
    }

    function addLeaderboard(string name, uint256 score) ownerOnly public {
    	if(leaderboards.length == 100 && score < leaderboards[99].score){
    		return;
    	}
    	
    	if(leaderboards.length < 100){
    		leaderboards.push(Leaderboard("contract temporary", 0));
    	}
    	
    	for(var i = leaderboards.length - 1; i >= 0; i--){
    		if(i == 0){
    			leaderboards[i]= Leaderboard(name, score);
    			break;
    		}
    		
    		if(score > leaderboards[i-1].score){
    			leaderboards[i]= leaderboards[i-1];
    		}else{
    			leaderboards[i]= Leaderboard(name, score);
    			break;
    		}
    	}
    }

    function getLeaderboard() public constant returns (string) {
        string memory ret = "\x5B";
        
        for (uint i=0; i<leaderboards.length; i++) {
            string memory result = strConcat(&#39;{"name": "&#39;, leaderboards[i].name , &#39;","score": "&#39;,
                                uintToString(leaderboards[i].score), &#39;"}&#39;);
            if(i != leaderboards.length - 1){
                result = strConcat(result, ",");
            }
            ret = strConcat(ret, result);
        }
        ret = strConcat(ret, "\x5D");
        return ret;
    }
    
    function uintToString(uint v) constant returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
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