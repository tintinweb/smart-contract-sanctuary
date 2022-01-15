/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// File: EventEmitter.sol

contract EventEmitter {
    event ContractCreated();
    event CallEvent(address sender);

    constructor() {
        emit ContractCreated();
    }

    function triggerEvent() public {
        emit CallEvent(msg.sender);
    }
}