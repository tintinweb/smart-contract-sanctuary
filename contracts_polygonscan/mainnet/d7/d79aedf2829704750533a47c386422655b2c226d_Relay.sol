/**
 *Submitted for verification at polygonscan.com on 2021-08-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Relay {
    event Message(address from, string ipfs_hash);

    function message(string memory ipfs_hash) public {
        emit Message(msg.sender, ipfs_hash);
    }
}