/**
 *Submitted for verification at polygonscan.com on 2021-09-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File contracts/Ledger.sol

pragma solidity ^0.8.2;

contract Ledger is Initializable {
  struct CollateralType {
    uint256 normalizedDebt; // Total Normalised Debt     [wad]
    uint256 accumulatedRate; // Accumulated Rates         [ray]
    uint256 safetyPrice; // Price with Safety Margin  [ray]
    uint256 debtCeiling; // Debt Ceiling              [rad]
    uint256 debtFloor; // Position Debt Floor            [rad]
  }
  struct Position {
    uint256 lockedCollateral; // Locked Collateral  [wad]
    uint256 normalizedDebt; // Normalised Debt    [wad]
  }

  mapping(address => uint256) public authorizedAccounts;
  mapping(bytes32 => CollateralType) public collateralTypes;
  mapping(address => mapping(address => uint256)) public allowed;
  mapping(bytes32 => mapping(address => Position)) public positions;
  mapping(bytes32 => mapping(address => uint256)) public collateral; // [wad]
  mapping(address => uint256) public debt; // internal coin balance [rad]
  mapping(address => uint256) public unbackedDebt; // system debt, not belonging to any Position [rad]

  uint256 public totalDebt; // Total Stablecoin Issued    [rad]
  uint256 public totalUnbackedDebt; // Total Unbacked Stablecoin  [rad]
  uint256 public totalDebtCeiling; // Total Debt Ceiling  [rad]
  uint256 public live; // Active Flag

  // --- Events ---
  event GrantAuthorization(address indexed account);
  event RevokeAuthorization(address indexed account);
  event AllowModification(address indexed target, address indexed user);
  event DenyModification(address indexed target, address indexed user);
  event InitializeCollateralType(bytes32 indexed collateralType);
  event UpdateParameter(bytes32 indexed parameter, uint256 data);
  event UpdateParameter(
    bytes32 indexed parameter,
    bytes32 indexed collateralType,
    uint256 data
  );
  event ModifyCollateral(bytes32 collateralType, address user, int256 amount);
  event TransferCollateral(
    bytes32 collateralType,
    address from,
    address to,
    uint256 amount
  );
  event TransferDebt(address from, address to, uint256 amount);
  event ModifyPositionCollateralization(
    bytes32 indexed collateralType,
    address indexed position,
    address collateralSource,
    address debtDestination,
    int256 collateralDelta,
    int256 normalizedDebtDelta,
    uint256 lockedCollateral,
    uint256 normalizedDebt
  );
  event TransferCollateralAndDebt(
    bytes32 indexed collateralType,
    address indexed src,
    address indexed dst,
    int256 collateralDelta,
    int256 normalizedDebtDelta,
    uint256 srcLockedCollateral,
    uint256 srcNormalizedDebt,
    uint256 dstLockedCollateral,
    uint256 dstNormalizedDebt
  );
  event ConfiscateCollateralAndDebt(
    bytes32 indexed collateralType,
    address indexed position,
    address collateralCounterparty,
    address debtCounterparty,
    int256 collateralDelta,
    int256 normalizedDebtDelta
  );
  event SettleUnbackedDebt(address indexed account, uint256 amount);
  event CreateUnbackedDebt(
    address debtDestination,
    address unbackedDebtDestination,
    uint256 amount,
    uint256 debtDestinationBalance,
    uint256 unbackedDebtDestinationBalance
  );
  event UpdateAccumulatedRate(
    bytes32 indexed collateralType,
    address surplusDestination,
    int256 accumulatedRatedelta,
    int256 surplusDelta
  );

  modifier isAuthorized() {
    require(authorizedAccounts[msg.sender] == 1, "Ledger/not-authorized");
    _;
  }

  modifier isLive() {
    require(live == 1, "Ledger/not-live");
    _;
  }

  function initialize() public initializer {
    authorizedAccounts[msg.sender] = 1;
    live = 1;
  }

  // --- Auth ---
  function grantAuthorization(address user) external isAuthorized {
    authorizedAccounts[user] = 1;
    emit GrantAuthorization(user);
  }

  function revokeAuthorization(address user) external isAuthorized {
    authorizedAccounts[user] = 0;
    emit RevokeAuthorization(user);
  }

  // --- Allowance ---
  function allowModification(address user) external {
    allowed[msg.sender][user] = 1;
    emit AllowModification(msg.sender, user);
  }

  function denyModification(address user) external {
    allowed[msg.sender][user] = 0;
    emit DenyModification(msg.sender, user);
  }

  function allowedToModifyDebtOrCollateral(address bit, address user)
    internal
    view
    returns (bool)
  {
    return
      either(
        // Either user is owner, or modification permission is given
        either(bit == user, allowed[bit][user] == 1),
        // Sender is admin
        authorizedAccounts[msg.sender] == 1
      );
  }

  // --- Math ---
  function addInt(uint256 x, int256 y) internal pure returns (uint256 z) {
    unchecked {
      z = x + uint256(y);
    }
    require(y >= 0 || z <= x);
    require(y <= 0 || z >= x);
  }

  function subInt(uint256 x, int256 y) internal pure returns (uint256 z) {
    unchecked {
      z = x - uint256(y);
    }
    require(y <= 0 || z <= x);
    require(y >= 0 || z >= x);
  }

  function mulInt(uint256 x, int256 y) internal pure returns (int256 z) {
    unchecked {
      z = int256(x) * y;
    }
    require(int256(x) >= 0);
    require(y == 0 || z / y == int256(x));
  }

  function either(bool x, bool y) internal pure returns (bool z) {
    assembly {
      z := or(x, y)
    }
  }

  function both(bool x, bool y) internal pure returns (bool z) {
    assembly {
      z := and(x, y)
    }
  }

  // --- Administration ---
  function initializeCollateralType(bytes32 collateralType)
    external
    isAuthorized
  {
    require(
      collateralTypes[collateralType].accumulatedRate == 0,
      "Ledger/collateralType-already-init"
    );
    collateralTypes[collateralType].accumulatedRate = 10**27;
    emit InitializeCollateralType(collateralType);
  }

  function updateTotalDebtCeiling(uint256 data) external isAuthorized isLive {
    totalDebtCeiling = data;
    emit UpdateParameter("totalDebtCeiling", data);
  }

  function updateSafetyPrice(bytes32 collateralType, uint256 data)
    external
    isAuthorized
    isLive
  {
    collateralTypes[collateralType].safetyPrice = data;
    emit UpdateParameter("safetyPrice", data);
  }

  function updateDebtCeiling(bytes32 collateralType, uint256 data)
    external
    isAuthorized
    isLive
  {
    collateralTypes[collateralType].debtCeiling = data;
    emit UpdateParameter("debtCeiling", collateralType, data);
  }

  function updateDebtFloor(bytes32 collateralType, uint256 data)
    external
    isAuthorized
    isLive
  {
    collateralTypes[collateralType].debtFloor = data;
    emit UpdateParameter("debtFloor", collateralType, data);
  }

  function shutdown() external isAuthorized {
    live = 0;
  }

  // --- Fungibility ---
  function modifyCollateral(
    bytes32 collateralType,
    address user,
    int256 wad
  ) external isAuthorized {
    collateral[collateralType][user] = addInt(
      collateral[collateralType][user],
      wad
    );
    emit ModifyCollateral(collateralType, user, wad);
  }

  function transferCollateral(
    bytes32 collateralType,
    address from,
    address to,
    uint256 wad
  ) external {
    require(
      allowedToModifyDebtOrCollateral(from, msg.sender),
      "Ledger/not-allowed"
    );
    collateral[collateralType][from] = collateral[collateralType][from] - wad;
    collateral[collateralType][to] = collateral[collateralType][to] + wad;
    emit TransferCollateral(collateralType, from, to, wad);
  }

  function transferDebt(
    address from,
    address to,
    uint256 rad
  ) external {
    require(
      allowedToModifyDebtOrCollateral(from, msg.sender),
      "Ledger/not-allowed"
    );
    debt[from] = debt[from] - rad;
    debt[to] = debt[to] + rad;
    emit TransferDebt(from, to, rad);
  }

  // --- CDP Manipulation ---
  function modifyPositionCollateralization(
    bytes32 collateralType,
    address position,
    address collateralSource,
    address debtDestination,
    int256 collateralDelta,
    int256 normalizedDebtDelta
  ) external isLive {
    Position memory positionData = positions[collateralType][position];
    CollateralType memory collateralTypeData = collateralTypes[collateralType];
    // collateralType has been initialised
    require(
      collateralTypeData.accumulatedRate != 0,
      "Ledger/collateralType-not-init"
    );

    positionData.lockedCollateral = addInt(
      positionData.lockedCollateral,
      collateralDelta
    );
    positionData.normalizedDebt = addInt(
      positionData.normalizedDebt,
      normalizedDebtDelta
    );
    collateralTypeData.normalizedDebt = addInt(
      collateralTypeData.normalizedDebt,
      normalizedDebtDelta
    );

    int256 adjustedDebtDelta = mulInt(
      collateralTypeData.accumulatedRate,
      normalizedDebtDelta
    );
    uint256 totalDebtOfPosition = collateralTypeData.accumulatedRate *
      positionData.normalizedDebt;
    totalDebt = addInt(totalDebt, adjustedDebtDelta);

    // either totalDebt has decreased, or totalDebtceilings are not exceeded
    require(
      either(
        normalizedDebtDelta <= 0,
        both(
          collateralTypeData.normalizedDebt *
            collateralTypeData.accumulatedRate <=
            collateralTypeData.debtCeiling,
          totalDebt <= totalDebtCeiling
        )
      ),
      "Ledger/ceiling-exceeded"
    );
    // position is either less risky than before, or it is safe
    require(
      either(
        both(normalizedDebtDelta <= 0, collateralDelta >= 0),
        totalDebtOfPosition <=
          positionData.lockedCollateral * collateralTypeData.safetyPrice
      ),
      "Ledger/not-safe"
    );

    // position is either more safe, or the owner consents
    require(
      either(
        both(normalizedDebtDelta <= 0, collateralDelta >= 0),
        allowedToModifyDebtOrCollateral(position, msg.sender)
      ),
      "Ledger/not-allowed-position"
    );
    // collateral src consents
    require(
      either(
        collateralDelta <= 0,
        allowedToModifyDebtOrCollateral(collateralSource, msg.sender)
      ),
      "Ledger/not-allowed-collateral-src"
    );
    // totalDebtdst consents
    require(
      either(
        normalizedDebtDelta >= 0,
        allowedToModifyDebtOrCollateral(debtDestination, msg.sender)
      ),
      "Ledger/not-allowed-debt-dst"
    );

    // position has no debt, or a non-negligible amount
    require(
      either(
        positionData.normalizedDebt == 0,
        totalDebtOfPosition >= collateralTypeData.debtFloor
      ),
      "Ledger/debtFloor"
    );

    collateral[collateralType][collateralSource] = subInt(
      collateral[collateralType][collateralSource],
      collateralDelta
    );
    debt[debtDestination] = addInt(debt[debtDestination], adjustedDebtDelta);

    positions[collateralType][position] = positionData;
    collateralTypes[collateralType] = collateralTypeData;
    emit ModifyPositionCollateralization(
      collateralType,
      position,
      collateralSource,
      debtDestination,
      collateralDelta,
      normalizedDebtDelta,
      positionData.lockedCollateral,
      positionData.normalizedDebt
    );
  }

  // --- CDP Fungibility ---
  function transferCollateralAndDebt(
    bytes32 collateralType,
    address src,
    address dst,
    int256 collateralDelta,
    int256 normalizedDebtDelta
  ) external {
    Position storage sourcePosition = positions[collateralType][src];
    Position storage destinationPosition = positions[collateralType][dst];
    CollateralType storage collateralTypeData = collateralTypes[collateralType];

    sourcePosition.lockedCollateral = subInt(
      sourcePosition.lockedCollateral,
      collateralDelta
    );
    sourcePosition.normalizedDebt = subInt(
      sourcePosition.normalizedDebt,
      normalizedDebtDelta
    );
    destinationPosition.lockedCollateral = addInt(
      destinationPosition.lockedCollateral,
      collateralDelta
    );
    destinationPosition.normalizedDebt = addInt(
      destinationPosition.normalizedDebt,
      normalizedDebtDelta
    );

    uint256 sourceDebt = sourcePosition.normalizedDebt *
      collateralTypeData.accumulatedRate;
    uint256 destinationDebt = destinationPosition.normalizedDebt *
      collateralTypeData.accumulatedRate;

    // both sides consent
    require(
      both(
        allowedToModifyDebtOrCollateral(src, msg.sender),
        allowedToModifyDebtOrCollateral(dst, msg.sender)
      ),
      "Ledger/not-allowed"
    );

    // both sides safe
    require(
      sourceDebt <=
        sourcePosition.lockedCollateral * collateralTypeData.safetyPrice,
      "Ledger/not-safe-src"
    );
    require(
      destinationDebt <=
        destinationPosition.lockedCollateral * collateralTypeData.safetyPrice,
      "Ledger/not-safe-dst"
    );

    // both sides non-negligible
    require(
      either(
        sourceDebt >= collateralTypeData.debtFloor,
        sourcePosition.normalizedDebt == 0
      ),
      "Ledger/debtFloor-src"
    );
    require(
      either(
        destinationDebt >= collateralTypeData.debtFloor,
        destinationPosition.normalizedDebt == 0
      ),
      "Ledger/debtFloor-dst"
    );
    emit TransferCollateralAndDebt(
      collateralType,
      src,
      dst,
      collateralDelta,
      normalizedDebtDelta,
      sourcePosition.lockedCollateral,
      sourcePosition.normalizedDebt,
      destinationPosition.lockedCollateral,
      destinationPosition.normalizedDebt
    );
  }

  // --- CDP Confiscation ---
  function confiscateCollateralAndDebt(
    bytes32 collateralType,
    address user,
    address collateralCounterparty,
    address debtCounterparty,
    int256 collateralDelta,
    int256 normalizedDebtDelta
  ) external isAuthorized {
    Position storage position = positions[collateralType][user];
    CollateralType storage collateralTypeData = collateralTypes[collateralType];

    position.lockedCollateral = addInt(
      position.lockedCollateral,
      collateralDelta
    );
    position.normalizedDebt = addInt(
      position.normalizedDebt,
      normalizedDebtDelta
    );
    collateralTypeData.normalizedDebt = addInt(
      collateralTypeData.normalizedDebt,
      normalizedDebtDelta
    );

    int256 unbackedDebtDelta = mulInt(
      collateralTypeData.accumulatedRate,
      normalizedDebtDelta
    );

    collateral[collateralType][collateralCounterparty] = subInt(
      collateral[collateralType][collateralCounterparty],
      collateralDelta
    );
    unbackedDebt[debtCounterparty] = subInt(
      unbackedDebt[debtCounterparty],
      unbackedDebtDelta
    );
    totalUnbackedDebt = subInt(totalUnbackedDebt, unbackedDebtDelta);
    emit ConfiscateCollateralAndDebt(
      collateralType,
      user,
      collateralCounterparty,
      debtCounterparty,
      collateralDelta,
      normalizedDebtDelta
    );
  }

  // --- Settlement ---
  function settleUnbackedDebt(uint256 rad) external {
    address user = msg.sender;
    unbackedDebt[user] = unbackedDebt[user] - rad;
    debt[user] = debt[user] - rad;
    totalUnbackedDebt = totalUnbackedDebt - rad;
    totalDebt = totalDebt - rad;
    emit SettleUnbackedDebt(user, rad);
  }

  function createUnbackedDebt(
    address unbackedDebtAccount,
    address debtAccount,
    uint256 rad
  ) external isAuthorized {
    unbackedDebt[unbackedDebtAccount] = unbackedDebt[unbackedDebtAccount] + rad;
    debt[debtAccount] = debt[debtAccount] + rad;
    totalUnbackedDebt = totalUnbackedDebt + rad;
    totalDebt = totalDebt + rad;
    emit CreateUnbackedDebt(
      debtAccount,
      unbackedDebtAccount,
      rad,
      debt[debtAccount],
      unbackedDebt[unbackedDebtAccount]
    );
  }

  // --- Rates ---
  function updateAccumulatedRate(
    bytes32 collateralType,
    address debtDestination,
    int256 accumulatedRateDelta
  ) external isAuthorized isLive {
    CollateralType storage collateralTypeData = collateralTypes[collateralType];
    collateralTypeData.accumulatedRate = addInt(
      collateralTypeData.accumulatedRate,
      accumulatedRateDelta
    );
    int256 debtDelta = mulInt(
      collateralTypeData.normalizedDebt,
      accumulatedRateDelta
    );
    debt[debtDestination] = addInt(debt[debtDestination], debtDelta);
    totalDebt = addInt(totalDebt, debtDelta);
    emit UpdateAccumulatedRate(
      collateralType,
      debtDestination,
      accumulatedRateDelta,
      debtDelta
    );
  }
}