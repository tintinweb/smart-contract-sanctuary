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
import "./SafeMathUpgradeable.sol";

import "./IBookKeeper.sol";
import "./IAuctioneer.sol";
import "./ISystemDebtEngine.sol";
import "./ILiquidationEngine.sol";
import "./ILiquidationStrategy.sol";
import "./ICagable.sol";

/// @title LiquidationEngine
/// @author Alpaca Fin Corporation
/** @notice A contract which is the manager for all of the liquidations of the protocol.
    LiquidationEngine will be the interface for the liquidator to trigger any positions into the liquidation process.
*/

contract LiquidationEngine is PausableUpgradeable, ReentrancyGuardUpgradeable, ICagable, ILiquidationEngine {
  using SafeMathUpgradeable for uint256;

  struct LocalVars {
    uint256 positionLockedCollateral;
    uint256 positionDebtShare;
    uint256 systemDebtEngineStablecoinBefore;
    uint256 newPositionLockedCollateral;
    uint256 newPositionDebtShare;
    uint256 wantStablecoinValueFromLiquidation;
  }

  struct CollateralPoolLocalVars {
    address strategy;
    uint256 priceWithSafetyMargin; // [ray]
    uint256 debtAccumulatedRate; // [ray]
  }

  IBookKeeper public bookKeeper; // CDP Engine
  ISystemDebtEngine public systemDebtEngine; // Debt Engine
  uint256 public override live; // Active Flag

  // --- Init ---
  function initialize(address _bookKeeper, address _systemDebtEngine) external initializer {
    PausableUpgradeable.__Pausable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    IBookKeeper(_bookKeeper).totalStablecoinIssued(); // Sanity Check Call
    bookKeeper = IBookKeeper(_bookKeeper);

    ISystemDebtEngine(_systemDebtEngine).surplusBuffer(); // Sanity Check Call
    systemDebtEngine = ISystemDebtEngine(_systemDebtEngine);

    // Sanity check
    bookKeeper.totalStablecoinIssued();

    live = 1;
  }

  // --- Math ---
  uint256 constant WAD = 10**18;

  function liquidate(
    bytes32 _collateralPoolId,
    address _positionAddress,
    uint256 _debtShareToBeLiquidated, // [rad]
    uint256 _maxDebtShareToBeLiquidated, // [rad]
    address _collateralRecipient,
    bytes calldata _data
  ) external override nonReentrant whenNotPaused {
    require(live == 1, "LiquidationEngine/not-live");
    require(_debtShareToBeLiquidated != 0, "LiquidationEngine/zero-debt-value-to-be-liquidated");
    require(_maxDebtShareToBeLiquidated != 0, "LiquidationEngine/zero-max-debt-value-to-be-liquidated");

    LocalVars memory _vars;

    (_vars.positionLockedCollateral, _vars.positionDebtShare) = bookKeeper.positions(
      _collateralPoolId,
      _positionAddress
    );
    // 1. Check if the position is underwater
    CollateralPoolLocalVars memory _collateralPoolLocalVars;
    _collateralPoolLocalVars.strategy = ICollateralPoolConfig(bookKeeper.collateralPoolConfig()).getStrategy(
      _collateralPoolId
    );
    _collateralPoolLocalVars.priceWithSafetyMargin = ICollateralPoolConfig(bookKeeper.collateralPoolConfig())
      .getPriceWithSafetyMargin(_collateralPoolId); // [ray]
    _collateralPoolLocalVars.debtAccumulatedRate = ICollateralPoolConfig(bookKeeper.collateralPoolConfig())
      .getDebtAccumulatedRate(_collateralPoolId); // [ray]

    ILiquidationStrategy _strategy = ILiquidationStrategy(_collateralPoolLocalVars.strategy);
    require(address(_strategy) != address(0), "LiquidationEngine/not-set-strategy");

    // (positionLockedCollateral [wad] * priceWithSafetyMargin [ray]) [rad]
    // (positionDebtShare [wad] * debtAccumulatedRate [ray]) [rad]
    require(
      _collateralPoolLocalVars.priceWithSafetyMargin > 0 &&
        _vars.positionLockedCollateral.mul(_collateralPoolLocalVars.priceWithSafetyMargin) <
        _vars.positionDebtShare.mul(_collateralPoolLocalVars.debtAccumulatedRate),
      "LiquidationEngine/position-is-safe"
    );

    _vars.systemDebtEngineStablecoinBefore = bookKeeper.stablecoin(address(systemDebtEngine));

    _strategy.execute(
      _collateralPoolId,
      _vars.positionDebtShare,
      _vars.positionLockedCollateral,
      _positionAddress,
      _debtShareToBeLiquidated,
      _maxDebtShareToBeLiquidated,
      msg.sender,
      _collateralRecipient,
      _data
    );
    (_vars.newPositionLockedCollateral, _vars.newPositionDebtShare) = bookKeeper.positions(
      _collateralPoolId,
      _positionAddress
    );
    require(_vars.newPositionDebtShare < _vars.positionDebtShare, "LiquidationEngine/debt-not-liquidated");

    // (positionDebtShare [wad] - newPositionDebtShare [wad]) * debtAccumulatedRate [ray]

    _vars.wantStablecoinValueFromLiquidation = _vars.positionDebtShare.sub(_vars.newPositionDebtShare).mul(
      _collateralPoolLocalVars.debtAccumulatedRate
    ); // [rad]
    require(
      bookKeeper.stablecoin(address(systemDebtEngine)).sub(_vars.systemDebtEngineStablecoinBefore) >=
        _vars.wantStablecoinValueFromLiquidation,
      "LiquidationEngine/payment-not-received"
    );

    // If collateral has been depleted from liquidation whilst there is remaining debt in the position
    if (_vars.newPositionLockedCollateral == 0 && _vars.newPositionDebtShare > 0) {
      // Overflow check
      require(_vars.newPositionDebtShare <= 2**255, "LiquidationEngine/overflow");
      // Record the bad debt to the system and close the position
      bookKeeper.confiscatePosition(
        _collateralPoolId,
        _positionAddress,
        _positionAddress,
        address(systemDebtEngine),
        0,
        -int256(_vars.newPositionDebtShare)
      );
    }
  }

  function cage() external override {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(IBookKeeper(bookKeeper).accessControlConfig());
    require(
      _accessControlConfig.hasRole(_accessControlConfig.OWNER_ROLE(), msg.sender) ||
        _accessControlConfig.hasRole(_accessControlConfig.SHOW_STOPPER_ROLE(), msg.sender),
      "!(ownerRole or showStopperRole)"
    );
    require(live == 1, "LiquidationEngine/not-live");
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
    require(live == 0, "LiquidationEngine/not-caged");
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