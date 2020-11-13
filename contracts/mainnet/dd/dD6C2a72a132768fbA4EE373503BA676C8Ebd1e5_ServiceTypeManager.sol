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

// File: contracts/InitializableV2.sol

pragma solidity >=0.4.24 <0.7.0;



/**
 * Wrapper around OpenZeppelin's Initializable contract.
 * Exposes initialized state management to ensure logic contract functions cannot be called before initialization.
 * This is needed because OZ's Initializable contract no longer exposes initialized state variable.
 * https://github.com/OpenZeppelin/openzeppelin-sdk/blob/v2.8.0/packages/lib/contracts/Initializable.sol
 */
contract InitializableV2 is Initializable {
    bool private isInitialized;

    string private constant ERROR_NOT_INITIALIZED = "InitializableV2: Not initialized";

    /**
     * @notice wrapper function around parent contract Initializable's `initializable` modifier
     *      initializable modifier ensures this function can only be called once by each deployed child contract
     *      sets isInitialized flag to true to which is used by _requireIsInitialized()
     */
    function initialize() public initializer {
        isInitialized = true;
    }

    /**
     * @notice Reverts transaction if isInitialized is false. Used by child contracts to ensure
     *      contract is initialized before functions can be called.
     */
    function _requireIsInitialized() internal view {
        require(isInitialized == true, ERROR_NOT_INITIALIZED);
    }

    /**
     * @notice Exposes isInitialized bool var to child contracts with read-only access
     */
    function _isInitialized() internal view returns (bool) {
        return isInitialized;
    }
}

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

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.5.0;


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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Burnable.sol

pragma solidity ^0.5.0;




/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Initializable, Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }

    uint256[50] private ______gap;
}

// File: @aragon/court/contracts/lib/Checkpointing.sol

pragma solidity ^0.5.8;


/**
* @title Checkpointing - Library to handle a historic set of numeric values
*/
library Checkpointing {
    uint256 private constant MAX_UINT192 = uint256(uint192(-1));

    string private constant ERROR_VALUE_TOO_BIG = "CHECKPOINT_VALUE_TOO_BIG";
    string private constant ERROR_CANNOT_ADD_PAST_VALUE = "CHECKPOINT_CANNOT_ADD_PAST_VALUE";

    /**
    * @dev To specify a value at a given point in time, we need to store two values:
    *      - `time`: unit-time value to denote the first time when a value was registered
    *      - `value`: a positive numeric value to registered at a given point in time
    *
    *      Note that `time` does not need to refer necessarily to a timestamp value, any time unit could be used
    *      for it like block numbers, terms, etc.
    */
    struct Checkpoint {
        uint64 time;
        uint192 value;
    }

    /**
    * @dev A history simply denotes a list of checkpoints
    */
    struct History {
        Checkpoint[] history;
    }

    /**
    * @dev Add a new value to a history for a given point in time. This function does not allow to add values previous
    *      to the latest registered value, if the value willing to add corresponds to the latest registered value, it
    *      will be updated.
    * @param self Checkpoints history to be altered
    * @param _time Point in time to register the given value
    * @param _value Numeric value to be registered at the given point in time
    */
    function add(History storage self, uint64 _time, uint256 _value) internal {
        require(_value <= MAX_UINT192, ERROR_VALUE_TOO_BIG);
        _add192(self, _time, uint192(_value));
    }

    /**
    * @dev Fetch the latest registered value of history, it will return zero if there was no value registered
    * @param self Checkpoints history to be queried
    */
    function getLast(History storage self) internal view returns (uint256) {
        uint256 length = self.history.length;
        if (length > 0) {
            return uint256(self.history[length - 1].value);
        }

        return 0;
    }

    /**
    * @dev Fetch the most recent registered past value of a history based on a given point in time that is not known
    *      how recent it is beforehand. It will return zero if there is no registered value or if given time is
    *      previous to the first registered value.
    *      It uses a binary search.
    * @param self Checkpoints history to be queried
    * @param _time Point in time to query the most recent registered past value of
    */
    function get(History storage self, uint64 _time) internal view returns (uint256) {
        return _binarySearch(self, _time);
    }

    /**
    * @dev Fetch the most recent registered past value of a history based on a given point in time. It will return zero
    *      if there is no registered value or if given time is previous to the first registered value.
    *      It uses a linear search starting from the end.
    * @param self Checkpoints history to be queried
    * @param _time Point in time to query the most recent registered past value of
    */
    function getRecent(History storage self, uint64 _time) internal view returns (uint256) {
        return _backwardsLinearSearch(self, _time);
    }

    /**
    * @dev Private function to add a new value to a history for a given point in time. This function does not allow to
    *      add values previous to the latest registered value, if the value willing to add corresponds to the latest
    *      registered value, it will be updated.
    * @param self Checkpoints history to be altered
    * @param _time Point in time to register the given value
    * @param _value Numeric value to be registered at the given point in time
    */
    function _add192(History storage self, uint64 _time, uint192 _value) private {
        uint256 length = self.history.length;
        if (length == 0 || self.history[self.history.length - 1].time < _time) {
            // If there was no value registered or the given point in time is after the latest registered value,
            // we can insert it to the history directly.
            self.history.push(Checkpoint(_time, _value));
        } else {
            // If the point in time given for the new value is not after the latest registered value, we must ensure
            // we are only trying to update the latest value, otherwise we would be changing past data.
            Checkpoint storage currentCheckpoint = self.history[length - 1];
            require(_time == currentCheckpoint.time, ERROR_CANNOT_ADD_PAST_VALUE);
            currentCheckpoint.value = _value;
        }
    }

    /**
    * @dev Private function to execute a backwards linear search to find the most recent registered past value of a
    *      history based on a given point in time. It will return zero if there is no registered value or if given time
    *      is previous to the first registered value. Note that this function will be more suitable when we already know
    *      that the time used to index the search is recent in the given history.
    * @param self Checkpoints history to be queried
    * @param _time Point in time to query the most recent registered past value of
    */
    function _backwardsLinearSearch(History storage self, uint64 _time) private view returns (uint256) {
        // If there was no value registered for the given history return simply zero
        uint256 length = self.history.length;
        if (length == 0) {
            return 0;
        }

        uint256 index = length - 1;
        Checkpoint storage checkpoint = self.history[index];
        while (index > 0 && checkpoint.time > _time) {
            index--;
            checkpoint = self.history[index];
        }

        return checkpoint.time > _time ? 0 : uint256(checkpoint.value);
    }

    /**
    * @dev Private function execute a binary search to find the most recent registered past value of a history based on
    *      a given point in time. It will return zero if there is no registered value or if given time is previous to
    *      the first registered value. Note that this function will be more suitable when don't know how recent the
    *      time used to index may be.
    * @param self Checkpoints history to be queried
    * @param _time Point in time to query the most recent registered past value of
    */
    function _binarySearch(History storage self, uint64 _time) private view returns (uint256) {
        // If there was no value registered for the given history return simply zero
        uint256 length = self.history.length;
        if (length == 0) {
            return 0;
        }

        // If the requested time is equal to or after the time of the latest registered value, return latest value
        uint256 lastIndex = length - 1;
        if (_time >= self.history[lastIndex].time) {
            return uint256(self.history[lastIndex].value);
        }

        // If the requested time is previous to the first registered value, return zero to denote missing checkpoint
        if (_time < self.history[0].time) {
            return 0;
        }

        // Execute a binary search between the checkpointed times of the history
        uint256 low = 0;
        uint256 high = lastIndex;

        while (high > low) {
            // No need for SafeMath: for this to overflow array size should be ~2^255
            uint256 mid = (high + low + 1) / 2;
            Checkpoint storage checkpoint = self.history[mid];
            uint64 midTime = checkpoint.time;

            if (_time > midTime) {
                low = mid;
            } else if (_time < midTime) {
                // No need for SafeMath: high > low >= 0 => high >= 1 => mid >= 1
                high = mid - 1;
            } else {
                return uint256(checkpoint.value);
            }
        }

        return uint256(self.history[low].value);
    }
}

// File: @aragon/court/contracts/lib/os/Uint256Helpers.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/Uint256Helpers.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


library Uint256Helpers {
    uint256 private constant MAX_UINT8 = uint8(-1);
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_UINT8_NUMBER_TOO_BIG = "UINT8_NUMBER_TOO_BIG";
    string private constant ERROR_UINT64_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint8(uint256 a) internal pure returns (uint8) {
        require(a <= MAX_UINT8, ERROR_UINT8_NUMBER_TOO_BIG);
        return uint8(a);
    }

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_UINT64_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

// File: contracts/Staking.sol

pragma solidity ^0.5.0;









contract Staking is InitializableV2 {
    using SafeMath for uint256;
    using Uint256Helpers for uint256;
    using Checkpointing for Checkpointing.History;
    using SafeERC20 for ERC20;

    string private constant ERROR_TOKEN_NOT_CONTRACT = "Staking: Staking token is not a contract";
    string private constant ERROR_AMOUNT_ZERO = "Staking: Zero amount not allowed";
    string private constant ERROR_ONLY_GOVERNANCE = "Staking: Only governance";
    string private constant ERROR_ONLY_DELEGATE_MANAGER = (
      "Staking: Only callable from DelegateManager"
    );
    string private constant ERROR_ONLY_SERVICE_PROVIDER_FACTORY = (
      "Staking: Only callable from ServiceProviderFactory"
    );

    address private governanceAddress;
    address private claimsManagerAddress;
    address private delegateManagerAddress;
    address private serviceProviderFactoryAddress;

    /// @dev stores the history of staking and claims for a given address
    struct Account {
        Checkpointing.History stakedHistory;
        Checkpointing.History claimHistory;
    }

    /// @dev ERC-20 token that will be used to stake with
    ERC20 internal stakingToken;

    /// @dev maps addresses to staking and claims history
    mapping (address => Account) internal accounts;

    /// @dev total staked tokens at a given block
    Checkpointing.History internal totalStakedHistory;

    event Staked(address indexed user, uint256 amount, uint256 total);
    event Unstaked(address indexed user, uint256 amount, uint256 total);
    event Slashed(address indexed user, uint256 amount, uint256 total);

    /**
     * @notice Function to initialize the contract
     * @dev claimsManagerAddress must be initialized separately after ClaimsManager contract is deployed
     * @dev delegateManagerAddress must be initialized separately after DelegateManager contract is deployed
     * @dev serviceProviderFactoryAddress must be initialized separately after ServiceProviderFactory contract is deployed
     * @param _tokenAddress - address of ERC20 token that will be staked
     * @param _governanceAddress - address for Governance proxy contract
     */
    function initialize(
        address _tokenAddress,
        address _governanceAddress
    ) public initializer
    {
        require(Address.isContract(_tokenAddress), ERROR_TOKEN_NOT_CONTRACT);
        stakingToken = ERC20(_tokenAddress);
        _updateGovernanceAddress(_governanceAddress);
        InitializableV2.initialize();
    }

    /**
     * @notice Set the Governance address
     * @dev Only callable by Governance address
     * @param _governanceAddress - address for new Governance contract
     */
    function setGovernanceAddress(address _governanceAddress) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        _updateGovernanceAddress(_governanceAddress);
    }

    /**
     * @notice Set the ClaimsManaager address
     * @dev Only callable by Governance address
     * @param _claimsManager - address for new ClaimsManaager contract
     */
    function setClaimsManagerAddress(address _claimsManager) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        claimsManagerAddress = _claimsManager;
    }

    /**
     * @notice Set the ServiceProviderFactory address
     * @dev Only callable by Governance address
     * @param _spFactory - address for new ServiceProviderFactory contract
     */
    function setServiceProviderFactoryAddress(address _spFactory) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        serviceProviderFactoryAddress = _spFactory;
    }

    /**
     * @notice Set the DelegateManager address
     * @dev Only callable by Governance address
     * @param _delegateManager - address for new DelegateManager contract
     */
    function setDelegateManagerAddress(address _delegateManager) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        delegateManagerAddress = _delegateManager;
    }

    /* External functions */

    /**
     * @notice Funds `_amount` of tokens from ClaimsManager to target account
     * @param _amount - amount of rewards to  add to stake
     * @param _stakerAccount - address of staker
     */
    function stakeRewards(uint256 _amount, address _stakerAccount) external {
        _requireIsInitialized();
        _requireClaimsManagerAddressIsSet();

        require(
            msg.sender == claimsManagerAddress,
            "Staking: Only callable from ClaimsManager"
        );
        _stakeFor(_stakerAccount, msg.sender, _amount);

        this.updateClaimHistory(_amount, _stakerAccount);
    }

    /**
     * @notice Update claim history by adding an event to the claim history
     * @param _amount - amount to add to claim history
     * @param _stakerAccount - address of staker
     */
    function updateClaimHistory(uint256 _amount, address _stakerAccount) external {
        _requireIsInitialized();
        _requireClaimsManagerAddressIsSet();

        require(
            msg.sender == claimsManagerAddress || msg.sender == address(this),
            "Staking: Only callable from ClaimsManager or Staking.sol"
        );

        // Update claim history even if no value claimed
        accounts[_stakerAccount].claimHistory.add(block.number.toUint64(), _amount);
    }

    /**
     * @notice Slashes `_amount` tokens from _slashAddress
     * @dev Callable from DelegateManager
     * @param _amount - Number of tokens slashed
     * @param _slashAddress - Address being slashed
     */
    function slash(
        uint256 _amount,
        address _slashAddress
    ) external
    {
        _requireIsInitialized();
        _requireDelegateManagerAddressIsSet();

        require(
            msg.sender == delegateManagerAddress,
            ERROR_ONLY_DELEGATE_MANAGER
        );

        // Burn slashed tokens from account
        _burnFor(_slashAddress, _amount);

        emit Slashed(
            _slashAddress,
            _amount,
            totalStakedFor(_slashAddress)
        );
    }

    /**
     * @notice Stakes `_amount` tokens, transferring them from _accountAddress, and assigns them to `_accountAddress`
     * @param _accountAddress - The final staker of the tokens
     * @param _amount - Number of tokens staked
     */
    function stakeFor(
        address _accountAddress,
        uint256 _amount
    ) external
    {
        _requireIsInitialized();
        _requireServiceProviderFactoryAddressIsSet();

        require(
            msg.sender == serviceProviderFactoryAddress,
            ERROR_ONLY_SERVICE_PROVIDER_FACTORY
        );
        _stakeFor(
            _accountAddress,
            _accountAddress,
            _amount
        );
    }

    /**
     * @notice Unstakes `_amount` tokens, returning them to the desired account.
     * @param _accountAddress - Account unstaked for, and token recipient
     * @param _amount - Number of tokens staked
     */
    function unstakeFor(
        address _accountAddress,
        uint256 _amount
    ) external
    {
        _requireIsInitialized();
        _requireServiceProviderFactoryAddressIsSet();

        require(
            msg.sender == serviceProviderFactoryAddress,
            ERROR_ONLY_SERVICE_PROVIDER_FACTORY
        );
        _unstakeFor(
            _accountAddress,
            _accountAddress,
            _amount
        );
    }

    /**
     * @notice Stakes `_amount` tokens, transferring them from `_delegatorAddress` to `_accountAddress`,
               only callable by DelegateManager
     * @param _accountAddress - The final staker of the tokens
     * @param _delegatorAddress - Address from which to transfer tokens
     * @param _amount - Number of tokens staked
     */
    function delegateStakeFor(
        address _accountAddress,
        address _delegatorAddress,
        uint256 _amount
    ) external {
        _requireIsInitialized();
        _requireDelegateManagerAddressIsSet();

        require(
            msg.sender == delegateManagerAddress,
            ERROR_ONLY_DELEGATE_MANAGER
        );
        _stakeFor(
            _accountAddress,
            _delegatorAddress,
            _amount);
    }

    /**
     * @notice Unstakes '_amount` tokens, transferring them from `_accountAddress` to `_delegatorAddress`,
               only callable by DelegateManager
     * @param _accountAddress - The staker of the tokens
     * @param _delegatorAddress - Address from which to transfer tokens
     * @param _amount - Number of tokens unstaked
     */
    function undelegateStakeFor(
        address _accountAddress,
        address _delegatorAddress,
        uint256 _amount
    ) external {
        _requireIsInitialized();
        _requireDelegateManagerAddressIsSet();

        require(
            msg.sender == delegateManagerAddress,
            ERROR_ONLY_DELEGATE_MANAGER
        );
        _unstakeFor(
            _accountAddress,
            _delegatorAddress,
            _amount);
    }

    /**
     * @notice Get the token used by the contract for staking and locking
     * @return The token used by the contract for staking and locking
     */
    function token() external view returns (address) {
        _requireIsInitialized();

        return address(stakingToken);
    }

    /**
     * @notice Check whether it supports history of stakes
     * @return Always true
     */
    function supportsHistory() external view returns (bool) {
        _requireIsInitialized();

        return true;
    }

    /**
     * @notice Get last time `_accountAddress` modified its staked balance
     * @param _accountAddress - Account requesting for
     * @return Last block number when account's balance was modified
     */
    function lastStakedFor(address _accountAddress) external view returns (uint256) {
        _requireIsInitialized();

        uint256 length = accounts[_accountAddress].stakedHistory.history.length;
        if (length > 0) {
            return uint256(accounts[_accountAddress].stakedHistory.history[length - 1].time);
        }
        return 0;
    }

    /**
     * @notice Get last time `_accountAddress` claimed a staking reward
     * @param _accountAddress - Account requesting for
     * @return Last block number when claim requested
     */
    function lastClaimedFor(address _accountAddress) external view returns (uint256) {
        _requireIsInitialized();

        uint256 length = accounts[_accountAddress].claimHistory.history.length;
        if (length > 0) {
            return uint256(accounts[_accountAddress].claimHistory.history[length - 1].time);
        }
        return 0;
    }

    /**
     * @notice Get the total amount of tokens staked by `_accountAddress` at block number `_blockNumber`
     * @param _accountAddress - Account requesting for
     * @param _blockNumber - Block number at which we are requesting
     * @return The amount of tokens staked by the account at the given block number
     */
    function totalStakedForAt(
        address _accountAddress,
        uint256 _blockNumber
    ) external view returns (uint256) {
        _requireIsInitialized();

        return accounts[_accountAddress].stakedHistory.get(_blockNumber.toUint64());
    }

    /**
     * @notice Get the total amount of tokens staked by all users at block number `_blockNumber`
     * @param _blockNumber - Block number at which we are requesting
     * @return The amount of tokens staked at the given block number
     */
    function totalStakedAt(uint256 _blockNumber) external view returns (uint256) {
        _requireIsInitialized();

        return totalStakedHistory.get(_blockNumber.toUint64());
    }

    /// @notice Get the Governance address
    function getGovernanceAddress() external view returns (address) {
        _requireIsInitialized();

        return governanceAddress;
    }

    /// @notice Get the ClaimsManager address
    function getClaimsManagerAddress() external view returns (address) {
        _requireIsInitialized();

        return claimsManagerAddress;
    }

    /// @notice Get the ServiceProviderFactory address
    function getServiceProviderFactoryAddress() external view returns (address) {
        _requireIsInitialized();

        return serviceProviderFactoryAddress;
    }

    /// @notice Get the DelegateManager address
    function getDelegateManagerAddress() external view returns (address) {
        _requireIsInitialized();

        return delegateManagerAddress;
    }

    /**
     * @notice Helper function wrapped around totalStakedFor. Checks whether _accountAddress
            is currently a valid staker with a non-zero stake
     * @param _accountAddress - Account requesting for
     * @return Boolean indicating whether account is a staker
     */
    function isStaker(address _accountAddress) external view returns (bool) {
        _requireIsInitialized();

        return totalStakedFor(_accountAddress) > 0;
    }

    /* Public functions */

    /**
     * @notice Get the amount of tokens staked by `_accountAddress`
     * @param _accountAddress - The owner of the tokens
     * @return The amount of tokens staked by the given account
     */
    function totalStakedFor(address _accountAddress) public view returns (uint256) {
        _requireIsInitialized();

        // we assume it's not possible to stake in the future
        return accounts[_accountAddress].stakedHistory.getLast();
    }

    /**
     * @notice Get the total amount of tokens staked by all users
     * @return The total amount of tokens staked by all users
     */
    function totalStaked() public view returns (uint256) {
        _requireIsInitialized();

        // we assume it's not possible to stake in the future
        return totalStakedHistory.getLast();
    }

    // ========================================= Internal Functions =========================================

    /**
     * @notice Adds stake from a transfer account to the stake account
     * @param _stakeAccount - Account that funds will be staked for
     * @param _transferAccount - Account that funds will be transferred from
     * @param _amount - amount to stake
     */
    function _stakeFor(
        address _stakeAccount,
        address _transferAccount,
        uint256 _amount
    ) internal
    {
        // staking 0 tokens is invalid
        require(_amount > 0, ERROR_AMOUNT_ZERO);

        // Checkpoint updated staking balance
        _modifyStakeBalance(_stakeAccount, _amount, true);

        // checkpoint total supply
        _modifyTotalStaked(_amount, true);

        // pull tokens into Staking contract
        stakingToken.safeTransferFrom(_transferAccount, address(this), _amount);

        emit Staked(
            _stakeAccount,
            _amount,
            totalStakedFor(_stakeAccount));
    }

    /**
     * @notice Unstakes tokens from a stake account to a transfer account
     * @param _stakeAccount - Account that staked funds will be transferred from
     * @param _transferAccount - Account that funds will be transferred to
     * @param _amount - amount to unstake
     */
    function _unstakeFor(
        address _stakeAccount,
        address _transferAccount,
        uint256 _amount
    ) internal
    {
        require(_amount > 0, ERROR_AMOUNT_ZERO);

        // checkpoint updated staking balance
        _modifyStakeBalance(_stakeAccount, _amount, false);

        // checkpoint total supply
        _modifyTotalStaked(_amount, false);

        // transfer tokens
        stakingToken.safeTransfer(_transferAccount, _amount);

        emit Unstaked(
            _stakeAccount,
            _amount,
            totalStakedFor(_stakeAccount)
        );
    }

    /**
     * @notice Burn tokens for a given staker
     * @dev Called when slash occurs
     * @param _stakeAccount - Account for which funds will be burned
     * @param _amount - amount to burn
     */
    function _burnFor(address _stakeAccount, uint256 _amount) internal {
        // burning zero tokens is not allowed
        require(_amount > 0, ERROR_AMOUNT_ZERO);

        // checkpoint updated staking balance
        _modifyStakeBalance(_stakeAccount, _amount, false);

        // checkpoint total supply
        _modifyTotalStaked(_amount, false);

        // burn
        ERC20Burnable(address(stakingToken)).burn(_amount);

        /** No event emitted since token.burn() call already emits a Transfer event */
    }

    /**
     * @notice Increase or decrease the staked balance for an account
     * @param _accountAddress - Account to modify
     * @param _by - amount to modify
     * @param _increase - true if increase in stake, false if decrease
     */
    function _modifyStakeBalance(address _accountAddress, uint256 _by, bool _increase) internal {
        uint256 currentInternalStake = accounts[_accountAddress].stakedHistory.getLast();

        uint256 newStake;
        if (_increase) {
            newStake = currentInternalStake.add(_by);
        } else {
            require(
                currentInternalStake >= _by,
                "Staking: Cannot decrease greater than current balance");
            newStake = currentInternalStake.sub(_by);
        }

        // add new value to account history
        accounts[_accountAddress].stakedHistory.add(block.number.toUint64(), newStake);
    }

    /**
     * @notice Increase or decrease the staked balance across all accounts
     * @param _by - amount to modify
     * @param _increase - true if increase in stake, false if decrease
     */
    function _modifyTotalStaked(uint256 _by, bool _increase) internal {
        uint256 currentStake = totalStaked();

        uint256 newStake;
        if (_increase) {
            newStake = currentStake.add(_by);
        } else {
            newStake = currentStake.sub(_by);
        }

        // add new value to total history
        totalStakedHistory.add(block.number.toUint64(), newStake);
    }

    /**
     * @notice Set the governance address after confirming contract identity
     * @param _governanceAddress - Incoming governance address
     */
    function _updateGovernanceAddress(address _governanceAddress) internal {
        require(
            Governance(_governanceAddress).isGovernanceAddress() == true,
            "Staking: _governanceAddress is not a valid governance contract"
        );
        governanceAddress = _governanceAddress;
    }

    // ========================================= Private Functions =========================================

    function _requireClaimsManagerAddressIsSet() private view {
        require(claimsManagerAddress != address(0x00), "Staking: claimsManagerAddress is not set");
    }

    function _requireDelegateManagerAddressIsSet() private view {
        require(
            delegateManagerAddress != address(0x00),
            "Staking: delegateManagerAddress is not set"
        );
    }

    function _requireServiceProviderFactoryAddressIsSet() private view {
        require(
            serviceProviderFactoryAddress != address(0x00),
            "Staking: serviceProviderFactoryAddress is not set"
        );
    }

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

// File: @openzeppelin/contracts-ethereum-package/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;




contract MinterRole is Initializable, Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    function initialize(address sender) public initializer {
        if (!isMinter(sender)) {
            _addMinter(sender);
        }
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Mintable.sol

pragma solidity ^0.5.0;




/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is Initializable, ERC20, MinterRole {
    function initialize(address sender) public initializer {
        MinterRole.initialize(sender);
    }

    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

    uint256[50] private ______gap;
}

// File: contracts/ClaimsManager.sol

pragma solidity ^0.5.0;

/// @notice ERC20 imported via Staking.sol
/// @notice SafeERC20 imported via Staking.sol
/// @notice Governance imported via Staking.sol
/// @notice SafeMath imported via ServiceProviderFactory.sol


/**
 * Designed to automate claim funding, minting tokens as necessary
 * @notice - will call InitializableV2 constructor
 */
contract ClaimsManager is InitializableV2 {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    string private constant ERROR_ONLY_GOVERNANCE = (
        "ClaimsManager: Only callable by Governance contract"
    );

    address private governanceAddress;
    address private stakingAddress;
    address private serviceProviderFactoryAddress;
    address private delegateManagerAddress;

    /**
      * @notice - Minimum number of blocks between funding rounds
      *       604800 seconds / week
      *       Avg block time - 13s
      *       604800 / 13 = 46523.0769231 blocks
      */
    uint256 private fundingRoundBlockDiff;

    /**
      * @notice - Configures the current funding amount per round
      *  Weekly rounds, 7% PA inflation = 70,000,000 new tokens in first year
      *                                 = 70,000,000/365*7 (year is slightly more than a week)
      *                                 = 1342465.75342 new AUDS per week
      *                                 = 1342465753420000000000000 new wei units per week
      * @dev - Past a certain block height, this schedule will be updated
      *      - Logic determining schedule will be sourced from an external contract
      */
    uint256 private fundingAmount;

    // Denotes current round
    uint256 private roundNumber;

    // Staking contract ref
    ERC20Mintable private audiusToken;

    /// @dev - Address to which recurringCommunityFundingAmount is transferred at funding round start
    address private communityPoolAddress;

    /// @dev - Reward amount transferred to communityPoolAddress at funding round start
    uint256 private recurringCommunityFundingAmount;

    // Struct representing round state
    // 1) Block at which round was funded
    // 2) Total funded for this round
    // 3) Total claimed in round
    struct Round {
        uint256 fundedBlock;
        uint256 fundedAmount;
        uint256 totalClaimedInRound;
    }

    // Current round information
    Round private currentRound;

    event RoundInitiated(
      uint256 indexed _blockNumber,
      uint256 indexed _roundNumber,
      uint256 indexed _fundAmount
    );

    event ClaimProcessed(
      address indexed _claimer,
      uint256 indexed _rewards,
      uint256 _oldTotal,
      uint256 indexed _newTotal
    );

    event CommunityRewardsTransferred(
      address indexed _transferAddress,
      uint256 indexed _amount
    );

    event FundingAmountUpdated(uint256 indexed _amount);
    event FundingRoundBlockDiffUpdated(uint256 indexed _blockDifference);
    event GovernanceAddressUpdated(address indexed _newGovernanceAddress);
    event StakingAddressUpdated(address indexed _newStakingAddress);
    event ServiceProviderFactoryAddressUpdated(address indexed _newServiceProviderFactoryAddress);
    event DelegateManagerAddressUpdated(address indexed _newDelegateManagerAddress);
    event RecurringCommunityFundingAmountUpdated(uint256 indexed _amount);
    event CommunityPoolAddressUpdated(address indexed _newCommunityPoolAddress);

    /**
     * @notice Function to initialize the contract
     * @dev stakingAddress must be initialized separately after Staking contract is deployed
     * @dev serviceProviderFactoryAddress must be initialized separately after ServiceProviderFactory contract is deployed
     * @dev delegateManagerAddress must be initialized separately after DelegateManager contract is deployed
     * @param _tokenAddress - address of ERC20 token that will be claimed
     * @param _governanceAddress - address for Governance proxy contract
     */
    function initialize(
        address _tokenAddress,
        address _governanceAddress
    ) public initializer
    {
        _updateGovernanceAddress(_governanceAddress);

        audiusToken = ERC20Mintable(_tokenAddress);

        fundingRoundBlockDiff = 46523;
        fundingAmount = 1342465753420000000000000; // 1342465.75342 AUDS
        roundNumber = 0;

        currentRound = Round({
            fundedBlock: 0,
            fundedAmount: 0,
            totalClaimedInRound: 0
        });

        // Community pool funding amount and address initialized to zero
        recurringCommunityFundingAmount = 0;
        communityPoolAddress = address(0x0);

        InitializableV2.initialize();
    }

    /// @notice Get the duration of a funding round in blocks
    function getFundingRoundBlockDiff() external view returns (uint256)
    {
        _requireIsInitialized();

        return fundingRoundBlockDiff;
    }

    /// @notice Get the last block where a funding round was initiated
    function getLastFundedBlock() external view returns (uint256)
    {
        _requireIsInitialized();

        return currentRound.fundedBlock;
    }

    /// @notice Get the amount funded per round in wei
    function getFundsPerRound() external view returns (uint256)
    {
        _requireIsInitialized();

        return fundingAmount;
    }

    /// @notice Get the total amount claimed in the current round
    function getTotalClaimedInRound() external view returns (uint256)
    {
        _requireIsInitialized();

        return currentRound.totalClaimedInRound;
    }

    /// @notice Get the Governance address
    function getGovernanceAddress() external view returns (address) {
        _requireIsInitialized();

        return governanceAddress;
    }

    /// @notice Get the ServiceProviderFactory address
    function getServiceProviderFactoryAddress() external view returns (address) {
        _requireIsInitialized();

        return serviceProviderFactoryAddress;
    }

    /// @notice Get the DelegateManager address
    function getDelegateManagerAddress() external view returns (address) {
        _requireIsInitialized();

        return delegateManagerAddress;
    }

    /**
     * @notice Get the Staking address
     */
    function getStakingAddress() external view returns (address)
    {
        _requireIsInitialized();

        return stakingAddress;
    }

    /**
     * @notice Get the community pool address
     */
    function getCommunityPoolAddress() external view returns (address)
    {
        _requireIsInitialized();

        return communityPoolAddress;
    }

    /**
     * @notice Get the community funding amount
     */
    function getRecurringCommunityFundingAmount() external view returns (uint256)
    {
        _requireIsInitialized();

        return recurringCommunityFundingAmount;
    }

    /**
     * @notice Set the Governance address
     * @dev Only callable by Governance address
     * @param _governanceAddress - address for new Governance contract
     */
    function setGovernanceAddress(address _governanceAddress) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        _updateGovernanceAddress(_governanceAddress);
        emit GovernanceAddressUpdated(_governanceAddress);
    }

    /**
     * @notice Set the Staking address
     * @dev Only callable by Governance address
     * @param _stakingAddress - address for new Staking contract
     */
    function setStakingAddress(address _stakingAddress) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        stakingAddress = _stakingAddress;
        emit StakingAddressUpdated(_stakingAddress);
    }

    /**
     * @notice Set the ServiceProviderFactory address
     * @dev Only callable by Governance address
     * @param _serviceProviderFactoryAddress - address for new ServiceProviderFactory contract
     */
    function setServiceProviderFactoryAddress(address _serviceProviderFactoryAddress) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        serviceProviderFactoryAddress = _serviceProviderFactoryAddress;
        emit ServiceProviderFactoryAddressUpdated(_serviceProviderFactoryAddress);
    }

    /**
     * @notice Set the DelegateManager address
     * @dev Only callable by Governance address
     * @param _delegateManagerAddress - address for new DelegateManager contract
     */
    function setDelegateManagerAddress(address _delegateManagerAddress) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        delegateManagerAddress = _delegateManagerAddress;
        emit DelegateManagerAddressUpdated(_delegateManagerAddress);
    }

    /**
     * @notice Start a new funding round
     * @dev Permissioned to be callable by stakers or governance contract
     */
    function initiateRound() external {
        _requireIsInitialized();
        _requireStakingAddressIsSet();

        require(
            block.number.sub(currentRound.fundedBlock) > fundingRoundBlockDiff,
            "ClaimsManager: Required block difference not met"
        );

        currentRound = Round({
            fundedBlock: block.number,
            fundedAmount: fundingAmount,
            totalClaimedInRound: 0
        });

        roundNumber = roundNumber.add(1);

        /*
         * Transfer community funding amount to community pool address, if set
         */
        if (recurringCommunityFundingAmount > 0 && communityPoolAddress != address(0x0)) {
            // ERC20Mintable always returns true
            audiusToken.mint(address(this), recurringCommunityFundingAmount);

            // Approve transfer to community pool address
            audiusToken.approve(communityPoolAddress, recurringCommunityFundingAmount);

            // Transfer to community pool address
            ERC20(address(audiusToken)).safeTransfer(communityPoolAddress, recurringCommunityFundingAmount);

            emit CommunityRewardsTransferred(communityPoolAddress, recurringCommunityFundingAmount);
        }

        emit RoundInitiated(
            currentRound.fundedBlock,
            roundNumber,
            currentRound.fundedAmount
        );
    }

    /**
     * @notice Mints and stakes tokens on behalf of ServiceProvider + delegators
     * @dev Callable through DelegateManager by Service Provider
     * @param _claimer  - service provider address
     * @param _totalLockedForSP - amount of tokens locked up across DelegateManager + ServiceProvider
     * @return minted rewards for this claimer
     */
    function processClaim(
        address _claimer,
        uint256 _totalLockedForSP
    ) external returns (uint256)
    {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireDelegateManagerAddressIsSet();
        _requireServiceProviderFactoryAddressIsSet();

        require(
            msg.sender == delegateManagerAddress,
            "ClaimsManager: ProcessClaim only accessible to DelegateManager"
        );

        Staking stakingContract = Staking(stakingAddress);
        // Prevent duplicate claim
        uint256 lastUserClaimBlock = stakingContract.lastClaimedFor(_claimer);
        require(
            lastUserClaimBlock <= currentRound.fundedBlock,
            "ClaimsManager: Claim already processed for user"
        );
        uint256 totalStakedAtFundBlockForClaimer = stakingContract.totalStakedForAt(
            _claimer,
            currentRound.fundedBlock);

        (,,bool withinBounds,,,) = (
            ServiceProviderFactory(serviceProviderFactoryAddress).getServiceProviderDetails(_claimer)
        );

        // Once they claim the zero reward amount, stake can be modified once again
        // Subtract total locked amount for SP from stake at fund block
        uint256 totalActiveClaimerStake = totalStakedAtFundBlockForClaimer.sub(_totalLockedForSP);
        uint256 totalStakedAtFundBlock = stakingContract.totalStakedAt(currentRound.fundedBlock);

        // Calculate claimer rewards
        uint256 rewardsForClaimer = (
          totalActiveClaimerStake.mul(fundingAmount)
        ).div(totalStakedAtFundBlock);

        // For a claimer violating bounds, no new tokens are minted
        // Claim history is marked to zero and function is short-circuited
        // Total rewards can be zero if all stake is currently locked up
        if (!withinBounds || rewardsForClaimer == 0) {
            stakingContract.updateClaimHistory(0, _claimer);
            emit ClaimProcessed(
                _claimer,
                0,
                totalStakedAtFundBlockForClaimer,
                totalActiveClaimerStake
            );
            return 0;
        }

        // ERC20Mintable always returns true
        audiusToken.mint(address(this), rewardsForClaimer);

        // Approve transfer to staking address for claimer rewards
        // ERC20 always returns true
        audiusToken.approve(stakingAddress, rewardsForClaimer);

        // Transfer rewards
        stakingContract.stakeRewards(rewardsForClaimer, _claimer);

        // Update round claim value
        currentRound.totalClaimedInRound = currentRound.totalClaimedInRound.add(rewardsForClaimer);

        // Update round claim value
        uint256 newTotal = stakingContract.totalStakedFor(_claimer);

        emit ClaimProcessed(
            _claimer,
            rewardsForClaimer,
            totalStakedAtFundBlockForClaimer,
            newTotal
        );

        return rewardsForClaimer;
    }

    /**
     * @notice Modify funding amount per round
     * @param _newAmount - new amount to fund per round in wei
     */
    function updateFundingAmount(uint256 _newAmount) external
    {
        _requireIsInitialized();
        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        fundingAmount = _newAmount;
        emit FundingAmountUpdated(_newAmount);
    }

    /**
     * @notice Returns boolean indicating whether a claim is considered pending
     * @dev Note that an address with no endpoints can never have a pending claim
     * @param _sp - address of the service provider to check
     * @return true if eligible for claim, false if not
     */
    function claimPending(address _sp) external view returns (bool) {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireServiceProviderFactoryAddressIsSet();

        uint256 lastClaimedForSP = Staking(stakingAddress).lastClaimedFor(_sp);
        (,,,uint256 numEndpoints,,) = (
            ServiceProviderFactory(serviceProviderFactoryAddress).getServiceProviderDetails(_sp)
        );
        return (lastClaimedForSP < currentRound.fundedBlock && numEndpoints > 0);
    }

    /**
     * @notice Modify minimum block difference between funding rounds
     * @param _newFundingRoundBlockDiff - new min block difference to set
     */
    function updateFundingRoundBlockDiff(uint256 _newFundingRoundBlockDiff) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        emit FundingRoundBlockDiffUpdated(_newFundingRoundBlockDiff);
        fundingRoundBlockDiff = _newFundingRoundBlockDiff;
    }

    /**
     * @notice Modify community funding amound for each round
     * @param _newRecurringCommunityFundingAmount - new reward amount transferred to
     *          communityPoolAddress at funding round start
     */
    function updateRecurringCommunityFundingAmount(
        uint256 _newRecurringCommunityFundingAmount
    ) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        recurringCommunityFundingAmount = _newRecurringCommunityFundingAmount;
        emit RecurringCommunityFundingAmountUpdated(_newRecurringCommunityFundingAmount);
    }

    /**
     * @notice Modify community pool address
     * @param _newCommunityPoolAddress - new address to which recurringCommunityFundingAmount
     *          is transferred at funding round start
     */
    function updateCommunityPoolAddress(address _newCommunityPoolAddress) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        communityPoolAddress = _newCommunityPoolAddress;
        emit CommunityPoolAddressUpdated(_newCommunityPoolAddress);
    }

    // ========================================= Private Functions =========================================

    /**
     * @notice Set the governance address after confirming contract identity
     * @param _governanceAddress - Incoming governance address
     */
    function _updateGovernanceAddress(address _governanceAddress) private {
        require(
            Governance(_governanceAddress).isGovernanceAddress() == true,
            "ClaimsManager: _governanceAddress is not a valid governance contract"
        );
        governanceAddress = _governanceAddress;
    }

    function _requireStakingAddressIsSet() private view {
        require(stakingAddress != address(0x00), "ClaimsManager: stakingAddress is not set");
    }

    function _requireDelegateManagerAddressIsSet() private view {
        require(
            delegateManagerAddress != address(0x00),
            "ClaimsManager: delegateManagerAddress is not set"
        );
    }

    function _requireServiceProviderFactoryAddressIsSet() private view {
        require(
            serviceProviderFactoryAddress != address(0x00),
            "ClaimsManager: serviceProviderFactoryAddress is not set"
        );
    }
}

// File: contracts/ServiceProviderFactory.sol

pragma solidity ^0.5.0;


/// @notice Governance imported via Staking.sol


contract ServiceProviderFactory is InitializableV2 {
    using SafeMath for uint256;

    /// @dev - denominator for deployer cut calculations
    /// @dev - user values are intended to be x/DEPLOYER_CUT_BASE
    uint256 private constant DEPLOYER_CUT_BASE = 100;

    string private constant ERROR_ONLY_GOVERNANCE = (
        "ServiceProviderFactory: Only callable by Governance contract"
    );
    string private constant ERROR_ONLY_SP_GOVERNANCE = (
        "ServiceProviderFactory: Only callable by Service Provider or Governance"
    );

    address private stakingAddress;
    address private delegateManagerAddress;
    address private governanceAddress;
    address private serviceTypeManagerAddress;
    address private claimsManagerAddress;

    /// @notice Period in blocks that a decrease stake operation is delayed.
    ///         Must be greater than governance votingPeriod + executionDelay in order to
    ///         prevent pre-emptive withdrawal in anticipation of a slash proposal
    uint256 private decreaseStakeLockupDuration;

    /// @notice Period in blocks that an update deployer cut operation is delayed.
    ///         Must be greater than funding round block diff in order
    ///         to prevent manipulation around a funding round
    uint256 private deployerCutLockupDuration;

    /// @dev - Stores following entities
    ///        1) Directly staked amount by SP, not including delegators
    ///        2) % Cut of delegator tokens taken during reward
    ///        3) Bool indicating whether this SP has met min/max requirements
    ///        4) Number of endpoints registered by SP
    ///        5) Minimum deployer stake for this service provider
    ///        6) Maximum total stake for this account
    struct ServiceProviderDetails {
        uint256 deployerStake;
        uint256 deployerCut;
        bool validBounds;
        uint256 numberOfEndpoints;
        uint256 minAccountStake;
        uint256 maxAccountStake;
    }

    /// @dev - Data structure for time delay during withdrawal
    struct DecreaseStakeRequest {
        uint256 decreaseAmount;
        uint256 lockupExpiryBlock;
    }

    /// @dev - Data structure for time delay during deployer cut update
    struct UpdateDeployerCutRequest {
        uint256 newDeployerCut;
        uint256 lockupExpiryBlock;
    }

    /// @dev - Struct maintaining information about sp
    /// @dev - blocknumber is block.number when endpoint registered
    struct ServiceEndpoint {
        address owner;
        string endpoint;
        uint256 blocknumber;
        address delegateOwnerWallet;
    }

    /// @dev - Mapping of service provider address to details
    mapping(address => ServiceProviderDetails) private spDetails;

    /// @dev - Uniquely assigned serviceProvider ID, incremented for each service type
    /// @notice - Keeps track of the total number of services registered regardless of
    ///           whether some have been deregistered since
    mapping(bytes32 => uint256) private serviceProviderTypeIDs;

    /// @dev - mapping of (serviceType -> (serviceInstanceId <-> serviceProviderInfo))
    /// @notice - stores the actual service provider data like endpoint and owner wallet
    ///           with the ability lookup by service type and service id */
    mapping(bytes32 => mapping(uint256 => ServiceEndpoint)) private serviceProviderInfo;

    /// @dev - mapping of keccak256(endpoint) to uint256 ID
    /// @notice - used to check if a endpoint has already been registered and also lookup
    /// the id of an endpoint
    mapping(bytes32 => uint256) private serviceProviderEndpointToId;

    /// @dev - mapping of address -> sp id array */
    /// @notice - stores all the services registered by a provider. for each address,
    /// provides the ability to lookup by service type and see all registered services
    mapping(address => mapping(bytes32 => uint256[])) private serviceProviderAddressToId;

    /// @dev - Mapping of service provider -> decrease stake request
    mapping(address => DecreaseStakeRequest) private decreaseStakeRequests;

    /// @dev - Mapping of service provider -> update deployer cut requests
    mapping(address => UpdateDeployerCutRequest) private updateDeployerCutRequests;

    event RegisteredServiceProvider(
      uint256 indexed _spID,
      bytes32 indexed _serviceType,
      address indexed _owner,
      string _endpoint,
      uint256 _stakeAmount
    );

    event DeregisteredServiceProvider(
      uint256 indexed _spID,
      bytes32 indexed _serviceType,
      address indexed _owner,
      string _endpoint,
      uint256 _unstakeAmount
    );

    event IncreasedStake(
      address indexed _owner,
      uint256 indexed _increaseAmount,
      uint256 indexed _newStakeAmount
    );

    event DecreaseStakeRequested(
      address indexed _owner,
      uint256 indexed _decreaseAmount,
      uint256 indexed _lockupExpiryBlock
    );

    event DecreaseStakeRequestCancelled(
      address indexed _owner,
      uint256 indexed _decreaseAmount,
      uint256 indexed _lockupExpiryBlock
    );

    event DecreaseStakeRequestEvaluated(
      address indexed _owner,
      uint256 indexed _decreaseAmount,
      uint256 indexed _newStakeAmount
    );

    event EndpointUpdated(
      bytes32 indexed _serviceType,
      address indexed _owner,
      string _oldEndpoint,
      string _newEndpoint,
      uint256 indexed _spID
    );

    event DelegateOwnerWalletUpdated(
      address indexed _owner,
      bytes32 indexed _serviceType,
      uint256 indexed _spID,
      address _updatedWallet
    );

    event DeployerCutUpdateRequested(
      address indexed _owner,
      uint256 indexed _updatedCut,
      uint256 indexed _lockupExpiryBlock
    );

    event DeployerCutUpdateRequestCancelled(
      address indexed _owner,
      uint256 indexed _requestedCut,
      uint256 indexed _finalCut
    );

    event DeployerCutUpdateRequestEvaluated(
      address indexed _owner,
      uint256 indexed _updatedCut
    );

    event DecreaseStakeLockupDurationUpdated(uint256 indexed _lockupDuration);
    event UpdateDeployerCutLockupDurationUpdated(uint256 indexed _lockupDuration);
    event GovernanceAddressUpdated(address indexed _newGovernanceAddress);
    event StakingAddressUpdated(address indexed _newStakingAddress);
    event ClaimsManagerAddressUpdated(address indexed _newClaimsManagerAddress);
    event DelegateManagerAddressUpdated(address indexed _newDelegateManagerAddress);
    event ServiceTypeManagerAddressUpdated(address indexed _newServiceTypeManagerAddress);

    /**
     * @notice Function to initialize the contract
     * @dev stakingAddress must be initialized separately after Staking contract is deployed
     * @dev delegateManagerAddress must be initialized separately after DelegateManager contract is deployed
     * @dev serviceTypeManagerAddress must be initialized separately after ServiceTypeManager contract is deployed
     * @dev claimsManagerAddress must be initialized separately after ClaimsManager contract is deployed
     * @param _governanceAddress - Governance proxy address
     */
    function initialize (
        address _governanceAddress,
        address _claimsManagerAddress,
        uint256 _decreaseStakeLockupDuration,
        uint256 _deployerCutLockupDuration
    ) public initializer
    {
        _updateGovernanceAddress(_governanceAddress);
        claimsManagerAddress = _claimsManagerAddress;
        _updateDecreaseStakeLockupDuration(_decreaseStakeLockupDuration);
        _updateDeployerCutLockupDuration(_deployerCutLockupDuration);
        InitializableV2.initialize();
    }

    /**
     * @notice Register a new endpoint to the account of msg.sender
     * @dev Transfers stake from service provider into staking pool
     * @param _serviceType - type of service to register, must be valid in ServiceTypeManager
     * @param _endpoint - url of the service to register - url of the service to register
     * @param _stakeAmount - amount to stake, must be within bounds in ServiceTypeManager
     * @param _delegateOwnerWallet - wallet to delegate some permissions for some basic management properties
     * @return New service provider ID for this endpoint
     */
    function register(
        bytes32 _serviceType,
        string calldata _endpoint,
        uint256 _stakeAmount,
        address _delegateOwnerWallet
    ) external returns (uint256)
    {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireServiceTypeManagerAddressIsSet();
        _requireClaimsManagerAddressIsSet();

        require(
            ServiceTypeManager(serviceTypeManagerAddress).serviceTypeIsValid(_serviceType),
            "ServiceProviderFactory: Valid service type required");

        // Stake token amount from msg.sender
        if (_stakeAmount > 0) {
            require(
                !_claimPending(msg.sender),
                "ServiceProviderFactory: No pending claim expected"
            );
            Staking(stakingAddress).stakeFor(msg.sender, _stakeAmount);
        }

        require (
            serviceProviderEndpointToId[keccak256(bytes(_endpoint))] == 0,
            "ServiceProviderFactory: Endpoint already registered");

        uint256 newServiceProviderID = serviceProviderTypeIDs[_serviceType].add(1);
        serviceProviderTypeIDs[_serviceType] = newServiceProviderID;

        // Index spInfo
        serviceProviderInfo[_serviceType][newServiceProviderID] = ServiceEndpoint({
            owner: msg.sender,
            endpoint: _endpoint,
            blocknumber: block.number,
            delegateOwnerWallet: _delegateOwnerWallet
        });

        // Update endpoint mapping
        serviceProviderEndpointToId[keccak256(bytes(_endpoint))] = newServiceProviderID;

        // Update (address -> type -> ids[])
        serviceProviderAddressToId[msg.sender][_serviceType].push(newServiceProviderID);

        // Increment number of endpoints for this address
        spDetails[msg.sender].numberOfEndpoints = spDetails[msg.sender].numberOfEndpoints.add(1);

        // Update deployer total
        spDetails[msg.sender].deployerStake = (
            spDetails[msg.sender].deployerStake.add(_stakeAmount)
        );

        // Update min and max totals for this service provider
        (, uint256 typeMin, uint256 typeMax) = ServiceTypeManager(
            serviceTypeManagerAddress
        ).getServiceTypeInfo(_serviceType);
        spDetails[msg.sender].minAccountStake = spDetails[msg.sender].minAccountStake.add(typeMin);
        spDetails[msg.sender].maxAccountStake = spDetails[msg.sender].maxAccountStake.add(typeMax);

        // Confirm both aggregate account balance and directly staked amount are valid
        this.validateAccountStakeBalance(msg.sender);
        uint256 currentlyStakedForOwner = Staking(stakingAddress).totalStakedFor(msg.sender);


        // Indicate this service provider is within bounds
        spDetails[msg.sender].validBounds = true;

        emit RegisteredServiceProvider(
            newServiceProviderID,
            _serviceType,
            msg.sender,
            _endpoint,
            currentlyStakedForOwner
        );

        return newServiceProviderID;
    }

    /**
     * @notice Deregister an endpoint from the account of msg.sender
     * @dev Unstakes all tokens for service provider if this is the last endpoint
     * @param _serviceType - type of service to deregister
     * @param _endpoint - endpoint to deregister
     * @return spId of the service that was deregistered
     */
    function deregister(
        bytes32 _serviceType,
        string calldata _endpoint
    ) external returns (uint256)
    {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireServiceTypeManagerAddressIsSet();

        // Unstake on deregistration if and only if this is the last service endpoint
        uint256 unstakeAmount = 0;
        bool unstaked = false;
        // owned by the service provider
        if (spDetails[msg.sender].numberOfEndpoints == 1) {
            unstakeAmount = spDetails[msg.sender].deployerStake;

            // Submit request to decrease stake, overriding any pending request
            decreaseStakeRequests[msg.sender] = DecreaseStakeRequest({
                decreaseAmount: unstakeAmount,
                lockupExpiryBlock: block.number.add(decreaseStakeLockupDuration)
            });

            unstaked = true;
        }

        require (
            serviceProviderEndpointToId[keccak256(bytes(_endpoint))] != 0,
            "ServiceProviderFactory: Endpoint not registered");

        // Cache invalided service provider ID
        uint256 deregisteredID = serviceProviderEndpointToId[keccak256(bytes(_endpoint))];

        // Update endpoint mapping
        serviceProviderEndpointToId[keccak256(bytes(_endpoint))] = 0;

        require(
            keccak256(bytes(serviceProviderInfo[_serviceType][deregisteredID].endpoint)) == keccak256(bytes(_endpoint)),
            "ServiceProviderFactory: Invalid endpoint for service type");

        require (
            serviceProviderInfo[_serviceType][deregisteredID].owner == msg.sender,
            "ServiceProviderFactory: Only callable by endpoint owner");

        // Update info mapping
        delete serviceProviderInfo[_serviceType][deregisteredID];
        // Reset id, update array
        uint256 spTypeLength = serviceProviderAddressToId[msg.sender][_serviceType].length;
        for (uint256 i = 0; i < spTypeLength; i ++) {
            if (serviceProviderAddressToId[msg.sender][_serviceType][i] == deregisteredID) {
                // Overwrite element to be deleted with last element in array
                serviceProviderAddressToId[msg.sender][_serviceType][i] = serviceProviderAddressToId[msg.sender][_serviceType][spTypeLength - 1];
                // Reduce array size, exit loop
                serviceProviderAddressToId[msg.sender][_serviceType].length--;
                // Confirm this ID has been found for the service provider
                break;
            }
        }

        // Decrement number of endpoints for this address
        spDetails[msg.sender].numberOfEndpoints -= 1;

        // Update min and max totals for this service provider
        (, uint256 typeMin, uint256 typeMax) = ServiceTypeManager(
            serviceTypeManagerAddress
        ).getServiceTypeInfo(_serviceType);
        spDetails[msg.sender].minAccountStake = spDetails[msg.sender].minAccountStake.sub(typeMin);
        spDetails[msg.sender].maxAccountStake = spDetails[msg.sender].maxAccountStake.sub(typeMax);

        emit DeregisteredServiceProvider(
            deregisteredID,
            _serviceType,
            msg.sender,
            _endpoint,
            unstakeAmount);

        // Confirm both aggregate account balance and directly staked amount are valid
        // Only if unstake operation has not occurred
        if (!unstaked) {
            this.validateAccountStakeBalance(msg.sender);
            // Indicate this service provider is within bounds
            spDetails[msg.sender].validBounds = true;
        }

        return deregisteredID;
    }

    /**
     * @notice Increase stake for service provider
     * @param _increaseStakeAmount - amount to increase staked amount by
     * @return New total stake for service provider
     */
    function increaseStake(
        uint256 _increaseStakeAmount
    ) external returns (uint256)
    {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireClaimsManagerAddressIsSet();

        // Confirm owner has an endpoint
        require(
            spDetails[msg.sender].numberOfEndpoints > 0,
            "ServiceProviderFactory: Registered endpoint required to increase stake"
        );
        require(
            !_claimPending(msg.sender),
            "ServiceProviderFactory: No claim expected to be pending prior to stake transfer"
        );

        Staking stakingContract = Staking(
            stakingAddress
        );

        // Stake increased token amount for msg.sender
        stakingContract.stakeFor(msg.sender, _increaseStakeAmount);

        uint256 newStakeAmount = stakingContract.totalStakedFor(msg.sender);

        // Update deployer total
        spDetails[msg.sender].deployerStake = (
            spDetails[msg.sender].deployerStake.add(_increaseStakeAmount)
        );

        // Confirm both aggregate account balance and directly staked amount are valid
        this.validateAccountStakeBalance(msg.sender);

        // Indicate this service provider is within bounds
        spDetails[msg.sender].validBounds = true;

        emit IncreasedStake(
            msg.sender,
            _increaseStakeAmount,
            newStakeAmount
        );

        return newStakeAmount;
    }

    /**
     * @notice Request to decrease stake. This sets a lockup for decreaseStakeLockupDuration after
               which the actual decreaseStake can be called
     * @dev Decreasing stake is only processed if a service provider is within valid bounds
     * @param _decreaseStakeAmount - amount to decrease stake by in wei
     * @return New total stake amount after the lockup
     */
    function requestDecreaseStake(uint256 _decreaseStakeAmount)
    external returns (uint256)
    {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireClaimsManagerAddressIsSet();

        require(
            _decreaseStakeAmount > 0,
            "ServiceProviderFactory: Requested stake decrease amount must be greater than zero"
        );
        require(
            !_claimPending(msg.sender),
            "ServiceProviderFactory: No claim expected to be pending prior to stake transfer"
        );

        Staking stakingContract = Staking(
            stakingAddress
        );

        uint256 currentStakeAmount = stakingContract.totalStakedFor(msg.sender);

        // Prohibit decreasing stake to invalid bounds
        _validateBalanceInternal(msg.sender, (currentStakeAmount.sub(_decreaseStakeAmount)));

        uint256 expiryBlock = block.number.add(decreaseStakeLockupDuration);
        decreaseStakeRequests[msg.sender] = DecreaseStakeRequest({
            decreaseAmount: _decreaseStakeAmount,
            lockupExpiryBlock: expiryBlock
        });

        emit DecreaseStakeRequested(msg.sender, _decreaseStakeAmount, expiryBlock);
        return currentStakeAmount.sub(_decreaseStakeAmount);
    }

    /**
     * @notice Cancel a decrease stake request during the lockup
     * @dev Either called by the service provider via DelegateManager or governance
            during a slash action
     * @param _account - address of service provider
     */
    function cancelDecreaseStakeRequest(address _account) external
    {
        _requireIsInitialized();
        _requireDelegateManagerAddressIsSet();

        require(
            msg.sender == _account || msg.sender == delegateManagerAddress,
            "ServiceProviderFactory: Only owner or DelegateManager"
        );
        require(
            _decreaseRequestIsPending(_account),
            "ServiceProviderFactory: Decrease stake request must be pending"
        );

        DecreaseStakeRequest memory cancelledRequest = decreaseStakeRequests[_account];

        // Clear decrease stake request
        decreaseStakeRequests[_account] = DecreaseStakeRequest({
            decreaseAmount: 0,
            lockupExpiryBlock: 0
        });

        emit DecreaseStakeRequestCancelled(
            _account,
            cancelledRequest.decreaseAmount,
            cancelledRequest.lockupExpiryBlock
        );
    }

    /**
     * @notice Called by user to decrease a stake after waiting the appropriate lockup period.
     * @return New total stake after decrease
     */
    function decreaseStake() external returns (uint256)
    {
        _requireIsInitialized();
        _requireStakingAddressIsSet();

        require(
            _decreaseRequestIsPending(msg.sender),
            "ServiceProviderFactory: Decrease stake request must be pending"
        );
        require(
            decreaseStakeRequests[msg.sender].lockupExpiryBlock <= block.number,
            "ServiceProviderFactory: Lockup must be expired"
        );

        Staking stakingContract = Staking(
            stakingAddress
        );

        uint256 decreaseAmount = decreaseStakeRequests[msg.sender].decreaseAmount;
        // Decrease staked token amount for msg.sender
        stakingContract.unstakeFor(msg.sender, decreaseAmount);

        // Query current stake
        uint256 newStakeAmount = stakingContract.totalStakedFor(msg.sender);

        // Update deployer total
        spDetails[msg.sender].deployerStake = (
            spDetails[msg.sender].deployerStake.sub(decreaseAmount)
        );

        // Confirm both aggregate account balance and directly staked amount are valid
        // During registration this validation is bypassed since no endpoints remain
        if (spDetails[msg.sender].numberOfEndpoints > 0) {
            this.validateAccountStakeBalance(msg.sender);
        }

        // Indicate this service provider is within bounds
        spDetails[msg.sender].validBounds = true;

        // Clear decrease stake request
        delete decreaseStakeRequests[msg.sender];

        emit DecreaseStakeRequestEvaluated(msg.sender, decreaseAmount, newStakeAmount);
        return newStakeAmount;
    }

    /**
     * @notice Update delegate owner wallet for a given endpoint
     * @param _serviceType - type of service to register, must be valid in ServiceTypeManager
     * @param _endpoint - url of the service to register - url of the service to register
     * @param _updatedDelegateOwnerWallet - address of new delegate wallet
     */
    function updateDelegateOwnerWallet(
        bytes32 _serviceType,
        string calldata _endpoint,
        address _updatedDelegateOwnerWallet
    ) external
    {
        _requireIsInitialized();

        uint256 spID = this.getServiceProviderIdFromEndpoint(_endpoint);

        require(
            serviceProviderInfo[_serviceType][spID].owner == msg.sender,
            "ServiceProviderFactory: Invalid update operation, wrong owner"
        );

        serviceProviderInfo[_serviceType][spID].delegateOwnerWallet = _updatedDelegateOwnerWallet;
        emit DelegateOwnerWalletUpdated(
            msg.sender,
            _serviceType,
            spID,
            _updatedDelegateOwnerWallet
        );
    }

    /**
     * @notice Update the endpoint for a given service
     * @param _serviceType - type of service to register, must be valid in ServiceTypeManager
     * @param _oldEndpoint - old endpoint currently registered
     * @param _newEndpoint - new endpoint to replace old endpoint
     * @return ID of updated service provider
     */
    function updateEndpoint(
        bytes32 _serviceType,
        string calldata _oldEndpoint,
        string calldata _newEndpoint
    ) external returns (uint256)
    {
        _requireIsInitialized();

        uint256 spId = this.getServiceProviderIdFromEndpoint(_oldEndpoint);
        require (
            spId != 0,
            "ServiceProviderFactory: Could not find service provider with that endpoint"
        );

        ServiceEndpoint memory serviceEndpoint = serviceProviderInfo[_serviceType][spId];

        require(
            serviceEndpoint.owner == msg.sender,
            "ServiceProviderFactory: Invalid update endpoint operation, wrong owner"
        );
        require(
            keccak256(bytes(serviceEndpoint.endpoint)) == keccak256(bytes(_oldEndpoint)),
            "ServiceProviderFactory: Old endpoint doesn't match what's registered for the service provider"
        );

        // invalidate old endpoint
        serviceProviderEndpointToId[keccak256(bytes(serviceEndpoint.endpoint))] = 0;

        // update to new endpoint
        serviceEndpoint.endpoint = _newEndpoint;
        serviceProviderInfo[_serviceType][spId] = serviceEndpoint;
        serviceProviderEndpointToId[keccak256(bytes(_newEndpoint))] = spId;

        emit EndpointUpdated(_serviceType, msg.sender, _oldEndpoint, _newEndpoint, spId);
        return spId;
    }

    /**
     * @notice Update the deployer cut for a given service provider
     * @param _serviceProvider - address of service provider
     * @param _cut - new value for deployer cut
     */
    function requestUpdateDeployerCut(address _serviceProvider, uint256 _cut) external
    {
        _requireIsInitialized();

        require(
            msg.sender == _serviceProvider || msg.sender == governanceAddress,
            ERROR_ONLY_SP_GOVERNANCE
        );

        require(
            (updateDeployerCutRequests[_serviceProvider].lockupExpiryBlock == 0) &&
            (updateDeployerCutRequests[_serviceProvider].newDeployerCut == 0),
            "ServiceProviderFactory: Update deployer cut operation pending"
        );

        require(
            _cut <= DEPLOYER_CUT_BASE,
            "ServiceProviderFactory: Service Provider cut cannot exceed base value"
        );

        uint256 expiryBlock = block.number + deployerCutLockupDuration;
        updateDeployerCutRequests[_serviceProvider] = UpdateDeployerCutRequest({
            lockupExpiryBlock: expiryBlock,
            newDeployerCut: _cut
        });

        emit DeployerCutUpdateRequested(_serviceProvider, _cut, expiryBlock);
    }

    /**
     * @notice Cancel a pending request to update deployer cut
     * @param _serviceProvider - address of service provider
     */
    function cancelUpdateDeployerCut(address _serviceProvider) external
    {
        _requireIsInitialized();
        _requirePendingDeployerCutOperation(_serviceProvider);

        require(
            msg.sender == _serviceProvider || msg.sender == governanceAddress,
            ERROR_ONLY_SP_GOVERNANCE
        );

        UpdateDeployerCutRequest memory cancelledRequest = (
            updateDeployerCutRequests[_serviceProvider]
        );

        // Zero out request information
        delete updateDeployerCutRequests[_serviceProvider];
        emit DeployerCutUpdateRequestCancelled(
            _serviceProvider,
            cancelledRequest.newDeployerCut,
            spDetails[_serviceProvider].deployerCut
        );
    }

    /**
     * @notice Evalue request to update service provider cut of claims
     * @notice Update service provider cut as % of delegate claim, divided by the deployerCutBase.
     * @dev SPs will interact with this value as a percent, value translation done client side
       @dev A value of 5 dictates a 5% cut, with ( 5 / 100 ) * delegateReward going to an SP from each delegator each round.
     */
    function updateDeployerCut(address _serviceProvider) external
    {
        _requireIsInitialized();
        _requirePendingDeployerCutOperation(_serviceProvider);

        require(
            msg.sender == _serviceProvider || msg.sender == governanceAddress,
            ERROR_ONLY_SP_GOVERNANCE
        );

        require(
            updateDeployerCutRequests[_serviceProvider].lockupExpiryBlock <= block.number,
            "ServiceProviderFactory: Lockup must be expired"
        );

        spDetails[_serviceProvider].deployerCut = (
            updateDeployerCutRequests[_serviceProvider].newDeployerCut
        );

        // Zero out request information
        delete updateDeployerCutRequests[_serviceProvider];

        emit DeployerCutUpdateRequestEvaluated(
            _serviceProvider,
            spDetails[_serviceProvider].deployerCut
        );
    }

    /**
     * @notice Update service provider balance
     * @dev Called by DelegateManager by functions modifying entire stake like claim and slash
     * @param _serviceProvider - address of service provider
     * @param _amount - new amount of direct state for service provider
     */
    function updateServiceProviderStake(
        address _serviceProvider,
        uint256 _amount
     ) external
    {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireDelegateManagerAddressIsSet();

        require(
            msg.sender == delegateManagerAddress,
            "ServiceProviderFactory: only callable by DelegateManager"
        );
        // Update SP tracked total
        spDetails[_serviceProvider].deployerStake = _amount;
        _updateServiceProviderBoundStatus(_serviceProvider);
    }

    /// @notice Update service provider lockup duration
    function updateDecreaseStakeLockupDuration(uint256 _duration) external {
        _requireIsInitialized();

        require(
            msg.sender == governanceAddress,
            ERROR_ONLY_GOVERNANCE
        );

        _updateDecreaseStakeLockupDuration(_duration);
        emit DecreaseStakeLockupDurationUpdated(_duration);
    }

    /// @notice Update service provider lockup duration
    function updateDeployerCutLockupDuration(uint256 _duration) external {
        _requireIsInitialized();

        require(
            msg.sender == governanceAddress,
            ERROR_ONLY_GOVERNANCE
        );

        _updateDeployerCutLockupDuration(_duration);
        emit UpdateDeployerCutLockupDurationUpdated(_duration);
    }

    /// @notice Get denominator for deployer cut calculations
    function getServiceProviderDeployerCutBase()
    external view returns (uint256)
    {
        _requireIsInitialized();

        return DEPLOYER_CUT_BASE;
    }

    /// @notice Get current deployer cut update lockup duration
    function getDeployerCutLockupDuration()
    external view returns (uint256)
    {
        _requireIsInitialized();

        return deployerCutLockupDuration;
    }

    /// @notice Get total number of service providers for a given serviceType
    function getTotalServiceTypeProviders(bytes32 _serviceType)
    external view returns (uint256)
    {
        _requireIsInitialized();

        return serviceProviderTypeIDs[_serviceType];
    }

    /// @notice Get service provider id for an endpoint
    function getServiceProviderIdFromEndpoint(string calldata _endpoint)
    external view returns (uint256)
    {
        _requireIsInitialized();

        return serviceProviderEndpointToId[keccak256(bytes(_endpoint))];
    }

    /**
     * @notice Get service provider ids for a given service provider and service type
     * @return List of service ids of that type for a service provider
     */
    function getServiceProviderIdsFromAddress(address _ownerAddress, bytes32 _serviceType)
    external view returns (uint256[] memory)
    {
        _requireIsInitialized();

        return serviceProviderAddressToId[_ownerAddress][_serviceType];
    }

    /**
     * @notice Get information about a service endpoint given its service id
     * @param _serviceType - type of service, must be a valid service from ServiceTypeManager
     * @param _serviceId - id of service
     */
    function getServiceEndpointInfo(bytes32 _serviceType, uint256 _serviceId)
    external view returns (address owner, string memory endpoint, uint256 blockNumber, address delegateOwnerWallet)
    {
        _requireIsInitialized();

        ServiceEndpoint memory serviceEndpoint = serviceProviderInfo[_serviceType][_serviceId];
        return (
            serviceEndpoint.owner,
            serviceEndpoint.endpoint,
            serviceEndpoint.blocknumber,
            serviceEndpoint.delegateOwnerWallet
        );
    }

    /**
     * @notice Get information about a service provider given their address
     * @param _serviceProvider - address of service provider
     */
    function getServiceProviderDetails(address _serviceProvider)
    external view returns (
        uint256 deployerStake,
        uint256 deployerCut,
        bool validBounds,
        uint256 numberOfEndpoints,
        uint256 minAccountStake,
        uint256 maxAccountStake)
    {
        _requireIsInitialized();

        return (
            spDetails[_serviceProvider].deployerStake,
            spDetails[_serviceProvider].deployerCut,
            spDetails[_serviceProvider].validBounds,
            spDetails[_serviceProvider].numberOfEndpoints,
            spDetails[_serviceProvider].minAccountStake,
            spDetails[_serviceProvider].maxAccountStake
        );
    }

    /**
     * @notice Get information about pending decrease stake requests for service provider
     * @param _serviceProvider - address of service provider
     */
    function getPendingDecreaseStakeRequest(address _serviceProvider)
    external view returns (uint256 amount, uint256 lockupExpiryBlock)
    {
        _requireIsInitialized();

        return (
            decreaseStakeRequests[_serviceProvider].decreaseAmount,
            decreaseStakeRequests[_serviceProvider].lockupExpiryBlock
        );
    }

    /**
     * @notice Get information about pending decrease stake requests for service provider
     * @param _serviceProvider - address of service provider
     */
    function getPendingUpdateDeployerCutRequest(address _serviceProvider)
    external view returns (uint256 newDeployerCut, uint256 lockupExpiryBlock)
    {
        _requireIsInitialized();

        return (
            updateDeployerCutRequests[_serviceProvider].newDeployerCut,
            updateDeployerCutRequests[_serviceProvider].lockupExpiryBlock
        );
    }

    /// @notice Get current unstake lockup duration
    function getDecreaseStakeLockupDuration()
    external view returns (uint256)
    {
        _requireIsInitialized();

        return decreaseStakeLockupDuration;
    }

    /**
     * @notice Validate that the total service provider balance is between the min and max stakes
               for all their registered services and validate  direct stake for sp is above minimum
     * @param _serviceProvider - address of service provider
     */
    function validateAccountStakeBalance(address _serviceProvider)
    external view
    {
        _requireIsInitialized();
        _requireStakingAddressIsSet();

        _validateBalanceInternal(
            _serviceProvider,
            Staking(stakingAddress).totalStakedFor(_serviceProvider)
        );
    }

    /// @notice Get the Governance address
    function getGovernanceAddress() external view returns (address) {
        _requireIsInitialized();

        return governanceAddress;
    }

    /// @notice Get the Staking address
    function getStakingAddress() external view returns (address) {
        _requireIsInitialized();

        return stakingAddress;
    }

    /// @notice Get the DelegateManager address
    function getDelegateManagerAddress() external view returns (address) {
        _requireIsInitialized();

        return delegateManagerAddress;
    }

    /// @notice Get the ServiceTypeManager address
    function getServiceTypeManagerAddress() external view returns (address) {
        _requireIsInitialized();

        return serviceTypeManagerAddress;
    }

    /// @notice Get the ClaimsManager address
    function getClaimsManagerAddress() external view returns (address) {
        _requireIsInitialized();

        return claimsManagerAddress;
    }

    /**
     * @notice Set the Governance address
     * @dev Only callable by Governance address
     * @param _governanceAddress - address for new Governance contract
     */
    function setGovernanceAddress(address _governanceAddress) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        _updateGovernanceAddress(_governanceAddress);
        emit GovernanceAddressUpdated(_governanceAddress);
    }

    /**
     * @notice Set the Staking address
     * @dev Only callable by Governance address
     * @param _address - address for new Staking contract
     */
    function setStakingAddress(address _address) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        stakingAddress = _address;
        emit StakingAddressUpdated(_address);
    }

    /**
     * @notice Set the DelegateManager address
     * @dev Only callable by Governance address
     * @param _address - address for new DelegateManager contract
     */
    function setDelegateManagerAddress(address _address) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        delegateManagerAddress = _address;
        emit DelegateManagerAddressUpdated(_address);
    }

    /**
     * @notice Set the ServiceTypeManager address
     * @dev Only callable by Governance address
     * @param _address - address for new ServiceTypeManager contract
     */
    function setServiceTypeManagerAddress(address _address) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        serviceTypeManagerAddress = _address;
        emit ServiceTypeManagerAddressUpdated(_address);
    }

    /**
     * @notice Set the ClaimsManager address
     * @dev Only callable by Governance address
     * @param _address - address for new ClaimsManager contract
     */
    function setClaimsManagerAddress(address _address) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        claimsManagerAddress = _address;
        emit ClaimsManagerAddressUpdated(_address);
    }

    // ========================================= Internal Functions =========================================

    /**
     * @notice Update status in spDetails if the bounds for a service provider is valid
     */
    function _updateServiceProviderBoundStatus(address _serviceProvider) internal {
        // Validate bounds for total stake
        uint256 totalSPStake = Staking(stakingAddress).totalStakedFor(_serviceProvider);
        if (totalSPStake < spDetails[_serviceProvider].minAccountStake ||
            totalSPStake > spDetails[_serviceProvider].maxAccountStake) {
            // Indicate this service provider is out of bounds
            spDetails[_serviceProvider].validBounds = false;
        } else {
            // Indicate this service provider is within bounds
            spDetails[_serviceProvider].validBounds = true;
        }
    }

    /**
     * @notice Set the governance address after confirming contract identity
     * @param _governanceAddress - Incoming governance address
     */
    function _updateGovernanceAddress(address _governanceAddress) internal {
        require(
            Governance(_governanceAddress).isGovernanceAddress() == true,
            "ServiceProviderFactory: _governanceAddress is not a valid governance contract"
        );
        governanceAddress = _governanceAddress;
    }

    /**
     * @notice Set the deployer cut lockup duration
     * @param _duration - incoming duration
     */
    function _updateDeployerCutLockupDuration(uint256 _duration) internal
    {
        require(
            ClaimsManager(claimsManagerAddress).getFundingRoundBlockDiff() < _duration,
            "ServiceProviderFactory: Incoming duration must be greater than funding round block diff"
        );
        deployerCutLockupDuration = _duration;
    }

    /**
     * @notice Set the decrease stake lockup duration
     * @param _duration - incoming duration
     */
    function _updateDecreaseStakeLockupDuration(uint256 _duration) internal
    {
        Governance governance = Governance(governanceAddress);
        require(
            _duration > governance.getVotingPeriod() + governance.getExecutionDelay(),
            "ServiceProviderFactory: decreaseStakeLockupDuration duration must be greater than governance votingPeriod + executionDelay"
        );
        decreaseStakeLockupDuration = _duration;
    }

    /**
     * @notice Compare a given amount input against valid min and max bounds for service provider
     * @param _serviceProvider - address of service provider
     * @param _amount - amount in wei to compare
     */
    function _validateBalanceInternal(address _serviceProvider, uint256 _amount) internal view
    {
        require(
            _amount <= spDetails[_serviceProvider].maxAccountStake,
            "ServiceProviderFactory: Maximum stake amount exceeded"
        );
        require(
            spDetails[_serviceProvider].deployerStake >= spDetails[_serviceProvider].minAccountStake,
            "ServiceProviderFactory: Minimum stake requirement not met"
        );
    }

    /**
     * @notice Get whether a decrease request has been initiated for service provider
     * @param _serviceProvider - address of service provider
     * return Boolean of whether decrease request has been initiated
     */
    function _decreaseRequestIsPending(address _serviceProvider)
    internal view returns (bool)
    {
        return (
            (decreaseStakeRequests[_serviceProvider].lockupExpiryBlock > 0) &&
            (decreaseStakeRequests[_serviceProvider].decreaseAmount > 0)
        );
    }

    /**
     * @notice Boolean indicating whether a claim is pending for this service provider
     */
     /**
     * @notice Get whether a claim is pending for this service provider
     * @param _serviceProvider - address of service provider
     * return Boolean of whether claim is pending
     */
    function _claimPending(address _serviceProvider) internal view returns (bool) {
        return ClaimsManager(claimsManagerAddress).claimPending(_serviceProvider);
    }

    // ========================================= Private Functions =========================================
    function _requirePendingDeployerCutOperation (address _serviceProvider) private view {
        require(
            (updateDeployerCutRequests[_serviceProvider].lockupExpiryBlock != 0),
            "ServiceProviderFactory: No update deployer cut operation pending"
        );
    }

    function _requireStakingAddressIsSet() private view {
        require(
            stakingAddress != address(0x00),
            "ServiceProviderFactory: stakingAddress is not set"
        );
    }

    function _requireDelegateManagerAddressIsSet() private view {
        require(
            delegateManagerAddress != address(0x00),
            "ServiceProviderFactory: delegateManagerAddress is not set"
        );
    }

    function _requireServiceTypeManagerAddressIsSet() private view {
        require(
            serviceTypeManagerAddress != address(0x00),
            "ServiceProviderFactory: serviceTypeManagerAddress is not set"
        );
    }

    function _requireClaimsManagerAddressIsSet() private view {
        require(
            claimsManagerAddress != address(0x00),
            "ServiceProviderFactory: claimsManagerAddress is not set"
        );
    }
}

// File: contracts/DelegateManager.sol

pragma solidity ^0.5.0;


/// @notice SafeMath imported via ServiceProviderFactory.sol
/// @notice Governance imported via Staking.sol



/**
 * Designed to manage delegation to staking contract
 */
contract DelegateManager is InitializableV2 {
    using SafeMath for uint256;

    string private constant ERROR_ONLY_GOVERNANCE = (
        "DelegateManager: Only callable by Governance contract"
    );
    string private constant ERROR_MINIMUM_DELEGATION = (
        "DelegateManager: Minimum delegation amount required"
    );
    string private constant ERROR_ONLY_SP_GOVERNANCE = (
        "DelegateManager: Only callable by target SP or governance"
    );
    string private constant ERROR_DELEGATOR_STAKE = (
        "DelegateManager: Delegator must be staked for SP"
    );

    address private governanceAddress;
    address private stakingAddress;
    address private serviceProviderFactoryAddress;
    address private claimsManagerAddress;

    /**
     * Period in  blocks an undelegate operation is delayed.
     * The undelegate operation speed bump is to prevent a delegator from
     *      attempting to remove their delegation in anticipation of a slash.
     * @notice Must be greater than governance votingPeriod + executionDelay
     */
    uint256 private undelegateLockupDuration;

    /// @notice Maximum number of delegators a single account can handle
    uint256 private maxDelegators;

    /// @notice Minimum amount of delegation allowed
    uint256 private minDelegationAmount;

    /**
     * Lockup duration for a remove delegator request.
     * The remove delegator speed bump is to prevent a service provider from maliciously
     *     removing a delegator prior to the evaluation of a proposal.
     * @notice Must be greater than governance votingPeriod + executionDelay
     */
    uint256 private removeDelegatorLockupDuration;

    /**
     * Evaluation period for a remove delegator request
     * @notice added to expiry block calculated for removeDelegatorLockupDuration
     */
    uint256 private removeDelegatorEvalDuration;

    // Staking contract ref
    ERC20Mintable private audiusToken;

    // Struct representing total delegated to SP and list of delegators
    struct ServiceProviderDelegateInfo {
        uint256 totalDelegatedStake;
        uint256 totalLockedUpStake;
        address[] delegators;
    }

    // Data structures for lockup during withdrawal
    struct UndelegateStakeRequest {
        address serviceProvider;
        uint256 amount;
        uint256 lockupExpiryBlock;
    }

    // Service provider address -> ServiceProviderDelegateInfo
    mapping (address => ServiceProviderDelegateInfo) private spDelegateInfo;

    // Delegator stake by address delegated to
    // delegator -> (service provider -> delegatedStake)
    mapping (address => mapping(address => uint256)) private delegateInfo;

    // Delegator stake total by address
    // delegator -> (totalDelegated)
    // Note - delegator properties are maintained in a mapping instead of struct
    // in order to facilitate extensibility in the future.
    mapping (address => uint256) private delegatorTotalStake;

    // Requester to pending undelegate request
    mapping (address => UndelegateStakeRequest) private undelegateRequests;

    // Pending remove delegator requests
    // service provider -> (delegator -> lockupExpiryBlock)
    mapping (address => mapping (address => uint256)) private removeDelegatorRequests;

    event IncreaseDelegatedStake(
        address indexed _delegator,
        address indexed _serviceProvider,
        uint256 indexed _increaseAmount
    );

    event UndelegateStakeRequested(
        address indexed _delegator,
        address indexed _serviceProvider,
        uint256 indexed _amount,
        uint256 _lockupExpiryBlock
    );

    event UndelegateStakeRequestCancelled(
        address indexed _delegator,
        address indexed _serviceProvider,
        uint256 indexed _amount
    );

    event UndelegateStakeRequestEvaluated(
        address indexed _delegator,
        address indexed _serviceProvider,
        uint256 indexed _amount
    );

    event Claim(
        address indexed _claimer,
        uint256 indexed _rewards,
        uint256 indexed _newTotal
    );

    event Slash(
        address indexed _target,
        uint256 indexed _amount,
        uint256 indexed _newTotal
    );

    event RemoveDelegatorRequested(
        address indexed _serviceProvider,
        address indexed _delegator,
        uint256 indexed _lockupExpiryBlock
    );

    event RemoveDelegatorRequestCancelled(
        address indexed _serviceProvider,
        address indexed _delegator
    );

    event RemoveDelegatorRequestEvaluated(
        address indexed _serviceProvider,
        address indexed _delegator,
        uint256 indexed _unstakedAmount
    );

    event MaxDelegatorsUpdated(uint256 indexed _maxDelegators);
    event MinDelegationUpdated(uint256 indexed _minDelegationAmount);
    event UndelegateLockupDurationUpdated(uint256 indexed _undelegateLockupDuration);
    event GovernanceAddressUpdated(address indexed _newGovernanceAddress);
    event StakingAddressUpdated(address indexed _newStakingAddress);
    event ServiceProviderFactoryAddressUpdated(address indexed _newServiceProviderFactoryAddress);
    event ClaimsManagerAddressUpdated(address indexed _newClaimsManagerAddress);
    event RemoveDelegatorLockupDurationUpdated(uint256 indexed _removeDelegatorLockupDuration);
    event RemoveDelegatorEvalDurationUpdated(uint256 indexed _removeDelegatorEvalDuration);

    /**
     * @notice Function to initialize the contract
     * @dev stakingAddress must be initialized separately after Staking contract is deployed
     * @dev serviceProviderFactoryAddress must be initialized separately after ServiceProviderFactory contract is deployed
     * @dev claimsManagerAddress must be initialized separately after ClaimsManager contract is deployed
     * @param _tokenAddress - address of ERC20 token that will be claimed
     * @param _governanceAddress - Governance proxy address
     */
    function initialize (
        address _tokenAddress,
        address _governanceAddress,
        uint256 _undelegateLockupDuration
    ) public initializer
    {
        _updateGovernanceAddress(_governanceAddress);
        audiusToken = ERC20Mintable(_tokenAddress);
        maxDelegators = 175;
        // Default minimum delegation amount set to 100AUD
        minDelegationAmount = 100 * 10**uint256(18);
        InitializableV2.initialize();

        _updateUndelegateLockupDuration(_undelegateLockupDuration);

        // 1 week = 168hrs * 60 min/hr * 60 sec/min / ~13 sec/block = 46523 blocks
        _updateRemoveDelegatorLockupDuration(46523);

        // 24hr * 60min/hr * 60sec/min / ~13 sec/block = 6646 blocks
        removeDelegatorEvalDuration = 6646;
    }

    /**
     * @notice Allow a delegator to delegate stake to a service provider
     * @param _targetSP - address of service provider to delegate to
     * @param _amount - amount in wei to delegate
     * @return Updated total amount delegated to the service provider by delegator
     */
    function delegateStake(
        address _targetSP,
        uint256 _amount
    ) external returns (uint256)
    {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireServiceProviderFactoryAddressIsSet();
        _requireClaimsManagerAddressIsSet();

        require(
            !_claimPending(_targetSP),
            "DelegateManager: Delegation not permitted for SP pending claim"
        );
        address delegator = msg.sender;
        Staking stakingContract = Staking(stakingAddress);

        // Stake on behalf of target service provider
        stakingContract.delegateStakeFor(
            _targetSP,
            delegator,
            _amount
        );

        // Update list of delegators to SP if necessary
        if (!_delegatorExistsForSP(delegator, _targetSP)) {
            // If not found, update list of delegates
            spDelegateInfo[_targetSP].delegators.push(delegator);
            require(
                spDelegateInfo[_targetSP].delegators.length <= maxDelegators,
                "DelegateManager: Maximum delegators exceeded"
            );
        }

        // Update following values in storage through helper
        // totalServiceProviderDelegatedStake = current sp total + new amount,
        // totalStakedForSpFromDelegator = current delegator total for sp + new amount,
        // totalDelegatorStake = current delegator total + new amount
        _updateDelegatorStake(
            delegator,
            _targetSP,
            spDelegateInfo[_targetSP].totalDelegatedStake.add(_amount),
            delegateInfo[delegator][_targetSP].add(_amount),
            delegatorTotalStake[delegator].add(_amount)
        );

        require(
            delegateInfo[delegator][_targetSP] >= minDelegationAmount,
            ERROR_MINIMUM_DELEGATION
        );

        // Validate balance
        ServiceProviderFactory(
            serviceProviderFactoryAddress
        ).validateAccountStakeBalance(_targetSP);

        emit IncreaseDelegatedStake(
            delegator,
            _targetSP,
            _amount
        );

        // Return new total
        return delegateInfo[delegator][_targetSP];
    }

    /**
     * @notice Submit request for undelegation
     * @param _target - address of service provider to undelegate stake from
     * @param _amount - amount in wei to undelegate
     * @return Updated total amount delegated to the service provider by delegator
     */
    function requestUndelegateStake(
        address _target,
        uint256 _amount
    ) external returns (uint256)
    {
        _requireIsInitialized();
        _requireClaimsManagerAddressIsSet();

        require(
            _amount > 0,
            "DelegateManager: Requested undelegate stake amount must be greater than zero"
        );
        require(
            !_claimPending(_target),
            "DelegateManager: Undelegate request not permitted for SP pending claim"
        );
        address delegator = msg.sender;
        require(
            _delegatorExistsForSP(delegator, _target),
            ERROR_DELEGATOR_STAKE
        );

        // Confirm no pending delegation request
        require(
            !_undelegateRequestIsPending(delegator),
            "DelegateManager: No pending lockup expected"
        );

        // Ensure valid bounds
        uint256 currentlyDelegatedToSP = delegateInfo[delegator][_target];
        require(
            _amount <= currentlyDelegatedToSP,
            "DelegateManager: Cannot decrease greater than currently staked for this ServiceProvider"
        );

        // Submit updated request for sender, with target sp, undelegate amount, target expiry block
        uint256 lockupExpiryBlock = block.number.add(undelegateLockupDuration);
        _updateUndelegateStakeRequest(
            delegator,
            _target,
            _amount,
            lockupExpiryBlock
        );
        // Update total locked for this service provider, increasing by unstake amount
        _updateServiceProviderLockupAmount(
            _target,
            spDelegateInfo[_target].totalLockedUpStake.add(_amount)
        );

        emit UndelegateStakeRequested(delegator, _target, _amount, lockupExpiryBlock);
        return delegateInfo[delegator][_target].sub(_amount);
    }

    /**
     * @notice Cancel undelegation request
     */
    function cancelUndelegateStakeRequest() external {
        _requireIsInitialized();

        address delegator = msg.sender;
        // Confirm pending delegation request
        require(
            _undelegateRequestIsPending(delegator),
            "DelegateManager: Pending lockup expected"
        );
        uint256 unstakeAmount = undelegateRequests[delegator].amount;
        address unlockFundsSP = undelegateRequests[delegator].serviceProvider;
        // Update total locked for this service provider, decreasing by unstake amount
        _updateServiceProviderLockupAmount(
            unlockFundsSP,
            spDelegateInfo[unlockFundsSP].totalLockedUpStake.sub(unstakeAmount)
        );
        // Remove pending request
        _resetUndelegateStakeRequest(delegator);
        emit UndelegateStakeRequestCancelled(delegator, unlockFundsSP, unstakeAmount);
    }

    /**
     * @notice Finalize undelegation request and withdraw stake
     * @return New total amount currently staked after stake has been undelegated
     */
    function undelegateStake() external returns (uint256) {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireServiceProviderFactoryAddressIsSet();
        _requireClaimsManagerAddressIsSet();

        address delegator = msg.sender;

        // Confirm pending delegation request
        require(
            _undelegateRequestIsPending(delegator),
            "DelegateManager: Pending lockup expected"
        );

        // Confirm lockup expiry has expired
        require(
            undelegateRequests[delegator].lockupExpiryBlock <= block.number,
            "DelegateManager: Lockup must be expired"
        );

        // Confirm no pending claim for this service provider
        require(
            !_claimPending(undelegateRequests[delegator].serviceProvider),
            "DelegateManager: Undelegate not permitted for SP pending claim"
        );

        address serviceProvider = undelegateRequests[delegator].serviceProvider;
        uint256 unstakeAmount = undelegateRequests[delegator].amount;

        // Unstake on behalf of target service provider
        Staking(stakingAddress).undelegateStakeFor(
            serviceProvider,
            delegator,
            unstakeAmount
        );

        // Update total delegated for SP
        // totalServiceProviderDelegatedStake - total amount delegated to service provider
        // totalStakedForSpFromDelegator - amount staked from this delegator to targeted service provider
        _updateDelegatorStake(
            delegator,
            serviceProvider,
            spDelegateInfo[serviceProvider].totalDelegatedStake.sub(unstakeAmount),
            delegateInfo[delegator][serviceProvider].sub(unstakeAmount),
            delegatorTotalStake[delegator].sub(unstakeAmount)
        );

        require(
            (delegateInfo[delegator][serviceProvider] >= minDelegationAmount ||
             delegateInfo[delegator][serviceProvider] == 0),
            ERROR_MINIMUM_DELEGATION
        );

        // Remove from delegators list if no delegated stake remaining
        if (delegateInfo[delegator][serviceProvider] == 0) {
            _removeFromDelegatorsList(serviceProvider, delegator);
        }

        // Update total locked for this service provider, decreasing by unstake amount
        _updateServiceProviderLockupAmount(
            serviceProvider,
            spDelegateInfo[serviceProvider].totalLockedUpStake.sub(unstakeAmount)
        );
        // Reset undelegate request
        _resetUndelegateStakeRequest(delegator);

        emit UndelegateStakeRequestEvaluated(
            delegator,
            serviceProvider,
            unstakeAmount
        );

        // Return new total
        return delegateInfo[delegator][serviceProvider];
    }

    /**
     * @notice Claim and distribute rewards to delegators and service provider as necessary
     * @param _serviceProvider - Provider for which rewards are being distributed
     * @dev Factors in service provider rewards from delegator and transfers deployer cut
     */
    function claimRewards(address _serviceProvider) external {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireServiceProviderFactoryAddressIsSet();
        _requireClaimsManagerAddressIsSet();

        ServiceProviderFactory spFactory = ServiceProviderFactory(serviceProviderFactoryAddress);

        // Total rewards = (balance in staking) - ((balance in sp factory) + (balance in delegate manager))
        (
            uint256 totalBalanceInStaking,
            uint256 totalBalanceInSPFactory,
            uint256 totalActiveFunds,
            uint256 totalRewards,
            uint256 deployerCut
        ) = _validateClaimRewards(spFactory, _serviceProvider);

        // No-op if balance is already equivalent
        // This case can occur if no rewards due to bound violation or all stake is locked
        if (totalRewards == 0) {
            return;
        }

        uint256 totalDelegatedStakeIncrease = _distributeDelegateRewards(
            _serviceProvider,
            totalActiveFunds,
            totalRewards,
            deployerCut,
            spFactory.getServiceProviderDeployerCutBase()
        );

        // Update total delegated to this SP
        spDelegateInfo[_serviceProvider].totalDelegatedStake = (
            spDelegateInfo[_serviceProvider].totalDelegatedStake.add(totalDelegatedStakeIncrease)
        );

        // spRewardShare represents rewards directly allocated to service provider for their stake
        // Value is computed as the remainder of total minted rewards after distribution to
        // delegators, eliminating any potential for precision loss.
        uint256 spRewardShare = totalRewards.sub(totalDelegatedStakeIncrease);

        // Adding the newly calculated reward share to current balance
        uint256 newSPFactoryBalance = totalBalanceInSPFactory.add(spRewardShare);

        require(
            totalBalanceInStaking == newSPFactoryBalance.add(spDelegateInfo[_serviceProvider].totalDelegatedStake),
            "DelegateManager: claimRewards amount mismatch"
        );

        spFactory.updateServiceProviderStake(
            _serviceProvider,
            newSPFactoryBalance
        );
    }

    /**
     * @notice Reduce current stake amount
     * @dev Only callable by governance. Slashes service provider and delegators equally
     * @param _amount - amount in wei to slash
     * @param _slashAddress - address of service provider to slash
     */
    function slash(uint256 _amount, address _slashAddress)
    external
    {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireServiceProviderFactoryAddressIsSet();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);

        Staking stakingContract = Staking(stakingAddress);
        ServiceProviderFactory spFactory = ServiceProviderFactory(serviceProviderFactoryAddress);

        // Amount stored in staking contract for owner
        uint256 totalBalanceInStakingPreSlash = stakingContract.totalStakedFor(_slashAddress);
        require(
            (totalBalanceInStakingPreSlash >= _amount),
            "DelegateManager: Cannot slash more than total currently staked"
        );

        // Cancel any withdrawal request for this service provider
        (uint256 spLockedStake,) = spFactory.getPendingDecreaseStakeRequest(_slashAddress);
        if (spLockedStake > 0) {
            spFactory.cancelDecreaseStakeRequest(_slashAddress);
        }

        // Amount in sp factory for slash target
        (uint256 totalBalanceInSPFactory,,,,,) = (
            spFactory.getServiceProviderDetails(_slashAddress)
        );
        require(
            totalBalanceInSPFactory > 0,
            "DelegateManager: Service Provider stake required"
        );

        // Decrease value in Staking contract
        // A value of zero slash will fail in staking, reverting this transaction
        stakingContract.slash(_amount, _slashAddress);
        uint256 totalBalanceInStakingAfterSlash = stakingContract.totalStakedFor(_slashAddress);

        // Emit slash event
        emit Slash(_slashAddress, _amount, totalBalanceInStakingAfterSlash);

        uint256 totalDelegatedStakeDecrease = 0;
        // For each delegator and deployer, recalculate new value
        // newStakeAmount = newStakeAmount * (oldStakeAmount / totalBalancePreSlash)
        for (uint256 i = 0; i < spDelegateInfo[_slashAddress].delegators.length; i++) {
            address delegator = spDelegateInfo[_slashAddress].delegators[i];
            uint256 preSlashDelegateStake = delegateInfo[delegator][_slashAddress];
            uint256 newDelegateStake = (
             totalBalanceInStakingAfterSlash.mul(preSlashDelegateStake)
            ).div(totalBalanceInStakingPreSlash);
            // slashAmountForDelegator = preSlashDelegateStake - newDelegateStake;
            delegateInfo[delegator][_slashAddress] = (
                delegateInfo[delegator][_slashAddress].sub(preSlashDelegateStake.sub(newDelegateStake))
            );
            // Update total stake for delegator
            _updateDelegatorTotalStake(
                delegator,
                delegatorTotalStake[delegator].sub(preSlashDelegateStake.sub(newDelegateStake))
            );
            // Update total decrease amount
            totalDelegatedStakeDecrease = (
                totalDelegatedStakeDecrease.add(preSlashDelegateStake.sub(newDelegateStake))
            );
            // Check for any locked up funds for this slashed delegator
            // Slash overrides any pending withdrawal requests
            if (undelegateRequests[delegator].amount != 0) {
                address unstakeSP = undelegateRequests[delegator].serviceProvider;
                uint256 unstakeAmount = undelegateRequests[delegator].amount;
                // Remove pending request
                _updateServiceProviderLockupAmount(
                    unstakeSP,
                    spDelegateInfo[unstakeSP].totalLockedUpStake.sub(unstakeAmount)
                );
                _resetUndelegateStakeRequest(delegator);
            }
        }

        // Update total delegated to this SP
        spDelegateInfo[_slashAddress].totalDelegatedStake = (
            spDelegateInfo[_slashAddress].totalDelegatedStake.sub(totalDelegatedStakeDecrease)
        );

        // Remaining decrease applied to service provider
        uint256 totalStakeDecrease = (
            totalBalanceInStakingPreSlash.sub(totalBalanceInStakingAfterSlash)
        );
        uint256 totalSPFactoryBalanceDecrease = (
            totalStakeDecrease.sub(totalDelegatedStakeDecrease)
        );
        spFactory.updateServiceProviderStake(
            _slashAddress,
            totalBalanceInSPFactory.sub(totalSPFactoryBalanceDecrease)
        );
    }

    /**
     * @notice Initiate forcible removal of a delegator
     * @param _serviceProvider - address of service provider
     * @param _delegator - address of delegator
     */
    function requestRemoveDelegator(address _serviceProvider, address _delegator) external {
        _requireIsInitialized();

        require(
            msg.sender == _serviceProvider || msg.sender == governanceAddress,
            ERROR_ONLY_SP_GOVERNANCE
        );

        require(
            removeDelegatorRequests[_serviceProvider][_delegator] == 0,
            "DelegateManager: Pending remove delegator request"
        );

        require(
            _delegatorExistsForSP(_delegator, _serviceProvider),
            ERROR_DELEGATOR_STAKE
        );

        // Update lockup
        removeDelegatorRequests[_serviceProvider][_delegator] = (
            block.number + removeDelegatorLockupDuration
        );

        emit RemoveDelegatorRequested(
            _serviceProvider,
            _delegator,
            removeDelegatorRequests[_serviceProvider][_delegator]
        );
    }

    /**
     * @notice Cancel pending removeDelegator request
     * @param _serviceProvider - address of service provider
     * @param _delegator - address of delegator
     */
    function cancelRemoveDelegatorRequest(address _serviceProvider, address _delegator) external {
        require(
            msg.sender == _serviceProvider || msg.sender == governanceAddress,
            ERROR_ONLY_SP_GOVERNANCE
        );
        require(
            removeDelegatorRequests[_serviceProvider][_delegator] != 0,
            "DelegateManager: No pending request"
        );
        // Reset lockup expiry
        removeDelegatorRequests[_serviceProvider][_delegator] = 0;
        emit RemoveDelegatorRequestCancelled(_serviceProvider, _delegator);
    }

    /**
     * @notice Evaluate removeDelegator request
     * @param _serviceProvider - address of service provider
     * @param _delegator - address of delegator
     * @return Updated total amount delegated to the service provider by delegator
     */
    function removeDelegator(address _serviceProvider, address _delegator) external {
        _requireIsInitialized();
        _requireStakingAddressIsSet();

        require(
            msg.sender == _serviceProvider || msg.sender == governanceAddress,
            ERROR_ONLY_SP_GOVERNANCE
        );

        require(
            removeDelegatorRequests[_serviceProvider][_delegator] != 0,
            "DelegateManager: No pending request"
        );

        // Enforce lockup expiry block
        require(
            block.number >= removeDelegatorRequests[_serviceProvider][_delegator],
            "DelegateManager: Lockup must be expired"
        );

        // Enforce evaluation window for request
        require(
            block.number < removeDelegatorRequests[_serviceProvider][_delegator] + removeDelegatorEvalDuration,
            "DelegateManager: RemoveDelegator evaluation window expired"
        );

        uint256 unstakeAmount = delegateInfo[_delegator][_serviceProvider];
        // Unstake on behalf of target service provider
        Staking(stakingAddress).undelegateStakeFor(
            _serviceProvider,
            _delegator,
            unstakeAmount
        );
        // Update total delegated for SP
        // totalServiceProviderDelegatedStake - total amount delegated to service provider
        // totalStakedForSpFromDelegator - amount staked from this delegator to targeted service provider
        _updateDelegatorStake(
            _delegator,
            _serviceProvider,
            spDelegateInfo[_serviceProvider].totalDelegatedStake.sub(unstakeAmount),
            delegateInfo[_delegator][_serviceProvider].sub(unstakeAmount),
            delegatorTotalStake[_delegator].sub(unstakeAmount)
        );

        if (
            _undelegateRequestIsPending(_delegator) &&
            undelegateRequests[_delegator].serviceProvider == _serviceProvider
        ) {
            // Remove pending request information
            _updateServiceProviderLockupAmount(
                _serviceProvider,
                spDelegateInfo[_serviceProvider].totalLockedUpStake.sub(undelegateRequests[_delegator].amount)
            );
            _resetUndelegateStakeRequest(_delegator);
        }

        // Remove from list of delegators
        _removeFromDelegatorsList(_serviceProvider, _delegator);

        // Reset lockup expiry
        removeDelegatorRequests[_serviceProvider][_delegator] = 0;
        emit RemoveDelegatorRequestEvaluated(_serviceProvider, _delegator, unstakeAmount);
    }

    /**
     * @notice Update duration for undelegate request lockup
     * @param _duration - new lockup duration
     */
    function updateUndelegateLockupDuration(uint256 _duration) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);

        _updateUndelegateLockupDuration(_duration);
        emit UndelegateLockupDurationUpdated(_duration);
    }

    /**
     * @notice Update maximum delegators allowed
     * @param _maxDelegators - new max delegators
     */
    function updateMaxDelegators(uint256 _maxDelegators) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);

        maxDelegators = _maxDelegators;
        emit MaxDelegatorsUpdated(_maxDelegators);
    }

    /**
     * @notice Update minimum delegation amount
     * @param _minDelegationAmount - min new min delegation amount
     */
    function updateMinDelegationAmount(uint256 _minDelegationAmount) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);

        minDelegationAmount = _minDelegationAmount;
        emit MinDelegationUpdated(_minDelegationAmount);
    }

    /**
     * @notice Update remove delegator lockup duration
     * @param _duration - new lockup duration
     */
    function updateRemoveDelegatorLockupDuration(uint256 _duration) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);

        _updateRemoveDelegatorLockupDuration(_duration);
        emit RemoveDelegatorLockupDurationUpdated(_duration);
    }

    /**
     * @notice Update remove delegator evaluation window duration
     * @param _duration - new window duration
     */
    function updateRemoveDelegatorEvalDuration(uint256 _duration) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);

        removeDelegatorEvalDuration = _duration;
        emit RemoveDelegatorEvalDurationUpdated(_duration);
    }

    /**
     * @notice Set the Governance address
     * @dev Only callable by Governance address
     * @param _governanceAddress - address for new Governance contract
     */
    function setGovernanceAddress(address _governanceAddress) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);

        _updateGovernanceAddress(_governanceAddress);
        governanceAddress = _governanceAddress;
        emit GovernanceAddressUpdated(_governanceAddress);
    }

    /**
     * @notice Set the Staking address
     * @dev Only callable by Governance address
     * @param _stakingAddress - address for new Staking contract
     */
    function setStakingAddress(address _stakingAddress) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        stakingAddress = _stakingAddress;
        emit StakingAddressUpdated(_stakingAddress);
    }

    /**
     * @notice Set the ServiceProviderFactory address
     * @dev Only callable by Governance address
     * @param _spFactory - address for new ServiceProviderFactory contract
     */
    function setServiceProviderFactoryAddress(address _spFactory) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        serviceProviderFactoryAddress = _spFactory;
        emit ServiceProviderFactoryAddressUpdated(_spFactory);
    }

    /**
     * @notice Set the ClaimsManager address
     * @dev Only callable by Governance address
     * @param _claimsManagerAddress - address for new ClaimsManager contract
     */
    function setClaimsManagerAddress(address _claimsManagerAddress) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        claimsManagerAddress = _claimsManagerAddress;
        emit ClaimsManagerAddressUpdated(_claimsManagerAddress);
    }

    // ========================================= View Functions =========================================

    /**
     * @notice Get list of delegators for a given service provider
     * @param _sp - service provider address
     */
    function getDelegatorsList(address _sp)
    external view returns (address[] memory)
    {
        _requireIsInitialized();

        return spDelegateInfo[_sp].delegators;
    }

    /**
     * @notice Get total delegation from a given address
     * @param _delegator - delegator address
     */
    function getTotalDelegatorStake(address _delegator)
    external view returns (uint256)
    {
        _requireIsInitialized();

        return delegatorTotalStake[_delegator];
    }

    /// @notice Get total amount delegated to a service provider
    function getTotalDelegatedToServiceProvider(address _sp)
    external view returns (uint256)
    {
        _requireIsInitialized();

        return spDelegateInfo[_sp].totalDelegatedStake;
    }

    /// @notice Get total delegated stake locked up for a service provider
    function getTotalLockedDelegationForServiceProvider(address _sp)
    external view returns (uint256)
    {
        _requireIsInitialized();

        return spDelegateInfo[_sp].totalLockedUpStake;
    }

    /// @notice Get total currently staked for a delegator, for a given service provider
    function getDelegatorStakeForServiceProvider(address _delegator, address _serviceProvider)
    external view returns (uint256)
    {
        _requireIsInitialized();

        return delegateInfo[_delegator][_serviceProvider];
    }

    /**
     * @notice Get status of pending undelegate request for a given address
     * @param _delegator - address of the delegator
     */
    function getPendingUndelegateRequest(address _delegator)
    external view returns (address target, uint256 amount, uint256 lockupExpiryBlock)
    {
        _requireIsInitialized();

        UndelegateStakeRequest memory req = undelegateRequests[_delegator];
        return (req.serviceProvider, req.amount, req.lockupExpiryBlock);
    }

    /**
     * @notice Get status of pending remove delegator request for a given address
     * @param _serviceProvider - address of the service provider
     * @param _delegator - address of the delegator
     * @return - current lockup expiry block for remove delegator request
     */
    function getPendingRemoveDelegatorRequest(
        address _serviceProvider,
        address _delegator
    ) external view returns (uint256)
    {
        _requireIsInitialized();

        return removeDelegatorRequests[_serviceProvider][_delegator];
    }

    /// @notice Get current undelegate lockup duration
    function getUndelegateLockupDuration()
    external view returns (uint256)
    {
        _requireIsInitialized();

        return undelegateLockupDuration;
    }

    /// @notice Current maximum delegators
    function getMaxDelegators()
    external view returns (uint256)
    {
        _requireIsInitialized();

        return maxDelegators;
    }

    /// @notice Get minimum delegation amount
    function getMinDelegationAmount()
    external view returns (uint256)
    {
        _requireIsInitialized();

        return minDelegationAmount;
    }

    /// @notice Get the duration for remove delegator request lockup
    function getRemoveDelegatorLockupDuration()
    external view returns (uint256)
    {
        _requireIsInitialized();

        return removeDelegatorLockupDuration;
    }

    /// @notice Get the duration for evaluation of remove delegator operations
    function getRemoveDelegatorEvalDuration()
    external view returns (uint256)
    {
        _requireIsInitialized();

        return removeDelegatorEvalDuration;
    }

    /// @notice Get the Governance address
    function getGovernanceAddress() external view returns (address) {
        _requireIsInitialized();

        return governanceAddress;
    }

    /// @notice Get the ServiceProviderFactory address
    function getServiceProviderFactoryAddress() external view returns (address) {
        _requireIsInitialized();

        return serviceProviderFactoryAddress;
    }

    /// @notice Get the ClaimsManager address
    function getClaimsManagerAddress() external view returns (address) {
        _requireIsInitialized();

        return claimsManagerAddress;
    }

    /// @notice Get the Staking address
    function getStakingAddress() external view returns (address)
    {
        _requireIsInitialized();

        return stakingAddress;
    }

    // ========================================= Internal functions =========================================

    /**
     * @notice Helper function for claimRewards to get balances from Staking contract
               and do validation
     * @param spFactory - reference to ServiceProviderFactory contract
     * @param _serviceProvider - address for which rewards are being claimed
     * @return (totalBalanceInStaking, totalBalanceInSPFactory, totalActiveFunds, spLockedStake, totalRewards, deployerCut)
     */
    function _validateClaimRewards(ServiceProviderFactory spFactory, address _serviceProvider)
    internal returns (
        uint256 totalBalanceInStaking,
        uint256 totalBalanceInSPFactory,
        uint256 totalActiveFunds,
        uint256 totalRewards,
        uint256 deployerCut
    )
    {
        // Account for any pending locked up stake for the service provider
        (uint256 spLockedStake,) = spFactory.getPendingDecreaseStakeRequest(_serviceProvider);
        uint256 totalLockedUpStake = (
            spDelegateInfo[_serviceProvider].totalLockedUpStake.add(spLockedStake)
        );

        // Process claim for msg.sender
        // Total locked parameter is equal to delegate locked up stake + service provider locked up stake
        uint256 mintedRewards = ClaimsManager(claimsManagerAddress).processClaim(
            _serviceProvider,
            totalLockedUpStake
        );

        // Amount stored in staking contract for owner
        totalBalanceInStaking = Staking(stakingAddress).totalStakedFor(_serviceProvider);

        // Amount in sp factory for claimer
        (
            totalBalanceInSPFactory,
            deployerCut,
            ,,,
        ) = spFactory.getServiceProviderDetails(_serviceProvider);
        // Require active stake to claim any rewards

        // Amount in delegate manager staked to service provider
        uint256 totalBalanceOutsideStaking = (
            totalBalanceInSPFactory.add(spDelegateInfo[_serviceProvider].totalDelegatedStake)
        );

        totalActiveFunds = totalBalanceOutsideStaking.sub(totalLockedUpStake);

        require(
            mintedRewards == totalBalanceInStaking.sub(totalBalanceOutsideStaking),
            "DelegateManager: Reward amount mismatch"
        );

        // Emit claim event
        emit Claim(_serviceProvider, totalRewards, totalBalanceInStaking);

        return (
            totalBalanceInStaking,
            totalBalanceInSPFactory,
            totalActiveFunds,
            mintedRewards,
            deployerCut
        );
    }

    /**
     * @notice Perform state updates when a delegate stake has changed
     * @param _delegator - address of delegator
     * @param _serviceProvider - address of service provider
     * @param _totalServiceProviderDelegatedStake - total delegated to this service provider
     * @param _totalStakedForSpFromDelegator - total delegated to this service provider by delegator
     * @param _totalDelegatorStake - total delegated from this delegator address
     */
    function _updateDelegatorStake(
        address _delegator,
        address _serviceProvider,
        uint256 _totalServiceProviderDelegatedStake,
        uint256 _totalStakedForSpFromDelegator,
        uint256 _totalDelegatorStake
    ) internal
    {
        // Update total delegated for SP
        spDelegateInfo[_serviceProvider].totalDelegatedStake = _totalServiceProviderDelegatedStake;

        // Update amount staked from this delegator to targeted service provider
        delegateInfo[_delegator][_serviceProvider] = _totalStakedForSpFromDelegator;

        // Update total delegated from this delegator
        _updateDelegatorTotalStake(_delegator, _totalDelegatorStake);
    }

    /**
     * @notice Reset pending undelegate stake request
     * @param _delegator - address of delegator
     */
    function _resetUndelegateStakeRequest(address _delegator) internal
    {
        _updateUndelegateStakeRequest(_delegator, address(0), 0, 0);
    }

    /**
     * @notice Perform updates when undelegate request state has changed
     * @param _delegator - address of delegator
     * @param _serviceProvider - address of service provider
     * @param _amount - amount being undelegated
     * @param _lockupExpiryBlock - block at which stake can be undelegated
     */
    function _updateUndelegateStakeRequest(
        address _delegator,
        address _serviceProvider,
        uint256 _amount,
        uint256 _lockupExpiryBlock
    ) internal
    {
        // Update lockup information
        undelegateRequests[_delegator] = UndelegateStakeRequest({
            lockupExpiryBlock: _lockupExpiryBlock,
            amount: _amount,
            serviceProvider: _serviceProvider
        });
    }

    /**
     * @notice Update total amount delegated from an address
     * @param _delegator - address of service provider
     * @param _amount - updated delegator total
     */
    function _updateDelegatorTotalStake(address _delegator, uint256 _amount) internal
    {
        delegatorTotalStake[_delegator] = _amount;
    }

    /**
     * @notice Update amount currently locked up for this service provider
     * @param _serviceProvider - address of service provider
     * @param _updatedLockupAmount - updated lock up amount
     */
    function _updateServiceProviderLockupAmount(
        address _serviceProvider,
        uint256 _updatedLockupAmount
    ) internal
    {
        spDelegateInfo[_serviceProvider].totalLockedUpStake = _updatedLockupAmount;
    }

    function _removeFromDelegatorsList(address _serviceProvider, address _delegator) internal
    {
        for (uint256 i = 0; i < spDelegateInfo[_serviceProvider].delegators.length; i++) {
            if (spDelegateInfo[_serviceProvider].delegators[i] == _delegator) {
                // Overwrite and shrink delegators list
                spDelegateInfo[_serviceProvider].delegators[i] = spDelegateInfo[_serviceProvider].delegators[spDelegateInfo[_serviceProvider].delegators.length - 1];
                spDelegateInfo[_serviceProvider].delegators.length--;
                break;
            }
        }
    }

    /**
     * @notice Helper function to distribute rewards to any delegators
     * @param _sp - service provider account tracked in staking
     * @param _totalActiveFunds - total funds minus any locked stake
     * @param _totalRewards - total rewaards generated in this round
     * @param _deployerCut - service provider cut of delegate rewards, defined as deployerCut / deployerCutBase
     * @param _deployerCutBase - denominator value for calculating service provider cut as a %
     * @return (totalBalanceInStaking, totalBalanceInSPFactory, totalBalanceOutsideStaking)
     */
    function _distributeDelegateRewards(
        address _sp,
        uint256 _totalActiveFunds,
        uint256 _totalRewards,
        uint256 _deployerCut,
        uint256 _deployerCutBase
    )
    internal returns (uint256 totalDelegatedStakeIncrease)
    {
        // Traverse all delegates and calculate their rewards
        // As each delegate reward is calculated, increment SP cut reward accordingly
        for (uint256 i = 0; i < spDelegateInfo[_sp].delegators.length; i++) {
            address delegator = spDelegateInfo[_sp].delegators[i];
            uint256 delegateStakeToSP = delegateInfo[delegator][_sp];

            // Subtract any locked up stake
            if (undelegateRequests[delegator].serviceProvider == _sp) {
                delegateStakeToSP = delegateStakeToSP.sub(undelegateRequests[delegator].amount);
            }

            // Calculate rewards by ((delegateStakeToSP / totalActiveFunds) * totalRewards)
            uint256 rewardsPriorToSPCut = (
              delegateStakeToSP.mul(_totalRewards)
            ).div(_totalActiveFunds);

            // Multiply by deployer cut fraction to calculate reward for SP
            // Operation constructed to perform all multiplication prior to division
            // uint256 spDeployerCut = (rewardsPriorToSPCut * deployerCut ) / (deployerCutBase);
            //                    = ((delegateStakeToSP * totalRewards) / totalActiveFunds) * deployerCut ) / (deployerCutBase);
            //                    = ((delegateStakeToSP * totalRewards * deployerCut) / totalActiveFunds ) / (deployerCutBase);
            //                    = (delegateStakeToSP * totalRewards * deployerCut) / (deployerCutBase * totalActiveFunds);
            uint256 spDeployerCut = (
                (delegateStakeToSP.mul(_totalRewards)).mul(_deployerCut)
            ).div(
                _totalActiveFunds.mul(_deployerCutBase)
            );
            // Increase total delegate reward in DelegateManager
            // Subtract SP reward from rewards to calculate delegate reward
            // delegateReward = rewardsPriorToSPCut - spDeployerCut;
            delegateInfo[delegator][_sp] = (
                delegateInfo[delegator][_sp].add(rewardsPriorToSPCut.sub(spDeployerCut))
            );

            // Update total for this delegator
            _updateDelegatorTotalStake(
                delegator,
                delegatorTotalStake[delegator].add(rewardsPriorToSPCut.sub(spDeployerCut))
            );

            totalDelegatedStakeIncrease = (
                totalDelegatedStakeIncrease.add(rewardsPriorToSPCut.sub(spDeployerCut))
            );
        }

        return (totalDelegatedStakeIncrease);
    }

    /**
     * @notice Set the governance address after confirming contract identity
     * @param _governanceAddress - Incoming governance address
     */
    function _updateGovernanceAddress(address _governanceAddress) internal {
        require(
            Governance(_governanceAddress).isGovernanceAddress() == true,
            "DelegateManager: _governanceAddress is not a valid governance contract"
        );
        governanceAddress = _governanceAddress;
    }

    /**
     * @notice Set the remove delegator lockup duration after validating against governance
     * @param _duration - Incoming remove delegator duration value
     */
    function _updateRemoveDelegatorLockupDuration(uint256 _duration) internal {
        Governance governance = Governance(governanceAddress);
        require(
            _duration > governance.getVotingPeriod() + governance.getExecutionDelay(),
            "DelegateManager: removeDelegatorLockupDuration duration must be greater than governance votingPeriod + executionDelay"
        );
        removeDelegatorLockupDuration = _duration;
    }

    /**
     * @notice Set the undelegate lockup duration after validating against governance
     * @param _duration - Incoming undelegate lockup duration value
     */
    function _updateUndelegateLockupDuration(uint256 _duration) internal {
        Governance governance = Governance(governanceAddress);
        require(
            _duration > governance.getVotingPeriod() + governance.getExecutionDelay(),
            "DelegateManager: undelegateLockupDuration duration must be greater than governance votingPeriod + executionDelay"
        );
        undelegateLockupDuration = _duration;
    }

    /**
     * @notice Returns if delegator has delegated to a service provider
     * @param _delegator - address of delegator
     * @param _serviceProvider - address of service provider
     * @return boolean indicating whether delegator exists for service provider
     */
    function _delegatorExistsForSP(
        address _delegator,
        address _serviceProvider
    ) internal view returns (bool)
    {
        for (uint256 i = 0; i < spDelegateInfo[_serviceProvider].delegators.length; i++) {
            if (spDelegateInfo[_serviceProvider].delegators[i] == _delegator) {
                return true;
            }
        }
        // Not found
        return false;
    }

    /**
     * @notice Determine if a claim is pending for this service provider
     * @param _sp - address of service provider
     * @return boolean indicating whether a claim is pending
     */
    function _claimPending(address _sp) internal view returns (bool) {
        ClaimsManager claimsManager = ClaimsManager(claimsManagerAddress);
        return claimsManager.claimPending(_sp);
    }

    /**
     * @notice Determine if a decrease request has been initiated
     * @param _delegator - address of delegator
     * @return boolean indicating whether a decrease request is pending
     */
    function _undelegateRequestIsPending(address _delegator) internal view returns (bool)
    {
        return (
            (undelegateRequests[_delegator].lockupExpiryBlock != 0) &&
            (undelegateRequests[_delegator].amount != 0) &&
            (undelegateRequests[_delegator].serviceProvider != address(0))
        );
    }

    // ========================================= Private Functions =========================================

    function _requireStakingAddressIsSet() private view {
        require(
            stakingAddress != address(0x00),
            "DelegateManager: stakingAddress is not set"
        );
    }

    function _requireServiceProviderFactoryAddressIsSet() private view {
        require(
            serviceProviderFactoryAddress != address(0x00),
            "DelegateManager: serviceProviderFactoryAddress is not set"
        );
    }

    function _requireClaimsManagerAddressIsSet() private view {
        require(
            claimsManagerAddress != address(0x00),
            "DelegateManager: claimsManagerAddress is not set"
        );
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

// File: contracts/registry/Registry.sol

pragma solidity ^0.5.0;





/**
* @title Central hub for Audius protocol. It stores all contract addresses to facilitate
*   external access and enable version management.
*/
contract Registry is InitializableV2, Ownable {
    using SafeMath for uint256;

    /**
     * @dev addressStorage mapping allows efficient lookup of current contract version
     *      addressStorageHistory maintains record of all contract versions
     */
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => address[]) private addressStorageHistory;

    event ContractAdded(
        bytes32 indexed _name,
        address indexed _address
    );

    event ContractRemoved(
        bytes32 indexed _name,
        address indexed _address
    );

    event ContractUpgraded(
        bytes32 indexed _name,
        address indexed _oldAddress,
        address indexed _newAddress
    );

    function initialize() public initializer {
        /// @notice Ownable.initialize(address _sender) sets contract owner to _sender.
        Ownable.initialize(msg.sender);
        InitializableV2.initialize();
    }

    // ========================================= Setters =========================================

    /**
     * @notice addContract registers contract name to address mapping under given registry key
     * @param _name - registry key that will be used for lookups
     * @param _address - address of contract
     */
    function addContract(bytes32 _name, address _address) external onlyOwner {
        _requireIsInitialized();

        require(
            addressStorage[_name] == address(0x00),
            "Registry: Contract already registered with given name."
        );
        require(
            _address != address(0x00),
            "Registry: Cannot register zero address."
        );

        setAddress(_name, _address);

        emit ContractAdded(_name, _address);
    }

    /**
     * @notice removes contract address registered under given registry key
     * @param _name - registry key for lookup
     */
    function removeContract(bytes32 _name) external onlyOwner {
        _requireIsInitialized();

        address contractAddress = addressStorage[_name];
        require(
            contractAddress != address(0x00),
            "Registry: Cannot remove - no contract registered with given _name."
        );

        setAddress(_name, address(0x00));

        emit ContractRemoved(_name, contractAddress);
    }

    /**
     * @notice replaces contract address registered under given key with provided address
     * @param _name - registry key for lookup
     * @param _newAddress - new contract address to register under given key
     */
    function upgradeContract(bytes32 _name, address _newAddress) external onlyOwner {
        _requireIsInitialized();

        address oldAddress = addressStorage[_name];
        require(
            oldAddress != address(0x00),
            "Registry: Cannot upgrade - no contract registered with given _name."
        );
        require(
            _newAddress != address(0x00),
            "Registry: Cannot upgrade - cannot register zero address."
        );

        setAddress(_name, _newAddress);

        emit ContractUpgraded(_name, oldAddress, _newAddress);
    }

    // ========================================= Getters =========================================

    /**
     * @notice returns contract address registered under given registry key
     * @param _name - registry key for lookup
     * @return contractAddr - address of contract registered under given registry key
     */
    function getContract(bytes32 _name) external view returns (address contractAddr) {
        _requireIsInitialized();

        return addressStorage[_name];
    }

    /// @notice overloaded getContract to return explicit version of contract
    function getContract(bytes32 _name, uint256 _version) external view
    returns (address contractAddr)
    {
        _requireIsInitialized();

        // array length for key implies version number
        require(
            _version <= addressStorageHistory[_name].length,
            "Registry: Index out of range _version."
        );
        return addressStorageHistory[_name][_version.sub(1)];
    }

    /**
     * @notice Returns the number of versions for a contract key
     * @param _name - registry key for lookup
     * @return number of contract versions
     */
    function getContractVersionCount(bytes32 _name) external view returns (uint256) {
        _requireIsInitialized();

        return addressStorageHistory[_name].length;
    }

    // ========================================= Private functions =========================================

    /**
     * @param _key the key for the contract address
     * @param _value the contract address
     */
    function setAddress(bytes32 _key, address _value) private {
        // main map for cheap lookup
        addressStorage[_key] = _value;
        // keep track of contract address history
        addressStorageHistory[_key].push(_value);
    }

}

// File: contracts/Governance.sol

pragma solidity ^0.5.0;







contract Governance is InitializableV2 {
    using SafeMath for uint256;

    string private constant ERROR_ONLY_GOVERNANCE = (
        "Governance: Only callable by self"
    );
    string private constant ERROR_INVALID_VOTING_PERIOD = (
        "Governance: Requires non-zero _votingPeriod"
    );
    string private constant ERROR_INVALID_REGISTRY = (
        "Governance: Requires non-zero _registryAddress"
    );
    string private constant ERROR_INVALID_VOTING_QUORUM = (
        "Governance: Requires _votingQuorumPercent between 1 & 100"
    );

    /**
     * @notice Address and contract instance of Audius Registry. Used to ensure this contract
     *      can only govern contracts that are registered in the Audius Registry.
     */
    Registry private registry;

    /// @notice Address of Audius staking contract, used to permission Governance method calls
    address private stakingAddress;

    /// @notice Address of Audius ServiceProvider contract, used to permission Governance method calls
    address private serviceProviderFactoryAddress;

    /// @notice Address of Audius DelegateManager contract, used to permission Governance method calls
    address private delegateManagerAddress;

    /// @notice Period in blocks for which a governance proposal is open for voting
    uint256 private votingPeriod;

    /// @notice Number of blocks that must pass after votingPeriod has expired before proposal can be evaluated/executed
    uint256 private executionDelay;

    /// @notice Required minimum percentage of total stake to have voted to consider a proposal valid
    ///         Percentaged stored as a uint256 between 0 & 100
    ///         Calculated as: 100 * sum of voter stakes / total staked in Staking (at proposal submission block)
    uint256 private votingQuorumPercent;

    /// @notice Max number of InProgress proposals possible at once
    /// @dev uint16 gives max possible value of 65,535
    uint16 private maxInProgressProposals;

    /**
     * @notice Address of account that has special Governance permissions. Can veto proposals
     *      and execute transactions directly on contracts.
     */
    address private guardianAddress;

    /***** Enums *****/

    /**
     * @notice All Proposal Outcome states.
     *      InProgress - Proposal is active and can be voted on.
     *      Rejected - Proposal votingPeriod has closed and vote failed to pass. Proposal will not be executed.
     *      ApprovedExecuted - Proposal votingPeriod has closed and vote passed. Proposal was successfully executed.
     *      QuorumNotMet - Proposal votingPeriod has closed and votingQuorumPercent was not met. Proposal will not be executed.
     *      ApprovedExecutionFailed - Proposal vote passed, but transaction execution failed.
     *      Evaluating - Proposal vote passed, and evaluateProposalOutcome function is currently running.
     *          This status is transiently used inside that function to prevent re-entrancy.
     *      Vetoed - Proposal was vetoed by Guardian.
     *      TargetContractAddressChanged - Proposal considered invalid since target contract address changed
     *      TargetContractCodeHashChanged - Proposal considered invalid since code has at target contract address has changed
     */
    enum Outcome {
        InProgress,
        Rejected,
        ApprovedExecuted,
        QuorumNotMet,
        ApprovedExecutionFailed,
        Evaluating,
        Vetoed,
        TargetContractAddressChanged,
        TargetContractCodeHashChanged
    }

    /**
     * @notice All Proposal Vote states for a voter.
     *      None - The default state, for any account that has not previously voted on this Proposal.
     *      No - The account voted No on this Proposal.
     *      Yes - The account voted Yes on this Proposal.
     * @dev Enum values map to uints, so first value in Enum always is 0.
     */
    enum Vote {None, No, Yes}

    struct Proposal {
        uint256 proposalId;
        address proposer;
        uint256 submissionBlockNumber;
        bytes32 targetContractRegistryKey;
        address targetContractAddress;
        uint256 callValue;
        string functionSignature;
        bytes callData;
        Outcome outcome;
        uint256 voteMagnitudeYes;
        uint256 voteMagnitudeNo;
        uint256 numVotes;
        mapping(address => Vote) votes;
        mapping(address => uint256) voteMagnitudes;
        bytes32 contractHash;
    }

    /***** Proposal storage *****/

    /// @notice ID of most recently created proposal. Ids are monotonically increasing and 1-indexed.
    uint256 lastProposalId = 0;

    /// @notice mapping of proposalId to Proposal struct with all proposal state
    mapping(uint256 => Proposal) proposals;

    /// @notice array of proposals with InProgress state
    uint256[] inProgressProposals;


    /***** Events *****/
    event ProposalSubmitted(
        uint256 indexed _proposalId,
        address indexed _proposer,
        string _name,
        string _description
    );
    event ProposalVoteSubmitted(
        uint256 indexed _proposalId,
        address indexed _voter,
        Vote indexed _vote,
        uint256 _voterStake
    );
    event ProposalVoteUpdated(
        uint256 indexed _proposalId,
        address indexed _voter,
        Vote indexed _vote,
        uint256 _voterStake,
        Vote _previousVote
    );
    event ProposalOutcomeEvaluated(
        uint256 indexed _proposalId,
        Outcome indexed _outcome,
        uint256 _voteMagnitudeYes,
        uint256 _voteMagnitudeNo,
        uint256 _numVotes
    );
    event ProposalTransactionExecuted(
        uint256 indexed _proposalId,
        bool indexed _success,
        bytes _returnData
    );
    event GuardianTransactionExecuted(
        address indexed _targetContractAddress,
        uint256 _callValue,
        string indexed _functionSignature,
        bytes indexed _callData,
        bytes _returnData
    );
    event ProposalVetoed(uint256 indexed _proposalId);
    event RegistryAddressUpdated(address indexed _newRegistryAddress);
    event GuardianshipTransferred(address indexed _newGuardianAddress);
    event VotingPeriodUpdated(uint256 indexed _newVotingPeriod);
    event ExecutionDelayUpdated(uint256 indexed _newExecutionDelay);
    event VotingQuorumPercentUpdated(uint256 indexed _newVotingQuorumPercent);
    event MaxInProgressProposalsUpdated(uint256 indexed _newMaxInProgressProposals);

    /**
     * @notice Initialize the Governance contract
     * @dev _votingPeriod <= DelegateManager.undelegateLockupDuration
     * @dev stakingAddress must be initialized separately after Staking contract is deployed
     * @param _registryAddress - address of the registry proxy contract
     * @param _votingPeriod - period in blocks for which a governance proposal is open for voting
     * @param _executionDelay - number of blocks that must pass after votingPeriod has expired before proposal can be evaluated/executed
     * @param _votingQuorumPercent - required minimum percentage of total stake to have voted to consider a proposal valid
     * @param _maxInProgressProposals - max number of InProgress proposals possible at once
     * @param _guardianAddress - address of account that has special Governance permissions
     */
    function initialize(
        address _registryAddress,
        uint256 _votingPeriod,
        uint256 _executionDelay,
        uint256 _votingQuorumPercent,
        uint16 _maxInProgressProposals,
        address _guardianAddress
    ) public initializer {
        require(_registryAddress != address(0x00), ERROR_INVALID_REGISTRY);
        registry = Registry(_registryAddress);

        require(_votingPeriod > 0, ERROR_INVALID_VOTING_PERIOD);
        votingPeriod = _votingPeriod;

        // executionDelay does not have to be non-zero
        executionDelay = _executionDelay;

        require(
            _maxInProgressProposals > 0,
            "Governance: Requires non-zero _maxInProgressProposals"
        );
        maxInProgressProposals = _maxInProgressProposals;

        require(
            _votingQuorumPercent > 0 && _votingQuorumPercent <= 100,
            ERROR_INVALID_VOTING_QUORUM
        );
        votingQuorumPercent = _votingQuorumPercent;

        require(
            _guardianAddress != address(0x00),
            "Governance: Requires non-zero _guardianAddress"
        );
        guardianAddress = _guardianAddress;  //Guardian address becomes the only party

        InitializableV2.initialize();
    }

    // ========================================= Governance Actions =========================================

    /**
     * @notice Submit a proposal for vote. Only callable by addresses with non-zero total active stake.
     *      total active stake = total active deployer stake + total active delegator stake
     *
     * @dev _name and _description length is not enforced since they aren't stored on-chain and only event emitted
     *
     * @param _targetContractRegistryKey - Registry key for the contract concerning this proposal
     * @param _callValue - amount of wei to pass with function call if a token transfer is involved
     * @param _functionSignature - function signature of the function to be executed if proposal is successful
     * @param _callData - encoded value(s) to call function with if proposal is successful
     * @param _name - Text name of proposal to be emitted in event
     * @param _description - Text description of proposal to be emitted in event
     *
     * @return - ID of new proposal
     */
    function submitProposal(
        bytes32 _targetContractRegistryKey,
        uint256 _callValue,
        string calldata _functionSignature,
        bytes calldata _callData,
        string calldata _name,
        string calldata _description
    ) external returns (uint256)
    {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireServiceProviderFactoryAddressIsSet();
        _requireDelegateManagerAddressIsSet();

        address proposer = msg.sender;

        // Require all InProgress proposals that can be evaluated have been evaluated before new proposal submission
        require(
            this.inProgressProposalsAreUpToDate(),
            "Governance: Cannot submit new proposal until all evaluatable InProgress proposals are evaluated."
        );

        // Require new proposal submission would not push number of InProgress proposals over max number
        require(
            inProgressProposals.length < maxInProgressProposals,
            "Governance: Number of InProgress proposals already at max. Please evaluate if possible, or wait for current proposals' votingPeriods to expire."
        );

        // Require proposer has non-zero total active stake or is guardian address
        require(
            _calculateAddressActiveStake(proposer) > 0 || proposer == guardianAddress,
            "Governance: Proposer must be address with non-zero total active stake or be guardianAddress."
        );

        // Require _targetContractRegistryKey points to a valid registered contract
        address targetContractAddress = registry.getContract(_targetContractRegistryKey);
        require(
            targetContractAddress != address(0x00),
            "Governance: _targetContractRegistryKey must point to valid registered contract"
        );

        // Signature cannot be empty
        require(
            bytes(_functionSignature).length != 0,
            "Governance: _functionSignature cannot be empty."
        );

        // Require non-zero description length
        require(bytes(_description).length > 0, "Governance: _description length must be > 0");

        // Require non-zero name length
        require(bytes(_name).length > 0, "Governance: _name length must be > 0");

        // set proposalId
        uint256 newProposalId = lastProposalId.add(1);

        // Store new Proposal obj in proposals mapping
        proposals[newProposalId] = Proposal({
            proposalId: newProposalId,
            proposer: proposer,
            submissionBlockNumber: block.number,
            targetContractRegistryKey: _targetContractRegistryKey,
            targetContractAddress: targetContractAddress,
            callValue: _callValue,
            functionSignature: _functionSignature,
            callData: _callData,
            outcome: Outcome.InProgress,
            voteMagnitudeYes: 0,
            voteMagnitudeNo: 0,
            numVotes: 0,
            contractHash: _getCodeHash(targetContractAddress)
            /* votes: mappings are auto-initialized to default state */
            /* voteMagnitudes: mappings are auto-initialized to default state */
        });

        // Append new proposalId to inProgressProposals array
        inProgressProposals.push(newProposalId);

        emit ProposalSubmitted(
            newProposalId,
            proposer,
            _name,
            _description
        );

        lastProposalId = newProposalId;

        return newProposalId;
    }

    /**
     * @notice Vote on an active Proposal. Only callable by addresses with non-zero active stake.
     * @param _proposalId - id of the proposal this vote is for
     * @param _vote - can be either {Yes, No} from Vote enum. No other values allowed
     */
    function submitVote(uint256 _proposalId, Vote _vote) external {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireServiceProviderFactoryAddressIsSet();
        _requireDelegateManagerAddressIsSet();
        _requireValidProposalId(_proposalId);

        address voter = msg.sender;

        // Require proposal votingPeriod is still active
        uint256 submissionBlockNumber = proposals[_proposalId].submissionBlockNumber;
        uint256 endBlockNumber = submissionBlockNumber.add(votingPeriod);
        require(
            block.number > submissionBlockNumber && block.number <= endBlockNumber,
            "Governance: Proposal votingPeriod has ended"
        );

        // Require voter has non-zero total active stake
        uint256 voterActiveStake = _calculateAddressActiveStake(voter);
        require(
            voterActiveStake > 0,
            "Governance: Voter must be address with non-zero total active stake."
        );

        // Require previous vote is None
        require(
            proposals[_proposalId].votes[voter] == Vote.None,
            "Governance: To update previous vote, call updateVote()"
        );

        // Require vote is either Yes or No
        require(
            _vote == Vote.Yes || _vote == Vote.No,
            "Governance: Can only submit a Yes or No vote"
        );

        // Record vote
        proposals[_proposalId].votes[voter] = _vote;

        // Record voteMagnitude for voter
        proposals[_proposalId].voteMagnitudes[voter] = voterActiveStake;

        // Update proposal cumulative vote magnitudes
        if (_vote == Vote.Yes) {
            _increaseVoteMagnitudeYes(_proposalId, voterActiveStake);
        } else {
            _increaseVoteMagnitudeNo(_proposalId, voterActiveStake);
        }

        // Increment proposal numVotes
        proposals[_proposalId].numVotes = proposals[_proposalId].numVotes.add(1);

        emit ProposalVoteSubmitted(
            _proposalId,
            voter,
            _vote,
            voterActiveStake
        );
    }

    /**
     * @notice Update previous vote on an active Proposal. Only callable by addresses with non-zero active stake.
     * @param _proposalId - id of the proposal this vote is for
     * @param _vote - can be either {Yes, No} from Vote enum. No other values allowed
     */
    function updateVote(uint256 _proposalId, Vote _vote) external {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireServiceProviderFactoryAddressIsSet();
        _requireDelegateManagerAddressIsSet();
        _requireValidProposalId(_proposalId);

        address voter = msg.sender;

        // Require proposal votingPeriod is still active
        uint256 submissionBlockNumber = proposals[_proposalId].submissionBlockNumber;
        uint256 endBlockNumber = submissionBlockNumber.add(votingPeriod);
        require(
            block.number > submissionBlockNumber && block.number <= endBlockNumber,
            "Governance: Proposal votingPeriod has ended"
        );

        // Retrieve previous vote
        Vote previousVote = proposals[_proposalId].votes[voter];

        // Require previous vote is not None
        require(
            previousVote != Vote.None,
            "Governance: To submit new vote, call submitVote()"
        );

        // Require vote is either Yes or No
        require(
            _vote == Vote.Yes || _vote == Vote.No,
            "Governance: Can only submit a Yes or No vote"
        );

        // Record updated vote
        proposals[_proposalId].votes[voter] = _vote;

        // Update vote magnitudes, using vote magnitude from when previous vote was submitted
        uint256 voteMagnitude = proposals[_proposalId].voteMagnitudes[voter];
        if (previousVote == Vote.Yes && _vote == Vote.No) {
            _decreaseVoteMagnitudeYes(_proposalId, voteMagnitude);
            _increaseVoteMagnitudeNo(_proposalId, voteMagnitude);
        } else if (previousVote == Vote.No && _vote == Vote.Yes) {
            _decreaseVoteMagnitudeNo(_proposalId, voteMagnitude);
            _increaseVoteMagnitudeYes(_proposalId, voteMagnitude);
        }
        // If _vote == previousVote, no changes needed to vote magnitudes.

        // Do not update numVotes

        emit ProposalVoteUpdated(
            _proposalId,
            voter,
            _vote,
            voteMagnitude,
            previousVote
        );
    }

    /**
     * @notice Once the voting period + executionDelay for a proposal has ended, evaluate the outcome and
     *      execute the proposal if voting quorum met & vote passes.
     *      To pass, stake-weighted vote must be > 50% Yes.
     * @dev Requires that caller is an active staker at the time the proposal is created
     * @param _proposalId - id of the proposal
     * @return Outcome of proposal evaluation
     */
    function evaluateProposalOutcome(uint256 _proposalId)
    external returns (Outcome)
    {
        _requireIsInitialized();
        _requireStakingAddressIsSet();
        _requireServiceProviderFactoryAddressIsSet();
        _requireDelegateManagerAddressIsSet();
        _requireValidProposalId(_proposalId);

        // Require proposal has not already been evaluated.
        require(
            proposals[_proposalId].outcome == Outcome.InProgress,
            "Governance: Can only evaluate InProgress proposal."
        );

        // Re-entrancy should not be possible here since this switches the status of the
        // proposal to 'Evaluating' so it should fail the status is 'InProgress' check
        proposals[_proposalId].outcome = Outcome.Evaluating;

        // Require proposal votingPeriod + executionDelay have ended.
        uint256 submissionBlockNumber = proposals[_proposalId].submissionBlockNumber;
        uint256 endBlockNumber = submissionBlockNumber.add(votingPeriod).add(executionDelay);
        require(
            block.number > endBlockNumber,
            "Governance: Proposal votingPeriod & executionDelay must end before evaluation."
        );

        address targetContractAddress = registry.getContract(
            proposals[_proposalId].targetContractRegistryKey
        );

        Outcome outcome;

        // target contract address changed -> close proposal without execution.
        if (targetContractAddress != proposals[_proposalId].targetContractAddress) {
            outcome = Outcome.TargetContractAddressChanged;
        }
        // target contract code hash changed -> close proposal without execution.
        else if (_getCodeHash(targetContractAddress) != proposals[_proposalId].contractHash) {
            outcome = Outcome.TargetContractCodeHashChanged;
        }
        // voting quorum not met -> close proposal without execution.
        else if (_quorumMet(proposals[_proposalId], Staking(stakingAddress)) == false) {
            outcome = Outcome.QuorumNotMet;
        }
        // votingQuorumPercent met & vote passed -> execute proposed transaction & close proposal.
        else if (
            proposals[_proposalId].voteMagnitudeYes > proposals[_proposalId].voteMagnitudeNo
        ) {
            (bool success, bytes memory returnData) = _executeTransaction(
                targetContractAddress,
                proposals[_proposalId].callValue,
                proposals[_proposalId].functionSignature,
                proposals[_proposalId].callData
            );

            emit ProposalTransactionExecuted(
                _proposalId,
                success,
                returnData
            );

            // Proposal outcome depends on success of transaction execution.
            if (success) {
                outcome = Outcome.ApprovedExecuted;
            } else {
                outcome = Outcome.ApprovedExecutionFailed;
            }
        }
        // votingQuorumPercent met & vote did not pass -> close proposal without transaction execution.
        else {
            outcome = Outcome.Rejected;
        }

        // This records the final outcome in the proposals mapping
        proposals[_proposalId].outcome = outcome;

        // Remove from inProgressProposals array
        _removeFromInProgressProposals(_proposalId);

        emit ProposalOutcomeEvaluated(
            _proposalId,
            outcome,
            proposals[_proposalId].voteMagnitudeYes,
            proposals[_proposalId].voteMagnitudeNo,
            proposals[_proposalId].numVotes
        );

        return outcome;
    }

    /**
     * @notice Action limited to the guardian address that can veto a proposal
     * @param _proposalId - id of the proposal
     */
    function vetoProposal(uint256 _proposalId) external {
        _requireIsInitialized();
        _requireValidProposalId(_proposalId);

        require(
            msg.sender == guardianAddress,
            "Governance: Only guardian can veto proposals."
        );

        require(
            proposals[_proposalId].outcome == Outcome.InProgress,
            "Governance: Cannot veto inactive proposal."
        );

        proposals[_proposalId].outcome = Outcome.Vetoed;

        // Remove from inProgressProposals array
        _removeFromInProgressProposals(_proposalId);

        emit ProposalVetoed(_proposalId);
    }

    // ========================================= Config Setters =========================================

    /**
     * @notice Set the Staking address
     * @dev Only callable by self via _executeTransaction
     * @param _stakingAddress - address for new Staking contract
     */
    function setStakingAddress(address _stakingAddress) external {
        _requireIsInitialized();

        require(msg.sender == address(this), ERROR_ONLY_GOVERNANCE);
        require(_stakingAddress != address(0x00), "Governance: Requires non-zero _stakingAddress");
        stakingAddress = _stakingAddress;
    }

    /**
     * @notice Set the ServiceProviderFactory address
     * @dev Only callable by self via _executeTransaction
     * @param _serviceProviderFactoryAddress - address for new ServiceProviderFactory contract
     */
    function setServiceProviderFactoryAddress(address _serviceProviderFactoryAddress) external {
        _requireIsInitialized();

        require(msg.sender == address(this), ERROR_ONLY_GOVERNANCE);
        require(
            _serviceProviderFactoryAddress != address(0x00),
            "Governance: Requires non-zero _serviceProviderFactoryAddress"
        );
        serviceProviderFactoryAddress = _serviceProviderFactoryAddress;
    }

    /**
     * @notice Set the DelegateManager address
     * @dev Only callable by self via _executeTransaction
     * @param _delegateManagerAddress - address for new DelegateManager contract
     */
    function setDelegateManagerAddress(address _delegateManagerAddress) external {
        _requireIsInitialized();

        require(msg.sender == address(this), ERROR_ONLY_GOVERNANCE);
        require(
            _delegateManagerAddress != address(0x00),
            "Governance: Requires non-zero _delegateManagerAddress"
        );
        delegateManagerAddress = _delegateManagerAddress;
    }

    /**
     * @notice Set the voting period for a Governance proposal
     * @dev Only callable by self via _executeTransaction
     * @param _votingPeriod - new voting period
     */
    function setVotingPeriod(uint256 _votingPeriod) external {
        _requireIsInitialized();

        require(msg.sender == address(this), ERROR_ONLY_GOVERNANCE);
        require(_votingPeriod > 0, ERROR_INVALID_VOTING_PERIOD);
        votingPeriod = _votingPeriod;
        emit VotingPeriodUpdated(_votingPeriod);
    }

    /**
     * @notice Set the voting quorum percentage for a Governance proposal
     * @dev Only callable by self via _executeTransaction
     * @param _votingQuorumPercent - new voting period
     */
    function setVotingQuorumPercent(uint256 _votingQuorumPercent) external {
        _requireIsInitialized();

        require(msg.sender == address(this), ERROR_ONLY_GOVERNANCE);
        require(
            _votingQuorumPercent > 0 && _votingQuorumPercent <= 100,
            ERROR_INVALID_VOTING_QUORUM
        );
        votingQuorumPercent = _votingQuorumPercent;
        emit VotingQuorumPercentUpdated(_votingQuorumPercent);
    }

    /**
     * @notice Set the Registry address
     * @dev Only callable by self via _executeTransaction
     * @param _registryAddress - address for new Registry contract
     */
    function setRegistryAddress(address _registryAddress) external {
        _requireIsInitialized();

        require(msg.sender == address(this), ERROR_ONLY_GOVERNANCE);
        require(_registryAddress != address(0x00), ERROR_INVALID_REGISTRY);

        registry = Registry(_registryAddress);

        emit RegistryAddressUpdated(_registryAddress);
    }

    /**
     * @notice Set the max number of concurrent InProgress proposals
     * @dev Only callable by self via _executeTransaction
     * @param _newMaxInProgressProposals - new value for maxInProgressProposals
     */
    function setMaxInProgressProposals(uint16 _newMaxInProgressProposals) external {
        _requireIsInitialized();

        require(msg.sender == address(this), ERROR_ONLY_GOVERNANCE);
        require(
            _newMaxInProgressProposals > 0,
            "Governance: Requires non-zero _newMaxInProgressProposals"
        );
        maxInProgressProposals = _newMaxInProgressProposals;
        emit MaxInProgressProposalsUpdated(_newMaxInProgressProposals);
    }

    /**
     * @notice Set the execution delay for a proposal
     * @dev Only callable by self via _executeTransaction
     * @param _newExecutionDelay - new value for executionDelay
     */
    function setExecutionDelay(uint256 _newExecutionDelay) external {
        _requireIsInitialized();

        require(msg.sender == address(this), ERROR_ONLY_GOVERNANCE);
        // executionDelay does not have to be non-zero
        executionDelay = _newExecutionDelay;
        emit ExecutionDelayUpdated(_newExecutionDelay);
    }

    // ========================================= Guardian Actions =========================================

    /**
     * @notice Allows the guardianAddress to execute protocol actions
     * @param _targetContractRegistryKey - key in registry of target contract
     * @param _callValue - amount of wei if a token transfer is involved
     * @param _functionSignature - function signature of the function to be executed if proposal is successful
     * @param _callData - encoded value(s) to call function with if proposal is successful
     */
    function guardianExecuteTransaction(
        bytes32 _targetContractRegistryKey,
        uint256 _callValue,
        string calldata _functionSignature,
        bytes calldata _callData
    ) external
    {
        _requireIsInitialized();

        require(
            msg.sender == guardianAddress,
            "Governance: Only guardian."
        );

        // _targetContractRegistryKey must point to a valid registered contract
        address targetContractAddress = registry.getContract(_targetContractRegistryKey);
        require(
            targetContractAddress != address(0x00),
            "Governance: _targetContractRegistryKey must point to valid registered contract"
        );

        // Signature cannot be empty
        require(
            bytes(_functionSignature).length != 0,
            "Governance: _functionSignature cannot be empty."
        );

        (bool success, bytes memory returnData) = _executeTransaction(
            targetContractAddress,
            _callValue,
            _functionSignature,
            _callData
        );

        require(success, "Governance: Transaction failed.");

        emit GuardianTransactionExecuted(
            targetContractAddress,
            _callValue,
            _functionSignature,
            _callData,
            returnData
        );
    }

    /**
     * @notice Change the guardian address
     * @dev Only callable by current guardian
     * @param _newGuardianAddress - new guardian address
     */
    function transferGuardianship(address _newGuardianAddress) external {
        _requireIsInitialized();

        require(
            msg.sender == guardianAddress,
            "Governance: Only guardian."
        );

        guardianAddress = _newGuardianAddress;

        emit GuardianshipTransferred(_newGuardianAddress);
    }

    // ========================================= Getter Functions =========================================

    /**
     * @notice Get proposal information by proposal Id
     * @param _proposalId - id of proposal
     */
    function getProposalById(uint256 _proposalId)
    external view returns (
        uint256 proposalId,
        address proposer,
        uint256 submissionBlockNumber,
        bytes32 targetContractRegistryKey,
        address targetContractAddress,
        uint256 callValue,
        string memory functionSignature,
        bytes memory callData,
        Outcome outcome,
        uint256 voteMagnitudeYes,
        uint256 voteMagnitudeNo,
        uint256 numVotes
    )
    {
        _requireIsInitialized();
        _requireValidProposalId(_proposalId);

        Proposal memory proposal = proposals[_proposalId];
        return (
            proposal.proposalId,
            proposal.proposer,
            proposal.submissionBlockNumber,
            proposal.targetContractRegistryKey,
            proposal.targetContractAddress,
            proposal.callValue,
            proposal.functionSignature,
            proposal.callData,
            proposal.outcome,
            proposal.voteMagnitudeYes,
            proposal.voteMagnitudeNo,
            proposal.numVotes
            /** @notice - votes mapping cannot be returned by external function */
            /** @notice - voteMagnitudes mapping cannot be returned by external function */
            /** @notice - returning contractHash leads to stack too deep compiler error, see getProposalTargetContractHash() */
        );
    }

    /**
     * @notice Get proposal target contract hash by proposalId
     * @dev This is a separate function because the getProposalById returns too many
            variables already and by adding more, you get the error
            `InternalCompilerError: Stack too deep, try using fewer variables`
     * @param _proposalId - id of proposal
     */
    function getProposalTargetContractHash(uint256 _proposalId)
    external view returns (bytes32)
    {
        _requireIsInitialized();
        _requireValidProposalId(_proposalId);

        return (proposals[_proposalId].contractHash);
    }

    /**
     * @notice Get vote direction and vote magnitude for a given proposal and voter
     * @param _proposalId - id of the proposal
     * @param _voter - address of the voter we want to check
     * @return returns vote direction and magnitude if valid vote, else default values
     */
    function getVoteInfoByProposalAndVoter(uint256 _proposalId, address _voter)
    external view returns (Vote vote, uint256 voteMagnitude)
    {
        _requireIsInitialized();
        _requireValidProposalId(_proposalId);

        return (
            proposals[_proposalId].votes[_voter],
            proposals[_proposalId].voteMagnitudes[_voter]
        );
    }

    /// @notice Get the contract Guardian address
    function getGuardianAddress() external view returns (address) {
        _requireIsInitialized();

        return guardianAddress;
    }

    /// @notice Get the Staking address
    function getStakingAddress() external view returns (address) {
        _requireIsInitialized();

        return stakingAddress;
    }

    /// @notice Get the ServiceProviderFactory address
    function getServiceProviderFactoryAddress() external view returns (address) {
        _requireIsInitialized();

        return serviceProviderFactoryAddress;
    }

    /// @notice Get the DelegateManager address
    function getDelegateManagerAddress() external view returns (address) {
        _requireIsInitialized();

        return delegateManagerAddress;
    }

    /// @notice Get the contract voting period
    function getVotingPeriod() external view returns (uint256) {
        _requireIsInitialized();

        return votingPeriod;
    }

    /// @notice Get the contract voting quorum percent
    function getVotingQuorumPercent() external view returns (uint256) {
        _requireIsInitialized();

        return votingQuorumPercent;
    }

    /// @notice Get the registry address
    function getRegistryAddress() external view returns (address) {
        _requireIsInitialized();

        return address(registry);
    }

    /// @notice Used to check if is governance contract before setting governance address in other contracts
    function isGovernanceAddress() external pure returns (bool) {
        return true;
    }

    /// @notice Get the max number of concurrent InProgress proposals
    function getMaxInProgressProposals() external view returns (uint16) {
        _requireIsInitialized();

        return maxInProgressProposals;
    }

    /// @notice Get the proposal execution delay
    function getExecutionDelay() external view returns (uint256) {
        _requireIsInitialized();

        return executionDelay;
    }

    /// @notice Get the array of all InProgress proposal Ids
    function getInProgressProposals() external view returns (uint256[] memory) {
        _requireIsInitialized();

        return inProgressProposals;
    }

    /**
     * @notice Returns false if any proposals in inProgressProposals array are evaluatable
     *          Evaluatable = proposals with closed votingPeriod
     * @dev Is public since its called internally in `submitProposal()` as well as externally in UI
     */
    function inProgressProposalsAreUpToDate() external view returns (bool) {
        _requireIsInitialized();

        // compare current block number against endBlockNumber of each proposal
        for (uint256 i = 0; i < inProgressProposals.length; i++) {
            if (
                block.number >
                (proposals[inProgressProposals[i]].submissionBlockNumber).add(votingPeriod).add(executionDelay)
            ) {
                return false;
            }
        }

        return true;
    }

    // ========================================= Internal Functions =========================================

    /**
     * @notice Execute a transaction attached to a governance proposal
     * @dev We are aware of both potential re-entrancy issues and the risks associated with low-level solidity
     *      function calls here, but have chosen to keep this code with those issues in mind. All governance
     *      proposals go through a voting process, and all will be reviewed carefully to ensure that they
     *      adhere to the expected behaviors of this call - but adding restrictions here would limit the ability
     *      of the governance system to do required work in a generic way.
     * @param _targetContractAddress - address of registry proxy contract to execute transaction on
     * @param _callValue - amount of wei if a token transfer is involved
     * @param _functionSignature - function signature of the function to be executed if proposal is successful
     * @param _callData - encoded value(s) to call function with if proposal is successful
     */
    function _executeTransaction(
        address _targetContractAddress,
        uint256 _callValue,
        string memory _functionSignature,
        bytes memory _callData
    ) internal returns (bool success, bytes memory returnData)
    {
        bytes memory encodedCallData = abi.encodePacked(
            bytes4(keccak256(bytes(_functionSignature))),
            _callData
        );
        (success, returnData) = (
            // solium-disable-next-line security/no-call-value
            _targetContractAddress.call.value(_callValue)(encodedCallData)
        );

        return (success, returnData);
    }

    function _increaseVoteMagnitudeYes(uint256 _proposalId, uint256 _voterStake) internal {
        proposals[_proposalId].voteMagnitudeYes = (
            proposals[_proposalId].voteMagnitudeYes.add(_voterStake)
        );
    }

    function _increaseVoteMagnitudeNo(uint256 _proposalId, uint256 _voterStake) internal {
        proposals[_proposalId].voteMagnitudeNo = (
            proposals[_proposalId].voteMagnitudeNo.add(_voterStake)
        );
    }

    function _decreaseVoteMagnitudeYes(uint256 _proposalId, uint256 _voterStake) internal {
        proposals[_proposalId].voteMagnitudeYes = (
            proposals[_proposalId].voteMagnitudeYes.sub(_voterStake)
        );
    }

    function _decreaseVoteMagnitudeNo(uint256 _proposalId, uint256 _voterStake) internal {
        proposals[_proposalId].voteMagnitudeNo = (
            proposals[_proposalId].voteMagnitudeNo.sub(_voterStake)
        );
    }

    /**
     * @dev Can make O(1) by storing index pointer in proposals mapping.
     *      Requires inProgressProposals to be 1-indexed, since all proposals that are not present
     *          will have pointer set to 0.
     */
    function _removeFromInProgressProposals(uint256 _proposalId) internal {
        uint256 index = 0;
        for (uint256 i = 0; i < inProgressProposals.length; i++) {
            if (inProgressProposals[i] == _proposalId) {
                index = i;
                break;
            }
        }

        // Swap proposalId to end of array + pop (deletes last elem + decrements array length)
        inProgressProposals[index] = inProgressProposals[inProgressProposals.length - 1];
        inProgressProposals.pop();
    }

    /**
     * @notice Returns true if voting quorum percentage met for proposal, else false.
     * @dev Quorum is met if total voteMagnitude * 100 / total active stake in Staking
     * @dev Eventual multiplication overflow:
     *      (proposal.voteMagnitudeYes + proposal.voteMagnitudeNo), with 100% staking participation,
     *          can sum to at most the entire token supply of 10^27
     *      With 7% annual token supply inflation, multiplication can overflow ~1635 years at the earliest:
     *      log(2^256/(10^27*100))/log(1.07) ~= 1635
     *
     * @dev Note that quorum is evaluated based on total staked at proposal submission
     *      not total staked at proposal evaluation, this is expected behavior
     */
    function _quorumMet(Proposal memory proposal, Staking stakingContract)
    internal view returns (bool)
    {
        uint256 participation = (
            (proposal.voteMagnitudeYes + proposal.voteMagnitudeNo)
            .mul(100)
            .div(stakingContract.totalStakedAt(proposal.submissionBlockNumber))
        );
        return participation >= votingQuorumPercent;
    }

    // ========================================= Private Functions =========================================

    function _requireStakingAddressIsSet() private view {
        require(
            stakingAddress != address(0x00),
            "Governance: stakingAddress is not set"
        );
    }

    function _requireServiceProviderFactoryAddressIsSet() private view {
        require(
            serviceProviderFactoryAddress != address(0x00),
            "Governance: serviceProviderFactoryAddress is not set"
        );
    }

    function _requireDelegateManagerAddressIsSet() private view {
        require(
            delegateManagerAddress != address(0x00),
            "Governance: delegateManagerAddress is not set"
        );
    }

    function _requireValidProposalId(uint256 _proposalId) private view {
        require(
            _proposalId <= lastProposalId && _proposalId > 0,
            "Governance: Must provide valid non-zero _proposalId"
        );
    }

    /**
     * Calculates and returns active stake for address
     *
     * Active stake = (active deployer stake + active delegator stake)
     *      active deployer stake = (direct deployer stake - locked deployer stake)
     *          locked deployer stake = amount of pending decreaseStakeRequest for address
     *      active delegator stake = (total delegator stake - locked delegator stake)
     *          locked delegator stake = amount of pending undelegateRequest for address
     */
    function _calculateAddressActiveStake(address _address) private view returns (uint256) {
        ServiceProviderFactory spFactory = ServiceProviderFactory(serviceProviderFactoryAddress);
        DelegateManager delegateManager = DelegateManager(delegateManagerAddress);

        // Amount directly staked by address, if any, in ServiceProviderFactory
        (uint256 directDeployerStake,,,,,) = spFactory.getServiceProviderDetails(_address);
        // Amount of pending decreasedStakeRequest for address, if any, in ServiceProviderFactory
        (uint256 lockedDeployerStake,) = spFactory.getPendingDecreaseStakeRequest(_address);
        // active deployer stake = (direct deployer stake - locked deployer stake)
        uint256 activeDeployerStake = directDeployerStake.sub(lockedDeployerStake);

        // Total amount delegated by address, if any, in DelegateManager
        uint256 totalDelegatorStake = delegateManager.getTotalDelegatorStake(_address);
        // Amount of pending undelegateRequest for address, if any, in DelegateManager
        (,uint256 lockedDelegatorStake, ) = delegateManager.getPendingUndelegateRequest(_address);
        // active delegator stake = (total delegator stake - locked delegator stake)
        uint256 activeDelegatorStake = totalDelegatorStake.sub(lockedDelegatorStake);

        // activeStake = (activeDeployerStake + activeDelegatorStake)
        uint256 activeStake = activeDeployerStake.add(activeDelegatorStake);

        return activeStake;
    }

    // solium-disable security/no-inline-assembly
    /**
     * @notice Helper function to generate the code hash for a contract address
     * @return contract code hash
     */
    function _getCodeHash(address _contract) private view returns (bytes32) {
        bytes32 contractHash;
        assembly {
          contractHash := extcodehash(_contract)
        }
        return contractHash;
    }
}

// File: contracts/ServiceTypeManager.sol

pragma solidity ^0.5.0;




contract ServiceTypeManager is InitializableV2 {
    address governanceAddress;

    string private constant ERROR_ONLY_GOVERNANCE = (
        "ServiceTypeManager: Only callable by Governance contract"
    );

    /**
     * @dev - mapping of serviceType - serviceTypeVersion
     * Example - "discovery-provider" - ["0.0.1", "0.0.2", ..., "currentVersion"]
     */
    mapping(bytes32 => bytes32[]) private serviceTypeVersions;

    /**
     * @dev - mapping of serviceType - < serviceTypeVersion, isValid >
     * Example - "discovery-provider" - <"0.0.1", true>
     */
    mapping(bytes32 => mapping(bytes32 => bool)) private serviceTypeVersionInfo;

    /// @dev List of valid service types
    bytes32[] private validServiceTypes;

    /// @dev Struct representing service type info
    struct ServiceTypeInfo {
        bool isValid;
        uint256 minStake;
        uint256 maxStake;
    }

    /// @dev mapping of service type info
    mapping(bytes32 => ServiceTypeInfo) private serviceTypeInfo;

    event SetServiceVersion(
        bytes32 indexed _serviceType,
        bytes32 indexed _serviceVersion
    );

    event ServiceTypeAdded(
        bytes32 indexed _serviceType,
        uint256 indexed _serviceTypeMin,
        uint256 indexed _serviceTypeMax
    );

    event ServiceTypeRemoved(bytes32 indexed _serviceType);

    /**
     * @notice Function to initialize the contract
     * @param _governanceAddress - Governance proxy address
     */
    function initialize(address _governanceAddress) public initializer
    {
        _updateGovernanceAddress(_governanceAddress);
        InitializableV2.initialize();
    }

    /// @notice Get the Governance address
    function getGovernanceAddress() external view returns (address) {
        _requireIsInitialized();

        return governanceAddress;
    }

    /**
     * @notice Set the Governance address
     * @dev Only callable by Governance address
     * @param _governanceAddress - address for new Governance contract
     */
    function setGovernanceAddress(address _governanceAddress) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        _updateGovernanceAddress(_governanceAddress);
    }

    // ========================================= Service Type Logic =========================================

    /**
     * @notice Add a new service type
     * @param _serviceType - type of service to add
     * @param _serviceTypeMin - minimum stake for service type
     * @param _serviceTypeMax - maximum stake for service type
     */
    function addServiceType(
        bytes32 _serviceType,
        uint256 _serviceTypeMin,
        uint256 _serviceTypeMax
    ) external
    {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        require(
            !this.serviceTypeIsValid(_serviceType),
            "ServiceTypeManager: Already known service type"
        );
        require(
            _serviceTypeMax > _serviceTypeMin,
            "ServiceTypeManager: Max stake must be non-zero and greater than min stake"
        );

        // Ensure serviceType cannot be re-added if it previously existed and was removed
        // stored maxStake > 0 means it was previously added and removed
        require(
            serviceTypeInfo[_serviceType].maxStake == 0,
            "ServiceTypeManager: Cannot re-add serviceType after it was removed."
        );

        validServiceTypes.push(_serviceType);
        serviceTypeInfo[_serviceType] = ServiceTypeInfo({
            isValid: true,
            minStake: _serviceTypeMin,
            maxStake: _serviceTypeMax
        });

        emit ServiceTypeAdded(_serviceType, _serviceTypeMin, _serviceTypeMax);
    }

    /**
     * @notice Remove an existing service type
     * @param _serviceType - name of service type to remove
     */
    function removeServiceType(bytes32 _serviceType) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);

        uint256 serviceIndex = 0;
        bool foundService = false;
        for (uint256 i = 0; i < validServiceTypes.length; i ++) {
            if (validServiceTypes[i] == _serviceType) {
                serviceIndex = i;
                foundService = true;
                break;
            }
        }
        require(foundService == true, "ServiceTypeManager: Invalid service type, not found");
        // Overwrite service index
        uint256 lastIndex = validServiceTypes.length - 1;
        validServiceTypes[serviceIndex] = validServiceTypes[lastIndex];
        validServiceTypes.length--;

        // Mark as invalid
        serviceTypeInfo[_serviceType].isValid = false;
        // Note - stake bounds are not reset so they can be checked to prevent serviceType from being re-added
        emit ServiceTypeRemoved(_serviceType);
    }

    /**
     * @notice Get isValid, min and max stake for a given service type
     * @param _serviceType - type of service
     * @return isValid, min and max stake for type
     */
    function getServiceTypeInfo(bytes32 _serviceType)
    external view returns (bool isValid, uint256 minStake, uint256 maxStake)
    {
        _requireIsInitialized();

        return (
            serviceTypeInfo[_serviceType].isValid,
            serviceTypeInfo[_serviceType].minStake,
            serviceTypeInfo[_serviceType].maxStake
        );
    }

    /**
     * @notice Get list of valid service types
     */
    function getValidServiceTypes()
    external view returns (bytes32[] memory)
    {
        _requireIsInitialized();

        return validServiceTypes;
    }

    /**
     * @notice Return indicating whether this is a valid service type
     */
    function serviceTypeIsValid(bytes32 _serviceType)
    external view returns (bool)
    {
        _requireIsInitialized();

        return serviceTypeInfo[_serviceType].isValid;
    }

    // ========================================= Service Version Logic =========================================

    /**
     * @notice Add new version for a serviceType
     * @param _serviceType - type of service
     * @param _serviceVersion - new version of service to add
     */
    function setServiceVersion(
        bytes32 _serviceType,
        bytes32 _serviceVersion
    ) external
    {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, ERROR_ONLY_GOVERNANCE);
        require(this.serviceTypeIsValid(_serviceType), "ServiceTypeManager: Invalid service type");
        require(
            serviceTypeVersionInfo[_serviceType][_serviceVersion] == false,
            "ServiceTypeManager: Already registered"
        );

         // Update array of known versions for type
        serviceTypeVersions[_serviceType].push(_serviceVersion);

        // Update status for this specific service version
        serviceTypeVersionInfo[_serviceType][_serviceVersion] = true;

        emit SetServiceVersion(_serviceType, _serviceVersion);
    }

    /**
     * @notice Get a version for a service type given it's index
     * @param _serviceType - type of service
     * @param _versionIndex - index in list of service versions
     * @return bytes32 value for serviceVersion
     */
    function getVersion(bytes32 _serviceType, uint256 _versionIndex)
    external view returns (bytes32)
    {
        _requireIsInitialized();

        require(
            serviceTypeVersions[_serviceType].length > _versionIndex,
            "ServiceTypeManager: No registered version of serviceType"
        );
        return (serviceTypeVersions[_serviceType][_versionIndex]);
    }

    /**
     * @notice Get curent version for a service type
     * @param _serviceType - type of service
     * @return Returns current version of service
     */
    function getCurrentVersion(bytes32 _serviceType)
    external view returns (bytes32)
    {
        _requireIsInitialized();

        require(
            serviceTypeVersions[_serviceType].length >= 1,
            "ServiceTypeManager: No registered version of serviceType"
        );
        uint256 latestVersionIndex = serviceTypeVersions[_serviceType].length - 1;
        return (serviceTypeVersions[_serviceType][latestVersionIndex]);
    }

    /**
     * @notice Get total number of versions for a service type
     * @param _serviceType - type of service
     */
    function getNumberOfVersions(bytes32 _serviceType)
    external view returns (uint256)
    {
        _requireIsInitialized();

        return serviceTypeVersions[_serviceType].length;
    }

    /**
     * @notice Return boolean indicating whether given version is valid for given type
     * @param _serviceType - type of service
     * @param _serviceVersion - version of service to check
     */
    function serviceVersionIsValid(bytes32 _serviceType, bytes32 _serviceVersion)
    external view returns (bool)
    {
        _requireIsInitialized();

        return serviceTypeVersionInfo[_serviceType][_serviceVersion];
    }

    /**
     * @notice Set the governance address after confirming contract identity
     * @param _governanceAddress - Incoming governance address
     */
    function _updateGovernanceAddress(address _governanceAddress) internal {
        require(
            Governance(_governanceAddress).isGovernanceAddress() == true,
            "ServiceTypeManager: _governanceAddress is not a valid governance contract"
        );
        governanceAddress = _governanceAddress;
    }
}