/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.8.1;

contract WriteOnBlockchain{
    string text;

    function Write(string calldata _text) public{
        text = _text;
    }

    function Read() public view returns(string memory){
        return text;
    }
}