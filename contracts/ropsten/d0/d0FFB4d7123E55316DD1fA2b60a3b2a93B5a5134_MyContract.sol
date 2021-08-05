/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MyContract {
    event MyEvent (
        uint indexed eventId,
        uint indexed date,
        string indexed value
    );
    uint nextId;

    function emitEvent (string calldata value) external{
        emit MyEvent(nextId,block.timestamp,value);
        nextId++;
    }
}