// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract MockUsdOracle {
    constructor() {}

    function latestAnswer() external view returns (int256) {
        return 2500 * 10 ** 6;
    }
}