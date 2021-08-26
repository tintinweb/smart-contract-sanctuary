/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.4.18;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Attack {
   
    function deposit() payable public{
        
    }
    
    function attack(address att) public {
        selfdestruct(att);
    }
}