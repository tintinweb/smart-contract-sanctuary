/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract Hello {
    string message = "Hello";
    
    function getMessage() public view returns (string memory) {
        return message;
    }
    
    function setMessage(string memory mseg) public {
        message = mseg;
    }
}