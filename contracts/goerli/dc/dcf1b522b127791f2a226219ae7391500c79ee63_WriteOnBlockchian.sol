/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract WriteOnBlockchian{
    string text;
    
    function write(string calldata _text) public {
        text = _text;
    }
    
    function read() public view returns(string memory){
        return text;
    }
}