/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


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

// File: contracts/vesting/ExenoTokenVesting.sol


pragma solidity ^0.8.4;





/**
 * @title ExenoTokenVesting
 * @notice Allows a token holder to release their token balance gradually
 */
contract ExenoTokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Released(uint256 amount);

    /**
     * @notice Beneficiary of tokens after they are released
     */
    address public beneficiary;

    /**
     * @notice When the vesting period starts
     */
    uint256 public start;

    /**
     * @notice When tokens begin to be available for release
     */
    uint256 public cliff;
    
    /**
     * @notice Duration in seconds of the period in which the tokens will vest
     */
    uint256 public duration;

    uint256 internal durationInHours;

    mapping(address => uint256) public released;

    /**
     * @notice Creates a vesting contract that vests its balance of any ERC20 token to the beneficiary, gradually in a linear fashion until start + duration
     * @param beneficiary_ Address of the beneficiary to whom vested tokens are being released
     * @param start_ When the vesting period starts
     * @param cliff_ Duration in seconds of the cliff in which tokens will begin to vest
     * @param duration_ Duration in seconds of the period in which the tokens will vest
     */
    constructor(address beneficiary_, uint256 start_, uint256 cliff_, uint256 duration_)
	{
        require(beneficiary_ != address(0),
            "ExenoTokenVesting: wrong beneficiary address");
        
        require(cliff_ <= duration_,
            "ExenoTokenVesting: cliff must be less than duration");
        
        beneficiary = beneficiary_;
        start = start_;
        cliff = start_.add(cliff_);
        duration = duration_;
        durationInHours = duration_.div(1 hours);
    }

    /**
     * @notice Transfers vested tokens to beneficiary
     * @param token ERC20 token which is being vested
     */
    function release(IERC20 token)
		public
	{
        uint256 amount = releasableAmount(token);
        require(amount > 0,
            "ExenoTokenVesting: nothing can be released");
        released[address(token)] = released[address(token)].add(amount);
        token.safeTransfer(beneficiary, amount);
        emit Released(amount);
    }

    /**
     * @notice Calculates the amount that has already vested but hasn't been released yet
     * @param token ERC20 token which is being vested
     */
    function releasableAmount(IERC20 token)
		public view returns (uint256)
	{
        return vestedAmount(token).sub(released[address(token)]);
    }

    /**
     * @notice Calculates the amount that has already vested
     * @param token ERC20 token which is being vested
     */
    function vestedAmount(IERC20 token)
		public view returns (uint256)
	{
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(released[address(token)]);

        if (block.timestamp < cliff) {
            return 0;
        }
        if (block.timestamp >= start.add(duration)) {
            return totalBalance;
        }

        uint256 ageInHours = block.timestamp.sub(start).div(1 hours);
        return totalBalance.mul(ageInHours).div(durationInHours);
    }
}

// File: contracts/vesting/ExenoTokenVestingPool.sol


pragma solidity ^0.8.4;





/**
 * @title ExenoTokenVestingPool
 * @notice Pool of `ExenoTokenVesting` contracts - each with different vesting conditions
 * Can work in lock-up mode (when cliff == duration) or vesting mode (when cliff < duration)
 * One beneficiary can have multiple vesting contracts
 * @author Based on a vesting pool contract created by Wibson Development Team <[email protected]>
 */
contract ExenoTokenVestingPool is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ERC20 token being held
    IERC20 public token;

    // Maximum amount of tokens to be distributed
    uint256 public totalFunds;

    // Tokens already distributed
    uint256 public distributedTokens;

    // List of beneficiaries added to the pool
    address[] public beneficiaries;

    // Mapping of beneficiary to ExenoTokenVesting contracts addresses
    mapping(address => address[]) private beneficiaryDistributionContracts;

    // Tracks the distribution contracts created by this contract
    mapping(address => bool) private distributionContracts;

    event BeneficiaryAdded(
        address indexed beneficiary,
        address vesting,
        uint256 amount
    );

    modifier validAddress(address a) {
        require(a != address(0),
			"ExenoTokenVestingPool: invalid address");
        require(a != address(this),
			"ExenoTokenVestingPool: invalid address");
        _;
    }

    /**
     * @param token_ Instance of an ERC20 token
     * @param totalFunds_ Maximum amount of tokens to be distributed among beneficiaries
     */
    constructor(IERC20 token_, uint256 totalFunds_)
        validAddress(address(token_))
    {
        require(
            totalFunds_ > 0,
            "ExenoTokenVestingPool: total funds must be non-zero"
        );

        token = token_;
        totalFunds = totalFunds_;
        distributedTokens = 0;
    }

    /**
     * @notice Assigns an `ExenoTokenVesting` contract to a beneficiary
     * @param beneficiary Address of the beneficiary to whom vested tokens are transferred
     * @param start The time at which point vesting starts
     * @param cliff Duration in seconds of the cliff in which tokens will begin to vest
     * @param duration Duration in seconds of the period in which the tokens will vest
     * @param amount Amount of tokens to be released
     * @return Address for the new `ExenoTokenVesting` contract instance
     */
    function addBeneficiary(
        address beneficiary,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 amount
    )
        public onlyOwner validAddress(beneficiary) returns (address)
    {
        require(beneficiary != owner(),
			"ExenoTokenVestingPool: beneficiary cannot be the owner");
        require(amount > 0,
			"ExenoTokenVestingPool: amount needs to be non-zero");
        require(duration >= cliff,
			"ExenoTokenVestingPool: cliff needs to be within duration");

        // Check there are sufficient funds and actual token balance
        require(SafeMath.sub(totalFunds, distributedTokens) >= amount,
			"ExenoTokenVestingPool: the amount of tokens to distribute cannot be more than the total funds");
        require(token.balanceOf(address(this)) >= amount,
			"ExenoTokenVestingPool: the token balance is not enough for this amount");

        if (!beneficiaryExists(beneficiary)) {
            beneficiaries.push(beneficiary);
        }

        // Bookkepping of distributed tokens
        distributedTokens = distributedTokens.add(amount);

        ExenoTokenVesting tokenVesting = new ExenoTokenVesting(
            beneficiary, start, cliff, duration);

        // Bookkeeping of distributions contracts per beneficiary
        beneficiaryDistributionContracts[beneficiary].push(address(tokenVesting));

        distributionContracts[address(tokenVesting)] = true;

        // Assign the tokens to the beneficiary
        token.safeTransfer(address(tokenVesting), amount);

        emit BeneficiaryAdded(beneficiary, address(tokenVesting), amount);
        
        return address(tokenVesting);
    }

    /**
     * @notice Gets an array of all the distribution contracts for a given beneficiary
     * @param beneficiary Address of the beneficiary to whom tokens will be transferred
     * @return List of ExenoTokenVesting addresses
     */
    function getDistributionContracts(address beneficiary)
        public view validAddress(beneficiary) returns (address[] memory)
    {
        return beneficiaryDistributionContracts[beneficiary];
    }

    /**
     * @notice Checks if a beneficiary was added to the pool at least once
     * @param beneficiary Address of the beneficiary to whom tokens will be transferred
     * @return True if beneficiary exists, false otherwise
     */
    function beneficiaryExists(address beneficiary)
        internal view returns (bool)
    {
        return beneficiaryDistributionContracts[beneficiary].length > 0;
    }
}

// File: contracts/crowdsale/ExenoTokenCrowdsale.sol


pragma solidity ^0.8.4;









contract ExenoTokenCrowdsale is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Date when crowdsale starts
    uint256 public startDate;

    // The token being sold
    IERC20 public token;

    // Address where cash is forwarded
    address payable public wallet;

    // How much cash has been raised
    uint256 public cashRaised;

    // How much cash has been forwarded to the wallet
    uint256 public cashForwarded;

    mapping(address => uint256) public tokenPurchases;
    mapping(address => uint256) public tokenPayments;
    mapping(uint256 => address) private beneficiaries;

    uint256 public totalTokensPurchased;
    uint256 public totalBeneficiaries;

    // Crowdsale stages
    enum CrowdsaleStage {Uninitialized, PreICO, ICO, PostICO, DistributionComplete}
    CrowdsaleStage public currentStage;

    // How many tokens a buyer gets per one native token
    uint256 public currentRate;

    uint256 public preIcoRate;
    uint256 public icoRate;

    ExenoTokenVesting private foundation1Vesting;
    ExenoTokenVesting private foundation2Vesting;
    ExenoTokenVesting private coreVesting;
    ExenoTokenVestingPool private crowdsaleVestingPool;

    address public liquidityAndMarketingFund;
    address public foundationFund;
    address public coreFund;

    uint256 constant public INVESTOR_MIN_CAP = 0.1 ether;
    uint256 constant public INVESTOR_MAX_CAP = 5.0 ether;

    uint256 constant public TOTAL_SUPPLY =                      5000 * 1000 * 1000 ether;
    uint256 constant public LIQUIDITY_AND_MARKETING_AMOUNT =     690 * 1000 * 1000 ether;
    uint256 constant public FOUNDATION_1_AMOUNT =                 90 * 1000 * 1000 ether;
    uint256 constant public FOUNDATION_2_AMOUNT =                450 * 1000 * 1000 ether;
    
    uint256 constant public CROWDSALE_PRE_ICO_LIMIT =            150 * 1000 * 1000 ether;
    uint256 constant public CROWDSALE_PRE_ICO_AND_ICO_LIMIT =    500 * 1000 * 1000 ether;
    uint256 constant public CORE_LIMIT =                        3270 * 1000 * 1000 ether;

    uint256 constant public FOUNDATION_1_VESTING_START = 10 days;
    uint256 constant public FOUNDATION_1_VESTING_CLIFF = 30 days;
    uint256 constant public FOUNDATION_1_VESTING_DURATION = 120 days;

    uint256 constant public FOUNDATION_2_VESTING_START = 130 days;
    uint256 constant public FOUNDATION_2_VESTING_CLIFF = 0 days;
    uint256 constant public FOUNDATION_2_VESTING_DURATION = 240 days;

    uint256 constant public CROWDSALE_VESTING_START = 10 days;
    uint256 constant public CROWDSALE_VESTING_CLIFF = 30 days;
    uint256 constant public CROWDSALE_VESTING_DURATION = 200 days;

    uint256 constant public CORE_VESTING_START = 30 days;
    uint256 constant public CORE_VESTING_CLIFF = 90 days;
    uint256 constant public CORE_VESTING_DURATION = 360 days;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value cash paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    event Received(address, uint256);

    constructor(
        IERC20 _token,
        uint256 _preIcoRate,
        uint256 _icoRate,
        address payable _wallet,
        address _liquidityAndMarketingFund,
        address _foundationFund,
        address _coreFund,
        uint256 _startDate
    )
    {
        require(_wallet != address(0),
            "ExenoTokenCrowdsale: wrong wallet address");
        
        require(_token.totalSupply() >= TOTAL_SUPPLY,
            "ExenoTokenCrowdsale: crowdsale total supply exceeds token total supply");
        
        token = _token;
        preIcoRate = _preIcoRate;
        icoRate = _icoRate;
        wallet = _wallet;
        liquidityAndMarketingFund = _liquidityAndMarketingFund;
        foundationFund = _foundationFund;
        coreFund = _coreFund;
        startDate = _startDate;

        currentStage = CrowdsaleStage.Uninitialized;
    }

    /**
     * @dev Conversion calculation
     * @param cashAmount Amount of cash to be converted into tokens
     * @return Number of tokens that can be purchased with the specified cashAmount
     */
    function _getTokenAmount(uint256 cashAmount)
        internal view returns (uint256)
    {
        return cashAmount.mul(currentRate);
    }

    /**
     * @dev Setting stage while making sure the appropriate rate is applied
     */
    function _setCrowdsaleStage(CrowdsaleStage stage)
        internal
    {
        if (stage == CrowdsaleStage.PreICO) {
            currentRate = preIcoRate;
        } else if (stage == CrowdsaleStage.ICO) {
            currentRate = icoRate;
        }
        currentStage = stage;
    }

    /**
     * @dev Receive function
     */
    receive()
        external payable
    {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Fallback function
     */
    fallback()
        external payable
    {
        buyTokens(msg.sender);
    }

    function pause()
        public onlyOwner
    {
        _pause();
    }

    function unpause()
        public onlyOwner
    {
        _unpause();
    }

    /**
     * @notice Allows onwer to start the crowdsale
     */
    function start()
        public onlyOwner
    {
        require (currentStage == CrowdsaleStage.Uninitialized,
            "ExenoTokenCrowdsale: crowdsale is already started");
        
        require (token.balanceOf(address(this)) >= TOTAL_SUPPLY,
            "ExenoTokenCrowdsale: the balance of this contract does not match total supply");
        
        _setCrowdsaleStage(CrowdsaleStage.PreICO);
    }

    /**
     * @notice Allows investors to purchase tokens
     * @param beneficiary Address performing the token purchase
     */
    function buyTokens(address beneficiary)
        public payable whenNotPaused nonReentrant
    {
        require(block.timestamp >= startDate,
            "ExenoTokenCrowdsale: the crowdsale has not started yet");

        require(beneficiary != address(0),
            "ExenoTokenCrowdsale: wrong beneficiary address");
        
        require(msg.value > 0,
            "ExenoTokenCrowdsale: wrong value");
        
        require(currentStage == CrowdsaleStage.PreICO || currentStage == CrowdsaleStage.ICO,
            "ExenoTokenCrowdsale: buying tokens is only allowed in preICO and ICO");

        if (currentStage == CrowdsaleStage.PreICO) {
            require(totalTokensPurchased < CROWDSALE_PRE_ICO_LIMIT,
                "ExenoTokenCrowdsale: trying to buy tokens in preICO when all token have been sold");
        } else if (currentStage == CrowdsaleStage.ICO) {
            require(totalTokensPurchased < CROWDSALE_PRE_ICO_AND_ICO_LIMIT,
                "ExenoTokenCrowdsale: trying to buy tokens in ICO when all token have been sold");
        }

        uint256 _cashAmount = msg.value;
        uint256 _existingPayment = tokenPayments[beneficiary];
        uint256 _newPayment = _existingPayment.add(_cashAmount);

        require(_newPayment >= INVESTOR_MIN_CAP,
            "ExenoTokenCrowdsale: investment is below min cap");

        require(_newPayment <= INVESTOR_MAX_CAP,
            "ExenoTokenCrowdsale: investment is above max cap");

        cashRaised = cashRaised.add(_cashAmount);

        uint256 _tokens = _getTokenAmount(_cashAmount);
        totalTokensPurchased = totalTokensPurchased.add(_tokens);

        uint256 _existingPurchase = tokenPurchases[beneficiary];
        uint256 _newPurchase = _existingPurchase.add(_tokens);

        emit TokenPurchase(msg.sender, beneficiary, _cashAmount, _tokens);

        tokenPayments[beneficiary] = _newPayment;
        tokenPurchases[beneficiary] = _newPurchase;

        if(_existingPurchase == 0) {
          beneficiaries[totalBeneficiaries] = beneficiary;
          totalBeneficiaries = totalBeneficiaries.add(1);
        }

        if (currentStage == CrowdsaleStage.PreICO
        && totalTokensPurchased >= CROWDSALE_PRE_ICO_LIMIT) {
            _setCrowdsaleStage(CrowdsaleStage.ICO);
        } else if (currentStage == CrowdsaleStage.ICO
        && totalTokensPurchased >= CROWDSALE_PRE_ICO_AND_ICO_LIMIT) {
            _setCrowdsaleStage(CrowdsaleStage.PostICO);
        }
    }

    /**
    * @notice Returns the amount contributed so far by a sepecific user
    * @param beneficiary Address of contributor
    * @return User contribution so far
    */
    function getUserContribution(address beneficiary)
        public view returns (uint256)
    {
        require(beneficiary != address(0),
            "ExenoTokenCrowdsale: wrong beneficiary address");
        return tokenPayments[beneficiary];
    }

    /**
    * @notice Returns the amount of tokens purchased so far by a sepecific user
    * @param beneficiary Address of contributor
    * @return Amount of tokens purchased so far
    */
    function getUserTokensPurchased(address beneficiary)
        public view returns (uint256)
    {
        require(beneficiary != address(0),
            "ExenoTokenCrowdsale: wrong beneficiary address");
        return tokenPurchases[beneficiary];
    }

    /**
    * @notice Allows onwer to update the crowdsale stage
    */
    function nextStage()
        public onlyOwner
    {
        require(currentStage == CrowdsaleStage.PreICO || currentStage == CrowdsaleStage.ICO,
            "ExenoTokenCrowdsale: changing stage is only allowed in preICO and ICO");

        if (currentStage == CrowdsaleStage.PreICO) {
            _setCrowdsaleStage(CrowdsaleStage.ICO);
        } else if (currentStage == CrowdsaleStage.ICO) {
            _setCrowdsaleStage(CrowdsaleStage.PostICO);
        }
    }

    /**
    * @notice Allows owner to update the crowdsale rate
    * @param rate Crowdsale rate
    */
    function updateRate(uint256 rate)
        public onlyOwner
    {
        require(currentStage == CrowdsaleStage.PreICO || currentStage == CrowdsaleStage.ICO,
            "ExenoTokenCrowdsale: updating rate is only allowed in preICO and ICO");
        
        require(rate < currentRate,
            "ExenoTokenCrowdsale: only decreasing rate is allowed");
        
        if (currentStage == CrowdsaleStage.PreICO) {
            require(rate >= icoRate,
                "ExenoTokenCrowdsale: during preICO the rate cannot be less than the ICO rate");
        }
        
        currentRate = rate;
    }

    /**
     * @notice Allows owner to apply token distribution when the crowdsale is finished
    */
    function distributeTokens()
        public onlyOwner
    {
        require(currentStage == CrowdsaleStage.PostICO,
            "ExenoTokenCrowdsale: token distribution is only allowed in postICO");

        require(totalTokensPurchased > 0,
            "ExenoTokenCrowdsale: no tokens have been purchased");

        assert (token.balanceOf(address(this)) >= TOTAL_SUPPLY);
        assert (totalTokensPurchased <= CROWDSALE_PRE_ICO_AND_ICO_LIMIT);

        uint256 coreAmount = TOTAL_SUPPLY.sub(LIQUIDITY_AND_MARKETING_AMOUNT);
        coreAmount = coreAmount.sub(FOUNDATION_1_AMOUNT);
        coreAmount = coreAmount.sub(FOUNDATION_2_AMOUNT);
        coreAmount = coreAmount.sub(totalTokensPurchased);
        assert (coreAmount >= CORE_LIMIT);

        //LiquidityAndMarketing
        token.safeTransfer(liquidityAndMarketingFund, LIQUIDITY_AND_MARKETING_AMOUNT);

        //Foundation1
        foundation1Vesting = new ExenoTokenVesting(
            foundationFund,
            block.timestamp + FOUNDATION_1_VESTING_START,
            FOUNDATION_1_VESTING_CLIFF,
            FOUNDATION_1_VESTING_DURATION
        );
        token.safeTransfer(address(foundation1Vesting), FOUNDATION_1_AMOUNT);

        //Foundation2
        foundation2Vesting = new ExenoTokenVesting(
            foundationFund,
            block.timestamp + FOUNDATION_2_VESTING_START,
            FOUNDATION_2_VESTING_CLIFF,
            FOUNDATION_2_VESTING_DURATION
        );
        token.safeTransfer(address(foundation2Vesting), FOUNDATION_2_AMOUNT);

        //Crowdsale
        crowdsaleVestingPool = new ExenoTokenVestingPool(
            token,
            totalTokensPurchased
        );
        token.safeTransfer(address(crowdsaleVestingPool), totalTokensPurchased);
        for (uint256 i = 0; i < totalBeneficiaries; i++) {
            address beneficiary = beneficiaries[i];
            uint256 purchase = tokenPurchases[beneficiary];
            crowdsaleVestingPool.addBeneficiary(
                beneficiary,
                block.timestamp + CROWDSALE_VESTING_START,
                CROWDSALE_VESTING_CLIFF,
                CROWDSALE_VESTING_DURATION,
                purchase
            );
        }

        //Core
        coreVesting = new ExenoTokenVesting(
            coreFund,
            block.timestamp + CORE_VESTING_START,
            CORE_VESTING_CLIFF,
            CORE_VESTING_DURATION
        );
        token.safeTransfer(address(coreVesting), coreAmount);

        //Finalize
        _setCrowdsaleStage(CrowdsaleStage.DistributionComplete);
    }

    /**
     * @notice Allows owner to forward funds to the company wallet
     */
    function forwardFunds()
        public onlyOwner
    {
        uint256 amount = cashRaised.sub(cashForwarded);
        require(amount > 0,
            "ExenoTokenCrowdsale: there is nothing to forward");
        wallet.transfer(amount);
        cashForwarded = cashForwarded.add(amount);
    }


    function getFoundation1VestingContract()
        public view returns (address)
    {
        require(currentStage == CrowdsaleStage.DistributionComplete,
            "ExenoTokenCrowdsale: tokens have not been distributed yet");
        return address(foundation1Vesting);
    }
    function getFoundation2VestingContract()
        public view returns (address)
    {
        require(currentStage == CrowdsaleStage.DistributionComplete,
            "ExenoTokenCrowdsale: tokens have not been distributed yet");
        return address(foundation2Vesting);
    }
    function getCoreVestingContract()
        public view returns (address)
    {
        require(currentStage == CrowdsaleStage.DistributionComplete,
            "ExenoTokenCrowdsale: tokens have not been distributed yet");
        return address(coreVesting);
    }
    function getCrowdsaleVestingPoolContract()
        public view returns (address)
    {
        require(currentStage == CrowdsaleStage.DistributionComplete,
            "ExenoTokenCrowdsale: tokens have not been distributed yet");
        return address(crowdsaleVestingPool);
    }
}