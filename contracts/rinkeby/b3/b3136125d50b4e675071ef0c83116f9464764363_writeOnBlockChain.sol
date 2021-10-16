/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0 < 0.9.0;

contract writeOnBlockChain {
    string text;
    
    function write(string calldata _text) public {
        text = _text;
    }
    
    function read() public view returns (string memory) {
        return text;
    }
}