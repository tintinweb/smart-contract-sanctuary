/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

contract IlliniBlockchainDevTask {

    event Task(string data, address sender, address origin);

    bytes public publicKey;

    constructor(bytes memory _publicKey) {
        publicKey = _publicKey;
    }

    function sendTask(string calldata data) public {
        require(msg.sender != tx.origin, "Must apply from a smart contract!");
        emit Task(data, msg.sender, tx.origin);
    }

}