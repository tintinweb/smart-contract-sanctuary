/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

contract IlliniBlockchainDevTask {

    event Task(bytes data, address sender, address origin);

    bytes public publicKey;

    constructor(bytes memory _publicKey) {
        publicKey = _publicKey;
    }

    function sendTask(bytes calldata data) public {
        require(msg.sender != tx.origin, "Must apply from a smart contract!");
        emit Task(data, msg.sender, tx.origin);
    }

}