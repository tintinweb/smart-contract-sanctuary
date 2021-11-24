/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

pragma solidity ^0.8.7;
//SPDX-License-Identifier:UNLICENSED
contract MessageboxO {
    string public message;
    
    constructor ()  {
        message = "HELLO WORLD!";
    }
    
    function setMessage(string memory _new_message) public {
        message = _new_message;
    }
    
    function getMessage() public view returns (string memory) {
        return message;
    }
    
}