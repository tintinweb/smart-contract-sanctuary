/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MyTokenConntract {
    string message;
    
    function Set(string memory _message) public payable {
        message = _message;
    }
}