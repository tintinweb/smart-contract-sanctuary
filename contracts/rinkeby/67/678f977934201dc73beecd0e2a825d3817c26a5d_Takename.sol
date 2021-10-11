/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: UNLICENSED
// File: Takename.sol


pragma solidity ^0.8.0;
contract Takename
{   
    uint nextID;
    constructor()
    {
        nextID=0;
    }
    struct D
    {
        uint id ;
        string name;
    }
    D[]d ;
    function letStore (string memory _name) public
    {
        d.push(D({id:nextID,name:_name}));
        nextID++;
 
    }
    function see() public view returns(D[] memory)
    {
        return d;
    }
}