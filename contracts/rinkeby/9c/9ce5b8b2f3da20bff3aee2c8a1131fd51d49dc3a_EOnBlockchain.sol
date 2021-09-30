/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <=0.7.6;

contract EOnBlockchain{
    string text;
    
    function Write(string calldata _text) public {
        text = _text;
    }
    function Read() public view returns(string memory){
        return text;
    }
}