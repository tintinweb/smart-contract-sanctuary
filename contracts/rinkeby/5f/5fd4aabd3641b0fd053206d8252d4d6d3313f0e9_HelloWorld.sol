/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;

contract HelloWorld{
    
    string private greeting;
    string public myName;
    
    function setUserName (string memory myNameNew) public {
        myName = myNameNew;
        setGreating();
    }
    
    function getGreeting() public view returns(string memory) {
        if (bytes(greeting).length > 0) {
            return greeting;
        } else {
            return getDefaultGreeting();
        }
    }
    
    function setGreating() internal {
        greeting = string(abi.encodePacked("Hello, ", myName));
    }
    
    function getDefaultGreeting() internal pure returns(string memory) {
        return "Hello, I don't know your name!";
    }
}