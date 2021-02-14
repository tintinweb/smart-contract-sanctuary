/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

pragma solidity 0.8.1;

contract HelloWorld {
    string hi = "Hello, EtherWorld";
    
    function getHello() public view returns (string memory) {
        return hi;
    }
    
    function setHello(string memory newHi) public {
        hi = newHi;
    }
}