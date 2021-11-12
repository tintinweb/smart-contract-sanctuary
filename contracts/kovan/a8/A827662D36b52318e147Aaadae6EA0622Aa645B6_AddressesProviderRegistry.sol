// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/SafeOwnable.sol';
import '../interfaces/IAddressesProviderRegistry.sol';
import '../tools/Errors.sol';

/**
 * @title AddressesProviderRegistry contract
 * @dev Main registry of AddressesProvider of multiple protocol's markets
 * - Used for indexing purposes of protocol's markets
 * - The id assigned to an AddressesProvider refers to the market it is connected with,
 *   for example with `1` for the first market, `2` for the next one, etc
 **/
contract AddressesProviderRegistry is SafeOwnable, IAddressesProviderRegistry {
  struct Entry {
    uint256 id;
    uint16 index;
  }
  mapping(address => Entry) private _index;
  address[] private _providers;

  address private _oneTimeRegistrar;
  uint256 private _oneTimeId;

  function setOneTimeRegistrar(address registrar, uint256 expectedId) external override onlyOwner {
    _oneTimeId = expectedId;
    _oneTimeRegistrar = registrar;
  }

  function renounceOneTimeRegistrar() external override {
    if (_oneTimeRegistrar == msg.sender) {
      _oneTimeRegistrar = address(0);
    }
  }

  function getOneTimeRegistrar() external view override returns (address user, uint256 expectedId) {
    if (_oneTimeRegistrar == address(0)) {
      return (address(0), 0);
    }
    return (_oneTimeRegistrar, _oneTimeId);
  }

  /**
   * @dev Returns the list of registered addresses provider
   * @return activeProviders - list of addresses provider, potentially containing address(0) elements
   **/
  function getAddressesProvidersList() external view override returns (address[] memory activeProviders) {
    return _providers;
  }

  function prepareAddressesProvider(address provider) external override {
    require(msg.sender == _oneTimeRegistrar || msg.sender == owner(), Errors.TXT_OWNABLE_CALLER_NOT_OWNER);
    require(provider != address(0) && _index[provider].index == 0, Errors.LPAPR_PROVIDER_NOT_REGISTERED);
    emit AddressesProviderPreparing(provider);
  }

  /**
   * @dev Registers an addresses provider
   * @param provider The address of the new AddressesProvider
   * @param id The id for the new AddressesProvider, referring to the market it belongs to
   **/
  function registerAddressesProvider(address provider, uint256 id) external override {
    if (msg.sender == _oneTimeRegistrar) {
      require(_oneTimeId == 0 || _oneTimeId == id, Errors.LPAPR_INVALID_ADDRESSES_PROVIDER_ID);
      _oneTimeRegistrar = address(0);
    } else {
      require(msg.sender == owner(), Errors.TXT_OWNABLE_CALLER_NOT_OWNER);
      require(id != 0, Errors.LPAPR_INVALID_ADDRESSES_PROVIDER_ID);
    }

    require(provider != address(0), Errors.LPAPR_PROVIDER_NOT_REGISTERED);

    if (_index[provider].index > 0) {
      _index[provider].id = id;
    } else {
      require(_providers.length < type(uint16).max);
      _providers.push(provider);
      _index[provider] = Entry(id, uint16(_providers.length));
    }

    emit AddressesProviderRegistered(provider);
  }

  /**
   * @dev Removes a AddressesProvider from the list of registered addresses provider
   * @param provider The AddressesProvider address
   **/
  function unregisterAddressesProvider(address provider) external override onlyOwner {
    uint256 idx = _index[provider].index;
    require(idx != 0, Errors.LPAPR_PROVIDER_NOT_REGISTERED);

    delete (_index[provider]);
    if (idx == _providers.length) {
      _providers.pop();
    } else {
      _providers[idx - 1] = address(0);
    }
    for (; _providers.length > 0 && _providers[_providers.length - 1] == address(0); ) {
      _providers.pop();
    }

    emit AddressesProviderUnregistered(provider);
  }

  /**
   * @dev Returns the id on a registered AddressesProvider
   * @return The id or 0 if the AddressesProvider is not registered
   */
  function getAddressesProviderIdByAddress(address provider) external view override returns (uint256) {
    return _index[provider].id;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * Ownership is transferred in 2 phases: current owner calls {transferOwnership}
 * then the new owner calls {acceptOwnership}.
 * The last owner can recover ownership with {recoverOwnership} before {acceptOwnership} is called by the new owner.
 *
 * When ownership transfer was initiated, this module behaves like there is no owner, until
 * either acceptOwnership() or recoverOwnership() is called.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract SafeOwnable {
  address private _lastOwner;
  address private _activeOwner;
  address private _pendingOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferring(address indexed previousOwner, address indexed pendingOwner);

  /// @dev Initializes the contract setting the deployer as the initial owner.
  constructor() {
    _activeOwner = msg.sender;
    _pendingOwner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  /// @dev Returns active owner
  function owner() public view returns (address) {
    return _activeOwner;
  }

  function owners()
    public
    view
    returns (
      address lastOwner,
      address activeOwner,
      address pendingOwner
    )
  {
    return (_lastOwner, _activeOwner, _pendingOwner);
  }

  /// @dev Reverts if called by any account other than the owner.
  /// Will also revert after transferOwnership() when neither acceptOwnership() nor recoverOwnership() was called.
  modifier onlyOwner() {
    require(
      _activeOwner == msg.sender,
      _pendingOwner == msg.sender ? 'Ownable: caller is not the owner (pending)' : 'Ownable: caller is not the owner'
    );
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() external onlyOwner {
    emit OwnershipTransferred(_activeOwner, address(0));
    _activeOwner = address(0);
    _pendingOwner = address(0);
    _lastOwner = address(0);
  }

  /// @dev Initiates ownership transfer of the contract to a new account `newOwner`.
  /// Can only be called by the current owner. The new owner must call acceptOwnership() to get the ownership.
  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferring(msg.sender, newOwner);
    _pendingOwner = newOwner;
    _lastOwner = _activeOwner;
    _activeOwner = address(0);
  }

  /// @dev Accepts ownership of this contract. Can only be called by the new owner set with transferOwnership().
  function acceptOwnership() external {
    require(_activeOwner == address(0) && _pendingOwner == msg.sender, 'SafeOwnable: caller is not the pending owner');

    emit OwnershipTransferred(_lastOwner, msg.sender);
    _lastOwner = address(0);
    _activeOwner = msg.sender;
  }

  /// @dev Recovers ownership of this contract to the last owner after transferOwnership(),
  /// unless acceptOwnership() was already called by the new owner.
  function recoverOwnership() external {
    require(_activeOwner == address(0) && _lastOwner == msg.sender, 'SafeOwnable: caller can not recover ownership');
    emit OwnershipTransferring(msg.sender, address(0));
    emit OwnershipTransferred(msg.sender, msg.sender);
    _pendingOwner = msg.sender;
    _lastOwner = address(0);
    _activeOwner = msg.sender;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IAddressesProviderRegistry {
  event AddressesProviderPreparing(address indexed newAddress);
  event AddressesProviderRegistered(address indexed newAddress);
  event AddressesProviderUnregistered(address indexed newAddress);

  function getAddressesProvidersList() external view returns (address[] memory);

  function getAddressesProviderIdByAddress(address) external view returns (uint256);

  function prepareAddressesProvider(address provider) external;

  function registerAddressesProvider(address provider, uint256 id) external;

  function unregisterAddressesProvider(address provider) external;

  function setOneTimeRegistrar(address user, uint256 expectedId) external;

  function getOneTimeRegistrar() external view returns (address user, uint256 expectedId);

  function renounceOneTimeRegistrar() external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts
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
  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // Amount must be greater than 0
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // Action requires an active reserve
  string public constant VL_RESERVE_FROZEN = '3'; // Action cannot be performed because the reserve is frozen
  string public constant VL_UNKNOWN_RESERVE = '4'; // Action requires an active reserve
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // User cannot withdraw more than the available balance (above min limit)
  string public constant VL_TRANSFER_NOT_ALLOWED = '6'; // Transfer cannot be allowed.
  string public constant VL_BORROWING_NOT_ENABLED = '7'; // Borrowing is not enabled
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // Invalid interest rate mode selected
  string public constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // The collateral balance is 0
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // Health factor is lesser than the liquidation threshold
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // There is not enough collateral to cover a new borrow
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // The requested amount is exceeds max size of a stable loan
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // to repay a debt, user needs to specify a correct debt type (variable or stable)
  string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // To repay on behalf of an user an explicit amount to repay is needed
  string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // User does not have a stable rate loan in progress on this reserve
  string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // User does not have a variable rate loan in progress on this reserve
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // The collateral balance needs to be greater than 0
  string public constant VL_DEPOSIT_ALREADY_IN_USE = '20'; // User deposit is already being used as collateral
  string public constant VL_RESERVE_MUST_BE_COLLATERAL = '21'; // This reserve must be enabled as collateral
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // Interest rate rebalance conditions were not met
  string public constant AT_OVERDRAFT_DISABLED = '23'; // User doesn't accept allocation of overdraft
  string public constant VL_INVALID_SUB_BALANCE_ARGS = '24';
  string public constant AT_INVALID_SLASH_DESTINATION = '25';

  string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = '27'; // The caller of the function is not the lending pool configurator

  string public constant LENDING_POOL_REQUIRED = '28'; // The caller of this function must be a lending pool
  string public constant CALLER_NOT_LENDING_POOL = '29'; // The caller of this function must be a lending pool
  string public constant AT_SUB_BALANCE_RESTIRCTED_FUNCTION = '30'; // The caller of this function must be a lending pool or a sub-balance operator

  string public constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // Reserve has already been initialized
  string public constant CALLER_NOT_POOL_ADMIN = '33'; // The caller must be the pool admin
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = '34'; // The liquidity of the reserve needs to be 0

  string public constant LPAPR_PROVIDER_NOT_REGISTERED = '41'; // Provider is not registered
  string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // Health factor is not below the threshold
  string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // The collateral chosen cannot be liquidated
  string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // User did not borrow the specified currency
  string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // There isn't enough liquidity available to liquidate

  string public constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string public constant MATH_ADDITION_OVERFLOW = '49';
  string public constant MATH_DIVISION_BY_ZERO = '50';
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = '51'; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = '52'; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = '53'; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = '54'; //  Variable borrow rate overflows uint128
  string public constant RL_STABLE_BORROW_RATE_OVERFLOW = '55'; //  Stable borrow rate overflows uint128
  string public constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string public constant CALLER_NOT_STAKE_ADMIN = '57';
  string public constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small
  string public constant CALLER_NOT_LIQUIDITY_CONTROLLER = '60';
  string public constant CALLER_NOT_REF_ADMIN = '61';
  string public constant VL_INSUFFICIENT_REWARD_AVAILABLE = '62';
  string public constant LP_CALLER_MUST_BE_DEPOSIT_TOKEN = '63';
  string public constant LP_IS_PAUSED = '64'; // Pool is paused
  string public constant LP_NO_MORE_RESERVES_ALLOWED = '65';
  string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = '66';
  string public constant RC_INVALID_LTV = '67';
  string public constant RC_INVALID_LIQ_THRESHOLD = '68';
  string public constant RC_INVALID_LIQ_BONUS = '69';
  string public constant RC_INVALID_DECIMALS = '70';
  string public constant RC_INVALID_RESERVE_FACTOR = '71';
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = '72';
  string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = '73';
  string public constant VL_TREASURY_REQUIRED = '74';
  string public constant LPC_INVALID_CONFIGURATION = '75'; // Invalid risk parameters for the reserve
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '76'; // The caller must be the emergency admin
  string public constant UL_INVALID_INDEX = '77';
  string public constant VL_CONTRACT_REQUIRED = '78';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '79';
  string public constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string public constant CALLER_NOT_REWARD_CONFIG_ADMIN = '81'; // The caller of this function must be a reward admin
  string public constant LP_INVALID_PERCENTAGE = '82'; // Percentage can't be more than 100%
  string public constant LP_IS_NOT_TRUSTED_FLASHLOAN = '83';
  string public constant CALLER_NOT_SWEEP_ADMIN = '84';
  string public constant LP_TOO_MANY_NESTED_CALLS = '85';
  string public constant LP_RESTRICTED_FEATURE = '86';
  string public constant LP_TOO_MANY_FLASHLOAN_CALLS = '87';
  string public constant RW_BASELINE_EXCEEDED = '88';
  string public constant CALLER_NOT_REWARD_RATE_ADMIN = '89';
  string public constant CALLER_NOT_REWARD_CONTROLLER = '90';
  string public constant RW_REWARD_PAUSED = '91';
  string public constant CALLER_NOT_TEAM_MANAGER = '92';
  string public constant STK_REDEEM_PAUSED = '93';
  string public constant STK_INSUFFICIENT_COOLDOWN = '94';
  string public constant STK_UNSTAKE_WINDOW_FINISHED = '95';
  string public constant STK_INVALID_BALANCE_ON_COOLDOWN = '96';
  string public constant STK_EXCESSIVE_SLASH_PCT = '97';
  string public constant STK_WRONG_COOLDOWN_OR_UNSTAKE = '98';
  string public constant STK_PAUSED = '99';

  string public constant TXT_OWNABLE_CALLER_NOT_OWNER = 'Ownable: caller is not the owner';
  string public constant TXT_CALLER_NOT_PROXY_OWNER = 'ProxyOwner: caller is not the owner';
  string public constant TXT_ACCESS_RESTRICTED = 'RESTRICTED';
}