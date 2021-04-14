/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard is Initializable {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    function initialize() public initializer {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/Controller.sol

pragma solidity 0.5.17;



/**
 * @title Controller component
 * @dev For easy access to any core components
 */
contract Controller is Initializable {
    using Roles for Roles.Role;

    Roles.Role private _admins;
    bool private _paused;
    address public pauseGuardian;

    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    modifier onlyAdmin() {
        require(
            _admins.has(msg.sender),
            "Controller: caller does not have the admin role"
        );
        _;
    }

    modifier onlyGuardian() {
        require(
            pauseGuardian == msg.sender,
            "Controller: caller does not have the guardian role"
        );
        _;
    }

    //When using minimal deploy, do not call initialize directly during deploy, because msg.sender is the proxyFactory address, and you need to call it manually
    function initialize(address admin_) public initializer {
        _paused = false;
        _admins.add(admin_);
        pauseGuardian = admin_;
    }

    /**
     * @dev Check if the address provided is the admin
     * @param account Account address
     */
    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    /**
     * @dev Add a new admin account
     * @param account Account address
     */
    function addAdmin(address account) public onlyAdmin {
        _admins.add(account);
    }

    /**
     * @dev Set pauseGuardian account
     * @param account Account address
     */
    function setGuardian(address account) public onlyAdmin {
        pauseGuardian = account;
    }

    /**
     * @dev Renouce the admin from the sender's address
     */
    function renounceAdmin() public {
        _admins.remove(msg.sender);
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyGuardian whenNotPaused() {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyGuardian whenPaused() {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    uint256[50] private ______gap;
}

// File: contracts/interfaces/IMarketRegistry.sol

pragma solidity 0.5.17;

/**
 * @title MarketRegistry Interface
 * @dev Registering and managing all the lending markets.
 */
interface IMarketRegistry {
    function getUTokens() external view returns (address[] memory);

    function getUserManagers() external view returns (address[] memory);

    /**
     *  @dev Returns the market address of the token
     *  @return The market address
     */
    function tokens(address token) external view returns (address, address);

    function createUToken(
        address token,
        address assetManager,
        uint256 originationFee,
        uint256 globalMaxLoan,
        uint256 maxBorrow,
        uint256 minLoan,
        uint256 maxLateBlock,
        address interestRateModel
    ) external returns (address);

    function createUserManager(
        address assetManager,
        address unionToken,
        address stakingToken,
        address creditLimitModel,
        address inflationIndexModel,
        address comptroller
    ) external returns (address);
}

// File: contracts/interfaces/IMoneyMarketAdapter.sol

pragma solidity 0.5.17;

/**
 * @title MoneyMarketAdapter Interface
 *  @dev Working with AssetManager to support external money markets, like Compound etc.
 */
interface IMoneyMarketAdapter {
    /**
     * @dev Returns the interest rate per block for the given token.
     */
    function getRate(address tokenAddress) external view returns (uint256);

    /**
     * @dev Deposits the given amount of tokens in the underlying money market.
     */
    function deposit(address tokenAddress) external;

    /**
     * @dev Withdraws the given amount of tokens from the underlying money market and transfers them to `recipient`.
     */
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @dev Withdraws all the tokens from the underlying money market and transfers them to `recipient`.
     */
    function withdrawAll(address tokenAddress, address recipient) external;

    function claimTokens(address tokenAddress, address recipient) external;

    /**
     * @dev Returns the supply for the given token, including accrued interest. This function can have side effects.
     */
    function getSupply(address tokenAddress) external returns (uint256);

    /**
     * @dev Returns the supply for the given token; it might not include accrued interest. This function *cannot* have side effects.
     */
    function getSupplyView(address tokenAddress) external view returns (uint256);

    /**
     * @dev Indicates if the adapter supports the token with the given address.
     */
    function supportsToken(address tokenAddress) external view returns (bool);

    /**
     * @dev The minimum amount that should be deposited in money market before moving to next priority market
     * @param tokenAddress The address of token whose floor is being fetched
     */
    function floorMap(address tokenAddress) external view returns (uint256);

    /**
     * @dev The maximum amount that should be deposited in money market
     * @param tokenAddress The address of token whose ceiling is being fetched
     */
    function ceilingMap(address tokenAddress) external view returns (uint256);
}

// File: contracts/interfaces/IAssetManager.sol

pragma solidity 0.5.17;

/**
 *  @title AssetManager Interface
 *  @dev Manage the token balances staked by the users and deposited by admins, and invest tokens to the integrated underlying lending protocols.
 */
interface IAssetManager {
    /**
     *  @dev Emit when making a deposit
     *  @param token Depositing token address
     *  @param account Account address
     *  @param amount Deposit amount, in wei
     */
    event LogDeposit(address indexed token, address indexed account, uint256 amount);
    /**
     *  @dev Emit when withdrawing from AssetManager
     *  @param token Depositing token address
     *  @param account Account address
     *  @param amount Withdraw amount, in wei
     *  @param remaining The amount cannot be withdrawn
     */
    event LogWithdraw(address indexed token, address indexed account, uint256 amount, uint256 remaining);
    /**
     *  @dev Emit when rebalancing among the integrated money markets
     *  @param tokenAddress The address of the token to be rebalanced
     *  @param percentages Array of the percentages of the tokens to deposit to the money markets
     */
    event LogRebalance(address tokenAddress, uint256[] percentages);

    /**
     *  @dev Returns the balance of asset manager, plus the total amount of tokens deposited to all the underlying lending protocols.
     *  @param tokenAddress ERC20 token address
     *  @return Lending pool balance
     */
    function getPoolBalance(address tokenAddress) external view returns (uint256);

    /**
     *  @dev Returns the amount of the lending pool balance minus the amount of total staked.
     *  @param tokenAddress ERC20 token address
     *  @return Amount can be borrowed
     */
    function getLoanableAmount(address tokenAddress) external view returns (uint256);

    /**
     *  @dev Get the total amount of tokens deposited to all the integrated underlying protocols without side effects.
     *  @param tokenAddress ERC20 token address
     *  @return Total market balance
     */
    function totalSupply(address tokenAddress) external returns (uint256);

    /**
     *  @dev Get the total amount of tokens deposited to all the integrated underlying protocols, but without side effects. Safe to call anytime, but may not get the most updated number for the current block. Call totalSupply() for that purpose.
     *  @param tokenAddress ERC20 token address
     *  @return Total market balance
     */
    function totalSupplyView(address tokenAddress) external view returns (uint256);

    /**
     *  @dev Check if there is an underlying protocol available for the given ERC20 token.
     *  @param tokenAddress ERC20 token address
     *  @return Whether is supported
     */
    function isMarketSupported(address tokenAddress) external view returns (bool);

    /**
     *  @dev Deposit tokens to AssetManager, and those tokens will be passed along to adapters to deposit to integrated asset protocols if any is available.
     *  @param token ERC20 token address
     *  @param amount Deposit amount, in wei
     *  @return Deposited amount
     */
    function deposit(address token, uint256 amount) external returns (bool);

    /**
     *  @dev Withdraw from AssetManager
     *  @param token ERC20 token address
     *  @param account User address
     *  @param amount Withdraw amount, in wei
     *  @return Withdraw amount
     */
    function withdraw(
        address token,
        address account,
        uint256 amount
    ) external returns (bool);

    /**
     *  @dev Add a new ERC20 token to support in AssetManager
     *  @param tokenAddress ERC20 token address
     */
    function addToken(address tokenAddress) external;

    /**
     *  @dev Add a new adapter for the underlying lending protocol
     *  @param adapterAddress adapter address
     */
    function addAdapter(address adapterAddress) external;

    /**
     *  @dev For a give token set allowance for all integrated money markets
     *  @param tokenAddress ERC20 token address
     */
    function approveAllMarketsMax(address tokenAddress) external;

    /**
     *  @dev For a give moeny market set allowance for all underlying tokens
     *  @param adapterAddress Address of adaptor for money market
     */
    function approveAllTokensMax(address adapterAddress) external;

    /**
     *  @dev Set withdraw sequence
     *  @param newSeq priority sequence of money market indices to be used while withdrawing
     */
    function changeWithdrawSequence(uint256[] calldata newSeq) external;

    /**
     *  @dev Rebalance the tokens between integrated lending protocols
     *  @param tokenAddress ERC20 token address
     *  @param percentages Proportion
     */
    function rebalance(address tokenAddress, uint256[] calldata percentages) external;

    /**
     *  @dev Claim the tokens left on AssetManager balance, in case there are tokens get stuck here.
     *  @param tokenAddress ERC20 token address
     *  @param recipient Recipient address
     */
    function claimTokens(address tokenAddress, address recipient) external;

    /**
     *  @dev Claim the tokens stuck in the integrated adapters
     *  @param index MoneyMarkets array index
     *  @param tokenAddress ERC20 token address
     *  @param recipient Recipient address
     */
    function claimTokensFromAdapter(
        uint256 index,
        address tokenAddress,
        address recipient
    ) external;

    /**
     *  @dev Get the number of supported underlying protocols.
     *  @return MoneyMarkets length
     */
    function moneyMarketsCount() external view returns (uint256);

    /**
     *  @dev Get the count of supported tokens
     *  @return Number of supported tokens
     */
    function supportedTokensCount() external view returns (uint256);

    /**
     *  @dev Get the supported lending protocol
     *  @param tokenAddress ERC20 token address
     *  @param marketId MoneyMarkets array index
     *  @return tokenSupply
     */
    function getMoneyMarket(address tokenAddress, uint256 marketId) external view returns (uint256, uint256);

    /**
     *  @dev debt write off
     *  @param tokenAddress ERC20 token address
     *  @param amount WriteOff amount
     */
    function debtWriteOff(address tokenAddress, uint256 amount) external;
}

// File: contracts/asset/AssetManager.sol

pragma solidity 0.5.17;










/**
 *  @title AssetManager
 *  @dev Manage the token assets deposited by components and admins, and invest tokens to the integrated underlying lending protocols.
 */
contract AssetManager is Controller, ReentrancyGuard, IAssetManager {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IMoneyMarketAdapter[] public moneyMarkets;
    mapping(address => Market) public supportedMarkets;
    address[] public supportedTokensList;
    //record admin or userManager balance
    mapping(address => mapping(address => uint256)) public balances; //1 user 2 token
    mapping(address => uint256) public totalPrincipal; //total stake amount
    address public marketRegistry;
    uint256[] public withdrawSeq; // Priority sequence of money market indices for processing withdraws

    struct Market {
        bool isSupported;
    }

    modifier checkMarketSupported(address token) {
        require(isMarketSupported(token), "AssetManager: token not support");
        _;
    }

    modifier onlyAuth(address token) {
        require(
            _isUToken(msg.sender, token) || _isUserManager(msg.sender, token),
            "AssetManager: sender must uToken or userManager"
        );
        _;
    }

    function initialize(address _marketRegistry) public initializer {
        Controller.initialize(msg.sender);
        ReentrancyGuard.initialize();
        marketRegistry = _marketRegistry;
    }

    function setMarketRegistry(address _marketRegistry) external onlyAdmin {
        marketRegistry = _marketRegistry;
    }

    /**
     *  @dev Get the balance of asset manager, plus the total amount of tokens deposited to all the underlying lending protocols
     *  @param tokenAddress ERC20 token address
     *  @return Pool balance
     */
    function getPoolBalance(address tokenAddress) public view returns (uint256) {
        IERC20 poolToken = IERC20(tokenAddress);
        uint256 balance = poolToken.balanceOf(address(this));
        if (isMarketSupported(tokenAddress)) {
            return totalSupplyView(tokenAddress).add(balance);
        } else {
            return balance;
        }
    }

    /**
     *  @dev Returns the amount of the lending pool balance minus the amount of total staked.
     *  @param tokenAddress ERC20 token address
     *  @return Amount can be borrowed
     */
    function getLoanableAmount(address tokenAddress) public view returns (uint256) {
        uint256 poolBalance = getPoolBalance(tokenAddress);
        if (poolBalance > totalPrincipal[tokenAddress]) return poolBalance.sub(totalPrincipal[tokenAddress]);
        return 0;
    }

    /**
     *  @dev Get the total amount of tokens deposited to all the integrated underlying protocols without side effects.
     *  @param tokenAddress ERC20 token address
     *  @return Total market balance
     */
    function totalSupply(address tokenAddress) public returns (uint256) {
        if (isMarketSupported(tokenAddress)) {
            uint256 tokenSupply = 0;
            for (uint256 i = 0; i < moneyMarkets.length; i++) {
                if (!moneyMarkets[i].supportsToken(tokenAddress)) {
                    continue;
                }
                tokenSupply = moneyMarkets[i].getSupply(tokenAddress).add(tokenSupply);
            }

            return tokenSupply;
        } else {
            return 0;
        }
    }

    /**
     *  @dev Get the total amount of tokens deposited to all the integrated underlying protocols, but without side effects. Safe to call anytime, but may not get the most updated number for the current block. Call totalSupply() for that purpose.
     *  @param tokenAddress ERC20 token address
     *  @return Total market balance
     */
    function totalSupplyView(address tokenAddress) public view returns (uint256) {
        if (isMarketSupported(tokenAddress)) {
            uint256 tokenSupply = 0;
            for (uint256 i = 0; i < moneyMarkets.length; i++) {
                if (!moneyMarkets[i].supportsToken(tokenAddress)) {
                    continue;
                }
                tokenSupply = moneyMarkets[i].getSupplyView(tokenAddress).add(tokenSupply);
            }

            return tokenSupply;
        } else {
            return 0;
        }
    }

    /**
     *  @dev Check if there is an underlying protocol available for the given ERC20 token.
     *  @param tokenAddress ERC20 token address
     *  @return Whether is supported
     */
    function isMarketSupported(address tokenAddress) public view returns (bool) {
        return supportedMarkets[tokenAddress].isSupported;
    }

    /**
     *  @dev Deposit tokens to AssetManager, and those tokens will be passed along to adapters to deposit to integrated asset protocols if any is available.
     *  @param token ERC20 token address
     *  @param amount ERC20 token address
     *  @return Deposited amount
     */
    function deposit(address token, uint256 amount)
        external
        whenNotPaused()
        onlyAuth(token)
        nonReentrant
        returns (bool)
    {
        IERC20 poolToken = IERC20(token);
        require(amount > 0, "AssetManager: amount can not be zero");

        if (!_isUToken(msg.sender, token)) {
            balances[msg.sender][token] = balances[msg.sender][token].add(amount);
            totalPrincipal[token] = totalPrincipal[token].add(amount);
        }

        bool remaining = true;
        if (isMarketSupported(token)) {
            // assumption: markets are arranged in order of decreasing liquidity
            // iterate markets till floors are filled
            // floors define minimum amount to maintain confidence in liquidity
            for (uint256 i = 0; i < moneyMarkets.length && remaining; i++) {
                IMoneyMarketAdapter moneyMarket = moneyMarkets[i];

                if (!moneyMarket.supportsToken(token)) continue;
                if (moneyMarket.floorMap(token) <= moneyMarket.getSupply(token)) continue;

                poolToken.safeTransferFrom(msg.sender, address(moneyMarket), amount);
                moneyMarket.deposit(token);
                remaining = false;
            }

            // assumption: less liquid markets provide more yield
            // iterate markets in reverse to optimize for yield
            // do this only if floors are filled i.e. min liquidity satisfied
            // dposit in the market where ceiling is not being exceeded
            for (uint256 j = moneyMarkets.length; j > 0 && remaining; j--) {
                IMoneyMarketAdapter moneyMarket = moneyMarkets[j - 1];
                if (!moneyMarket.supportsToken(token)) continue;

                uint256 supply = moneyMarket.getSupply(token);
                uint256 ceiling = moneyMarket.ceilingMap(token);
                if (ceiling <= supply) continue;
                if (supply.add(amount) > ceiling) continue;

                poolToken.safeTransferFrom(msg.sender, address(moneyMarket), amount);
                moneyMarket.deposit(token);
                remaining = false;
            }
        }

        if (remaining) {
            poolToken.safeTransferFrom(msg.sender, address(this), amount);
        }

        emit LogDeposit(token, msg.sender, amount);

        return true;
    }

    /**
     *  @dev Withdraw from AssetManager
     *  @param token ERC20 token address
     *  @param account User address
     *  @param amount ERC20 token address
     *  @return Withdraw amount
     */
    function withdraw(
        address token,
        address account,
        uint256 amount
    ) external whenNotPaused() nonReentrant onlyAuth(token) returns (bool) {
        require(_checkSenderBalance(msg.sender, token, amount), "AssetManager: balance not enough to withdraw");

        uint256 remaining = amount;

        // If there are tokens in Asset Manager then transfer them on priority
        uint256 selfBalance = IERC20(token).balanceOf(address(this));
        if (selfBalance > 0) {
            uint256 withdrawAmount = selfBalance < remaining ? selfBalance : remaining;
            remaining = remaining.sub(withdrawAmount);
            IERC20(token).safeTransfer(account, withdrawAmount);
        }

        if (isMarketSupported(token)) {
            // iterate markets according to defined sequence and withdraw
            for (uint256 i = 0; i < withdrawSeq.length && remaining > 0; i++) {
                IMoneyMarketAdapter moneyMarket = moneyMarkets[withdrawSeq[i]];
                if (!moneyMarket.supportsToken(token)) continue;

                uint256 supply = moneyMarket.getSupply(token);
                if (supply == 0) continue;

                uint256 withdrawAmount = supply < remaining ? supply : remaining;
                remaining = remaining.sub(withdrawAmount);
                moneyMarket.withdraw(token, account, withdrawAmount);
            }
        }

        if (!_isUToken(msg.sender, token)) {
            balances[msg.sender][token] = balances[msg.sender][token].sub(amount).add(remaining);
            totalPrincipal[token] = totalPrincipal[token].sub(amount).add(remaining);
        }

        emit LogWithdraw(token, account, amount, remaining);

        return true;
    }

    function debtWriteOff(address token, uint256 amount) external {
        require(balances[msg.sender][token] >= amount, "AssetManager: balance not enough");
        balances[msg.sender][token] = balances[msg.sender][token].sub(amount);
        totalPrincipal[token] = totalPrincipal[token].sub(amount);
    }

    /**
     *  @dev Add a new ERC20 token to support in AssetManager
     *  @param tokenAddress ERC20 token address
     */
    function addToken(address tokenAddress) external onlyAdmin {
        require(!supportedMarkets[tokenAddress].isSupported, "AssetManager: token is exist");
        supportedTokensList.push(tokenAddress);
        supportedMarkets[tokenAddress].isSupported = true;

        approveAllMarketsMax(tokenAddress);
    }

    /**
     *  @dev For a give token set allowance for all integrated money markets
     *  @param tokenAddress ERC20 token address
     */
    function approveAllMarketsMax(address tokenAddress) public onlyAdmin {
        IERC20 poolToken = IERC20(tokenAddress);
        for (uint256 i = 0; i < moneyMarkets.length; i++) {
            poolToken.safeApprove(address(moneyMarkets[i]), 0);
            poolToken.safeApprove(address(moneyMarkets[i]), uint256(-1));
        }
    }

    /**
     *  @dev Add a new adapter for the underlying lending protocol
     *  @param adapterAddress adapter address
     */
    function addAdapter(address adapterAddress) external onlyAdmin {
        bool isExist = false;
        for (uint256 i = 0; i < moneyMarkets.length; i++) {
            if (adapterAddress == address(moneyMarkets[i])) isExist = true;
        }

        if (!isExist) moneyMarkets.push(IMoneyMarketAdapter(adapterAddress));

        approveAllTokensMax(adapterAddress);
    }

    function overwriteAdapters(address[] calldata adapters) external onlyAdmin {
        moneyMarkets = new IMoneyMarketAdapter[](adapters.length);
        for (uint256 i = 0; i < adapters.length; i++) {
            moneyMarkets[i] = IMoneyMarketAdapter(adapters[i]);
        }
    }

    /**
     *  @dev For a give moeny market set allowance for all underlying tokens
     *  @param adapterAddress Address of adaptor for money market
     */
    function approveAllTokensMax(address adapterAddress) public onlyAdmin {
        for (uint256 i = 0; i < supportedTokensList.length; i++) {
            IERC20 poolToken = IERC20(supportedTokensList[i]);
            poolToken.safeApprove(adapterAddress, 0);
            poolToken.safeApprove(adapterAddress, uint256(-1));
        }
    }

    /**
     *  @dev Set withdraw sequence
     *  @param newSeq priority sequence of money market indices to be used while withdrawing
     */
    function changeWithdrawSequence(uint256[] calldata newSeq) external onlyAdmin {
        withdrawSeq = newSeq;
    }

    /**
     * @dev Take all the supply of `tokenAddress` and redistribute it according to `percentages`.
     *
     * Rejects if the token is not supported.
     *
     * @param tokenAddress Address of the token that is going to be rebalanced
     * @param percentages A list of percentages, expressed as units in 10000, indicating how to deposit the tokens in
     * each underlying money market. The length of this array is one less than the amount of money markets: the last
     * money market will receive the remaining tokens. For example, if there are 3 money markets, and you want to
     * rebalance so that the first one has 10.5% of the tokens, the second one 55%, and the third one 34.5%, this param
     * will be [1050, 5500].
     */
    function rebalance(address tokenAddress, uint256[] calldata percentages)
        external
        checkMarketSupported(tokenAddress)
        onlyAdmin
    {
        IERC20 token = IERC20(tokenAddress);
        require(percentages.length + 1 == moneyMarkets.length, "AssetManager: percentages error");

        for (uint256 i = 0; i < moneyMarkets.length; i++) {
            if (!moneyMarkets[i].supportsToken(tokenAddress)) {
                continue;
            }
            moneyMarkets[i].withdrawAll(tokenAddress, address(this));
        }

        uint256 tokenSupply = token.balanceOf(address(this));

        for (uint256 i = 0; i < percentages.length; i++) {
            if (!moneyMarkets[i].supportsToken(tokenAddress)) {
                continue;
            }
            uint256 amountToDeposit = (tokenSupply * percentages[i]) / 10000;
            if (amountToDeposit == 0) {
                continue;
            }
            token.safeTransfer(address(moneyMarkets[i]), amountToDeposit);
            moneyMarkets[i].deposit(tokenAddress);
        }

        uint256 remainingTokens = token.balanceOf(address(this));
        if (moneyMarkets[moneyMarkets.length - 1].supportsToken(tokenAddress) && remainingTokens > 0) {
            token.safeTransfer(address(moneyMarkets[moneyMarkets.length - 1]), remainingTokens);
            moneyMarkets[moneyMarkets.length - 1].deposit(tokenAddress);
        }

        require(token.balanceOf(address(this)) == 0, "AssetManager: there are remaining funds in the fund pool");

        emit LogRebalance(tokenAddress, percentages);
    }

    /**
     *  @dev Claim the tokens left on AssetManager balance, in case there are tokens get stuck here.
     *  @param tokenAddress ERC20 token address
     *  @param recipient Recipient address
     */
    function claimTokens(address tokenAddress, address recipient) external onlyAdmin {
        require(recipient != address(0), "AsstManager: recipient can not be zero");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(recipient, balance);
    }

    /**
     *  @dev Claim the tokens stuck in the integrated adapters
     *  @param index MoneyMarkets array index
     *  @param tokenAddress ERC20 token address
     *  @param recipient Recipient address
     */
    function claimTokensFromAdapter(
        uint256 index,
        address tokenAddress,
        address recipient
    ) external onlyAdmin {
        IMoneyMarketAdapter moneyMarket = moneyMarkets[index];
        moneyMarket.claimTokens(tokenAddress, recipient);
    }

    /**
     *  @dev Get the number of supported underlying protocols.
     *  @return MoneyMarkets length
     */
    function moneyMarketsCount() external view returns (uint256) {
        return moneyMarkets.length;
    }

    /**
     *  @dev Get the count of supported tokens
     *  @return Number of supported tokens
     */
    function supportedTokensCount() external view returns (uint256) {
        return supportedTokensList.length;
    }

    /**
     *  @dev Get the supported lending protocol
     *  @param tokenAddress ERC20 token address
     *  @param marketId MoneyMarkets array index
     *  @return tokenSupply
     */
    function getMoneyMarket(address tokenAddress, uint256 marketId)
        external
        view
        returns (uint256 rate, uint256 tokenSupply)
    {
        rate = moneyMarkets[marketId].getRate(tokenAddress);
        tokenSupply = moneyMarkets[marketId].getSupplyView(tokenAddress).add(tokenSupply);
    }

    function _checkSenderBalance(
        address sender,
        address tokenAddress,
        uint256 amount
    ) private view returns (bool) {
        if (_isUToken(sender, tokenAddress)) {
            // For all the lending markets, which have no deposits, return the tokens from the pool
            return getLoanableAmount(tokenAddress) >= amount;
        } else {
            return balances[sender][tokenAddress] >= amount;
        }
    }

    function _isUToken(address sender, address token) private view returns (bool) {
        (address uTokenAddress, ) = IMarketRegistry(marketRegistry).tokens(token);
        return uTokenAddress == sender;
    }

    function _isUserManager(address sender, address token) private view returns (bool) {
        (, address userManagerAddress) = IMarketRegistry(marketRegistry).tokens(token);
        return userManagerAddress == sender;
    }
}