/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract ReceiveEther {

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}