/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/math/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File contracts/lib/FixedPointMath.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

library FixedPointMath {
  uint256 public constant DECIMALS = 18;
  uint256 public constant SCALAR = 10**DECIMALS;

  struct uq192x64 {
    uint256 x;
  }

  function fromU256(uint256 value) internal pure returns (uq192x64 memory) {
    uint256 x;
    require(value == 0 || (x = value * SCALAR) / SCALAR == value);
    return uq192x64(x);
  }

  function maximumValue() internal pure returns (uq192x64 memory) {
    return uq192x64(uint256(-1));
  }

  function add(uq192x64 memory self, uq192x64 memory value) internal pure returns (uq192x64 memory) {
    uint256 x;
    require((x = self.x + value.x) >= self.x);
    return uq192x64(x);
  }

  function add(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
    return add(self, fromU256(value));
  }

  function sub(uq192x64 memory self, uq192x64 memory value) internal pure returns (uq192x64 memory) {
    uint256 x;
    require((x = self.x - value.x) <= self.x);
    return uq192x64(x);
  }

  function sub(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
    return sub(self, fromU256(value));
  }

  function mul(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
    uint256 x;
    require(value == 0 || (x = self.x * value) / value == self.x);
    return uq192x64(x);
  }

  function div(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
    require(value != 0);
    return uq192x64(self.x / value);
  }

  function cmp(uq192x64 memory self, uq192x64 memory value) internal pure returns (int256) {
    if (self.x < value.x) {
      return -1;
    }

    if (self.x > value.x) {
      return 1;
    }

    return 0;
  }

  function decode(uq192x64 memory self) internal pure returns (uint256) {
    return self.x / SCALAR;
  }
}


// File contracts/interfaces/IDetailedERC20.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

interface IDetailedERC20 is IERC20 {
  function name() external returns (string memory);
  function symbol() external returns (string memory);
  function decimals() external returns (uint8);
}


// File contracts/interfaces/IMintableERC20.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

interface IMintableERC20 is IDetailedERC20{
  function mint(address _recipient, uint256 _amount) external;
  function burnFrom(address account, uint256 amount) external;
  function lowerHasMinted(uint256 amount) external;
  function lowerHasMintedIfNeeded(uint256 amount) external;
}


// File contracts/interfaces/IRewardVesting.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

interface IRewardVesting  {
    function addEarning(address user, uint256 amount, uint256 durationInSecs) external;
    function userBalances(address user) external view returns (uint256 bal);
}


// File @openzeppelin/contracts/math/[email protected]


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
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// File contracts/farm/Pool.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma experimental ABIEncoderV2;





/// @title Pool
///
/// @dev A library which provides the Pool data struct and associated functions.
library Pool {
  using FixedPointMath for FixedPointMath.uq192x64;
  using Pool for Pool.Data;
  using Pool for Pool.List;
  using SafeMath for uint256;

  struct Context {
    uint256 rewardRate;
    uint256 totalRewardWeight;
  }

  struct Data {
    IERC20 token;
    uint256 totalDeposited;
    uint256 rewardWeight;
    FixedPointMath.uq192x64 accumulatedRewardWeight;
    // for vesting
    uint256 lastUpdatedBlock;
    bool needVesting;
    // for referral power calculation
    uint256 vestingDurationInSecs;
    bool onReferralBonus;
    uint256 totalReferralAmount; // deposited through referral
    FixedPointMath.uq192x64 accumulatedReferralWeight;
  }

  struct List {
    Data[] elements;
  }

  /// @dev Updates the pool.
  ///
  /// @param _ctx the pool context.
  function update(Data storage _data, Context storage _ctx) internal {
    _data.accumulatedRewardWeight = _data.getUpdatedAccumulatedRewardWeight(_ctx);

    if (_data.onReferralBonus) {
      _data.accumulatedReferralWeight = _data.getUpdatedAccumulatedReferralWeight(_ctx);
    }

    _data.lastUpdatedBlock = block.number;
  }

  /// @dev Gets the rate at which the pool will distribute rewards to stakers.
  ///
  /// @param _ctx the pool context.
  ///
  /// @return the reward rate of the pool in tokens per block.
  function getRewardRate(Data storage _data, Context storage _ctx)
    internal view
    returns (uint256)
  {
    return _ctx.rewardRate.mul(_data.rewardWeight).div(_ctx.totalRewardWeight);
  }

  /// @dev Gets the accumulated reward weight of a pool.
  ///
  /// @param _ctx the pool context.
  ///
  /// @return the accumulated reward weight.
  function getUpdatedAccumulatedRewardWeight(Data storage _data, Context storage _ctx)
    internal view
    returns (FixedPointMath.uq192x64 memory)
  {
    if (_data.totalDeposited == 0) {
      return _data.accumulatedRewardWeight;
    }

    uint256 _elapsedTime = block.number.sub(_data.lastUpdatedBlock);
    if (_elapsedTime == 0) {
      return _data.accumulatedRewardWeight;
    }

    uint256 _rewardRate = _data.getRewardRate(_ctx);
    uint256 _distributeAmount = _rewardRate.mul(_elapsedTime);

    if (_distributeAmount == 0) {
      return _data.accumulatedRewardWeight;
    }

    FixedPointMath.uq192x64 memory _rewardWeight = FixedPointMath.fromU256(_distributeAmount).div(_data.totalDeposited);
    return _data.accumulatedRewardWeight.add(_rewardWeight);
  }

  /// @dev Gets the accumulated referral weight of a pool.
  ///
  /// @param _ctx the pool context.
  ///
  /// @return the accumulated reward weight.
  function getUpdatedAccumulatedReferralWeight(Data storage _data, Context storage _ctx)
    internal view
    returns (FixedPointMath.uq192x64 memory)
  {
    if (_data.totalReferralAmount == 0) {

      return _data.accumulatedReferralWeight;
    }

    uint256 _elapsedTime = block.number.sub(_data.lastUpdatedBlock);
    if (_elapsedTime == 0) {
      return _data.accumulatedReferralWeight;
    }

    uint256 _rewardRate = _data.getRewardRate(_ctx);
    uint256 _distributeAmount = _rewardRate.mul(_elapsedTime);

    if (_distributeAmount == 0) {
      return _data.accumulatedReferralWeight;
    }

    FixedPointMath.uq192x64 memory _rewardWeight = FixedPointMath.fromU256(_distributeAmount).div(_data.totalReferralAmount);
    return _data.accumulatedReferralWeight.add(_rewardWeight);
  }  

  /// @dev Adds an element to the list.
  ///
  /// @param _element the element to add.
  function push(List storage _self, Data memory _element) internal {
    _self.elements.push(_element);
  }

  /// @dev Gets an element from the list.
  ///
  /// @param _index the index in the list.
  ///
  /// @return the element at the specified index.
  function get(List storage _self, uint256 _index) internal view returns (Data storage) {
    return _self.elements[_index];
  }

  /// @dev Gets the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///ck
  /// @return the last element in the list.
  function last(List storage _self) internal view returns (Data storage) {
    return _self.elements[_self.lastIndex()];
  }

  /// @dev Gets the index of the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the index of the last element.
  function lastIndex(List storage _self) internal view returns (uint256) {
    uint256 _length = _self.length();
    return _length.sub(1, "Pool.List: list is empty");
  }

  /// @dev Gets the number of elements in the list.
  ///
  /// @return the number of elements.
  function length(List storage _self) internal view returns (uint256) {
    return _self.elements.length;
  }
}


// File contracts/farm/Stake.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity ^0.6.2;





/// @title Stake
///
/// @dev A library which provides the Stake data struct and associated functions.
library Stake {
  using FixedPointMath for FixedPointMath.uq192x64;
  using Pool for Pool.Data;
  using SafeMath for uint256;
  using Stake for Stake.Data;

  struct Data {
    uint256 totalDeposited;
    uint256 totalUnclaimed;
    FixedPointMath.uq192x64 lastAccumulatedWeight;
  }

  function update(Data storage _self, Pool.Data storage _pool, Pool.Context storage _ctx) internal {
    _self.totalUnclaimed = _self.getUpdatedTotalUnclaimed(_pool, _ctx);
    _self.lastAccumulatedWeight = _pool.getUpdatedAccumulatedRewardWeight(_ctx);
  }

  function getUpdatedTotalUnclaimed(Data storage _self, Pool.Data storage _pool, Pool.Context storage _ctx)
    internal view
    returns (uint256)
  {
    FixedPointMath.uq192x64 memory _currentAccumulatedWeight = _pool.getUpdatedAccumulatedRewardWeight(_ctx);
    FixedPointMath.uq192x64 memory _lastAccumulatedWeight = _self.lastAccumulatedWeight;

    if (_currentAccumulatedWeight.cmp(_lastAccumulatedWeight) == 0) {
      return _self.totalUnclaimed;
    }

    uint256 _distributedAmount = _currentAccumulatedWeight
      .sub(_lastAccumulatedWeight)
      .mul(_self.totalDeposited)
      .decode();

    return _self.totalUnclaimed.add(_distributedAmount);
  }
}


// File contracts/farm/ReferralPower.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity ^0.6.2;




/// @title ReferralPower
///
/// @dev A library which provides the ReferralPower data struct and associated functions.
library ReferralPower {
  using FixedPointMath for FixedPointMath.uq192x64;
  using Pool for Pool.Data;
  using SafeMath for uint256;
  using ReferralPower for ReferralPower.Data;

  struct Data {
    uint256 totalDeposited;
    uint256 totalReferralPower;
    FixedPointMath.uq192x64 lastAccumulatedReferralPower;
  }

  function update(Data storage _self, Pool.Data storage _pool, Pool.Context storage _ctx) internal {
    _self.totalReferralPower = _self.getUpdatedTotalReferralPower(_pool, _ctx);
    _self.lastAccumulatedReferralPower = _pool.getUpdatedAccumulatedReferralWeight(_ctx);
  }

  function getUpdatedTotalReferralPower(Data storage _self, Pool.Data storage _pool, Pool.Context storage _ctx)
    internal view
    returns (uint256)
  {
    FixedPointMath.uq192x64 memory _currentAccumulatedReferralPower = _pool.getUpdatedAccumulatedReferralWeight(_ctx);
    FixedPointMath.uq192x64 memory lastAccumulatedReferralPower = _self.lastAccumulatedReferralPower;

    if (_currentAccumulatedReferralPower.cmp(lastAccumulatedReferralPower) == 0) {
      return _self.totalReferralPower;
    }

    uint256 _distributedAmount = _currentAccumulatedReferralPower
      .sub(lastAccumulatedReferralPower)
      .mul(_self.totalDeposited)
      .decode();

    return _self.totalReferralPower.add(_distributedAmount);
  }
}


// File contracts/farm/StakingPool.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity ^0.6.2;










// import "hardhat/console.sol";

/// @dev A contract which allows users to stake to farm tokens.
///
/// This contract was inspired by Chef Nomi's 'MasterChef' contract which can be found in this
/// repository: https://github.com/sushiswap/sushiswap.
contract StakingPools is ReentrancyGuard {
  using FixedPointMath for FixedPointMath.uq192x64;
  using Pool for Pool.Data;
  using Pool for Pool.List;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using Stake for Stake.Data;
  using ReferralPower for ReferralPower.Data;

  event PendingGovernanceUpdated(
    address pendingGovernance
  );

  event GovernanceUpdated(
    address governance
  );

  event RewardRateUpdated(
    uint256 rewardRate
  );

  event PoolRewardWeightUpdated(
    uint256 indexed poolId,
    uint256 rewardWeight
  );

  event PoolCreated(
    uint256 indexed poolId,
    IERC20 indexed token
  );

  event TokensDeposited(
    address indexed user,
    uint256 indexed poolId,
    uint256 amount
  );

  event TokensWithdrawn(
    address indexed user,
    uint256 indexed poolId,
    uint256 amount
  );

  event TokensClaimed(
    address indexed user,
    uint256 indexed poolId,
    uint256 amount
  );

  event PauseUpdated(
    bool status
  );

  event SentinelUpdated(
    address sentinel
  );

  event RewardVestingUpdated(
    IRewardVesting rewardVesting
  );

  event NewReferralAdded(
    address referral, address referee
  );

  /// @dev The token which will be minted as a reward for staking.
  IERC20 public reward;

  /// @dev The address of reward vesting.
  IRewardVesting public rewardVesting;

  /// @dev The address of the account which currently has administrative capabilities over this contract.
  address public governance;

  address public pendingGovernance;

  /// @dev The address of the account which can perform emergency activities
  address public sentinel;

  /// @dev Tokens are mapped to their pool identifier plus one. Tokens that do not have an associated pool
  /// will return an identifier of zero.
  mapping(IERC20 => uint256) public tokenPoolIds;

  /// @dev The context shared between the pools.
  Pool.Context private _ctx;

  /// @dev A list of all of the pools.
  Pool.List private _pools;

  /// @dev A mapping of all of the user stakes mapped first by pool and then by address.
  mapping(address => mapping(uint256 => Stake.Data)) private _stakes;

  /// @dev A mapping of all of the referral power mapped first by pool and then by address.
  mapping(address => mapping(uint256 => ReferralPower.Data)) private _referralPowers;

/// @dev A mapping of all of the referee staker power mapped first by pool and then by referral address.
  mapping(address => mapping(uint256 => address)) public myReferral;

  /// @dev A mapping of known referrals mapped first by pool and then by address.
  mapping(address => mapping(uint256 => bool)) public referralIsKnown;

  /// @dev A mapping of referral Address mapped first by pool and then by nextReferral.
  mapping(uint256 => mapping(uint256 => address)) public referralList;

  /// @dev index record next user index mapped by pool
  mapping(uint256 => uint256) public nextReferral;

  // @dev A mapping of all of the referee staker referred by me. Mapping as by pool id and then by my address then referee array
  mapping(uint256 => mapping(address => address[])) public myreferees;

  /// @dev A flag indicating if claim should be halted
  bool public pause;

  constructor(
    IMintableERC20 _reward,
    address _governance,
    address _sentinel,
    IRewardVesting _rewardVesting
  ) public {
    require(_governance != address(0), "StakingPools: governance address cannot be 0x0");
    require(_sentinel != address(0), "StakingPools: sentinel address cannot be 0x0");

    reward = _reward;
    governance = _governance;
    sentinel = _sentinel;
    rewardVesting = _rewardVesting;
  }

  /// @dev A modifier which reverts when the caller is not the governance.
  modifier onlyGovernance() {
    require(msg.sender == governance, "StakingPools: only governance");
    _;
  }

  ///@dev modifier add referral to referrallist. Users are indexed in order to keep track of
  modifier checkIfNewReferral(uint256 pid, address referral) {
    Pool.Data storage _pool = _pools.get(pid);

    if (_pool.onReferralBonus && referral != address(0)) {
      if (!referralIsKnown[referral][pid]) {
          referralList[pid][nextReferral[pid]] = referral;
          referralIsKnown[referral][pid] = true;
          nextReferral[pid]++;

          emit NewReferralAdded(referral, msg.sender);
      }

      // add referee to referral's myreferee array
      bool toAdd = true;
      address refereeAddr = msg.sender;
      address[] storage  referees = myreferees[pid][referral];
      for (uint256 i = 0; i < referees.length; i++) {
        if (referees[i] == refereeAddr) {
          toAdd = false;
        }
      }

      if (toAdd) {
        referees.push(refereeAddr);
      }
    } 

    _;
  }

  /// @dev Sets the governance.
  ///
  /// This function can only called by the current governance.
  ///
  /// @param _pendingGovernance the new pending governance.
  function setPendingGovernance(address _pendingGovernance) external onlyGovernance {
    require(_pendingGovernance != address(0), "StakingPools: pending governance address cannot be 0x0");
    pendingGovernance = _pendingGovernance;

    emit PendingGovernanceUpdated(_pendingGovernance);
  }

  function acceptGovernance() external {
    require(msg.sender == pendingGovernance, "StakingPools: only pending governance");

    address _pendingGovernance = pendingGovernance;
    governance = _pendingGovernance;

    emit GovernanceUpdated(_pendingGovernance);
  }

  /// @dev Sets the distribution reward rate.
  ///
  /// This will update all of the pools.
  ///
  /// @param _rewardRate The number of tokens to distribute per second.
  function setRewardRate(uint256 _rewardRate) external onlyGovernance {
    _updatePools();

    _ctx.rewardRate = _rewardRate;

    emit RewardRateUpdated(_rewardRate);
  }

  /// @dev Creates a new pool.
  function createPool(IERC20 _token, bool _needVesting, uint256 durationInSecs) external onlyGovernance returns (uint256) {
    require(tokenPoolIds[_token] == 0, "StakingPools: token already has a pool");

    uint256 _poolId = _pools.length();

    _pools.push(Pool.Data({
      token: _token,
      totalDeposited: 0,
      rewardWeight: 0,
      accumulatedRewardWeight: FixedPointMath.uq192x64(0),
      lastUpdatedBlock: block.number,
      needVesting: _needVesting,
      vestingDurationInSecs: durationInSecs,
      onReferralBonus: false,
      totalReferralAmount: 0,
      accumulatedReferralWeight: FixedPointMath.uq192x64(0)
    }));

    tokenPoolIds[_token] = _poolId + 1;

    emit PoolCreated(_poolId, _token);

    return _poolId;
  }

  /// @dev Sets the reward weights of all of the pools.
  ///
  /// @param _rewardWeights The reward weights of all of the pools.
  function setRewardWeights(uint256[] calldata _rewardWeights) external onlyGovernance {
    require(_rewardWeights.length == _pools.length(), "StakingPools: weights length mismatch");

    _updatePools();

    uint256 _totalRewardWeight = _ctx.totalRewardWeight;
    for (uint256 _poolId = 0; _poolId < _pools.length(); _poolId++) {
      Pool.Data storage _pool = _pools.get(_poolId);

      uint256 _currentRewardWeight = _pool.rewardWeight;
      if (_currentRewardWeight == _rewardWeights[_poolId]) {
        continue;
      }

      // FIXME
      _totalRewardWeight = _totalRewardWeight.sub(_currentRewardWeight).add(_rewardWeights[_poolId]);
      _pool.rewardWeight = _rewardWeights[_poolId];

      emit PoolRewardWeightUpdated(_poolId, _rewardWeights[_poolId]);
    }

    _ctx.totalRewardWeight = _totalRewardWeight;
  }

  /// @dev Stakes tokens into a pool.
  ///
  /// @param _poolId        the pool to deposit tokens into.
  /// @param _depositAmount the amount of tokens to deposit.
  /// @param referral       the address of referral.
  function deposit(uint256 _poolId, uint256 _depositAmount, address referral) external nonReentrant checkIfNewReferral(_poolId, referral) {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);

    address _referral = myReferral[msg.sender][_poolId];
    if (_pool.onReferralBonus) {
      if (referral != address(0)) {
        require (_referral == address(0) || _referral == referral, "referred already");
        myReferral[msg.sender][_poolId] = referral;
      }

      _referral = myReferral[msg.sender][_poolId];
      if (_referral != address(0)) {
        ReferralPower.Data storage _referralPower = _referralPowers[_referral][_poolId];
        _referralPower.update(_pool, _ctx);
      }
    }

    _deposit(_poolId, _depositAmount, _referral);
  }

  /// @dev Withdraws staked tokens from a pool.
  ///
  /// @param _poolId          The pool to withdraw staked tokens from.
  /// @param _withdrawAmount  The number of tokens to withdraw.
  function withdraw(uint256 _poolId, uint256 _withdrawAmount) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);

    address _referral = _pool.onReferralBonus ? myReferral[msg.sender][_poolId] : address(0);

    if (_pool.onReferralBonus && _referral != address(0)) {
      ReferralPower.Data storage _referralPower = _referralPowers[_referral][_poolId];
      _referralPower.update(_pool, _ctx);
    }

    _claim(_poolId);
    _withdraw(_poolId, _withdrawAmount, _referral);
  }

  /// @dev Claims all rewarded tokens from a pool.
  ///
  /// @param _poolId The pool to claim rewards from.
  ///
  /// @notice use this function to claim the tokens from a corresponding pool by ID.
  function claim(uint256 _poolId) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];

    _stake.update(_pool, _ctx);

    _claim(_poolId);
  }

  /// @dev Claims all rewards from a pool and then withdraws all staked tokens.
  ///
  /// @param _poolId the pool to exit from.
  function exit(uint256 _poolId) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);

    address _referral = _pool.onReferralBonus ? myReferral[msg.sender][_poolId] : address(0);

    if (_pool.onReferralBonus && _referral != address(0)) {
      ReferralPower.Data storage _referralPower = _referralPowers[_referral][_poolId];
      _referralPower.update(_pool, _ctx);
    }

    _claim(_poolId);
    _withdraw(_poolId, _stake.totalDeposited, _referral);
  }

  /// @dev Gets the rate at which tokens are minted to stakers for all pools.
  ///
  /// @return the reward rate.
  function rewardRate() external view returns (uint256) {
    return _ctx.rewardRate;
  }

  /// @dev Gets the total reward weight between all the pools.
  ///
  /// @return the total reward weight.
  function totalRewardWeight() external view returns (uint256) {
    return _ctx.totalRewardWeight;
  }

  /// @dev Gets the number of pools that exist.
  ///
  /// @return the pool count.
  function poolCount() external view returns (uint256) {
    return _pools.length();
  }

  /// @dev Gets the token a pool accepts.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the token.
  function getPoolToken(uint256 _poolId) external view returns (IERC20) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.token;
  }

  /// @dev Gets the total amount of funds staked in a pool.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the total amount of staked or deposited tokens.
  function getPoolTotalDeposited(uint256 _poolId) external view returns (uint256) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.totalDeposited;
  }

  /// @dev Gets the total amount of referreal power in a pool.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the total amount of referreal power in pool.
  function getPoolTotalReferralAmount(uint256 _poolId) external view returns (uint256) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.totalReferralAmount;
  }

  /// @dev Gets the reward weight of a pool which determines how much of the total rewards it receives per block.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the pool reward weight.
  function getPoolRewardWeight(uint256 _poolId) external view returns (uint256) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.rewardWeight;
  }

  /// @dev Gets the amount of tokens per block being distributed to stakers for a pool.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the pool reward rate.
  function getPoolRewardRate(uint256 _poolId) external view returns (uint256) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.getRewardRate(_ctx);
  }

  /// @dev Gets the number of tokens a user has staked into a pool.
  ///
  /// @param _account The account to query.
  /// @param _poolId  the identifier of the pool.
  ///
  /// @return the amount of deposited tokens.
  function getStakeTotalDeposited(address _account, uint256 _poolId) external view returns (uint256) {
    Stake.Data storage _stake = _stakes[_account][_poolId];
    return _stake.totalDeposited;
  }

  /// @dev Gets the number of unclaimed reward tokens a user can claim from a pool.
  ///
  /// @param _account The account to get the unclaimed balance of.
  /// @param _poolId  The pool to check for unclaimed rewards.
  ///
  /// @return the amount of unclaimed reward tokens a user has in a pool.
  function getStakeTotalUnclaimed(address _account, uint256 _poolId) external view returns (uint256) {
    Stake.Data storage _stake = _stakes[_account][_poolId];
    return _stake.getUpdatedTotalUnclaimed(_pools.get(_poolId), _ctx);
  }

  /// @dev Gets address accumulated power.
  ///
  /// @param _referral The referral account to get accumulated power.
  /// @param _poolId  The pool to check for accumulated referral power.
  ///
  /// @return the amount of accumulated power a user has in a pool.
  function getAccumulatedReferralPower(address _referral, uint256 _poolId) external view returns (uint256) {
    ReferralPower.Data storage _referralPower = _referralPowers[_referral][_poolId];
    return _referralPower.getUpdatedTotalReferralPower(_pools.get(_poolId), _ctx);
  }

  /// @dev Gets address of referral address by index
  ///
  /// @param _poolId The pool to get referral address
  /// @param _referralIndex the index to get referral address
  ///
  /// @return the referral address in a specifgic pool with index. 
  function getPoolReferral(uint256 _poolId, uint256 _referralIndex) external view returns (address) {
    return referralList[_poolId][_referralIndex];
  }

  /// @dev Gets addressed of referee referred by a referral
  ///
  /// @param _poolId The pool to get referral address
  /// @param referral the address of referral to find all its referees
  ///
  /// @return the address array of referees
  function getPoolreferee(uint256 _poolId, address referral) external view returns(address[] memory) {
    return myreferees[_poolId][referral];
  }

  /// @dev Updates all of the pools.
  function _updatePools() internal {
    for (uint256 _poolId = 0; _poolId < _pools.length(); _poolId++) {
      Pool.Data storage _pool = _pools.get(_poolId);
      _pool.update(_ctx);
    }
  }

  /// @dev Stakes tokens into a pool.
  ///
  /// The pool and stake MUST be updated before calling this function.
  ///
  /// @param _poolId        the pool to deposit tokens into.
  /// @param _depositAmount the amount of tokens to deposit.
  /// @param _referral      the address of referral.
  function _deposit(uint256 _poolId, uint256 _depositAmount, address _referral) internal {
    Pool.Data storage _pool = _pools.get(_poolId);
    Stake.Data storage _stake = _stakes[msg.sender][_poolId];

    _pool.totalDeposited = _pool.totalDeposited.add(_depositAmount);
    _stake.totalDeposited = _stake.totalDeposited.add(_depositAmount);

    if (_pool.onReferralBonus && _referral != address(0)) {
      ReferralPower.Data storage _referralPower = _referralPowers[_referral][_poolId];
      _pool.totalReferralAmount = _pool.totalReferralAmount.add(_depositAmount);
      _referralPower.totalDeposited = _referralPower.totalDeposited.add(_depositAmount);
    }

    _pool.token.safeTransferFrom(msg.sender, address(this), _depositAmount);

    emit TokensDeposited(msg.sender, _poolId, _depositAmount);
  }

  /// @dev Withdraws staked tokens from a pool.
  ///
  /// The pool and stake MUST be updated before calling this function.
  ///
  /// @param _poolId          The pool to withdraw staked tokens from.
  /// @param _withdrawAmount  The number of tokens to withdraw.
  /// @param _referral        The referral's address for reducing referral power accumulation.
  function _withdraw(uint256 _poolId, uint256 _withdrawAmount, address _referral) internal {
    Pool.Data storage _pool = _pools.get(_poolId);
    Stake.Data storage _stake = _stakes[msg.sender][_poolId];

    _pool.totalDeposited = _pool.totalDeposited.sub(_withdrawAmount);
    _stake.totalDeposited = _stake.totalDeposited.sub(_withdrawAmount);

    if (_pool.onReferralBonus && _referral != address(0)) {
      ReferralPower.Data storage _referralPower = _referralPowers[_referral][_poolId];
      _pool.totalReferralAmount = _pool.totalReferralAmount.sub(_withdrawAmount);
      _referralPower.totalDeposited = _referralPower.totalDeposited.sub(_withdrawAmount);
    }

    _pool.token.safeTransfer(msg.sender, _withdrawAmount);

    emit TokensWithdrawn(msg.sender, _poolId, _withdrawAmount);
  }

  /// @dev Claims all rewarded tokens from a pool.
  ///
  /// The pool and stake MUST be updated before calling this function.
  ///
  /// @param _poolId The pool to claim rewards from.
  ///
  /// @notice use this function to claim the tokens from a corresponding pool by ID.
  function _claim(uint256 _poolId) internal {
    require(!pause, "StakingPools: emergency pause enabled");

    Pool.Data storage _pool = _pools.get(_poolId);
    Stake.Data storage _stake = _stakes[msg.sender][_poolId];

    uint256 _claimAmount = _stake.totalUnclaimed;
    _stake.totalUnclaimed = 0;

    if(_pool.needVesting){
      reward.approve(address(rewardVesting),uint(-1));
      rewardVesting.addEarning(msg.sender, _claimAmount, _pool.vestingDurationInSecs);
    } else {
      reward.safeTransfer(msg.sender, _claimAmount);
    }

    emit TokensClaimed(msg.sender, _poolId, _claimAmount);
  }

  /// @dev Updates the reward vesting contract
  ///
  /// @param _rewardVesting the new reward vesting contract
  function setRewardVesting(IRewardVesting _rewardVesting) external {
    require(pause && (msg.sender == governance || msg.sender == sentinel), "StakingPools: not paused, or not governance or sentinel");
    rewardVesting = _rewardVesting;
    emit RewardVestingUpdated(_rewardVesting);
  }

  /// @dev Sets the address of the sentinel
  ///
  /// @param _sentinel address of the new sentinel
  function setSentinel(address _sentinel) external onlyGovernance {
      require(_sentinel != address(0), "StakingPools: sentinel address cannot be 0x0.");
      sentinel = _sentinel;
      emit SentinelUpdated(_sentinel);
  }

  /// @dev Sets if the contract should enter emergency pause mode.
  ///
  /// There are 2 main reasons to pause:
  ///     1. Need to shut down claims in case of any issues in the reward vesting contract
  ///     2. Need to migrate to a new reward vesting contract
  ///
  /// While this contract is paused, claim is disabled
  ///
  /// @param _pause if the contract should enter emergency pause mode.
  function setPause(bool _pause) external {
      require(msg.sender == governance || msg.sender == sentinel, "StakingPools: !(gov || sentinel)");
      pause = _pause;
      emit PauseUpdated(_pause);
  }

  /// @dev To start referral power calculation for a pool, referral power caculation won't turn on if the onReferralBonus is not set
  ///
  /// @param _poolId the pool to start referral power accumulation
  function startReferralBonus(uint256 _poolId) external {
      require(msg.sender == governance || msg.sender == sentinel, "startReferralBonus: !(gov || sentinel)");
      Pool.Data storage _pool = _pools.get(_poolId);
      require(_pool.onReferralBonus == false, "referral bonus already on");
      _pool.onReferralBonus = true;
  }

  /// @dev To stop referral power calculation for a pool, referral power caculation won't turn on if the onReferralBonus is not set
  ///
  /// @param _poolId the pool to stop referral power accumulation
  function stoptReferralBonus(uint256 _poolId) external {
      require(msg.sender == governance || msg.sender == sentinel, "stoptReferralBonus: !(gov || sentinel)");
      Pool.Data storage _pool = _pools.get(_poolId);
      require(_pool.onReferralBonus == true, "referral not turned on");
      _pool.onReferralBonus = false;
  }
}