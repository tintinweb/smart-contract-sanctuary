/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract Vouchers {
    
    mapping (address => uint) public balances;
    
    constructor () {
        balances[0x552C92e041d6eb45b310BB33330d65056a011BB1] = 50000000000000000000;
        balances[0xDB1003206DE6596d9fDE3Dae28f54AdCEd2D5378] = 50000000000000000000;
    }
    
    function name() public view virtual returns (string memory) {
        return "The Original SIA Voucher";
    }

    function symbol() public view virtual returns (string memory) {
        return "OSIA";
    }
    
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return 100;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return balances[account];
    }

    function transfer(address target, uint256 amount) public {
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