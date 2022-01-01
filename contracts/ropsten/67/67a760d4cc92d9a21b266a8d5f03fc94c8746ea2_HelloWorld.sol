/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

pragma solidity ^0.4.18;
 
contract HelloWorld {
    
    string wellcomeString = "Hello, world!";
    
    function getData() public constant returns (string) {
        return wellcomeString;
    }
    
    function setData(string newData) public {
        wellcomeString = newData;
    }
    
}