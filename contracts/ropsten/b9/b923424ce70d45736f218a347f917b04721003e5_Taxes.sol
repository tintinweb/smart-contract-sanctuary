/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.9;

contract Taxes {

    uint tax_percentage = 10;
    address payable tax_collector = payable(0x934B80edC8ba22166DAC3A0AF994FE27C4eEa96C);

    function pay (address payable beneficiary) payable public {
        uint tax = msg.value * tax_percentage / 100;
        beneficiary.transfer(msg.value - tax);
        tax_collector.transfer(tax);
    }

}