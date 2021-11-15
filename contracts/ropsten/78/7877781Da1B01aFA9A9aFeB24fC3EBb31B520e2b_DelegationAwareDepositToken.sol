// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '../../tools/upgradeability/VersionedInitializable.sol';
import '../../tools/Errors.sol';
import '../../interfaces/IDelegationToken.sol';
import './interfaces/PoolTokenConfig.sol';
import './base/DepositTokenBase.sol';

/// @dev Token able delegate voting power of the underlying asset (COMP delegation interface) to a different address.
contract DelegationAwareDepositToken is DepositTokenBase, VersionedInitializable {
  uint256 private constant TOKEN_REVISION = 0x1;

  function getRevision() internal pure virtual override returns (uint256) {
    return TOKEN_REVISION;
  }

  function initialize(
    PoolTokenConfig calldata config,
    string calldata name,
    string calldata symbol,
    uint8 decimals,
    bytes calldata params
  ) external override initializerRunAlways(TOKEN_REVISION) {
    _initializeERC20(name, symbol, decimals);
    if (!isRevisionInitialized(TOKEN_REVISION)) {
      _initializeDomainSeparator();
    }
    _treasury = config.treasury;
    _initializePoolToken(config, name, symbol, decimals, params);
  }

  modifier onlyPoolAdmin {
    require(_pool.getAccessController().isPoolAdmin(msg.sender), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  /// @dev Delegates voting power of the underlying asset to a `delegatee` address
  function delegateUnderlyingTo(address delegatee) external onlyPoolAdmin {
    IDelegationToken(_underlyingAsset).delegate(delegatee);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement versioned initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` or `initializerRunAlways` modifier.
 * The revision number should be defined as a private constant, returned by getRevision() and used by initializer() modifier.
 *
 * ATTN: There is a built-in protection from implementation self-destruct exploits. This protection
 * prevents initializers from being called on an implementation inself, but only on proxied contracts.
 * To override this protection, call _unsafeResetVersionedInitializers() from a constructor.
 *
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an initializable contract, as well
 * as extending an initializable contract via inheritance.
 *
 * ATTN: When used with inheritance, parent initializers with `initializer` modifier are prevented by calling twice,
 * but can only be called in child-to-parent sequence.
 *
 * WARNING: When used with inheritance, parent initializers with `initializerRunAlways` modifier
 * are NOT protected from multiple calls by another initializer.
 */
abstract contract VersionedInitializable {
  uint256 private constant BLOCK_REVISION = type(uint256).max;
  // This revision number is applied to implementations
  uint256 private constant IMPL_REVISION = BLOCK_REVISION - 1;

  /// @dev Indicates that the contract has been initialized. The default value blocks initializers from being called on an implementation.
  uint256 private lastInitializedRevision = IMPL_REVISION;

  /// @dev Indicates that the contract is in the process of being initialized.
  uint256 private lastInitializingRevision = 0;

  /**
   * @dev There is a built-in protection from self-destruct of implementation exploits. This protection
   * prevents initializers from being called on an implementation inself, but only on proxied contracts.
   * Function _unsafeResetVersionedInitializers() can be called from a constructor to disable this protection.
   * It must be called before any initializers, otherwise it will fail.
   */
  function _unsafeResetVersionedInitializers() internal {
    require(isConstructor(), 'only for constructor');

    if (lastInitializedRevision == IMPL_REVISION) {
      lastInitializedRevision = 0;
    } else {
      require(lastInitializedRevision == 0, 'can only be called before initializer(s)');
    }
  }

  /// @dev Modifier to use in the initializer function of a contract.
  modifier initializer(uint256 localRevision) {
    (uint256 topRevision, bool initializing, bool skip) = _preInitializer(localRevision);

    if (!skip) {
      lastInitializingRevision = localRevision;
      _;
      lastInitializedRevision = localRevision;
    }

    if (!initializing) {
      lastInitializedRevision = topRevision;
      lastInitializingRevision = 0;
    }
  }

  modifier initializerRunAlways(uint256 localRevision) {
    (uint256 topRevision, bool initializing, bool skip) = _preInitializer(localRevision);

    if (!skip) {
      lastInitializingRevision = localRevision;
    }
    _;
    if (!skip) {
      lastInitializedRevision = localRevision;
    }

    if (!initializing) {
      lastInitializedRevision = topRevision;
      lastInitializingRevision = 0;
    }
  }

  function _preInitializer(uint256 localRevision)
    private
    returns (
      uint256 topRevision,
      bool initializing,
      bool skip
    )
  {
    topRevision = getRevision();
    require(topRevision < IMPL_REVISION, 'invalid contract revision');

    require(localRevision > 0, 'incorrect initializer revision');
    require(localRevision <= topRevision, 'inconsistent contract revision');

    if (lastInitializedRevision < IMPL_REVISION) {
      // normal initialization
      initializing = lastInitializingRevision > 0 && lastInitializedRevision < topRevision;
      require(
        initializing || isConstructor() || topRevision > lastInitializedRevision,
        'already initialized'
      );
    } else {
      // by default, initialization of implementation is only allowed inside a constructor
      require(lastInitializedRevision == IMPL_REVISION && isConstructor(), 'initializer blocked');

      // enable normal use of initializers inside a constructor
      lastInitializedRevision = 0;
      // but make sure to block initializers afterwards
      topRevision = BLOCK_REVISION;

      initializing = lastInitializingRevision > 0;
    }

    if (initializing) {
      require(lastInitializingRevision > localRevision, 'incorrect order of initializers');
    }

    if (localRevision <= lastInitializedRevision) {
      // prevent calling of parent's initializer when it was called before
      if (initializing) {
        // Can't set zero yet, as it is not a top-level call, otherwise `initializing` will become false.
        // Further calls will fail with the `incorrect order` assertion above.
        lastInitializingRevision = 1;
      }
      return (topRevision, initializing, true);
    }
    return (topRevision, initializing, false);
  }

  function isRevisionInitialized(uint256 localRevision) internal view returns (bool) {
    return lastInitializedRevision >= localRevision;
  }

  function REVISION() public pure returns (uint256) {
    return getRevision();
  }

  /**
   * @dev returns the revision number (< type(uint256).max - 1) of the contract.
   * The number should be defined as a private constant.
   **/
  function getRevision() internal pure virtual returns (uint256);

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[4] private ______gap;
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
  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // Amount must be greater than 0
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // Action requires an active reserve
  string public constant VL_RESERVE_FROZEN = '3'; // Action cannot be performed because the reserve is frozen
  string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = '4'; // The current liquidity is not enough
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // User cannot withdraw more than the available balance
  string public constant VL_TRANSFER_NOT_ALLOWED = '6'; // Transfer cannot be allowed.
  string public constant VL_BORROWING_NOT_ENABLED = '7'; // Borrowing is not enabled
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // Invalid interest rate mode selected
  string public constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // The collateral balance is 0
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // Health factor is lesser than the liquidation threshold
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // There is not enough collateral to cover a new borrow
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // The requested amount is greater than the max loan size in stable rate mode
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt
  string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // To repay on behalf of an user an explicit amount to repay is needed
  string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // User does not have a stable rate loan in progress on this reserve
  string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // User does not have a variable rate loan in progress on this reserve
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // The underlying balance needs to be greater than 0
  string public constant VL_DEPOSIT_ALREADY_IN_USE = '20'; // User deposit is already being used as collateral
  string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = '21'; // User does not have any stable rate loan for this reserve
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // Interest rate rebalance conditions were not met
  //  string public constant LP_LIQUIDATION_CALL_FAILED = '23'; // Liquidation call failed
  string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = '24'; // There is not enough liquidity available to borrow
  string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = '25'; // The requested amount is too small for a FlashLoan.
  string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = '26'; // The actual balance of the protocol is inconsistent
  string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = '27'; // The caller of the function is not the lending pool configurator
  string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = '28';
  string public constant CT_CALLER_MUST_BE_LENDING_POOL = '29'; // The caller of this function must be a lending pool
  string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = '30'; // User cannot give allowance to himself
  string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = '31'; // Transferred amount needs to be greater than zero
  string public constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // Reserve has already been initialized
  string public constant CALLER_NOT_POOL_ADMIN = '33'; // The caller must be the pool admin
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = '34'; // The liquidity of the reserve needs to be 0
  string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = '35'; // The liquidity of the reserve needs to be 0
  string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = '36'; // The liquidity of the reserve needs to be 0
  string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = '37'; // The liquidity of the reserve needs to be 0
  string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '38'; // The liquidity of the reserve needs to be 0
  string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '39'; // The liquidity of the reserve needs to be 0
  string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = '40'; // The liquidity of the reserve needs to be 0
  string public constant LPAPR_PROVIDER_NOT_REGISTERED = '41'; // Provider is not registered
  string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // Health factor is not below the threshold
  string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // The collateral chosen cannot be liquidated
  string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // User did not borrow the specified currency
  string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // There isn't enough liquidity available to liquidate
  //  string public constant LPCM_NO_ERRORS = '46'; // No errors
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
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small
  string public constant LP_FAILED_COLLATERAL_SWAP = '60';
  string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = '61';
  string public constant LP_REENTRANCY_NOT_ALLOWED = '62';
  string public constant LP_CALLER_MUST_BE_AN_ATOKEN = '63';
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
  string public constant LP_INCONSISTENT_PARAMS_LENGTH = '74';
  string public constant LPC_INVALID_CONFIGURATION = '75'; // Invalid risk parameters for the reserve
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '76'; // The caller must be the emergency admin
  string public constant UL_INVALID_INDEX = '77';
  string public constant VL_CONTRACT_REQUIRED = '78';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '79';
  string public constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string public constant CT_CALLER_MUST_BE_REWARD_ADMIN = '81'; // The caller of this function must be a reward admin
  string public constant LP_INVALID_PERCENTAGE = '82'; // Percentage can't be more than 100%
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

  string public constant TXT_OWNABLE_CALLER_NOT_OWNER = 'Ownable: caller is not the owner';
  string public constant TXT_CALLER_NOT_PROXY_OWNER = 'ProxyOwner: caller is not the owner';
  string public constant TXT_ACCESS_RESTRICTED = 'RESTRICTED';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/// @dev Implements an interface for tokens with delegation COMP/UNI compatible
interface IDelegationToken {
  function delegate(address delegatee) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

struct PoolTokenConfig {
  // The address of the associated lending pool
  address pool;
  // The address of the treasury
  address treasury;
  // The address of the underlying asset
  address underlyingAsset;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import '../../../dependencies/openzeppelin/contracts/ERC20Events.sol';
import '../../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import '../../../interfaces/IDepositToken.sol';
import '../../../tools/math/WadRayMath.sol';
import '../../../misc/PermitForERC20.sol';
import './PoolTokenBase.sol';

/// @dev Implementation of the interest bearing token for the Augmented Finance protocol
abstract contract DepositTokenBase is
  PoolTokenBase('', '', 0),
  PermitForERC20,
  ERC20Events,
  IDepositToken
{
  using WadRayMath for uint256;
  using SafeERC20 for IERC20;

  mapping(address => mapping(address => uint256)) private _allowances;
  address internal _treasury;

  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external override onlyLendingPool {
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
    _burnBalance(user, amountScaled, index);

    IERC20(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);

    emit Transfer(user, address(0), amount);
    emit Burn(user, receiverOfUnderlying, amount, index);
  }

  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external override onlyLendingPool returns (bool) {
    bool firstBalance = super.balanceOf(user) == 0;

    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);
    _mintBalance(user, amountScaled, index);

    emit Transfer(address(0), user, amount);
    emit Mint(user, amount, index);

    return firstBalance;
  }

  function mintToTreasury(uint256 amount, uint256 index) external override onlyLendingPool {
    if (amount == 0) {
      return;
    }

    address treasury = _treasury;

    // Compared to the normal mint, we don't check for rounding errors.
    // The treasury may experience a very small loss, but it wont revert a valid transactions.
    _mintBalance(treasury, amount.rayDiv(index), index);

    emit Transfer(address(0), treasury, amount);
    emit Mint(treasury, amount, index);
  }

  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external override onlyLendingPool {
    // Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
    // so no need to emit a specific event here
    _transfer(from, to, value, false);

    emit Transfer(from, to, value);
  }

  /// @dev Calculates the balance of the user: principal balance + interest generated by the principal
  function balanceOf(address user) public view override(IERC20, PoolTokenBase) returns (uint256) {
    return super.balanceOf(user).rayMul(_pool.getReserveNormalizedIncome(_underlyingAsset));
  }

  function scaledBalanceOf(address user) external view override returns (uint256) {
    return super.balanceOf(user);
  }

  function getScaledUserBalanceAndSupply(address user)
    external
    view
    override
    returns (uint256, uint256)
  {
    return (super.balanceOf(user), super.totalSupply());
  }

  function totalSupply() public view override(IERC20, PoolTokenBase) returns (uint256) {
    uint256 currentSupplyScaled = super.totalSupply();
    if (currentSupplyScaled == 0) {
      return 0;
    }

    return currentSupplyScaled.rayMul(_pool.getReserveNormalizedIncome(_underlyingAsset));
  }

  function scaledTotalSupply() public view virtual override returns (uint256) {
    return super.totalSupply();
  }

  /// @dev Returns the address of the treasury, receiving the fees on this depositToken
  function RESERVE_TREASURY_ADDRESS() public view returns (address) {
    return _treasury;
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount, true);
    emit Transfer(msg.sender, recipient, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount, true);
    _approve(
      sender,
      msg.sender,
      _allowances[sender][msg.sender].sub(amount, 'ERC20: transfer amount exceeds allowance')
    );
    emit Transfer(sender, recipient, amount);
    return true;
  }

  function transferUnderlyingTo(address target, uint256 amount)
    external
    override
    onlyLendingPool
    returns (uint256)
  {
    IERC20(_underlyingAsset).safeTransfer(target, amount);
    return amount;
  }

  function handleRepayment(address user, uint256 amount) external override onlyLendingPool {}

  /**
   * @dev Validates and executes a transfer.
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   * @param validate `true` if the transfer needs to be validated
   **/
  function _transfer(
    address from,
    address to,
    uint256 amount,
    bool validate
  ) internal {
    address underlyingAsset = _underlyingAsset;

    uint256 index = _pool.getReserveNormalizedIncome(underlyingAsset);

    uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
    uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

    super._transferBalance(from, to, amount.rayDiv(index), index);

    if (validate) {
      _pool.finalizeTransfer(underlyingAsset, from, to, amount, fromBalanceBefore, toBalanceBefore);
    }

    emit BalanceTransfer(from, to, amount, index);
  }

  function _approveByPermit(
    address owner,
    address spender,
    uint256 amount
  ) internal override {
    _approve(owner, spender, amount);
  }

  function _getPermitDomainName() internal view override returns (bytes memory) {
    return bytes(super.name());
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/// @dev Interface of the ERC20 standard as defined in the EIP excluding events to avoid linearization issues.
interface IERC20 {
  /// @dev Returns the amount of tokens in existence.
  function totalSupply() external view returns (uint256);

  /// @dev Returns the amount of tokens owned by `account`.
  function balanceOf(address account) external view returns (uint256);

  /// @dev Moves `amount` tokens from the caller's account to `recipient`.
  function transfer(address recipient, uint256 amount) external returns (bool);

  /// @dev Returns the remaining number of tokens that `spender` will be allowed to spend.
  function allowance(address owner, address spender) external view returns (uint256);

  /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
  function approve(address spender, uint256 amount) external returns (bool);

  /// @dev Moves `amount` tokens from `sender` to `recipient`
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/// @dev Interface of the ERC20 standard as defined in the EIP.
interface ERC20Events {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './IERC20.sol';
import './SafeMath.sol';
import './Addr.sol';

/// @dev Wrappers around ERC20 operations that throw on failure (when the token contract returns false).
library SafeERC20 {
  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(Addr.isContract(address(token)), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import '../dependencies/openzeppelin/contracts/IERC20.sol';
import './IScaledBalanceToken.sol';
import './IPoolToken.sol';

interface IDepositToken is IERC20, IScaledBalanceToken, IPoolToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` depositTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted after depositTokens are burned
   * @param from The owner of the depositTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param value The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred
   * @param index The new liquidity index of the reserve
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @dev Burns depositTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the depositTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @dev Mints depositTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Transfers depositTokens in the event of a borrow being liquidated, in case the liquidators reclaims the depositToken
   * @param from The address getting liquidated, current owner of the depositTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external;

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

  /**
   * @dev Invoked to execute actions on the depositToken side after a repayment.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   **/
  function handleRepayment(address user, uint256 amount) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import '../Errors.sol';

/// @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /// @return One ray, 1e27
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /// @return One wad, 1e18
  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /// @return Half ray, 1e27/2
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /// @return Half ray, 1e18/2
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /// @dev Multiplies two wad, rounding half up to the nearest wad
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfWAD) / WAD;
  }

  /// @dev Divides two wad, rounding half up to the nearest wad
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * WAD + halfB) / b;
  }

  /// @dev Multiplies two ray, rounding half up to the nearest ray
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfRAY) / RAY;
  }

  /// @dev Divides two ray, rounding half up to the nearest ray
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * RAY + halfB) / b;
  }

  /// @dev Casts ray down to wad
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

    return result / WAD_RAY_RATIO;
  }

  /// @dev Converts wad up to ray
  function wadToRay(uint256 a) internal pure returns (uint256 result) {
    result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

abstract contract PermitForERC20 {
  bytes32 public DOMAIN_SEPARATOR;
  bytes public constant EIP712_REVISION = bytes('1');
  bytes32 internal constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  /// @dev owner => next valid nonce to submit with permit()
  mapping(address => uint256) public _nonces;

  constructor() public {
    _initializeDomainSeparator();
  }

  function _initializeDomainSeparator() internal {
    uint256 chainId;

    //solium-disable-next-line
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        EIP712_DOMAIN,
        keccak256(_getPermitDomainName()),
        keccak256(EIP712_REVISION),
        chainId,
        address(this)
      )
    );
  }

  /**
   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner the owner of the funds
   * @param spender the spender
   * @param value the amount
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(owner != address(0), 'INVALID_OWNER');
    //solium-disable-next-line
    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest =
      keccak256(
        abi.encodePacked(
          '\x19\x01',
          DOMAIN_SEPARATOR,
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
        )
      );

    require(owner == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');
    _nonces[owner] = currentValidNonce + 1;
    _approveByPermit(owner, spender, value);
  }

  function _approveByPermit(
    address owner,
    address spender,
    uint256 value
  ) internal virtual;

  function _getPermitDomainName() internal view virtual returns (bytes memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '../../../tools/Errors.sol';
import '../../../dependencies/openzeppelin/contracts/IERC20Details.sol';
import '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import '../../../dependencies/openzeppelin/contracts/SafeMath.sol';
import '../../../interfaces/IPoolToken.sol';
import '../../../interfaces/IBalanceHook.sol';
import '../../../interfaces/ILendingPoolForTokens.sol';
import '../../../access/AccessHelper.sol';
import '../../../access/AccessFlags.sol';
import '../interfaces/IInitializablePoolToken.sol';
import '../interfaces/PoolTokenConfig.sol';

abstract contract PoolTokenBase is IERC20, IInitializablePoolToken, IPoolToken, IERC20Details {
  using SafeMath for uint256;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  mapping(address => uint256) internal _balances;
  uint256 internal _totalSupply;

  ILendingPoolForTokens internal _pool;
  address internal _underlyingAsset;
  IBalanceHook private _incentivesController;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function _initializeERC20(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) internal {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function _onlyLendingPool() private view {
    require(msg.sender == address(_pool), Errors.CT_CALLER_MUST_BE_LENDING_POOL);
  }

  modifier onlyLendingPool {
    _onlyLendingPool();
    _;
  }

  function _onlyRewardConfiguratorOrAdmin() private view {
    require(
      AccessHelper.hasAnyOf(
        _pool.getAccessController(),
        msg.sender,
        AccessFlags.REWARD_CONFIG_ADMIN | AccessFlags.REWARD_CONFIGURATOR
      ),
      Errors.CT_CALLER_MUST_BE_REWARD_ADMIN
    );
  }

  modifier onlyRewardConfiguratorOrAdmin {
    _onlyRewardConfiguratorOrAdmin();
    _;
  }

  function _initializePoolToken(
    PoolTokenConfig memory config,
    string memory debtTokenName,
    string memory debtTokenSymbol,
    uint8 debtTokenDecimals,
    bytes calldata params
  ) internal {
    _pool = ILendingPoolForTokens(config.pool);
    _underlyingAsset = config.underlyingAsset;

    emit Initialized(
      config.underlyingAsset,
      address(config.pool),
      address(config.treasury),
      debtTokenName,
      debtTokenSymbol,
      debtTokenDecimals,
      params
    );
  }

  function UNDERLYING_ASSET_ADDRESS() public view override returns (address) {
    return _underlyingAsset;
  }

  function POOL() public view override returns (address) {
    return address(_pool);
  }

  function handleBalanceUpdate(
    address holder,
    uint256 oldBalance,
    uint256 newBalance,
    uint256 providerSupply
  ) internal virtual {
    IBalanceHook hook = _incentivesController;
    if (hook == IBalanceHook(0)) {
      return;
    }
    hook.handleBalanceUpdate(getIncentivesToken(), holder, oldBalance, newBalance, providerSupply);
  }

  function handleScaledBalanceUpdate(
    address holder,
    uint256 oldBalance,
    uint256 newBalance,
    uint256 providerSupply,
    uint256 scale
  ) internal {
    IBalanceHook hook = _incentivesController;
    if (hook == IBalanceHook(0)) {
      return;
    }
    hook.handleScaledBalanceUpdate(
      getIncentivesToken(),
      holder,
      oldBalance,
      newBalance,
      providerSupply,
      scale
    );
  }

  function getIncentivesToken() internal view virtual returns (address) {
    return address(this);
  }

  function _setIncentivesController(address hook) internal virtual {
    _incentivesController = IBalanceHook(hook);
  }

  function setIncentivesController(address hook) external override onlyRewardConfiguratorOrAdmin {
    _setIncentivesController(hook);
  }

  function getIncentivesController() public view override returns (address) {
    return address(_incentivesController);
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function _mintBalance(
    address account,
    uint256 amount,
    uint256 scale
  ) internal {
    require(account != address(0), 'ERC20: mint to the zero address');
    _beforeTokenTransfer(address(0), account, amount);

    uint256 total = _totalSupply;
    total = total.add(amount);
    _totalSupply = total;

    uint256 oldAccountBalance = _balances[account];
    uint256 newAccountBalance = oldAccountBalance.add(amount);
    _balances[account] = newAccountBalance;

    handleScaledBalanceUpdate(account, oldAccountBalance, newAccountBalance, total, scale);
  }

  function _burnBalance(
    address account,
    uint256 amount,
    uint256 scale
  ) internal {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    uint256 total = _totalSupply;
    total = total.sub(amount);
    _totalSupply = total;

    uint256 oldAccountBalance = _balances[account];
    uint256 newAccountBalance = oldAccountBalance.sub(amount, 'ERC20: burn amount exceeds balance');
    _balances[account] = newAccountBalance;

    handleScaledBalanceUpdate(account, oldAccountBalance, newAccountBalance, total, scale);
  }

  function _transferBalance(
    address sender,
    address recipient,
    uint256 amount,
    uint256 scale
  ) internal {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 oldSenderBalance = _balances[sender];
    uint256 newSenderBalance =
      oldSenderBalance.sub(amount, 'ERC20: transfer amount exceeds balance');
    _balances[sender] = newSenderBalance;

    uint256 oldRecipientBalance = _balances[recipient];
    uint256 newRecipientBalance = oldRecipientBalance.add(amount);
    _balances[recipient] = newRecipientBalance;

    IBalanceHook hook = _incentivesController;
    if (address(hook) != address(0)) {
      address token = getIncentivesToken();
      uint256 currentTotalSupply = _totalSupply;

      hook.handleScaledBalanceUpdate(
        token,
        sender,
        oldSenderBalance,
        newSenderBalance,
        currentTotalSupply,
        scale
      );

      if (sender != recipient) {
        hook.handleScaledBalanceUpdate(
          token,
          recipient,
          oldRecipientBalance,
          newRecipientBalance,
          currentTotalSupply,
          scale
        );
      }
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/// @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
library SafeMath {
  /// @dev Returns the addition of two unsigned integers, reverting on overflow.
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, 'SafeMath: addition overflow');
  }

  /// @dev Returns the subtraction of two unsigned integers, reverting on overflow (when the result is negative).
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /// @dev Returns the subtraction of two unsigned integers, reverting with custom message on overflow (when the result is negative).
  function sub(
    uint256 a,
    uint256 b,
    string memory errMsg
  ) internal pure returns (uint256) {
    require(b <= a, errMsg);
    return a - b;
  }

  /// @dev Returns the multiplication of two unsigned integers, reverting on overflow.
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');
  }

  /// @dev Returns the integer division of two unsigned integers. Reverts on division by zero. The result is rounded towards zero.
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /// @dev Returns the integer division of two unsigned integers. Reverts with custom message on division by zero. The result is rounded towards zero.
  function div(
    uint256 a,
    uint256 b,
    string memory errMsg
  ) internal pure returns (uint256 c) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errMsg);
    c = a / b;
  }

  /// @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo), Reverts when dividing by zero.
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /// @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo), Reverts with custom message when dividing by zero.
  function mod(
    uint256 a,
    uint256 b,
    string memory errMsg
  ) internal pure returns (uint256) {
    require(b != 0, errMsg);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @dev Extracted from Address.sol to fit into the verification limit
library Addr {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import './IDerivedToken.sol';
import './IRewardedToken.sol';

interface IPoolToken is IDerivedToken, IRewardedToken {
  function POOL() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.12;

interface IDerivedToken {
  /**
   * @dev Returns the address of the underlying asset of this token (E.g. WETH for agWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IRewardedToken {
  function setIncentivesController(address) external;

  function getIncentivesController() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IERC20Details {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IBalanceHook {
  function handleBalanceUpdate(
    address token,
    address holder,
    uint256 oldBalance,
    uint256 newBalance,
    uint256 providerSupply
  ) external;

  function handleScaledBalanceUpdate(
    address token,
    address holder,
    uint256 oldBalance,
    uint256 newBalance,
    uint256 providerSupply,
    uint256 scaleRay
  ) external;

  function isScaledBalanceUpdateNeeded() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '../access/interfaces/IMarketAccessController.sol';
import '../protocol/libraries/types/DataTypes.sol';

interface ILendingPoolForTokens {
  /**
   * @dev Validates and finalizes an depositToken transfer
   * - Only callable by the overlying depositToken of the `asset`
   * @param asset The address of the underlying asset of the depositToken
   * @param from The user from which the depositToken are transferred
   * @param to The user receiving the depositToken
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The depositToken balance of the `from` user before the transfer
   * @param balanceToBefore The depositToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external;

  function getAccessController() external view returns (IMarketAccessController);

  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import './interfaces/IRemoteAccessBitmask.sol';

/// @dev Helper/wrapper around IRemoteAccessBitmask
library AccessHelper {

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
    uint256 found = queryAcl(remote, subject, flags);
    return found & flags != 0;
  }

  function hasAny(IRemoteAccessBitmask remote, address subject) internal view returns (bool) {
    return remote.queryAccessControlMask(subject, 0) != 0;
  }

  function hasNone(IRemoteAccessBitmask remote, address subject) internal view returns (bool) {
    return remote.queryAccessControlMask(subject, 0) == 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.12;

library AccessFlags {
  // roles that can be assigned to multiple addresses - use range [0..15]
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

  uint256 public constant ROLES = (uint256(1) << 16) - 1;

  // singletons - use range [16..64] - can ONLY be assigned to a single address
  uint256 public constant SINGLETONS = ((uint256(1) << 64) - 1) & ~ROLES;

  // proxied singletons
  uint256 public constant LENDING_POOL = 1 << 16;
  uint256 public constant LENDING_POOL_CONFIGURATOR = 1 << 17;
  uint256 public constant LIQUIDITY_CONTROLLER = 1 << 18;

  uint256 public constant TREASURY = 1 << 21;
  uint256 public constant REWARD_TOKEN = 1 << 22;
  uint256 public constant REWARD_STAKE_TOKEN = 1 << 23;
  uint256 public constant REWARD_CONTROLLER = 1 << 24;
  uint256 public constant REWARD_CONFIGURATOR = 1 << 25;
  uint256 public constant STAKE_CONFIGURATOR = 1 << 26; 
  uint256 public constant REFERRAL_REGISTRY = 1 << 27; 

  uint256 public constant PROXIES = ((uint256(1) << 28) - 1) & ~ROLES;

  // non-proxied singletons, numbered down from 62 
  uint256 public constant WETH_GATEWAY = 1 << 59;
  uint256 public constant DATA_HELPER = 1 << 60;
  uint256 public constant PRICE_ORACLE = 1 << 61;
  uint256 public constant LENDING_RATE_ORACLE = 1 << 62;

  // any other roles - use range [64..]
  // these roles can be assigned to multiple addresses

  uint256 public constant REWARD_MINT = 1 << 64;
  uint256 public constant REWARD_BURN = 1 << 65;

  uint256 public constant POOL_SPONSORED_LOAN_USER = 1 << 66;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import './PoolTokenConfig.sol';

/// @dev Interface for the initialize function on PoolToken or DebtToken
interface IInitializablePoolToken {
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    string tokenName,
    string tokenSymbol,
    uint8 tokenDecimals,
    bytes params
  );

  /// @dev Initializes the depositToken
  function initialize(
    PoolTokenConfig calldata config,
    string calldata tokenName,
    string calldata tokenSymbol,
    uint8 tokenDecimals,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import './IAccessController.sol';

/// @dev Main registry of addresses part of or connected to the protocol, including permissioned roles. Also acts a proxy factory.
interface IMarketAccessController is IAccessController {
  function getMarketId() external view returns (string memory);

  function getLendingPool() external view returns (address);

  function isPoolAdmin(address) external view returns (bool);

  function getPriceOracle() external view returns (address);

  function getLendingRateOracle() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

library DataTypes {
  uint64 public constant MASK_ASSET_TYPE = 0x0F;
  uint64 public constant ASSET_TYPE_INTERNAL = 0;
  uint64 public constant ASSET_TYPE_AAVE = 0x01;
  uint64 public constant ASSET_TYPE_DELEGATED = 0x0F;

  // refer to the AAVE whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint64 reserveFlags;
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
    //tokens addresses
    address depositTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address strategy;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}

  struct InitReserveData {
    address asset;
    address depositTokenAddress;
    address stableDebtAddress;
    address variableDebtAddress;
    address strategy;
    uint64 reserveFlags;
  }
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
  /**
   * @dev Returns access flags granted to the given address and limited by the filterMask. filterMask == 0 has a special meaning.
   * @param addr an to get access perfmissions for
   * @param filterMask limits a subset of flags to be checked. NB! When filterMask == 0 then zero is returned no flags granted, or an unspecified non-zero value otherwise.
   * @return Access flags currently granted
   */
  function queryAccessControlMask(address addr, uint256 filterMask) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IProxy {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

