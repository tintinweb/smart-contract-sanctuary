/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
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
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

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

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

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

interface IStrategy {
    function want() external view returns (address);

    function farmingToken() external view returns (address);

    function targetProfitToken() external view returns (address);

    function inFarmBalance() external view returns (uint256);

    function totalBalance() external view returns (uint256);

    function deposit(address _account, uint256 _amount) external;

    function withdraw(address _account, uint256 _amount) external;

    function withdrawAll() external;
}

interface ICappedMintableBurnableERC20 {
    function decimals() external view returns (uint8);

    function cap() external view returns (uint256);

    function minter(address) external view returns (bool);

    function mint(address, uint256) external;

    function burn(uint256) external;

    function burnFrom(address, uint256) external;
}

contract ShareRewardBank is OwnableUpgradeSafe, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SDSs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSdsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSdsPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SDSs to distribute per block.
        uint256 lastRewardTime; // Last timestamp that SDSs distribution occurs.
        uint256 accSdsPerShare; // Accumulated SDSs per share, times 1e18. See below.
        address strategy; // Strategy address, use LP to farm and buy back SDS
        uint256 totalLpSupply;
        bool isStarted; // if lastRewardTime has passed
        uint256 startTime;
        uint16 depositFeeBP; // Deposit fee in basis points
        uint256 lockedTime;
        uint256 earlyWithdrawFee;
    }

    address public sds = address(0xAB72EE159Ff70b64beEcBbB0FbBE58b372391C54); // SDSv2

    uint256 public totalRewardPerSecond;
    uint256 public rewardPerSecond;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The block number when SDS mining starts.
    uint256 public startTime;

    uint256 public week;
    uint256 public nextHalvingTime;
    uint256 public rewardHalvingRate;
    bool public halvingChecked;

    //   > Dev/Mkt/Airdrop:     150,000,000 (16.66%)
    //   > Treasury Fund:       200,000,000 (22.22%)
    //   > Insurance Fund:       50,000,000  (5.55%)
    uint256 public devRate;
    uint256 public treasuryRate;
    uint256 public insuranceRate;

    address public devFund;
    address public treasuryFund;
    address public insuranceFund;

    uint256 public totalDevFundAdded;
    uint256 public totalTreasuryFundAdded;
    uint256 public totalInsuranceFundAdded;

    mapping(uint256 => mapping(address => uint256)) public userLastDepositTime;
    mapping(address => bool) public whitelistedContract;

    address public timelock = address(0x31d484ff03f8cbEDD26Adc7f2b7EF97e4276B1D8);
    mapping(address => bool) public approvedStrategies;

    /* =================== Added variables (need to keep orders for proxy to work) =================== */
    // ...

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawFee(address indexed user, uint256 indexed pid, uint256 amount, uint256 fee);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event LogRewardPerSecond(uint256 rewardPerSecond);
    event StrategyUpdated(uint256 indexed pid, address oldStrategy, address newStrategy);
    event TimelockUpdated(address newTimelock);

    modifier checkHalving() {
        if (halvingChecked) {
            halvingChecked = false;
            if (now >= nextHalvingTime) {
                massUpdatePools();
                uint256 _totalRewardPerSecond = totalRewardPerSecond.mul(rewardHalvingRate).div(10000); // x98.61% (1.39% decreased weekly)
                totalRewardPerSecond = _totalRewardPerSecond;
                _updateRewardPerSecond();
                nextHalvingTime = nextHalvingTime.add(7 days);
                ++week;
            }
            halvingChecked = true;
        }
        _;
    }

    modifier notContract() {
        if (!whitelistedContract[msg.sender]) {
            uint256 size;
            address addr = msg.sender;
            assembly {
                size := extcodesize(addr)
            }
            require(size == 0, "contract not allowed");
            require(tx.origin == msg.sender, "contract not allowed");
        }
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == timelock, "!timelock");
        _;
    }

    function _updateRewardPerSecond() internal {
        uint256 _totalRewardPerSecond = totalRewardPerSecond;
        uint256 _totalRate = devRate.add(treasuryRate).add(insuranceRate);
        rewardPerSecond = _totalRewardPerSecond.sub(_totalRewardPerSecond.mul(_totalRate).div(10000));
        emit LogRewardPerSecond(rewardPerSecond);
    }

    function initialize(
        address _sds,
        address _devFund,
        address _treasuryFund,
        address _insuranceFund,
        address _timelock,
        uint256 _totalRewardPerSecond,
        uint256 _startTime
    ) external initializer {
        OwnableUpgradeSafe.__Ownable_init();

        sds = _sds;

        devFund = _devFund;
        treasuryFund = _treasuryFund;
        insuranceFund = _insuranceFund;

        devRate = 1666; // 16.66%
        treasuryRate = 2222; // 22.22%
        insuranceRate = 555; // 5.55%

        totalRewardPerSecond = _totalRewardPerSecond;
        _updateRewardPerSecond();

        week = 0;
        startTime = _startTime;
        nextHalvingTime = _startTime.add(7 days);

        rewardHalvingRate = 9861; // 98.61%
        halvingChecked = true;

        timelock = _timelock;
    }

    function resetStartTime(uint256 _startTime) external onlyOwner {
        require(startTime > now && _startTime > now, "late");
        startTime = _startTime;
        nextHalvingTime = _startTime.add(7 days);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setHalvingChecked(bool _halvingChecked) external onlyOwner {
        halvingChecked = _halvingChecked;
    }

    function setRewardHalvingRate(uint256 _rewardHalvingRate) external onlyOwner {
        require(_rewardHalvingRate >= 9000, "below 90%");
        massUpdatePools();
        rewardHalvingRate = _rewardHalvingRate;
    }

    function setWhitelistedContract(address _contract, bool _isWhitelisted) external onlyOwner {
        whitelistedContract[_contract] = _isWhitelisted;
    }

    function setTimelock(address _timelock) external onlyTimelock {
        require(_timelock != address(0), "invalidAddress");
        timelock = _timelock;
        emit TimelockUpdated(_timelock);
    }

    function checkPoolDuplicate(IERC20 _lpToken) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].lpToken != _lpToken, "add: existing pool?");
        }
    }

    function addPool(
        uint256 _allocPoint,
        IERC20 _lpToken,
        address _strategy,
        uint16 _depositFeeBP,
        uint256 _lastRewardTime,
        uint256 _lockedTime,
        uint256 _earlyWithdrawFee
    ) external onlyOwner {
        require(_allocPoint <= 100000, "too high allocation point"); // <= 100x
        require(_depositFeeBP <= 1000, "too high fee"); // <= 10%
        require(_lockedTime <= 14 days, "locked time is too long");
        require(_earlyWithdrawFee <= 1000, "early withdraw fee is too high"); // <= 10%
        checkPoolDuplicate(_lpToken);
        massUpdatePools();
        if (now < startTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = startTime;
            } else {
                if (_lastRewardTime < startTime) {
                    _lastRewardTime = startTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < now) {
                _lastRewardTime = now;
            }
        }
        bool _isStarted = (_lastRewardTime <= startTime) || (_lastRewardTime <= now);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTime: _lastRewardTime,
                accSdsPerShare: 0,
                strategy: _strategy,
                totalLpSupply: 0,
                isStarted: _isStarted,
                depositFeeBP: _depositFeeBP,
                startTime: _lastRewardTime,
                lockedTime: _lockedTime,
                earlyWithdrawFee: _earlyWithdrawFee
            })
        );
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    function replacePoolLpToken(uint256 _pid, IERC20 _lpToken) external onlyOwner {
        require(_lpToken.totalSupply() > 0, "Non-existing token");
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.accSdsPerShare == 0 && pool.totalLpSupply == 0, "Cant replace running pool");
        massUpdatePools();
        pool.lpToken = _lpToken;
    }

    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        uint256 _lockedTime,
        uint256 _earlyWithdrawFee
    ) external onlyOwner {
        require(_allocPoint <= 100000, "too high allocation point"); // <= 100x
        require(_depositFeeBP <= 1000, "too high fee"); // <= 10%
        require(_lockedTime <= 14 days, "locked time is too long");
        require(_earlyWithdrawFee <= 1000, "early withdraw fee is too high"); // <= 10%
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
        }
        pool.allocPoint = _allocPoint;
        pool.depositFeeBP = _depositFeeBP;
        pool.lockedTime = _lockedTime;
        pool.earlyWithdrawFee = _earlyWithdrawFee;
    }

    function approveStrategy(address _strategy) external onlyTimelock {
        approvedStrategies[_strategy] = true;
    }

    function revokeStrategy(address _strategy) external onlyTimelock {
        approvedStrategies[_strategy] = false;
    }

    function changeStrategy(uint256 _pid, address _newStrategy) external onlyOwner {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 _lpToken = pool.lpToken;
        uint256 _totalLpSupply = pool.totalLpSupply;
        address _oldStrategy = pool.strategy;
        if (_oldStrategy == address(0)) {
            require(_newStrategy != address(0), "0 to 0");
        } else {
            IStrategy(_oldStrategy).withdrawAll();
            _checkStrategyBalance(_lpToken, _oldStrategy, _totalLpSupply);
        }
        if (_newStrategy != address(0)) {
            require(approvedStrategies[_newStrategy], "!approved");
            require(IStrategy(_newStrategy).want() == address(_lpToken), "!want");
            require(IStrategy(_newStrategy).targetProfitToken() == sds, "!targetProfitToken");
            _depositToStrategy(address(this), _lpToken, _newStrategy, _lpToken.balanceOf(address(this)));
            _checkStrategyBalance(_lpToken, _newStrategy, _totalLpSupply);
        }
        pool.strategy = _newStrategy;
        emit StrategyUpdated(_pid, _oldStrategy, _newStrategy);
    }

    function setTotalRewardPerSecond(uint256 _totalRewardPerSecond) external onlyOwner {
        require(_totalRewardPerSecond <= 0.2 ether, "insane high rate");
        massUpdatePools();
        totalRewardPerSecond = _totalRewardPerSecond;
        _updateRewardPerSecond();
    }

    function setDevRate(uint256 _devRate) external onlyOwner {
        require(_devRate <= 3000, "too high"); // <= 30%
        massUpdatePools();
        devRate = _devRate;
        _updateRewardPerSecond();
    }

    function setTreasuryRate(uint256 _treasuryRate) external onlyOwner {
        require(_treasuryRate <= 5000, "too high"); // <= 50%
        massUpdatePools();
        treasuryRate = _treasuryRate;
        _updateRewardPerSecond();
    }

    function setInsuranceRate(uint256 _insuranceRate) external onlyOwner {
        require(_insuranceRate <= 1500, "too high"); // <= 15%
        massUpdatePools();
        insuranceRate = _insuranceRate;
        _updateRewardPerSecond();
    }

    function setDevFund(address _devFund) external onlyOwner {
        require(_devFund != address(0), "zero");
        devFund = _devFund;
    }

    function setTreasuryFund(address _treasuryFund) external onlyOwner {
        require(_treasuryFund != address(0), "zero");
        treasuryFund = _treasuryFund;
    }

    function setInsuranceFund(address _insuranceFund) external onlyOwner {
        require(_insuranceFund != address(0), "zero");
        insuranceFund = _insuranceFund;
    }

    // View function to see pending SDSs on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSdsPerShare = pool.accSdsPerShare;
        uint256 lpSupply = pool.totalLpSupply;
        if (now > pool.lastRewardTime && lpSupply != 0) {
            uint256 _seconds = now.sub(pool.lastRewardTime);
            if (totalAllocPoint > 0) {
                uint256 _sdsReward = _seconds.mul(rewardPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
                accSdsPerShare = accSdsPerShare.add(_sdsReward.mul(1e18).div(lpSupply));
            }
        }
        return user.amount.mul(accSdsPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (now <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = pool.totalLpSupply;
        if (lpSupply == 0) {
            pool.lastRewardTime = now;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _seconds = now.sub(pool.lastRewardTime);
            uint256 _sdsReward = _seconds.mul(rewardPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
            pool.accSdsPerShare = pool.accSdsPerShare.add(_sdsReward.mul(1e18).div(lpSupply));
        }
        pool.lastRewardTime = now;
    }

    function _harvestReward(uint256 _pid, address _account) internal {
        UserInfo storage user = userInfo[_pid][_account];
        if (user.amount > 0) {
            PoolInfo storage pool = poolInfo[_pid];
            uint256 _claimableAmount = user.amount.mul(pool.accSdsPerShare).div(1e18).sub(user.rewardDebt);
            if (_claimableAmount > 0) {
                require(_claimableAmount.mul(50) <= IERC20(sds).totalSupply(), "Suspicious big reward amount!!"); // <= 2% total supply
                emit RewardPaid(_account, _claimableAmount);

                _topupFunds(_claimableAmount);

                _safeSdsMint(address(this), _claimableAmount);
                _safeSdsTransfer(_account, _claimableAmount);
            }
        }
    }

    function _depositToStrategy(
        address _account,
        IERC20 _lpToken,
        address _strategy,
        uint256 _amount
    ) internal {
        uint256 _before = IStrategy(_strategy).totalBalance();
        _lpToken.safeIncreaseAllowance(address(_strategy), _amount);
        IStrategy(_strategy).deposit(_account, _amount);
        uint256 _after = IStrategy(_strategy).totalBalance();
        require(_after.sub(_before) == _amount, "Short of strategy balance");
    }

    function _withdrawFromStrategy(
        address _account,
        IERC20 _lpToken,
        address _strategy,
        uint256 _amount
    ) internal {
        uint256 _before = _lpToken.balanceOf(address(this));
        IStrategy(_strategy).withdraw(_account, _amount);
        uint256 _after = _lpToken.balanceOf(address(this));
        require(_after.sub(_before) == _amount, "withdraw from strategy is not enough");
    }

    function _checkStrategyBalance(
        IERC20 _lpToken,
        address _strategy,
        uint256 _totalLpBalance
    ) internal view {
        uint256 _strategyBal = IStrategy(_strategy).totalBalance();
        require(_lpToken.balanceOf(address(this)).add(_strategyBal) >= _totalLpBalance, "Short of strategy balance: need audit!");
    }

    function deposit(uint256 _pid, uint256 _amount) public notContract nonReentrant checkHalving {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            _harvestReward(_pid, msg.sender);
        }
        if (_amount > 0) {
            IERC20 _lpToken = pool.lpToken;
            uint256 _before = _lpToken.balanceOf(address(this));
            _lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 _after = _lpToken.balanceOf(address(this));
            _amount = _after.sub(_before); // fix issue of deflation token
            if (_amount > 0) {
                uint256 _depositFeeBP = pool.depositFeeBP;
                uint256 _userAmount = _amount;
                if (_depositFeeBP > 0) {
                    uint256 _fee = _amount.mul(_depositFeeBP).div(10000);
                    _lpToken.safeTransfer(insuranceFund, _fee);
                    _userAmount = _userAmount.sub(_fee);
                }
                address _strategy = pool.strategy;
                uint256 _totalLpSupply = pool.totalLpSupply;
                if (_strategy != address(0)) {
                    _depositToStrategy(msg.sender, _lpToken, _strategy, _userAmount);
                    _checkStrategyBalance(_lpToken, _strategy, _totalLpSupply);
                }
                pool.totalLpSupply = _totalLpSupply.add(_userAmount);
                user.amount = user.amount.add(_userAmount);
                userLastDepositTime[_pid][msg.sender] = now;
            }
        }
        user.rewardDebt = user.amount.mul(pool.accSdsPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function unfrozenDepositTime(uint256 _pid, address _account) public view returns (uint256) {
        return userLastDepositTime[_pid][_account].add(poolInfo[_pid].lockedTime);
    }

    function withdraw(uint256 _pid, uint256 _amount) public notContract nonReentrant checkHalving {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        if (user.amount > 0) {
            _harvestReward(_pid, msg.sender);
        }
        if (_amount > 0) {
            IERC20 _lpToken = pool.lpToken;
            uint256 _totalLpSupply = pool.totalLpSupply;

            address _strategy = pool.strategy;
            if (_strategy != address(0)) {
                _withdrawFromStrategy(msg.sender, _lpToken, _strategy, _amount);
                _checkStrategyBalance(_lpToken, _strategy, _totalLpSupply);
            }

            uint256 _sentAmount = _amount;
            uint256 _earlyWithdrawFee = pool.earlyWithdrawFee;
            if (_earlyWithdrawFee > 0 && insuranceFund != address(0) && now < unfrozenDepositTime(_pid, msg.sender)) {
                _earlyWithdrawFee = _amount.mul(_earlyWithdrawFee).div(10000);
                _sentAmount = _sentAmount.sub(_earlyWithdrawFee);
                _lpToken.safeTransfer(insuranceFund, _earlyWithdrawFee);
                emit WithdrawFee(msg.sender, _pid, _amount, _earlyWithdrawFee);
            }

            pool.totalLpSupply = _totalLpSupply.sub(_amount);
            user.amount = user.amount.sub(_amount);
            _lpToken.safeTransfer(msg.sender, _sentAmount);
        }
        user.rewardDebt = user.amount.mul(pool.accSdsPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function withdrawAll(uint256 _pid) external {
        withdraw(_pid, userInfo[_pid][msg.sender].amount);
    }

    function harvestAllRewards() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (userInfo[pid][msg.sender].amount > 0) {
                withdraw(pid, 0);
            }
        }
    }

    function _safeSdsTransfer(address _to, uint256 _amount) internal {
        uint256 _sdsBal = IERC20(sds).balanceOf(address(this));
        if (_sdsBal > 0) {
            if (_amount > _sdsBal) {
                IERC20(sds).safeTransfer(_to, _sdsBal);
            } else {
                IERC20(sds).safeTransfer(_to, _amount);
            }
        }
    }

    function _safeSdsMint(address _to, uint256 _amount) internal {
        address _sds = sds;
        if (ICappedMintableBurnableERC20(_sds).minter(address(this)) && _to != address(0)) {
            uint256 _totalSupply = IERC20(_sds).totalSupply();
            uint256 _cap = ICappedMintableBurnableERC20(_sds).cap();
            uint256 _mintAmount = (_totalSupply.add(_amount) <= _cap) ? _amount : _cap.sub(_totalSupply);
            if (_mintAmount > 0) {
                ICappedMintableBurnableERC20(_sds).mint(_to, _mintAmount);
            }
        }
    }

    function _topupFunds(uint256 _claimableAmount) internal {
        address _sds = sds;
        uint256 _totalAmount = _claimableAmount.mul(totalRewardPerSecond).div(rewardPerSecond);
        uint256 _devAmount = _totalAmount.mul(devRate).div(10000);
        uint256 _treasuryAmount = _totalAmount.mul(treasuryRate).div(10000);
        uint256 _insuranceAmount = _totalAmount.mul(insuranceRate).div(10000);
        uint256 _totalMintAmount = _devAmount.add(_treasuryAmount).add(_insuranceAmount);
        if (
            ICappedMintableBurnableERC20(_sds).minter(address(this)) &&
            IERC20(_sds).totalSupply().add(_totalMintAmount) <= ICappedMintableBurnableERC20(_sds).cap()
        ) {
            ICappedMintableBurnableERC20(_sds).mint(devFund, _devAmount);
            ICappedMintableBurnableERC20(_sds).mint(treasuryFund, _treasuryAmount);
            ICappedMintableBurnableERC20(_sds).mint(insuranceFund, _insuranceAmount);
            totalDevFundAdded = totalDevFundAdded.add(_devAmount);
            totalTreasuryFundAdded = totalTreasuryFundAdded.add(_treasuryAmount);
            totalInsuranceFundAdded = totalInsuranceFundAdded.add(_insuranceAmount);
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external notContract nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        IERC20 _lpToken = pool.lpToken;
        uint256 _amount = user.amount;
        uint256 _sentAmount = _amount;
        if (insuranceFund != address(0) && now < unfrozenDepositTime(_pid, msg.sender)) {
            uint256 _earlyWithdrawFee = pool.earlyWithdrawFee;
            if (_earlyWithdrawFee > 0) {
                _earlyWithdrawFee = _amount.mul(_earlyWithdrawFee).div(10000);
                _sentAmount = _sentAmount.sub(_earlyWithdrawFee);
                _lpToken.safeTransfer(insuranceFund, _earlyWithdrawFee);
                emit WithdrawFee(msg.sender, _pid, _amount, _earlyWithdrawFee);
            }
        }
        user.amount = 0;
        user.rewardDebt = 0;
        pool.totalLpSupply = pool.totalLpSupply.sub(_amount);
        _lpToken.safeTransfer(address(msg.sender), _sentAmount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // This function allows governance to take unsupported tokens out of the contract. This is in an effort to make someone whole, should they seriously mess up.
    // There is no guarantee governance will vote to return these. It also allows for removal of airdropped tokens.
    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 amount,
        address to
    ) external onlyOwner {
        // do not allow to drain lpToken
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            require(_token != pool.lpToken, "pool.lpToken");
        }
        _token.safeTransfer(to, amount);
    }
}