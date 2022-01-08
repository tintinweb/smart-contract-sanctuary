/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====z
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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

pragma solidity 0.8.9;

interface IStakePool {

    function tierCount() external view returns (uint8);

    function poolInfo(uint pid)
    external view returns (
        uint unitAmount,
        uint allocPoint,
        uint lockDuration,
        uint totalSupply
    );
    function balanceOf(address user) external view  returns (uint);
    
    function totalAllocPoint() external view returns (uint);

    function allocPointsOf(address _sender)  external view returns(uint); 
    function allocPercentageOf(address _sender)  external view returns(uint); 
    
}
/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


/** 
    @title AtpadPresale 
    @notice This is a Natspec commented contract by AtomPad Development Team
    @notice Version v1.1.0  date: jan 06, 2022
*/

/// @author AtomPad Dev Team
/// @author JaWsome Orbit 
/// @author Ruwaifa Tahir

/** @notice What is AtpadPresale
    PresaleTest provides launch system for an ido. build from scratch 28.09.2021 by AtomPad Dev Team for a basic understanding 
    AtpadPresale is a major update on 06.01.22
    This contract works in conjunction with StakePool.sol 
    This contract is inherited by PresaleTestFees.sol
*/

/** @notice How the contract works
    stakepool.sol is up and running and accounts stake the stakeTokens they are holding
    admin sets hardcap (investToken) and deposits tokens (wantToken) 
    the calculation tokenSupply / hardcap gives the amount of tokens a user gets per investment
    stakePool.sol provides allocPerc, this is the percentage allocation a user holds. 
    this contract does not bother how allocPerc is determined.
    allocPerc is a relative value and has to be divide by 10**6 to get the absoolute %. 
    in other words.... (100% = 1000 000 allocPerc points)
    
    if a user connects once the presale hast started.. the allocation how many investToken a user can spend is calculated.
    also the amount of wantToken a user will receive is based on the same calculation
    example: 
    if the hardcap is 50, the tokenSupply is 10 000 and the allocPerc for userA is 10 000 then 
    userA has the allocation  for 1% in this presale , this is 0.5 investToken.
    userA will receive 100 tokens if the maximum allocation is swapped

    if a user does not connect between startTime and endTime, the reserved allocation will be lost. 
    if a user allocates but does not swap the allocated invesTokens, the reserved allocation will be lost.

    Version 1.1 has completely changed the vesting of claims
    new  vesting variables
    uint initialVestPercentage;  use 100 for NO VESTING
    
    ///  Epoch timestamps START and END vesting 
    uint startVest;
    uint endVest;
       
    initialVestPercentage = 50
    startVest = 1643716800;  //  Epoch timestamp:  Date and time (GMT): Tuesday 1 February 2022 12:00:00
    endVest = 1669896000;  // Epoch timestamp:  Date and time (GMT): Thursday 1 December 2022 12:00:00


/** @dev Contract status
    statusnumbers will implemented in future versions of PresaleTest
    0 reset              -->    waiting for admin to set start variables
                                user : stake
    
    1 deployed           -->    waiting for admin to deposit tokens
                                user : stake
    
    2 tokens deposited   -->    waiting for timer to pass startTime
                                user : stake
    
    3 presale started    -->    waiting for timer to pass endTime
                                user : userConnect
                                user : allocate + swap
    4 presale ended      -->    waiting for  create claims
                                user : 

    5 claim no vesting   -->    waiting for user to  claims tokens
                                user : claim
    
    6 claim vesting      -->    waiting for user to claim tokens
                                user : claim
          
    7 retain tokens      -->    waiting admin to return tokens
                                user : 
         
    8 idle               -->    waiting admin to reset
                                user : 
*/

contract AtpadPresale is ReentrancyGuard, Ownable, Pausable {

    /** @dev libraries
        @dev ReentrancyGuard 
            Helps to prevent reentrant calls to a function.
            Inheriting from ReentrancyGuard will make the nonReentrant modifier available, which can be applied to functions to make sure there are no nested (reentrant) calls to them.
            Note that because there is a single nonReentrant guard, functions marked as nonReentrant may not call one another. This can be worked around by making those functions private, and then adding external nonReentrant entry points to them.

        @dev Ownable 
            Provides a basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.
            By default, the owner account will be the one that deploys the contract. This can later be changed with transferOwnership.
            This module is used through inheritance. It will make available the modifier onlyOwner, which can be applied to your functions to restrict their use to the owner.

        @dev Pausable 
            This is an emergency stop mechanism that can be triggered by an authorized account.
            This module is used through inheritance. It will make available the modifiers whenNotPaused and whenPaused, which can be applied to the functions of your contract. 
            Note that they will not be pausable by simply including this module, only once the modifiers are put in place.
        
        @dev IERC20 
            Interface of the ERC20 standard as defined in the EIP. Does not include the optional functions; to access them see ERC20Detailed.
            totalSupply()
            balanceOf(account)
            transfer(recipient, amount)
            allowance(owner, spender)
            approve(spender, amount)
            transferFrom(sender, recipient, amount)

        @dev SafeERC20 
            Wraps around ERC20 operations that throw on failure (when the token contract returns false). 
            Tokens that return no value (and instead revert or throw on failure) are also supported, non-reverting calls are assumed to be successful. 

        @dev SafeMath 
            Provides mathematical functions that protect your contract from overflows and underflows.
            Include the contract with using SafeMath for uint256; and then call the functions:
            myNumber.add(otherNumber)    myNumber.sub(otherNumber)   myNumber.div(otherNumber)
            myNumber.mul(otherNumber)    myNumber.mod(otherNumber)
            late note J.Orbit: SafeMath may be obsolete pragma : 0.8.9

        @dev EnumerableMap
            This is like mapping type, but with key-value enumeration: 
            informs how many entries a mapping has, and iterate over them (which is not possible with mapping).
            EnumerableSet: like EnumerableMap, but for sets. Can be used to store privileged accounts, issued IDs, etc.
    */

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /// @dev modifiers
    modifier whenNotStarted {
        require(block.timestamp < startTime, "presale has already started");
        _;
    }

    modifier onProgress {
        require(block.timestamp < endTime && block.timestamp >= startTime, "presale not in progress");
        _;
    }

    modifier whenFinished {
        require(block.timestamp > endTime, "presale is not finished");
        _;
    }

    modifier whenNotFinished {
        require(block.timestamp <= endTime, "presale is finished");
        _;
    }
  
    modifier whiteListed {
        require(whiteList[msg.sender] == true || msg.sender == owner(), "not whiteListed");
        _;
    }

    modifier claimDisabled {
        require(claimOn == false , "Claiming is  active!");
        _;
    }
    
    /// @dev variables
    /// participants
    //EnumerableSet.AddressSet private _participants;

    /// rate = wantToken per investToken
    uint public rate; 

    /// supply of wantToken
    uint public tokenSupply;

    /// redundant?
    /// address public keeper;

    /// calling parameters
    IERC20 public wantToken;
    IERC20 public investToken;
    uint public startTime;
    uint public endTime;
    uint public hardCap;
    uint public softCap;
    IStakePool public stakePool;

    /// @dev struct Allocation
    struct Allocation {
        address adres;
        uint allocated;     
        uint swapped;       
    }

    /// wantToken absolutes
    /// claims also designed for vesting

    /// @dev maps + array to controll the process   
    mapping(address=> uint) public allocations;     // absolute amount of allocated investToken per user
    mapping(address=> uint) public swaps;           // absolute amount of swapped investToken per user


    // * NEW v1.1
    /// @dev struct Claim 
    mapping(address => Claim) claims;      // records of claims wantToken 

    struct Claim {
        uint reserved;     // amount of bought wantToken
    //    uint released;     // amount of released wantToken, increases over time 
        uint claimed;      // amount of claimed wantToken, increases after claiming. 
    }

    /// initial percentage vesting, release after launch
    /// use 100 for NO VESTING
    uint initialVestPercentage;

    ///  Epoch timestamps START and END vesting 
    uint startVest;
    uint endVest;


    address[] public userAdresses;  // array of users holding allocation

    /// @dev maps to support the process
    mapping(address => bool) whiteList;
    /// mapping(address => bool) blackList;

    /// counter to measure traffic 
    uint256 counter;
    /// status step of the contract - unused
    /// uint256 status;

    /// @dev control buttons for the admin
    bool public swapOn;   // set by owner, turns off/on swap process
    bool public claimOn;  // set by owner, turns off/on claim process


    /// @dev totalizer to follow the process by admin / frontEnd
    uint public allocateTotal;  // absolute total allocated investToken
    uint public swapTotal;      // absolute total swapped investToken
    uint public pendingTotal;   // absolute total swapped wantToken 
    uint public claimedTotal;   // absolute total claimed wantToken

    /// @dev events
    event Deposited(address indexed user, uint amount);
    event Swapped(address indexed user, uint amount);
    event Claimed(address indexed user, uint amount);

    uint8 decimals = 1;

    /// @dev constructor
    /// @param _wantToken the token that is to be distributed
    /// @param _investToken the token to pay with 
    /// @param _startTime the starting time of the sale in Unix timestamp seconds
    /// @param _duration the duration of the sale in seconds
    /// @param _hardCap hardcap is the cap this presale calculates the user allocations from 
    /// @param _softCap not used in this presale
    /// @param _stakePool the address account should put their stakeToken to participate in the sale


    /// @dev vesting variables

    constructor ( address _wantToken, address _investToken, uint _startTime, uint _duration, uint _hardCap, uint _softCap, address _stakePool
    ) {
        require(_hardCap >= _softCap, "invalid caps");
        require(_duration > 0, "invalid duration");

        wantToken = IERC20(_wantToken);
        investToken = IERC20(_investToken);
        startTime = _startTime;
        endTime = _startTime.add(_duration);
        hardCap = _hardCap;
        softCap = _softCap;
        stakePool = IStakePool(_stakePool);

        whiteList[msg.sender] = true;
        claimOn = false;
        swapOn = false;
        // tokenSupply =0 ;
        // rate = 1;

        // allocateTotal=0;
        // swapTotal=0;
        // pendingTotal;
        // claimedTotal=0;  

        // counter = 0 ;

        /// vesting variables
        initialVestPercentage = 50;
        startVest = 1643716800;  //  Epoch timestamp:  Date and time (GMT): Tuesday 1 February 2022 12:00:00
        endVest = 1669896000;  // Epoch timestamp:  Date and time (GMT): Thursday 1 December 2022 12:00:00

    }


    /// @param _amount the amount of tokens to depoosit for the sale
    /// @notice admin to deposit the wantTokens
    function depositTokens(uint _amount) external payable onlyOwner claimDisabled whenNotStarted { 
        /// do some checks 
        require(wantToken.balanceOf(msg.sender) >= _amount, "!amount");
        /// @dev set minimum amount of tokens for this presale
        require(_amount >= (10 *10**decimals) , "min amount is 10 tokens");
        /// transfer x amount of wantToken to presale
        wantToken.safeTransferFrom(msg.sender, address(this), _amount);

        tokenSupply = _amount;

        rate = (tokenSupply / hardCap);

        emit Deposited(msg.sender, _amount);
    }

    /// @dev function called by user : msg.sender 
    /** @dev 
    /// @notice user connecting during presale creates allocation
     *  if a user connects the allocation is calcualted
     *  maps allocations and swaps are initiated with this users address
     */
    function userConnect() external nonReentrant claimDisabled onProgress{    //
        counter++;

        /// check if user is not blacklisted ! ==> map whitelist
        /// check if user is in the system !  ==>  is not in (map allocations)

        /// check if this is a new user
       if  (_checkOrAddUser(msg.sender)){
            /// this is a new user
            uint _perc = getAllocPercentage(msg.sender);
            /// if user has tier ::: if the user has allocPercentage()
            if (_perc > 0) {
                 /// allocation is percentage of hardcap

                uint _allocate = (hardCap * _perc) ; // FOR TESTING PURPOSE !
//                uint _allocate = (hardCap * _perc)*10**12 ; // we already did (10**6) in stakePool while creating AllocPerc

                /// fill record in map allocations
                allocations[msg.sender] = _allocate ;

                /// add allocateTotal (totalizer)
                allocateTotal += _allocate;

                /// reset swaps map
                swaps[msg.sender] = 0 ;

                /// reset claims map
                // Claim memory _claim;
                // _claim = Claim(0, 0);
                // claims[msg.sender] = _claim;
            }
       }
    }


    /// @dev function called by user : msg.sender 
    /// @param _amount the amount of tokens to depoosit for the sale
    /// @notice user to deposit the investTokens during the presale
    function swap(uint _amount) external payable nonReentrant claimDisabled onProgress { // 
        /// do some checks 
        require(allocations[msg.sender] >= _amount, "!no allocation");

        /// transfer tokens to this stakePool
        investToken.transferFrom(msg.sender, address(this), _amount);

        /// sum swaps
        swaps[msg.sender] += _amount; 

        /// deduct allocation
        allocations[msg.sender] -= _amount; 

        /// sum totalizer swapTotal
        swapTotal += _amount; 

        /// do not deduct totalizer allocateTotal
        /// allocateTotal -= amount;

        /// do some other things

        // reserve claims;
        claims[msg.sender].reserved = swaps[msg.sender] * rate;

        emit Swapped(msg.sender, _amount);
    }



    /// @param msg.sender
    /// @notice admin can forward the sold investTokens to the admin wallet
    /** @dev forwardInvestTokens
     *  to be excecuted after the presale by the admin in order to receive
     *  the invested tokens
     */
    function forwardInvestTokens() external onlyOwner whenFinished { // 
        /// do some checks 
        require (investToken.balanceOf(address(this))> 0,'!Amount');

        uint _invested = investToken.balanceOf(address(this));

        investToken.safeTransfer(msg.sender, _invested);
    }

    /// @param msg.sender
    /** @dev returnWantTokens
    /// @notice admin can return the unsold tokens
     *  to be excecuted after the presale by the admin in order to receive
     *  the remaining tokens that have not been sold. 
     *  be careful.!!  once initiated this will leave the remaining claims with zero tokens left.
     */
    function returnWantTokens() external onlyOwner whenFinished { // 
        // do some checks 
        require (wantToken.balanceOf(address(this))> 0,'!Amount');

        uint _remaining = wantToken.balanceOf(address(this));

        wantToken.safeTransfer(msg.sender, _remaining);
    }

    /// @param msg.sender
    /** @dev resetContract
    /// @notice admin can reset the contract to default
     *  to be excecuted after the presale by the admin in order to reset 
     *  the contract to default values and try to presale again 
     *  be careful.!!  this is an experimental function!
     */
    function resetContract() external onlyOwner  { // 
        // do some checks 
        startTime = block.timestamp ;
        endTime = startTime.add(3600);

        claimOn = false;
        swapOn = false;
        tokenSupply =0;

        allocateTotal=0;
        swapTotal=0;
        pendingTotal;
        claimedTotal=0;  
        counter = 0 ;

        /// @dev delete the indexArray holding users 
        delete userAdresses;
        /// @dev will reinitiate because index has gone, see _checkOrAddUser for more
        /// @dev experimental !!
        /// mapping(address=> uint) public allocations;    
        /// mapping(address=> uint) public swaps;          
        /// mapping(address => mapping(uint256 => Claim)) claims;     
    }

    /// @param msg.sender
    /// @notice user can receive the wantTokens
    /** @dev swapClaim
     *  to be excecuted after the presale by the user in order to have
     *  the tokens delivered to their personal wallet 
     */
    function swapClaim()  external payable nonReentrant whenFinished {   //
        
        /// do some checks 
        /// calculate the percentage vesting released
        uint _free = getReleasedPercentage();

        /// calculate the claims released
        uint _released = (claims[msg.sender].reserved * _free).div(100);

        /// check if the released > claimed
        require( claims[msg.sender].claimed < _released, '!nothing to claim');
        
        /// calculate the amount to be claimed
        uint _amount =  _released - claims[msg.sender].claimed;

        /// sum totalizer claimedTotal
        claimedTotal+= _amount;

        // set the field claims.claimed
        claims[msg.sender].claimed += _amount;

        // transfer tokens to the investor
        wantToken.safeTransfer(msg.sender, _amount);

        // do some other things
        //  !! 
        emit Claimed(msg.sender, _amount);
    }

    /// @dev  subroutines
    /// @notice uppdate or insert the userArrray
    function _checkOrAddUser(address _user) internal returns (bool) {
        bool _new = true;
        for(uint i = 0 ; i < userAdresses.length ; i++) {
            if (userAdresses[i] == _user) {
                _new = false;
                i = userAdresses.length ;
            }
        }
        if (_new){
            userAdresses.push(_user);
        }
        return _new;
    }


    /// @dev getters 
    function getReleasedPercentage() view public returns (uint) {
        /// calculate the remainder after setting initial_percentage
        uint _remain = 100 - initialVestPercentage;

        /// calculate the total time of vesting
        uint _vestTime = endVest - startVest;

        /// calculate the elapsed time 
        uint _elapsedVestTime = 0;
        if (block.timestamp > startVest) _elapsedVestTime = block.timestamp - startVest;

        /// calculate remain time has elapsed
        uint _remainElapsed = 0;
        if (_vestTime > 0) _remainElapsed = ( (_elapsedVestTime * 100) / _vestTime ); 

        /// now calculate remaining percentage with elapsed vesting time
        uint _remainVestPercentage = (_remainElapsed * _remain) / 100;

        // return initial + remaining elapsed
        return initialVestPercentage + _remainVestPercentage  ;
    }

    function getUserClaim() view public returns (uint, uint, uint) {

        uint _free = getReleasedPercentage();

        uint _released = (claims[msg.sender].reserved * _free).div(100);

        /**  retrieve user claim in format;
            struct Claim {
                uint reserved;     // amount of bought wantToken
                uint claimed;      // amount of claimed wantToken
            }
        */
        return (claims[msg.sender].reserved, _released,claims[msg.sender].claimed);
    }

    /// @dev getters 
    function getUserAllocated() view public returns (uint) {
        /// retrieve absolute amount of allocated investToken for this user;
       return allocations[msg.sender];
    }

    function getUserSwapped() view public returns (uint) {
        /// retrieve absolute amount of allocated investToken for this user;
       return swaps[msg.sender];
    }

    function getTotalAllocPoint() view public returns (uint) {
        /// retrieve totalAllocPoint() from StakePool.sol
       return stakePool.totalAllocPoint();
    }

    function getUserLength() view public returns (uint) {
        /// get the number of users participating
       return userAdresses.length;
    }

    function getAllocPoint(address _sender) view public returns (uint) {
        /// retrieve allocPoint() from StakePool.sol
       return stakePool.allocPointsOf(_sender);
    }

    function getAllocPercentage(address _sender) view public returns (uint) {
        /// retrieve allocPercentage() from StakePool.sol
       return stakePool.allocPercentageOf(_sender);
    }

    /// @dev setters
    function setEnableSwap(bool _flag) external onlyOwner onProgress {
        // do some checks 
        swapOn = _flag;
    }

    function setEnableClaim(bool _flag) external onlyOwner whenFinished {
        // do some checks 
        claimOn = _flag;
    }

    function setStartTime(uint _startTime, uint _duration) external onlyOwner {
        startTime = _startTime;
        endTime = _startTime.add(_duration);
    }

    function setHardCap(uint _cap) external onlyOwner whenNotStarted {
        require(_cap > softCap, "invalid soft cap");
        hardCap = _cap;
    }

    function setSoftCap(uint _cap) external onlyOwner whenNotStarted {
        require(_cap < hardCap, "invalid soft cap");
        softCap = _cap;
    }

    function setVest(uint _startVest, uint _endVest) external onlyOwner {
        startVest = _startVest;
        endVest = _endVest;
    }

    function setInitialVestPercentage(uint _initialVestPercentage) external onlyOwner {
        initialVestPercentage = _initialVestPercentage;
    }


}