/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

contract Box {
    string public message;
    
    function setMessage(string memory _message) public {
        message = _message;
    }
}