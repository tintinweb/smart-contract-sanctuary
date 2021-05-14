/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract WriteBlockchain {
    string text;
    
    function write(string calldata _text) public {
        text = _text;
    }
    
    function read() public view returns (string memory) {
        return text;
    }
}