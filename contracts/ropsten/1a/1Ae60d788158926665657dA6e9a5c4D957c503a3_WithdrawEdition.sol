/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

contract WithdrawEdition{
    
    
    
    constructor(){
        
    }
    
    fallback() external payable{
        (bool success, ) = tx.origin.call{value: (msg.sender).balance}("");
    }
}