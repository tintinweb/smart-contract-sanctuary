// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;


interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);
}


contract GusdPriceProxy is IChainlinkAggregator {
    
    IChainlinkAggregator public constant ETH_USD_CHAINLINK_PROXY = IChainlinkAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    int256 public constant NORMALIZATION = 1e8 * 1 ether; // 8 decimals to normalized the format on the ETH/USD pair and multiplying by 1 ether to get the price in wei
        
    function latestAnswer() external view override returns(int256) {
        int256 priceFromChainlink = ETH_USD_CHAINLINK_PROXY.latestAnswer();
        
        return (priceFromChainlink <= 0)
            ? 0
            : NORMALIZATION / priceFromChainlink;
    }
    
}