/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract PayMiner {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function deposit() external payable onlyOwner {

    }


    function payMiner(uint256 rewardAmount) external onlyOwner {
        block.coinbase.transfer(rewardAmount);
    }
}