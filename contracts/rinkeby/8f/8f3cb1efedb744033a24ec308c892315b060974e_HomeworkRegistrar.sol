// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

import "./Registerer.sol";

contract HomeworkRegistrar {
    mapping(string => bool) private registered;
    
    address owner = 0x0B41892C365Bd2283c41e023532403bFf58b80A3;
    
    function registerHW(Registerer _registerer) external payable {
        require(msg.value == 1 ether);
        
        string memory studentName = _registerer.registerMe();
        
        require(registered[studentName] == false, "already registered");
        
        registered[studentName] = true;
    }
    
    function withdraw(uint amount) external {
        require(msg.sender == owner, "you are not the owner");
        msg.sender.transfer(amount);
    }
    
    function isRegistered(string memory name) external view returns(bool) {
        require(msg.sender == owner, "you are not the owner");
        return registered[name];
    }
}