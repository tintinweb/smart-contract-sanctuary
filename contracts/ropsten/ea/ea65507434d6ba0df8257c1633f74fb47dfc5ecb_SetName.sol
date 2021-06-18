/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract SetName {
    
    string name;
    
    string[] public names; 
    
    mapping (address => string) public AddressToName;
    
    function SetNewName(string memory _name) public returns (bool) {
        name = _name;
        names.push(name);
        AddressToName[msg.sender] = _name;
        return true;
    }
    
    function GetName() public view returns (string memory) {
        return name;
    }
    
    function GetNameByNumber(uint256 _number) public view returns (string memory) {
        return names[_number];
    }
    
}