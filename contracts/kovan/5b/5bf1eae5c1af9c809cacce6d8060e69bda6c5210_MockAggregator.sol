/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.1;

contract MockAggregator {
    int256 priceE8 = 2500 * 10**8;

    function latestAnswer() external view returns (int256) {
        return priceE8;
    }

    function changePrice(int256 newPrice) external {
        priceE8 = newPrice;
    }
}