/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0 < 0.9.0;

contract WriteOnBlockchain {
    
    string text;
    
    function Write(string calldata _text) public {
        text = _text;
    }
    
    function Read() public view returns(string memory) {
        return text;
    }
    
}