/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-06
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Includes openzeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/) code with MIT license


// File: @openzeppelin/contracts/GSN/Context.sol


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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/utils/Pausable.sol






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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

// File: @openzeppelin/contracts/math/SafeMath.sol





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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol








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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
    constructor () internal {
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
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol





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

    constructor () internal {
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

// File: contracts/Escapable.sol





/*
    Copyright 2016, Jordi Baylina
    Contributor: Adrià Massanet <[email protected]>
    Contributor: Oleg Abrosimov <[email protected]>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


*/






/// @dev Creates an escape hatch function that can be called in an
///  emergency that will allow designated addresses to send any ether or tokens
///  held in the contract to an `escapeHatchDestination`
contract Escapable is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  /// @notice The `escapeHatch()` should only be called as a last resort if a
  /// security issue is uncovered or something unexpected happened
  /// @param _token to transfer, use 0x0 for ether
  function escapeHatch(address _token, address payable _escapeHatchDestination) external onlyOwner nonReentrant {
    require(_escapeHatchDestination != address(0x0));

    uint256 balance;

    /// @dev Logic for ether
    if (_token == address(0x0)) {
      balance = address(this).balance;
      _escapeHatchDestination.transfer(balance);
      EscapeHatchCalled(_token, balance);
      return;
    }
    // Logic for tokens
    IERC20 token = IERC20(_token);
    balance = token.balanceOf(address(this));
    token.safeTransfer(_escapeHatchDestination, balance);
    emit EscapeHatchCalled(_token, balance);
  }

  event EscapeHatchCalled(address token, uint256 amount);
}

// File: contracts/MultiTransfer.sol





/*
    Copyright 2020, Oleg Abrosimov <[email protected]>
    Based on work by: Jordi Baylina, Adrià Massanet, Alon Bukai

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


*/




/// @notice Transfer Ether to multiple addresses
contract MultiTransfer is Pausable {
  using SafeMath for uint256;

  /// @notice Send to multiple addresses using two arrays which
  ///  includes the address and the amount.
  ///  Payable
  /// @param _addresses Array of addresses to send to
  /// @param _amounts Array of amounts to send
  function multiTransfer_OST(address payable[] calldata _addresses, uint256[] calldata _amounts)
  payable external whenNotPaused returns(bool)
  {
    // require(_addresses.length == _amounts.length);
    // require(_addresses.length <= 255);
    uint256 _value = msg.value;
    for (uint8 i; i < _addresses.length; i++) {
      _value = _value.sub(_amounts[i]);

      // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
      /*(success, ) = */_addresses[i].call{ value: _amounts[i] }("");
      // we do not care. caller should check sending results manually and re-send if needed.
    }
    return true;
  }

  /// @notice Send to two addresses
  ///  Payable
  /// @param _address1 Address to send to
  /// @param _amount1 Amount to send to _address1
  /// @param _address2 Address to send to
  /// @param _amount2 Amount to send to _address2
  function transfer2(address payable _address1, uint256 _amount1, address payable _address2, uint256 _amount2)
  payable external whenNotPaused returns(bool)
  {
    uint256 _value = msg.value;
    _value = _value.sub(_amount1);
    _value = _value.sub(_amount2);

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    /*(success, ) = */_address1.call{ value: _amount1 }("");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    /*(success, ) = */_address2.call{ value: _amount2 }("");

    return true;
  }
}

// File: contracts/MultiTransferEqual.sol





/*
    Copyright 2020, Oleg Abrosimov <[email protected]>
    Based on work by: Jordi Baylina, Adrià Massanet, Alon Bukai

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


*/


/// @notice Transfer equal Ether amount to multiple addresses
contract MultiTransferEqual is Pausable {
  /// @notice Send equal Ether amount to multiple addresses.
  ///  Payable
  /// @param _addresses Array of addresses to send to
  /// @param _amount Amount to send
  function multiTransferEqual_L1R(address payable[] calldata _addresses, uint256 _amount)
  payable external whenNotPaused returns(bool)
  {
    // assert(_addresses.length <= 255);
    require(_amount <= msg.value / _addresses.length);
    for (uint8 i; i < _addresses.length; i++) {
      // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
      /*(success, ) = */_addresses[i].call{ value: _amount }("");
      // we do not care. caller should check sending results manually and re-send if needed.
    }
    return true;
  }
}

// File: contracts/MultiTransferToken.sol





/*
    Copyright 2020, Oleg Abrosimov <[email protected]>
    Based on work by: Jordi Baylina, Adrià Massanet, Alon Bukai

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


*/





/// @notice Transfer tokens to multiple addresses
contract MultiTransferToken is Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

    /// @notice Send ERC20 tokens to multiple addresses
  ///  using two arrays which includes the address and the amount.
  ///
  /// @param _token The token to send
  /// @param _addresses Array of addresses to send to
  /// @param _amounts Array of token amounts to send
  /// @param _amountSum Sum of the _amounts array to send
  function multiTransferToken_a4A_simple(
    address _token,
    address[] calldata _addresses,
    uint256[] calldata _amounts,
    uint256 _amountSum
  ) payable external whenNotPaused
  {
     require(_addresses.length == _amounts.length);
    // require(_addresses.length <= 255);
    IERC20 token = IERC20(_token);
    uint256 balanceN = token.balanceOf(address(this));
    require(balanceN >= _amountSum);
    //token.safeTransferFrom(msg.sender, address(this), _amountSum);
    for (uint8 i; i < _addresses.length; i++) {
      _amountSum = _amountSum.sub(_amounts[i]);
      token.transfer(_addresses[i], _amounts[i]);
    }
  }

  /// @notice Send ERC20 tokens to multiple addresses
  ///  using two arrays which includes the address and the amount.
  ///
  /// @param _token The token to send
  /// @param _addresses Array of addresses to send to
  /// @param _amounts Array of token amounts to send
  /// @param _amountSum Sum of the _amounts array to send
  function multiTransferToken_a4A(
    address _token,
    address[] calldata _addresses,
    uint256[] calldata _amounts,
    uint256 _amountSum
  ) payable external whenNotPaused
  {
     require(_addresses.length == _amounts.length);
    // require(_addresses.length <= 255);
    IERC20 token = IERC20(_token);
    token.safeTransferFrom(msg.sender, address(this), _amountSum);
    for (uint8 i; i < _addresses.length; i++) {
      _amountSum = _amountSum.sub(_amounts[i]);
      token.transfer(_addresses[i], _amounts[i]);
    }
  }
}

// File: contracts/MultiTransferTokenEqual.sol





/*
    Copyright 2020, Oleg Abrosimov <[email protected]>
    Based on work by: Jordi Baylina, Adrià Massanet, Alon Bukai

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


*/





/// @notice Transfer equal tokens amount to multiple addresses
contract MultiTransferTokenEqual is Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @notice Send equal ERC20 tokens amount to multiple contracts
  ///
  /// @param _token The token to send
  /// @param _addresses Array of addresses to send to
  /// @param _amount Tokens amount to send to each address
  function multiTransferTokenEqual_71p(
    address _token,
    address[] calldata _addresses,
    uint256 _amount
  ) payable external whenNotPaused
  {
    // assert(_addresses.length <= 255);
    uint256 _amountSum = _amount.mul(_addresses.length);
    IERC20 token = IERC20(_token);
    token.safeTransferFrom(msg.sender, address(this), _amountSum);
    for (uint8 i; i < _addresses.length; i++) {
      token.transfer(_addresses[i], _amount);
    }
  }
}

// File: contracts/MultiTransferTokenEther.sol





/*
    Copyright 2020, Oleg Abrosimov <[email protected]>
    Based on work by: Jordi Baylina, Adrià Massanet, Alon Bukai

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


*/





/// @notice Transfer tokens and Ether to multiple addresses in one call
contract MultiTransferTokenEther is Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @notice Send ERC20 tokens and Ether to multiple addresses
  ///  using three arrays which includes the address and the amounts.
  ///
  /// @param _token The token to send
  /// @param _addresses Array of addresses to send to
  /// @param _amounts Array of token amounts to send
  /// @param _amountsEther Array of Ether amounts to send
  function multiTransferTokenEther(
    address _token,
    address payable[] calldata _addresses,
    uint256[] calldata _amounts,
    uint256 _amountSum,
    uint256[] calldata _amountsEther
  ) payable external whenNotPaused
  {
    // assert(_addresses.length == _amounts.length);
    // assert(_addresses.length == _amountsEther.length);
    // assert(_addresses.length <= 255);
    uint256 _value = msg.value;
    IERC20 token = IERC20(_token);
    token.safeTransferFrom(msg.sender, address(this), _amountSum);
    // bool success;
    for (uint8 i; i < _addresses.length; i++) {
      _amountSum = _amountSum.sub(_amounts[i]);
      _value = _value.sub(_amountsEther[i]);
      token.transfer(_addresses[i], _amounts[i]);

      // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
      /*(success, ) = */_addresses[i].call{ value: _amountsEther[i] }("");
      // we do not care. caller should check sending results manually and re-send if needed.
    }
  }
}

// File: contracts/MultiTransferTokenEtherEqual.sol





/*
    Copyright 2020, Oleg Abrosimov <[email protected]>
    Based on work by: Jordi Baylina, Adrià Massanet, Alon Bukai

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


*/





/// @notice Transfer equal amounts of tokens and Ether to multiple addresses in one call
contract MultiTransferTokenEtherEqual is Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @notice Send equal ERC20 tokens amount to multiple addresses
  ///
  /// @param _token The token to send
  /// @param _addresses Array of addresses to send to
  /// @param _amount Tokens amount to send to each address
  /// @param _amountEther Ether amount to send
  function multiTransferTokenEtherEqual(
    address _token,
    address payable[] calldata _addresses,
    uint256 _amount,
    uint256 _amountEther
  ) payable external whenNotPaused
  {
    // assert(_addresses.length <= 255);
    require(_amountEther <= msg.value / _addresses.length);

    uint256 _amountSum = _amount.mul(_addresses.length);
    IERC20 token = IERC20(_token);
    token.safeTransferFrom(msg.sender, address(this), _amountSum);
    for (uint8 i; i < _addresses.length; i++) {
      token.transfer(_addresses[i], _amount);

      // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
      /*(success, ) = */_addresses[i].call{ value: _amountEther }("");
      // we do not care. caller should check sending results manually and re-send if needed.
    }
  }
}

// File: contracts/MultiSend.sol





/*
    Copyright 2020, Oleg Abrosimov <[email protected]>
    Based on work by: Jordi Baylina, Adrià Massanet, Alon Bukai

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


*/









/// @notice `MultiSend` is a contract for sending multiple ETH/ERC20 Tokens to
/// multiple addresses.
///
/// Used for the https://ethereumico.io/multisend service and
/// in the [Ethereum Wallet](https://wordpress.org/plugins/ethereum-wallet/) and
/// [ERC20 Dividend Payments WordPress](https://ethereumico.io/product/erc20-dividend-payments/)
/// plugins implementation
///
contract MultiSend is Pausable, Escapable,
  MultiTransfer,
  MultiTransferEqual,
  MultiTransferToken,
  MultiTransferTokenEqual,
  MultiTransferTokenEther,
  MultiTransferTokenEtherEqual
{
  /// @dev Emergency stop contract in a case of a critical security flaw discovered
  function emergencyStop() external onlyOwner {
      _pause();
  }

  /// @dev Default payable function to not allow sending to contract;
  receive() external payable {
    revert("Can not accept Ether directly.");
  }

  /// @dev Notice callers if functions that do not exist are called
  fallback() external payable { require(msg.data.length == 0); }
}