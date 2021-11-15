/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;


struct Timestamp {
    bytes32 hash;
    uint timestamp;
}


contract TimestampDB {
    address     public immutable owner;
    Timestamp[] public           timestamps;
    
    constructor() {
        owner = msg.sender;
    }

    function append(bytes32 hash) external {
        timestamps.push(Timestamp({
            hash: hash,
            timestamp: block.timestamp
        }));
    }
}