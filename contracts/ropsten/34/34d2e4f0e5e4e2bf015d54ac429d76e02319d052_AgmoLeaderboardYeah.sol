pragma solidity ^0.4.0;

contract AgmoLeaderboardYeah {
    
    struct Game{
        string name;
        address gameOwner;
        uint leaderboardCount;
        mapping(uint => Leaderboard) leaderboards;
    }

    struct Leaderboard {
        string name;
        uint score;
    }
    
    address owner;
    mapping(string => Game) private games;

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
    
    modifier gameOwnerOnly(string gameName) {
        require(msg.sender == games[gameName].gameOwner);
        _;
    }
    
    function addGame(string name) ownerOnly public {
        games[name] = Game({name: name, gameOwner: msg.sender, leaderboardCount: 0});
    }

    function addLeaderboard(string gameName, string name, uint256 score) gameOwnerOnly(gameName) public {
    	if(games[gameName].leaderboardCount == 100 && score < games[gameName].leaderboards[99].score){
    		return;
    	}
    	
    	if(games[gameName].leaderboardCount < 100){
    		games[gameName].leaderboards[games[gameName].leaderboardCount].name = "TEMP";
    		games[gameName].leaderboards[games[gameName].leaderboardCount].score = 0;
    		games[gameName].leaderboardCount++;
    	}
    	
    	for(uint i = games[gameName].leaderboardCount - 1; i >= 0; i--){
    		if(i == 0){
    			games[gameName].leaderboards[i].name = name;
    			games[gameName].leaderboards[i].score = score;
    			break;
    		}
    		
    		if(score > games[gameName].leaderboards[i-1].score){
    			games[gameName].leaderboards[i]= games[gameName].leaderboards[i-1];
    		}else{
    			games[gameName].leaderboards[i].name = name;
    			games[gameName].leaderboards[i].score = score;
    			break;
    		}
    	}
    }

    function getLeaderboard(string gameName) public constant returns (string) {
        string memory ret = "\x5B";
        
        for (uint i=0; i < games[gameName].leaderboardCount; i++) {
            string memory result = strConcat(&#39;{"name": "&#39;, games[gameName].leaderboards[i].name , &#39;","score": "&#39;,
                                uintToString(games[gameName].leaderboards[i].score), &#39;"}&#39;);
            if(i != games[gameName].leaderboardCount - 1){
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