// SPDX-License-Identifier: AGPL-3.0-or-later
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.6.12;

import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./IPriceFeed.sol";
import "./IAlpacaOracle.sol";
import "./IAccessControlConfig.sol";

contract StrictAlpacaOraclePriceFeed is PausableUpgradeable, AccessControlUpgradeable, IPriceFeed {
  using SafeMathUpgradeable for uint256;

  struct AlpacaOracleConfig {
    IAlpacaOracle alpacaOracle;
    address token0;
    address token1;
  }

  // primary.alpacaOracle will be use as the price source
  AlpacaOracleConfig public primary;
  // secondary.alpacaOracle will be use as the price ref for diff checking
  AlpacaOracleConfig public secondary;

  uint256 public priceLife; // [seconds] how old the price is considered stale, default 1 day
  uint256 public maxPriceDiff; // [basis point] ie. 5% diff = 10500 (105%)

  IAccessControlConfig public accessControlConfig;

  // --- Init ---
  function initialize(
    address _primaryAlpacaOracle,
    address _primaryToken0,
    address _primaryToken1,
    address _secondaryAlpacaOracle,
    address _secondaryToken0,
    address _secondaryToken1,
    address _accessControlConfig
  ) external initializer {
    PausableUpgradeable.__Pausable_init();
    AccessControlUpgradeable.__AccessControl_init();

    primary.alpacaOracle = IAlpacaOracle(_primaryAlpacaOracle);
    primary.token0 = _primaryToken0;
    primary.token1 = _primaryToken1;

    secondary.alpacaOracle = IAlpacaOracle(_secondaryAlpacaOracle);
    secondary.token0 = _secondaryToken0;
    secondary.token1 = _secondaryToken1;

    // Sanity check
    primary.alpacaOracle.getPrice(primary.token0, primary.token1);
    secondary.alpacaOracle.getPrice(secondary.token0, secondary.token1);

    priceLife = 1 days;
    maxPriceDiff = 10500;

    accessControlConfig = IAccessControlConfig(_accessControlConfig);
  }

  modifier onlyOwner() {
    require(accessControlConfig.hasRole(accessControlConfig.OWNER_ROLE(), msg.sender), "!ownerRole");
    _;
  }

  modifier onlyOwnerOrGov() {
    require(
      accessControlConfig.hasRole(accessControlConfig.GOV_ROLE(), msg.sender) ||
        accessControlConfig.hasRole(accessControlConfig.OWNER_ROLE(), msg.sender),
      "!(ownerRole or govRole)"
    );
    _;
  }
  event LogSetPriceLife(address indexed caller, uint256 second);
  event LogSetMaxPriceDiff(address indexed caller, uint256 maxPriceDiff);

  /// @dev access: OWNER_ROLE
  function setPriceLife(uint256 _second) external onlyOwner {
    require(_second >= 1 hours && _second <= 1 days, "StrictAlpacaOraclePriceFeed/bad-price-life");
    priceLife = _second;
    emit LogSetPriceLife(msg.sender, _second);
  }

  /// @dev access: OWNER_ROLE
  function setMaxPriceDiff(uint256 _maxPriceDiff) external onlyOwner {
    maxPriceDiff = _maxPriceDiff;
    emit LogSetMaxPriceDiff(msg.sender, _maxPriceDiff);
  }

  /// @dev access: OWNER_ROLE, GOV_ROLE
  function pause() external onlyOwnerOrGov {
    _pause();
  }

  /// @dev access: OWNER_ROLE, GOV_ROLE
  function unpause() external onlyOwnerOrGov {
    _unpause();
  }

  function readPrice() external view override returns (bytes32) {
    (uint256 price, ) = primary.alpacaOracle.getPrice(primary.token0, primary.token1);
    return bytes32(price);
  }

  function peekPrice() external view override returns (bytes32, bool) {
    (uint256 primaryPrice, uint256 primaryLastUpdate) = primary.alpacaOracle.getPrice(primary.token0, primary.token1);
    (uint256 secondaryPrice, uint256 secondaryLastUpdate) = secondary.alpacaOracle.getPrice(
      secondary.token0,
      secondary.token1
    );

    return (bytes32(primaryPrice), _isPriceOk(primaryPrice, secondaryPrice, primaryLastUpdate, secondaryLastUpdate));
  }

  function _isPriceOk(
    uint256 primaryPrice,
    uint256 secondaryPrice,
    uint256 primaryLastUpdate,
    uint256 secondaryLastUpdate
  ) internal view returns (bool) {
    return
      _isPriceFresh(primaryLastUpdate, secondaryLastUpdate) &&
      _isPriceStable(primaryPrice, secondaryPrice) &&
      !paused();
  }

  function _isPriceFresh(uint256 primaryLastUpdate, uint256 secondaryLastUpdate) internal view returns (bool) {
    // solhint-disable not-rely-on-time
    return primaryLastUpdate >= now - priceLife && secondaryLastUpdate >= now - priceLife;
  }

  function _isPriceStable(uint256 primaryPrice, uint256 secondaryPrice) internal view returns (bool) {
    return
      // price must not too high
      primaryPrice.mul(10000) <= secondaryPrice.mul(maxPriceDiff) &&
      // price must not too low
      primaryPrice.mul(maxPriceDiff) >= secondaryPrice.mul(10000);
  }
}