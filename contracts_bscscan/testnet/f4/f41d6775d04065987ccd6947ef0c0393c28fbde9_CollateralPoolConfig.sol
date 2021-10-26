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

import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./IPriceFeed.sol";
import "./IGenericTokenAdapter.sol";
import "./ICollateralPoolConfig.sol";
import "./ILiquidationStrategy.sol";
import "./IAccessControlConfig.sol";

contract CollateralPoolConfig is AccessControlUpgradeable, ICollateralPoolConfig {
  using SafeMathUpgradeable for uint256;

  uint256 constant RAY = 10**27;

  event LogSetPriceWithSafetyMargin(address indexed _caller, bytes32 _collateralPoolId, uint256 _priceWithSafetyMargin);
  event LogSetDebtCeiling(address indexed _caller, bytes32 _collateralPoolId, uint256 _debtCeiling);
  event LogSetDebtFloor(address indexed _caller, bytes32 _collateralPoolId, uint256 _debtFloor);
  event LogSetPriceFeed(address indexed _caller, bytes32 _poolId, address _priceFeed);
  event LogSetLiquidationRatio(address indexed _caller, bytes32 _poolId, uint256 _data);
  event LogSetStabilityFeeRate(address indexed _caller, bytes32 _poolId, uint256 _data);
  event LogSetAdapter(address indexed _caller, bytes32 _collateralPoolId, address _adapter);
  event LogSetCloseFactorBps(address indexed _caller, bytes32 _collateralPoolId, uint256 _closeFactorBps);
  event LogSetLiquidatorIncentiveBps(
    address indexed _caller,
    bytes32 _collateralPoolId,
    uint256 _liquidatorIncentiveBps
  );
  event LogSetTreasuryFeesBps(address indexed _caller, bytes32 _collateralPoolId, uint256 _treasuryFeeBps);
  event LogSetStrategy(address indexed _caller, bytes32 _collateralPoolId, address strategy);
  event LogSetTotalDebtShare(address indexed _caller, bytes32 _collateralPoolId, uint256 _totalDebtShare);
  event LogSetDebtAccumulatedRate(address indexed _caller, bytes32 _collateralPoolId, uint256 _debtAccumulatedRate);

  mapping(bytes32 => ICollateralPoolConfig.CollateralPool) private _collateralPools;

  function collateralPools(bytes32 _collateralPoolId)
    external
    view
    override
    returns (ICollateralPoolConfig.CollateralPool memory)
  {
    return _collateralPools[_collateralPoolId];
  }

  IAccessControlConfig public accessControlConfig;

  modifier onlyOwner() {
    require(accessControlConfig.hasRole(accessControlConfig.OWNER_ROLE(), msg.sender), "!ownerRole");
    _;
  }

  // --- Init ---
  function initialize(address _accessControlConfig) external initializer {
    AccessControlUpgradeable.__AccessControl_init();

    accessControlConfig = IAccessControlConfig(_accessControlConfig);

    // Grant the contract deployer the owner role: it will be able
    // to grant and revoke any roles
    _setupRole(accessControlConfig.OWNER_ROLE(), msg.sender);
  }

  function initCollateralPool(
    bytes32 _collateralPoolId,
    uint256 _debtCeiling,
    uint256 _debtFloor,
    address _priceFeed,
    uint256 _liquidationRatio,
    uint256 _stabilityFeeRate,
    address _adapter,
    uint256 _closeFactorBps,
    uint256 _liquidatorIncentiveBps,
    uint256 _treasuryFeesBps,
    address _strategy
  ) external onlyOwner {
    require(
      _collateralPools[_collateralPoolId].debtAccumulatedRate == 0,
      "CollateralPoolConfig/collateral-pool-already-init"
    );
    _collateralPools[_collateralPoolId].debtAccumulatedRate = RAY;
    _collateralPools[_collateralPoolId].debtCeiling = _debtCeiling;
    _collateralPools[_collateralPoolId].debtFloor = _debtFloor;
    IPriceFeed(_priceFeed).peekPrice(); // Sanity Check Call
    _collateralPools[_collateralPoolId].priceFeed = _priceFeed;
    _collateralPools[_collateralPoolId].liquidationRatio = _liquidationRatio;
    require(_stabilityFeeRate >= RAY, "CollateralPoolConfig/invalid-stability-fee-rate");
    _collateralPools[_collateralPoolId].stabilityFeeRate = _stabilityFeeRate;
    _collateralPools[_collateralPoolId].lastAccumulationTime = now;
    IGenericTokenAdapter(_adapter).decimals(); // Sanity Check Call
    _collateralPools[_collateralPoolId].adapter = _adapter;
    require(_closeFactorBps <= 10000, "CollateralPoolConfig/invalid-close-factor-bps");
    require(
      _liquidatorIncentiveBps >= 10000 && _liquidatorIncentiveBps <= 19000,
      "CollateralPoolConfig/invalid-liquidator-incentive-bps"
    );
    require(_treasuryFeesBps <= 9000, "CollateralPoolConfig/invalid-treasury-fees-bps");
    _collateralPools[_collateralPoolId].closeFactorBps = _closeFactorBps;
    _collateralPools[_collateralPoolId].liquidatorIncentiveBps = _liquidatorIncentiveBps;
    _collateralPools[_collateralPoolId].treasuryFeesBps = _treasuryFeesBps;
    _collateralPools[_collateralPoolId].strategy = _strategy;
  }

  function setPriceWithSafetyMargin(bytes32 _collateralPoolId, uint256 _priceWithSafetyMargin) external override {
    require(accessControlConfig.hasRole(accessControlConfig.PRICE_ORACLE_ROLE(), msg.sender), "!priceOracleRole");
    _collateralPools[_collateralPoolId].priceWithSafetyMargin = _priceWithSafetyMargin;
    emit LogSetPriceWithSafetyMargin(msg.sender, _collateralPoolId, _priceWithSafetyMargin);
  }

  function setDebtCeiling(bytes32 _collateralPoolId, uint256 _debtCeiling) external onlyOwner {
    _collateralPools[_collateralPoolId].debtCeiling = _debtCeiling;
    emit LogSetDebtCeiling(msg.sender, _collateralPoolId, _debtCeiling);
  }

  function setDebtFloor(bytes32 _collateralPoolId, uint256 _debtFloor) external onlyOwner {
    _collateralPools[_collateralPoolId].debtFloor = _debtFloor;
    emit LogSetDebtFloor(msg.sender, _collateralPoolId, _debtFloor);
  }

  function setPriceFeed(bytes32 _poolId, address _priceFeed) external onlyOwner {
    _collateralPools[_poolId].priceFeed = _priceFeed;
    emit LogSetPriceFeed(msg.sender, _poolId, _priceFeed);
  }

  function setLiquidationRatio(bytes32 _poolId, uint256 _data) external onlyOwner {
    _collateralPools[_poolId].liquidationRatio = _data;
    emit LogSetLiquidationRatio(msg.sender, _poolId, _data);
  }

  /** @dev Set the stability fee rate of the collateral pool.
      The rate to be set here is the `r` in:

          r^N = APR

      Where:
        r = stability fee rate
        N = Accumulation frequency which is per-second in this case; the value will be 60*60*24*365 = 31536000 to signify the number of seconds within a year.
        APR = the annual percentage rate

    For example, to achieve 0.5% APR for stability fee rate:

          r^31536000 = 1.005

    Find the 31536000th root of 1.005 and we will get:

          r = 1.000000000158153903837946258002097...

    The rate is in [ray] format, so the actual value of `stabilityFeeRate` will be:

          stabilityFeeRate = 1000000000158153903837946258

    The above `stabilityFeeRate` will be the value we will use in this contract.
  */
  /// @param _collateralPool Collateral pool id
  /// @param _stabilityFeeRate the new stability fee rate [ray]
  function setStabilityFeeRate(bytes32 _collateralPool, uint256 _stabilityFeeRate) external onlyOwner {
    require(_stabilityFeeRate >= RAY, "CollateralPoolConfig/invalid-stability-fee-rate");
    _collateralPools[_collateralPool].stabilityFeeRate = _stabilityFeeRate;
    emit LogSetStabilityFeeRate(msg.sender, _collateralPool, _stabilityFeeRate);
  }

  function setAdapter(bytes32 _collateralPoolId, address _adapter) external onlyOwner {
    _collateralPools[_collateralPoolId].adapter = _adapter;
    emit LogSetAdapter(msg.sender, _collateralPoolId, _adapter);
  }

  function setCloseFactorBps(bytes32 _collateralPoolId, uint256 _closeFactorBps) external onlyOwner {
    require(_closeFactorBps <= 10000, "CollateralPoolConfig/invalid-close-factor-bps");
    _collateralPools[_collateralPoolId].closeFactorBps = _closeFactorBps;
    emit LogSetCloseFactorBps(msg.sender, _collateralPoolId, _closeFactorBps);
  }

  function setLiquidatorIncentiveBps(bytes32 _collateralPoolId, uint256 _liquidatorIncentiveBps) external onlyOwner {
    require(
      _liquidatorIncentiveBps >= 10000 && _liquidatorIncentiveBps <= 19000,
      "CollateralPoolConfig/invalid-liquidator-incentive-bps"
    );
    _collateralPools[_collateralPoolId].liquidatorIncentiveBps = _liquidatorIncentiveBps;
    emit LogSetLiquidatorIncentiveBps(msg.sender, _collateralPoolId, _liquidatorIncentiveBps);
  }

  function setTreasuryFeesBps(bytes32 _collateralPoolId, uint256 _treasuryFeesBps) external onlyOwner {
    require(_treasuryFeesBps <= 9000, "CollateralPoolConfig/invalid-treasury-fees-bps");
    _collateralPools[_collateralPoolId].treasuryFeesBps = _treasuryFeesBps;
    emit LogSetTreasuryFeesBps(msg.sender, _collateralPoolId, _treasuryFeesBps);
  }

  function setTotalDebtShare(bytes32 _collateralPoolId, uint256 _totalDebtShare) external override {
    require(accessControlConfig.hasRole(accessControlConfig.BOOK_KEEPER_ROLE(), msg.sender), "!bookKeeperRole");
    _collateralPools[_collateralPoolId].totalDebtShare = _totalDebtShare;
    emit LogSetTotalDebtShare(msg.sender, _collateralPoolId, _totalDebtShare);
  }

  function setDebtAccumulatedRate(bytes32 _collateralPoolId, uint256 _debtAccumulatedRate) external override {
    require(accessControlConfig.hasRole(accessControlConfig.BOOK_KEEPER_ROLE(), msg.sender), "!bookKeeperRole");
    _collateralPools[_collateralPoolId].debtAccumulatedRate = _debtAccumulatedRate;
    emit LogSetDebtAccumulatedRate(msg.sender, _collateralPoolId, _debtAccumulatedRate);
  }

  function setStrategy(bytes32 _collateralPoolId, address _strategy) external onlyOwner {
    _collateralPools[_collateralPoolId].strategy = _strategy;
    emit LogSetStrategy(msg.sender, _collateralPoolId, address(_strategy));
  }

  function updateLastAccumulationTime(bytes32 _collateralPoolId) external override {
    require(
      accessControlConfig.hasRole(accessControlConfig.STABILITY_FEE_COLLECTOR_ROLE(), msg.sender),
      "!stabilityFeeCollectorRole"
    );
    _collateralPools[_collateralPoolId].lastAccumulationTime = now;
  }

  function getTotalDebtShare(bytes32 _collateralPoolId) external view override returns (uint256) {
    return _collateralPools[_collateralPoolId].totalDebtShare;
  }

  function getDebtAccumulatedRate(bytes32 _collateralPoolId) external view override returns (uint256) {
    return _collateralPools[_collateralPoolId].debtAccumulatedRate;
  }

  function getPriceWithSafetyMargin(bytes32 _collateralPoolId) external view override returns (uint256) {
    return _collateralPools[_collateralPoolId].priceWithSafetyMargin;
  }

  function getDebtCeiling(bytes32 _collateralPoolId) external view override returns (uint256) {
    return _collateralPools[_collateralPoolId].debtCeiling;
  }

  function getDebtFloor(bytes32 _collateralPoolId) external view override returns (uint256) {
    return _collateralPools[_collateralPoolId].debtFloor;
  }

  function getPriceFeed(bytes32 _collateralPoolId) external view override returns (address) {
    return _collateralPools[_collateralPoolId].priceFeed;
  }

  function getLiquidationRatio(bytes32 _collateralPoolId) external view override returns (uint256) {
    return _collateralPools[_collateralPoolId].liquidationRatio;
  }

  function getStabilityFeeRate(bytes32 _collateralPoolId) external view override returns (uint256) {
    return _collateralPools[_collateralPoolId].stabilityFeeRate;
  }

  function getLastAccumulationTime(bytes32 _collateralPoolId) external view override returns (uint256) {
    return _collateralPools[_collateralPoolId].lastAccumulationTime;
  }

  function getAdapter(bytes32 _collateralPoolId) external view override returns (address) {
    return _collateralPools[_collateralPoolId].adapter;
  }

  function getCloseFactorBps(bytes32 _collateralPoolId) external view override returns (uint256) {
    return _collateralPools[_collateralPoolId].closeFactorBps;
  }

  function getLiquidatorIncentiveBps(bytes32 _collateralPoolId) external view override returns (uint256) {
    return _collateralPools[_collateralPoolId].liquidatorIncentiveBps;
  }

  function getTreasuryFeesBps(bytes32 _collateralPoolId) external view override returns (uint256) {
    return _collateralPools[_collateralPoolId].treasuryFeesBps;
  }

  function getStrategy(bytes32 _collateralPoolId) external view override returns (address) {
    return _collateralPools[_collateralPoolId].strategy;
  }
}