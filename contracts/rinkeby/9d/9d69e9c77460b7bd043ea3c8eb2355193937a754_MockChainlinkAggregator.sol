/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-02-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

contract MockChainlinkAggregator {
    int256 public price;

    constructor(int256 mockPrice) public {
        price = mockPrice;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (uint80(0), price, uint256(0), uint256(0), uint80(0));
    }

    function setPrice(int256 mockPrice) public {
        price = mockPrice;
    }
    
    function decimals() pure public returns(uint8) {
        return 18;
    }
}