/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

contract Demo_20211017 {
    
    string text;
    
    function setText (string calldata _text) public {
        text = _text;
    }
    
    function getText () public view returns (string memory){
        return text;
    }
}