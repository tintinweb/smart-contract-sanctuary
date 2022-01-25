/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Greeting
{
    string name;
    address owner;

    constructor() 
    {
        owner = msg.sender;
    }

    function changeName(string memory _name) public returns(string memory)
    {
        require(owner == msg.sender,"Access Denied!!!");
            name= _name;
            return "ok";


    }

    function show() view public returns(string memory)
    {
        return name;
    }



}