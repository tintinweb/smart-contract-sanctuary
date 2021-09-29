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


// File contracts/OracleRelayer.sol

pragma solidity ^0.8.2;

interface LedgerLike {
  function updateSafetyPrice(bytes32 collateralType, uint256 data) external;
}

interface OracleLike {
  function getPrice() external returns (uint256, bool); // wad
}

contract OracleRelayer is Initializable {
  uint256 constant ONE = 10**27;

  struct CollateralType {
    OracleLike oracle; // Price Feed
    uint256 collateralizationRatio; // Liquidation ratio [ray]
  }

  mapping(address => uint256) public authorizedAccounts;
  mapping(bytes32 => CollateralType) public collateralTypes;

  LedgerLike public ledger; // CDP Engine
  uint256 public redemptionPrice; // ref per dai [ray]
  uint256 public live;

  // --- Events ---
  event GrantAuthorization(address indexed account);
  event RevokeAuthorization(address indexed account);
  event UpdateCollateralPrice(
    bytes32 collateralType,
    uint256 price, // [wad]
    uint256 safetyPrice // [ray]
  );
  event UpdateParameter(bytes32 indexed parameter, uint256 data);
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

  // --- Init ---
  function initialize(address ledger_) public initializer {
    authorizedAccounts[msg.sender] = 1;
    ledger = LedgerLike(ledger_);
    redemptionPrice = ONE;
    live = 1;
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
    require(
      authorizedAccounts[msg.sender] == 1,
      "OracleRelayer/not-authorized"
    );
    _;
  }

  // --- Math ---
  function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = (x * ONE) / y;
  }

  // --- Administration ---
  function updateOracle(bytes32 collateralType, address oracle_)
    external
    isAuthorized
  {
    collateralTypes[collateralType].oracle = OracleLike(oracle_);
    emit UpdateParameter("oracle", collateralType, oracle_);
  }

  function updateRedemptionPrice(uint256 data) external isAuthorized {
    redemptionPrice = data;
    emit UpdateParameter("redemptionPrice", data);
  }

  function updateCollateralizationRatio(bytes32 collateralType, uint256 data)
    external
    isAuthorized
  {
    require(data >= ONE, "OracleRelayer/ratio-lt-ray");
    collateralTypes[collateralType].collateralizationRatio = data;
    emit UpdateParameter("collateralizationRatio", collateralType, data);
  }

  // --- Update value ---
  function updateCollateralPrice(bytes32 collateralType) external {
    (uint256 price, bool isValidPrice) = collateralTypes[collateralType]
      .oracle
      .getPrice();
    uint256 safetyPrice = isValidPrice
      ? rdiv(
        rdiv(price * 10**9, redemptionPrice),
        collateralTypes[collateralType].collateralizationRatio
      )
      : 0;
    ledger.updateSafetyPrice(collateralType, safetyPrice);
    emit UpdateCollateralPrice(collateralType, price, safetyPrice);
  }

  function shutdown() external isAuthorized {
    live = 0;
  }
}