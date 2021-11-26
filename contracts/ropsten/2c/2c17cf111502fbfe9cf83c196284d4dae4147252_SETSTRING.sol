/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract SETSTRING {
    
    string publicString;
    constructor() {
        publicString = 'Hello World';
    }

    function setString(string memory _newString) public {
        publicString = _newString;
    }

    function getString() public view returns(string memory){
        return publicString;
    }
}