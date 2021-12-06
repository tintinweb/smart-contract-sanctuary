/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

pragma solidity ^0.8.7;		

contract constructorExample {		
	
	address str;		
	constructor(address _str) {				
		str = _str;		
	}		
	

    function checkval(address _chk) public view returns(bool) {
        require(str == _chk,"Not valid address");
        return(true);
    }
}