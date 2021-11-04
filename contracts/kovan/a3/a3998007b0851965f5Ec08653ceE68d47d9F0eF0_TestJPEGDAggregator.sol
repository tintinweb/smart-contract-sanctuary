// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../interfaces/IAggregatorV3Interface.sol";

// This contract is only for testing
contract TestJPEGDAggregator is IAggregatorV3Interface {
    int256 public override latestAnswer;

    constructor() {
        latestAnswer = 1e8;
    }

    function updateAnswer(int256 newAnswer) external {
        latestAnswer = newAnswer;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IAggregatorV3Interface {
    function latestAnswer() external view returns (int256 answer);
}