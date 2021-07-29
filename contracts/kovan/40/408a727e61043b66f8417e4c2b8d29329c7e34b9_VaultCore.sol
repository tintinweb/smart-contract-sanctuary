/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: MIT


// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


pragma solidity >=0.6.0 <0.8.0;


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
abstract contract ContextUpgradeable is Initializable {
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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


pragma solidity >=0.6.0 <0.8.0;


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol


pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol


pragma solidity >=0.6.0 <0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol


pragma solidity >=0.6.0 <0.8.0;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// File: contracts/libraries/InitializableERC20Detailed.sol

pragma solidity ^0.6.12;


/**
 * @dev Optional functions from the ERC20 standard.
 * Converted from openzeppelin/contracts/token/ERC20/ERC20Detailed.sol
 */
abstract contract InitializableERC20Detailed is ERC20Upgradeable {
    // Storage gap to skip storage from prior to OUSD reset
    uint256[100] private _____gap;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     * @notice To avoid variable shadowing appended `Arg` after arguments name.
     */
    function _initialize(
        string memory nameArg,
        string memory symbolArg,
        uint8 decimalsArg
    ) internal {
        _name = nameArg;
        _symbol = symbolArg;
        _decimals = decimalsArg;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }


}

// File: contracts/libraries/StableMath.sol

pragma solidity ^0.6.12;


// Based on StableMath from Stability Labs Pty. Ltd.
// https://github.com/mstable/mStable-contracts/blob/master/contracts/shared/StableMath.sol

library StableMath {
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /***************************************
                    Helpers
    ****************************************/

    /**
     * @dev Adjust the scale of an integer
     * @param adjustment Amount to adjust by e.g. scaleBy(1e18, -1) == 1e17
     */
    function scaleBy(uint256 x, int8 adjustment)
        internal
        pure
        returns (uint256)
    {
        if (adjustment > 0) {
            x = x.mul(10**uint256(adjustment));
        } else if (adjustment < 0) {
            x = x.div(10**uint256(adjustment * -1));
        }
        return x;
    }

    /***************************************
               Precise Arithmetic
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @return Result after multiplying the two inputs and then dividing by the shared
     *         scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @param scale Scale unit
     * @return Result after multiplying the two inputs and then dividing by the shared
     *         scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        uint256 z = x.mul(y);
        // return 9e38 / 1e18 = 9e18
        return z.div(scale);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @return Result after multiplying the two inputs and then dividing by the shared
     *          scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x.mul(y);
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled.add(FULL_SCALE.sub(1));
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil.div(FULL_SCALE);
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x Left hand input to division
     * @param y Right hand input to division
     * @return Result after multiplying the left operand by the scale, and
     *         executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e18 * 1e18 = 8e36
        uint256 z = x.mul(FULL_SCALE);
        // e.g. 8e36 / 10e18 = 8e17
        return z.div(y);
    }
}

// File: contracts/token/USDs.sol

pragma solidity ^0.6.12;

/**
 * @title USDs Token Contract
 * @dev ERC20 compatible contract for USDs
 * @dev Implements an elastic supply
 * @author Origin Protocol Inc
 */
//import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";







/**
 * NOTE that this is an ERC20 token but the invariant that the sum of
 * balanceOf(x) for all x is not >= totalSupply(). This is a consequence of the
 * rebasing design. Any integrations with USDs should be aware.
 */

contract USDs is Initializable, InitializableERC20Detailed, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using StableMath for uint256;

    event TotalSupplyUpdated(
        uint256 totalSupply,
        uint256 rebasingCredits,
        uint256 rebasingCreditsPerToken
    );

    enum RebaseOptions { NotSet, OptOut, OptIn }

    uint256 private constant MAX_SUPPLY = ~uint128(0); // (2^128) - 1
    uint256 public _totalSupply;
    uint256 public _totalMinted;
    uint256 public _totalBurnt;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public vaultAddress;
    mapping(address => uint256) private _creditBalances;
    uint256 public rebasingCredits;
    uint256 public rebasingCreditsPerToken;
    // Frozen address/credits are non rebasing (value is held in contracts which
    // do not receive yield unless they explicitly opt in)
    uint256 public nonRebasingSupply;
    mapping(address => uint256) public nonRebasingCreditsPerToken;
    mapping(address => RebaseOptions) public rebaseState;

    function initialize(
        string calldata _nameArg,
        string calldata _symbolArg,
        address _vaultAddress
    ) external initializer {
        InitializableERC20Detailed._initialize(_nameArg, _symbolArg, 18);
        OwnableUpgradeable.__Ownable_init();
        rebasingCreditsPerToken = 1e18;
        vaultAddress = _vaultAddress;
    }

    function changeVault(address newVault) external onlyOwner {
        vaultAddress = newVault;
    }

    /**
     * @dev Verifies that the caller is the Savings Manager contract
     */
    modifier onlyVault() {
        require(vaultAddress == msg.sender, "Caller is not the Vault");
        _;
    }

    /**
     * @return The total supply of USDs.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _account Address to query the balance of.
     * @return A uint256 representing the _amount of base units owned by the
     *         specified address.
     */
    function balanceOf(address _account) public view override returns (uint256) {
        if (_creditBalances[_account] == 0) return 0;
        return
            _creditBalances[_account].divPrecisely(_creditsPerToken(_account));
    }

    /**
     * @dev Gets the credits balance of the specified address.
     * @param _account The address to query the balance of.
     * @return (uint256, uint256) Credit balance and credits per token of the
     *         address
     */
    function creditsBalanceOf(address _account)
        public
        view
        returns (uint256, uint256)
    {
        return (_creditBalances[_account], _creditsPerToken(_account));
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param _to the address to transfer to.
     * @param _value the _amount to be transferred.
     * @return true on success.
     */
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_to != address(0), "Transfer to zero address");
        require(
            _value <= balanceOf(msg.sender),
            "Transfer greater than balance"
        );

        _executeTransfer(msg.sender, _to, _value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param _from The address you want to send tokens from.
     * @param _to The address you want to transfer to.
     * @param _value The _amount of tokens to be transferred.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        require(_to != address(0), "Transfer to zero address");
        require(_value <= balanceOf(_from), "Transfer greater than balance");

        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(
            _value
        );

        _executeTransfer(_from, _to, _value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev Update the count of non rebasing credits in response to a transfer
     * @param _from The address you want to send tokens from.
     * @param _to The address you want to transfer to.
     * @param _value Amount of USDs to transfer
     */
    function _executeTransfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        bool isNonRebasingTo = _isNonRebasingAccount(_to);
        bool isNonRebasingFrom = _isNonRebasingAccount(_from);

        // Credits deducted and credited might be different due to the
        // differing creditsPerToken used by each account
        uint256 creditsCredited = _value.mulTruncate(_creditsPerToken(_to));
        uint256 creditsDeducted = _value.mulTruncate(_creditsPerToken(_from));

        _creditBalances[_from] = _creditBalances[_from].sub(
            creditsDeducted,
            "Transfer amount exceeds balance"
        );
        _creditBalances[_to] = _creditBalances[_to].add(creditsCredited);

        if (isNonRebasingTo && !isNonRebasingFrom) {
            // Transfer to non-rebasing account from rebasing account, credits
            // are removed from the non rebasing tally
            nonRebasingSupply = nonRebasingSupply.add(_value);
            // Update rebasingCredits by subtracting the deducted amount
            rebasingCredits = rebasingCredits.sub(creditsDeducted);
        } else if (!isNonRebasingTo && isNonRebasingFrom) {
            // Transfer to rebasing account from non-rebasing account
            // Decreasing non-rebasing credits by the amount that was sent
            nonRebasingSupply = nonRebasingSupply.sub(_value);
            // Update rebasingCredits by adding the credited amount
            rebasingCredits = rebasingCredits.add(creditsCredited);
        }
    }

    /**
     * @dev Function to check the _amount of tokens that an owner has allowed to a _spender.
     * @param _owner The address which owns the funds.
     * @param _spender The address which will spend the funds.
     * @return The number of tokens still available for the _spender.
     */
    function allowance(address _owner, address _spender)
        public
        view
        override returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    /**
     * @dev Approve the passed address to spend the specified _amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param _spender The address which will spend the funds.
     * @param _value The _amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public override returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Increase the _amount of tokens that an owner has allowed to a _spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param _spender The address which will spend the funds.
     * @param _addedValue The _amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][_spender] = _allowances[msg.sender][_spender]
            .add(_addedValue);
        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the _amount of tokens that an owner has allowed to a _spender.
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The _amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 oldValue = _allowances[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            _allowances[msg.sender][_spender] = 0;
        } else {
            _allowances[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Mints new tokens, increasing totalSupply.
     */
    function mint(address _account, uint256 _amount) external onlyVault {
        _mint(_account, _amount);
    }

    /**
     * @dev Creates `_amount` tokens and assigns them to `_account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address _account, uint256 _amount) internal override {
        require(_account != address(0), "Mint to the zero address");

        bool isNonRebasingAccount = _isNonRebasingAccount(_account);

        uint256 creditAmount = _amount.mulTruncate(_creditsPerToken(_account));
        _creditBalances[_account] = _creditBalances[_account].add(creditAmount);

        // If the account is non rebasing and doesn't have a set creditsPerToken
        // then set it i.e. this is a mint from a fresh contract
        if (isNonRebasingAccount) {
            nonRebasingSupply = nonRebasingSupply.add(_amount);
        } else {
            rebasingCredits = rebasingCredits.add(creditAmount);
        }

        _totalSupply = _totalSupply.add(_amount);
        _totalMinted = _totalMinted.add(_amount);

        require(_totalSupply < MAX_SUPPLY, "Max supply");

        emit Transfer(address(0), _account, _amount);
    }

    /**
     * @dev Burns tokens, decreasing totalSupply.
     */
    function burn(address account, uint256 amount) external onlyVault {
        _burn(account, amount);
    }

    /**
     * @dev Destroys `_amount` tokens from `_account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `_account` cannot be the zero address.
     * - `_account` must have at least `_amount` tokens.
     */
    function _burn(address _account, uint256 _amount) internal override {
        require(_account != address(0), "Burn from the zero address");
        if (_amount == 0) {
            return;
        }

        bool isNonRebasingAccount = _isNonRebasingAccount(_account);
        uint256 creditAmount = _amount.mulTruncate(_creditsPerToken(_account));
        uint256 currentCredits = _creditBalances[_account];

        // Remove the credits, burning rounding errors
        if (
            currentCredits == creditAmount || currentCredits - 1 == creditAmount
        ) {
            // Handle dust from rounding
            _creditBalances[_account] = 0;
        } else if (currentCredits > creditAmount) {
            _creditBalances[_account] = _creditBalances[_account].sub(
                creditAmount
            );
        } else {
            revert("Remove exceeds balance");
        }

        // Remove from the credit tallies and non-rebasing supply
        if (isNonRebasingAccount) {
            nonRebasingSupply = nonRebasingSupply.sub(_amount);
        } else {
            rebasingCredits = rebasingCredits.sub(creditAmount);
        }

        _totalSupply = _totalSupply.sub(_amount);
        _totalBurnt = _totalBurnt.add(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    /**
     * @dev Get the credits per token for an account. Returns a fixed amount
     *      if the account is non-rebasing.
     * @param _account Address of the account.
     */
    function _creditsPerToken(address _account)
        internal
        view
        returns (uint256)
    {
        if (nonRebasingCreditsPerToken[_account] != 0) {
            return nonRebasingCreditsPerToken[_account];
        } else {
            return rebasingCreditsPerToken;
        }
    }

    /**
     * @dev Is an account using rebasing accounting or non-rebasing accounting?
     *      Also, ensure contracts are non-rebasing if they have not opted in.
     * @param _account Address of the account.
     */
    function _isNonRebasingAccount(address _account) internal returns (bool) {
        bool isContract = AddressUpgradeable.isContract(_account);
        if (isContract && rebaseState[_account] == RebaseOptions.NotSet) {
            _ensureRebasingMigration(_account);
        }
        return nonRebasingCreditsPerToken[_account] > 0;
    }

    /**
     * @dev Ensures internal account for rebasing and non-rebasing credits and
     *      supply is updated following deployment of frozen yield change.
     */
    function _ensureRebasingMigration(address _account) internal {
        if (nonRebasingCreditsPerToken[_account] == 0) {
            // Set fixed credits per token for this account
            nonRebasingCreditsPerToken[_account] = rebasingCreditsPerToken;
            // Update non rebasing supply
            nonRebasingSupply = nonRebasingSupply.add(balanceOf(_account));
            // Update credit tallies
            rebasingCredits = rebasingCredits.sub(_creditBalances[_account]);
        }
    }

    /**
     * @dev Add a contract address to the non rebasing exception list. I.e. the
     * address's balance will be part of rebases so the account will be exposed
     * to upside and downside.
     */
    function rebaseOptIn() public onlyOwner {
        require(_isNonRebasingAccount(msg.sender), "Account has not opted out");

        // Convert balance into the same amount at the current exchange rate
        uint256 newCreditBalance = _creditBalances[msg.sender]
            .mul(rebasingCreditsPerToken)
            .div(_creditsPerToken(msg.sender));

        // Decreasing non rebasing supply
        nonRebasingSupply = nonRebasingSupply.sub(balanceOf(msg.sender));

        _creditBalances[msg.sender] = newCreditBalance;

        // Increase rebasing credits, totalSupply remains unchanged so no
        // adjustment necessary
        rebasingCredits = rebasingCredits.add(_creditBalances[msg.sender]);

        rebaseState[msg.sender] = RebaseOptions.OptIn;

        // Delete any fixed credits per token
        delete nonRebasingCreditsPerToken[msg.sender];
    }

    /**
     * @dev Remove a contract address to the non rebasing exception list.
     */
    function rebaseOptOut() public onlyOwner {
        require(!_isNonRebasingAccount(msg.sender), "Account has not opted in");

        // Increase non rebasing supply
        nonRebasingSupply = nonRebasingSupply.add(balanceOf(msg.sender));
        // Set fixed credits per token
        nonRebasingCreditsPerToken[msg.sender] = rebasingCreditsPerToken;

        // Decrease rebasing credits, total supply remains unchanged so no
        // adjustment necessary
        rebasingCredits = rebasingCredits.sub(_creditBalances[msg.sender]);

        // Mark explicitly opted out of rebasing
        rebaseState[msg.sender] = RebaseOptions.OptOut;
    }

    /**
     * @dev Modify the supply without minting new tokens. This uses a change in
     *      the exchange rate between "credits" and USDs tokens to change balances.
     * @param _newTotalSupply New total supply of USDs.
     */
    function changeSupply(uint256 _newTotalSupply)
        external
        onlyVault
    {
        require(_totalSupply > 0, "Cannot increase 0 supply");

        if (_totalSupply == _newTotalSupply) {
            emit TotalSupplyUpdated(
                _totalSupply,
                rebasingCredits,
                rebasingCreditsPerToken
            );
            return;
        }

        _totalSupply = _newTotalSupply > MAX_SUPPLY
            ? MAX_SUPPLY
            : _newTotalSupply;

        rebasingCreditsPerToken = rebasingCredits.divPrecisely(
            _totalSupply.sub(nonRebasingSupply)
        );

        require(rebasingCreditsPerToken > 0, "Invalid change in supply");

        _totalSupply = rebasingCredits
            .divPrecisely(rebasingCreditsPerToken)
            .add(nonRebasingSupply);

        emit TotalSupplyUpdated(
            _totalSupply,
            rebasingCredits,
            rebasingCreditsPerToken
        );
    }
}

// File: contracts/interfaces/IBancorFormula.sol

pragma solidity 0.6.12;

/*
    Bancor Formula interface
*/
interface IBancorFormula {

}

// File: contracts/libraries/BancorFormula.sol

pragma solidity 0.6.12;



contract BancorFormula is IBancorFormula {
    using SafeMathUpgradeable for uint256;

    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    // Auto-generated via 'PrintIntScalingFactors.py'
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    // Auto-generated via 'PrintLn2ScalingFactors.py'
    uint256 private constant LN2_NUMERATOR = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    // Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    // Auto-generated via 'PrintLambertFactors.py'
    uint256 private constant LAMBERT_CONV_RADIUS = 0x002f16ac6c59de6f8d5d6f63c1482a7c86;
    uint256 private constant LAMBERT_POS2_SAMPLE = 0x0003060c183060c183060c183060c18306;
    uint256 private constant LAMBERT_POS2_MAXVAL = 0x01af16ac6c59de6f8d5d6f63c1482a7c80;
    uint256 private constant LAMBERT_POS3_MAXVAL = 0x6b22d43e72c326539cceeef8bb48f255ff;

    // Auto-generated via 'PrintWeightFactors.py'
    uint256 private constant MAX_UNF_WEIGHT = 0x10c6f7a0b5ed8d36b4c7f34938583621fafc8b0079a2834d26fa3fcc9ea9;

    // Auto-generated via 'PrintMaxExpArray.py'
    uint256[128] private maxExpArray;

    function initMaxExpArray() private {
        //  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
        //  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
        //  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
        //  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
        //  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
        //  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
        //  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
        //  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
        //  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
        //  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
        //  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
        //  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
        //  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
        //  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
        //  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
        //  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
        //  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
        //  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
        //  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
        //  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
        //  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
        //  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
        //  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
        //  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
        //  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
        //  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
        //  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
        //  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
        //  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
        //  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
        //  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
        //  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
        maxExpArray[32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

    /**
     * @dev should be executed after construction (too large for the constructor)
     */
    function init() public {
        initMaxExpArray();
    }


    /**
     * @dev General Description:
     *     Determine a value of precision.
     *     Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
     *     Return the result along with the precision used.
     *
     * Detailed Description:
     *     Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
     *     The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
     *     The larger "precision" is, the more accurately this value represents the real value.
     *     However, the larger "precision" is, the more bits are required in order to store this value.
     *     And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
     *     This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     *     Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
     *     This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
     *     This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
     *     Since we rely on unsigned-integer arithmetic and "base < 1" ==> "log(base) < 0", this function does not support "_baseN < _baseD".
     */
    function power(
        uint256 _baseN,
        uint256 _baseD,
        uint32 _expN,
        uint32 _expD
    ) public view returns (uint256, uint8) {
        require(_baseN < MAX_NUM);

        uint256 baseLog;
        uint256 base = (_baseN * FIXED_1) / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        } else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = (baseLog * _expN) / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        } else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
        }
    }

    /**
     * @dev computes log(x / FIXED_1) * FIXED_1.
     * This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
     */
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return (res * LN2_NUMERATOR) / LN2_DENOMINATOR;
    }

    /**
     * @dev computes the largest integer smaller than or equal to the binary logarithm of the input.
     */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        } else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
     * @dev the global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
     * - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
     * - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
     */
    function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= _x) lo = mid;
            else hi = mid;
        }

        if (maxExpArray[hi] >= _x) return hi;
        if (maxExpArray[lo] >= _x) return lo;

        require(false);
    }

    /**
     * @dev this function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
     * it approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
     * it returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
     * the global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
     * the maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     */
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision;
        res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
     * @dev computes log(x / FIXED_1) * FIXED_1
     * Input range: FIXED_1 <= x <= OPT_LOG_MAX_VAL - 1
     * Auto-generated via 'PrintFunctionOptimalLog.py'
     * Detailed description:
     * - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
     * - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
     * - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
     * - The natural logarithm of the input is calculated by summing up the intermediate results above
     * - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
     */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {
            res += 0x40000000000000000000000000000000;
            x = (x * FIXED_1) / 0xd3094c70f034de4b96ff7d5b6f99fcd8;
        } // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {
            res += 0x20000000000000000000000000000000;
            x = (x * FIXED_1) / 0xa45af1e1f40c333b3de1db4dd55f29a7;
        } // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {
            res += 0x10000000000000000000000000000000;
            x = (x * FIXED_1) / 0x910b022db7ae67ce76b441c27035c6a1;
        } // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {
            res += 0x08000000000000000000000000000000;
            x = (x * FIXED_1) / 0x88415abbe9a76bead8d00cf112e4d4a8;
        } // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {
            res += 0x04000000000000000000000000000000;
            x = (x * FIXED_1) / 0x84102b00893f64c705e841d5d4064bd3;
        } // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {
            res += 0x02000000000000000000000000000000;
            x = (x * FIXED_1) / 0x8204055aaef1c8bd5c3259f4822735a2;
        } // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e99) {
            res += 0x01000000000000000000000000000000;
            x = (x * FIXED_1) / 0x810100ab00222d861931c15e39b44e99;
        } // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f733) {
            res += 0x00800000000000000000000000000000;
            x = (x * FIXED_1) / 0x808040155aabbbe9451521693554f733;
        } // add 1 / 2^8

        z = y = x - FIXED_1;
        w = (y * y) / FIXED_1;
        res += (z * (0x100000000000000000000000000000000 - y)) / 0x100000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
        res += (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) / 0x200000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
        res += (z * (0x099999999999999999999999999999999 - y)) / 0x300000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
        res += (z * (0x092492492492492492492492492492492 - y)) / 0x400000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
        res += (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) / 0x500000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
        res += (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) / 0x600000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
        res += (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) / 0x700000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
        res += (z * (0x088888888888888888888888888888888 - y)) / 0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16

        return res;
    }

    /**
     * @dev computes e ^ (x / FIXED_1) * FIXED_1
     * input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
     * auto-generated via 'PrintFunctionOptimalExp.py'
     * Detailed description:
     * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
     * - The exponentiation of each binary exponent is given (pre-calculated)
     * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
     * - The exponentiation of the input is calculated by multiplying the intermediate results above
     * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
     */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = (z * y) / FIXED_1;
        res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = (z * y) / FIXED_1;
        res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = (z * y) / FIXED_1;
        res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = (z * y) / FIXED_1;
        res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = (z * y) / FIXED_1;
        res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = (z * y) / FIXED_1;
        res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = (z * y) / FIXED_1;
        res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0)
            res = (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) / 0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0)
            res = (res * 0x18ebef9eac820ae8682b9793ac6d1e778) / 0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0)
            res = (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) / 0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0)
            res = (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) / 0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0)
            res = (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) / 0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0)
            res = (res * 0x00960aadc109e7a3bf4578099615711d7) / 0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0)
            res = (res * 0x0002bf84208204f5977f9a8cf01fdc307) / 0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }

}

// File: contracts/vault/VaultStorage.sol

pragma solidity ^0.6.12;



contract VaultStorage {
	bool public mintRedeemAllowed;

	bool public swapfeeInAllowed;
	bool public swapfeeOutAllowed;

	mapping(address => uint256) supportedCollat;
	address[] allCollat;
	address[] allStrategies;

	address public SPATokenAddr;
	address public oracleAddr;
	address public collaValut;
	address public SPAValut;
	address public USDsFeeValut;
	address public USDsYieldValut;

	uint public startBlockHeight;

	uint public chiInit;
	uint public constant chiPrec = 100000;
	uint public constant chi_alpha = 5130573085013596;
	uint public constant chi_alpha_Prec = 10**23;
	uint public constant chi_beta = 9;
	uint public constant chi_beta_Prec = 1;
	uint public constant chi_gamma = 1;
	uint public constant chi_gamma_Prec = 1;


	uint public constant swapFeePresion = 1000000;
	uint public constant swapFee_p = 99;
	uint public constant swapFee_p_Prec = 100;
	uint public constant swapFee_theta = 50;
	uint public constant swapFee_theta_Prec = 1;
	uint32 public constant swapFee_a = 12;
	uint32 public constant swapFee_a_Prec = 10;
	uint public constant swapFee_A = 20;
	uint public constant swapFee_A_Prec = 1;


	USDs USDsInstance;
	BancorFormula BancorInstance;

}

// File: contracts/libraries/MyMath.sol

pragma solidity ^0.6.12;

//inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol

library MyMath {
    //inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol
    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
      function toUint112(uint256 value) internal pure returns (uint112) {
          require(value < 2**112, "SafeCast: value doesnt fit in 112 bits");
          return uint112(value);
      }
}

// File: contracts/interfaces/IBasicToken.sol

pragma solidity >=0.5.11;

interface IBasicToken {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: contracts/libraries/Helpers.sol

pragma solidity >=0.5.11;


library Helpers {
    /**
     * @notice Fetch the `symbol()` from an ERC20 token
     * @dev Grabs the `symbol()` from a contract
     * @param _token Address of the ERC20 token
     * @return string Symbol of the ERC20 token
     */
    function getSymbol(address _token) internal view returns (string memory) {
        string memory symbol = IBasicToken(_token).symbol();
        return symbol;
    }

    /**
     * @notice Fetch the `decimals()` from an ERC20 token
     * @dev Grabs the `decimals()` from a contract and fails if
     *      the decimal value does not live within a certain range
     * @param _token Address of the ERC20 token
     * @return uint256 Decimals of the ERC20 token
     */
    function getDecimals(address _token) internal view returns (uint256) {
        uint256 decimals = IBasicToken(_token).decimals();
        require(
            decimals >= 4 && decimals <= 18,
            "Token must have sufficient decimal places"
        );

        return decimals;
    }
}

// File: contracts/interfaces/IOracle.sol

pragma solidity ^0.6.12;

interface IOracle {
    event Update(uint currPriceMA7, uint currPricetime);

    function lastUpdateTime() external view returns (uint32);
    function period() external view returns (uint32);
    function token0PriceMA() external view returns (uint);
    function update() external;
    function collatPrice(address tokenAddr) external view returns (uint);
    function getSPAPrice() external view returns (uint);
    function getUSDsPrice() external view returns (uint);
    function ETHPricePrecision() external view returns (uint);
    function collatPricePrecision(address tokenAddr) external view returns (uint);
    function SPAPricePrecision() external view returns (uint);
    function USDsPricePrecision() external view returns (uint);
    function USDsInOutRatio() external view returns (uint);
    function USDsInOutRatioPrecision() external view returns (uint);
}

// File: contracts/interfaces/ISperaxToken.sol

pragma solidity >=0.5.0;

interface ISperaxToken {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function burnFrom(address account, uint256 amount) external;
}

// File: contracts/vault/VaultCore.sol

//To-do: fix presion

pragma solidity ^0.6.12;












contract VaultCore is Initializable, VaultStorage, OwnableUpgradeable {
	using SafeERC20Upgradeable for ERC20Upgradeable;
	using SafeMathUpgradeable for uint;
	using MyMath for uint;

	modifier whenMintRedeemAllowed {
		require(mintRedeemAllowed, "Mint & redeem paused");
		_;
	}

	function initialize(address USDsToken_, address oracleAddr_, address BancorFormulaAddr_) public initializer {
		OwnableUpgradeable.__Ownable_init();
		// Initialize variables
		mintRedeemAllowed = true;
		swapfeeInAllowed = true;
		swapfeeOutAllowed = true;
		SPATokenAddr = 0xFb931d41A744bE590E8B51e2e343bBE030aC4f93;
		chiInit = 95000;

		collaValut = address(this);
		SPAValut = address(this);
		USDsFeeValut = address(this);
		USDsYieldValut = address(this);
		supportedCollat[0xb7a4F3E9097C08dA09517b5aB877F7a917224ede] = 1;
		allCollat.push(0xb7a4F3E9097C08dA09517b5aB877F7a917224ede);
		USDsInstance = USDs(USDsToken_);
		oracleAddr = oracleAddr_;
		BancorInstance = BancorFormula(BancorFormulaAddr_);
		startBlockHeight = block.number;
		// DAI
		// 0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa
		// 0x777A68032a88E5A84678A77Af2CD65A7b3c0775a
		// 8
		// USDC
		// 0xb7a4F3E9097C08dA09517b5aB877F7a917224ede
		// 0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60
		// 8
		// USDT
		// 0x07de306ff27a2b630b1141956844eb1552b956b5
		// 0x2ca5A90D34cA333661083F89D831f757A9A50148
		// 8
	}


	function calculateSwapFeeIn() public view returns (uint) {
		if (!swapfeeInAllowed) {
			return 0;
		}

		uint priceUSDs = uint(IOracle(oracleAddr).getUSDsPrice()); //TODO: change to 3 days average
		uint precisionUSDs = IOracle(oracleAddr).USDsPricePrecision();
		uint smallPwithPrecision = swapFee_p.mul(precisionUSDs).div(swapFee_p_Prec);
		if (smallPwithPrecision < priceUSDs) {
			return swapFeePresion / 1000; // 0.1%
		} else {
			uint temp = (smallPwithPrecision - priceUSDs).mul(swapFee_theta).div(swapFee_theta_Prec); //precision: precisionUSDs
			uint temp2 = temp.mul(temp); //precision: precisionUSDs^2
			uint temp3 = temp2.mul(swapFeePresion).div(precisionUSDs).div(precisionUSDs);
			uint temp4 = temp3.div(100);
			return swapFeePresion / 1000 + temp4;
		}

	}

	function calculateSwapFeeOut() public view returns (uint) {
		if (!swapfeeOutAllowed) {
			return 0;
		}
		uint USDsInOutRatio = IOracle(oracleAddr).USDsInOutRatio();
		uint USDsInOutRatioPrecision = IOracle(oracleAddr).USDsInOutRatioPrecision();
		if (USDsInOutRatio <= uint(12).mul(USDsInOutRatioPrecision).div(10)) {
			return 1000; //0.1%
		} else {

			(uint powResWithPrec, uint8 powResPrec) = BancorInstance.power(uint(swapFee_A), uint(swapFee_A_Prec), swapFee_a, swapFee_a_Prec);
			return uint(powResWithPrec >> powResPrec).mul(10**4);
		}
	}

	function chiTarget(uint chiInit_, uint blockPassed, uint priceUSDs, uint precisionUSDs) public view returns (uint chiTarget_) {
		uint chiAdjustmentA = blockPassed.mul(chi_alpha).div(chi_alpha_Prec);
		uint chiAdjustmentB;
		if (priceUSDs > precisionUSDs) {
			chiAdjustmentB = chi_beta.mul(priceUSDs - precisionUSDs).mul(priceUSDs - precisionUSDs).div(chi_beta_Prec);
			chiTarget_ = chiInit_.sub(chiAdjustmentA).add(chiAdjustmentB);
		} else if (priceUSDs < precisionUSDs) {
			chiAdjustmentB = chi_beta.mul(precisionUSDs - priceUSDs).mul(precisionUSDs - priceUSDs).div(chi_beta_Prec);
			chiTarget_ = chiInit_.sub(chiAdjustmentA).sub(chiAdjustmentB);
		} else {
			chiTarget_ = chiInit_.sub(chiAdjustmentA);
		}
	}

	function chiMint() public view returns (uint)  {
		uint priceUSDs = uint(IOracle(oracleAddr).getUSDsPrice());
		uint precisionUSDs = IOracle(oracleAddr).USDsPricePrecision();
		uint blockPassed = uint(block.number).sub(startBlockHeight);
		return chiTarget(chiInit, blockPassed, priceUSDs, precisionUSDs);
	}

	function chiRedeem() public view returns (uint chiRedeem_) {
		uint priceUSDs = uint(IOracle(oracleAddr).getUSDsPrice());
		uint precisionUSDs = IOracle(oracleAddr).USDsPricePrecision();
		uint blockPassed = uint(block.number).sub(startBlockHeight);
		uint chiTarget_ = chiTarget(chiInit, blockPassed, priceUSDs, precisionUSDs);
		//uint collateralRatio_ = collateralRatio();
		uint collateralRatio_ = chiTarget_;
		if (chiTarget_ > collateralRatio_) {
			chiRedeem_ = chiTarget_.add(chi_gamma.mul(chiTarget_ - collateralRatio_).div(chi_gamma_Prec));
		} else {
			chiRedeem_ = chiTarget_;
		}

	}

	function mintWithUSDs(address collaAddr, uint USDsMintAmt)
		public
		whenMintRedeemAllowed
	{
		require(supportedCollat[collaAddr] > 0, "Collateral not supported");
		require(USDsMintAmt > 0, "Amount needs to be greater than 0");
		_mint(collaAddr, USDsMintAmt, 0);
	}

	function mintWithSPA(address collaAddr, uint SPAAmt)
		public
		whenMintRedeemAllowed
	{
		require(supportedCollat[collaAddr] > 0, "Collateral not supported");
		require(SPAAmt > 0, "Amount needs to be greater than 0");
		_mint(collaAddr, SPAAmt, 1);
	}

	function mintWithColla(address collaAddr, uint CollaAmt)
		public
		whenMintRedeemAllowed
	{
		require(supportedCollat[collaAddr] > 0, "Collateral not supported");
		require(CollaAmt > 0, "Amount needs to be greater than 0");
		_mint(collaAddr, CollaAmt, 2);
	}


	//View functions

	function mintWithUSDsView(address collaAddr, uint USDsMintAmt)
		public view returns (uint SPABurnAmt, uint CollaDepAmt, uint USDsAmt, uint swapFeeAmount)
	{
		require(supportedCollat[collaAddr] > 0, "Collateral not supported");
		require(USDsMintAmt > 0, "Amount needs to be greater than 0");
		(SPABurnAmt, CollaDepAmt, USDsAmt, swapFeeAmount) = mintView(collaAddr, USDsMintAmt, 0);
	}

	function mintWithSPAView(address collaAddr, uint SPAAmt)
		public view returns (uint SPABurnAmt, uint CollaDepAmt, uint USDsAmt, uint swapFeeAmount)
	{
		require(supportedCollat[collaAddr] > 0, "Collateral not supported");
		require(SPAAmt > 0, "Amount needs to be greater than 0");
		(SPABurnAmt, CollaDepAmt, USDsAmt, swapFeeAmount)  = mintView(collaAddr, SPAAmt, 1);
	}

	function mintWithCollaView(address collaAddr, uint CollaAmt)
		public view returns (uint SPABurnAmt, uint CollaDepAmt, uint USDsAmt, uint swapFeeAmount)
	{
		require(supportedCollat[collaAddr] > 0, "Collateral not supported");
		require(CollaAmt > 0, "Amount needs to be greater than 0");
		(SPABurnAmt, CollaDepAmt, USDsAmt, swapFeeAmount) = mintView(collaAddr, CollaAmt, 2);
	}

	// SPABurnAmt precision: 10^18
	// CollaDepAmt precision: 10^collaAddrDecimal
	// USDsAmt precision: 10^18
	// swapFeeAmount precision: swapFeePresion

	function mintView(
		address collaAddr,
		uint valueAmt,
		uint8 valueType
	) public view returns (uint SPABurnAmt, uint CollaDepAmt, uint USDsAmt, uint swapFeeAmount) {
		uint priceColla = IOracle(oracleAddr).collatPrice(collaAddr);
		uint precisionColla = IOracle(oracleAddr).collatPricePrecision(collaAddr);
		uint priceSPA = IOracle(oracleAddr).getSPAPrice();
		uint precisionSPA = IOracle(oracleAddr).SPAPricePrecision();
		uint swapFee = calculateSwapFeeIn();
		uint collaAddrDecimal = uint(ERC20Upgradeable(collaAddr).decimals());


		if (valueType == 0) {
			USDsAmt = valueAmt;
			SPABurnAmt = USDsAmt.mul(chiPrec - chiMint()).mul(precisionSPA).div(priceSPA.mul(chiPrec));
			if (swapFee > 0) {
				SPABurnAmt = SPABurnAmt.add(SPABurnAmt.mul(swapFee).div(swapFeePresion));
			}

			//Deposit collaeral
			uint CollaDepAmt_18 = USDsAmt.mul(chiMint()).mul(precisionColla).div(chiPrec.mul(priceColla));
			CollaDepAmt = CollaDepAmt_18.div(10**(uint(18).sub(collaAddrDecimal)));
			if (swapFee > 0) {
				CollaDepAmt = CollaDepAmt.add(CollaDepAmt.mul(swapFee).div(swapFeePresion));
			}

			swapFeeAmount = USDsAmt.mul(swapFee).div(swapFeePresion);
		} else if (valueType == 1) {
			SPABurnAmt = valueAmt;

			USDsAmt = SPABurnAmt;
			if (swapFee > 0) {
				USDsAmt = USDsAmt.div(1 + swapFee.div(swapFeePresion));
			}
			USDsAmt = USDsAmt.mul(chiPrec).mul(priceSPA).div(precisionSPA.mul(chiPrec - chiMint()));

			//Deposit collaeral
			uint CollaDepAmt_18 = USDsAmt.mul(chiMint()).mul(precisionColla).div(chiPrec.mul(priceColla));
			CollaDepAmt = CollaDepAmt_18.div(10**(uint(18).sub(collaAddrDecimal)));
			if (swapFee > 0) {
				CollaDepAmt = CollaDepAmt.add(CollaDepAmt.mul(swapFee).div(swapFeePresion));
			}

			swapFeeAmount = USDsAmt.mul(swapFee).div(swapFeePresion);
		} else if (valueType == 2) {
			CollaDepAmt = valueAmt;
			uint CollaDepAmt_18 = CollaDepAmt.mul(10**(uint(18).sub(collaAddrDecimal)));
			USDsAmt = CollaDepAmt_18.mul(chiPrec.mul(priceColla)).div(precisionColla).div(chiMint());

			SPABurnAmt = USDsAmt.mul(chiPrec - chiMint()).mul(precisionSPA).div(priceSPA.mul(chiPrec));
			if (swapFee > 0) {
				SPABurnAmt = SPABurnAmt.add(SPABurnAmt.mul(swapFee).div(swapFeePresion));
			}

			swapFeeAmount = USDsAmt.mul(swapFee).div(swapFeePresion);
		}


	}

	function _mint(
		address collaAddr,
		uint valueAmt,
		uint8 valueType
	) internal whenMintRedeemAllowed {
		(uint SPABurnAmt, uint CollaDepAmt, uint USDsAmt, uint swapFeeAmount) = mintView(collaAddr, valueAmt, valueType);
		ISperaxToken(SPATokenAddr).burnFrom(msg.sender, SPABurnAmt);
		ERC20Upgradeable(collaAddr).safeTransferFrom(msg.sender, collaValut, CollaDepAmt);
		USDsInstance.mint(msg.sender, USDsAmt);
		USDsInstance.mint(USDsFeeValut, swapFeeAmount);

	}

	function redeem(address collaAddr, uint USDsAmt)
		public
		whenMintRedeemAllowed
	{
		require(supportedCollat[collaAddr] > 0, "Collateral not supported");
		require(USDsAmt > 0, "Amount needs to be greater than 0");
		_redeem(collaAddr, USDsAmt);
	}


	function redeemView(
		address collaAddr,
		uint USDsAmt
	) public view returns (uint SPAMintAmt, uint CollaUnlockAmtCorrect, uint USDsBurntAmt, uint swapFeeAmount) {
		uint priceColla = IOracle(oracleAddr).collatPrice(collaAddr);
		uint precisionColla = IOracle(oracleAddr).collatPricePrecision(collaAddr);
		uint priceSPA = IOracle(oracleAddr).getSPAPrice();
		uint precisionSPA = IOracle(oracleAddr).SPAPricePrecision();
		uint swapFee = calculateSwapFeeOut();
		SPAMintAmt = USDsAmt.mul(chiPrec - chiRedeem()).mul(precisionSPA).div(priceSPA.mul(chiPrec));
		if (swapFee > 0) {
			SPAMintAmt = SPAMintAmt.sub(SPAMintAmt.mul(swapFee).div(swapFeePresion));
		}

		//Unlock collaeral
		uint CollaUnlockAmt = USDsAmt.mul(chiRedeem().mul(precisionColla)).div(chiPrec.mul(priceColla));
		if (swapFee > 0) {
			CollaUnlockAmt = CollaUnlockAmt.sub(CollaUnlockAmt.mul(swapFee).div(swapFeePresion));
		}
		uint collaAddrDecimal = uint(ERC20Upgradeable(collaAddr).decimals());
		CollaUnlockAmtCorrect =  CollaUnlockAmt.div(10**(uint(18).sub(collaAddrDecimal)));

		//Burn USDs
		swapFeeAmount = USDsAmt.mul(swapFee).div(swapFeePresion);
		USDsBurntAmt =  USDsAmt.sub(swapFeeAmount);
	}

	function _redeem(
		address collaAddr,
		uint USDsAmt
	) internal whenMintRedeemAllowed {
		(uint SPAMintAmt, uint CollaUnlockAmtCorrect, uint USDsBurntAmt, uint swapFeeAmount) = redeemView(collaAddr, USDsAmt);
		ERC20Upgradeable(collaAddr).safeTransferFrom(SPAValut, msg.sender, SPAMintAmt);
		ERC20Upgradeable(collaAddr).safeTransferFrom(collaValut, msg.sender, CollaUnlockAmtCorrect);
		USDsInstance.burn(msg.sender, USDsBurntAmt);
		USDsInstance.transferFrom(msg.sender, USDsFeeValut, swapFeeAmount);

	}

	/**
	 * @dev Calculate the total value of assets held by the Vault and all
	 *      strategies and update the supply of USDs.
	 */
	function rebase() public {
		_rebase();
	}

	/**
	 * @dev Calculate the total value of assets held by the Vault and all
	 *      strategies and update the supply of USDs, optionaly sending a
	 *      portion of the yield to the trustee.
	 */
	function _rebase() internal {
		uint256 totalSupply = USDsInstance.totalSupply();
		uint256 vaultValue = _totalValue();

		if (vaultValue > totalSupply && totalSupply != 0) {
			USDsInstance.changeSupply(vaultValue);
		}
	}

	/**
	 * @dev  Precision: same as chi
	 */

	function collateralRatio() public view returns (uint256 ratio) {
        uint totalValue = _totalValue();
		uint USDsSupply =  USDsInstance.totalSupply();
		ratio = totalValue.mul(chiPrec).div(USDsSupply);
    }

	/**
     * @dev Determine the total value of assets held by the vault and its
     *         strategies.
     * @return value Total value in USD (1e18)
     */
    function totalValue() external view returns (uint256 value) {
        value = _totalValue();
    }

    /**
     * @dev Internal Calculate the total value of the assets held by the
     *         vault and its strategies.
     * @return value Total value in USD (1e18)
     */
    function _totalValue() internal view returns (uint256 value) {
        return _totalValueInVault().add(_totalValueInStrategies());
    }

    /**
     * @dev Internal to calculate total value of all assets held in Vault.
     * @return value in ETH (1e18)
     */
    function _totalValueInVault() internal view returns (uint256 value) {
        // for (uint256 y = 0; y < allCollat.length; y++) {
        //     ERC20Upgradeable asset = ERC20Upgradeable(allCollat[y]);
        //     uint256 assetDecimals = Helpers.getDecimals(allCollat[y]);
        //     uint256 balance = asset.balanceOf(address(this));
        //     if (balance > 0) {
        //         value = value.add(balance.scaleBy(int8(18 - assetDecimals)));
        //     }
        // }
    }

    /**
     * @dev Internal to calculate total value of all assets held in Strategies.
     * @return value in ETH (1e18)
     */
    function _totalValueInStrategies() internal view returns (uint256 value) {
        for (uint256 i = 0; i < allStrategies.length; i++) {
            value = value.add(_totalValueInStrategy(allStrategies[i]));
        }
    }

    /**
     * @dev Internal to calculate total value of all assets held by strategy.
     * @param _strategyAddr Address of the strategy
     * @return value in ETH (1e18)
     */
    function _totalValueInStrategy(address _strategyAddr)
        internal
        view
        returns (uint256 value)
    {
        value = 0;
    }

	/**
     * @notice Get the balance of an asset held in Vault and all strategies.
     * @param _asset Address of asset
     * @return uint256 Balance of asset in decimals of asset
     */
    function checkBalance(address _asset) external view returns (uint256) {
        return _checkBalance(_asset);
    }

    /**
     * @notice Get the balance of an asset held in Vault and all strategies.
     * @param _asset Address of asset
     * @return balance Balance of asset in decimals of asset
     */
    function _checkBalance(address _asset)
        internal
        view
        returns (uint256 balance)
    {
        ERC20Upgradeable asset = ERC20Upgradeable(_asset);
        balance = asset.balanceOf(address(this));
        // for (uint256 i = 0; i < allStrategies.length; i++) {
        //     IStrategy strategy = IStrategy(allStrategies[i]);
        //     if (strategy.supportsAsset(_asset)) {
        //         balance = balance.add(strategy.checkBalance(_asset));
        //     }
        // }
    }

    //
    // Owner Only Function: change swap fee allowance
    //

    function toggleSwapfeeInAllowed(bool newAllowance) external onlyOwner {
      swapfeeInAllowed = newAllowance;
    }

    function toggleSwapfeeOutAllowed(bool newAllowance) external onlyOwner {
      swapfeeOutAllowed = newAllowance;
    }

    function updateCollateralList(address collatAddress, bool allowance) external onlyOwner {
			if (allowance) {
				require(supportedCollat[collatAddress] == 0, "Collateral already allowed");
				allCollat.push(collatAddress);
				supportedCollat[collatAddress] = allCollat.length;
			} else {
				require(supportedCollat[collatAddress] > 0, "Collateral not allowed");
				allCollat[supportedCollat[collatAddress] - 1] = allCollat[allCollat.length - 1];
				allCollat.pop();
				delete supportedCollat[collatAddress];
			}
    }
}