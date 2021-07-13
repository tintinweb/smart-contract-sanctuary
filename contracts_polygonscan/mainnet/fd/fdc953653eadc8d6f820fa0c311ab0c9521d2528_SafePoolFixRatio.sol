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

interface ISafeAsset {
    function poolBurnFrom(address _address, uint256 _amount) external;

    function poolMint(address _address, uint256 m_amount) external;
}

interface ISafeTreasury {
    function hasPool(address _address) external view returns (bool);

    function minting_fee() external view returns (uint256);

    function redemption_fee() external view returns (uint256);

    function reserve_share_state() external view returns (uint8);

    function collateralReserve() external view returns (address);

    function profitSharingFund() external view returns (address);

    function globalCollateralBalance() external view returns (uint256);

    function globalCollateralValue() external view returns (uint256);

    function globalShareBalance() external view returns (uint256);

    function globalShareValue() external view returns (uint256);

    function requestTransfer(
        address token,
        address receiver,
        uint256 amount
    ) external;

    function reserveReceiveShares(uint256 amount) external;

    function info()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint8
        );
}

interface ISafeOracle {
    function consult() external view returns (uint256);

    function consultTrue() external view returns (uint256);
}

interface ISafePool {
    function calcMintInput(uint256 _safeAssetAmount) external view returns (uint256 _collateralAmount, uint256 _shareAmount);

    function calcMintOutputFromCollateral(uint256 _collateralAmount) external view returns (uint256 _safeAssetAmount, uint256 _shareAmount);

    function calcMintOutputFromShare(uint256 _shareAmount) external view returns (uint256 _safeAssetAmount, uint256 _collateralAmount);

    function calcRedeemOutput(uint256 _safeAssetAmount) external view returns (uint256 _collateralAmount, uint256 _shareAmount);

    function getCollateralPrice() external view returns (uint256);

    function getSharePrice() external view returns (uint256);

    function getEffectiveCollateralRatio() external view returns (uint256);

    function getRedemptionOpenTime(address _account) external view returns (uint256);

    function unclaimed_pool_collateral() external view returns (uint256);

    function unclaimed_pool_share() external view returns (uint256);

    function treasuryMintByShares(address _receiver, uint256 _safeAssetAmount) external returns (uint256 _shareAmount);
}

interface ISafeCollateralReserve {
    function fundBalance(address _token) external view returns (uint256);

    function transferTo(
        address _token,
        address _receiver,
        uint256 _amount
    ) external;

    function receiveShares(uint256 _amount) external;
}

interface ICappedMintableBurnableERC20 {
    function decimals() external view returns (uint8);

    function cap() external view returns (uint256);

    function minter(address) external view returns (bool);

    function mint(address, uint256) external;

    function burn(uint256) external;

    function burnFrom(address, uint256) external;
}

contract SafePoolFixRatio is OwnableUpgradeSafe, ReentrancyGuard, ISafePool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== ADDRESSES ================ */
    address public shareOracle;
    address public collateral;
    address public safeAsset;
    address public share;
    address public treasury;

    /* ========== STATE VARIABLES ========== */

    mapping(address => uint256) public redeem_share_balances;
    mapping(address => uint256) public redeem_collateral_balances;

    uint256 public override unclaimed_pool_collateral;
    uint256 public override unclaimed_pool_share;

    mapping(address => uint256) public last_redeemed;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;

    // Number of decimals needed to get to 18
    uint256 private missing_decimals; // =12

    // Number of seconds to wait before being able to collectRedemption()
    uint256 public redemption_delay = 60;

    // AccessControl state variables
    bool public mint_paused = false;
    bool public redeem_paused = false;

    uint256 public targetCollateralRatio;

    uint256 public mintedBySharesCap;
    uint256 public mintedBySharesAmount;

    /* =================== Added variables (need to keep orders for proxy to work) =================== */
    address public collateralOracle;

    /* ========== EVENTS ========== */

    event TreasuryUpdated(address indexed newTreasury);
    event MintPausedUpdated(bool mint_paused);
    event RedeemPausedUpdated(bool redeem_paused);
    event TargetCollateralRatioUpdated(uint256 targetCollateralRatio);
    event SafeAssetMinted(address indexed from, address indexed to, uint256 amount);
    event Mint(address indexed account, uint256 safeAssetAmount, uint256 collateralAmount, uint256 shareAmount);
    event Redeem(address indexed account, uint256 safeAssetAmount, uint256 collateralAmount, uint256 shareAmount);
    event CollectRedemption(address indexed account, uint256 collateralAmount, uint256 shareAmount);
    event TreasuryMintByShares(address indexed receiver, uint256 safeAssetAmount, uint256 shareAmount);

    /* ========== MODIFIERS ========== */

    modifier onlyTreasury() {
        require(msg.sender == treasury, "!treasury");
        _;
    }

    modifier onlyTreasuryOrOwner() {
        require(msg.sender == treasury || msg.sender == owner(), "!treasury && !owner");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _safeAsset,
        address _share,
        address _collateral,
        address _treasury,
        uint256 _targetCollateralRatio
    ) external initializer {
        OwnableUpgradeSafe.__Ownable_init();

        safeAsset = _safeAsset;
        share = _share;
        collateral = _collateral;
        treasury = _treasury;
        missing_decimals = uint256(18).sub(uint256(ICappedMintableBurnableERC20(_collateral).decimals()));

        targetCollateralRatio = _targetCollateralRatio;

        redemption_delay = 60;
        mint_paused = false;
        redeem_paused = false;

        mintedBySharesCap = 250000 ether;
        mintedBySharesAmount = 0 ether;
    }

    /* ========== VIEWS ========== */

    function info()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        return (
            unclaimed_pool_collateral, // unclaimed amount of COLLATERAL
            unclaimed_pool_share, // unclaimed amount of SHARE
            PRICE_PRECISION, // collateral price
            mint_paused,
            redeem_paused
        );
    }

    function collateralReserve() public view returns (address) {
        return ISafeTreasury(treasury).collateralReserve();
    }

    function getCollateralPrice() public view override returns (uint256) {
        return (collateralOracle == address(0)) ? PRICE_PRECISION : ISafeOracle(collateralOracle).consult(); // WMATIC = 1$
    }

    function getSharePrice() public view override returns (uint256) {
        return (shareOracle == address(0)) ? PRICE_PRECISION * 10 : ISafeOracle(shareOracle).consult(); // Minimum 10$
    }

    function getTrueSharePrice() public view returns (uint256) {
        return (shareOracle == address(0)) ? PRICE_PRECISION * 5 : ISafeOracle(shareOracle).consultTrue(); // Constant 5$
    }

    function getEffectiveCollateralRatio() external view override returns (uint256) {
        uint256 _collateral_bal = ISafeTreasury(treasury).globalCollateralBalance();
        uint256 _total_safeAsset_supply = IERC20(safeAsset).totalSupply();
        return _collateral_bal.mul(10**missing_decimals).mul(10000).div(_total_safeAsset_supply);
    }

    function getRedemptionOpenTime(address _account) public view override returns (uint256) {
        uint256 _last_redeemed = last_redeemed[_account];
        return (_last_redeemed == 0) ? 0 : _last_redeemed.add(redemption_delay);
    }

    function calcMintInput(uint256 _safeAssetAmount) public view override returns (uint256 _collateralAmount, uint256 _shareAmount) {
        uint256 _collateral_price = getCollateralPrice();
        uint256 _share_price = getTrueSharePrice();
        uint256 _safeAssetFullValue = _safeAssetAmount.mul(_collateral_price).div(PRICE_PRECISION);
        uint256 _collateralFullValue = _safeAssetFullValue.mul(targetCollateralRatio).div(10000);
        _collateralAmount = _collateralFullValue.mul(PRICE_PRECISION).div(_collateral_price).div(10**missing_decimals);
        uint256 _required_shareAmount = _safeAssetFullValue.sub(_collateralFullValue).mul(PRICE_PRECISION).div(_share_price);
        uint256 _mintingFee = ISafeTreasury(treasury).minting_fee();
        uint256 _shareFee = _required_shareAmount.mul(_mintingFee).div(10000);
        _shareAmount = _required_shareAmount.add(_shareFee);
        uint256 _collateralFee = _collateralAmount.mul(_mintingFee).div(10000);
        _collateralAmount = _collateralAmount.add(_collateralFee);
    }

    function calcMintOutputFromCollateral(uint256 _collateralAmount) public view override returns (uint256 _safeAssetAmount, uint256 _shareAmount) {
        uint256 _collateral_price = getCollateralPrice();
        uint256 _share_price = getTrueSharePrice();
        uint256 _collateralFullValue = _collateralAmount.mul(10**missing_decimals).mul(_collateral_price).div(PRICE_PRECISION);
        uint256 _safeAssetFullValue = _collateralFullValue.mul(10000).div(targetCollateralRatio);
        _safeAssetAmount = _safeAssetFullValue.mul(PRICE_PRECISION).div(_collateral_price);
        uint256 _shareFullValue = _safeAssetFullValue.sub(_collateralFullValue);
        _shareAmount = _shareFullValue.mul(PRICE_PRECISION).div(_share_price);
        uint256 _mintingFee = ISafeTreasury(treasury).minting_fee();
        _safeAssetAmount = _safeAssetAmount.mul(10000).div(uint256(10000).add(_mintingFee)).sub(1);
    }

    function calcMintOutputFromShare(uint256 _shareAmount) public view override returns (uint256 _safeAssetAmount, uint256 _collateralAmount) {
        uint256 _collateral_price = getCollateralPrice();
        uint256 _share_price = getTrueSharePrice();
        uint256 _shareFullValue = _shareAmount.mul(_share_price).div(PRICE_PRECISION);
        uint256 _safeAssetFullValue = _shareFullValue.mul(10000).div(uint256(10000).sub(targetCollateralRatio));
        _safeAssetAmount = _safeAssetFullValue.mul(PRICE_PRECISION).div(_collateral_price);
        uint256 _collateralFullValue = _safeAssetFullValue.sub(_shareFullValue);
        _collateralAmount = _collateralFullValue.div(10**missing_decimals).mul(PRICE_PRECISION).div(_collateral_price);
        uint256 _mintingFee = ISafeTreasury(treasury).minting_fee();
        _safeAssetAmount = _safeAssetAmount.mul(10000).div(uint256(10000).add(_mintingFee)).sub(1);
    }

    function calcRedeemOutput(uint256 _safeAssetAmount) public view override returns (uint256 _collateralAmount, uint256 _shareAmount) {
        uint256 _collateral_bal = ISafeTreasury(treasury).globalCollateralBalance();
        uint256 _share_bal = ISafeTreasury(treasury).globalShareBalance();
        uint256 _total_safeAsset_supply = IERC20(safeAsset).totalSupply();
        uint256 _outputRatio = _safeAssetAmount.mul(1e18).div(_total_safeAsset_supply);
        _collateralAmount = _collateral_bal.mul(_outputRatio).div(1e18);
        uint256 _share_out = _share_bal.mul(_outputRatio).div(1e18);
        uint256 _redemptionFee = ISafeTreasury(treasury).redemption_fee();
        uint256 _shareFee = _share_out.mul(_redemptionFee).div(10000);
        _shareAmount = _share_out.sub(_shareFee);
        uint256 _collateralFee = _collateralAmount.mul(_redemptionFee).div(10000);
        _collateralAmount = _collateralAmount.sub(_collateralFee);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function mint(
        uint256 _collateralAmount,
        uint256 _shareAmount,
        uint256 _safeAssetOutMin
    )
        external
        returns (
            uint256 _safeAssetOut,
            uint256 _required_collateralAmount,
            uint256 _required_shareAmount
        )
    {
        require(mint_paused == false, "Minting is paused");
        trimExtraToTreasury();

        (_safeAssetOut, _required_shareAmount) = calcMintOutputFromCollateral(_collateralAmount);
        if (_required_shareAmount > _shareAmount) {
            (_safeAssetOut, _required_collateralAmount) = calcMintOutputFromShare(_shareAmount);
            require(_required_collateralAmount <= _collateralAmount, "invalid input quantities");
        }
        require(_safeAssetOut >= _safeAssetOutMin, "slippage");

        (_required_collateralAmount, _required_shareAmount) = calcMintInput(_safeAssetOut);
        require(_required_collateralAmount <= _collateralAmount, "Not enough _collateralAmount");
        require(_required_shareAmount <= _shareAmount, "Not enough _shareAmount");
        require(_safeAssetOut <= _collateralAmount.mul(10**missing_decimals).mul(12600).div(10000), "Insanely big _safeAssetOut"); // double check - we dont want to mint too much safeAsset

        _transferToReserve(collateral, msg.sender, _required_collateralAmount);
        _transferToReserve(share, msg.sender, _required_shareAmount);
        ISafeAsset(safeAsset).poolMint(msg.sender, _safeAssetOut);
        emit Mint(msg.sender, _safeAssetOut, _required_collateralAmount, _required_shareAmount);
    }

    function redeem(
        uint256 _safeAssetAmount,
        uint256 _collateral_out_min,
        uint256 _share_out_min
    ) external returns (uint256 _collateral_out, uint256 _share_out) {
        require(redeem_paused == false, "Redeeming is paused");
        trimExtraToTreasury();

        (_collateral_out, _share_out) = calcRedeemOutput(_safeAssetAmount);
        require(_collateral_out >= _collateral_out_min, "short of collateral");
        require(_share_out >= _share_out_min, "short of share");
        require(_collateral_out.mul(10**missing_decimals) <= _safeAssetAmount.mul(10100).div(10000), "Insanely big _collateral_out"); // double check - we dont want to redeem too much collateral
        ISafeAsset(safeAsset).poolBurnFrom(msg.sender, _safeAssetAmount);

        if (_collateral_out > 0) {
            redeem_collateral_balances[msg.sender] = redeem_collateral_balances[msg.sender].add(_collateral_out);
            unclaimed_pool_collateral = unclaimed_pool_collateral.add(_collateral_out);
        }
        if (_share_out > 0) {
            redeem_share_balances[msg.sender] = redeem_share_balances[msg.sender].add(_share_out);
            unclaimed_pool_share = unclaimed_pool_share.add(_share_out);
        }
        last_redeemed[msg.sender] = now;
        emit Redeem(msg.sender, _safeAssetAmount, _collateral_out, _share_out);
    }

    function collectRedemption() external {
        require(getRedemptionOpenTime(msg.sender) <= now, "<redemption_delay");
        trimExtraToTreasury();

        uint256 _collateralAmount = redeem_collateral_balances[msg.sender];
        uint256 _shareAmount = redeem_share_balances[msg.sender];

        if (_collateralAmount > 0) {
            redeem_collateral_balances[msg.sender] = 0;
            unclaimed_pool_collateral = unclaimed_pool_collateral.sub(_collateralAmount);
            _requestTransferFromReserve(collateral, msg.sender, _collateralAmount);
        }

        if (_shareAmount > 0) {
            redeem_share_balances[msg.sender] = 0;
            unclaimed_pool_share = unclaimed_pool_share.sub(_shareAmount);
            _requestTransferFromReserve(share, msg.sender, _shareAmount);
        }

        emit CollectRedemption(msg.sender, _collateralAmount, _shareAmount);
    }

    function treasuryMintByShares(address _receiver, uint256 _safeAssetAmount) external override onlyTreasury returns (uint256 _shareAmount) {
        require(mint_paused == false, "Minting is paused");
        mintedBySharesAmount = mintedBySharesAmount.add(_safeAssetAmount);
        require(mintedBySharesAmount <= mintedBySharesCap, "exceeds cap");
        trimExtraToTreasury();
        uint256 _share_price = getSharePrice();
        _shareAmount = _safeAssetAmount.mul(PRICE_PRECISION).div(_share_price);
        _transferToReserve(share, msg.sender, _shareAmount);
        ISafeAsset(safeAsset).poolMint(_receiver, _safeAssetAmount);
        emit TreasuryMintByShares(_receiver, _safeAssetAmount, _shareAmount);
    }

    function trimExtraToTreasury() public returns (uint256 _collateralAmount, uint256 _shareAmount) {
        uint256 _collateral_price = getCollateralPrice();
        uint256 _collateral_bal = ISafeTreasury(treasury).globalCollateralBalance();
        uint256 _collateralFullValue = _collateral_bal.mul(10**missing_decimals).mul(_collateral_price).div(PRICE_PRECISION);
        uint256 _total_safeAsset_supply = IERC20(safeAsset).totalSupply();
        uint256 _total_safeAsset_FullValue = _total_safeAsset_supply.mul(_collateral_price).div(PRICE_PRECISION);
        uint256 _share_bal = ISafeTreasury(treasury).globalShareBalance();
        address _profitSharingFund = ISafeTreasury(treasury).profitSharingFund();
        if (_collateralFullValue >= _total_safeAsset_FullValue) {
            _collateralAmount = _collateralFullValue.sub(_total_safeAsset_FullValue).div(10**missing_decimals).mul(PRICE_PRECISION).div(_collateral_price);
            if (_collateralAmount > 0) {
                _requestTransferFromReserve(collateral, _profitSharingFund, _collateralAmount);
            }
            if (_share_bal > 0) {
                _shareAmount = _share_bal;
                _requestTransferFromReserve(share, _profitSharingFund, _shareAmount);
            }
        } else {
            uint256 _share_true_price = getTrueSharePrice();
            uint256 _total_share_value = _share_true_price.mul(_share_bal).div(PRICE_PRECISION);
            uint256 _total_reserve_value = _collateralFullValue.add(_total_share_value);
            if (_total_reserve_value > _total_safeAsset_FullValue) {
                uint256 _extra_value_from_reserve = _total_reserve_value.sub(_total_safeAsset_FullValue);
                _shareAmount = _extra_value_from_reserve.mul(PRICE_PRECISION).div(_share_true_price);
                _requestTransferFromReserve(share, _profitSharingFund, _shareAmount);
            }
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _transferToReserve(
        address _token,
        address _sender,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            address _reserve = collateralReserve();
            require(_reserve != address(0), "Invalid reserve address");
            IERC20(_token).safeTransferFrom(_sender, _reserve, _amount);
            if (_token == share) {
                ISafeTreasury(treasury).reserveReceiveShares(_amount);
            }
        }
    }

    function _requestTransferFromReserve(
        address _token,
        address _receiver,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            ISafeTreasury(treasury).requestTransfer(_token, _receiver, _amount);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function toggleMinting() external onlyOwner {
        mint_paused = !mint_paused;
        emit MintPausedUpdated(mint_paused);
    }

    function toggleRedeeming() external onlyOwner {
        redeem_paused = !redeem_paused;
        emit RedeemPausedUpdated(redeem_paused);
    }

    function setShareOracle(address _shareOracle) external onlyOwner {
        require(_shareOracle != address(0), "Invalid address");
        shareOracle = _shareOracle;
    }

    function setCollateralOracle(address _collateralOracle) external onlyOwner {
        require(_collateralOracle != address(0), "Invalid address");
        collateralOracle = _collateralOracle;
    }

    function setRedemptionDelay(uint256 _redemption_delay) external onlyOwner {
        redemption_delay = _redemption_delay;
    }

    function setMintedBySharesCap(uint256 _mintedBySharesCap) external onlyOwner {
        require(_mintedBySharesCap <= 500000 ether, "too much");
        mintedBySharesCap = _mintedBySharesCap;
    }

    function setTargetCollateralRatio(uint256 _targetCollateralRatio) external onlyTreasuryOrOwner {
        require(_targetCollateralRatio <= 10000, "<=100%");
        require(_targetCollateralRatio >= 8200, ">=82%"); // share percent <= 18%
        targetCollateralRatio = _targetCollateralRatio;
        emit TargetCollateralRatioUpdated(_targetCollateralRatio);
    }

    /* ========== EMERGENCY ========== */

    function rescueStuckErc20(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}