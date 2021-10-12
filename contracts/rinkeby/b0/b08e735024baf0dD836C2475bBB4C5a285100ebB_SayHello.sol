/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity ^0.8.1;


contract SayHello {
    
    string greeting;
    
    function setHello(string memory _saySomething) public {
        greeting = _saySomething;
    }
    
    function getHello() public view returns (string memory) {
        return greeting;
    }
    
}