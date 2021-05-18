/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Bank{
    string text;
    
    function set(string memory _text)public returns(bool){
        text = _text;
        return true;
    }
    
    function get()public view returns(string memory){
        return text;
    }
}