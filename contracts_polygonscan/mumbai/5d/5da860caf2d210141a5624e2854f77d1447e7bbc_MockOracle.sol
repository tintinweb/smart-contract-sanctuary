/**
 *Submitted for verification at polygonscan.com on 2021-12-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MockOracle {
    uint80 public roundId;
    int256 public price;

    constructor() {
        roundId = 0;
        price = 0;
    }

    function setPrice(int256 _price) public {
        roundId = roundId + 1;
        price = _price;
    }

    function latestRoundData() public view returns(uint80, int256, uint256, uint256, uint80) {
        return (roundId, price, block.timestamp, block.timestamp, roundId);
    }
}