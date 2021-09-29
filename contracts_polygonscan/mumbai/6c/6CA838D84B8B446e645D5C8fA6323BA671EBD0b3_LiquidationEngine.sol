/**
 *Submitted for verification at polygonscan.com on 2021-09-28
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

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


// File contracts/LiquidationEngine.sol
pragma solidity ^0.8.2;

interface LiquidationAuctionLike {
  function collateralType() external view returns (bytes32);

  function startAuction(
    uint256 debtToRaise,
    uint256 collateralToSell,
    address position,
    address keeper
  ) external returns (uint256);
}

interface LedgerLike {
  function collateralTypes(bytes32)
    external
    view
    returns (
      uint256 normalizedDebt, // [wad]
      uint256 accumulatedRate, // [ray]
      uint256 safetyPrice, // [ray]
      uint256 debtCeiling, // [rad]
      uint256 debtFloor // [rad]
    );

  function positions(bytes32, address)
    external
    view
    returns (
      uint256 lockedCollateral, // [wad]
      uint256 normalizedDebt // [wad]
    );

  function confiscateCollateralAndDebt(
    bytes32 collateralType,
    address user,
    address collateralCounterparty,
    address debtCounterparty,
    int256 collateralDelta,
    int256 normalizedDebtDelta
  ) external;
}

interface AccountingEngineLike {
  function pushDebtToQueue(uint256) external;
}

contract LiquidationEngine is Initializable {
  uint256 constant WAD = 10**18;

  // --- Data ---
  struct CollateralTypes {
    address liquidationAuction; // LiquidationAuction
    uint256 liquidatonPenalty; // Liquidation Penalty [wad]                                          [wad]
    uint256 maxDebtForActiveAuctions; // Max debt needed to cover debt+fees of active auctions per ilk [rad]
    uint256 debtRequiredForActiveAuctions; // Amt debt needed to cover debt+fees of active auctions per ilk [rad]
  }

  mapping(address => uint256) public authorizedAccounts;
  LedgerLike public ledger; // CDP Engine

  mapping(bytes32 => CollateralTypes) public collateralTypes;

  AccountingEngineLike public accountingEngine; // Debt Engine
  uint256 public live; // Active Flag
  uint256 public globalMaxDebtForActiveAuctions; // Max debt needed to cover debt+fees of active auctions [rad]
  uint256 public globalDebtRequiredForActiveAuctions; // Amt debt needed to cover debt+fees of active auctions [rad]

  // --- Events ---
  event GrantAuthorization(address indexed account);
  event RevokeAuthorization(address indexed account);
  event UpdateParameter(bytes32 indexed parameter, uint256 data);
  event UpdateParameter(bytes32 indexed parameter, address data);
  event UpdateParameter(
    bytes32 indexed parameter,
    bytes32 indexed collateralType,
    uint256 data
  );
  event UpdateParameter(
    bytes32 indexed parameter,
    bytes32 indexed collateralType,
    address data
  );
  event LiquidatePosition(
    bytes32 indexed collateralType,
    uint256 indexed auctionId,
    address indexed position,
    uint256 lockedCollateralToConfiscate,
    uint256 normalizedDebtToConfiscate,
    uint256 debtConfiscated,
    address liquidationAuction
  );
  event DebtRemoved(bytes32 indexed ilk, uint256 rad);
  event Shutdown();

  // --- Init ---
  function initialize(address ledger_) public initializer {
    ledger = LedgerLike(ledger_);
    live = 1;
    authorizedAccounts[msg.sender] = 1;
    emit GrantAuthorization(msg.sender);
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

  modifier isAuthorized() {
    require(authorizedAccounts[msg.sender] == 1, "Core/not-authorized");
    _;
  }

  // --- Math ---
  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x <= y ? x : y;
  }

  // --- Administration ---
  function updateAccountingEngine(address data) external isAuthorized {
    accountingEngine = AccountingEngineLike(data);
    emit UpdateParameter("accountingEngine", data);
  }

  function updateGlobalMaxDebtForActiveAuctions(uint256 data)
    external
    isAuthorized
  {
    globalMaxDebtForActiveAuctions = data;
    emit UpdateParameter("globalMaxDebtForActiveAuctions", data);
  }

  function updateLiquidatonPenalty(bytes32 collateralType, uint256 data)
    external
    isAuthorized
  {
    require(data >= WAD, "LiquidationEngine/file-liquidatonPenalty-lt-WAD");
    collateralTypes[collateralType].liquidatonPenalty = data;
    emit UpdateParameter("liquidatonPenalty", collateralType, data);
  }

  function updateMaxDebtForActiveAuctions(bytes32 collateralType, uint256 data)
    external
    isAuthorized
  {
    collateralTypes[collateralType].maxDebtForActiveAuctions = data;
    emit UpdateParameter("maxDebtForActiveAuctions", collateralType, data);
  }

  function updateLiquidationAuction(
    bytes32 collateralType,
    address liquidationAuction
  ) external isAuthorized {
    require(
      collateralType ==
        LiquidationAuctionLike(liquidationAuction).collateralType(),
      "LiquidationEngine/file-collateralType-neq-liquidationAuction.collateralType"
    );
    collateralTypes[collateralType].liquidationAuction = liquidationAuction;
    emit UpdateParameter(
      "liquidationAuction",
      collateralType,
      liquidationAuction
    );
  }

  function liquidatonPenalty(bytes32 ilk) external view returns (uint256) {
    return collateralTypes[ilk].liquidatonPenalty;
  }

  // --- CDP Liquidation ---
  //
  // Liquidate a Vault and start a Dutch auction to sell its collateral for debt.
  //
  // The third argument is the address that will receive the liquidation reward, if any.
  //
  // The entire Vault will be liquidated except when the target amount of debt to be raised in
  // the resulting auction (debt of Vault + liquidation penalty) causes either globalDebtRequiredForActiveAuctions to exceed
  // globalMaxDebtForActiveAuctions or ilk.debtRequiredForActiveAuctions to exceed ilk.maxDebtForActiveAuctions by an economically significant amount. In that
  // case, a partial liquidation is performed to respect the global and per-ilk limits on
  // outstanding debt target. The one exception is if the resulting auction would likely
  // have too little collateral to be interesting to Keepers (debt taken from Vault < ilk.debtFloor),
  // in which case the function reverts. Please refer to the code and comments within if
  // more detail is desired.
  function liquidatePosition(
    bytes32 collateralType,
    address position,
    address keeper
  ) external returns (uint256 auctionId) {
    require(live == 1, "LiquidationEngine/not-live");

    (uint256 lockedCollateral, uint256 normalizedDebt) = ledger.positions(
      collateralType,
      position
    );
    CollateralTypes memory collateralTypeData = collateralTypes[collateralType];
    uint256 normalizedDebtToConfiscate;
    uint256 accumulatedRate;
    uint256 debtFloor;
    {
      uint256 safetyPrice;
      (, accumulatedRate, safetyPrice, , debtFloor) = ledger.collateralTypes(
        collateralType
      );
      require(
        safetyPrice > 0 &&
          lockedCollateral * safetyPrice < normalizedDebt * accumulatedRate,
        "LiquidationEngine/not-unsafe"
      );

      // Get the minimum value between:
      // 1) Remaining space in the general globalMaxDebtForActiveAuctions
      // 2) Remaining space in the collateral maxDebtForActiveAuctions
      require(
        globalMaxDebtForActiveAuctions > globalDebtRequiredForActiveAuctions &&
          collateralTypeData.maxDebtForActiveAuctions >
          collateralTypeData.debtRequiredForActiveAuctions,
        "LiquidationEngine/liquidation-limit-hit"
      );
      uint256 maximumDebtAllowedToBeLiquidated = min(
        globalMaxDebtForActiveAuctions - globalDebtRequiredForActiveAuctions,
        collateralTypeData.maxDebtForActiveAuctions -
          collateralTypeData.debtRequiredForActiveAuctions
      );

      // uint256.max()/(RAD*WAD) = 115,792,089,237,316
      normalizedDebtToConfiscate = min(
        normalizedDebt,
        (maximumDebtAllowedToBeLiquidated * WAD) /
          accumulatedRate /
          collateralTypeData.liquidatonPenalty
      );

      // Partial liquidation edge case logic
      if (normalizedDebt > normalizedDebtToConfiscate) {
        if (
          (normalizedDebt - normalizedDebtToConfiscate) * accumulatedRate <
          debtFloor
        ) {
          // If the leftover Vault would be debtFloory, just liquidate it entirely.
          // This will result in at least one of debtRequiredForActiveAuction_is > maxDebtForActiveAuctions_i or globalDebtRequiredForActiveAuctions > globalMaxDebtForActiveAuctions becoming true.
          // The amount of excess will be bounded above by ceiling(debtFloor_i * liquidatonPenalty_i / WAD).
          // This deviation is assumed to be small compared to both maxDebtForActiveAuctions_i and globalMaxDebtForActiveAuctions, so that
          // the extra amount of target debt over the limits intended is not of economic concern.
          normalizedDebtToConfiscate = normalizedDebt;
        } else {
          // In a partial liquidation, the resulting auction should also be non-debtFloory.
          require(
            normalizedDebtToConfiscate * accumulatedRate >= debtFloor,
            "LiquidationEngine/debtFloory-auction-from-pnormalizedDebtial-liquidation"
          );
        }
      }
    }

    uint256 lockedCollateralToConfiscate = (lockedCollateral *
      normalizedDebtToConfiscate) / normalizedDebt;

    require(lockedCollateralToConfiscate > 0, "LiquidationEngine/null-auction");
    require(
      normalizedDebtToConfiscate <= 2**255 &&
        lockedCollateralToConfiscate <= 2**255,
      "LiquidationEngine/overflow"
    );

    ledger.confiscateCollateralAndDebt(
      collateralType,
      position,
      collateralTypeData.liquidationAuction,
      address(accountingEngine),
      -int256(lockedCollateralToConfiscate),
      -int256(normalizedDebtToConfiscate)
    );

    uint256 debtConfiscated = normalizedDebtToConfiscate * accumulatedRate;
    accountingEngine.pushDebtToQueue(debtConfiscated);

    {
      // Avoid stack too deep
      // This calcuation will overflow if normalizedDebtToConfiscate*accumulatedRate exceeds ~10^14
      uint256 debtWithPenalty = (debtConfiscated *
        collateralTypeData.liquidatonPenalty) / WAD;
      globalDebtRequiredForActiveAuctions =
        globalDebtRequiredForActiveAuctions +
        debtWithPenalty;
      collateralTypes[collateralType].debtRequiredForActiveAuctions =
        collateralTypeData.debtRequiredForActiveAuctions +
        debtWithPenalty;

      auctionId = LiquidationAuctionLike(collateralTypeData.liquidationAuction)
        .startAuction({
          debtToRaise: debtWithPenalty,
          collateralToSell: lockedCollateralToConfiscate,
          position: position,
          keeper: keeper
        });
    }

    emit LiquidatePosition(
      collateralType,
      auctionId,
      position,
      lockedCollateralToConfiscate,
      normalizedDebtToConfiscate,
      debtConfiscated,
      collateralTypeData.liquidationAuction
    );
  }

  function removeDebtFromLiquidation(bytes32 collateralType, uint256 rad)
    external
    isAuthorized
  {
    globalDebtRequiredForActiveAuctions =
      globalDebtRequiredForActiveAuctions -
      rad;
    collateralTypes[collateralType].debtRequiredForActiveAuctions =
      collateralTypes[collateralType].debtRequiredForActiveAuctions -
      rad;
    emit DebtRemoved(collateralType, rad);
  }

  function shutdown() external isAuthorized {
    live = 0;
    emit Shutdown();
  }
}