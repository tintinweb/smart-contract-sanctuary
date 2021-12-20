/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract test{
    address private owner;    
    uint c=0;
    constructor(){
        owner=msg.sender;
    }

    function getowner() public view returns(address)
    {
        return owner;
    }

    function addtion(uint a, uint b) public{
        c=a+b;       
    }
    function subtract(uint a, uint b) public{
        c=a-b;       
    }
     function divided(uint a, uint b) public{
        c=a/b;       
    }
    function modof(uint a, uint b) public{
       c=a%b;       
    }
    
    function getresult() public view returns(uint){
       return c;
    }
}