/**
 *Submitted for verification at polygonscan.com on 2021-08-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
contract Bribe {
    function bribe() payable public {
        block.coinbase.transfer(msg.value);
    }
}