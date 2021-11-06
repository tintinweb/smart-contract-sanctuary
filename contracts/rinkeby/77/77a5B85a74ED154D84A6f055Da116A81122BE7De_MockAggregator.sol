// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract MockAggregator {
    uint256 lastAnswer;

    function setLatestAnswer(uint256 answer) public {
        lastAnswer = answer;
    }

    function latestAnswer() public view returns (uint256) {
        return lastAnswer;
    }
}