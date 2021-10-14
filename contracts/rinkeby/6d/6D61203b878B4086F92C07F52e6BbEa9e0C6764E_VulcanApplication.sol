/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulcanApplication {
    event Application(bytes data, address indexed sender, address indexed origin);

    string public name;
    string public publicKey;

    constructor(string memory _name, string memory _publicKey) {
        name = _name;
        publicKey = _publicKey;
    }

    function sendApplication(bytes calldata data) public {
        require(msg.sender != tx.origin, 'Must apply from a smart contract!');
        emit Application(data, msg.sender, tx.origin);
    }
}