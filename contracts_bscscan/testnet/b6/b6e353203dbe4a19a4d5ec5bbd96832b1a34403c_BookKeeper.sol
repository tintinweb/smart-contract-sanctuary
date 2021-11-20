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
import "./ICagable.sol";
import "./ICollateralPoolConfig.sol";
import "./IAccessControlConfig.sol";

/// @title BookKeeper
/// @author Alpaca Fin Corporation
/** @notice A contract which acts as a book keeper of the Alpaca Stablecoin protocol. 
    It has the ability to move collateral token and stablecoin with in the accounting state variable. 
*/

contract BookKeeper is IBookKeeper, PausableUpgradeable, ReentrancyGuardUpgradeable, ICagable {
  modifier onlyOwner() {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(accessControlConfig);
    require(_accessControlConfig.hasRole(_accessControlConfig.OWNER_ROLE(), msg.sender), "!ownerRole");
    _;
  }

  modifier onlyOwnerOrGov() {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(accessControlConfig);
    require(
      _accessControlConfig.hasRole(_accessControlConfig.OWNER_ROLE(), msg.sender) ||
        _accessControlConfig.hasRole(_accessControlConfig.GOV_ROLE(), msg.sender),
      "!(ownerRole or govRole)"
    );
    _;
  }

  modifier onlyOwnerOrShowStopper() {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(accessControlConfig);
    require(
      _accessControlConfig.hasRole(_accessControlConfig.OWNER_ROLE(), msg.sender) ||
        _accessControlConfig.hasRole(_accessControlConfig.SHOW_STOPPER_ROLE(), msg.sender),
      "!(ownerRole or showStopperRole)"
    );
    _;
  }

  modifier onlyPositionManager() {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(accessControlConfig);
    require(
      _accessControlConfig.hasRole(_accessControlConfig.POSITION_MANAGER_ROLE(), msg.sender),
      "!positionManagerRole"
    );
    _;
  }

  modifier onlyCollateralManager() {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(accessControlConfig);
    require(
      _accessControlConfig.hasRole(_accessControlConfig.COLLATERAL_MANAGER_ROLE(), msg.sender),
      "!collateralManagerRole"
    );
    _;
  }

  modifier onlyLiquidationEngine() {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(accessControlConfig);
    require(
      _accessControlConfig.hasRole(_accessControlConfig.LIQUIDATION_ENGINE_ROLE(), msg.sender),
      "!liquidationEngineRole"
    );
    _;
  }

  modifier onlyMintable() {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(accessControlConfig);
    require(_accessControlConfig.hasRole(_accessControlConfig.MINTABLE_ROLE(), msg.sender), "!mintableRole");
    _;
  }

  modifier onlyAdapter() {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(accessControlConfig);
    require(_accessControlConfig.hasRole(_accessControlConfig.ADAPTER_ROLE(), msg.sender), "!adapterRole");
    _;
  }

  modifier onlyStabilityFeeCollector() {
    IAccessControlConfig _accessControlConfig = IAccessControlConfig(accessControlConfig);
    require(
      _accessControlConfig.hasRole(_accessControlConfig.STABILITY_FEE_COLLECTOR_ROLE(), msg.sender),
      "!stabilityFeeCollectorRole"
    );
    _;
  }

  /// @dev access: OWNER_ROLE, GOV_ROLE
  function pause() external onlyOwnerOrGov {
    _pause();
  }

  /// @dev access: OWNER_ROLE, GOV_ROLE
  function unpause() external onlyOwnerOrGov {
    _unpause();
  }

  /// @dev This is the mapping which stores the consent or allowance to adjust positions by the position addresses.
  /// @dev `address` The position address
  /// @dev `address` The allowance delegate address
  /// @dev `uint256` true (1) means allowed or false (0) means not allowed
  mapping(address => mapping(address => uint256)) public override positionWhitelist;

  /// @dev Give an allowance to the `usr` address to adjust the position address who is the caller.
  /// @dev `usr` The address to be allowed to adjust position
  function whitelist(address toBeWhitelistedAddress) external override whenNotPaused {
    positionWhitelist[msg.sender][toBeWhitelistedAddress] = 1;
  }

  /// @dev Revoke an allowance from the `usr` address to adjust the position address who is the caller.
  /// @dev `usr` The address to be revoked from adjusting position
  function blacklist(address toBeBlacklistedAddress) external override whenNotPaused {
    positionWhitelist[msg.sender][toBeBlacklistedAddress] = 0;
  }

  /// @dev Check if the `usr` address is allowed to adjust the position address (`bit`).
  /// @param bit The position address
  /// @param usr The address to be checked for permission
  function wish(address bit, address usr) internal view returns (bool) {
    return either(bit == usr, positionWhitelist[bit][usr] == 1);
  }

  // --- Data ---
  struct Position {
    uint256 lockedCollateral; // Locked collateral inside this position (used for minting)                  [wad]
    uint256 debtShare; // The debt share of this position or the share amount of minted Alpaca Stablecoin   [wad]
  }

  mapping(bytes32 => mapping(address => Position)) public override positions; // mapping of all positions by collateral pool id and position address
  mapping(bytes32 => mapping(address => uint256)) public override collateralToken; // the accounting of collateral token which is deposited into the protocol [wad]
  mapping(address => uint256) public override stablecoin; // the accounting of the stablecoin that is deposited or has not been withdrawn from the protocol [rad]
  mapping(address => uint256) public override systemBadDebt; // the bad debt of the system from late liquidation [rad]

  uint256 public override totalStablecoinIssued; // Total stable coin issued or total stalbecoin in circulation   [rad]
  uint256 public totalUnbackedStablecoin; // Total unbacked stable coin  [rad]
  uint256 public totalDebtCeiling; // Total debt ceiling  [rad]
  uint256 public live; // Active Flag
  address public override collateralPoolConfig;
  address public override accessControlConfig;

  // --- Init ---
  function initialize(address _collateralPoolConfig, address _accessControlConfig) external initializer {
    PausableUpgradeable.__Pausable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    collateralPoolConfig = _collateralPoolConfig;

    accessControlConfig = _accessControlConfig;

    live = 1;
  }

  // --- Math ---
  function add(uint256 x, int256 y) internal pure returns (uint256 z) {
    z = x + uint256(y);
    require(y >= 0 || z <= x);
    require(y <= 0 || z >= x);
  }

  function sub(uint256 x, int256 y) internal pure returns (uint256 z) {
    z = x - uint256(y);
    require(y <= 0 || z <= x);
    require(y >= 0 || z >= x);
  }

  function mul(uint256 x, int256 y) internal pure returns (int256 z) {
    z = int256(x) * y;
    require(int256(x) >= 0);
    require(y == 0 || z / y == int256(x));
  }

  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x);
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x);
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x);
  }

  // --- Administration ---
  event LogSetTotalDebtCeiling(address indexed _caller, uint256 _totalDebtCeiling);
  event LogSetAccessControlConfig(address indexed _caller, address _accessControlConfig);
  event LogSetCollateralPoolConfig(address indexed _caller, address _collateralPoolConfig);
  event LogAdjustPosition(
    address indexed _caller,
    address _positionAddress,
    uint256 _lockedCollateral,
    uint256 _debtShare,
    int256 _addCollateral,
    int256 _addDebtShare
  );
  event LogAddCollateral(address indexed _caller, address _usr, int256 _amount);
  event LogMoveCollateral(address indexed _caller, address _src, address _dst, uint256 _amount);

  /// @dev access: OWNER_ROLE
  function setTotalDebtCeiling(uint256 _totalDebtCeiling) external onlyOwner {
    require(live == 1, "BookKeeper/not-live");
    totalDebtCeiling = _totalDebtCeiling;
    emit LogSetTotalDebtCeiling(msg.sender, _totalDebtCeiling);
  }

  /// @dev access: OWNER_ROLE
  function setAccessControlConfig(address _accessControlConfig) external onlyOwner {
    IAccessControlConfig(_accessControlConfig).hasRole(
      IAccessControlConfig(_accessControlConfig).OWNER_ROLE(),
      msg.sender
    ); // Sanity Check Call
    accessControlConfig = _accessControlConfig;

    emit LogSetAccessControlConfig(msg.sender, _accessControlConfig);
  }

  /// @dev access: OWNER_ROLE
  function setCollateralPoolConfig(address _collateralPoolConfig) external onlyOwner {
    collateralPoolConfig = _collateralPoolConfig;
    emit LogSetCollateralPoolConfig(msg.sender, _collateralPoolConfig);
  }

  /// @dev access: OWNER_ROLE, SHOW_STOPPER_ROLE
  function cage() external override onlyOwnerOrShowStopper {
    require(live == 1, "BookKeeper/not-live");
    live = 0;

    emit LogCage();
  }

  /// @dev access: OWNER_ROLE, SHOW_STOPPER_ROLE
  function uncage() external override onlyOwnerOrShowStopper {
    require(live == 0, "BookKeeper/not-caged");
    live = 1;

    emit LogUncage();
  }

  // --- Fungibility ---
  /// @dev Add or remove collateral token balance to an address within the accounting of the protocol
  /// @param _collateralPoolId The collateral pool id
  /// @param _usr The target address
  /// @param _amount The collateral amount in [wad]
  /// @dev access: ADAPTER_ROLE
  function addCollateral(
    bytes32 _collateralPoolId,
    address _usr,
    int256 _amount
  ) external override nonReentrant whenNotPaused onlyAdapter {
    collateralToken[_collateralPoolId][_usr] = add(collateralToken[_collateralPoolId][_usr], _amount);
    emit LogAddCollateral(msg.sender, _usr, _amount);
  }

  /// @dev Move a balance of collateral token from a source address to a destination address within the accounting of the protocol
  /// @param _collateralPoolId the collateral pool id
  /// @param _src The source address
  /// @param _dst The destination address
  /// @param _amount The collateral amount in [wad]
  /// @dev access: COLLATERAL_MANAGER_ROLE
  function moveCollateral(
    bytes32 _collateralPoolId,
    address _src,
    address _dst,
    uint256 _amount
  ) external override nonReentrant whenNotPaused onlyCollateralManager {
    require(wish(_src, msg.sender), "BookKeeper/not-allowed");
    collateralToken[_collateralPoolId][_src] = sub(collateralToken[_collateralPoolId][_src], _amount);
    collateralToken[_collateralPoolId][_dst] = add(collateralToken[_collateralPoolId][_dst], _amount);
    emit LogMoveCollateral(msg.sender, _src, _dst, _amount);
  }

  /// @dev Move a balance of stablecoin from a source address to a destination address within the accounting of the protocol
  /// @param _src The source address
  /// @param _dst The destination address
  /// @param _value The stablecoin value in [rad]
  function moveStablecoin(
    address _src,
    address _dst,
    uint256 _value
  ) external override nonReentrant whenNotPaused {
    require(wish(_src, msg.sender), "BookKeeper/not-allowed");
    stablecoin[_src] = sub(stablecoin[_src], _value);
    stablecoin[_dst] = add(stablecoin[_dst], _value);
  }

  function either(bool _x, bool _y) internal pure returns (bool _z) {
    assembly {
      _z := or(_x, _y)
    }
  }

  function both(bool _x, bool _y) internal pure returns (bool _z) {
    assembly {
      _z := and(_x, _y)
    }
  }

  // --- CDP Manipulation ---
  /// @dev Adjust a position on the target position address to perform locking/unlocking of collateral and minting/repaying of stablecoin
  /// @param _collateralPoolId Collateral pool id
  /// @param _positionAddress Address of the position
  /// @param _collateralOwner The payer/receiver of the collateral token, the collateral token must already be deposited into the protocol in case of locking the collateral
  /// @param _stablecoinOwner The payer/receiver of the stablecoin, the stablecoin must already be deposited into the protocol in case of repaying debt
  /// @param _collateralValue The value of the collateral to lock/unlock
  /// @param _debtShare The debt share of stalbecoin to mint/repay. Please pay attention that this is a debt share not debt value.
  /// @dev access: POSITION_MANAGER_ROLE
  function adjustPosition(
    bytes32 _collateralPoolId,
    address _positionAddress,
    address _collateralOwner,
    address _stablecoinOwner,
    int256 _collateralValue,
    int256 _debtShare
  ) external override nonReentrant whenNotPaused onlyPositionManager {
    // system is live
    require(live == 1, "BookKeeper/not-live");

    Position memory position = positions[_collateralPoolId][_positionAddress];

    ICollateralPoolConfig.CollateralPoolInfo memory _vars = ICollateralPoolConfig(collateralPoolConfig)
      .getCollateralPoolInfo(_collateralPoolId);

    // collateralPool has been initialised
    require(_vars.debtAccumulatedRate != 0, "BookKeeper/collateralPool-not-init");
    position.lockedCollateral = add(position.lockedCollateral, _collateralValue);
    position.debtShare = add(position.debtShare, _debtShare);
    _vars.totalDebtShare = add(_vars.totalDebtShare, _debtShare);
    ICollateralPoolConfig(collateralPoolConfig).setTotalDebtShare(_collateralPoolId, _vars.totalDebtShare);

    int256 _debtValue = mul(_vars.debtAccumulatedRate, _debtShare);
    uint256 _positionDebtValue = mul(_vars.debtAccumulatedRate, position.debtShare);
    totalStablecoinIssued = add(totalStablecoinIssued, _debtValue);

    // either debt has decreased, or debt ceilings are not exceeded
    require(
      either(
        _debtShare <= 0,
        both(
          mul(_vars.totalDebtShare, _vars.debtAccumulatedRate) <= _vars.debtCeiling,
          totalStablecoinIssued <= totalDebtCeiling
        )
      ),
      "BookKeeper/ceiling-exceeded"
    );
    // position is either less risky than before, or it is safe :: check work factor
    require(
      either(
        both(_debtShare <= 0, _collateralValue >= 0),
        _positionDebtValue <= mul(position.lockedCollateral, _vars.priceWithSafetyMargin)
      ),
      "BookKeeper/not-safe"
    );

    // position is either more safe, or the owner consents
    require(
      either(both(_debtShare <= 0, _collateralValue >= 0), wish(_positionAddress, msg.sender)),
      "BookKeeper/not-allowed-position-address"
    );
    // collateral src consents
    require(
      either(_collateralValue <= 0, wish(_collateralOwner, msg.sender)),
      "BookKeeper/not-allowed-collateral-owner"
    );
    // debt dst consents
    require(either(_debtShare >= 0, wish(_stablecoinOwner, msg.sender)), "BookKeeper/not-allowed-stablecoin-owner");

    // position has no debt, or a non-debtFloory amount
    require(either(position.debtShare == 0, _positionDebtValue >= _vars.debtFloor), "BookKeeper/debt-floor");
    collateralToken[_collateralPoolId][_collateralOwner] = sub(
      collateralToken[_collateralPoolId][_collateralOwner],
      _collateralValue
    );
    stablecoin[_stablecoinOwner] = add(stablecoin[_stablecoinOwner], _debtValue);

    positions[_collateralPoolId][_positionAddress] = position;

    emit LogAdjustPosition(
      msg.sender,
      _positionAddress,
      position.lockedCollateral,
      position.debtShare,
      _collateralValue,
      _debtShare
    );
  }

  // --- CDP Fungibility ---
  /// @dev Move the collateral or stablecoin debt inside a position to another position
  /// @param _collateralPoolId Collateral pool id
  /// @param _src Source address of the position
  /// @param _dst Destination address of the position
  /// @param _collateralAmount The amount of the locked collateral to be moved
  /// @param _debtShare The debt share of stalbecoin to be moved
  /// @dev access: POSITION_MANAGER_ROLE
  function movePosition(
    bytes32 _collateralPoolId,
    address _src,
    address _dst,
    int256 _collateralAmount,
    int256 _debtShare
  ) external override nonReentrant whenNotPaused onlyPositionManager {
    Position storage _positionSrc = positions[_collateralPoolId][_src];
    Position storage _positionDst = positions[_collateralPoolId][_dst];

    ICollateralPoolConfig.CollateralPoolInfo memory _vars = ICollateralPoolConfig(collateralPoolConfig)
      .getCollateralPoolInfo(_collateralPoolId);

    _positionSrc.lockedCollateral = sub(_positionSrc.lockedCollateral, _collateralAmount);
    _positionSrc.debtShare = sub(_positionSrc.debtShare, _debtShare);
    _positionDst.lockedCollateral = add(_positionDst.lockedCollateral, _collateralAmount);
    _positionDst.debtShare = add(_positionDst.debtShare, _debtShare);

    uint256 _utab = mul(_positionSrc.debtShare, _vars.debtAccumulatedRate);
    uint256 _vtab = mul(_positionDst.debtShare, _vars.debtAccumulatedRate);

    // both sides consent
    require(both(wish(_src, msg.sender), wish(_dst, msg.sender)), "BookKeeper/not-allowed");

    // both sides safe
    require(_utab <= mul(_positionSrc.lockedCollateral, _vars.priceWithSafetyMargin), "BookKeeper/not-safe-src");
    require(_vtab <= mul(_positionDst.lockedCollateral, _vars.priceWithSafetyMargin), "BookKeeper/not-safe-dst");

    // both sides non-debtFloory
    require(either(_utab >= _vars.debtFloor, _positionSrc.debtShare == 0), "BookKeeper/debt-floor-src");
    require(either(_vtab >= _vars.debtFloor, _positionDst.debtShare == 0), "BookKeeper/debt-floor-dst");
  }

  // --- CDP Confiscation ---
  /** @dev Confiscate position from the owner for the position to be liquidated.
      The position will be confiscated of collateral in which these collateral will be sold through a liquidation process to repay the stablecoin debt.
      The confiscated collateral will be seized by the Auctioneer contracts and will be moved to the corresponding liquidator addresses upon later.
      The stablecoin debt will be mark up on the SystemDebtEngine contract first. This would signify that the system currently has a bad debt of this amount. 
      But it will be cleared later on from a successful liquidation. If this debt is not fully liquidated, the remaining debt will stay inside SystemDebtEngine as bad debt.
  */
  /// @param _collateralPoolId Collateral pool id
  /// @param _positionAddress The position address
  /// @param _collateralCreditor The address which will temporarily own the collateral of the liquidated position; this will always be the Auctioneer
  /// @param _stablecoinDebtor The address which will be the one to be in debt for the amount of stablecoin debt of the liquidated position, this will always be the SystemDebtEngine
  /// @param _collateralAmount The amount of collateral to be confiscated [wad]
  /// @param _debtShare The debt share to be confiscated [wad]
  /// @dev access: LIQUIDATION_ENGINE_ROLE
  function confiscatePosition(
    bytes32 _collateralPoolId,
    address _positionAddress,
    address _collateralCreditor,
    address _stablecoinDebtor,
    int256 _collateralAmount,
    int256 _debtShare
  ) external override nonReentrant whenNotPaused onlyLiquidationEngine {
    Position storage position = positions[_collateralPoolId][_positionAddress];
    ICollateralPoolConfig.CollateralPoolInfo memory _vars = ICollateralPoolConfig(collateralPoolConfig)
      .getCollateralPoolInfo(_collateralPoolId);

    position.lockedCollateral = add(position.lockedCollateral, _collateralAmount);
    position.debtShare = add(position.debtShare, _debtShare);
    _vars.totalDebtShare = add(_vars.totalDebtShare, _debtShare);
    ICollateralPoolConfig(collateralPoolConfig).setTotalDebtShare(_collateralPoolId, _vars.totalDebtShare);

    int256 _debtValue = mul(_vars.debtAccumulatedRate, _debtShare);

    collateralToken[_collateralPoolId][_collateralCreditor] = sub(
      collateralToken[_collateralPoolId][_collateralCreditor],
      _collateralAmount
    );
    systemBadDebt[_stablecoinDebtor] = sub(systemBadDebt[_stablecoinDebtor], _debtValue);
    totalUnbackedStablecoin = sub(totalUnbackedStablecoin, _debtValue);
  }

  // --- Settlement ---
  /** @dev Settle the system bad debt of the caller.
      This function will always be called by the SystemDebtEngine which will be the contract that always incur the system debt.
      By executing this function, the SystemDebtEngine must have enough stablecoin which will come from the Surplus of the protocol.
      A successful `settleSystemBadDebt` would remove the bad debt from the system.
  */
  /// @param _value the value of stablecoin to be used to settle bad debt [rad]
  function settleSystemBadDebt(uint256 _value) external override nonReentrant whenNotPaused {
    systemBadDebt[msg.sender] = sub(systemBadDebt[msg.sender], _value);
    stablecoin[msg.sender] = sub(stablecoin[msg.sender], _value);
    totalUnbackedStablecoin = sub(totalUnbackedStablecoin, _value);
    totalStablecoinIssued = sub(totalStablecoinIssued, _value);
  }

  /// @dev Mint unbacked stablecoin without any collateral to be used for incentives and flash mint.
  /// @param _from The address which will be the one who incur bad debt (will always be SystemDebtEngine here)
  /// @param _to The address which will receive the minted stablecoin
  /// @param _value The value of stablecoin to be minted [rad]
  /// @dev access: MINTABLE_ROLE
  function mintUnbackedStablecoin(
    address _from,
    address _to,
    uint256 _value
  ) external override nonReentrant whenNotPaused onlyMintable {
    systemBadDebt[_from] = add(systemBadDebt[_from], _value);
    stablecoin[_to] = add(stablecoin[_to], _value);
    totalUnbackedStablecoin = add(totalUnbackedStablecoin, _value);
    totalStablecoinIssued = add(totalStablecoinIssued, _value);
  }

  // --- Rates ---
  /** @dev Accrue stability fee or the mint interest rate.
      This function will always be called only by the StabilityFeeCollector contract.
      `debtAccumulatedRate` of a collateral pool is the exchange rate of the stablecoin minted from that pool (think of it like ibToken price from Lending Vault).
      The higher the `debtAccumulatedRate` means the minter of the stablecoin will beed to pay back the debt with higher amount.
      The point of Stability Fee is to collect a surplus amount from minters and this is technically done by incrementing the `debtAccumulatedRate` overtime.
  */
  /// @param _collateralPoolId Collateral pool id
  /// @param _stabilityFeeRecipient The address which will receive the surplus from Stability Fee. This will always be SystemDebtEngine who will use the surplus to settle bad debt.
  /// @param _debtAccumulatedRate The difference value of `debtAccumulatedRate` which will be added to the current value of `debtAccumulatedRate`. [ray]
  /// @dev access: STABILITY_FEE_COLLECTOR_ROLE
  function accrueStabilityFee(
    bytes32 _collateralPoolId,
    address _stabilityFeeRecipient,
    int256 _debtAccumulatedRate
  ) external override nonReentrant whenNotPaused onlyStabilityFeeCollector {
    require(live == 1, "BookKeeper/not-live");
    ICollateralPoolConfig.CollateralPoolInfo memory _vars = ICollateralPoolConfig(collateralPoolConfig)
      .getCollateralPoolInfo(_collateralPoolId);

    _vars.debtAccumulatedRate = add(_vars.debtAccumulatedRate, _debtAccumulatedRate);
    ICollateralPoolConfig(collateralPoolConfig).setDebtAccumulatedRate(_collateralPoolId, _vars.debtAccumulatedRate);
    int256 _value = mul(_vars.totalDebtShare, _debtAccumulatedRate); // [rad]
    stablecoin[_stabilityFeeRecipient] = add(stablecoin[_stabilityFeeRecipient], _value);
    totalStablecoinIssued = add(totalStablecoinIssued, _value);
  }
}