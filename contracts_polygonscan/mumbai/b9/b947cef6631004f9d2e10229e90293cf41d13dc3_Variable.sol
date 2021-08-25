/**
 *Submitted for verification at polygonscan.com on 2021-08-24
*/

/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma solidity 0.8.6;


contract Variable {
    
    uint16 public overflow = 256;
    
    string private variable = 'Data variable';
    
    function setVariable (string memory value) public {
        
        variable = value;
    }
    
    function getVariable () public view returns (string memory) {
        
        return variable;
    }
    
}