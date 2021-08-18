// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

contract TestAggregator {
    string public name;
    uint public price;
    uint public decimals;
    constructor (string memory name_, uint decimals_, uint price_) public {
        name = name_;
        decimals = decimals_;
        price = price_;
    }
    function setPrice(uint price_) external{
        price = price_;
    }
    function latestRoundData() external view returns(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ){
        return (0, int256(price), 0, 0, 0);
    }
}