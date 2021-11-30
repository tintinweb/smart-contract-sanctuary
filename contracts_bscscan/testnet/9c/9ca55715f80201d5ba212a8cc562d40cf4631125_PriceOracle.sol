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
pragma experimental ABIEncoderV2;

import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IBookKeeper.sol";
import "./IPriceFeed.sol";
import "./IPriceOracle.sol";
import "./ICagable.sol";
import "./ICollateralPoolConfig.sol";

/// @title PriceOracle
/// @author Alpaca Fin Corporation
/** @notice A contract which is the price oracle of the BookKeeper to keep all collateral pools updated with the latest price of the collateral.
    The price oracle is important in reflecting the current state of the market price.
*/

contract PriceOracle is PausableUpgradeable, ReentrancyGuardUpgradeable, IPriceOracle, ICagable {
  // --- Data ---
  struct CollateralPool {
    IPriceFeed priceFeed; // Price Feed
    uint256 liquidationRatio; // Liquidation ratio or Collateral ratio [ray]
  }

  IBookKeeper public bookKeeper; // CDP Engine
  uint256 public override stableCoinReferencePrice; // ref per AUSD [ray] :: value of stablecoin in the reference asset (e.g. $1 per Alpaca USD)

  uint256 public live;

  // --- Events ---
  event LogSetPrice(
    bytes32 _poolId,
    bytes32 _rawPrice, // Raw price from price feed [wad]
    uint256 _priceWithSafetyMargin // Price with safety margin [ray]
  );

  // --- Init ---
  function initialize(address _bookKeeper) external initializer {
    PausableUpgradeable.__Pausable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    IBookKeeper(_bookKeeper).collateralPoolConfig(); // Sanity check call
    bookKeeper = IBookKeeper(_bookKeeper);
    stableCoinReferencePrice = ONE;
    live = 1;
  }

  // --- Math ---
  uint256 constant ONE = 10**27;

  function mul(uint256 _x, uint256 _y) internal pure returns (uint256 _z) {
    require(_y == 0 || (_z = _x * _y) / _y == _x);
  }

  function rdiv(uint256 _x, uint256 _y) internal pure returns (uint256 _z) {
    _z = mul(_x, ONE) / _y;
  }

  // --- Administration ---
  event LogSetStableCoinReferencePrice(address indexed _caller, uint256 _data);

  function setStableCoinReferencePrice(uint256 _data) external {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(bookKeeper.accessControlConfig());
    require(_accessControlConfig.hasRole(_accessControlConfig.OWNER_ROLE(), msg.sender), "!ownerRole");
    require(live == 1, "PriceOracle/not-live");
    stableCoinReferencePrice = _data;
    emit LogSetStableCoinReferencePrice(msg.sender, _data);
  }

  // --- Update value ---
  /// @dev Update the latest price with safety margin of the collateral pool to the BookKeeper
  /// @param _collateralPoolId Collateral pool id
  function setPrice(bytes32 _collateralPoolId) external whenNotPaused {
    IPriceFeed _priceFeed = IPriceFeed(
      ICollateralPoolConfig(bookKeeper.collateralPoolConfig()).collateralPools(_collateralPoolId).priceFeed
    );
    uint256 _liquidationRatio = ICollateralPoolConfig(bookKeeper.collateralPoolConfig()).getLiquidationRatio(
      _collateralPoolId
    );
    (bytes32 _rawPrice, bool _hasPrice) = _priceFeed.peekPrice();
    uint256 _priceWithSafetyMargin = _hasPrice
      ? rdiv(rdiv(mul(uint256(_rawPrice), 10**9), stableCoinReferencePrice), _liquidationRatio)
      : 0;
    address _collateralPoolConfig = address(bookKeeper.collateralPoolConfig());
    ICollateralPoolConfig(_collateralPoolConfig).setPriceWithSafetyMargin(_collateralPoolId, _priceWithSafetyMargin);
    emit LogSetPrice(_collateralPoolId, _rawPrice, _priceWithSafetyMargin);
  }

  function cage() external override {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(IBookKeeper(bookKeeper).accessControlConfig());
    require(
      _accessControlConfig.hasRole(_accessControlConfig.OWNER_ROLE(), msg.sender) ||
        _accessControlConfig.hasRole(_accessControlConfig.SHOW_STOPPER_ROLE(), msg.sender),
      "!(ownerRole or showStopperRole)"
    );
    require(live == 1, "PriceOracle/not-live");
    live = 0;
    emit LogCage();
  }

  function uncage() external override {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(IBookKeeper(bookKeeper).accessControlConfig());
    require(
      _accessControlConfig.hasRole(_accessControlConfig.OWNER_ROLE(), msg.sender) ||
        _accessControlConfig.hasRole(_accessControlConfig.SHOW_STOPPER_ROLE(), msg.sender),
      "!(ownerRole or showStopperRole)"
    );
    require(live == 0, "PriceOracle/not-caged");
    live = 1;
    emit LogUncage();
  }

  // --- pause ---
  function pause() external {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(IBookKeeper(bookKeeper).accessControlConfig());
    require(
      _accessControlConfig.hasRole(_accessControlConfig.OWNER_ROLE(), msg.sender) ||
        _accessControlConfig.hasRole(_accessControlConfig.GOV_ROLE(), msg.sender),
      "!(ownerRole or govRole)"
    );
    _pause();
  }

  function unpause() external {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(IBookKeeper(bookKeeper).accessControlConfig());
    require(
      _accessControlConfig.hasRole(_accessControlConfig.OWNER_ROLE(), msg.sender) ||
        _accessControlConfig.hasRole(_accessControlConfig.GOV_ROLE(), msg.sender),
      "!(ownerRole or govRole)"
    );
    _unpause();
  }
}