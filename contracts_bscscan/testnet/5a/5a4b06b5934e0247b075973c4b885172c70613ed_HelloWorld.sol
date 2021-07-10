/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.8.5;

contract HelloWorld
{
    string private yourName;
    
    constructor() 
    {
        yourName = "World";
    }
    
    function set(string memory name) public
    {
        yourName = name;
    }
    
    function hello() view public returns (string memory) 
    {
        return string(abi.encodePacked("Hello ", yourName));
    }
}