/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.8 < 0.9.0;

contract Storage {
    uint256 num;

    function store(uint256 nums) public {
        num = nums;
    }

    function retrieve() public view returns (uint256) {
        return num;
    }
}