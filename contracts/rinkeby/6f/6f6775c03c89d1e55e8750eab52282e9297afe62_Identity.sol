/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract Identity
{
    string name;
    uint age;
    
    constructor()
    {
        name = "Ali";
        age = 19;
    }
    
    function getName() view public returns(string memory)
    {
        return name;
    }
    
    function getAge() view public returns(uint)
    {
        return age;
    }
    
    function setAge() public
    {
        age = age + 1;
    }
    
    function setName() public
    {
        name = "Ali Hassan";
    }
}