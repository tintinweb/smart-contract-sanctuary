/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    string _message;
    constructor(string memory message) {
        _message = message;
    }
    
    function ShowMessage() public view returns (string memory){
        return _message;
    }
    
    function Hello() public pure returns(string memory) {
        return "Hello World";
    }
 }