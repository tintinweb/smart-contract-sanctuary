/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
contract HashLock {
    bytes32 public constant hashLock = bytes32(0xC775E7B757EDE630CD0AA1113BD102661AB38829CA52A6422AB782862F268646);
    receive() external payable {}
    function claim(string memory _WhatIsTheMagicKey) public {
        require(sha256(abi.encodePacked(_WhatIsTheMagicKey)) == hashLock);
        selfdestruct(msg.sender);
    }
}