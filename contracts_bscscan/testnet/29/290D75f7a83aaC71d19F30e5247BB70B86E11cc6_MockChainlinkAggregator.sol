/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File src/_mock/oracle/MockChainlinkAggregator.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

contract MockChainlinkAggregator {
    int256 public mock_price;
    uint8 public mock_decimals;

    constructor(int256 _mock_price, uint8 _decimals) public {
        mock_price = _mock_price;
        mock_decimals = _decimals;
    }

    function decimals() external view returns (uint8) {
        return mock_decimals;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256 answer,
            uint256,
            uint256,
            uint80
        )
    {
        answer = mock_price;
    }

    function setLatestPrice(int256 _mock_price) public {
        mock_price = _mock_price;
    }

    function setDecimals(uint8 _decimals) public {
        mock_decimals = _decimals;
    }
}