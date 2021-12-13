/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
    contract HashLock {
        bytes32 public constant hashLock = bytes32(0xC23546A58B36D4568EF7CE399D4D78BA418CD732FC2F62E500C7693CA1343375);
        receive() external payable {}
        function claim(string memory _WhatIsTheMagicKey) public {
            require(sha256(abi.encodePacked(_WhatIsTheMagicKey)) == hashLock);
            selfdestruct(msg.sender);
        }
    }