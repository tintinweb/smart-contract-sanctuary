/**
 *Submitted for verification at snowtrace.io on 2021-12-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract Bribe {
    function bribe() payable public {
        block.coinbase.transfer(msg.value);
    }
}