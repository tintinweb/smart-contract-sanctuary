/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract MoonieContract {
    string message;
    
    function setMessage(string memory _message) public {
        message=_message;
    }
}