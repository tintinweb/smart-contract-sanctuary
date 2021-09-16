/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract WriteInTheBlockchain{
    string text;
    
    function Write(string calldata _text) public{
        text = _text;
    }
    
    function Leer() public view returns(string memory){
        return text;
    }
}