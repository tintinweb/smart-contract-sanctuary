/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract HashDrop {
    struct Drop {
        string hash;
    }

    uint256 public numDrops = 0;
    mapping(uint256 => Drop) public idToDrop;
    mapping(string => address) public dropToAddress;
    mapping(address => Drop[]) public addressToDrops;

    function add(Drop calldata drop) public payable {
        idToDrop[numDrops] = drop;
        dropToAddress[drop.hash] = msg.sender;
        addressToDrops[msg.sender].push(drop);
        numDrops++;
        // TODO: send a little eth to my wallet
    }
}