// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// Chainlink Aggregator
interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}


interface IExchangeRateFeeder {
    function exchangeRateOf(
        address _token,
        bool _simulate
    ) external view returns (uint256);
}

contract aUSTOracle is IExchangeRateFeeder {
    IAggregator public constant aUST = IAggregator(0x73bB8A4220E5C7Db3E73e4Fcb8d7DCf2efe04805);
    function exchangeRateOf(address, bool) external view returns (uint256) {
        return uint256(aUST.latestAnswer());
    }
}