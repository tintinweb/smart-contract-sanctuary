/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract NumbaGoUp {

    uint256 private startBlock;

    constructor() {
        startBlock = block.number;
    }
    
    function numba() public view returns (uint256) {
        return block.number - startBlock;
    }
}