/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Article {
    
    string public str = "";
    address public author;
    
    constructor(string memory _str) {
        str = _str;
        author = msg.sender;
    }
    
}