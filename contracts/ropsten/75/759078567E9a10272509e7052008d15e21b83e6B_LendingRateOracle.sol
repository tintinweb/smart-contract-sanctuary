// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import '../interfaces/IManagedLendingRateOracle.sol';
import '../interfaces/ILendingRateOracle.sol';
import '../access/MarketAccessBitmask.sol';
import '../access/AccessFlags.sol';
import '../access/interfaces/IMarketAccessController.sol';

contract LendingRateOracle is ILendingRateOracle, IManagedLendingRateOracle, MarketAccessBitmask {
  mapping(address => uint256) borrowRates;
  mapping(address => uint256) liquidityRates;

  constructor(IMarketAccessController remoteAcl) public MarketAccessBitmask(remoteAcl) {}

  function getMarketBorrowRate(address _asset) external view override returns (uint256) {
    return borrowRates[_asset];
  }

  function setMarketBorrowRate(address _asset, uint256 _rate)
    external
    override
    aclHas(AccessFlags.LENDING_RATE_ADMIN)
  {
    borrowRates[_asset] = _rate;
  }

  function setMarketBorrowRates(address[] calldata assets, uint256[] calldata rates)
    external
    override
    aclHas(AccessFlags.LENDING_RATE_ADMIN)
  {
    require(assets.length == rates.length, 'array lengths different');

    for (uint256 i = 0; i < assets.length; i++) {
      borrowRates[assets[i]] = rates[i];
    }
  }

  function getMarketLiquidityRate(address _asset) external view returns (uint256) {
    return liquidityRates[_asset];
  }

  function setMarketLiquidityRate(address _asset, uint256 _rate)
    external
    aclHas(AccessFlags.LENDING_RATE_ADMIN)
  {
    liquidityRates[_asset] = _rate;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IManagedLendingRateOracle {
  /// @dev sets the market borrow rate. Rate value must be in ray
  function setMarketBorrowRate(address asset, uint256 rate) external;

  /// @dev sets the market borrow rates. Rate value must be in ray
  function setMarketBorrowRates(address[] calldata assets, uint256[] calldata rates) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/// @dev Interface for the Aave borrow rate oracle. Provides the average market borrow rate to be used as a base for the stable borrow rate calculations
interface ILendingRateOracle {
  /// @dev returns the market borrow rate in ray
  function getMarketBorrowRate(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.12;

import './interfaces/IMarketAccessController.sol';
import './AccessHelper.sol';
import './AccessFlags.sol';
import '../tools/Errors.sol';

contract MarketAccessBitmask {
  using AccessHelper for IMarketAccessController;
  IMarketAccessController internal _remoteAcl;

  constructor(IMarketAccessController remoteAcl) internal {
    _remoteAcl = remoteAcl;
  }

  function _getRemoteAcl(address addr) internal view returns (uint256) {
    return _remoteAcl.getAcl(addr);
  }

  function hasRemoteAcl() internal view returns (bool) {
    return _remoteAcl != IMarketAccessController(0);
  }

  function acl_hasAllOf(address subject, uint256 flags) internal view returns (bool) {
    return _remoteAcl.hasAllOf(subject, flags);
  }

  function acl_hasAnyOf(address subject, uint256 flags) internal view returns (bool) {
    return _remoteAcl.hasAnyOf(subject, flags);
  }

  function acl_requireAllOf(
    address subject,
    uint256 flags,
    string memory text
  ) internal view {
    require(_remoteAcl.hasAllOf(subject, flags), text);
  }

  function acl_requireAnyOf(
    address subject,
    uint256 flags,
    string memory text
  ) internal view {
    require(_remoteAcl.hasAnyOf(subject, flags), text);
  }

  modifier aclHas(uint256 flags) virtual {
    acl_requireAllOf(msg.sender, flags, Errors.TXT_ACCESS_RESTRICTED);
    _;
  }

  modifier aclAllOf(uint256 flags) {
    acl_requireAllOf(msg.sender, flags, Errors.TXT_ACCESS_RESTRICTED);
    _;
  }

  modifier aclAnyOf(uint256 flags) {
    acl_requireAnyOf(msg.sender, flags, Errors.TXT_ACCESS_RESTRICTED);
    _;
  }

  modifier onlyPoolAdmin {
    acl_requireAllOf(msg.sender, AccessFlags.POOL_ADMIN, Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  modifier onlyEmergencyAdmin {
    acl_requireAllOf(msg.sender, AccessFlags.EMERGENCY_ADMIN, Errors.CALLER_NOT_EMERGENCY_ADMIN);
    _;
  }

  modifier onlySweepAdmin {
    acl_requireAllOf(msg.sender, AccessFlags.SWEEP_ADMIN, Errors.CT_CALLER_MUST_BE_SWEEP_ADMIN);
    _;
  }

  modifier onlyRewardAdmin {
    acl_requireAllOf(
      msg.sender,
      AccessFlags.REWARD_CONFIG_ADMIN,
      Errors.CT_CALLER_MUST_BE_REWARD_ADMIN
    );
    _;
  }

  modifier onlyRewardConfiguratorOrAdmin {
    acl_requireAnyOf(
      msg.sender,
      AccessFlags.REWARD_CONFIG_ADMIN | AccessFlags.REWARD_CONFIGURATOR,
      Errors.CT_CALLER_MUST_BE_REWARD_ADMIN
    );
    _;
  }

  modifier onlyRewardRateAdmin {
    acl_requireAllOf(
      msg.sender,
      AccessFlags.REWARD_RATE_ADMIN,
      Errors.CT_CALLER_MUST_BE_REWARD_RATE_ADMIN
    );
    _;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.12;

library AccessFlags {
  uint256 public constant ROLES = (uint256(1) << 16) - 1;
  uint256 public constant SINGLETONS = ((uint256(1) << 64) - 1) & ~ROLES;
  uint256 public constant PROXIES =
    LENDING_POOL |
      LENDING_POOL_CONFIGURATOR |
      TREASURY |
      REWARD_TOKEN |
      REWARD_STAKE_TOKEN |
      REWARD_CONTROLLER |
      REWARD_CONFIGURATOR |
      REFERRAL_REGISTRY |
      STAKE_CONFIGURATOR;

  // various admins & managers - use range [0..15]
  // these roles can be assigned to multiple addresses

  uint256 public constant EMERGENCY_ADMIN = 1 << 0;
  uint256 public constant POOL_ADMIN = 1 << 1;
  uint256 public constant TREASURY_ADMIN = 1 << 2;
  uint256 public constant REWARD_CONFIG_ADMIN = 1 << 3;
  uint256 public constant REWARD_RATE_ADMIN = 1 << 4;
  uint256 public constant STAKE_ADMIN = 1 << 5;
  uint256 public constant REFERRAL_ADMIN = 1 << 6;
  uint256 public constant LENDING_RATE_ADMIN = 1 << 7;
  uint256 public constant SWEEP_ADMIN = 1 << 8;
  uint256 public constant ORACLE_ADMIN = 1 << 9;

  uint256 public constant LIQUIDITY_CONTROLLER = 1 << 15; // can slash & pause stakes

  // singletons - use range [16..64]
  // these roles can ONLY be assigned to a single address
  uint256 public constant LENDING_POOL = 1 << 16; // use proxy
  uint256 public constant LENDING_POOL_CONFIGURATOR = 1 << 17; // use proxy

  uint256 public constant PRICE_ORACLE = 1 << 19;
  uint256 public constant LENDING_RATE_ORACLE = 1 << 20;
  uint256 public constant TREASURY = 1 << 21; // use proxy

  uint256 public constant REWARD_TOKEN = 1 << 22; // use proxy
  uint256 public constant REWARD_STAKE_TOKEN = 1 << 23; // use proxy
  uint256 public constant REWARD_CONTROLLER = 1 << 24; // use proxy
  uint256 public constant REWARD_CONFIGURATOR = 1 << 25; // use proxy

  uint256 public constant STAKE_CONFIGURATOR = 1 << 26; // use proxy

  uint256 public constant REFERRAL_REGISTRY = 1 << 27; // use proxy

  uint256 public constant WETH_GATEWAY = 1 << 28;

  uint256 public constant DATA_HELPER = 1 << 29;

  // any other roles - use range [64..]
  // these roles can be assigned to multiple addresses

  uint256 public constant REWARD_MINT = 1 << 64;
  uint256 public constant REWARD_BURN = 1 << 65;

  uint256 public constant POOL_SPONSORED_LOAN_USER = 1 << 66;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import './IAccessController.sol';

/**
 * @title IMarketAccessController contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 **/
interface IMarketAccessController is IAccessController {
  function getMarketId() external view returns (string memory);

  function getLendingPool() external view returns (address);

  // Deprecated, for backward compatibility & scritps. By contracts use AccessHelper and AccessFlags instead.
  function getLendingPoolConfigurator() external view returns (address);

  function isPoolAdmin(address) external view returns (bool);

  function getPriceOracle() external view returns (address);

  function getLendingRateOracle() external view returns (address);

  function getTreasury() external view returns (address);

  function getRewardToken() external view returns (address);

  function getRewardStakeToken() external view returns (address);

  function getRewardController() external view returns (address);

  function getRewardConfigurator() external view returns (address);

  function getStakeConfigurator() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import '../tools/math/BitUtils.sol';
import './interfaces/IRemoteAccessBitmask.sol';

/// @dev Helper/wrapper around IRemoteAccessBitmask
library AccessHelper {
  using BitUtils for uint256;

  function getAcl(IRemoteAccessBitmask remote, address subject) internal view returns (uint256) {
    return remote.queryAccessControlMask(subject, ~uint256(0));
  }

  function queryAcl(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 filterMask
  ) internal view returns (uint256) {
    return remote.queryAccessControlMask(subject, filterMask);
  }

  function hasAnyOf(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 flags
  ) internal view returns (bool) {
    return queryAcl(remote, subject, flags).hasAnyOf(flags);
  }

  function hasAllOf(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 flags
  ) internal view returns (bool) {
    return queryAcl(remote, subject, flags).hasAllOf(flags);
  }

  function hasNoneOf(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 flags
  ) internal view returns (bool) {
    return queryAcl(remote, subject, flags).hasNoneOf(flags);
  }

  function hasAny(IRemoteAccessBitmask remote, address subject) internal view returns (bool) {
    return remote.queryAccessControlMask(subject, 0) != 0;
  }

  function hasNone(IRemoteAccessBitmask remote, address subject) internal view returns (bool) {
    return remote.queryAccessControlMask(subject, 0) == 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (DepositToken, VariableDebtToken and StableDebtToken)
 *  - AT = DepositToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = AddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolExtension
 *  - ST = Stake
 */
library Errors {
  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = '33'; // 'The caller must be the pool admin'
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small

  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = '3'; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = '4'; // 'The current liquidity is not enough'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // 'User cannot withdraw more than the available balance'
  string public constant VL_TRANSFER_NOT_ALLOWED = '6'; // 'Transfer cannot be allowed.'
  string public constant VL_BORROWING_NOT_ENABLED = '7'; // 'Borrowing is not enabled'
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // 'Invalid interest rate mode selected'
  string public constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // 'The collateral balance is 0'
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // 'Health factor is lesser than the liquidation threshold'
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // 'There is not enough collateral to cover a new borrow'
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // 'The requested amount is greater than the max loan size in stable rate mode
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // 'To repay on behalf of an user an explicit amount to repay is needed'
  string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // 'User does not have a stable rate loan in progress on this reserve'
  string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // 'User does not have a variable rate loan in progress on this reserve'
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // 'The underlying balance needs to be greater than 0'
  string public constant VL_DEPOSIT_ALREADY_IN_USE = '20'; // 'User deposit is already being used as collateral'
  string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = '21'; // 'User does not have any stable rate loan for this reserve'
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // 'Interest rate rebalance conditions were not met'
  //  string public constant LP_LIQUIDATION_CALL_FAILED = '23'; // 'Liquidation call failed'
  string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = '24'; // 'There is not enough liquidity available to borrow'
  string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = '25'; // 'The requested amount is too small for a FlashLoan.'
  string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = '26'; // 'The actual balance of the protocol is inconsistent'
  string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = '27'; // 'The caller of the function is not the lending pool configurator'
  string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = '28';
  string public constant CT_CALLER_MUST_BE_LENDING_POOL = '29'; // 'The caller of this function must be a lending pool'
  string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = '30'; // 'User cannot give allowance to himself'
  string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = '31'; // 'Transferred amount needs to be greater than zero'
  string public constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // 'Reserve has already been initialized'
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = '34'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = '35'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = '36'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = '37'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '38'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '39'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = '40'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPAPR_PROVIDER_NOT_REGISTERED = '41'; // 'Provider is not registered'
  string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // 'Health factor is not below the threshold'
  string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // 'The collateral chosen cannot be liquidated'
  string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // 'User did not borrow the specified currency'
  string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // "There isn't enough liquidity available to liquidate"
  //  string public constant LPCM_NO_ERRORS = '46'; // 'No errors'
  string public constant LP_INVALID_FLASHLOAN_MODE = '47'; //Invalid flashloan mode selected
  string public constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string public constant MATH_ADDITION_OVERFLOW = '49';
  string public constant MATH_DIVISION_BY_ZERO = '50';
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = '51'; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = '52'; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = '53'; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = '54'; //  Variable borrow rate overflows uint128
  string public constant RL_STABLE_BORROW_RATE_OVERFLOW = '55'; //  Stable borrow rate overflows uint128
  string public constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string public constant LP_FAILED_REPAY_WITH_COLLATERAL = '57';
  string public constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string public constant LP_FAILED_COLLATERAL_SWAP = '60';
  string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = '61';
  string public constant LP_REENTRANCY_NOT_ALLOWED = '62';
  string public constant LP_CALLER_MUST_BE_AN_ATOKEN = '63';
  string public constant LP_IS_PAUSED = '64'; // 'Pool is paused'
  string public constant LP_NO_MORE_RESERVES_ALLOWED = '65';
  string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = '66';
  string public constant RC_INVALID_LTV = '67';
  string public constant RC_INVALID_LIQ_THRESHOLD = '68';
  string public constant RC_INVALID_LIQ_BONUS = '69';
  string public constant RC_INVALID_DECIMALS = '70';
  string public constant RC_INVALID_RESERVE_FACTOR = '71';
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = '72';
  string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = '73';
  string public constant LP_INCONSISTENT_PARAMS_LENGTH = '74';
  string public constant LPC_INVALID_CONFIGURATION = '75'; // 'Invalid risk parameters for the reserve'
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '76'; // 'The caller must be the emergency admin'
  string public constant UL_INVALID_INDEX = '77';
  string public constant LP_NOT_CONTRACT = '78';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '79';
  string public constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string public constant CT_CALLER_MUST_BE_REWARD_ADMIN = '81'; // 'The caller of this function must be a reward admin'
  string public constant LP_INVALID_PERCENTAGE = '82'; // 'Percentage can't be more than 100%'
  string public constant LP_IS_NOT_SPONSORED_LOAN = '83';
  string public constant CT_CALLER_MUST_BE_SWEEP_ADMIN = '84';
  string public constant LP_TOO_MANY_NESTED_CALLS = '85';
  string public constant LP_RESTRICTED_FEATURE = '86';

  string public constant CT_CALLER_MUST_BE_REWARD_RATE_ADMIN = '89';
  string public constant CT_CALLER_MUST_BE_REWARD_CONTROLLER = '90';
  string public constant RW_REWARD_PAUSED = '91';
  string public constant CT_CALLER_MUST_BE_TEAM_MANAGER = '92';

  string public constant STK_REDEEM_PAUSED = '93';
  string public constant STK_INSUFFICIENT_COOLDOWN = '94';
  string public constant STK_UNSTAKE_WINDOW_FINISHED = '95';
  string public constant STK_INVALID_BALANCE_ON_COOLDOWN = '96';
  string public constant STK_EXCESSIVE_SLASH_PCT = '97';
  string public constant STK_EXCESSIVE_COOLDOWN_PERIOD = '98';
  string public constant STK_WRONG_UNSTAKE_PERIOD = '98';

  string public constant VL_CONTRACT_REQUIRED = '99'; // The address is not a contract

  string public constant TXT_OWNABLE_CALLER_NOT_OWNER = 'Ownable: caller is not the owner';
  string public constant TXT_CALLER_NOT_PROXY_OWNER = 'ProxyOwner: caller is not the owner';
  string public constant TXT_ACCESS_RESTRICTED = 'RESTRICTED';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import './IRemoteAccessBitmask.sol';
import '../../tools/upgradeability/IProxy.sol';

/// @dev Main registry of permissions and addresses
interface IAccessController is IRemoteAccessBitmask {
  function getAddress(uint256 id) external view returns (address);

  function createProxy(
    address admin,
    address impl,
    bytes calldata params
  ) external returns (IProxy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IRemoteAccessBitmask {
  /// @notice Returns access flags granted to the given address and limited by the filterMask.
  /// @dev Zero value of filterMask has a special meaning.
  /// @param addr a parameter just like in doxygen (must be followed by parameter name)
  /// @param filterMask limits a subset of flags to be checked.
  ///        When filterMask is zero, the function will return zero if no flags granted, or an unspecified non zero value otherwise.
  /// @return Access flags currently granted
  function queryAccessControlMask(address addr, uint256 filterMask) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IProxy {
  function implementation() external returns (address);

  function upgradeTo(address newImplementation) external;

  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

library BitUtils {
  function hasAnyOf(uint256 v, uint256 flags) internal pure returns (bool) {
    return v & flags != 0;
  }

  function hasAllOf(uint256 v, uint256 flags) internal pure returns (bool) {
    return v & flags == flags;
  }

  function isBit(uint256 v, uint8 index) internal pure returns (bool) {
    return v & (uint256(1) << index) != 0;
  }

  function hasNoneOf(uint256 v, uint256 flags) internal pure returns (bool) {
    return v & flags == 0;
  }

  function nextPowerOf2(uint256 v) internal pure returns (uint256) {
    if (v == 0) {
      return 1;
    }
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v |= v >> 32;
    v |= v >> 64;
    v |= v >> 128;
    return v + 1;
  }

  function isPowerOf2(uint256 v) internal pure returns (bool) {
    return (v & (v - 1)) == 0;
  }

  function isPowerOf2nz(uint256 v) internal pure returns (bool) {
    if (v == 0) {
      return false;
    }
    return (v & (v - 1)) == 0;
  }

  function bitLength(uint256 v) internal pure returns (uint256 len) {
    if (v == 0) {
      return 0;
    }
    if (v > type(uint128).max) {
      v >>= 128;
      len += 128;
    }
    if (v > type(uint64).max) {
      v >>= 64;
      len += 64;
    }
    if (v > type(uint32).max) {
      v >>= 32;
      len += 32;
    }
    if (v > type(uint16).max) {
      v >>= 16;
      len += 16;
    }
    if (v > type(uint8).max) {
      v >>= 8;
      len += 8;
    }
    if (v > 15) {
      v >>= 4;
      len += 4;
    }
    if (v > 3) {
      v >>= 2;
      len += 2;
    }
    if (v > 1) {
      len += 1;
    }
    return len;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}