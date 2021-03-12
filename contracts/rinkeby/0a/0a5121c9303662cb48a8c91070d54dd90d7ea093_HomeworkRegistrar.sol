// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

import "./Registerer.sol";

contract HomeworkRegistrar {
    mapping(string => bool) private registered;
    
    function registerHW(Registerer _registerer) external payable {
        require(msg.value == 1 ether);
        
        string memory studentName = _registerer.registerMe();
        
        require(registered[studentName] == false, "already registered");
        
        registered[studentName] = true;
    }
}