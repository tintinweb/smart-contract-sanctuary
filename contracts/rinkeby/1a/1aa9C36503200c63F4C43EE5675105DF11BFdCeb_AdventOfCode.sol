/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


contract AdventOfCode {
    function day1(uint32 [] memory nums) pure public returns(uint32, uint32) {
        uint32 ans1 = 0;
        uint32 ans2 = 0;
        for (uint i = 0; i < nums.length - 1; i++) {
            if (nums[i] < nums[i + 1])
                ans1 += 1;
            if (i + 3 < nums.length && nums[i] < nums[i + 3])
                ans2 += 1;
        }
        return (ans1, ans2);
    }

    function day1part1(uint32 [] memory nums) pure public returns(uint32) {
        uint32 ans = 0;
        for (uint i = 0; i < nums.length - 1; i++) {
            if (nums[i] < nums[i + 1])
                ans += 1;
        }
        return ans;
    }

    function day1part2(uint32 [] memory nums) pure public returns(uint32) {
        uint32 ans = 0;
        for (uint i = 0; i < nums.length - 3; i++) {
            if (nums[i] < nums[i + 3])
                ans += 1;
        }
        return ans;
    }

    function day1bigboy(uint32 [] memory nums) payable public returns(uint32, uint32) {
        uint32 ans1 = 0;
        uint32 ans2 = 0;
        for (uint i = 0; i < nums.length - 1; i++) {
            if (nums[i] < nums[i + 1])
                ans1 += 1;
            if (i + 3 < nums.length && nums[i] < nums[i + 3])
                ans2 += 1;
        }
        return (ans1, ans2);
    }
}