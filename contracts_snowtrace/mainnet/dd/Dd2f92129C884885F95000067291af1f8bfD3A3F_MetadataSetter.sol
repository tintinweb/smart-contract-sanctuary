/**
 *Submitted for verification at snowtrace.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


contract MetadataSetter {
   
    address private owner;
   

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address user) onlyOwner public{
        owner = user;
    }
   
    function setParam1(uint planetNo, string memory key, uint256 value) onlyNovaxGame public{
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        planet.setParam1(planetNo, key, value);
    }
   
    function setParam2(uint planetNo, string memory key, string memory value) onlyNovaxGame public{
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        planet.setParam2(planetNo, key, value);
    }
   
    function getOwner() public view returns (address)  {
        return owner;
    }

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
   
    modifier onlyNovaxGame() {

        Novax novax = Novax(0x7273A2B25B506cED8b60Eb3aA1eAE661a888b412);
        address gameAddress = novax.getParam3("game");
        address researchAddress = novax.getParam3("research");
        address warzoneAddress = novax.getParam3("warzone");
       
        require (gameAddress != address(0));
        require (researchAddress != address(0));
        require (warzoneAddress != address(0));
        require (msg.sender == gameAddress || msg.sender == researchAddress || msg.sender == warzoneAddress);
        _;
    }
   
}


contract Novax {
   
    function getParam3(string memory key) public view returns (address)  {}
   
}

contract Planet {
    function setParam1(uint planetId, string memory key, uint256 value)  public{  }
   
    function setParam2(uint planetId, string memory key, string memory value)  public{}
 
}