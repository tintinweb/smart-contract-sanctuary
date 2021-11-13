// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title IPriceOracle
 * @author Aave
 * @notice Defines the basic interface for a Price oracle.
 **/
interface IPriceOracle {
  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);

  /**
   * @notice Set the price of the asset
   * @param asset The address of the asset
   * @param price The price of the asset
   **/
  function setAssetPrice(address asset, uint256 price) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {IPriceOracle} from '../../interfaces/IPriceOracle.sol';

contract PriceOracle is IPriceOracle {
  mapping(address => uint256) prices;
  uint256 ethPriceUsd;

  event AssetPriceUpdated(address _asset, uint256 _price, uint256 timestamp);
  event EthPriceUpdated(uint256 _price, uint256 timestamp);

  function getAssetPrice(address _asset) external view override returns (uint256) {
    return prices[_asset];
  }

  function setAssetPrice(address _asset, uint256 _price) external override {
    prices[_asset] = _price;
    emit AssetPriceUpdated(_asset, _price, block.timestamp);
  }

  function getEthUsdPrice() external view returns (uint256) {
    return ethPriceUsd;
  }

  function setEthUsdPrice(uint256 _price) external {
    ethPriceUsd = _price;
    emit EthPriceUpdated(_price, block.timestamp);
  }
}