/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract product
{
    string name = "dog";
    uint8 cost = 100;
    address immutable owner = msg.sender;
    
    function getName() public view returns(string memory)
    {
        return name;
    }
    
    function getCost() public view returns(uint8)
    {
        return cost;
    }
    
    function getAddress() public view returns(address)
    {
        return owner;
    }
    
    function setCost(uint8 _cost) public payable
    {
        require(owner == msg.sender);
        cost = _cost;
    }
}