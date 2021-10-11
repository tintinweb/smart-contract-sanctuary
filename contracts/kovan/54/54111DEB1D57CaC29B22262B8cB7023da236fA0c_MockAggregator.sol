// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract MockAggregator {
    int256 internal _answer;

    function setAnswer(int256 _a) external {
        _answer = _a;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return (0, _answer, 0, 0, 0);
    }
}