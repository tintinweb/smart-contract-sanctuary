/**
 *Submitted for verification at polygonscan.com on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.8.7;

contract to_exclude {
    
    event Mensage(string mensage);
    
    uint256 public limit = block.timestamp+10;
    bool public isclaimable = true;
    
    function update() external {
        require(isclaimable, "Sua chance passou");
        if (block.timestamp > limit){
            isclaimable = false;
            emit Mensage("Obrigado por contrinuir com o projeto");
            return;
        }
    }
        
}