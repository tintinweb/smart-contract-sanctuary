/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Messagebox {
    string public message;
    
    constructor ()  {
        message = "Hello World!";
    }
    
    function setMessage(string memory _new_message) public {
        message = _new_message;
    }
    
    function getMessage() public view returns (string memory) {
        return message;
    }
    
}