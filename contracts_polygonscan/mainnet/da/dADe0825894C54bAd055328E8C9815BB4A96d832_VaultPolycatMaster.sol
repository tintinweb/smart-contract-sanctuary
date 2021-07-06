/**
 *Submitted for verification at polygonscan.com on 2021-07-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

    constructor () {
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

// File: @openzeppelin/contracts/utils/Context.sol

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol

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
    constructor () {
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

// File: @openzeppelin/contracts/utils/Address.sol

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
    constructor () {
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
}

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/IBEP20.sol

interface IBEP20 is IERC20
{
	function decimals() external view returns (uint8);
	
	function symbol() external view returns (string memory);

	
	function name() external view returns (string memory);
}

// File: .deps/github/Loesil/VaultChef/contracts/DeFi Projects/Polycat/IPolycatMasterChef.sol

interface IPolycatMasterChef
{
    function poolLength() external view returns (uint256);

    function poolInfo(uint256 _pid) external view returns (address, uint256, uint256, uint256, uint16);

    function userInfo() external view returns (uint256);

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function pendingFish(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount, address _referrer) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;
}

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/IToTheMoonRouter.sol

interface IToTheMoonRouter
{
    //-------------------------------------------------------------------------
    // ATTRIBUTES FUNCTIONS
    //-------------------------------------------------------------------------	
    
    function router() external view returns(address);
    
    //-------------------------------------------------------------------------
    // INFO FUNCTIONS
    //-------------------------------------------------------------------------	
    
    function getPair(address _token0, address _token1) external view returns(address);
    
	//-------------------------------------------------------------------------
    // PRICE FUNCTIONS
    //-------------------------------------------------------------------------	
	
	function getPrice(address _tokenFrom, address _tokenTo) external view returns(uint256);
	
	function getPriceForAmount(address _tokenFrom, address _tokenTo, uint256 _amountFrom) external view returns(uint256);
	
	function getLPPrice(address _tokenFrom, address _tokenTo) external view returns(uint256);
	
	function getLPPriceForAmount(address _tokenFrom, address _tokenTo, uint256 _amountFrom) external view returns(uint256);

	//-------------------------------------------------------------------------
    // LIQUIDITY FUNCTIONS
    //-------------------------------------------------------------------------	
	
	function addLiquidity(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1,
        address _spender
    ) external;
    
    function removeLiquidity(
        address _lpToken,
        uint256 _amount,
        address _spender
    ) external;

	//-------------------------------------------------------------------------
    // SWAP FUNCTIONS
    //-------------------------------------------------------------------------	
	
	function swapExactTokensForTokensSupportingFee(
        uint256 _amount,
        address _tokenIn,
		address _tokenOut,
        address _spender
    ) external;
	
	function swapExactTokensForTokensSupportingFeeWithPath(
        uint256 _amount,
        address[] calldata _path,
        address _spender
    ) external;
    
    //-------------------------------------------------------------------------
    // HELPER FUNCTIONS
    //-------------------------------------------------------------------------	
    
    function makeSwapPath(address _tokenIn, address _tokenOut) external view returns(address[] memory);
}

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/IRouter.sol

interface IRouter01
{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01
{
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/ITokenPair.sol

interface ITokenPair is IBEP20
{
	//-------------------------------------------------------------------------
    // INFO FUNCTIONS
    //-------------------------------------------------------------------------	
	
	function token0() external view returns (address);
	
	function token1() external view returns (address);
	
	function getReserves() external view returns (uint112, uint112, uint32);	
}

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/IVault.sol

interface IVault
{
    //-------------------------------------------------------------------------
    // CONSTANTS
    //-------------------------------------------------------------------------
 
    function VERSION() external view returns (string memory);
    
    //-------------------------------------------------------------------------
    // ATTRIBUTES
    //-------------------------------------------------------------------------
    
    function router() external view returns (address);
    
    function totalDeposit() external view returns (uint256);
    
    function totalShares() external view returns (uint256);
    
    function lastEarnDailyAPR() external view returns (uint256);
    
    function lastEarnTimestamp() external view returns (uint256);
    
    function depositToken() external view returns (address);
    
    function rewardToken() external view returns (address);
    
    //-------------------------------------------------------------------------
    // POOL INFO FUNCTIONS
    //-------------------------------------------------------------------------

    function getTotalPending() external view returns (uint256);
    
    function getMiningEndBlock() external view returns (uint256);
    
    function getMiningEndTime() external view returns (uint256);
    
    function isMinable() external view returns (bool);
    
    //-------------------------------------------------------------------------
    // USER INFO FUNCTIONS
    //-------------------------------------------------------------------------

    function getUserShares(address _user) external view returns (uint256);
    
    function getUserPending(address _user) external view returns (uint256);
    
    function getUserDeposit(address _user) external view returns (uint256);
    
    function getUserProfit(address _user) external view returns(int256);
    
    //-------------------------------------------------------------------------
    // COMPOUND FUNCTIONS
    //-------------------------------------------------------------------------
    
    function compound(address _claimAddress) external;
    
    function getCompoundReward() external view returns (uint256);
    
    function getNextCompoundDelay() external view returns (uint256);

    //-------------------------------------------------------------------------
    // DEPOSIT / WITHDRAW FUNCTIONS
    //-------------------------------------------------------------------------
    
    function getDepositFee() external view returns (uint256);
    
    function getWithdrawFee() external view returns (uint256);

    function deposit(address _user, uint256 _amount) external returns (uint256);

    function withdraw(address _user, uint256 _amount) external returns (uint256);
}

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/IVaultChef.sol

interface IVaultChef
{
    //-------------------------------------------------------------------------
    // ADMIN FUNCTIONS
    //-------------------------------------------------------------------------
    
    function getVaultConfig() external view returns (address, address, uint256, uint256);
    
    //-------------------------------------------------------------------------
    // BANK FUNCTIONS
    //-------------------------------------------------------------------------
    
    function getBankPoolPayoutRate() external view returns(uint256);
    
    function depositToBankVault(uint256 _amount) external;
}

// File: .deps/github/Loesil/VaultChef/contracts/Vault.sol

abstract contract Vault is IVault, Ownable, Pausable, ReentrancyGuard
{
    using SafeERC20 for IERC20;
    
    //-------------------------------------------------------------------------
    // STRUCTS
    //-------------------------------------------------------------------------
    
    struct UserInfo
    {
		uint256 refundId; // ID in map, NEVER 0
        uint256 shares; // number of shares for a user
        uint256 depositSum; //sum of all deposits
        uint256 withdrawSum; //sum of all withdraws
    }
	
	struct RefundInfo
	{
		address user; //address of user to refund
	}
    
    //-------------------------------------------------------------------------
    // CONSTANTS
    //-------------------------------------------------------------------------
    
    string public override constant VERSION = "1.3";
    
    uint256 internal constant PERCENT_FACTOR = 10000; //100%
    
    //-------------------------------------------------------------------------
    // ATTRIBUTES
    //-------------------------------------------------------------------------
    
    mapping(address => UserInfo) public userMap;

	mapping(uint256 => RefundInfo) public refundMap; //will be indexed at 1
	uint256 public refundOffset = 1;
	uint256 public refundLength;
    
    address public vaultChef;
    address public override router;
    address public immutable chef;
    uint256 public immutable poolID;
    
    address public override depositToken;
    address public override rewardToken;
    address public token0;
    address public token1;
	address public stakingToken;
	address public additionalReward;
    
    address public governor;
    
    uint256 public lastEarnBlock;
    uint256 public override lastEarnTimestamp;
	uint256 public override lastEarnDailyAPR;
    uint256 public earnDelay;
    
    uint256 public override totalShares;
    uint256 public override totalDeposit;
    
    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event Deposit(address indexed _user, uint256 _amount);
    event Withdraw(address indexed _user, uint256 _amount);
    event Compound(uint256 indexed _timestamp, address indexed _claimAddress, uint256 _totalDepositBefore, uint256 _totalDepositAfter);
    
    //-------------------------------------------------------------------------
    // CREATE
    //-------------------------------------------------------------------------
    
    constructor(
        address _vaultChef,
        address _chef,
        uint256 _poolID,
        address _router
    )
    {
        //base
        vaultChef = _vaultChef;
        chef = _chef;
        poolID = _poolID;
        router = _router;
    }
    
    //-------------------------------------------------------------------------
    // HELPER FUNCTIONS
    //-------------------------------------------------------------------------
    
    function init(address _newOwner, bool _isTokenPair) internal    
	{
		if (_isTokenPair)
		{
			token0 = ITokenPair(depositToken).token0();
            token1 = ITokenPair(depositToken).token1();
		}
        
        governor = owner();
        transferOwnership(_newOwner);
    }
    
    //-------------------------------------------------------------------------
    // POOL INFO FUNCTIONS
    //-------------------------------------------------------------------------

    function isStaking() internal view returns (bool)
    {
        return (token0 == address(0)
            || token1 == address(0));
    }
     
    function getDepositFee() public view override virtual returns (uint256)
    {
        this; // silence state mutability warning without generating bytecode
        return 0;
    }
    
    function getWithdrawFee() public view override virtual returns (uint256)
    {
        this; // silence state mutability warning without generating bytecode
        return 0;
    }
     
    function getMiningEndBlock() public view override virtual returns (uint256)
    {
        this; // silence state mutability warning without generating bytecode
        return 0;
    }
    
    function getMiningEndTime() public view override virtual returns (uint256)
    {
        this; // silence state mutability warning without generating bytecode
        return 0;
    }
    
    function getAllocPoints() internal view virtual returns (uint256)
    {
        this; // silence state mutability warning without generating bytecode
        return 1;
    }
    
    function isMinable() public view override returns (bool)
    {
        uint256 endBlock = getMiningEndBlock();
        uint256 endTime = getMiningEndTime();
        if (getAllocPoints() == 0
            || (endBlock > 0
                && block.number >= endBlock)
            || (endTime > 0
                && endTime >= block.timestamp))
        {
            return false;
        }
        
        return true;
    }
    
    //-------------------------------------------------------------------------
    // USER INFO FUNCTIONS
    //-------------------------------------------------------------------------

    function getUserShares(address _user) public override view returns (uint256)
    {
        return getShare(_user, totalShares);
    }
    
    function getUserPending(address _user) public override view returns (uint256)
    {
        return getShare(_user, this.getTotalPending());
    }
    
    function getUserDeposit(address _user) public override view returns (uint256)
    {
        return getShare(_user, totalDeposit);
    }
    
    function getShare(address _user, uint256 _total) internal view returns (uint256)
    {
        UserInfo storage user = userMap[_user];
        if (totalShares == 0)
        {
            return 0;
        }
        
        return (user.shares * _total) / totalShares;
    }
    
    function getUserProfit(address _user) external view override returns(int256)
    {
        UserInfo storage user = userMap[_user];
        uint256 userDepositSum = user.depositSum;
        uint256 userWithdrawSum = user.withdrawSum;
        uint256 userDepositCur = getUserDeposit(_user);
        
        //check overflow
        if (userWithdrawSum >= type(uint256).max - userDepositCur)
        {
            return type(int256).max;
        }
        uint256 userGains = userWithdrawSum + userDepositCur;
        
        //calculate profit/loss
        uint256 diff;
        uint256 percent;
        int256 profitPercent;
        if (userGains > userDepositSum)
        {
            //profit
            diff = userGains - userDepositSum;
            percent = (diff * PERCENT_FACTOR) / userDepositSum;
            profitPercent = int256(percent);
        }
        else if (userGains < userDepositSum)
        {
            //loss
            diff = userDepositSum - userGains;
            percent = (diff * PERCENT_FACTOR) / userDepositSum;
            profitPercent = -int256(percent);
        }
        
        return profitPercent;
    }
    
    function updateUserDepositWithdrawSum(address _user, uint256 _amount, bool _deposit) internal
    {
        UserInfo storage user = userMap[_user];
        uint256 cur = (_deposit ? user.depositSum : user.withdrawSum);
        
        //check overflow
        if (cur >= type(uint256).max - _amount)
        {
            return;
        }
        
        //update value
        if (_deposit)
        {
            user.depositSum += _amount;
        }
        else
        {
            user.withdrawSum += _amount;
        }
    }
    
    //-------------------------------------------------------------------------
    // DEPOSIT / WITHDRAW FUNCTIONS
    //-------------------------------------------------------------------------
    
    function deposit(address _user, uint256 _amount) external override onlyOwner nonReentrant whenNotPaused returns (uint256)
    {	
		if (_amount > 0)
		{
			UserInfo storage user = userMap[_user];
			uint256 origAmount = _amount;
			
			//ensure refund list
			checkRefundMap(_user);
			
			//deposit
			(_amount, ) = safeTransferFrom_withTax(_user, address(this), depositToken, _amount);
			
			//farm
			uint256 lostRate = 0;
			uint256 totalDepositBefore = 0;
            (, lostRate) = farm();
		
			//calculate shares
			uint256 sharesAdded = reduceByFee(_amount, lostRate);
			if (totalDepositBefore > 0)
			{
				sharesAdded = (_amount * totalShares) / totalDepositBefore;
			}
			totalShares += sharesAdded;
			user.shares += sharesAdded;
			updateUserDepositWithdrawSum(_user, origAmount, true);
        
            //event
            emit Deposit(_user, _amount);
		}

        return _amount;
    }

    function withdraw(address _user, uint256 _amount) external override onlyOwner nonReentrant returns (uint256)
    {
        require(_amount > 0, "amount");
        require(totalDeposit > 0, "deposit");        
        
        //check if valid user amount
        UserInfo storage user = userMap[_user];
		uint256 userDeposit = getUserDeposit(_user);
		if (_amount > userDeposit)
		{
			_amount = userDeposit;
		}
		uint256 origAmount = _amount;
		
		if (_amount > 0)
		{
            //check share & total deposit
            uint256 amountShares = (_amount * totalShares) / totalDeposit;
    		require(amountShares <= user.shares, ">userShares");
    		require(amountShares <= totalShares, ">vaultShares");
    		require(_amount <= totalDeposit, ">deposit");
    
    		//withdraw from vault
            (uint256 received,) = claim(_amount);
            
            //get received funds
            IERC20(depositToken).safeTransfer(_user, received);		
    		
            //set shares/deposit
            user.shares -= amountShares;
            totalShares -= amountShares;        
            totalDeposit -= _amount;
            updateUserDepositWithdrawSum(_user, origAmount, false);
            
		    //event
            emit Withdraw(_user, _amount);
		}

        return _amount;
    }
    
    function poolDeposit(uint256 _amount) internal virtual returns(uint256 _received, uint256 _lostRate)
    {
        _amount; // silence unused parameter warning without generating bytecode
        return (0, 0);
    }
    
    function poolWithdraw(uint256 _amount) internal virtual returns(uint256 _received, uint256 _lostRate)
    {
        _amount; // silence unused parameter warning without generating bytecode
        return (0, 0);
    }
    
    //-------------------------------------------------------------------------
    // FARM / CLAIM FUNCTIONS
    //-------------------------------------------------------------------------
    
    function farm() internal virtual returns(uint256 _received, uint256 _lostRate)
    {
        //try harvest before deposit (which also could harvest reward)
        if (getNextCompoundDelay() > 0
            && totalShares > 0)
        {
            poolWithdraw(0);
        }
        
        //get balance
        uint256 amount = IERC20(depositToken).balanceOf(address(this));
        
        //make deposit
        uint256 lostRate = 0;
        IERC20(depositToken).safeIncreaseAllowance(chef, amount);
        (amount, lostRate) = poolDeposit(amount);
        
        //increase total deposit
        totalDeposit += amount;
        
        return (amount, lostRate);
    }
    
    function claim(uint256 _amount) internal virtual returns(uint256 _received, uint256 _lostRate)
    {
        if (totalDeposit == 0)
        {
            return (0, 0);
        }
        
        if (_amount != 0)
        {
            //try harvest before withdraw
            poolWithdraw(0);
        }
        return poolWithdraw(_amount);
    }    
    
    //-------------------------------------------------------------------------
    // COMPOUND FUNCTIONS
    //-------------------------------------------------------------------------
    
    function compound(address _claimAddress) public override whenNotPaused
    {
		require(getNextCompoundDelay() == 0, "compoundLock");	
	
        //claim rewards
        claim(0);
        
        //convert additional reward to reward
        if (additionalReward != address(0))
        {
            uint256 additionalBalance = IERC20(additionalReward).balanceOf(address(this));
    		if (additionalBalance > 0)
    		{
    		    swapTokens(additionalBalance, additionalReward, true);   
    		}
        }

        //convert reward to deposit
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
		if (balance > 0)
		{
			//distribute to treasury and compound reward
			balance = distributeFees(balance, _claimAddress);
			
			//send payout to bank
			uint256 bankPayoutRate = IVaultChef(vaultChef).getBankPoolPayoutRate();
			uint256 reinvest = reduceByFee(balance, bankPayoutRate);
			uint256 payout = balance - reinvest;
			if (payout > 0)
			{
			    (, address bank, ,) = IVaultChef(vaultChef).getVaultConfig();
			    IERC20(rewardToken).safeIncreaseAllowance(bank, payout);
			    IVaultChef(vaultChef).depositToBankVault(payout);
			}
			balance = reinvest;

			//exchange reward to deposit
			convertRewardToDeposit(balance);
		}
        
        //reinvest		
		uint256 lastEarnDeposit = totalDeposit;
        farm();
        
        //set info & calc last daily APR
		uint256 earned = totalDeposit - lastEarnDeposit;
		uint256 passed = block.timestamp - lastEarnTimestamp;
		if (passed > 0
			&& earned > 0
			&& totalDeposit > 0)
		{
			uint256 earnDay = (earned * 1 days) / passed;
			lastEarnDailyAPR = (earnDay * PERCENT_FACTOR) / lastEarnDeposit;	
		}		
        lastEarnBlock = block.number;
        lastEarnTimestamp = block.timestamp;
        
        //event
        emit Compound(block.timestamp, _claimAddress, lastEarnDeposit, totalDeposit);
    }

    function getCompoundReward() public override view returns (uint256)
    {
        return this.calcCompoundReward(this.getTotalPending());
    }
    
    function calcCompoundReward(uint256 _earned) public view returns (uint256)
    {
        (, , , uint reward) = IVaultChef(vaultChef).getVaultConfig();
        uint claimReward = (_earned * reward) / PERCENT_FACTOR;
        
        return claimReward;
    }
    
    function getNextCompound() public virtual view returns (uint256)
    {
        return lastEarnTimestamp + earnDelay;
    }
    
    function getNextCompoundDelay() public override view returns (uint256)
    {
        uint next = getNextCompound();
        if (next <= block.timestamp)
        {
            return 0;
        }
        
        return next - block.timestamp;
    }
    
    //-------------------------------------------------------------------------
    // SWAP FUNCTIONS
    //-------------------------------------------------------------------------
    
    function convertRewardToDeposit(uint256 _amount) internal virtual
    {
		if (isStaking())
		{
			if (rewardToken != depositToken)
			{
				swapTokens(_amount, depositToken, false);
			}
		}
		else
		{
			uint256 halfEarned = _amount / 2;

			//swap half earned to token0
			if (rewardToken != token0)
    		{
    			swapTokens(halfEarned, token0, false);
    		}

			//swap half earned to token1
			if (rewardToken != token1)
    		{
    			swapTokens(halfEarned, token1, false);
    		}

			//get deposit tokens
			uint256 token0Amount = IERC20(token0).balanceOf(address(this));
			uint256 token1Amount = IERC20(token1).balanceOf(address(this));
			if (token0Amount > 0
				&& token1Amount > 0)
			{
				addLiquidity(token0Amount, token1Amount);
			}
			
			//handle remaining dust
			convertDustToReward();
		}
    }

    function convertDustToReward() public virtual whenNotPaused
    {
        if (!isStaking())
        {
            return;
        }

        //converts token0 dust (if any) to reward token
        uint256 token0Amount = IERC20(token0).balanceOf(address(this));
        if (token0 != rewardToken
            && token0Amount > 0)
        {
            swapTokens(token0Amount, token0, true);
        }

        //converts token1 dust (if any) to reward token
        uint256 token1Amount = IERC20(token1).balanceOf(address(this));
        if (token1 != rewardToken
            && token1Amount > 0)
        {
            swapTokens(token1Amount, token1, true);
        }
    }
    
    function addLiquidity(uint256 _amount0, uint256 _amount1) internal virtual
    {
        address projectRouter = IToTheMoonRouter(router).router();
        
		//increase allowance
		IERC20(token0).safeIncreaseAllowance(projectRouter, _amount0);
		IERC20(token1).safeIncreaseAllowance(projectRouter, _amount1);
		
		//add Liquidity
		IRouter02(projectRouter).addLiquidity(
            token0,
            token1,
            _amount0,
            _amount1,
            0,
            0,
           address(this),
            block.timestamp + 60
        );
    }
    
    function swapTokens(uint256 _amount, address _token, bool _toReward) internal virtual
    {
	    address projectRouter = IToTheMoonRouter(router).router();
	    
		//increase allowance
		IERC20((_toReward ? _token : rewardToken)).safeIncreaseAllowance(projectRouter, _amount);
	
		//swap
		IRouter02(projectRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            IToTheMoonRouter(router).makeSwapPath(
                (_toReward ? _token : rewardToken),
                (_toReward ? rewardToken : _token)),
            address(this),
            block.timestamp + 60
        );
    }
	
    //-------------------------------------------------------------------------
    // TREASURY FUNCTIONS
    //-------------------------------------------------------------------------
	
	function withdrawToTreasury(address _token) external
	{
		//check if allowed (only unused tokens or when no deposit)
		bool locked = false;
		if (totalDeposit != 0
			&& (_token == token0
				|| _token == token1
				|| _token == rewardToken
				|| _token == depositToken
				|| _token == stakingToken))
		{
			locked = true;
		}
		require(!locked, "locked");
		
		//transfer
		uint256 balance = IERC20(_token).balanceOf(address(this));
		if (balance > 0)
		{
			(address treasury, , ,) = IVaultChef(vaultChef).getVaultConfig();		
			IERC20(_token).safeTransfer(treasury, balance);
		}
	}
    
    function distributeClaimReward(uint256 _earned, address _claimAddress) internal returns (uint256)
    {
        uint256 claimShare = 0;
        if (_earned > 0)
        {
            claimShare = this.calcCompoundReward(_earned);
            if (claimShare > 0)
            {
                IERC20(rewardToken).safeTransfer(_claimAddress, claimShare);
            }
        }

        return claimShare;
    } 
    
    function distributeFees(uint256 _earned, address _claimAddress) internal returns (uint256)
    {
        if (_earned > 0)
        {
            (address treasury, , uint256 fee,) = IVaultChef(vaultChef).getVaultConfig();
            
            //claim reward
            uint claimAmount = distributeClaimReward(_earned, _claimAddress);

            //treasury fee
            uint256 treasuryAmount = 0;
            if (fee > 0)
            {
                treasuryAmount = (_earned * fee) / PERCENT_FACTOR;
                IERC20(rewardToken).safeTransfer(treasury, treasuryAmount);
                _earned -= treasuryAmount;
            }
            
            //reduce earned
            _earned -= claimAmount + treasuryAmount;
        }

        return _earned;
    }
	
	//-------------------------------------------------------------------------
    // REFUND FUNCTIONS
    //-------------------------------------------------------------------------

	function checkRefundMap(address _user) internal
	{
		UserInfo storage user = userMap[_user];
		if (user.refundId != 0)
		{
			//user is already in refund map
			return;
		}
		
		//set user data
		refundLength += 1;
		user.refundId = refundLength; //0 is never used
		
		//create refund data
		RefundInfo storage refund = refundMap[user.refundId];
		refund.user = _user;
	}
	
	function resetRefundOffset() public onlyGov
	{
		refundOffset = 1;
	}
	
	function refundUsers(uint256 _count) public onlyGov whenPaused
	{
	    uint256 to = refundOffset + _count;
	    if (to > refundLength)
	    {
	        to = refundLength;
	    }
	    
		for (uint256 n = refundOffset; n <= to; n++)
		{
			RefundInfo storage refund = refundMap[n];
			UserInfo storage user = userMap[refund.user];
			
			//get user data
			uint256 userBalance = getUserDeposit(refund.user);
			if (userBalance > 0)
			{
				//claim			
				claim(userBalance);
				
				//transfer
				IERC20(depositToken).safeTransfer(refund.user, userBalance);		
				
				//set shares/deposit
				totalShares -= user.shares;        
				totalDeposit -= userBalance;
				user.shares = 0;
			}
			
			//next refund
			refundOffset += 1;			
		}	
	}
	
	//-------------------------------------------------------------------------
    // TRANSFER WITH TAX FUNCTIONS
    //-------------------------------------------------------------------------
    
    function safeTransferFrom_withTax(address _from, address _to, address _token, uint256 _amount) internal returns(uint256 _received, uint256 _lostRate)
    {
        uint256 balanceBefore = IERC20(_token).balanceOf(_to);
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
        return calculateTransferLoss(_to, _token, _amount, balanceBefore);
    }
    
    function safeTransfer_withTax(address _to, address _token, uint256 _amount) internal returns(uint256 _received, uint256 _lostRate)
    {
        uint256 balanceBefore = IERC20(_token).balanceOf(_to);
        IERC20(_token).safeTransfer(_to, _amount);
        return calculateTransferLoss(_to, _token, _amount, balanceBefore);
    }
    
    //-------------------------------------------------------------------------
    // HELPER FUNCTIONS
    //-------------------------------------------------------------------------
    
    function calculateTransferLoss(address _target, address _token, uint256 _amount, uint256 _balanceBefore) internal view returns(uint256 _received, uint256 _lostRate)
    {
        if (_amount == 0)
        {
            return (0, 0);
        }
        uint256 balanceAfter = IERC20(_token).balanceOf(_target);
        return calculateTransferLossValue(_amount, _balanceBefore, balanceAfter);
    }
    
    function calculateTransferLossValue(uint256 _amount, uint256 _balanceBefore, uint256 _balanceAfter) internal pure returns(uint256 _received, uint256 _lostRate)
    {
        if (_amount == 0)
        {
            return (0, 0);
        }
        uint256 received = _balanceAfter - _balanceBefore;
        uint256 lost = _amount - received;
        uint256 lostRate = (lost * PERCENT_FACTOR) / _amount;
        return (received, lostRate);
    }
    
    function reduceByFee(uint256 _value, uint256 _feeRate) internal pure returns (uint256)
    {
        if (_feeRate == 0)
        {
            return _value;
        }
        return (_value * (PERCENT_FACTOR - _feeRate)) / PERCENT_FACTOR;
    }
    
    //-------------------------------------------------------------------------
    // GOVERNANCE FUNCTIONS
    //-------------------------------------------------------------------------
    
    modifier onlyGov()
    {
        _onlyGov();
        _;
    }
	
	function _onlyGov() internal view
	{
		require(governor == msg.sender, "!Gov");	
	}
    
    function transferGovernance(address _gov) public onlyGov
    {
        governor = _gov;
    }

    function pause() public onlyGov
    {
        _pause();
    }

    function unpause() external onlyGov
    {
        _unpause();
    }
    
    function setCompoundDelay(uint256 _delay) external onlyGov
    {
        earnDelay = _delay;
    }
    
    function migrateToVault(address _vaultChef) external onlyGov
    {
        vaultChef = _vaultChef;
    }
    
    function setRouter(address _router) external onlyGov
    {
        router = _router;
    }
}

// File: .deps/github/Loesil/VaultChef/contracts/DeFi Projects/Polycat/VaultPolycatMaster.sol

contract VaultPolycatMaster is Vault
{
    using SafeERC20 for IBEP20;
    
    //-------------------------------------------------------------------------
    // CONSTANTS
    //-------------------------------------------------------------------------

    address public constant REWARD_TOKEN = 0x3a3Df212b7AA91Aa0402B9035b098891d276572B;
    
    address public constant CHEF = 0x8CFD1B9B7478E7B0422916B72d1DB6A9D513D734;
    
    //-------------------------------------------------------------------------
    // CREATE
    //-------------------------------------------------------------------------
    
    constructor(
        address _vaultChef,				
        uint256 _poolID,
        bool _isTokenPair,
		address _router
    ) Vault(
        _vaultChef,
        CHEF,
        _poolID,
		_router
    )
    {
        //tokens
        (depositToken, , , ,) = IPolycatMasterChef(CHEF).poolInfo(_poolID);
        rewardToken = REWARD_TOKEN;
        
        //init
        init(address(_vaultChef), _isTokenPair);
    }
    
    //-------------------------------------------------------------------------
    // POOL INFO FUNCTIONS
    //-------------------------------------------------------------------------
    
    function getTotalPending() public override view returns (uint256)
    {
        uint256 balance = IERC20(depositToken).balanceOf(address(this));
        uint256 pending = IPolycatMasterChef(chef).pendingFish(poolID, address(this));
        
        return balance + pending;
    }
    
    function getAllocPoints() internal view override returns (uint256)
    {
        (, uint256 allocPoints, , ,) = IPolycatMasterChef(CHEF).poolInfo(poolID);
        return allocPoints;
    }
	
    //-------------------------------------------------------------------------
    // DEPOSIT / WITHDRAW FUNCTIONS
    //-------------------------------------------------------------------------
    
    function getDepositFee() public view override returns (uint256)
    {
        (, , , , uint16 poolDepositFee) = IPolycatMasterChef(chef).poolInfo(poolID);
        return uint256(poolDepositFee); //10000 = 100%
    }
    
    function poolDeposit(uint256 _amount) internal override returns(uint256 _received, uint256 _lostRate)
    {
		(address treasury, , ,) = IVaultChef(vaultChef).getVaultConfig();
		
        uint256 balanceBefore = IERC20(depositToken).balanceOf(chef);
        IPolycatMasterChef(chef).deposit(poolID, _amount, treasury);
        return calculateTransferLoss(chef, depositToken, _amount, balanceBefore);
    }
    
    function poolWithdraw(uint256 _amount) internal override returns(uint256 _received, uint256 _lostRate)
    {
        uint256 balanceBefore = IERC20(depositToken).balanceOf(address(this));
        IPolycatMasterChef(chef).withdraw(poolID, _amount);
        return calculateTransferLoss(address(this), depositToken, _amount, balanceBefore);
    }
}