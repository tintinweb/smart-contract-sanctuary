/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;



// Part: IChainLinkFeed

interface IChainLinkFeed {
    function latestAnswer() external view returns (int256);
}

// File: MockChainLinkOracle.sol

/**
 * @dev
 */
contract MockChainLinkOracle is IChainLinkFeed {

    int256 public gasPrice;

    constructor() {
        gasPrice = 130000;
    }

    function setGasPrice(int256 newPrice) external {
        gasPrice = newPrice;
    }

    function latestAnswer() external view override returns (int256) {
        return gasPrice;
    }

}