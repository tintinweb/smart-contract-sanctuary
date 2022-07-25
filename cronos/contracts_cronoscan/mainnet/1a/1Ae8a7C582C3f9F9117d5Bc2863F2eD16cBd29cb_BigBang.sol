/**
 *Submitted for verification at cronoscan.com on 2022-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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



// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

    constructor() {
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
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}




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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


/**
       _____ _             __     _______                           
      / ___/(_)___  ____ _/ /__  / ____(_)___  ____ _____  ________ 
      \__ \/ / __ \/ __ `/ / _ \/ /_  / / __ \/ __ `/ __ \/ ___/ _ \
     ___/ / / / / / /_/ / /  __/ __/ / / / / / /_/ / / / / /__/  __/
    /____/_/_/ /_/\__, /_/\___/_/   /_/_/ /_/\__,_/_/ /_/\___/\___/ 
                 /____/                                             
*/


/**
 * Single Finance token with Governance.
 */
contract SingleToken is ERC20("SINGLE Token", "SINGLE"), Ownable {
  using SafeMath for uint256;

  uint256 private constant CAP = 1000_000_000e18;

  uint256 public constant INVESTOR_MINT_CAP = 137_000_000e18;
  uint256 public constant LIQUIDITY_MINT_CAP = 20_000_000e18;

  uint256 public startMiningTimestamp;
  // uint256 public startReleaseTimestamp;
  uint256 public launchPeriodEndTimestamp;
  uint256 public nextAdjustTimestamp;

  uint256 public INITIAL_SUPPLY_PER_BLOCK;
  uint256 public SUPPLY_PER_BLOCK;
  uint256 public constant LAUNCH_PERIOD_ADJUST_WINDOW = 365 days / 12;
  uint256 public constant SUPPLY_HALVING_WINDOW = 365 days / 2;

  uint256 public constant ECOSYSTEM_TGE_RELEASE = 11_150_000e18;
  uint256 public constant ECOSYSTEM_VESTING_AMT = 211_850_000e18;
  uint256 public constant ECOSYSTEM_VESTING_PERIOD = 365 days *2; // 24 months

  uint256 public constant TEAM_TGE_RELEASE = 2_200_000e18;
  uint256 public constant TEAM_VESTING_AMT = 217_800_000e18;
  uint256 public constant TEAM_VESTING_PERIOD = 365 days *2; // 24 months

  uint256 public investorMinted = 0;
  uint256 public liquidityMinted = 0;
  uint256 public teamMinted = 0;
  uint256 public ecosystemMinted = 0;

  
  event SupplyAdjusted(uint256 supplyPerBlock, uint256 nextAdjustTs);


  constructor(
    uint256 initialSupplyPerBlock,
    uint256 _startMiningTimestamp
  ) {

    if(_startMiningTimestamp == 0){
      _startMiningTimestamp = block.timestamp;
    }

    require(block.timestamp <= _startMiningTimestamp, "cannot set past block number");

    startMiningTimestamp = _startMiningTimestamp;
    
    launchPeriodEndTimestamp = startMiningTimestamp.add(SUPPLY_HALVING_WINDOW);

    // available for first adjustment after mining started
    nextAdjustTimestamp = startMiningTimestamp;

    INITIAL_SUPPLY_PER_BLOCK = initialSupplyPerBlock;
    SUPPLY_PER_BLOCK = 0;

  }

  function cap() public pure returns (uint256) {
    return CAP;
  }



  
  function mint(address _to, uint256 _amount) public onlyOwner {
    require(totalSupply().add(_amount) <= cap(), "cap exceeded");
    _mint(_to, _amount);
    _moveDelegates(address(0), _delegates[_to], _amount);
  }

  function mintForLiquidity(address _to, uint256 _amount) public onlyOwner {
    require(liquidityMinted.add(_amount) <= LIQUIDITY_MINT_CAP, "mint limit exceeded");
    liquidityMinted = liquidityMinted.add(_amount);
    mint(_to, _amount);
  }

  function mintForInvestor(address _to, uint256 _amount) public onlyOwner {
    require(investorMinted.add(_amount) <= INVESTOR_MINT_CAP, "mint limit exceeded");
    investorMinted = investorMinted.add(_amount);
    mint(_to, _amount);
  }


  function mintForEcosystem(address _to, uint256 _amount) public onlyOwner {
    require(ecosystemMinted.add(_amount) <= ECOSYSTEM_VESTING_AMT.add(ECOSYSTEM_TGE_RELEASE), "mint limit exceeded");
    require(_amount <= pendingEcosystemTokens(), "available limit exceeded");
    ecosystemMinted = ecosystemMinted.add(_amount);
    mint(_to, _amount);
  }

  function mintForTeam(address _to, uint256 _amount) public onlyOwner {
    require(teamMinted.add(_amount) <= TEAM_VESTING_AMT.add(TEAM_TGE_RELEASE), "mint limit exceeded");
    require(_amount <= pendingTeamTokens(), "available limit exceeded");
    teamMinted = teamMinted.add(_amount);
    mint(_to, _amount);
  }


  function burn(address _account, uint256 _amount) external onlyOwner {
    _burn(_account, _amount);
    _moveDelegates(_delegates[_account], address(0), _amount);
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(recipient != address(this), "ERC20: transfer to the token contract");

    _transfer(_msgSender(), recipient, amount);
    _moveDelegates(_delegates[_msgSender()], _delegates[recipient], amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(recipient != address(this), "ERC20: transfer to the token contract");

    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
    _moveDelegates(_delegates[sender], _delegates[recipient], amount);
    return true;
  }


  function pendingEcosystemTokens() public view returns (uint256)
  {
    if(block.timestamp < startMiningTimestamp){
      return 0;
    }

    uint256 singlePerSec = ECOSYSTEM_VESTING_AMT.div(ECOSYSTEM_VESTING_PERIOD);

    uint256 timePast = uint256(block.timestamp).sub(startMiningTimestamp);

    if(timePast >= ECOSYSTEM_VESTING_PERIOD){
      return ECOSYSTEM_VESTING_AMT.add(ECOSYSTEM_TGE_RELEASE).sub(ecosystemMinted);
    }

    return timePast.mul(singlePerSec).add(ECOSYSTEM_TGE_RELEASE).sub(ecosystemMinted);
  }


  function pendingTeamTokens() public view returns (uint256)
  {
    if(block.timestamp < startMiningTimestamp){
      return 0;
    }

    uint256 singlePerSec = TEAM_VESTING_AMT.div(TEAM_VESTING_PERIOD);

    uint256 timePast = uint256(block.timestamp).sub(startMiningTimestamp);

    if(timePast >= TEAM_VESTING_PERIOD){
      return TEAM_VESTING_AMT.add(TEAM_TGE_RELEASE).sub(teamMinted);
    }

    return timePast.mul(singlePerSec).add(TEAM_TGE_RELEASE).sub(teamMinted);
  }


  /**
   * Perform adjust on token supply once invoked
   */
  function supplyAdjust() public onlyOwner
  {

    require(block.timestamp >= nextAdjustTimestamp, "SingleToken: not yet");


    if(block.timestamp < launchPeriodEndTimestamp)
    {
      launchPeriodSupplyAdjust();
    }else
    {

      // first halving
      if( (block.timestamp - launchPeriodEndTimestamp) < SUPPLY_HALVING_WINDOW ){
        SUPPLY_PER_BLOCK = INITIAL_SUPPLY_PER_BLOCK.div(2);
      }else{
        // halving
        SUPPLY_PER_BLOCK = SUPPLY_PER_BLOCK.div(2);
      }

      nextAdjustTimestamp = nextAdjustTimestamp.add(SUPPLY_HALVING_WINDOW);

      emit SupplyAdjusted(SUPPLY_PER_BLOCK, nextAdjustTimestamp);

    }

  }


  function launchPeriodSupplyAdjust() internal{

    uint256 N = 6 - (launchPeriodEndTimestamp - block.timestamp).mul(100).div(LAUNCH_PERIOD_ADJUST_WINDOW).div(100);

    // multiplier = ( 32 + p(3.5-N) ) / 32
    // p = 5
    uint256 multiplier = uint256(3200).add(1750).sub(N.mul(500)).mul(1e12).div(3200);

    SUPPLY_PER_BLOCK = INITIAL_SUPPLY_PER_BLOCK.mul(multiplier).div(1e12);

    // advance the next adjust time
    nextAdjustTimestamp = nextAdjustTimestamp.add(LAUNCH_PERIOD_ADJUST_WINDOW);

    emit SupplyAdjusted(SUPPLY_PER_BLOCK, nextAdjustTimestamp);

  }



  // Copied and modified from YAM code:
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
  // Which is copied and modified from COMPOUND:
  // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

  /// @notice A record of each accounts delegate
  mapping (address => address) internal _delegates;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  /// @notice A record of votes checkpoints for each account, by index
  mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping (address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// @notice A record of states for signing / validating signatures
  mapping (address => uint) public nonces;

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

  /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegator The address to get delegatee for
    */
  function delegates(address delegator)
      external
      view
      returns (address)
  {
      return _delegates[delegator];
  }

  /**
  * @notice Delegate votes from `msg.sender` to `delegatee`
  * @param delegatee The address to delegate votes to
  */
  function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
  }

  /**
    * @notice Delegates votes from signatory to `delegatee`
    * @param delegatee The address to delegate votes to
    * @param nonce The contract state required to match the signature
    * @param expiry The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
      external
  {
      bytes32 domainSeparator = keccak256(
          abi.encode(
              DOMAIN_TYPEHASH,
              keccak256(bytes(name())),
              // getChainId(),
              block.chainid,
              address(this)
          )
      );

      bytes32 structHash = keccak256(
          abi.encode(
              DELEGATION_TYPEHASH,
              delegatee,
              nonce,
              expiry
          )
      );

      bytes32 digest = keccak256(
          abi.encodePacked(
              "\x19\x01",
              domainSeparator,
              structHash
          )
      );

      address signatory = ecrecover(digest, v, r, s);
      require(signatory != address(0), "SINGLE::delegateBySig: invalid signature");
      require(nonce == nonces[signatory]++, "SINGLE::delegateBySig: invalid nonce");
      require(block.timestamp <= expiry, "SINGLE::delegateBySig: signature expired");
      return _delegate(signatory, delegatee);
  }

  /**
    * @notice Gets the current votes balance for `account`
    * @param account The address to get votes balance
    * @return The number of current votes for `account`
    */
  function getCurrentVotes(address account)
      external
      view
      returns (uint256)
  {
      uint32 nCheckpoints = numCheckpoints[account];
      return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
    * @notice Determine the prior number of votes for an account as of a block number
    * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    * @param account The address of the account to check
    * @param blockNumber The block number to get the vote balance at
    * @return The number of votes the account had as of the given block
    */
  function getPriorVotes(address account, uint blockNumber)
      external
      view
      returns (uint256)
  {
    require(blockNumber < block.number, "SINGLE::getPriorVotes: not yet determined");

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
        return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
        return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
        return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
        uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
        Checkpoint memory cp = checkpoints[account][center];
        if (cp.fromBlock == blockNumber) {
            return cp.votes;
        } else if (cp.fromBlock < blockNumber) {
            lower = center;
        } else {
            upper = center - 1;
        }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee)
      internal
  {
    address currentDelegate = _delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator); // balance of underlying YAMs (not scaled);
    _delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        // decrease old representative
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint256 srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        // increase new representative
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint256 dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint256 oldVotes,
    uint256 newVotes
  ) internal
  {
    uint32 blockNumber = safe32(block.number, "SINGLE::_writeCheckpoint: block number exceeds 32 bits");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
        checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
        checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
        numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }


}



interface IAccountant {
  function withdrawToProtocol(address token, uint256 amount, uint256 singleAmtMin) external returns(uint256 protocolAmount);

  function withdrawToBurn(address token,uint256 amount, uint256 singleAmtMin) external returns(uint256 burnAmount);
  
  function deposit(address token, uint16 treasuryBps, uint16 protocolBps, uint256 totalAmount) external;
}



interface ILocker {
    function lock(address _user, uint256 _amount, uint256 pid) external;
    function pendingTokens(uint256 pid, address user) external returns (uint256);
    function release(uint256 pid, address user) external;
}



pragma experimental ABIEncoderV2;


/**
 * Distribute SINGLE by staking ERC20 based tokens
 */
contract BigBang is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many Staking tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    address fundedBy; // Funded by who?
  }

  // Info of each pool.
  struct PoolInfo {
    uint256 allocPoint; // How many allocation points assigned to this pool. SINGLEs to distribute per block.
    uint256 lastRewardBlock; // Last block number that SINGLEs distribution occurs.
    uint256 accRewardPerShare; // Accumulated SINGLEs per share, times 1e12. See below.
  }

  // The reward token
  SingleToken public single;
  // Dev address.
  address public devaddr;
  // SINGLE tokens created per block.
  uint256 public singlePerBlock;


  /// @notice The SINGLE ERC-20 contract.
  IERC20 public SINGLE;

  /// @notice Info of each pool.
  PoolInfo[] public poolInfo;
  /// @notice Address of the ERC-20 for each Pool.
  IERC20[] public stakeTokens;
  /// @notice Address of each `ILockers` contract.
  ILocker public locker;
  IAccountant public accountant;
  

  /// @notice Info of each user that stakes tokens.
  mapping (uint256 => mapping (address => UserInfo)) public userInfo;
  /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;

  uint256 private constant ACC_SINGLE_PRECISION = 1e12;

  // always the first vault to be deployed
  uint8 public constant IBSINGLE_POOL_ID = 1;
  mapping (address => bool ) public whitelistedFunders;

  // Bonus single during bonus period.
  uint256 public bonusSinglePerBlock;
  // Block number when bonus SINGLE period ends.
  uint256 public bonusEndBlock;
  // Block number when bonus SINGLE period starts.
  uint256 public bonusStartBlock;


  event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
  event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
  event LogSetPool(uint256 indexed pid, uint256 allocPoint);
  event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accRewardPerShare);
  event RewardProtocol(uint256 rewardTotal, uint256 extraPerShare);
  event SetBonus( uint256 extraRewardPerBlock, uint256 bonusStartBlock, uint256 bonusEndBlock);
  event LogUpdatePoolBonus(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accRewardPerShare);
  event BuyBack(uint256 accRewardPerShare);
  event LogInit();
  

  constructor(
    SingleToken _single,
    address _devaddr
  ) {
    totalAllocPoint = 0;
    single = _single;
    SINGLE = IERC20(address(_single));
    devaddr = _devaddr;
    singlePerBlock = single.SUPPLY_PER_BLOCK();

    emit LogInit();
  }


  // Update dev address by the previous dev.
  function setDev(address _devaddr) public {
    require(msg.sender == devaddr, "dev: not owner?");
    devaddr = _devaddr;
  }


  // control the mining rate of reward tokens
  // only can invoked at the time of supply halving
  function updateSinglePerBlock() external onlyOwner {
    single.supplyAdjust();
    singlePerBlock = single.SUPPLY_PER_BLOCK();
  }


  /// @notice Returns the number of pools.
  function poolLength() public view returns (uint256) {
    return poolInfo.length;
  }

  function manualBurn(uint256 _amount) external {
    require (msg.sender == address(accountant), "accountant only"); 
    IERC20(SINGLE).safeTransferFrom(msg.sender, address(this), _amount);
    single.burn(address(this), _amount);
  }

  function mintForLiquidity(address _to, uint256 _amount) public onlyOwner {
    single.mintForLiquidity(_to, _amount);
  }

  function mintForEcosystem(address _to, uint256 _amount) public onlyOwner {
    single.mintForEcosystem(_to, _amount);
  }

  function mintForTeam(address _to, uint256 _amount) public onlyOwner {
    single.mintForTeam(_to, _amount);
  }
  

  /**
   * Mint SINGLE tokens and lock for a period of time
   * @param pid Locker pool id
   */
  function mintForInvestor(uint256 pid, address _for, uint256 _amount) public onlyOwner {
    // mint SINGLE from the investor pool
    single.mintForInvestor(address(this), _amount);
    require(address(locker) != address(0), "!locker");
    SINGLE.safeApprove(address(locker),_amount);
    // locker handle the lock and vesting
    locker.lock(_for, _amount, pid);
  }


  /// @notice Returns if stakeToken is duplicated
  function isDuplicatedPool(IERC20 _stakeToken) public view returns (bool) {
    uint256 length = poolInfo.length;
    for(uint256 _pid = 0; _pid < length; _pid++) {
      if(stakeTokens[_pid] == _stakeToken) return true;
    }
    return false;
  }

  function setLocker (address _locker) external onlyOwner {
    require(address(locker) == address(0),"once only");
    locker = ILocker (_locker);
  }


  /// @notice Add a new lp to the pool. Can only be called by the owner.
  
  /// @param allocPoint AP of the new pool
  /// @param _stakeToken address of the LP token
  function addPool(
      uint256 allocPoint, 
      IERC20 _stakeToken, 
      uint256 _startBlock,
      bool _withUpdate
  ) external onlyOwner {
    
    require(!isDuplicatedPool(_stakeToken), "BigBang::addPool:: stakeToken dup");
    
    if (_withUpdate) {
      updateAllPools();
    }
    
    uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
    totalAllocPoint = totalAllocPoint.add(allocPoint);

    stakeTokens.push(_stakeToken);
    
    poolInfo.push(PoolInfo({
      allocPoint: allocPoint,
      lastRewardBlock: lastRewardBlock,
      accRewardPerShare: 0
    }));

    emit LogPoolAddition(stakeTokens.length.sub(1), allocPoint, _stakeToken);
  }


  /// @notice Update the given pool's SINGLE allocation point. Can only be called by the owner.
  
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _allocPoint new AP of the pool
  function setPool(
    uint256 _pid, 
    uint256 _allocPoint,
    bool _withUpdate
  ) external onlyOwner {
    if(_withUpdate) {
      updateAllPools();
    }
    
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    poolInfo[_pid].allocPoint = _allocPoint;
    
    emit LogSetPool(_pid, _allocPoint);
  }

  /// @notice Update reward variables for all pools. Be careful of gas spending!
  function updateAllPools() public {
    uint256 len = poolLength();
    for (uint256 i = 0; i < len; ++i) {
      updatePool(i);
    }
  }

  function setBonus(
    uint256 _extraRewardPerBlock,
    uint256 _numberOfBlocks
    // bool _withUpdate
    // uint256 _bonusLockUpBps
  ) external onlyOwner {
    require(_numberOfBlocks > 0, "setBonus: bad bonusEndBlock");
    require(_extraRewardPerBlock > 0, "setBonus: bad extraReward");
    require(bonusEndBlock < block.number, "setBonus: bonus round not ended");
    
    // if(_withUpdate) {
    //   updateAllPools();
    // }

    bonusSinglePerBlock = _extraRewardPerBlock;
    bonusStartBlock = block.number;
    bonusEndBlock = block.number.add(_numberOfBlocks);
    SINGLE.safeTransferFrom(msg.sender, address(this), bonusSinglePerBlock.mul(_numberOfBlocks));
    
    emit SetBonus(_extraRewardPerBlock, bonusStartBlock, bonusEndBlock);
  }


  /// @notice Update reward variables of the given pool.
  /// @param pid The index of the pool. See `poolInfo`.
  function updatePool(uint256 pid) public {
    PoolInfo storage pool = poolInfo[pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 stakeTokenSupply = stakeTokens[pid].balanceOf(address(this));
    if (stakeTokenSupply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 lastRewardBlock = pool.lastRewardBlock;
    uint256 multiplier = block.number.sub(lastRewardBlock);
    pool.lastRewardBlock = block.number;
    
    
    
    // uint256 multiplier = blocks;
    uint256 singleReward = totalAllocPoint > 0? multiplier.mul(singlePerBlock).mul(pool.allocPoint).div(totalAllocPoint) : 0;
    
    // prevent minting rewards if the reserve is depleted
    if( single.totalSupply().add(singleReward).add(singleReward.div(10)) < single.cap() ){
      pool.accRewardPerShare = pool.accRewardPerShare.add( singleReward.mul(ACC_SINGLE_PRECISION).div(stakeTokenSupply) );
      // pool.lastRewardBlock = block.number;
      single.mint(devaddr, singleReward.div(10));
      single.mint(address(this), singleReward);
      
      emit LogUpdatePool(pid, pool.lastRewardBlock, stakeTokenSupply, pool.accRewardPerShare);
    }

    //if bonus tokens are rewarded.
    uint256 bonusReward;
    uint256 bonusEndRange = bonusEndBlock > block.number? block.number : bonusEndBlock;
    uint256 bonusStartRange = lastRewardBlock > bonusStartBlock? lastRewardBlock : bonusStartBlock;
    if (bonusEndRange > bonusStartRange){
      bonusReward = totalAllocPoint > 0? (bonusEndRange.sub(bonusStartRange)).mul(bonusSinglePerBlock).mul(pool.allocPoint).div(totalAllocPoint): 0;
    }

    if (bonusReward > 0) {
      pool.accRewardPerShare = pool.accRewardPerShare.add( bonusReward.mul(ACC_SINGLE_PRECISION).div(stakeTokenSupply) );
      emit LogUpdatePoolBonus(pid, pool.lastRewardBlock, stakeTokenSupply, pool.accRewardPerShare);
    }
      

  }



  /**
      ██     ██  ██████  ██████  ██   ██ 
      ██     ██ ██    ██ ██   ██ ██  ██  
      ██  █  ██ ██    ██ ██████  █████   
      ██ ███ ██ ██    ██ ██   ██ ██  ██  
      ███ ███   ██████  ██   ██ ██   ██ 
  */


  /// @notice Deposit tokens for SINGLE allocation.
  /// @param _for The address that will get yield
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount to deposit.
  function deposit(address _for, uint256 pid, uint256 amount) external nonReentrant {
    if(!whitelistedFunders[msg.sender]){
      require(_for == msg.sender, "EOA cannot deposit for others");
    } 
    _deposit(_for, pid, amount);
    
  }

  

  function _deposit(address _for, uint256 pid, uint amount) internal {
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][_for];
    if (user.fundedBy != address(0)) require(user.fundedBy == msg.sender, "bad sof");
    require(address(stakeTokens[pid]) != address(0), "deposit: not accept deposit");
    updatePool(pid);
    if (user.amount > 0) _harvest(_for, pid);
    if (user.fundedBy == address(0)) user.fundedBy = msg.sender;
    stakeTokens[pid].safeTransferFrom(address(msg.sender), address(this), amount);
    user.amount = user.amount.add(amount);
    user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(ACC_SINGLE_PRECISION);

    emit Deposit(msg.sender, pid, amount, _for);
  }

  
  /// @notice Withdraw tokens from the distribution pool
  /// @param _for Receiver of yield
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount of lp tokens to withdraw.
  function withdraw(address _for, uint256 pid, uint256 amount) external nonReentrant {

    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][_for];
    require(user.fundedBy == msg.sender, "only funder");
    require(user.amount >= amount, "withdraw: not good");
    updatePool(pid);
    _harvest(_for, pid);
    user.amount = user.amount.sub(amount);
    user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
    if (user.amount == 0) user.fundedBy = address(0);
    
    stakeTokens[pid].safeTransfer(address(msg.sender), amount);

    emit Withdraw(msg.sender, pid, user.amount, _for);
  }


  // Harvest SINGLEs earn from the pool.
  function harvest(uint256 _pid) external nonReentrant {
    // console.log("harvesting", block.number);
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);
    _harvest(msg.sender, _pid);
    user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(ACC_SINGLE_PRECISION);
  }


  /// @notice Harvest proceeds for transaction sender to `to`.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param to Receiver of SINGLE rewards.
  function _harvest(address to, uint256 pid) internal {
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][to];

    if(user.amount > 0){
      uint256 pending = user.amount.mul(pool.accRewardPerShare).div(ACC_SINGLE_PRECISION).sub(user.rewardDebt);
      require(pending <= single.balanceOf(address(this)), "wtf not enough SINGLE");
      SINGLE.safeTransfer(to, pending);

      emit Harvest(to, pid, pending);
    }
  }


  /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param to Receiver of the staking tokens.
  function emergencyWithdraw(uint256 pid, address to) external nonReentrant {
    UserInfo storage user = userInfo[pid][msg.sender];
    require(user.fundedBy == msg.sender, "BigBang::emergencyWithdraw:: only funder");
    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;
    user.fundedBy = address(0);
    // Note: transfer can fail or succeed if `amount` is zero.
    stakeTokens[pid].safeTransfer(to, amount);
    emit EmergencyWithdraw(msg.sender, pid, amount, to);
  }



  /// @notice View function to see pending SINGLEs on frontend.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _user address of user
  function pendingSingle(uint256 _pid, address _user) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accRewardPerShare = pool.accRewardPerShare;
    uint256 stakeTokenSupply = stakeTokens[_pid].balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && stakeTokenSupply != 0) {
      // uint256 blocks = block.number.sub(pool.lastRewardBlock);
      uint256 multiplier = block.number.sub(pool.lastRewardBlock);
      uint256 singleReward = totalAllocPoint > 0? multiplier.mul(singlePerBlock).mul(pool.allocPoint).div(totalAllocPoint) : 0;
    //   accRewardPerShare = accRewardPerShare.add(singleReward.mul(ACC_SINGLE_PRECISION).div(stakeTokenSupply));
      uint256 bonusReward;
      if (block.number <= bonusEndBlock) {
        bonusReward = totalAllocPoint > 0? multiplier.mul(bonusSinglePerBlock).mul(pool.allocPoint).div(totalAllocPoint): 0;
      }else if(block.number > bonusEndBlock && pool.lastRewardBlock < bonusEndBlock) {
        bonusReward = totalAllocPoint > 0? bonusEndBlock.sub(pool.lastRewardBlock).mul(bonusSinglePerBlock).mul(pool.allocPoint).div(totalAllocPoint) : 0;
      }
    
      accRewardPerShare = accRewardPerShare.add((singleReward.add(bonusReward)).mul(ACC_SINGLE_PRECISION).div(stakeTokenSupply));
    }
    
    return user.amount.mul(accRewardPerShare).div(ACC_SINGLE_PRECISION).sub(user.rewardDebt);
  }


  function setAccountant (address payable _accountant) external onlyOwner {
    accountant = IAccountant(_accountant);
  }

  function setWhitelistedFunders(address[] calldata funders, bool status) external onlyOwner {
    for (uint256 i = 0; i <  funders.length; i++) {
      whitelistedFunders[funders[i]] = status;
    }
  }

  function rewardProtocol(address token, uint256 amount, uint256 returnAmtMin) external {
    require( msg.sender == devaddr, "not dev");
    require(IERC20(stakeTokens[IBSINGLE_POOL_ID]).balanceOf(address(this)) > 0,"no staking amount" );
    
    // perform buyback and compute the total SINGLE
    uint256 back = accountant.withdrawToProtocol(token, amount, returnAmtMin);

    // burn portion of the SINGLE
    // uint256 burn = back.mul(accountant.burnBps()).div(10000);
    // back = back.sub(burn);
    // single.burn(address(this), burn);
    require(IERC20(SINGLE).balanceOf(address(this)) >= back, "wtf? not enough single");
    uint256 extraPerShare = back.mul(ACC_SINGLE_PRECISION).div(IERC20(stakeTokens[IBSINGLE_POOL_ID]).balanceOf(address(this)));
    // deposit into protocol profit
    poolInfo[IBSINGLE_POOL_ID].accRewardPerShare = poolInfo[IBSINGLE_POOL_ID].accRewardPerShare
      .add(extraPerShare);

    emit RewardProtocol(back, extraPerShare);
  }

  function buyBackAndBurn(address token, uint256 amount,  uint256 returnAmtMin) external {
    require( msg.sender == devaddr, "not dev");
    
    single.burn(address(this), accountant.withdrawToBurn(token, amount, returnAmtMin));
    
  }

}