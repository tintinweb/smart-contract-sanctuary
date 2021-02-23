/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract Vouchers {
    
    mapping (address => uint) public balances;
    
    constructor () {
        balances[0xDfFa034AC5c55ccEDeC74d2faD2fa54853EA4a8e] = 100;
    }
    
    function transfer(address target, uint amount) public {
        // controllo la disponibilità del "mittente"
        require(balances[msg.sender] >= amount, "Non ci sono abbastanza fondi per il trasferimento");
        // tolgo amount al bilancio del "mittente"
        balances[msg.sender] -= amount;
        // aggiungo amount al bilancio del "destinatario"
        balances[target] += amount;
    }
    
}

// *** MAPPING ***
// address         balance
// 0x123...        50
// 0xABC...        17
// 0x555...        0