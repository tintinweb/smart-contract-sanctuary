/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract Voucher {

    mapping (address => uint) public balances;

    constructor () {
        balances[msg.sender] = 1000;
    }

    function transfer (address target, uint amount) public {
        require(balances[msg.sender] >= amount, "Non hai abbastanza voucher");
        balances[msg.sender] -= amount;
        balances[target] += amount;
    }

}