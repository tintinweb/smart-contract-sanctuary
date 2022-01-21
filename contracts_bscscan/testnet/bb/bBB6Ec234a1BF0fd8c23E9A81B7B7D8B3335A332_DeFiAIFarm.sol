// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/*
   ___      _____ ___   ____
  / _ \___ / __(_) _ | /  _/
 / // / -_) _// / __ |_/ /  
/____/\__/_/ /_/_/ |_/___/  

*
* MIT License
* ===========
*
* Copyright (c) 2022 DeFiAI
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

 */

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IVestingMaster.sol";
import "./interfaces/IDeFiAIFarm.sol";
import "./interfaces/IStrategy.sol";

contract DeFiAIFarm is IDeFiAIFarm, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ============= */

    // Denominator for fee calculations.
    uint256 public constant FEE_DENOM = 10000;

    // DeFiAI token
    IERC20 public immutable override defiai;

    // The block number when mining starts.
    uint256 public immutable override startBlock;

    // Early withdrawal period. User withdrawals within this period will be charged an exit fee.
    uint256 public immutable override earlyExitPeriod;

    /* ========== STATE VARIABLES ========== */

    // Info of each pool.
    PoolInfo[] public override poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public override userInfo;

    // Pair corresponding pid.
    mapping(address => uint256) public override pair2Pid;
    mapping(IERC20 => bool) public override poolExistence;

    // DeFiAI tokens rewarded per block.
    uint256 public override defiaiPerBlock;
    
    // The block number when mining ends.
    uint256 public override endBlock;
  
    // Fee paid for early withdrawals
    uint256 public override earlyExitFee;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public override totalAllocPoint = 0;

    // Vesting contract that vested rewards get sent to.
    IVestingMaster public override vestingMaster;

    // Developer address.
    address public devAddress;

    // Supply percentage allocated to the developer.
    uint256 public devSupply;   

    /* ========== MODIFIERS ========== */

    modifier nonDuplicated(IERC20 _want) {
        require(
            !poolExistence[_want],
            "DeFiAIFarm::nonDuplicated: Duplicated"
        );
        _;
    }

    modifier validatePid(uint256 _pid) {
        require(
            _pid < poolInfo.length,
            "DeFiAIFarm::validatePid: Not exist"
        );
        _;
    }

    modifier onlyGovernance() {
        require(
            (msg.sender == devAddress || msg.sender == owner()),
            "DeFiAIFarm::onlyGovernance: Not gov"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _vestingMaster,
        address _defiai,
        uint256 _defiaiPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        address _devAddress,
        uint256 _devSupply,
        uint256 _earlyExitFee,
        uint256 _earlyExitPeriod
    ) {
        require(
            _startBlock < _endBlock,
            "DeFiAIFarm::constructor: End less than start"
        );
        vestingMaster = IVestingMaster(_vestingMaster);
        defiai = IERC20(_defiai);
        defiaiPerBlock = _defiaiPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        devAddress = _devAddress;
        devSupply = _devSupply;
        earlyExitFee = _earlyExitFee;
        earlyExitPeriod = _earlyExitPeriod;
    }

    /* ========== VIEWS ========== */

    function getMultiplier(uint256 _from, uint256 _to)
        public
        override
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    function pendingDeFiAI(uint256 _pid, address _user)
        external
        override
        view
        validatePid(_pid)
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 _sharesTotal = IStrategy(pool.strat).sharesTotal();
        if (block.number > pool.lastRewardBlock && _sharesTotal != 0) {
            uint256 tokenReward = getTokenReward(_pid);
            accTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(1e12).div(_sharesTotal)
            );
        }
        return user.shares.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    function sharesTotal(uint256 _pid)
        external
        override
        view
        validatePid(_pid)
        returns (uint256)
    {
        return IStrategy(poolInfo[_pid].strat).sharesTotal();
    }

    function stakedWantTokens(uint256 _pid, address _user)
        external
        override
        view
        returns (uint256)
    {
        return userInfo[_pid][_user].shares;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public override validatePid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.lastRewardBlock >= endBlock) {
            return;
        }
        uint256 lastRewardBlock = block.number >= endBlock ? endBlock : block.number;
        uint256 strategyShares = IStrategy(pool.strat).sharesTotal();
        if (strategyShares == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = lastRewardBlock;
            return;
        }
        uint256 tokenReward = getTokenReward(_pid);
        safeTokenTransfer(devAddress, tokenReward.mul(devSupply).div(FEE_DENOM));
        pool.accTokenPerShare = pool.accTokenPerShare.add(
            tokenReward.mul(1e12).div(strategyShares)
        );
        pool.lastRewardBlock = lastRewardBlock;
    }

    function deposit(uint256 _pid, uint256 _wantAmt)
        external
        override
        validatePid(_pid)
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.shares > 0) {
            uint256 pending =
                user.shares.mul(pool.accTokenPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                uint256 locked;
                if (address(vestingMaster) != address(0)) {
                    locked = pending
                        .div(vestingMaster.lockedPeriodAmount().add(1))
                        .mul(vestingMaster.lockedPeriodAmount());
                }
                safeTokenTransfer(msg.sender, pending.sub(locked));
                if (locked > 0) {
                    uint256 actualAmount = safeTokenTransfer(
                        address(vestingMaster),
                        locked
                    );
                    vestingMaster.lock(msg.sender, actualAmount);
                }
            }
        }
        if (_wantAmt > 0) {
            pool.want.safeTransferFrom(
                address(msg.sender),
                address(this),
                _wantAmt
            );

            pool.want.safeIncreaseAllowance(pool.strat, _wantAmt);
            uint256 sharesAdded = IStrategy(pool.strat).deposit(_wantAmt);
            user.shares = user.shares.add(sharesAdded);
            user.lastDepositedTime = block.timestamp;
        }
        user.rewardDebt = user.shares.mul(pool.accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _wantAmt);
    }

    function withdraw(uint256 _pid, uint256 _wantAmt)
        public
        override
        validatePid(_pid)
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.shares > 0) {
            uint256 pending =
                user.shares.mul(pool.accTokenPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                uint256 locked;
                if (address(vestingMaster) != address(0)) {
                    locked = pending
                        .div(vestingMaster.lockedPeriodAmount().add(1))
                        .mul(vestingMaster.lockedPeriodAmount());
                }
                safeTokenTransfer(msg.sender, pending.sub(locked));
                if (locked > 0) {
                    uint256 actualAmount = safeTokenTransfer(
                        address(vestingMaster),
                        locked
                    );
                    vestingMaster.lock(msg.sender, actualAmount);
                }
            }
        }

        if (_wantAmt > user.shares) {
            _wantAmt = user.shares;
        }
        if (_wantAmt > 0) {
            uint256 realAmt = IStrategy(pool.strat).withdraw(_wantAmt);
            if (realAmt > user.shares) {
                realAmt = user.shares;
                user.shares = 0;
            } else {
                user.shares = user.shares.sub(realAmt);
            }

            _wantAmt = realAmt;
            if (block.timestamp.sub(user.lastDepositedTime) < earlyExitPeriod) {
                _wantAmt = _wantAmt.mul(earlyExitFee).div(FEE_DENOM);
                pool.want.safeTransfer(pool.strat, realAmt.sub(_wantAmt));
            }
            pool.want.safeTransfer(address(msg.sender), _wantAmt);
        }
        user.rewardDebt = user.shares.mul(pool.accTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _wantAmt);
    }

    function withdrawAll(uint256 _pid) external override {
        withdraw(_pid, uint256(-1));
    }

    function emergencyWithdraw(uint256 _pid)
        external
        override
        validatePid(_pid)
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 realAmt = IStrategy(pool.strat).withdraw(user.shares);
        if (realAmt > user.shares) {
            realAmt = user.shares;
        }
        user.shares = 0;
        user.rewardDebt = 0;
        pool.want.safeTransfer(address(msg.sender), realAmt);
        emit EmergencyWithdraw(msg.sender, _pid, realAmt);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    
    function add(
        uint256 _allocPoint,
        IERC20 _want,
        bool _withUpdate,
        address _strat
    )
        external
        override
        onlyGovernance
        nonDuplicated(_want)
    {
        require(
            block.number < endBlock,
            "DeFiAIFarm::add: Exceed endblock"
        );
        require(_strat != address(0), "DeFiAIFarm::add: Strat can not be zero address.");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                want: _want,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0,
                strat: _strat
            })
        );
        poolExistence[_want] = true;
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    )
        external
        override
        onlyGovernance
        validatePid(_pid)
    {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function updateDeFiAIPerBlock(uint256 _defiaiPerBlock)
        external
        override
        onlyGovernance
    {
        massUpdatePools();
        defiaiPerBlock = _defiaiPerBlock;
        emit UpdateEmissionRate(msg.sender, _defiaiPerBlock);
    }

    function updateEndBlock(uint256 _endBlock)
        external
        override
        onlyGovernance
    {
        require(_endBlock > startBlock, "DeFiAIFarm::updateEndBlock: Less");
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            require(
                _endBlock > poolInfo[pid].lastRewardBlock,
                "DeFiAIFarm::updateEndBlock: Less"
            );
        }
        massUpdatePools();
        endBlock = _endBlock;
        emit UpdateEndBlock(msg.sender, _endBlock);
    }

    function setEarlyExitFee(uint256 _earlyExitFee)
        external
        override
        onlyGovernance
    {
        earlyExitFee = _earlyExitFee;
        emit SetEarlyExitFee(msg.sender, _earlyExitFee);
    }

    function setVestingMaster(address _vestingMaster) 
        external 
        override 
        onlyGovernance 
    {   
        require(_vestingMaster != address(0), "DeFiAIFarm::set: Zero address");
        vestingMaster = IVestingMaster(_vestingMaster);
        emit SetVestingMaster(msg.sender, _vestingMaster);
    }

    function setDevAddress(address _devAddress)
        external
        override
        onlyGovernance
    {   
        require(_devAddress != address(0), "DeFiAIFarm::set: Zero address");
        devAddress = _devAddress;
        emit SetDevAddress(msg.sender, _devAddress);
    }

    function setDevSupply(uint256 _devSupply) 
        external 
        override 
        onlyGovernance 
    {   
        devSupply = _devSupply;
        emit SetDevSupply(msg.sender, _devSupply);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function getTokenReward(uint256 _pid)
        internal
        view
        returns (uint256 tokenReward)
    {
        PoolInfo storage pool = poolInfo[_pid];
        require(
            pool.lastRewardBlock < block.number,
            "DeFiAIFarm::getTokenReward: Must less than block number"
        );
        uint256 multiplier = getMultiplier(
            pool.lastRewardBlock,
            block.number >= endBlock ? endBlock : block.number
        );
        tokenReward = multiplier.mul(defiaiPerBlock).mul(pool.allocPoint).div(
            totalAllocPoint
        );
    }

    /* ========== UTILITY FUNCTIONS ========== */

    function safeTokenTransfer(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 balance = defiai.balanceOf(address(this));
        uint256 amount;
        if (_amount > balance) {
            amount = balance;
        } else {
            amount = _amount;
        }

        require(
            defiai.transfer(_to, amount),
            "DeFiAIFarm::safeTokenTransfer: Transfer failed"
        );
        return amount;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/*
   ___      _____ ___   ____
  / _ \___ / __(_) _ | /  _/
 / // / -_) _// / __ |_/ /  
/____/\__/_/ /_/_/ |_/___/  

*
* MIT License
* ===========
*
* Copyright (c) 2022 DeFiAI
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IVestingMaster.sol";

interface IDeFiAIFarm {

  /* ========== STRUCTS ========== */

    struct UserInfo {
        uint256 shares;
        uint256 rewardDebt;
        uint256 lastDepositedTime;
    }

    struct PoolInfo {
        IERC20 want;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        address strat;
    }

    /* ========== EVENTS ========== */

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event UpdateEmissionRate(address indexed user, uint256 tokenPerBlock);
    event UpdateEndBlock(address indexed user, uint256 endBlock);
    event SetEarlyExitFee(address indexed user, uint256 earlyExitFee);
    event SetDevAddress(address indexed user, address devAddress);
    event SetVestingMaster(address indexed user, address vestingMaster);
    event SetDevSupply(address indexed user, uint256 devSupply);

    /* ========== VIEWS ========== */

    function defiai() external view returns (IERC20);

    function startBlock() external view returns (uint256);

    function poolInfo(uint256 _pid) external view returns (
        IERC20 want,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accTokenPerShare,
        address strat
    );

    function userInfo(uint256 _pid, address _account) external view returns (
        uint256 shares,
        uint256 rewardDebt,
        uint256 lastDepositedTime
    );

    function pair2Pid(address) external view returns(uint256);

    function poolExistence(IERC20 _lpToken) external view returns (bool);

    function defiaiPerBlock() external view returns (uint256);

    function endBlock() external view returns (uint256);

    function earlyExitFee() external view returns (uint256);

    function earlyExitPeriod() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function vestingMaster() external view returns (IVestingMaster);

    function poolLength() external view returns (uint256);

    function setVestingMaster(address) external;


    function getMultiplier(uint256, uint256) external pure returns (uint256);

    function pendingDeFiAI(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function sharesTotal(uint256 _pid) external view returns (uint256);

    function stakedWantTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _wantAmt) external;

    function withdraw(uint256 _pid, uint256 _wantAmt) external;

    function withdrawAll(uint256 _pid) external;

    function emergencyWithdraw(uint256 _pid) external;

    /* ========== RESTRICTED FUNCTIONS ========== */

    function add(
        uint256 _allocPoint,
        IERC20 _want,
        bool _withUpdate,
        address _strat
    ) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function updateDeFiAIPerBlock(uint256 _defiaiPerBlock) external;

    function updateEndBlock(uint256 _endBlock) external;

    function setEarlyExitFee(uint256 _earlyExitFee) external;

    function setDevAddress(address _devAddress) external;

    function setDevSupply(uint256 _devSupply) external;
    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/*
   ___      _____ ___   ____
  / _ \___ / __(_) _ | /  _/
 / // / -_) _// / __ |_/ /  
/____/\__/_/ /_/_/ |_/___/  

*
* MIT License
* ===========
*
* Copyright (c) 2022 DeFiAI
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

 */

interface IStrategy {

   /* ========== EVENTS ========== */

    event SetDevAddress(address indexed user, address devAddress);
    event SetDistributorAddress(address indexed user, address distributorAddress);
    event SetBuyBackRate(address indexed user, uint256 buyBackRate);
    
    /* ========== VIEWS ========== */
    
    function sharesTotal() external view returns (uint256);


    /* ========== MUTATIVE FUNCTIONS ========== */
    
    function earn() external;

    /* ========== RESTRICTED FUNCTIONS ========== */

    function deposit(uint256 _wantAmt)
        external
        returns (uint256);
        
    function withdraw(uint256 _wantAmt)
        external
        returns (uint256);

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/*
   ___      _____ ___   ____
  / _ \___ / __(_) _ | /  _/
 / // / -_) _// / __ |_/ /  
/____/\__/_/ /_/_/ |_/___/  

*
* MIT License
* ===========
*
* Copyright (c) 2022 DeFiAI
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVestingMaster {

    /* ========== STRUCTS ========== */

    // Info of each user's vesting.
    struct LockedReward {
        uint256 vesting; // How much is being vested in total
        uint256 pending; // Rewards yet to be claimed (vesting - amount_claimed)
        uint256 start; // Start of the vesting period
        uint256 lastClaimed; // Last time the vested amount was claimed
    }
    
    /* ========== EVENTS ========== */

    event Lock(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event SetFarm(address indexed user, address farmAddress);
    event SetDevAddress(address indexed user, address devAddress);

    /* ========== RESTRICTED FUNCTIONS ========== */

    function lock(address, uint256) external;
    function setFarm(address) external;
    function setDevAddress(address) external;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claim() external;

    /* ========== VIEWS ========== */

    function vestingToken() external view returns (IERC20);

    function period() external view returns (uint256);

    function lockedPeriodAmount() external view returns (uint256);

    function totalLockedRewards() external view returns (uint256);

    function getVestingAmount() external view returns (uint256, uint256);

    function farmAddress() external view returns (address);

    function devAddress() external view returns (address);
}