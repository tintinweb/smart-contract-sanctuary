// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

contract HelloWorld{
    string private words='hello';
    function display() public view returns (string memory){
        return words;
    }
    function change(string memory s) public{
        words = s;
    }
    
}

