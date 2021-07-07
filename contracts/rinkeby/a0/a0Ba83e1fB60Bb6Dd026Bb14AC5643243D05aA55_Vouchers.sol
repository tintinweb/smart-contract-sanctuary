/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract Vouchers {
    
    mapping (address => uint) public saldi;
    
    function transfer (address destinatario, uint quanti) public {
        // aumenta il saldo del destinatario di "quanti"
        saldi[destinatario] += quanti;
        // diminuisci il saldo del mittente di "quanti"
        saldi[msg.sender] -= quanti;
    } 
    
}