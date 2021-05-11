/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.1;

contract WhichBlock {
    event CHAINID(uint);
    event COINBASE(address);
    event DIFFICULTY(uint);
    event GASLIMIT(uint);
    event NUMBER(uint);
    event TIMESTAMP(uint);
    event BLOCKHASH(uint, bytes32);

    constructor() {
        emit CHAINID(block.chainid);
        emit COINBASE(block.coinbase);
        emit DIFFICULTY(block.difficulty);
        emit GASLIMIT(block.gaslimit);
        emit NUMBER(block.number);
        emit TIMESTAMP(block.timestamp);

        emit BLOCKHASH(block.number, blockhash(block.number));
        emit BLOCKHASH(block.number - 1, blockhash(block.number -1));
    }
}