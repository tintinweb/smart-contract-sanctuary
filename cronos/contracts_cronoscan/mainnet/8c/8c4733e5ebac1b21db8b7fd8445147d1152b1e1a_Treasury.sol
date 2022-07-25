/**
 *Submitted for verification at cronoscan.com on 2022-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
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

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            "operator: caller is not the operator"
        );
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(
            newOperator_ != address(0),
            "operator: zero address given for new operator"
        );
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(
            !checkSameOriginReentranted(),
            "ContractGuard: one block, one function"
        );
        require(
            !checkSameSenderReentranted(),
            "ContractGuard: one block, one function"
        );

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

interface IEpoch {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function nextEpochLength() external view returns (uint256);

    function getPegPrice() external view returns (int256);

    function getPegPriceUpdated() external view returns (int256);
}

interface ITreasury is IEpoch {
    function getMainTokenPrice() external view returns (uint256);

    function getMainTokenUpdatedPrice() external view returns (uint256);

    function getPegTokenPrice(address _token) external view returns (uint256);

    function getPegTokenUpdatedPrice(address _token)
        external
        view
        returns (uint256);

    function getMainTokenLockedBalance() external view returns (uint256);

    function getMainTokenCirculatingSupply() external view returns (uint256);

    function getNextExpansionRate() external view returns (uint256);

    function getNextExpansionAmount() external view returns (uint256);

    function getPegTokenExpansionRate(address) external view returns (uint256);

    function getPegTokenExpansionAmount(address)
        external
        view
        returns (uint256);

    function previousEpochMainTokenPrice() external view returns (uint256);

    function boardroom() external view returns (address);

    function boardroomSharedPercent() external view returns (uint256);

    function daoFund() external view returns (address);

    function daoFundSharedPercent() external view returns (uint256);

    function marketingFund() external view returns (address);

    function marketingFundSharedPercent() external view returns (uint256);

    function insuranceFund() external view returns (address);

    function insuranceFundSharedPercent() external view returns (uint256);

    function getBondDiscountRate() external view returns (uint256);

    function getBondPremiumRate() external view returns (uint256);

    function buyBonds(uint256 amount, uint256 targetPrice) external;

    function redeemBonds(uint256 amount, uint256 targetPrice) external;
}

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;

    function transferOwnership(address newOwner_) external;

    function distributeReward(address _launcherAddress) external;

    function totalBurned() external view returns (uint256);
}

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn)
        external
        view
        returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn)
        external
        view
        returns (uint144 _amountOut);

    function getPegPrice() external view returns (int256);

    function getPegPriceUpdated() external view returns (int256);
}

interface IBoardroom {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _member) external view returns (uint256);

    function share() external view returns (address);

    function earned(address _token, address _member)
        external
        view
        returns (uint256);

    function canClaimReward() external view returns (bool);

    function canWithdraw(address _member) external view returns (bool);

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getMainTokenPrice() external view returns (uint256);

    function setOperator(address _operator) external;

    function setLockUp(uint256 _withdrawLockupEpochs) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(address _token, uint256 _amount) external;

    function governanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

interface IRegulationStats {
    function addEpochInfo(
        uint256 epochNumber,
        uint256 twap,
        uint256 expanded,
        uint256 boardroomFunding,
        uint256 daoFunding,
        uint256 marketingFunding,
        uint256 insuranceFunding
    ) external;

    function addPegEpochInfo(
        address _pegToken,
        uint256 epochNumber,
        uint256 twap,
        uint256 expanded,
        uint256 boardroomFunding,
        uint256 daoFunding,
        uint256 marketingFunding,
        uint256 insuranceFunding
    ) external;

    function addBonded(uint256 epochNumber, uint256 added) external;

    function addRedeemed(uint256 epochNumber, uint256 added) external;
}

interface IRewardPool {
    function reward() external view returns (address);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function withdrawAll(uint256 _pid) external;

    function harvestAllRewards() external;

    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function pendingAllRewards(address _user) external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function getPoolInfo(uint256 _pid)
        external
        view
        returns (address _lp, uint256 _allocPoint);

    function getRewardPerSecond() external view returns (uint256);

    function updateRewardRate(uint256 _newRate) external;
}

// PAYTOKEN OPERA FINANCE
contract Treasury is ITreasury, ContractGuard, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // flags
    bool public initialized = false;

    // epoch
    uint256 public startTime;
    uint256 public lastEpochTime;
    uint256 private epoch_ = 0;
    uint256 private epochLength_ = 0;
    uint256 public epochSupplyContractionLeft = 0;

    // core components
    address public maintoken;
    address public bondtoken;

    address public override boardroom;
    address public maintokenOracle;

    // price
    uint256 public maintokenPriceOne;
    uint256 public maintokenPriceCeiling;

    uint256 public seigniorageSaved;

    uint256 public nextSupplyTarget;

    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxSupplyContractionPercent;
    uint256 public maxDebtRatioPercent;

    // 28 first epochs (1 week) with 4.5% expansion regardless of maintoken price
    uint256 public bootstrapEpochs;
    uint256 public bootstrapSupplyExpansionPercent;

    uint256 public override previousEpochMainTokenPrice;
    uint256 public allocateSeigniorageSalary;
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate; // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumPercent;
    uint256 public mintingFactorForPayingDebt; // print extra maintoken during debt phase

    address public override daoFund;
    uint256 public override daoFundSharedPercent; // 3000 (30%)

    address public override marketingFund;
    uint256 public override marketingFundSharedPercent; // 1000 (10%)

    address public override insuranceFund;
    uint256 public override insuranceFundSharedPercent; // 2000 (20%)

    address public regulationStats;

    address[] public maintokenLockedAccounts;

    // Multi-Pegs
    address[] public pegTokens;
    mapping(address => address) public pegTokenOracle;
    mapping(address => address) public pegTokenFarmingPool; // to exclude balance from supply
    mapping(address => uint256) public pegTokenEpochStart;
    mapping(address => uint256) public pegTokenSupplyTarget;
    mapping(address => uint256) public pegTokenMaxSupplyExpansionPercent; // 1% = 10000
    bool public multiPegEnabled;
    mapping(uint256 => mapping(address => bool)) public hasAllocatedPegToken; // epoch => pegToken => true/false

    mapping(address => bool) public strategist;

    /* =================== Added variables =================== */

    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event RedeemedBonds(
        address indexed from,
        uint256 maintokenAmount,
        uint256 bondAmount
    );
    event BoughtBonds(
        address indexed from,
        uint256 maintokenAmount,
        uint256 bondAmount
    );
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event FundingAdded(
        uint256 indexed epoch,
        uint256 timestamp,
        uint256 price,
        uint256 expanded,
        uint256 boardroomFunded,
        uint256 daoFunded,
        uint256 marketingFunded,
        uint256 insuranceFund
    );
    event PegTokenFundingAdded(
        address indexed pegToken,
        uint256 indexed epoch,
        uint256 timestamp,
        uint256 price,
        uint256 expanded,
        uint256 boardroomFunded,
        uint256 daoFunded,
        uint256 marketingFunded,
        uint256 insuranceFund
    );

    /* =================== Modifier =================== */

    modifier onlyOperator() {
        require(operator == msg.sender, "!operator");
        _;
    }

    modifier onlyStrategist() {
        require(
            strategist[msg.sender] || operator == msg.sender,
            "!strategist && !operator"
        );
        _;
    }

    modifier checkEpoch() {
        uint256 _nextEpochPoint = nextEpochPoint();
        require(block.timestamp >= _nextEpochPoint, "!opened");

        _;

        lastEpochTime = _nextEpochPoint;
        epoch_ = epoch_.add(1);
        epochSupplyContractionLeft = (getMainTokenPrice() > maintokenPriceCeiling)
            ? 0
            : IERC20(maintoken).totalSupply().mul(maxSupplyContractionPercent).div(
                10000
            );
    }

    modifier checkOperator() {
        require(
            IBasisAsset(maintoken).operator() == address(this) &&
                IBasisAsset(bondtoken).operator() == address(this),
            "need more permission"
        );

        _;
    }

    modifier notInitialized() {
        require(!initialized, "initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // epoch
    function epoch() public view override returns (uint256) {
        return epoch_;
    }

    function nextEpochPoint() public view override returns (uint256) {
        return lastEpochTime.add(nextEpochLength());
    }

    function nextEpochLength() public view override returns (uint256) {
        return epochLength_;
    }

    function getPegPrice() external view override returns (int256) {
        return IOracle(maintokenOracle).getPegPrice();
    }

    function getPegPriceUpdated() external view override returns (int256) {
        return IOracle(maintokenOracle).getPegPriceUpdated();
    }

    // oracle
    function getMainTokenPrice() public view override returns (uint256 maintokenPrice) {
        try IOracle(maintokenOracle).consult(maintoken, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("oracle failed");
        }
    }

    function getMainTokenUpdatedPrice()
        public
        view
        override
        returns (uint256 _maintokenPrice)
    {
        try IOracle(maintokenOracle).twap(maintoken, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("oracle failed");
        }
    }

    function getPegTokenPrice(address _token)
        public
        view
        override
        returns (uint256 _pegTokenPrice)
    {
        if (_token == maintoken) {
            return getMainTokenPrice();
        }
        try IOracle(pegTokenOracle[_token]).consult(_token, 1e18) returns (
            uint144 price
        ) {
            return uint256(price);
        } catch {
            revert("oracle failed");
        }
    }

    function getPegTokenUpdatedPrice(address _token)
        public
        view
        override
        returns (uint256 _pegTokenPrice)
    {
        if (_token == maintoken) {
            return getMainTokenUpdatedPrice();
        }
        try IOracle(pegTokenOracle[_token]).twap(_token, 1e18) returns (
            uint144 price
        ) {
            return uint256(price);
        } catch {
            revert("oracle failed");
        }
    }

    function boardroomSharedPercent() external view override returns (uint256) {
        return
            uint256(10000)
                .sub(daoFundSharedPercent)
                .sub(marketingFundSharedPercent)
                .sub(insuranceFundSharedPercent);
    }

    // budget
    function getReserve() external view returns (uint256) {
        return seigniorageSaved;
    }

    function getBurnablemaintokenLeft()
        external
        view
        returns (uint256 _burnablemaintokenLeft)
    {
        uint256 _maintokenPrice = getMainTokenPrice();
        if (_maintokenPrice <= maintokenPriceOne) {
            uint256 _bondMaxSupply = IERC20(maintoken)
                .totalSupply()
                .mul(maxDebtRatioPercent)
                .div(10000);
            uint256 _bondSupply = IERC20(bondtoken).totalSupply();
            if (_bondMaxSupply > _bondSupply) {
                uint256 _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
                uint256 _maxBurnablemaintoken = _maxMintableBond
                    .mul(getBondDiscountRate())
                    .div(1e18);
                _burnablemaintokenLeft = Math.min(
                    epochSupplyContractionLeft,
                    _maxBurnablemaintoken
                );
            }
        }
    }

    function getRedeemableBonds()
        external
        view
        returns (uint256 _redeemableBonds)
    {
        uint256 _maintokenPrice = getMainTokenPrice();
        if (_maintokenPrice > maintokenPriceCeiling) {
            uint256 _totalmaintoken = IERC20(maintoken).balanceOf(address(this));
            uint256 _rate = getBondPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalmaintoken.mul(1e18).div(_rate);
            }
        }
    }

    function getBondDiscountRate()
        public
        view
        override
        returns (uint256 _rate)
    {
        uint256 _maintokenPrice = getMainTokenPrice();
        if (_maintokenPrice <= maintokenPriceOne) {
            if (discountPercent == 0) {
                // no discount
                _rate = maintokenPriceOne;
            } else {
                uint256 _bondAmount = maintokenPriceOne.mul(1e18).div(_maintokenPrice); // to burn 1 maintoken
                uint256 _discountAmount = _bondAmount
                    .sub(maintokenPriceOne)
                    .mul(discountPercent)
                    .div(10000);
                _rate = maintokenPriceOne.add(_discountAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getBondPremiumRate() public view override returns (uint256 _rate) {
        uint256 _maintokenPrice = getMainTokenPrice();
        if (_maintokenPrice > maintokenPriceCeiling) {
            if (premiumPercent == 0) {
                // no premium bonus
                _rate = maintokenPriceOne;
            } else {
                uint256 _premiumAmount = _maintokenPrice
                    .sub(maintokenPriceOne)
                    .mul(premiumPercent)
                    .div(10000);
                _rate = maintokenPriceOne.add(_premiumAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getMainTokenCirculatingSupply()
        public
        view
        override
        returns (uint256)
    {
        return IERC20(maintoken).totalSupply().sub(getMainTokenLockedBalance());
    }

    function getMainTokenLockedBalance()
        public
        view
        override
        returns (uint256 _lockedBalance)
    {
        uint256 _length = maintokenLockedAccounts.length;
        IERC20 _maintoken = IERC20(maintoken);
        for (uint256 i = 0; i < _length; i++) {
            _lockedBalance = _lockedBalance.add(
                _maintoken.balanceOf(maintokenLockedAccounts[i])
            );
        }
    }

    function getNextExpansionRate() public view override returns (uint256) {
        return getPegTokenExpansionRate(maintoken);
    }

    function getNextExpansionAmount() external view override returns (uint256) {
        return getMainTokenCirculatingSupply().mul(getNextExpansionRate()).div(1e6);
    }

    function pegTokenLength() external view returns (uint256) {
        return pegTokens.length;
    }

    function getCirculatingSupply(address _token)
        public
        view
        returns (uint256)
    {
        return
            (_token == maintoken)
                ? getMainTokenCirculatingSupply()
                : IERC20(_token).totalSupply().sub(
                    IERC20(_token).balanceOf(pegTokenFarmingPool[_token])
                );
    }

    function getPegTokenExpansionRate(address _pegToken)
        public
        view
        override
        returns (uint256 _rate)
    {
        if (_pegToken != maintoken) {
            uint256 _epochStart = pegTokenEpochStart[_pegToken];
            if (_epochStart == 0 || _epochStart > epoch_.add(1)) return 0;
        } else if (epoch_ < bootstrapEpochs) {
            // 28 first epochs with 3.5% expansion
            return bootstrapSupplyExpansionPercent; // 1% = 1e18
        }
        uint256 _twap = getPegTokenUpdatedPrice(_pegToken);
        if (_twap > maintokenPriceCeiling) {
            uint256 _percentage = _twap.sub(maintokenPriceOne); // 1% = 1e16
            uint256 _mse = (_pegToken == maintoken)
                ? maxSupplyExpansionPercent.mul(1e14)
                : pegTokenMaxSupplyExpansionPercent[_pegToken].mul(1e12);
            if (_percentage > _mse) {
                _percentage = _mse;
            }
            _rate = _percentage.div(1e12);
        }
    }

    function getPegTokenExpansionAmount(address _pegToken)
        public
        view
        override
        returns (uint256)
    {
        uint256 _rate = getPegTokenExpansionRate(_pegToken);
        return getCirculatingSupply(_pegToken).mul(_rate).div(1e6);
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _maintoken,
        address _bondtoken,
        address _maintokenOracle,
        address _boardroom,
        uint256 _startTime
    ) public notInitialized {
        maintoken = _maintoken;
        bondtoken = _bondtoken;
        maintokenOracle = _maintokenOracle;
        boardroom = _boardroom;

        startTime = _startTime;
        epochLength_ = 6 hours;
        lastEpochTime = _startTime.sub(6 hours);

        maintokenPriceOne = 10**18; // This is to allow a PEG of 1 maintoken per VVS
        maintokenPriceCeiling = maintokenPriceOne.mul(1001).div(1000);

        maxSupplyExpansionPercent = 350; // Upto 3.0% supply for expansion

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for boardroom
        maxSupplyContractionPercent = 450; // Upto 4.5% supply for contraction (to burn maintoken and mint bondtoken)
        maxDebtRatioPercent = 4500; // Upto 45% supply of bondtoken to purchase

        maxDiscountRate = 13e17; // 30% - when purchasing bond
        maxPremiumRate = 13e17; // 30% - when redeeming bond

        discountPercent = 0; // no discount
        premiumPercent = 6500; // 65% premium

        // First 28 epochs with 4.5% expansion
        bootstrapEpochs = 0;
        bootstrapSupplyExpansionPercent = 350;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(maintoken).balanceOf(address(this));

        nextSupplyTarget = 1000000 ether; // 2B supply is the next target to reduce expansion rate
        allocateSeigniorageSalary = 1 ether; // 1 MAINTOKEN for allocateSeigniorage() calling

        initialized = true;
        operator = msg.sender;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setBoardroom(address _boardroom) external onlyOperator {
        boardroom = _boardroom;
    }

    function setRegulationStats(address _regulationStats)
        external
        onlyOperator
    {
        regulationStats = _regulationStats;
    }

    function setMainTokenOracle(address _maintokenOracle) external onlyOperator {
        maintokenOracle = _maintokenOracle;
    }

    function setMainTokenPriceCeiling(uint256 _maintokenPriceCeiling)
        external
        onlyOperator
    {
        require(
            _maintokenPriceCeiling >= maintokenPriceOne &&
                _maintokenPriceCeiling <= maintokenPriceOne.mul(120).div(100),
            "out of range"
        ); // [$1.0, $1.2]
        maintokenPriceCeiling = _maintokenPriceCeiling;
    }

    function setEpochLength(uint256 _epochLength) external onlyOperator {
        epochLength_ = _epochLength;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent)
        external
        onlyOperator
    {
        require(
            _maxSupplyExpansionPercent >= 10 &&
                _maxSupplyExpansionPercent <= 1000,
            "out of range"
        ); // [0.1%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent)
        external
        onlyOperator
    {
        require(
            _bondDepletionFloorPercent >= 500 &&
                _bondDepletionFloorPercent <= 10000,
            "out of range"
        ); // [5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxSupplyContractionPercent(
        uint256 _maxSupplyContractionPercent
    ) external onlyOperator {
        require(
            _maxSupplyContractionPercent >= 100 &&
                _maxSupplyContractionPercent <= 1500,
            "out of range"
        ); // [0.1%, 15%]
        maxSupplyContractionPercent = _maxSupplyContractionPercent;
    }

    function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent)
        external
        onlyOperator
    {
        require(
            _maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000,
            "out of range"
        ); // [10%, 100%]
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    function setBootstrap(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 120, "out of range"); // <= 1 month
        require(_bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 1000, "out of range"); // [1%, 10%]
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }

    function toggleMultiPegEnabled() external onlyOperator {
        multiPegEnabled = !multiPegEnabled;
    }

    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _marketingFund,
        uint256 _marketingFundSharedPercent,
        address _insuranceFund,
        uint256 _insuranceFundSharedPercent
    ) external onlyOperator {
        require(_daoFundSharedPercent == 0 || _daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 4000, "out of range"); // <= 40%
        require(
            _marketingFundSharedPercent == 0 || _marketingFund != address(0),
            "zero"
        );
        require(_marketingFundSharedPercent <= 2000, "out of range"); // <= 20%
        require(
            _insuranceFundSharedPercent == 0 || _insuranceFund != address(0),
            "zero"
        );
        require(_insuranceFundSharedPercent <= 3000, "out of range"); // <= 30%
        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        marketingFund = _marketingFund;
        marketingFundSharedPercent = _marketingFundSharedPercent;
        insuranceFund = _insuranceFund;
        insuranceFundSharedPercent = _insuranceFundSharedPercent;
    }

    function setAllocateSeigniorageSalary(uint256 _allocateSeigniorageSalary)
        external
        onlyOperator
    {
        require(_allocateSeigniorageSalary <= 10000 ether, "too much");
        allocateSeigniorageSalary = _allocateSeigniorageSalary;
    }

    function setDiscountConfig(
        uint256 _maxDiscountRate,
        uint256 _discountPercent
    ) external onlyOperator {
        require(_discountPercent <= 20000, "over 200%");
        maxDiscountRate = _maxDiscountRate;
        discountPercent = _discountPercent;
    }

    function setPremiumConfig(uint256 _maxPremiumRate, uint256 _premiumPercent)
        external
        onlyOperator
    {
        require(_premiumPercent <= 20000, "over 200%");
        maxPremiumRate = _maxPremiumRate;
        premiumPercent = _premiumPercent;
    }

    function setMintingFactorForPayingDebt(uint256 _mintingFactorForPayingDebt)
        external
        onlyOperator
    {
        require(
            _mintingFactorForPayingDebt >= 10000 &&
                _mintingFactorForPayingDebt <= 20000,
            "out of range"
        ); // [100%, 200%]
        mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
    }

    function setNextSupplyTarget(uint256 _target) external onlyOperator {
        require(_target > IERC20(maintoken).totalSupply(), "too small");
        nextSupplyTarget = _target;
    }

    function setMainTokenLockedAccounts(address[] memory _maintokenLockedAccounts)
        external
        onlyOperator
    {
        delete maintokenLockedAccounts;
        uint256 _length = _maintokenLockedAccounts.length;
        for (uint256 i = 0; i < _length; i++) {
            maintokenLockedAccounts.push(_maintokenLockedAccounts[i]);
        }
    }

    function addPegToken(address _token) external onlyOperator {
        require(IERC20(_token).totalSupply() > 0, "invalid token");
        uint256 _ptlength = pegTokens.length;
        for (uint256 _pti = 0; _pti < _ptlength; ++_pti) {
            require(pegTokens[_pti] != _token, "Boardroom: existing token");
        }
        pegTokens.push(_token);
    }

    function setPegTokenConfig(
        address _token,
        address _oracle,
        address _pool,
        uint256 _epochStart,
        uint256 _supplyTarget,
        uint256 _expansionPercent
    ) external onlyOperator {
        pegTokenOracle[_token] = _oracle;
        pegTokenFarmingPool[_token] = _pool;
        pegTokenEpochStart[_token] = _epochStart;
        pegTokenSupplyTarget[_token] = _supplyTarget;
        pegTokenMaxSupplyExpansionPercent[_token] = _expansionPercent;
    }

    function setStrategistStatus(address _account, bool _status)
        external
        onlyOperator
    {
        strategist[_account] = _status;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updatemaintokenPrice() internal {
        try IOracle(maintokenOracle).update() {} catch {}
    }

    function _updatePegTokenPrice(address _token) internal {
        try IOracle(pegTokenOracle[_token]).update() {} catch {}
    }

    function buyBonds(uint256 _maintokenAmount, uint256 targetPrice)
        external
        override
        onlyOneBlock
        checkOperator
        nonReentrant
    {
        require(_maintokenAmount > 0, "zero amount");

        uint256 maintokenPrice = getMainTokenPrice();
        require(maintokenPrice == targetPrice, "price moved");
        require(
            maintokenPrice < maintokenPriceOne, // price < $1
            "maintokenPrice not eligible for bond purchase"
        );

        require(
            _maintokenAmount <= epochSupplyContractionLeft,
            "not enough bond left to purchase"
        );

        uint256 _rate = getBondDiscountRate();
        require(_rate > 0, "invalid bond rate");

        address _maintoken = maintoken;
        uint256 _bondAmount = _maintokenAmount.mul(_rate).div(1e18);
        uint256 _maintokenSupply = IERC20(maintoken).totalSupply();
        uint256 newBondSupply = IERC20(bondtoken).totalSupply().add(_bondAmount);
        require(
            newBondSupply <= _maintokenSupply.mul(maxDebtRatioPercent).div(10000),
            "over max debt ratio"
        );

        IBasisAsset(_maintoken).burnFrom(msg.sender, _maintokenAmount);
        IBasisAsset(bondtoken).mint(msg.sender, _bondAmount);

        epochSupplyContractionLeft = epochSupplyContractionLeft.sub(
            _maintokenAmount
        );
        _updatemaintokenPrice();
        if (regulationStats != address(0))
            IRegulationStats(regulationStats).addBonded(epoch_, _bondAmount);

        emit BoughtBonds(msg.sender, _maintokenAmount, _bondAmount);
    }

    function redeemBonds(uint256 _bondAmount, uint256 targetPrice)
        external
        override
        onlyOneBlock
        checkOperator
        nonReentrant
    {
        require(_bondAmount > 0, "cannot redeem bonds with zero amount");

        uint256 maintokenPrice = getMainTokenPrice();
        require(maintokenPrice == targetPrice, "price moved");
        require(
            maintokenPrice > maintokenPriceCeiling, // price > $1.01
            "maintokenPrice not eligible for bond purchase"
        );

        uint256 _rate = getBondPremiumRate();
        require(_rate > 0, "invalid bond rate");

        uint256 _maintokenAmount = _bondAmount.mul(_rate).div(1e18);
        require(
            IERC20(maintoken).balanceOf(address(this)) >= _maintokenAmount,
            "treasury has no more budget"
        );

        seigniorageSaved = seigniorageSaved.sub(
            Math.min(seigniorageSaved, _maintokenAmount)
        );
        allocateSeigniorageSalary = 1000 ether; // 1000 maintoken salary for calling allocateSeigniorage()

        IBasisAsset(bondtoken).burnFrom(msg.sender, _bondAmount);
        IERC20(maintoken).safeTransfer(msg.sender, _maintokenAmount);

        _updatemaintokenPrice();
        if (regulationStats != address(0))
            IRegulationStats(regulationStats).addRedeemed(epoch_, _maintokenAmount);

        emit RedeemedBonds(msg.sender, _maintokenAmount, _bondAmount);
    }

    function _sendToBoardroom(uint256 _amount, uint256 _expanded) internal {
        address _maintoken = maintoken;
        IBasisAsset(_maintoken).mint(address(this), _amount);

        uint256 _daoFundSharedAmount = 0;
        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
            IERC20(_maintoken).transfer(daoFund, _daoFundSharedAmount);
        }

        uint256 _marketingFundSharedAmount = 0;
        if (marketingFundSharedPercent > 0) {
            _marketingFundSharedAmount = _amount
                .mul(marketingFundSharedPercent)
                .div(10000);
            IERC20(_maintoken).transfer(marketingFund, _marketingFundSharedAmount);
        }

        uint256 _insuranceFundSharedAmount = 0;
        if (insuranceFundSharedPercent > 0) {
            _insuranceFundSharedAmount = _amount
                .mul(insuranceFundSharedPercent)
                .div(10000);
            IERC20(_maintoken).transfer(insuranceFund, _insuranceFundSharedAmount);
        }

        _amount = _amount
            .sub(_daoFundSharedAmount)
            .sub(_marketingFundSharedAmount)
            .sub(_insuranceFundSharedAmount);

        IERC20(_maintoken).safeIncreaseAllowance(boardroom, _amount);
        IBoardroom(boardroom).allocateSeigniorage(_maintoken, _amount);

        if (regulationStats != address(0))
            IRegulationStats(regulationStats).addEpochInfo(
                epoch_.add(1),
                previousEpochMainTokenPrice,
                _expanded,
                _amount,
                _daoFundSharedAmount,
                _marketingFundSharedAmount,
                _insuranceFundSharedAmount
            );
        emit FundingAdded(
            epoch_.add(1),
            block.timestamp,
            previousEpochMainTokenPrice,
            _expanded,
            _amount,
            _daoFundSharedAmount,
            _marketingFundSharedAmount,
            _insuranceFundSharedAmount
        );
    }

    function allocateSeigniorage()
        external
        onlyOneBlock
        checkEpoch
        checkOperator
        nonReentrant
    {
        _updatemaintokenPrice();
        previousEpochMainTokenPrice = getMainTokenPrice();
        address _maintoken = maintoken;
        uint256 _supply = getMainTokenCirculatingSupply();
        uint256 _nextSupplyTarget = nextSupplyTarget;
        if (_supply >= _nextSupplyTarget) {
            nextSupplyTarget = _nextSupplyTarget.mul(12500).div(10000); // +25%
            maxSupplyExpansionPercent = maxSupplyExpansionPercent.mul(9500).div(
                    10000
                ); // -5%
            if (maxSupplyExpansionPercent < 25) {
                maxSupplyExpansionPercent = 25; // min 0.25%
            }
        }
        uint256 _seigniorage;
        if (epoch_ < bootstrapEpochs) {
            // 28 first epochs with 4.5% expansion
            if (epoch_ == 0) _supply = IERC20(_maintoken).totalSupply();
            _seigniorage = _supply.mul(bootstrapSupplyExpansionPercent).div(
                10000
            );
            _sendToBoardroom(_seigniorage, _seigniorage);
        } else {
            if (previousEpochMainTokenPrice > maintokenPriceCeiling) {
                // Expansion ($maintoken Price > 1 $ETH): there is some seigniorage to be allocated
                uint256 bondSupply = IERC20(bondtoken).totalSupply();
                uint256 _percentage = previousEpochMainTokenPrice.sub(
                    maintokenPriceOne
                );
                uint256 _savedForBond;
                uint256 _savedForBoardroom;
                uint256 _mse = maxSupplyExpansionPercent.mul(1e14);
                if (_percentage > _mse) {
                    _percentage = _mse;
                }
                if (
                    seigniorageSaved >=
                    bondSupply.mul(bondDepletionFloorPercent).div(10000)
                ) {
                    // saved enough to pay debt, mint as usual rate
                    _savedForBoardroom = _seigniorage = _supply
                        .mul(_percentage)
                        .div(1e18);
                } else {
                    // have not saved enough to pay debt, mint more
                    _seigniorage = _supply.mul(_percentage).div(1e18);
                    _savedForBoardroom = _seigniorage
                        .mul(seigniorageExpansionFloorPercent)
                        .div(10000);
                    _savedForBond = _seigniorage.sub(_savedForBoardroom);
                    if (mintingFactorForPayingDebt > 0) {
                        _savedForBond = _savedForBond
                            .mul(mintingFactorForPayingDebt)
                            .div(10000);
                    }
                }
                if (_savedForBoardroom > 0) {
                    _sendToBoardroom(_savedForBoardroom, _seigniorage);
                } else {
                    // function addEpochInfo(uint256 epochNumber, uint256 twap, uint256 expanded, uint256 boardroomFunding, uint256 daoFunding, uint256 marketingFunding, uint256 insuranceFunding) external;
                    if (regulationStats != address(0))
                        IRegulationStats(regulationStats).addEpochInfo(
                            epoch_.add(1),
                            previousEpochMainTokenPrice,
                            0,
                            0,
                            0,
                            0,
                            0
                        );
                    emit FundingAdded(
                        epoch_.add(1),
                        block.timestamp,
                        previousEpochMainTokenPrice,
                        0,
                        0,
                        0,
                        0,
                        0
                    );
                }
                if (_savedForBond > 0) {
                    seigniorageSaved = seigniorageSaved.add(_savedForBond);
                    IBasisAsset(_maintoken).mint(address(this), _savedForBond);
                    emit TreasuryFunded(block.timestamp, _savedForBond);
                }
            } else if (previousEpochMainTokenPrice < maintokenPriceOne) {
                if (regulationStats != address(0))
                    IRegulationStats(regulationStats).addEpochInfo(
                        epoch_.add(1),
                        previousEpochMainTokenPrice,
                        0,
                        0,
                        0,
                        0,
                        0
                    );
                emit FundingAdded(
                    epoch_.add(1),
                    block.timestamp,
                    previousEpochMainTokenPrice,
                    0,
                    0,
                    0,
                    0,
                    0
                );
            }
        }
        if (allocateSeigniorageSalary > 0) {
            IBasisAsset(_maintoken).mint(
                address(msg.sender),
                allocateSeigniorageSalary
            );
        }
        if (multiPegEnabled) {
            uint256 _ptlength = pegTokens.length;
            for (uint256 _pti = 0; _pti < _ptlength; ++_pti) {
                address _pegToken = pegTokens[_pti];
                uint256 _epochStart = pegTokenEpochStart[_pegToken];
                if (_epochStart > 0 && _epochStart <= epoch_.add(1)) {
                    _updatePegTokenPrice(_pegToken);
                    _allocateSeignioragePegToken(epoch_, _pegToken);
                }
            }
        }
    }

    function _allocateSeignioragePegToken(uint256 _epoch, address _pegToken)
        internal
    {
        if (hasAllocatedPegToken[_epoch.add(1)][_pegToken]) return; // skip
        hasAllocatedPegToken[_epoch.add(1)][_pegToken] = true;
        uint256 _supply = getCirculatingSupply(_pegToken);
        if (_supply >= pegTokenSupplyTarget[_pegToken]) {
            pegTokenSupplyTarget[_pegToken] = pegTokenSupplyTarget[_pegToken]
                .mul(12500)
                .div(10000); // +25%
            pegTokenMaxSupplyExpansionPercent[
                _pegToken
            ] = pegTokenMaxSupplyExpansionPercent[_pegToken].mul(9500).div(
                10000
            ); // -5%
            if (pegTokenMaxSupplyExpansionPercent[_pegToken] < 1000) {
                pegTokenMaxSupplyExpansionPercent[_pegToken] = 1000; // min 0.1%
            }
        }
        uint256 _pegTokenTwap = getPegTokenPrice(_pegToken);
        if (_pegTokenTwap > maintokenPriceCeiling) {
            uint256 _percentage = _pegTokenTwap.sub(maintokenPriceOne); // 1% = 1e16
            uint256 _mse = pegTokenMaxSupplyExpansionPercent[_pegToken].mul(
                1e12
            ); // 10000 = 1%
            if (_percentage > _mse) {
                _percentage = _mse;
            }
            uint256 _expanded = _supply.mul(_percentage).div(1e18);
            uint256 _daoFundSharedAmount = 0;
            uint256 _marketingFundSharedAmount = 0;
            uint256 _insuranceFundSharedAmount = 0;
            uint256 _boardroomAmount = 0;
            if (_expanded > 0) {
                IBasisAsset(_pegToken).mint(address(this), _expanded);

                if (daoFundSharedPercent > 0) {
                    _daoFundSharedAmount = _expanded
                        .mul(daoFundSharedPercent)
                        .div(10000);
                    IERC20(_pegToken).transfer(daoFund, _daoFundSharedAmount);
                }

                if (marketingFundSharedPercent > 0) {
                    _marketingFundSharedAmount = _expanded
                        .mul(marketingFundSharedPercent)
                        .div(10000);
                    IERC20(_pegToken).transfer(
                        marketingFund,
                        _marketingFundSharedAmount
                    );
                }

                if (insuranceFundSharedPercent > 0) {
                    _insuranceFundSharedAmount = _expanded
                        .mul(insuranceFundSharedPercent)
                        .div(10000);
                    IERC20(_pegToken).transfer(
                        insuranceFund,
                        _insuranceFundSharedAmount
                    );
                }

                _boardroomAmount = _expanded
                    .sub(_daoFundSharedAmount)
                    .sub(_marketingFundSharedAmount)
                    .sub(_insuranceFundSharedAmount);

                IERC20(_pegToken).safeIncreaseAllowance(
                    boardroom,
                    _boardroomAmount
                );
                IBoardroom(boardroom).allocateSeigniorage(
                    _pegToken,
                    _boardroomAmount
                );
            }

            if (regulationStats != address(0))
                IRegulationStats(regulationStats).addPegEpochInfo(
                    _pegToken,
                    _epoch.add(1),
                    _pegTokenTwap,
                    _expanded,
                    _boardroomAmount,
                    _daoFundSharedAmount,
                    _marketingFundSharedAmount,
                    _insuranceFundSharedAmount
                );

            emit PegTokenFundingAdded(
                _pegToken,
                _epoch.add(1),
                block.timestamp,
                _pegTokenTwap,
                _expanded,
                _boardroomAmount,
                _daoFundSharedAmount,
                _marketingFundSharedAmount,
                _insuranceFundSharedAmount
            );
        }
    }

    /**
     * @dev should call this after the main function allocateSeigniorage()
     */
    function governanceAllocateSeignioragePegToken(address _pegToken)
        public
        onlyStrategist
    {
        _updatePegTokenPrice(_pegToken);
        uint256 _epoch = (epoch_ == 0) ? 0 : epoch_.sub(1);
        _allocateSeignioragePegToken(_epoch, _pegToken);
    }

    function governanceAllocateSeigniorageForAllPegTokens() external {
        uint256 _ptlength = pegTokens.length;
        for (uint256 _pti = 0; _pti < _ptlength; ++_pti) {
            address _pegToken = pegTokens[_pti];
            uint256 _epochStart = pegTokenEpochStart[_pegToken];
            if (_epochStart > 0 && _epochStart <= epoch_) {
                governanceAllocateSeignioragePegToken(_pegToken);
            }
        }
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(maintoken), "maintoken");
        require(address(_token) != address(bondtoken), "bond");
        _token.safeTransfer(_to, _amount);
    }

    function tokenTransferOperator(address _token, address _operator)
        external
        onlyOperator
    {
        IBasisAsset(_token).transferOperator(_operator);
    }

    function boardroomSetOperator(address _operator) external onlyOperator {
        IBoardroom(boardroom).setOperator(_operator);
    }

    function boardroomGovernanceRecoverUnsupported(
        address _boardRoomOrToken,
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IBoardroom(_boardRoomOrToken).governanceRecoverUnsupported(
            _token,
            _amount,
            _to
        );
    }
}