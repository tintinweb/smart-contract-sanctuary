/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Apwars {

    address public person;
    mapping(address => string) public personName;
    
    
    function getName(address account) public view returns (string memory)
    {
        return personName[account];
    }
    
    function setName(string memory name) public
    {
        personName[msg.sender] = name;
    }

}