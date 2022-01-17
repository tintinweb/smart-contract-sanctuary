/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0 < 0.9.0;

contract Taxes {
    
    uint tax_percentage = 10;
    address payable tax_collector = payable (0x1EA29e2604540A7d0561E43D6c975a177F4aFC68);
    
    function pay (address payable beneficiary) payable public {
        uint tax = msg.value * tax_percentage / 100;
        beneficiary.transfer(msg.value - tax);
        tax_collector.transfer(tax);
        }
}