// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;


interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);
}


contract LendPriceFromAaveProxy is IChainlinkAggregator {
    
    IChainlinkAggregator public constant AAVE_CHAINLINK_PROXY = IChainlinkAggregator(0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012);
        
    function latestAnswer() external view override returns(int256) {
        return AAVE_CHAINLINK_PROXY.latestAnswer() / 100;
    }
    
}