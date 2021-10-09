/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.7.6;

contract Bridge{
    struct cbInfo {
        uint256 fromChainID;
        address fromContract;
        string eventName;
        uint256 startBlock;
    }

    event Subscription(uint256 fromChainID, address fromContract, string eventName, uint256 startBlock);

    function subscribe(
        uint256 fromChainID,
        address fromContract,
        string memory eventName,
        uint256 startBlock
    ) external {
        emit Subscription(fromChainID, fromContract, eventName, startBlock);
    }
}