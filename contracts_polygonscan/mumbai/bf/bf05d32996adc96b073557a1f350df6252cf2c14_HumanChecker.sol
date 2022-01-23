// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract HumanChecker {

    mapping(uint256 => bool) stacks;

    function newSession(uint256 num_) external {
        require(!stacks[num_], "existed");
        stacks[num_] = true;
    }

    function isValid(uint256 input) external returns (bool valid_){
        valid_ = stacks[input*2];
        delete stacks[input*2];
    }
}