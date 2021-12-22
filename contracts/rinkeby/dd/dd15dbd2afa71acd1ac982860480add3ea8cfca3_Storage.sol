/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    event RewardDistributed(address indexed triggerUser, uint256 rewardAmount);

    constructor() {
        number = 0;
    }

    function rewardDistribute(uint256 rewardAmount) public {
        number = number + rewardAmount;
        emit RewardDistributed(tx.origin, rewardAmount);
    }

}