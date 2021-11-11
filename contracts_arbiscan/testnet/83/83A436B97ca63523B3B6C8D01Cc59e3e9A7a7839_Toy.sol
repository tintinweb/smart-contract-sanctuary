/**
 *Submitted for verification at arbiscan.io on 2021-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
//pragma abicoder v2;

/**
 * @dev LP vesting, for staking with lock
 */
contract Toy {
    
    constructor() {}

    function readBlockTime() view external returns (uint) {
        return block.number;
    }

    function readBlockNumber() view external returns (uint) {
        return block.timestamp;
    }


}