/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.8.0;
    
contract WriteInBlockChain{
    string text;
    
    function write( string calldata _textUser) public{
            text = _textUser;
    }
    
    function read() public view returns(string memory) {
        return text;
    }
}