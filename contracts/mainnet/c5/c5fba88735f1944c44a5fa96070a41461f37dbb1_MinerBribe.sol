// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MinerBribe {
    function bribe() payable public {
        block.coinbase.transfer(msg.value);
    }
}

