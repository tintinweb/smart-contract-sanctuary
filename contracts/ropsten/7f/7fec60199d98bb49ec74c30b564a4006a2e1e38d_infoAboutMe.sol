/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract infoAboutMe
{
    string name;
    string info;
    address immutable owner;
    
    constructor (string memory _name, string memory _info)
    {
        name = _name;
        info = _info;
        owner = msg.sender;
    }
    function getName() public view returns(string memory)
    {
        return name;
    }
    function getInfo() public view returns(string memory)
    {
        return info;
    }
    
    modifier OwnerOnly {
    require(msg.sender == owner, "sry but ure not owner");
    _;
    }
    
    function setInfo(string memory _info) public OwnerOnly
    { 
      info = _info;
    }
    function setName(string memory _name) public OwnerOnly
    { 
      name = _name;
    }
}