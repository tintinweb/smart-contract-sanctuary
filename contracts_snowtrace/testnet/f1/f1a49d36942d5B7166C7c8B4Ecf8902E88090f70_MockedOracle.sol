// SPDX-License-Identifier: XXX
pragma solidity ^0.8.0;

contract MockedOracle {
    function getEthPriceInTokens() external pure returns (uint) {
        return 4000 * 1e6;
    }
}