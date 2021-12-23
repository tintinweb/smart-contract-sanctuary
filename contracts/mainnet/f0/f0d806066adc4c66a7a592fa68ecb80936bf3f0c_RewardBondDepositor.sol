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


// File contracts/interfaces/IVault.sol

pragma solidity ^0.7.6;

interface IVault {
  function getRewardTokens() external view returns (address[] memory);

  function balance() external view returns (uint256);

  function balanceOf(address _user) external view returns (uint256);

  function deposit(uint256 _amount) external;

  function withdraw(uint256 _amount) external;

  function claim() external;

  function exit() external;

  function harvest() external;
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


// File contracts/interfaces/ITreasury.sol

pragma solidity ^0.7.6;

interface ITreasury {
  enum ReserveType {
    // used by reserve manager, will not used to bond ALD.
    NULL,
    // used by main asset bond
    UNDERLYING,
    // used by vault reward bond
    VAULT_REWARD,
    // used by liquidity token bond
    LIQUIDITY_TOKEN
  }

  /// @dev return the usd value given token and amount.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function valueOf(address _token, uint256 _amount) external view returns (uint256);

  /// @dev return the amount of bond ALD given token and usd value.
  /// @param _token The address of token.
  /// @param _value The usd of token.
  function bondOf(address _token, uint256 _value) external view returns (uint256);

  /// @dev deposit token to bond ALD.
  /// @param _type The type of deposited token.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function deposit(
    ReserveType _type,
    address _token,
    uint256 _amount
  ) external returns (uint256);

  /// @dev withdraw token from POL.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function withdraw(address _token, uint256 _amount) external;

  /// @dev manage token to earn passive yield.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function manage(address _token, uint256 _amount) external;

  /// @dev mint ALD reward.
  /// @param _recipient The address of to receive ALD token.
  /// @param _amount The amount of token.
  function mintRewards(address _recipient, uint256 _amount) external;
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


// File contracts/bond/RewardBondDepositor.sol

pragma solidity ^0.7.6;







contract RewardBondDepositor is OwnableUpgradeable, IRewardBondDepositor {
  using SafeMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  uint256 private constant MAX_REWARD_TOKENS = 4;

  struct Epoch {
    uint64 epochNumber;
    uint64 startBlock; // include
    uint64 nextBlock; // not include
    uint64 epochLength;
  }

  struct AccountCheckpoint {
    uint32 epochNumber;
    uint32 blockNumber;
    uint192 rewardShare;
  }

  struct AccountEpochShare {
    uint32 startEpoch; // include
    uint32 endEpoch; // not inclued
    uint192 totalShare;
  }

  struct PendingBondReward {
    bool hasReward;
    uint256[MAX_REWARD_TOKENS] amounts;
  }

  // The address of ald.
  address public ald;
  // The address of Treasury.
  address public treasury;

  // The address of staking contract
  address public staking;

  // The struct of current epoch.
  Epoch public override currentEpoch;

  // A list of epoch infomation.
  // 65536 epoch is about 170 years.
  Epoch[65536] public epoches;

  // A list of vaults. Push only, beware false-positives.
  address[] public vaults;
  // Record whether an address is vault or not.
  mapping(address => bool) public isVault;
  // Mapping from vault address to a list of reward tokens.
  mapping(address => address[]) public rewardTokens;

  // Mapping from vault address to token address to reward amount in current epoch.
  mapping(address => PendingBondReward) public rewards;
  // Mapping from epoch number to vault address to total reward share.
  mapping(uint256 => mapping(address => uint256)) public override rewardShares;

  // The address of keeper.
  address public keeper;

  // Mapping from vault address to global checkpoint block
  mapping(address => uint256) private checkpointBlock;

  // Mapping from user address to vault address to account checkpoint.
  mapping(address => mapping(address => AccountCheckpoint)) private accountCheckpoint;

  // Mapping from user address to vault address to account epoch shares.
  mapping(address => mapping(address => AccountEpochShare[])) private accountEpochShares;

  // Mapping from user address to a list of interacted vault
  mapping(address => address[]) private accountVaults;

  function initialize(
    address _ald,
    address _treasury,
    uint64 _startBlock,
    uint64 _epochLength
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    require(_ald != address(0), "RewardBondDepositor: not zero address");
    require(_treasury != address(0), "RewardBondDepositor: not zero address");
    require(_startBlock >= block.number, "RewardBondDepositor: start block too small");

    ald = _ald;
    treasury = _treasury;

    currentEpoch = Epoch({
      epochNumber: 0,
      startBlock: _startBlock,
      nextBlock: _startBlock + _epochLength,
      epochLength: _epochLength
    });
  }

  function initializeStaking(address _staking) external onlyOwner {
    require(_staking != address(0), "RewardBondDepositor: not zero address");
    require(staking == address(0), "RewardBondDepositor: already set");

    staking = _staking;
    IERC20Upgradeable(ald).safeApprove(_staking, uint256(-1));
  }

  /********************************** View Functions **********************************/

  function getVaultsFromAccount(address _user) external view override returns (address[] memory) {
    return accountVaults[_user];
  }

  function getCurrentEpochRewardShare(address _vault) external view returns (uint256) {
    uint256 _share = rewardShares[currentEpoch.epochNumber][_vault];
    uint256 _balance = IVault(_vault).balance();
    uint256 _lastBlock = checkpointBlock[_vault];
    return _share.add(_balance.mul(block.number - _lastBlock));
  }

  function getCurrentEpochAccountRewardShare(address _user, address _vault) external view returns (uint256) {
    AccountCheckpoint memory _accountCheckpoint = accountCheckpoint[_user][_vault];
    if (_accountCheckpoint.blockNumber == 0) return 0;

    Epoch memory _epoch = currentEpoch;
    uint256 _balance = IVault(_vault).balanceOf(_user);

    if (_accountCheckpoint.epochNumber == _epoch.epochNumber) {
      return _balance.mul(block.number - _accountCheckpoint.blockNumber).add(_accountCheckpoint.rewardShare);
    } else {
      return _balance.mul(block.number - currentEpoch.startBlock + 1);
    }
  }

  function getAccountRewardShareSince(
    uint256 _epoch,
    address _user,
    address _vault
  ) external view override returns (uint256[] memory) {
    uint256[] memory _shares = new uint256[](currentEpoch.epochNumber - _epoch);
    if (_shares.length == 0) return _shares;

    // it is a new user. all shares equals to zero
    if (accountCheckpoint[_user][_vault].blockNumber == 0) return _shares;

    _getRecordedAccountRewardShareSince(_epoch, _user, _vault, _shares);
    _getPendingAccountRewardShareSince(_epoch, _user, _vault, _shares);

    return _shares;
  }

  /********************************** Mutated Functions **********************************/

  function notifyRewards(address _user, uint256[] memory _amounts) external override {
    require(isVault[msg.sender], "RewardBondDepositor: not approved");

    _checkpoint(msg.sender);
    _userCheckpoint(_user, msg.sender);

    PendingBondReward storage _pending = rewards[msg.sender];
    bool hasReward = false;

    address[] memory _tokens = rewardTokens[msg.sender];
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 _pool = IERC20Upgradeable(_tokens[i]).balanceOf(address(this));
      IERC20Upgradeable(_tokens[i]).safeTransferFrom(msg.sender, address(this), _amounts[i]);
      uint256 _amount = IERC20Upgradeable(_tokens[i]).balanceOf(address(this)).sub(_pool);
      if (_amount > 0) {
        hasReward = true;
        _pending.amounts[i] = _pending.amounts[i].add(_amount);
      }
    }

    if (hasReward && !_pending.hasReward) {
      _pending.hasReward = true;
    }
  }

  function bond(address _vault) external override {
    require(msg.sender == keeper, "RewardBondDepositor: not keeper");

    _bond(_vault);
  }

  function rebase() external override {
    require(msg.sender == keeper, "RewardBondDepositor: not keeper");

    Epoch memory _currentEpoch = currentEpoch;
    require(block.number >= currentEpoch.nextBlock, "RewardBondDepositor: too soon");

    // bond for vault has pending rewards
    uint256 length = vaults.length;
    for (uint256 i = 0; i < length; i++) {
      address _vault = vaults[i];
      _checkpoint(_vault);
      _bond(_vault);
    }

    IStaking(staking).rebase();

    // record passed epoch info
    //   + start at _currentEpoch.startBlock
    //   + actual end at block.number
    epoches[_currentEpoch.epochNumber] = Epoch({
      epochNumber: _currentEpoch.epochNumber,
      startBlock: _currentEpoch.startBlock,
      nextBlock: uint64(block.number),
      epochLength: uint64(block.number - _currentEpoch.startBlock)
    });

    // update current epoch info
    //   + start at block.number + 1
    //   + expected end at block.number + _currentEpoch.epochLength
    currentEpoch = Epoch({
      epochNumber: _currentEpoch.epochNumber + 1,
      startBlock: uint64(block.number),
      nextBlock: uint64(block.number + _currentEpoch.epochLength),
      epochLength: _currentEpoch.epochLength
    });
  }

  /********************************** Restricted Functions **********************************/

  function updateKeeper(address _keeper) external onlyOwner {
    keeper = _keeper;
  }

  function updateVault(address _vault, bool status) external onlyOwner {
    if (status) {
      require(!isVault[_vault], "RewardBondDepositor: already added");
      isVault[_vault] = true;
      if (!_listContainsAddress(vaults, _vault)) {
        vaults.push(_vault);

        address[] memory _rewardTokens = IVault(_vault).getRewardTokens();
        require(_rewardTokens.length <= MAX_REWARD_TOKENS, "RewardBondDepositor: too much reward");
        // approve token for treasury
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
          IERC20Upgradeable(_rewardTokens[i]).safeApprove(treasury, 0);
          IERC20Upgradeable(_rewardTokens[i]).safeApprove(treasury, uint256(-1));
        }

        rewardTokens[_vault] = _rewardTokens;
      }
    } else {
      require(isVault[_vault], "RewardBondDepositor: already removed");
      isVault[_vault] = false;
    }
  }

  /********************************** Internal Functions **********************************/

  function _bond(address _vault) internal {
    require(isVault[_vault], "RewardBondDepositor: vault not approved");

    PendingBondReward storage _pending = rewards[_vault];
    if (!_pending.hasReward) return;

    address[] memory _tokens = rewardTokens[_vault];
    address _treasury = treasury;
    uint256 _bondAmount = 0;
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 _amount = ITreasury(_treasury).deposit(
        ITreasury.ReserveType.VAULT_REWARD,
        _tokens[i],
        _pending.amounts[i]
      );
      _bondAmount = _bondAmount.add(_amount);
    }

    IStaking(staking).rewardBond(_vault, _bondAmount);

    delete rewards[_vault];
  }

  function _checkpoint(address _vault) internal {
    uint256 _lastBlock = checkpointBlock[_vault];
    if (_lastBlock > 0 && _lastBlock < block.number) {
      uint256 _share = rewardShares[currentEpoch.epochNumber][_vault];
      uint256 _balance = IVault(_vault).balance();
      rewardShares[currentEpoch.epochNumber][_vault] = _share.add(_balance.mul(block.number - _lastBlock));
    }
    checkpointBlock[_vault] = block.number;
  }

  function _userCheckpoint(address _user, address _vault) internal {
    AccountCheckpoint memory _accountCheckpoint = accountCheckpoint[_user][_vault];

    // updated in current block.
    if (block.number == _accountCheckpoint.blockNumber) {
      return;
    }

    // keep track the vaults which user interacted with.
    if (!_listContainsAddress(accountVaults[_user], _vault)) {
      accountVaults[_user].push(_vault);
    }

    // it's a new user, just record the checkpoint
    if (_accountCheckpoint.blockNumber == 0) {
      accountCheckpoint[_user][_vault] = AccountCheckpoint({
        epochNumber: uint32(currentEpoch.epochNumber),
        blockNumber: uint32(block.number),
        rewardShare: 0
      });
      return;
    }

    Epoch memory _cur = currentEpoch;
    uint256 _balance = IVault(_vault).balanceOf(_user);

    if (_accountCheckpoint.epochNumber == _cur.epochNumber) {
      // In the same epoch
      uint256 newShare = uint256(_accountCheckpoint.rewardShare).add(
        _balance.mul(block.number - _accountCheckpoint.blockNumber)
      );
      accountCheckpoint[_user][_vault] = AccountCheckpoint({
        epochNumber: uint32(currentEpoch.epochNumber),
        blockNumber: uint32(block.number),
        rewardShare: uint192(newShare)
      });
    } else {
      // across multiple epoches
      AccountEpochShare[] storage _shareList = accountEpochShares[_user][_vault];

      Epoch memory _next;
      if (_accountCheckpoint.epochNumber + 1 == _cur.epochNumber) {
        _next = _cur;
      } else {
        _next = epoches[_accountCheckpoint.epochNumber + 1];
      }

      uint256 newShare = uint256(_accountCheckpoint.rewardShare).add(
        _balance.mul(_next.startBlock - _accountCheckpoint.blockNumber)
      );

      // push current checkpoint to list
      _shareList.push(
        AccountEpochShare({
          startEpoch: _accountCheckpoint.epochNumber,
          endEpoch: _accountCheckpoint.epochNumber + 1,
          totalShare: uint192(newShare)
        })
      );

      // push old epoches to list
      if (_next.epochNumber < _cur.epochNumber) {
        _shareList.push(
          AccountEpochShare({
            startEpoch: uint32(_next.epochNumber),
            endEpoch: uint32(_cur.epochNumber),
            totalShare: uint192(_balance.mul(_cur.startBlock - _next.startBlock))
          })
        );
      }

      // update account checkpoint to latest one
      accountCheckpoint[_user][_vault] = AccountCheckpoint({
        epochNumber: uint32(_cur.epochNumber),
        blockNumber: uint32(block.number),
        rewardShare: uint192(_balance.mul(block.number - _cur.startBlock))
      });
    }
  }

  function _listContainsAddress(address[] storage _list, address _item) internal view returns (bool) {
    uint256 length = _list.length;
    for (uint256 i = 0; i < length; i++) {
      if (_list[i] == _item) return true;
    }
    return false;
  }

  function _getRecordedAccountRewardShareSince(
    uint256 _epoch,
    address _user,
    address _vault,
    uint256[] memory _shares
  ) internal view {
    AccountEpochShare[] storage _accountEpochShares = accountEpochShares[_user][_vault];
    uint256 length = _accountEpochShares.length;

    Epoch memory _cur = currentEpoch;
    Epoch memory _now = epoches[0];
    Epoch memory _next;
    for (uint256 i = 0; i < length; i++) {
      AccountEpochShare memory _epochShare = _accountEpochShares[i];
      if (_epochShare.endEpoch == _cur.epochNumber) {
        _next = _cur;
      } else {
        _next = epoches[_epochShare.endEpoch];
      }
      uint256 blocks = _next.startBlock - _now.startBlock;
      uint256 _start;
      if (_epoch <= _epochShare.startEpoch) {
        _start = _epochShare.startEpoch;
      } else if (_epoch < _epochShare.endEpoch) {
        _start = _epoch;
      } else {
        _start = _epochShare.endEpoch;
      }
      _now = _next;

      for (uint256 j = _start; j < _epochShare.endEpoch; j++) {
        if (_epochShare.endEpoch == _epochShare.startEpoch + 1) {
          _shares[j - _epoch] = _epochShare.totalShare;
        } else {
          _shares[j - _epoch] = uint256(_epochShare.totalShare).mul(epoches[j].epochLength).div(blocks);
        }
      }
    }
  }

  function _getPendingAccountRewardShareSince(
    uint256 _epoch,
    address _user,
    address _vault,
    uint256[] memory _shares
  ) internal view {
    Epoch memory _cur = currentEpoch;
    AccountCheckpoint memory _accountCheckpoint = accountCheckpoint[_user][_vault];
    if (_accountCheckpoint.epochNumber == _cur.epochNumber) return;

    uint256 _balance = IVault(_vault).balanceOf(_user);

    if (_accountCheckpoint.epochNumber >= _epoch) {
      Epoch memory _next;
      if (_accountCheckpoint.epochNumber + 1 == _cur.epochNumber) {
        _next = _cur;
      } else {
        _next = epoches[_accountCheckpoint.epochNumber + 1];
      }
      _shares[_accountCheckpoint.epochNumber - _epoch] = uint256(_accountCheckpoint.rewardShare).add(
        _balance.mul(_next.startBlock - _accountCheckpoint.blockNumber)
      );
    }

    for (uint256 i = _accountCheckpoint.epochNumber + 1; i < _cur.epochNumber; i++) {
      if (i >= _epoch) {
        _shares[i - _epoch] = _balance.mul(epoches[i].epochLength);
      }
    }
  }
}