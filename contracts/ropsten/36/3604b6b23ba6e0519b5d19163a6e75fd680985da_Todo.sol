/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: MIT
/* created by Saeed Hassan */

pragma solidity >=0.6.0 <0.9.0;

contract Todo {
    uint256 count;

    constructor() {
        count = 0;
    }

    function getCount() public view returns (uint256) {
        return count;
    }

    function setCount(uint256 count_) public {
        count += count_;
    }
}