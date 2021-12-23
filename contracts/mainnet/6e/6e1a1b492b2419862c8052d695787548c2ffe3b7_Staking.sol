/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity ^0.7.0;

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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity ^0.7.0;


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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

pragma solidity ^0.7.0;

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


// File @openzeppelin/contracts-upgradeable/math/[email protected]

pragma solidity ^0.7.0;

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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

pragma solidity ^0.7.0;



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


// File @openzeppelin/contracts/math/[email protected]

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// File @openzeppelin/contracts/math/[email protected]

pragma solidity ^0.7.0;

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


// File contracts/interfaces/IDistributor.sol

pragma solidity ^0.7.6;

interface IDistributor {
  /// @dev distribute ALD reward to Aladdin Staking contract.
  function distribute() external;
}


// File contracts/interfaces/IStaking.sol

pragma solidity ^0.7.6;

interface IStaking {
  function stake(uint256 _amount) external;

  function stakeFor(address _recipient, uint256 _amount) external;

  function unstake(address _recipient, uint256 _amount) external;

  function unstakeAll(address _recipient) external;

  function bondFor(address _recipient, uint256 _amount) external;

  function rewardBond(address _vault, uint256 _amount) external;

  function rebase() external;

  function redeem(address _recipient, bool _withdraw) external;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.7.0;

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


// File contracts/interfaces/IXALD.sol

pragma solidity ^0.7.6;

interface IXALD is IERC20 {
  function stake(address _recipient, uint256 _aldAmount) external;

  function unstake(address _account, uint256 _xALDAmount) external;

  function rebase(uint256 epoch, uint256 profit) external;

  function getSharesByALD(uint256 _aldAmount) external view returns (uint256);

  function getALDByShares(uint256 _sharesAmount) external view returns (uint256);
}


// File contracts/interfaces/IWXALD.sol

pragma solidity ^0.7.6;

interface IWXALD {
  function wrap(uint256 _xALDAmount) external returns (uint256);

  function unwrap(uint256 _wxALDAmount) external returns (uint256);

  function wrappedXALDToXALD(uint256 _wxALDAmount) external view returns (uint256);
}


// File contracts/interfaces/IRewardBondDepositor.sol

pragma solidity ^0.7.6;

interface IRewardBondDepositor {
  function currentEpoch()
    external
    view
    returns (
      uint64 epochNumber,
      uint64 startBlock,
      uint64 nextBlock,
      uint64 epochLength
    );

  function rewardShares(uint256 _epoch, address _vault) external view returns (uint256);

  function getVaultsFromAccount(address _user) external view returns (address[] memory);

  function getAccountRewardShareSince(
    uint256 _epoch,
    address _user,
    address _vault
  ) external view returns (uint256[] memory);

  function bond(address _vault) external;

  function rebase() external;

  function notifyRewards(address _user, uint256[] memory _amounts) external;
}


// File contracts/stake/Staking.sol

pragma solidity ^0.7.6;









contract Staking is OwnableUpgradeable, IStaking {
  using SafeMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event Bond(address indexed recipient, uint256 aldAmount, uint256 wxALDAmount);
  event RewardBond(address indexed vault, uint256 aldAmount, uint256 wxALDAmount);
  event Stake(address indexed caller, address indexed recipient, uint256 amount);
  event Unstake(address indexed caller, address indexed recipient, uint256 amount);
  event Redeem(address indexed caller, address indexed recipient, uint256 amount);

  struct UserLockedBalance {
    // The amount of wxALD locked.
    uint192 amount;
    // The block number when the lock starts.
    uint32 lockedBlock;
    // The block number when the lock ends.
    uint32 unlockBlock;
  }

  struct RewardBondBalance {
    // The block number when the lock starts.
    uint32 lockedBlock;
    // The block number when the lock ends.
    uint32 unlockBlock;
    // Mapping from vault address to the amount of wxALD locked.
    mapping(address => uint256) amounts;
  }

  struct Checkpoint {
    uint128 epochNumber;
    uint128 blockNumber;
  }

  // The address of governor.
  address public governor;

  // The address of ALD token.
  address public ALD;
  // The address of xALD token.
  address public xALD;
  // The address of wxALD token.
  address public wxALD;
  // The address of direct bond contract.
  address public directBondDepositor;
  // The address of vault reward bond contract.
  address public rewardBondDepositor;

  // The address of distributor.
  address public distributor;

  // Whether staking is paused.
  bool public paused;

  // Whether to enable whitelist mode.
  bool public enableWhitelist;
  mapping(address => bool) public isWhitelist;

  // Whether an address is in black list
  mapping(address => bool) public blacklist;

  // The default locking period in epoch.
  uint256 public defaultLockingPeriod;
  // The bond locking period in epoch.
  uint256 public bondLockingPeriod;
  // Mapping from user address to locking period in epoch.
  mapping(address => uint256) public lockingPeriod;

  // Mapping from user address to staked ald balances.
  mapping(address => UserLockedBalance[]) private userStakedLocks;
  // Mapping from user address to asset bond ald balances.
  mapping(address => UserLockedBalance[]) private userDirectBondLocks;
  // Mapping from user address to reward bond ald balances.
  mapping(address => UserLockedBalance[]) private userRewardBondLocks;

  // The list of reward bond ald locks.
  // 65536 epoch is about 170 year, assuming 1 epoch = 1 day.
  RewardBondBalance[65536] public rewardBondLocks;

  // Mapping from user address to lastest interacted epoch/block number.
  mapping(address => Checkpoint) private checkpoint;

  modifier notPaused() {
    require(!paused, "Staking: paused");
    _;
  }

  modifier onlyGovernor() {
    require(msg.sender == governor || msg.sender == owner(), "Treasury: only governor");
    _;
  }

  /// @param _ALD The address of ALD token.
  /// @param _xALD The address of xALD token.
  /// @param _wxALD The address of wxALD token.
  /// @param _rewardBondDepositor The address of reward bond contract.
  function initialize(
    address _ALD,
    address _xALD,
    address _wxALD,
    address _rewardBondDepositor
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    require(_ALD != address(0), "Treasury: zero address");
    require(_xALD != address(0), "Treasury: zero address");
    require(_wxALD != address(0), "Treasury: zero address");
    require(_rewardBondDepositor != address(0), "Treasury: zero address");

    ALD = _ALD;
    xALD = _xALD;
    wxALD = _wxALD;

    IERC20Upgradeable(_xALD).safeApprove(_wxALD, uint256(-1));

    paused = true;
    enableWhitelist = true;

    defaultLockingPeriod = 90;
    bondLockingPeriod = 5;

    rewardBondDepositor = _rewardBondDepositor;
  }

  /********************************** View Functions **********************************/

  /// @dev return the full vested block (staking and bond) for given user
  /// @param _user The address of user;
  function fullyVestedBlock(address _user) external view returns (uint256, uint256) {
    uint256 stakeVestedBlock;
    {
      UserLockedBalance[] storage _locks = userStakedLocks[_user];
      for (uint256 i = 0; i < _locks.length; i++) {
        UserLockedBalance storage _lock = _locks[i];
        if (_lock.amount > 0) {
          stakeVestedBlock = Math.max(stakeVestedBlock, _lock.unlockBlock);
        }
      }
    }
    uint256 bondVestedBlock;
    {
      UserLockedBalance[] storage _locks = userDirectBondLocks[_user];
      for (uint256 i = 0; i < _locks.length; i++) {
        UserLockedBalance storage _lock = _locks[i];
        if (_lock.amount > 0) {
          bondVestedBlock = Math.max(bondVestedBlock, _lock.unlockBlock);
        }
      }
    }
    return (stakeVestedBlock, bondVestedBlock);
  }

  /// @dev return the pending xALD amount including locked and unlocked.
  /// @param _user The address of user.
  function pendingXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;
    uint256 _lastEpoch = checkpoint[_user].epochNumber;

    uint256 pendingAmount = _getPendingWithList(userStakedLocks[_user], _lastBlock);
    pendingAmount = pendingAmount.add(_getPendingWithList(userDirectBondLocks[_user], _lastBlock));
    pendingAmount = pendingAmount.add(_getPendingWithList(userRewardBondLocks[_user], _lastBlock));
    pendingAmount = pendingAmount.add(_getPendingRewardBond(_user, _lastEpoch, _lastBlock));

    return IWXALD(wxALD).wrappedXALDToXALD(pendingAmount);
  }

  /// @dev return the pending xALD amount from user staking, including locked and unlocked.
  /// @param _user The address of user.
  function pendingStakedXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;

    uint256 pendingAmount = _getPendingWithList(userStakedLocks[_user], _lastBlock);

    return IWXALD(wxALD).wrappedXALDToXALD(pendingAmount);
  }

  /// @dev return the pending xALD amount from user bond, including locked and unlocked.
  /// @param _user The address of user.
  function pendingBondXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;

    uint256 pendingAmount = _getPendingWithList(userDirectBondLocks[_user], _lastBlock);

    return IWXALD(wxALD).wrappedXALDToXALD(pendingAmount);
  }

  /// @dev return the pending xALD amount from user vault reward, including locked and unlocked.
  /// @param _user The address of user.
  /// @param _vault The address of vault.
  function pendingXALDByVault(address _user, address _vault) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;
    uint256 _startEpoch = _findPossibleStartEpoch(_user, _lastBlock);

    uint256 pendingAmount = _getPendingRewardBondByVault(_user, _vault, _startEpoch, _lastBlock);

    return IWXALD(wxALD).wrappedXALDToXALD(pendingAmount);
  }

  /// @dev return the unlocked xALD amount.
  /// @param _user The address of user.
  function unlockedXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;
    uint256 _lastEpoch = checkpoint[_user].epochNumber;

    uint256 unlockedAmount = _getRedeemableWithList(userStakedLocks[_user], _lastBlock);
    unlockedAmount = unlockedAmount.add(_getRedeemableWithList(userDirectBondLocks[_user], _lastBlock));
    unlockedAmount = unlockedAmount.add(_getRedeemableWithList(userRewardBondLocks[_user], _lastBlock));
    unlockedAmount = unlockedAmount.add(_getRedeemableRewardBond(_user, _lastEpoch, _lastBlock));

    return IWXALD(wxALD).wrappedXALDToXALD(unlockedAmount);
  }

  /// @dev return the unlocked xALD amount from user staking.
  /// @param _user The address of user.
  function unlockedStakedXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;

    uint256 unlockedAmount = _getRedeemableWithList(userStakedLocks[_user], _lastBlock);

    return IWXALD(wxALD).wrappedXALDToXALD(unlockedAmount);
  }

  /// @dev return the unlocked xALD amount from user bond.
  /// @param _user The address of user.
  function unlockedBondXALD(address _user) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;

    uint256 unlockedAmount = _getRedeemableWithList(userDirectBondLocks[_user], _lastBlock);

    return IWXALD(wxALD).wrappedXALDToXALD(unlockedAmount);
  }

  /// @dev return the unlocked xALD amount from user vault reward.
  /// @param _user The address of user.
  /// @param _vault The address of vault.
  function unlockedXALDByVault(address _user, address _vault) external view returns (uint256) {
    // be carefull when no checkpoint for _user
    uint256 _lastBlock = checkpoint[_user].blockNumber;
    uint256 _startEpoch = _findPossibleStartEpoch(_user, _lastBlock);

    uint256 pendingAmount = _getRedeemableRewardBondByVault(_user, _vault, _startEpoch, _lastBlock);

    return IWXALD(wxALD).wrappedXALDToXALD(pendingAmount);
  }

  /********************************** Mutated Functions **********************************/

  /// @dev stake all ALD for xALD.
  function stakeAll() external notPaused {
    if (enableWhitelist) {
      require(isWhitelist[msg.sender], "Staking: not whitelist");
    }

    uint256 _amount = IERC20Upgradeable(ALD).balanceOf(msg.sender);
    _amount = _transferAndWrap(msg.sender, _amount);
    _stakeFor(msg.sender, _amount);
  }

  /// @dev stake ALD for xALD.
  /// @param _amount The amount of ALD to stake.
  function stake(uint256 _amount) external override notPaused {
    if (enableWhitelist) {
      require(isWhitelist[msg.sender], "Staking: not whitelist");
    }

    _amount = _transferAndWrap(msg.sender, _amount);
    _stakeFor(msg.sender, _amount);
  }

  /// @dev stake ALD for others.
  /// @param _recipient The address to receipt xALD.
  /// @param _amount The amount of ALD to stake.
  function stakeFor(address _recipient, uint256 _amount) external override notPaused {
    if (enableWhitelist) {
      require(isWhitelist[msg.sender], "Staking: not whitelist");
    }

    _amount = _transferAndWrap(msg.sender, _amount);
    _stakeFor(_recipient, _amount);
  }

  /// @dev unstake xALD to ALD.
  /// @param _recipient The address to receipt ALD.
  /// @param _amount The amount of xALD to unstake.
  function unstake(address _recipient, uint256 _amount) external override notPaused {
    _unstake(_recipient, _amount);
  }

  /// @dev unstake all xALD to ALD.
  /// @param _recipient The address to receipt ALD.
  function unstakeAll(address _recipient) external override notPaused {
    uint256 _amount = IXALD(xALD).balanceOf(msg.sender);
    _unstake(_recipient, _amount);
  }

  /// @dev bond ALD from direct asset. only called by DirectBondDepositor contract.
  /// @notice all bond on the same epoch are grouped at the expected start block of next epoch.
  /// @param _recipient The address to receipt xALD.
  /// @param _amount The amount of ALD to stake.
  function bondFor(address _recipient, uint256 _amount) external override notPaused {
    require(directBondDepositor == msg.sender, "Staking: not approved");
    uint256 _wxALDAmount = _transferAndWrap(msg.sender, _amount);

    // bond lock logic
    (, , uint256 nextBlock, uint256 epochLength) = IRewardBondDepositor(rewardBondDepositor).currentEpoch();
    UserLockedBalance[] storage _locks = userDirectBondLocks[_recipient];
    uint256 length = _locks.length;

    if (length == 0 || _locks[length - 1].lockedBlock != nextBlock) {
      _locks.push(
        UserLockedBalance({
          amount: uint192(_wxALDAmount),
          lockedBlock: uint32(nextBlock),
          unlockBlock: uint32(nextBlock + epochLength * bondLockingPeriod)
        })
      );
    } else {
      _locks[length - 1].amount = uint192(uint256(_locks[length - 1].amount).add(_wxALDAmount));
    }

    emit Bond(_recipient, _amount, _wxALDAmount);
  }

  /// @dev bond ALD from vault reward. only called by RewardBondDepositor contract.
  /// @notice all bond on the same epoch are grouped at the expected start block of next epoch.
  /// @param _vault The address of vault.
  /// @param _amount The amount of ALD to stake.
  function rewardBond(address _vault, uint256 _amount) external override notPaused {
    require(rewardBondDepositor == msg.sender, "Staking: not approved");
    uint256 _wxALDAmount = _transferAndWrap(msg.sender, _amount);

    (uint256 epochNumber, , uint256 nextBlock, uint256 epochLength) = IRewardBondDepositor(rewardBondDepositor)
      .currentEpoch();
    RewardBondBalance storage _lock = rewardBondLocks[epochNumber];

    if (_lock.lockedBlock == 0) {
      // first bond in current epoch
      _lock.lockedBlock = uint32(nextBlock);
      _lock.unlockBlock = uint32(nextBlock + epochLength * bondLockingPeriod);
    }
    _lock.amounts[_vault] = _lock.amounts[_vault].add(_wxALDAmount);

    emit RewardBond(_vault, _amount, _wxALDAmount);
  }

  /// @dev mint ALD reward for stakers.
  /// @notice assume it is called in `rebase()` from contract `rewardBondDepositor`.
  function rebase() external override notPaused {
    require(rewardBondDepositor == msg.sender, "Staking: not approved");

    if (distributor != address(0)) {
      uint256 _pool = IERC20Upgradeable(ALD).balanceOf(address(this));
      IDistributor(distributor).distribute();
      uint256 _distributed = IERC20Upgradeable(ALD).balanceOf(address(this)).sub(_pool);

      (uint256 epochNumber, , , ) = IRewardBondDepositor(rewardBondDepositor).currentEpoch();
      IXALD(xALD).rebase(epochNumber, _distributed);
    }
  }

  /// @dev redeem unlocked xALD from contract.
  /// @param _recipient The address to receive xALD/ALD.
  /// @param __unstake Whether to unstake xALD to ALD.
  function redeem(address _recipient, bool __unstake) external override notPaused {
    require(!blacklist[msg.sender], "Staking: blacklist");

    // be carefull when no checkpoint for msg.sender
    uint256 _lastBlock = checkpoint[msg.sender].blockNumber;
    uint256 _lastEpoch = checkpoint[msg.sender].epochNumber;
    if (_lastBlock == block.number) {
      return;
    }

    uint256 unlockedAmount = _redeemWithList(userStakedLocks[msg.sender], _lastBlock);
    unlockedAmount = unlockedAmount.add(_redeemWithList(userDirectBondLocks[msg.sender], _lastBlock));
    unlockedAmount = unlockedAmount.add(_redeemWithList(userRewardBondLocks[msg.sender], _lastBlock));
    unlockedAmount = unlockedAmount.add(_redeemRewardBondLocks(msg.sender, _lastEpoch, _lastBlock));

    // find the unlocked xALD amount
    unlockedAmount = IWXALD(wxALD).unwrap(unlockedAmount);

    emit Redeem(msg.sender, _recipient, unlockedAmount);

    if (__unstake) {
      IXALD(xALD).unstake(address(this), unlockedAmount);
      IERC20Upgradeable(ALD).safeTransfer(_recipient, unlockedAmount);
      emit Unstake(msg.sender, _recipient, unlockedAmount);
    } else {
      IERC20Upgradeable(xALD).safeTransfer(_recipient, unlockedAmount);
    }

    (uint256 epochNumber, , , ) = IRewardBondDepositor(rewardBondDepositor).currentEpoch();

    checkpoint[msg.sender] = Checkpoint({ blockNumber: uint128(block.number), epochNumber: uint128(epochNumber) });
  }

  /********************************** Restricted Functions **********************************/

  function updateGovernor(address _governor) external onlyOwner {
    governor = _governor;
  }

  function updateDistributor(address _distributor) external onlyOwner {
    distributor = _distributor;
  }

  function updatePaused(bool _paused) external onlyGovernor {
    paused = _paused;
  }

  function updateEnableWhitelist(bool _enableWhitelist) external onlyOwner {
    enableWhitelist = _enableWhitelist;
  }

  function updateWhitelist(address[] memory _users, bool status) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      isWhitelist[_users[i]] = status;
    }
  }

  function updateBlacklist(address[] memory _users, bool status) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      blacklist[_users[i]] = status;
    }
  }

  function updateBongLockingPeriod(uint256 _bondLockingPeriod) external onlyOwner {
    bondLockingPeriod = _bondLockingPeriod;
  }

  function updateDefaultLockingPeriod(uint256 _defaultLockingPeriod) external onlyOwner {
    defaultLockingPeriod = _defaultLockingPeriod;
  }

  function updateLockingPeriod(address[] memory _users, uint256[] memory _periods) external onlyOwner {
    require(_users.length == _periods.length, "Staking: length mismatch");
    for (uint256 i = 0; i < _users.length; i++) {
      lockingPeriod[_users[i]] = _periods[i];
    }
  }

  function updateDirectBondDepositor(address _directBondDepositor) external onlyOwner {
    require(_directBondDepositor != address(0), "Treasury: zero address");

    directBondDepositor = _directBondDepositor;
  }

  /********************************** Internal Functions **********************************/

  /// @dev all stakes on the same epoch are grouped at the expected start block of next epoch.
  /// @param _recipient The address of recipient who receives xALD.
  /// @param _amount The amount of wxALD for the recipient.
  function _stakeFor(address _recipient, uint256 _amount) internal {
    (, , uint256 nextBlock, uint256 epochLength) = IRewardBondDepositor(rewardBondDepositor).currentEpoch();
    UserLockedBalance[] storage _locks = userStakedLocks[_recipient];
    uint256 length = _locks.length;

    // stake lock logic
    if (length == 0 || _locks[length - 1].lockedBlock != nextBlock) {
      uint256 _period = _lockingPeriod(_recipient);

      _locks.push(
        UserLockedBalance({
          amount: uint192(_amount),
          lockedBlock: uint32(nextBlock),
          unlockBlock: uint32(nextBlock + epochLength * _period)
        })
      );
    } else {
      _locks[length - 1].amount = uint192(uint256(_locks[length - 1].amount).add(_amount));
    }

    emit Stake(msg.sender, _recipient, _amount);
  }

  function _unstake(address _recipient, uint256 _amount) internal {
    IXALD(xALD).unstake(msg.sender, _amount);
    IERC20Upgradeable(ALD).safeTransfer(_recipient, _amount);

    emit Unstake(msg.sender, _recipient, _amount);
  }

  function _lockingPeriod(address _user) internal view returns (uint256) {
    uint256 _period = lockingPeriod[_user];
    if (_period == 0) return defaultLockingPeriod;
    else return _period;
  }

  function _transferAndWrap(address _sender, uint256 _amount) internal returns (uint256) {
    IERC20Upgradeable(ALD).safeTransferFrom(_sender, address(this), _amount);
    IXALD(xALD).stake(address(this), _amount);
    return IWXALD(wxALD).wrap(_amount);
  }

  function _redeemRewardBondLocks(
    address _user,
    uint256 _lastEpoch,
    uint256 _lastBlock
  ) internal returns (uint256) {
    uint256 unlockedAmount;

    address[] memory _vaults = IRewardBondDepositor(rewardBondDepositor).getVaultsFromAccount(_user);
    for (uint256 i = 0; i < _vaults.length; i++) {
      unlockedAmount = unlockedAmount.add(_redeemRewardBondLocksByVault(_user, _vaults[i], _lastEpoch, _lastBlock));
    }

    return unlockedAmount;
  }

  function _redeemRewardBondLocksByVault(
    address _user,
    address _vault,
    uint256 _startEpoch,
    uint256 _lastBlock
  ) internal returns (uint256) {
    IRewardBondDepositor _depositor = IRewardBondDepositor(rewardBondDepositor); // gas saving
    UserLockedBalance[] storage _locks = userRewardBondLocks[_user];
    uint256 unlockedAmount;

    uint256[] memory _shares = _depositor.getAccountRewardShareSince(_startEpoch, _user, _vault);
    for (uint256 i = 0; i < _shares.length; i++) {
      if (_shares[i] == 0) continue;

      uint256 _epoch = _startEpoch + i;
      uint256 _amount = rewardBondLocks[_epoch].amounts[_vault];
      {
        uint256 _totalShare = _depositor.rewardShares(_epoch, _vault);
        _amount = _amount.mul(_shares[i]).div(_totalShare);
      }
      uint256 _lockedBlock = rewardBondLocks[_epoch].lockedBlock;
      uint256 _unlockBlock = rewardBondLocks[_epoch].unlockBlock;

      // [_lockedBlock, _unlockBlock), [_lastBlock + 1, block.number + 1)
      uint256 _left = Math.max(_lockedBlock, _lastBlock + 1);
      uint256 _right = Math.min(_unlockBlock, block.number + 1);
      if (_left < _right) {
        unlockedAmount = unlockedAmount.add(_amount.mul(_right - _left).div(_unlockBlock - _lockedBlock));
      }
      // some reward unlocked
      if (_unlockBlock > block.number + 1) {
        _locks.push(
          UserLockedBalance({
            amount: uint192(_amount),
            lockedBlock: uint32(_lockedBlock),
            unlockBlock: uint32(_unlockBlock)
          })
        );
      }
    }
    return unlockedAmount;
  }

  function _redeemWithList(UserLockedBalance[] storage _locks, uint256 _lastBlock) internal returns (uint256) {
    uint256 length = _locks.length;
    uint256 unlockedAmount = 0;

    for (uint256 i = 0; i < length; ) {
      uint256 _amount = _locks[i].amount;
      uint256 _startBlock = _locks[i].lockedBlock;
      uint256 _endBlock = _locks[i].unlockBlock;
      if (_amount > 0 && _startBlock <= block.number) {
        // in this case: _endBlock must greater than _lastBlock
        uint256 _left = Math.max(_lastBlock + 1, _startBlock);
        uint256 _right = Math.min(block.number + 1, _endBlock);
        unlockedAmount = unlockedAmount.add(_amount.mul(_right - _left).div(_endBlock - _startBlock));
        if (_endBlock <= block.number) {
          // since the order is not important
          // use swap and delete to reduce the length of array
          length -= 1;
          _locks[i] = _locks[length];
          delete _locks[length];
          _locks.pop();
        } else {
          i++;
        }
      }
    }

    return unlockedAmount;
  }

  function _getRedeemableWithList(UserLockedBalance[] storage _locks, uint256 _lastBlock)
    internal
    view
    returns (uint256)
  {
    uint256 length = _locks.length;
    uint256 unlockedAmount = 0;

    for (uint256 i = 0; i < length; i++) {
      uint256 _amount = _locks[i].amount;
      uint256 _startBlock = _locks[i].lockedBlock;
      uint256 _endBlock = _locks[i].unlockBlock;
      if (_amount > 0 && _startBlock <= block.number) {
        // in this case: _endBlock must greater than _lastBlock
        uint256 _left = Math.max(_lastBlock + 1, _startBlock);
        uint256 _right = Math.min(block.number + 1, _endBlock);
        unlockedAmount = unlockedAmount.add(_amount.mul(_right - _left).div(_endBlock - _startBlock));
      }
    }

    return unlockedAmount;
  }

  function _getPendingWithList(UserLockedBalance[] storage _locks, uint256 _lastBlock) internal view returns (uint256) {
    uint256 length = _locks.length;
    uint256 pendingAmount = 0;

    for (uint256 i = 0; i < length; i++) {
      uint256 _amount = _locks[i].amount;
      uint256 _startBlock = _locks[i].lockedBlock;
      uint256 _endBlock = _locks[i].unlockBlock;
      // [_startBlock, _endBlock), [_lastBlock + 1, oo)
      if (_amount > 0 && _endBlock > _lastBlock + 1) {
        // in this case: _endBlock must greater than _lastBlock
        uint256 _left = Math.max(_lastBlock + 1, _startBlock);
        pendingAmount = pendingAmount.add(_amount.mul(_endBlock - _left).div(_endBlock - _startBlock));
      }
    }

    return pendingAmount;
  }

  function _getRedeemableRewardBond(
    address _user,
    uint256 _lastEpoch,
    uint256 _lastBlock
  ) internal view returns (uint256) {
    uint256 unlockedAmount;
    address[] memory _vaults = IRewardBondDepositor(rewardBondDepositor).getVaultsFromAccount(_user);

    for (uint256 i = 0; i < _vaults.length; i++) {
      unlockedAmount = unlockedAmount.add(_getRedeemableRewardBondByVault(_user, _vaults[i], _lastEpoch, _lastBlock));
    }

    return unlockedAmount;
  }

  function _getPendingRewardBond(
    address _user,
    uint256 _lastEpoch,
    uint256 _lastBlock
  ) internal view returns (uint256) {
    uint256 pendingAmount;
    address[] memory _vaults = IRewardBondDepositor(rewardBondDepositor).getVaultsFromAccount(_user);

    for (uint256 i = 0; i < _vaults.length; i++) {
      pendingAmount = pendingAmount.add(_getPendingRewardBondByVault(_user, _vaults[i], _lastEpoch, _lastBlock));
    }

    return pendingAmount;
  }

  function _getRedeemableRewardBondByVault(
    address _user,
    address _vault,
    uint256 _startEpoch,
    uint256 _lastBlock
  ) internal view returns (uint256) {
    IRewardBondDepositor _depositor = IRewardBondDepositor(rewardBondDepositor); // gas saving
    uint256 unlockedAmount;

    uint256[] memory _shares = _depositor.getAccountRewardShareSince(_startEpoch, _user, _vault);
    for (uint256 i = 0; i < _shares.length; i++) {
      if (_shares[i] == 0) continue;

      uint256 _epoch = _startEpoch + i;
      uint256 _unlockBlock = rewardBondLocks[_epoch].unlockBlock;
      if (_unlockBlock <= _lastBlock + 1) continue;

      uint256 _amount = rewardBondLocks[_epoch].amounts[_vault];
      uint256 _lockedBlock = rewardBondLocks[_epoch].lockedBlock;
      {
        uint256 _totalShare = _depositor.rewardShares(_epoch, _vault);
        _amount = _amount.mul(_shares[i]).div(_totalShare);
      }
      // [_lockedBlock, _unlockBlock), [_lastBlock + 1, block.number + 1)
      uint256 _left = Math.max(_lockedBlock, _lastBlock + 1);
      uint256 _right = Math.min(_unlockBlock, block.number + 1);
      if (_left < _right) {
        unlockedAmount = unlockedAmount.add(_amount.mul(_right - _left).div(_unlockBlock - _lockedBlock));
      }
    }
    return unlockedAmount;
  }

  function _getPendingRewardBondByVault(
    address _user,
    address _vault,
    uint256 _startEpoch,
    uint256 _lastBlock
  ) internal view returns (uint256) {
    IRewardBondDepositor _depositor = IRewardBondDepositor(rewardBondDepositor); // gas saving
    uint256 pendingAmount;

    uint256[] memory _shares = _depositor.getAccountRewardShareSince(_startEpoch, _user, _vault);
    for (uint256 i = 0; i < _shares.length; i++) {
      if (_shares[i] == 0) continue;

      uint256 _epoch = _startEpoch + i;
      uint256 _unlockBlock = rewardBondLocks[_epoch].unlockBlock;
      if (_unlockBlock <= _lastBlock + 1) continue;

      uint256 _amount = rewardBondLocks[_epoch].amounts[_vault];
      uint256 _lockedBlock = rewardBondLocks[_epoch].lockedBlock;
      {
        uint256 _totalShare = _depositor.rewardShares(_epoch, _vault);
        _amount = _amount.mul(_shares[i]).div(_totalShare);
      }
      // [_lockedBlock, _unlockBlock), [_lastBlock + 1, oo)
      uint256 _left = Math.max(_lockedBlock, _lastBlock + 1);
      if (_left < _unlockBlock) {
        pendingAmount = pendingAmount.add(_amount.mul(_unlockBlock - _left).div(_unlockBlock - _lockedBlock));
      }
    }
    return pendingAmount;
  }

  /// @dev Find the possible start epoch for current user to calculate pending/unlocked ALD for vault.
  /// @param _user The address of user.
  /// @param _lastBlock The last block user interacted with the contract.
  function _findPossibleStartEpoch(address _user, uint256 _lastBlock) internal view returns (uint256) {
    uint256 _minLockedBlock = _findEarlistRewardLockedBlock(_user);
    uint256 _lastEpoch = checkpoint[_user].epochNumber;
    if (_minLockedBlock == 0) {
      // No locks available or all locked ALD are redeemed, in this case,
      //  + _lastBlock = 0: user didn't interact with the contract, we should calculate from the first epoch
      //  + _lastBlock != 0: user has interacted with the contract, we should calculate from the last epoch
      if (_lastBlock == 0) return 0;
      else return _lastEpoch;
    } else {
      // Locks available, we should find the epoch number by searching _minLockedBlock
      return _findEpochByLockedBlock(_minLockedBlock, _lastEpoch);
    }
  }

  /// @dev find the epoch whose lockedBlock is `_lockedBlock`.
  /// @param _lockedBlock the epoch to find
  /// @param _epochHint the hint for search the epoch
  function _findEpochByLockedBlock(uint256 _lockedBlock, uint256 _epochHint) internal view returns (uint256) {
    // usually at most `bondLockingPeriod` loop is enough.
    while (_epochHint > 0) {
      if (rewardBondLocks[_epochHint].lockedBlock == _lockedBlock) break;
      _epochHint = _epochHint - 1;
    }
    return _epochHint;
  }

  /// @dev find the earlist reward locked block, which will be used to find possible start epoch
  /// @param _user The address of user.
  function _findEarlistRewardLockedBlock(address _user) internal view returns (uint256) {
    UserLockedBalance[] storage _locks = userRewardBondLocks[_user];
    uint256 length = _locks.length;
    // no locks or all unlocked and redeemed
    if (length == 0) return 0;

    uint256 _minLockedBlock = _locks[0].lockedBlock;
    for (uint256 i = 1; i < length; i++) {
      uint256 _lockedBlock = _locks[i].lockedBlock;
      if (_lockedBlock < _minLockedBlock) {
        _minLockedBlock = _lockedBlock;
      }
    }
    return _minLockedBlock;
  }
}