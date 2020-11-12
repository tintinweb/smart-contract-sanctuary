/*
https://powerpool.finance/
          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr
*/

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

pragma solidity ^0.6.2;

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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;




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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.6.0;


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
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

    }


    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

// File: contracts/interfaces/ILpTokenMigrator.sol

pragma solidity 0.6.12;

// note "contracts-ethereum-package" (but not "contracts") version of the package


interface ILpTokenMigrator {
    // Perform LP token migration from legacy UniswapV2 to PowerSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // PowerSwap must mint EXACTLY the same amount of PowerSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token, uint8 poolType) external returns (IERC20);
}

// File: contracts/interfaces/IVestedLPMining.sol

pragma solidity 0.6.12;



/**
 * @notice
 */
interface IVestedLPMining {

    /**
    * @notice Initializes the storage of the contract
    * @dev "constructor" to be called on a new proxy deployment
    * @dev Sets the contract `owner` account to the deploying account
    */
    function initialize(
        IERC20 _cvp,
        address _reservoir,
        uint256 _cvpPerBlock,
        uint256 _startBlock,
        uint256 _cvpVestingPeriodInBlocks
    ) external;

    function poolLength() external view returns (uint256);

    /// @notice Add a new pool (only the owner may call)
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint8 _poolType,
        bool _votesEnabled
    ) external;

    /// @notice Update parameters of the given pool (only the owner may call)
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint8 _poolType,
        bool _votesEnabled
    ) external;

    /// @notice Set the migrator contract (only the owner may call)
    function setMigrator(ILpTokenMigrator _migrator) external;

    /// @notice Set CVP reward per block (only the owner may call)
    /// @dev Consider updating pool before calling this function
    function setCvpPerBlock(uint256 _cvpPerBlock) external;

    /// @notice Set CVP vesting period in blocks (only the owner may call)
    function setCvpVestingPeriodInBlocks(uint256 _cvpVestingPeriodInBlocks) external;

    /// @notice Migrate LP token to another LP contract
    function migrate(uint256 _pid) external;

    /// @notice Return reward multiplier over the given _from to _to block
    function getMultiplier(uint256 _from, uint256 _to) external pure returns (uint256);

    /// @notice Return the amount of pending CVPs entitled to the given user of the pool
    function pendingCvp(uint256 _pid, address _user) external view returns (uint256);

    /// @notice Return the amount of CVP tokens which may be vested to a user of a pool in the current block
    function vestableCvp(uint256 _pid, address user) external view returns (uint256);

    /// @notice Return `true` if the LP Token is added to created pools
    function isLpTokenAdded(IERC20 _lpToken) external view returns (bool);

    /// @notice Update reward computation params for all pools
    /// @dev Be careful of gas spending
    function massUpdatePools() external;

    /// @notice Update CVP tokens allocation for the given pool
    function updatePool(uint256 _pid) external;

    /// @notice Deposit the given amount of LP tokens to the given pool
    function deposit(uint256 _pid, uint256 _amount) external;

    /// @notice Withdraw the given amount of LP tokens from the given pool
    function withdraw(uint256 _pid, uint256 _amount) external;

    /// @notice Withdraw LP tokens without caring about pending CVP tokens. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;

    /// @notice Write votes of the given user at the current block
    function checkpointVotes(address _user) external;

    /// @notice Get CVP amount and the share of CVPs in LP pools for the given account and the checkpoint
    function getCheckpoint(address account, uint32 checkpointId)
    external view returns (uint32 fromBlock, uint96 cvpAmount, uint96 pooledCvpShare);

    event AddLpToken(address indexed lpToken, uint256 indexed pid, uint256 allocPoint);
    event SetLpToken(address indexed lpToken, uint256 indexed pid, uint256 allocPoint);
    event SetMigrator(address indexed migrator);
    event SetCvpPerBlock(uint256 cvpPerBlock);
    event SetCvpVestingPeriodInBlocks(uint256 cvpVestingPeriodInBlocks);
    event MigrateLpToken(address indexed oldLpToken, address indexed newLpToken, uint256 indexed pid);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event CheckpointTotalLpVotes(uint256 lpVotes);
    event CheckpointUserLpVotes(address indexed user, uint256 indexed pid, uint256 lpVotes);
    event CheckpointUserVotes(address indexed user, uint256 pendedVotes, uint256 lpVotesShare);
}

// File: contracts/lib/ReservedSlots.sol

pragma solidity 0.6.12;

/// @dev Slots reserved for possible storage layout changes (it neither spends gas nor adds extra bytecode)
contract ReservedSlots {
    uint256[100] private __gap;
}

// File: contracts/lib/SafeMath96.sol

pragma solidity 0.6.12;

library SafeMath96 {

    function add(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function add(uint96 a, uint96 b) internal pure returns (uint96) {
        return add(a, b, "SafeMath96: addition overflow");
    }

    function sub(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function sub(uint96 a, uint96 b) internal pure returns (uint96) {
        return sub(a, b, "SafeMath96: subtraction overflow");
    }

    function average(uint96 a, uint96 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function fromUint(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function fromUint(uint n) internal pure returns (uint96) {
        return fromUint(n, "SafeMath96: exceeds 96 bits");
    }
}

// File: contracts/lib/SafeMath32.sol

pragma solidity 0.6.12;

library SafeMath32 {

    function add(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        return add(a, b, "SafeMath32: addition overflow");
    }

    function sub(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        return sub(a, b, "SafeMath32: subtraction overflow");
    }

    function fromUint(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function fromUint(uint n) internal pure returns (uint32) {
        return fromUint(n, "SafeMath32: exceeds 32 bits");
    }
}

// File: contracts/lib/DelegatableCheckpoints.sol

pragma solidity 0.6.12;


library DelegatableCheckpoints {

    /// @dev A checkpoint storing some data effective from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint192 data;
        // uint32 __reserved;
    }

    /// @dev A set of checkpoints and a 'delegatee'
    struct Record {
        /// @dev new slot
        uint32 numCheckpoints;
        uint32 lastCheckpointBlock;
        address delegatee;
        // uint32 __reserved;

        /// @dev new slot
        // Checkpoints by IDs
        mapping (uint32 => Checkpoint) checkpoints;
        // @dev Checkpoint IDs get counted from 1 (but not from 0) -
        // the 1st checkpoint has ID of 1, and the last checkpoint' ID is `numCheckpoints`
    }

    function getCheckpoint(Record storage record, uint checkpointId)
    internal view returns (uint32 fromBlock, uint192 data)
    {
        return checkpointId == 0 || checkpointId > record.numCheckpoints
            ? (0, 0)
            : _getCheckpoint(record, uint32(checkpointId));
    }

    function _getCheckpoint(Record storage record, uint32 checkpointId)
    internal view returns (uint32 fromBlock, uint192 data)
    {
        return (record.checkpoints[checkpointId].fromBlock, record.checkpoints[checkpointId].data);
    }

    /**
     * @dev Gets the data recorded in the latest checkpoint of the given record
     */
    function getLatestData(Record storage record)
    internal view returns (uint192)
    {
        Record memory _record = record;
        return _record.numCheckpoints == 0
        ? 0
        : record.checkpoints[_record.numCheckpoints].data;
    }

    /**
     * @dev Returns the prior data written in the given record' checkpoints as of a block number
     * (reverts if the requested block has not been finalized)
     * @param record The record with checkpoints
     * @param blockNumber The block number to get the data at
     * @param checkpointId Optional ID of a checkpoint to first look into
     * @return The data effective as of the given block
     */
    function getPriorData(Record storage record, uint blockNumber, uint checkpointId)
    internal view returns (uint192)
    {
        uint32 blockNum = _safeMinedBlockNum(blockNumber);
        Record memory _record = record;
        Checkpoint memory cp;

        // First check specific checkpoint, if it's provided
        if (checkpointId != 0) {
            require(checkpointId <= _record.numCheckpoints, "ChPoints: invalid checkpoint id");
            uint32 cpId = uint32(checkpointId);

            cp = record.checkpoints[cpId];
            if (cp.fromBlock == blockNum) {
                return cp.data;
            } else if (cp.fromBlock < blockNum) {
                if (cpId == _record.numCheckpoints) {
                    return cp.data;
                }
                uint32 nextFromBlock = record.checkpoints[cpId + 1].fromBlock;
                if (nextFromBlock > blockNum) {
                    return cp.data;
                }
            }
        }

        // Finally, search trough all checkpoints
        ( , uint192 data) = _findCheckpoint(record, _record.numCheckpoints, blockNum);
        return data;
    }

    /**
     * @dev Finds a checkpoint in the given record for the given block number
     * (reverts if the requested block has not been finalized)
     * @param record The record with checkpoints
     * @param blockNumber The block number to get the checkpoint at
     * @return id The checkpoint ID
     * @return data The checkpoint data
     */
    function findCheckpoint(Record storage record, uint blockNumber)
    internal view returns (uint32 id, uint192 data)
    {
        uint32 blockNum = _safeMinedBlockNum(blockNumber);
        uint32 numCheckpoints = record.numCheckpoints;

        (id, data) = _findCheckpoint(record, numCheckpoints, blockNum);
    }

    /**
     * @dev Writes a checkpoint with given data to the given record and returns the checkpoint ID
     */
    function writeCheckpoint(Record storage record, uint192 data)
    internal returns (uint32 id)
    {
        uint32 blockNum = _safeBlockNum(block.number);
        Record memory _record = record;

        uint192 oldData = _record.numCheckpoints > 0 ? record.checkpoints[_record.numCheckpoints].data : 0;
        bool isChanged = data != oldData;

        if (_record.lastCheckpointBlock != blockNum) {
            _record.numCheckpoints = _record.numCheckpoints + 1; // overflow chance ignored
            record.numCheckpoints = _record.numCheckpoints;
            record.lastCheckpointBlock = blockNum;
            isChanged = true;
        }
        if (isChanged) {
            record.checkpoints[_record.numCheckpoints] = Checkpoint(blockNum, data);
        }
        id = _record.numCheckpoints;
    }

    /**
     * @dev Gets the given record properties (w/o mappings)
     */
    function getProperties(Record storage record) internal view returns (uint32, uint32, address) {
        return (record.numCheckpoints, record.lastCheckpointBlock, record.delegatee);
    }

    /**
     * @dev Writes given delegatee to the given record
     */
    function writeDelegatee(Record storage record, address delegatee) internal {
        record.delegatee = delegatee;
    }

    function _safeBlockNum(uint256 blockNumber) private pure returns (uint32) {
        require(blockNumber < 2**32, "ChPoints: blockNum >= 2**32");
        return uint32(blockNumber);
    }

    function _safeMinedBlockNum(uint256 blockNumber) private view returns (uint32) {
        require(blockNumber < block.number, "ChPoints: block not yet mined");
        return _safeBlockNum(blockNumber);
    }

    function _findCheckpoint(Record storage record, uint32 numCheckpoints, uint32 blockNum)
    private view returns (uint32, uint192)
    {
        Checkpoint memory cp;

        // Check special cases first
        if (numCheckpoints == 0) {
            return (0, 0);
        }
        cp = record.checkpoints[numCheckpoints];
        if (cp.fromBlock <= blockNum) {
            return (numCheckpoints, cp.data);
        }
        if (record.checkpoints[1].fromBlock > blockNum) {
            return (0, 0);
        }

        uint32 lower = 1;
        uint32 upper = numCheckpoints;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            cp = record.checkpoints[center];
            if (cp.fromBlock == blockNum) {
                return (center, cp.data);
            } else if (cp.fromBlock < blockNum) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return (lower, record.checkpoints[lower].data);
    }
}

// File: contracts/DelegatableVotes.sol

pragma solidity 0.6.12;



abstract contract DelegatableVotes {
    using SafeMath96 for uint96;
    using DelegatableCheckpoints for DelegatableCheckpoints.Record;

    /**
     * @notice Votes computation data for each account
     * @dev Data adjusted to account "delegated" votes
     * @dev For the contract address, stores shared for all accounts data
     */
    mapping (address => DelegatableCheckpoints.Record) public book;

    /**
     * @dev Data on votes which an account may delegate or has already delegated
     */
    mapping (address => uint192) internal delegatables;

    /// @notice The event is emitted when a delegate account' vote balance changes
    event CheckpointBalanceChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice An event that's emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @notice Get the "delegatee" account for the message sender
     */
    function delegatee() public view returns (address) {
        return book[msg.sender].delegatee;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        require(delegatee != address(this), "delegate: can't delegate to contract address");
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Get the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint192 userData = book[account].getLatestData();
        if (userData == 0) return 0;

        uint192 sharedData = book[address(this)].getLatestData();
        return _computeUserVotes(userData, sharedData);
    }

    /**
     * @notice Determine the prior number of votes for the given account as of the given block
     * @dev To prevent misinformation, the call reverts if the block requested is not finalized
     * @param account The address of the account to get votes for
     * @param blockNumber The block number to get votes at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        return getPriorVotes(account, blockNumber, 0, 0);
    }

    /**
     * @notice Gas-optimized version of the `getPriorVotes` function -
     * it accepts IDs of checkpoints to look for voice data as of the given block in
     * (if the checkpoints miss the data, it get searched through all checkpoints recorded)
     * @dev Call (off-chain) the `findCheckpoints` function to get needed IDs
     * @param account The address of the account to get votes for
     * @param blockNumber The block number to get votes at
     * @param userCheckpointId ID of the checkpoint to look for the user data first
     * @param userCheckpointId ID of the checkpoint to look for the shared data first
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(
        address account,
        uint blockNumber,
        uint32 userCheckpointId,
        uint32 sharedCheckpointId
    ) public view returns (uint96)
    {
        uint192 userData = book[account].getPriorData(blockNumber, userCheckpointId);
        if (userData == 0) return 0;

        uint192 sharedData = book[address(this)].getPriorData(blockNumber, sharedCheckpointId);
        return _computeUserVotes(userData, sharedData);
    }

    /// @notice Returns IDs of checkpoints which store the given account' voice computation data
    /// @dev Intended for off-chain use (by UI)
    function findCheckpoints(address account, uint256 blockNumber)
    external view returns (uint32 userCheckpointId, uint32 sharedCheckpointId)
    {
        require(account != address(0), "findCheckpoints: zero account");
        (userCheckpointId, ) = book[account].findCheckpoint(blockNumber);
        (sharedCheckpointId, ) = book[address(this)].findCheckpoint(blockNumber);
    }

    function _getCheckpoint(address account, uint32 checkpointId)
    internal view returns (uint32 fromBlock, uint192 data)
    {
        (fromBlock, data) = book[account].getCheckpoint(checkpointId);
    }

    function _writeSharedData(uint192 data) internal {
        book[address(this)].writeCheckpoint(data);
    }

    function _writeUserData(address account, uint192 data) internal {
        DelegatableCheckpoints.Record storage src = book[account];
        address delegatee = src.delegatee;
        DelegatableCheckpoints.Record storage dst = delegatee == address(0) ? src : book[delegatee];

        dst.writeCheckpoint(
           // keep in mind voices which others could have delegated
            _computeUserData(dst.getLatestData(), data, delegatables[account])
        );
        delegatables[account] = data;
    }

    function _moveUserData(address account, address from, address to) internal {
        DelegatableCheckpoints.Record storage src;
        DelegatableCheckpoints.Record storage dst;

        if (from == address(0)) { // no former delegatee
            src = book[account];
            dst = book[to];
        }
        else if (to == address(0)) { // delegation revoked
            src = book[from];
            dst = book[account];
        }
        else {
            src = book[from];
            dst = book[to];
        }
        uint192 delegatable = delegatables[account];

        uint192 srcPrevData = src.getLatestData();
        uint192 srcData = _computeUserData(srcPrevData, 0, delegatable);
        if (srcPrevData != srcData) src.writeCheckpoint(srcData);

        uint192 dstPrevData = dst.getLatestData();
        uint192 dstData = _computeUserData(dstPrevData, delegatable, 0);
        if (dstPrevData != dstData) dst.writeCheckpoint(dstData);
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = book[delegator].delegatee;
        book[delegator].delegatee = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveUserData(delegator, currentDelegate, delegatee);
    }

    function _computeUserVotes(uint192 userData, uint192 sharedData) internal pure virtual returns (uint96 votes);

    function _computeUserData(uint192 prevData, uint192 newDelegated, uint192 prevDelegated)
    internal pure virtual returns (uint192 userData)
    {
        (uint96 prevA, uint96 prevB) = _unpackData(prevData);
        (uint96 newDelegatedA, uint96 newDelegatedB) = _unpackData(newDelegated);
        (uint96 prevDelegatedA, uint96 prevDelegatedB) = _unpackData(prevDelegated);
        userData = _packData(
            _getNewValue(prevA, newDelegatedA, prevDelegatedA),
            _getNewValue(prevB, newDelegatedB, prevDelegatedB)
        );
    }

    function _unpackData(uint192 data) internal pure virtual returns (uint96 valA, uint96 valB) {
        return (uint96(data >> 96), uint96((data << 96) >> 96));
    }

    function _packData(uint96 valA, uint96 valB) internal pure  virtual returns (uint192 data) {
        return ((uint192(valA) << 96) | uint192(valB));
    }

    function _getNewValue(uint96 val, uint96 more, uint96 less) internal pure  virtual returns (uint96 newVal) {
        if (more == less) {
            newVal = val;
        } else if (more > less) {
            newVal = val.add(more.sub(less));
        } else {
            uint96 decrease = less.sub(more);
            newVal = val > decrease ? val.sub(decrease) : 0;
        }
    }

    uint256[50] private _gap; // reserved
}

// File: contracts/VestedLPMining.sol

pragma solidity 0.6.12;












contract VestedLPMining is
    OwnableUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    ReservedSlots,
    DelegatableVotes,
    IVestedLPMining
{
    using SafeMath for uint256;
    using SafeMath96 for uint96;
    using SafeMath32 for uint32;

    using SafeERC20 for IERC20;

    /// @dev properties grouped to optimize storage costs

    struct User {
        /// @dev new slot
        uint32 lastUpdateBlock;   // block when the params (below) were updated
        uint32 vestingBlock;      // block by when all entitled CVP tokens to be vested
        uint96 pendedCvp;         // amount of CVPs tokens entitled but not yet vested to the user
        uint96 cvpAdjust;         // adjustments for pended CVP tokens amount computation
                                  // (with regard to LP token deposits/withdrawals in the past)
        /// @dev new slot
        uint256 lptAmount;        // amount of LP tokens the user has provided to a pool
        /** @dev
         * At any time, the amount of CVP tokens entitled to a user but not yet vested is the sum of:
         * (1) CVP token amount entitled after the user last time deposited or withdrawn LP tokens
         *     = (user.lptAmount * pool.accCvpPerLpt) - user.cvpAdjust
         * (2) CVP token amount entitled before the last deposit or withdrawal but not yet vested
         *     = user.pendedCvp
         *
         * Whenever a user deposits or withdraws LP tokens to a pool:
         *   1. `pool.accCvpPerLpt` for the pool gets updated;
         *   2. CVP token amounts to be entitled and vested to the user get computed;
         *   3. Token amount which may be vested get sent to the user;
         *   3. User' `lptAmount`, `cvpAdjust` and `pendedCvp` get updated.
         *
         * Note comments on vesting rules in the `function _computeCvpVesting` code bellow.
         */
    }

    struct Pool {
        /// @dev new slot
        IERC20 lpToken;           // address of the LP token contract
        bool votesEnabled;        // if the pool is enabled to write votes
        uint8 poolType;           // pool type (1 - Uniswap, 2 - Balancer)
        uint32 allocPoint;        // points assigned to the pool, which affect CVPs distribution between pools
        uint32 lastUpdateBlock;   // latest block when the pool params which follow was updated
        /// @dev new slot
        uint256 accCvpPerLpt;     // accumulated distributed CVPs per one deposited LP token, times 1e12
    }
    // scale factor for `accCvpPerLpt`
    uint256 internal constant SCALE = 1e12;

    /// @dev new slot
    // The CVP TOKEN
    IERC20 public cvp;
    // Total amount of CVP tokens pended (not yet vested to users)
    uint96 public cvpVestingPool;

    /// @dev new slot
    // Reservoir address
    address public reservoir;
    // Vesting duration in blocks
    uint32 public cvpVestingPeriodInBlocks;
    // The block number when CVP mining starts
    uint32 public startBlock;
    // The amount of CVP tokens rewarded to all pools every block
    uint96 public cvpPerBlock;

    /// @dev new slot
    // The migrator contract (only the owner may assign it)
    ILpTokenMigrator public migrator;

    // Params of each pool
    Pool[] public pools;
    // Pid (i.e. the index in `pools`) of each pool by its LP token address
    mapping(address => uint256) public poolPidByAddress;
    // Params of each user that stakes LP tokens, by the Pid and the user address
    mapping (uint256 => mapping (address => User)) public users;
    // Sum of allocation points for all pools
    uint256 public totalAllocPoint = 0;

    /// @inheritdoc IVestedLPMining
    function initialize(
        IERC20 _cvp,
        address _reservoir,
        uint256 _cvpPerBlock,
        uint256 _startBlock,
        uint256 _cvpVestingPeriodInBlocks
    ) external override initializer {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();

        cvp = _cvp;
        reservoir = _reservoir;
        startBlock = SafeMath32.fromUint(_startBlock, "VLPMining: too big startBlock");
        cvpVestingPeriodInBlocks = SafeMath32.fromUint(_cvpVestingPeriodInBlocks, "VLPMining: too big vest period");
        setCvpPerBlock(_cvpPerBlock);
    }

    /// @inheritdoc IVestedLPMining
    function poolLength() external view override returns (uint256) {
        return pools.length;
    }

    /// @inheritdoc IVestedLPMining
    function add(uint256 _allocPoint, IERC20 _lpToken, uint8 _poolType, bool _votesEnabled)
    public override onlyOwner
    {
        require(!isLpTokenAdded(_lpToken), "VLPMining: token already added");

        massUpdatePools();
        uint32 blockNum = _currBlock();
        uint32 lastUpdateBlock = blockNum > startBlock ? blockNum : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        uint256 pid = pools.length;
        pools.push(Pool({
            lpToken: _lpToken,
            votesEnabled: _votesEnabled,
            poolType: _poolType,
            allocPoint: SafeMath32.fromUint(_allocPoint, "VLPMining: too big allocation"),
            lastUpdateBlock: lastUpdateBlock,
            accCvpPerLpt: 0
        }));
        poolPidByAddress[address(_lpToken)] = pid;

        emit AddLpToken(address(_lpToken), pid, _allocPoint);
    }

    /// @inheritdoc IVestedLPMining
    function set(uint256 _pid, uint256 _allocPoint, uint8 _poolType, bool _votesEnabled)
    public override onlyOwner
    {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(uint256(pools[_pid].allocPoint)).add(_allocPoint);
        pools[_pid].allocPoint = SafeMath32.fromUint(_allocPoint, "VLPMining: too big allocation");
        pools[_pid].votesEnabled = _votesEnabled;
        pools[_pid].poolType = _poolType;

        emit SetLpToken(address(pools[_pid].lpToken), _pid, _allocPoint);
    }

    /// @inheritdoc IVestedLPMining
    function setMigrator(ILpTokenMigrator _migrator) public override onlyOwner {
        migrator = _migrator;

        emit SetMigrator(address(_migrator));
    }

    /// @inheritdoc IVestedLPMining
    function setCvpPerBlock(uint256 _cvpPerBlock) public override onlyOwner {
        cvpPerBlock = SafeMath96.fromUint(_cvpPerBlock, "VLPMining: too big cvpPerBlock");

        emit SetCvpPerBlock(_cvpPerBlock);
    }

    /// @inheritdoc IVestedLPMining
    function setCvpVestingPeriodInBlocks(uint256 _cvpVestingPeriodInBlocks) public override onlyOwner {
        cvpVestingPeriodInBlocks = SafeMath32.fromUint(
            _cvpVestingPeriodInBlocks,
            "VLPMining: too big cvpVestingPeriodInBlocks"
        );

        emit SetCvpVestingPeriodInBlocks(_cvpVestingPeriodInBlocks);
    }

    /// @inheritdoc IVestedLPMining
    /// @dev Anyone may call, so we have to trust the migrator contract
    function migrate(uint256 _pid) public override nonReentrant {
        require(address(migrator) != address(0), "VLPMining: no migrator");
        Pool storage pool = pools[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken, pool.poolType);
        require(bal == newLpToken.balanceOf(address(this)), "VLPMining: invalid migration");
        pool.lpToken = newLpToken;

        delete poolPidByAddress[address(lpToken)];
        poolPidByAddress[address(newLpToken)] = _pid;

        emit MigrateLpToken(address(lpToken), address(newLpToken), _pid);
    }

    /// @inheritdoc IVestedLPMining
    function getMultiplier(uint256 _from, uint256 _to) public pure override returns (uint256) {
        return _to.sub(_from, "VLPMining: _to exceeds _from");
    }

    /// @inheritdoc IVestedLPMining
    function pendingCvp(uint256 _pid, address _user) external view override returns (uint256) {
        if (_pid >= pools.length) return 0;

        Pool memory _pool = pools[_pid];
        User storage user = users[_pid][_user];

        _computePoolReward(_pool);
        uint96 newlyEntitled = _computeCvpToEntitle(
            user.lptAmount,
            user.cvpAdjust,
            _pool.accCvpPerLpt
        );

        return uint256(newlyEntitled.add(user.pendedCvp));
    }

    /// @inheritdoc IVestedLPMining
    function vestableCvp(uint256 _pid, address user) external view override returns (uint256) {
        Pool memory _pool = pools[_pid];
        User memory _user = users[_pid][user];

        _computePoolReward(_pool);
        ( , uint256 newlyVested) = _computeCvpVesting(_user, _pool.accCvpPerLpt);

        return newlyVested;
    }

    /// @inheritdoc IVestedLPMining
    function isLpTokenAdded(IERC20 _lpToken) public view override returns (bool) {
        uint256 pid = poolPidByAddress[address(_lpToken)];
        return pools.length > pid && address(pools[pid].lpToken) == address(_lpToken);
    }

    /// @inheritdoc IVestedLPMining
    function massUpdatePools() public override {
        uint256 length = pools.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// @inheritdoc IVestedLPMining
    function updatePool(uint256 _pid) public override nonReentrant {
        Pool storage pool = pools[_pid];
        _doPoolUpdate(pool);
    }

    /// @inheritdoc IVestedLPMining
    function deposit(uint256 _pid, uint256 _amount) public override nonReentrant {
        _validatePoolId(_pid);

        Pool storage pool = pools[_pid];
        User storage user = users[_pid][msg.sender];

        _doPoolUpdate(pool);
        _vestUserCvp(user, pool.accCvpPerLpt);

        if(_amount != 0) {
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            user.lptAmount = user.lptAmount.add(_amount);
        }
        user.cvpAdjust = _computeCvpAdjustment(user.lptAmount, pool.accCvpPerLpt);
        emit Deposit(msg.sender, _pid, _amount);

        _doCheckpointVotes(msg.sender);
    }

    /// @inheritdoc IVestedLPMining
    function withdraw(uint256 _pid, uint256 _amount) public override nonReentrant {
        _validatePoolId(_pid);

        Pool storage pool = pools[_pid];
        User storage user = users[_pid][msg.sender];
        require(user.lptAmount >= _amount, "VLPMining: amount exceeds balance");

        _doPoolUpdate(pool);
        _vestUserCvp(user, pool.accCvpPerLpt);

        if(_amount != 0) {
            user.lptAmount = user.lptAmount.sub(_amount);
            pool.lpToken.safeTransfer(msg.sender, _amount);
        }
        user.cvpAdjust = _computeCvpAdjustment(user.lptAmount, pool.accCvpPerLpt);
        emit Withdraw(msg.sender, _pid, _amount);

        _doCheckpointVotes(msg.sender);
    }

    /// @inheritdoc IVestedLPMining
    function emergencyWithdraw(uint256 _pid) public override nonReentrant {
        _validatePoolId(_pid);

        Pool storage pool = pools[_pid];
        User storage user = users[_pid][msg.sender];

        pool.lpToken.safeTransfer(msg.sender, user.lptAmount);
        emit EmergencyWithdraw(msg.sender, _pid, user.lptAmount);

        if (user.pendedCvp > 0) {
            // TODO: Make user.pendedCvp be updated as of the pool' lastUpdateBlock
            if (user.pendedCvp > cvpVestingPool) {
                cvpVestingPool = cvpVestingPool.sub(user.pendedCvp);
            } else {
                cvpVestingPool = 0;
            }
        }

        user.lptAmount = 0;
        user.cvpAdjust = 0;
        user.pendedCvp = 0;
        user.vestingBlock = 0;

        _doCheckpointVotes(msg.sender);
    }

    /// @inheritdoc IVestedLPMining
    function checkpointVotes(address _user) public override nonReentrant {
        _doCheckpointVotes(_user);
    }

    /// @inheritdoc IVestedLPMining
    function getCheckpoint(address account, uint32 checkpointId)
    external override view returns (uint32 fromBlock, uint96 cvpAmount, uint96 pooledCvpShare)
    {
        uint192 data;
        (fromBlock, data) = _getCheckpoint(account, checkpointId);
        (cvpAmount, pooledCvpShare) = _unpackData(data);
    }

    function _doCheckpointVotes(address _user) internal {
        uint256 length = pools.length;
        uint96 userPendedCvp = 0;
        uint256 userTotalLpCvp = 0;
        uint96 totalLpCvp = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            userPendedCvp = userPendedCvp.add(users[pid][_user].pendedCvp);

            Pool storage pool = pools[pid];
            uint96 lpCvp = SafeMath96.fromUint(
                cvp.balanceOf(address(pool.lpToken)),
                // this and similar error messages are not intended for end-users
                "VLPMining::_doCheckpointVotes:1"
            );
            totalLpCvp = totalLpCvp.add(lpCvp);

            if (!pool.votesEnabled) {
                continue;
            }

            uint256 lptTotalSupply = pool.lpToken.totalSupply();
            uint256 lptAmount = users[pid][_user].lptAmount;
            if (lptAmount != 0 && lptTotalSupply != 0) {
                uint256 cvpPerLpt = uint256(lpCvp).mul(SCALE).div(lptTotalSupply);
                uint256 userLpCvp = lptAmount.mul(cvpPerLpt).div(SCALE);
                userTotalLpCvp = userTotalLpCvp.add(userLpCvp);

                emit CheckpointUserLpVotes(_user, pid, userLpCvp);
            }
        }

        uint96 lpCvpUserShare = (userTotalLpCvp == 0 || totalLpCvp == 0)
            ? 0
            : SafeMath96.fromUint(
                userTotalLpCvp.mul(SCALE).div(totalLpCvp),
                "VLPMining::_doCheckpointVotes:2"
            );

        emit CheckpointTotalLpVotes(totalLpCvp);
        emit CheckpointUserVotes(_user, uint256(userPendedCvp), lpCvpUserShare);

        _writeUserData(_user, _packData(userPendedCvp, lpCvpUserShare));
        _writeSharedData(_packData(totalLpCvp, 0));
    }

    function _transferCvp(address _to, uint256 _amount) internal {
        SafeERC20.safeTransferFrom(cvp, reservoir, _to, _amount);
    }

    /// @dev must be guarded for reentrancy
    function _doPoolUpdate(Pool storage pool) internal {
        Pool memory _pool = pool;
        uint32 prevBlock = _pool.lastUpdateBlock;
        uint256 prevAcc = _pool.accCvpPerLpt;

        uint256 cvpReward = _computePoolReward(_pool);
        if (cvpReward != 0) {
            cvpVestingPool = cvpVestingPool.add(
                SafeMath96.fromUint(cvpReward, "VLPMining::_doPoolUpdate:1"),
                "VLPMining::_doPoolUpdate:2"
            );
        }
        if (_pool.accCvpPerLpt > prevAcc) {
            pool.accCvpPerLpt = _pool.accCvpPerLpt;
        }
        if (_pool.lastUpdateBlock > prevBlock) {
            pool.lastUpdateBlock = _pool.lastUpdateBlock;
        }
    }

    function _vestUserCvp(User storage user, uint256 accCvpPerLpt) internal {
        User memory _user = user;
        uint32 prevVestingBlock = _user.vestingBlock;
        uint32 prevUpdateBlock = _user.lastUpdateBlock;
        (uint256 newlyEntitled, uint256 newlyVested) = _computeCvpVesting(_user, accCvpPerLpt);

        if (newlyEntitled != 0) {
            user.pendedCvp = _user.pendedCvp;
        }
        if (newlyVested != 0) {
            if (newlyVested > cvpVestingPool) newlyVested = uint256(cvpVestingPool);
            cvpVestingPool = cvpVestingPool.sub(
                SafeMath96.fromUint(newlyVested, "VLPMining::_vestUserCvp:1"),
                "VLPMining::_vestUserCvp:2"
            );
            _transferCvp(msg.sender, newlyVested);
        }
        if (_user.vestingBlock > prevVestingBlock) {
            user.vestingBlock = _user.vestingBlock;
        }
        if (_user.lastUpdateBlock > prevUpdateBlock) {
            user.lastUpdateBlock = _user.lastUpdateBlock;
        }
    }

    /* @dev Compute the amount of CVP tokens to be entitled and vested to a user of a pool
     * ... and update the `_user` instance (in the memory):
     *   `_user.pendedCvp` gets increased by `newlyEntitled - newlyVested`
     *   `_user.vestingBlock` set to the updated value
     *   `_user.lastUpdateBlock` set to the current block
     *
     * @param _user - user to compute tokens for
     * @param accCvpPerLpt - value of the pool' `pool.accCvpPerLpt`
     * @return newlyEntitled - CVP amount to entitle (on top of tokens entitled so far)
     * @return newlyVested - CVP amount to vest (on top of tokens already vested)
     */
    function _computeCvpVesting(User memory _user, uint256 accCvpPerLpt)
    internal view returns (uint256 newlyEntitled, uint256 newlyVested)
    {
        uint32 prevBlock = _user.lastUpdateBlock;
        _user.lastUpdateBlock = _currBlock();
        if (prevBlock >= _user.lastUpdateBlock) {
            return (0, 0);
        }

        uint32 age = _user.lastUpdateBlock - prevBlock;

        // Tokens which are to be entitled starting from the `user.lastUpdateBlock`, shall be
        // vested proportionally to the number of blocks already minted within the period between
        // the `user.lastUpdateBlock` and `cvpVestingPeriodInBlocks` following the current block
        newlyEntitled = uint256(_computeCvpToEntitle(_user.lptAmount, _user.cvpAdjust, accCvpPerLpt));
        uint256 newToVest = newlyEntitled == 0 ? 0 : (
            newlyEntitled.mul(uint256(age)).div(uint256(age + cvpVestingPeriodInBlocks))
        );

        // Tokens which have been pended since the `user.lastUpdateBlock` shall be vested:
        // - in full, if the `user.vestingBlock` has been mined
        // - otherwise, proportionally to the number of blocks already mined so far in the period
        //   between the `user.lastUpdateBlock` and the `user.vestingBlock` (not yet mined)
        uint256 pended = uint256(_user.pendedCvp);
        age = _user.lastUpdateBlock >= _user.vestingBlock
            ? cvpVestingPeriodInBlocks
            : _user.lastUpdateBlock - prevBlock;
        uint256 pendedToVest = pended == 0 ? 0 : (
            age >= cvpVestingPeriodInBlocks
                ? pended
                : pended.mul(uint256(age)).div(uint256(_user.vestingBlock - prevBlock))
        );

        newlyVested = pendedToVest.add(newToVest);
        _user.pendedCvp = SafeMath96.fromUint(
            uint256(_user.pendedCvp).add(newlyEntitled).sub(newlyVested),
            "VLPMining::computeCvpVest:1"
        );

        // Amount of CVP token pended (i.e. not yet vested) from now
        uint256 remainingPended = pended == 0 ? 0 : pended.sub(pendedToVest);
        uint256 unreleasedNewly = newlyEntitled == 0 ? 0 : newlyEntitled.sub(newlyVested);
        uint256 pending = remainingPended.add(unreleasedNewly);

        // Compute the vesting block (i.e. when the pended tokens to be all vested)
        uint256 period = 0;
        if (pending == 0) {
            // `period` remains 0
        } else if (remainingPended == 0) {
            // only newly entitled CVPs remain pended
            period = cvpVestingPeriodInBlocks;
        } else {
            // "old" CVPs and, perhaps, "new" CVPs are pending - the weighted average applied
            age = _user.vestingBlock - _user.lastUpdateBlock;
            period = (
                (remainingPended.mul(age))
                .add(unreleasedNewly.mul(cvpVestingPeriodInBlocks))
            ).div(pending);
        }
        _user.vestingBlock = _user.lastUpdateBlock + (
            cvpVestingPeriodInBlocks > uint32(period) ? uint32(period) : cvpVestingPeriodInBlocks
        );

        return (newlyEntitled, newlyVested);
    }

    function _computePoolReward(Pool memory _pool)
    internal view returns (uint256 poolCvpReward)
    {
        poolCvpReward = 0;
        uint32 blockNum = _currBlock();
        if (blockNum > _pool.lastUpdateBlock) {
            uint256 multiplier = uint256(blockNum - _pool.lastUpdateBlock); // can't overflow
            _pool.lastUpdateBlock = blockNum;

            uint256 lptBalance = _pool.lpToken.balanceOf(address(this));
            if (lptBalance != 0) {
                poolCvpReward = multiplier
                    .mul(uint256(cvpPerBlock))
                    .mul(uint256(_pool.allocPoint))
                    .div(totalAllocPoint);

                _pool.accCvpPerLpt = _pool.accCvpPerLpt.add(poolCvpReward.mul(SCALE).div(lptBalance));
            }
        }
    }

    function _computeUserVotes(uint192 userData, uint192 sharedData)
    internal override pure returns (uint96 votes)
    {
        (uint96 ownCvp, uint96 pooledCvpShare) = _unpackData(userData);
        (uint96 totalPooledCvp, ) = _unpackData(sharedData);

        if (pooledCvpShare == 0) {
            votes = ownCvp;
        } else {
            uint256 pooledCvp = uint256(pooledCvpShare).mul(totalPooledCvp).div(SCALE);
            votes = ownCvp.add(SafeMath96.fromUint(pooledCvp, "VLPMining::_computeVotes"));
        }
    }

    function _computeCvpToEntitle(uint256 userLpt, uint96 userCvpAdjust, uint256 poolAccCvpPerLpt)
    private pure returns (uint96)
    {
        return userLpt == 0 ? 0 : (
            SafeMath96.fromUint(userLpt.mul(poolAccCvpPerLpt).div(SCALE), "VLPMining::computeCvp:1")
                .sub(userCvpAdjust, "VLPMining::computeCvp:2")
        );
    }

    function _computeCvpAdjustment(uint256 lptAmount, uint256 accCvpPerLpt)
    private pure returns (uint96)
    {
        return SafeMath96.fromUint(
            lptAmount.mul(accCvpPerLpt).div(SCALE),
            "VLPMining::_computeCvpAdj"
        );
    }

    function _validatePoolId(uint256 pid) private view {
        require(pid < pools.length, "VLPMining: invalid pool id");
    }

    function _currBlock() private view returns (uint32) {
        return SafeMath32.fromUint(block.number, "VLPMining::_currBlock:overflow");
    }
}