/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Math {

    uint256 private count;
    
    constructor() {
        count = 0;
    }

    function addCount(uint256 num) public{
        count += num;
    }

    function subCount(uint256 num) public{
        count -= num;
    }
}