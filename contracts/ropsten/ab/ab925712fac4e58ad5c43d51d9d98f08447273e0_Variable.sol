/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma solidity 0.8.4;


contract Variable {
    
    string private variable = 'Example variable';
    
    function setVariable (string memory value) public {
        
        variable = value;
    }
    
    function getVariable () public view returns (string memory) {
        
        return variable;
    }
    
}