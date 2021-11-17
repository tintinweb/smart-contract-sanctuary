/**
 *Submitted for verification at polygonscan.com on 2021-11-16
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/math/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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


// File contracts/IRewardDistributionRecipient.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

abstract contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        public
        /* external */
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}


// File @openzeppelin/contracts/math/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;



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


// File contracts/interfaces/IEmiswap.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.2;

interface IEmiswapRegistry {
    function pools(IERC20 token1, IERC20 token2) external view returns (IEmiswap);

    function isPool(address addr) external view returns (bool);

    function deploy(IERC20 tokenA, IERC20 tokenB) external returns (IEmiswap);

    function getAllPools() external view returns (IEmiswap[] memory);
}

interface IEmiswap {
    function fee() external view returns (uint256);

    function tokens(uint256 i) external view returns (IERC20);

    function deposit(
        uint256[] calldata amounts,
        uint256[] calldata minAmounts,
        address referral
    ) external payable returns (uint256 fairSupply);

    function withdraw(uint256 amount, uint256[] calldata minReturns) external;

    function getBalanceForAddition(IERC20 token) external view returns (uint256);

    function getBalanceForRemoval(IERC20 token) external view returns (uint256);

    function getReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) external view returns (uint256, uint256);

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        address to,
        address referral
    ) external payable returns (uint256 returnAmount);

    function initialize(IERC20[] calldata assets) external;
}


// File contracts/libraries/EmiswapLib.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.2;



library EmiswapLib {
    using SafeMath for uint256;
    uint256 public constant FEE_DENOMINATOR = 1e18;

    function previewSwapExactTokenForToken(
        address factory,
        address tokenFrom,
        address tokenTo,
        uint256 ammountFrom
    ) internal view returns (uint256 ammountTo) {
        IEmiswap pairContract = IEmiswapRegistry(factory).pools(IERC20(tokenFrom), IERC20(tokenTo));

        if (pairContract != IEmiswap(0)) {
            (, ammountTo) = pairContract.getReturn(IERC20(tokenFrom), IERC20(tokenTo), ammountFrom);
        }
    }

    /**************************************************************************************
     * get preview result of virtual swap by route of tokens
     **************************************************************************************/
    function previewSwapbyRoute(
        address factory,
        address[] memory path,
        uint256 ammountFrom
    ) internal view returns (uint256 ammountTo) {
        for (uint256 i = 0; i < path.length - 1; i++) {
            if (path.length >= 2) {
                ammountTo = previewSwapExactTokenForToken(factory, path[i], path[i + 1], ammountFrom);

                if (i == (path.length - 2)) {
                    return (ammountTo);
                } else {
                    ammountFrom = ammountTo;
                }
            }
        }
    }

    function fee(address factory) internal view returns (uint256) {
        return IEmiswap(factory).fee();
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        address factory,
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view returns (uint256 amountIn) {
        require(amountOut > 0, "EmiswapLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "EmiswapLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(uint256(1000000000000000000).sub(fee(factory)).div(1e15)); // 997
        amountIn = (numerator / denominator).add(1);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        address factory,
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view returns (uint256 amountOut) {
        if (amountIn == 0 || reserveIn == 0 || reserveOut == 0) {
            return (0);
        }

        uint256 amountInWithFee = amountIn.mul(uint256(1000000000000000000).sub(fee(factory)).div(1e15)); //997
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = (denominator == 0 ? 0 : amountOut = numerator / denominator);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "EmiswapLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            IEmiswap pairContract = IEmiswapRegistry(factory).pools(IERC20(IERC20(path[i])), IERC20(path[i - 1]));

            uint256 reserveIn;
            uint256 reserveOut;

            if (address(pairContract) != address(0)) {
                reserveIn = IEmiswap(pairContract).getBalanceForAddition(IERC20(path[i - 1]));
                reserveOut = IEmiswap(pairContract).getBalanceForRemoval(IERC20(path[i]));
            }

            amounts[i - 1] = getAmountIn(factory, amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "EmiswapLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i = 0; i < path.length - 1; i++) {
            IEmiswap pairContract = IEmiswapRegistry(factory).pools(IERC20(IERC20(path[i])), IERC20(path[i + 1]));

            uint256 reserveIn;
            uint256 reserveOut;

            if (address(pairContract) != address(0)) {
                reserveIn = IEmiswap(pairContract).getBalanceForAddition(IERC20(path[i]));
                reserveOut = IEmiswap(pairContract).getBalanceForRemoval(IERC20(path[i + 1]));
            }

            amounts[i + 1] = getAmountOut(factory, amounts[i], reserveIn, reserveOut);
        }
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "EmiswapLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "EmiswapLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }
}


// File contracts/LPTokenWrapper.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

//import "hardhat/console.sol";





interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);
}

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // minimal time to be passed from wallet first stake to allow exit
    uint256 public exitTimeOut = 30 days;

    mapping(address => uint256) public exitLimits;

    // Stable coin
    address public stableCoin;

    // path to stable on Emiswap dex
    struct path {
        address[] route;
        bool isActive;
    }

    // Routs to stable coin
    path[] public routeToStable;

    // save hash of path to check unique
    mapping(bytes32 => bool) public availableRoutes;

    // EmiFactory
    IEmiswapRegistry public emiFactory;

    // is the main token (ESW)
    address public stakeToken;

    // main token (ESW) supply
    uint256 private _totalSupply;

    // wallet -> lp -> amount
    mapping(address => mapping(address => uint256)) private _balances;

    // 0 means the token address is not in the array
    mapping(address => uint256) internal tokensIndex;
    // used stake tokens
    address[] public stakeTokens;

    event Staked(address indexed user, address lp, uint256 lpAmount, uint256 amount);

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOfStakeToken(address account) public view returns (uint256) {
        return _balances[account][stakeToken];
    }

    function balanceOfLPToken(address account, address lp) public view returns (uint256) {
        return _balances[account][lp];
    }

    /**
     * @dev admin function to setup price routes to the "stableCoin"
     * @param route - route must ends with "stableCoin", and can consist only of 1 element - "stableCoin"
     */

    function addRoutes(address[] memory route) public virtual {
        require(route.length > 0 && route[route.length - 1] == stableCoin, "set route to stable");
        require(!availableRoutes[keccak256(abi.encodePacked(route))], "route already added");
        availableRoutes[keccak256(abi.encodePacked(route))] = true;
        routeToStable.push(path(route, true));
    }

    /**
     * @dev activate/deactivate route
     * @param _route array of tokens
     * @param _isActive change to true/false enable/disable
     */

    function activationRoute(address[] memory _route, bool _isActive) public virtual {
        for (uint256 index = 0; index < routeToStable.length; index++) {
            if (
                keccak256(abi.encodePacked(routeToStable[index].route)) == keccak256(abi.encodePacked(_route)) &&
                routeToStable[index].isActive != _isActive
            ) {
                routeToStable[index].isActive = _isActive;
                return;
            }
        }
    }

    /**
     * @dev get route info
     * @param _route input route
     * @return routeRes stored route if found
     * @return isActiveRes is active flag
     */

    function getRoute(address[] memory _route) public view returns (address[] memory routeRes, bool isActiveRes) {
        for (uint256 index = 0; index < routeToStable.length; index++) {
            if (keccak256(abi.encodePacked(routeToStable[index].route)) == keccak256(abi.encodePacked(_route))) {
                routeRes = routeToStable[index].route;
                isActiveRes = routeToStable[index].isActive;
            }
        }
    }

    /**
     * @dev stake two tokens: lp and stake token (esw)
     * @param lp lp token address
     * @param lpAmount lp token amount
     * @param amountMax stake token maximum amount to take in
     */

    function stake(
        address lp,
        uint256 lpAmount,
        uint256 amountMax
    ) public virtual {
        require(emiFactory.isPool(lp), "token incorrect or not LP");

        // calc needful stake token amount
        uint256 stakeTokenAmount = getStakeValuebyLP(lp, lpAmount);
        require(stakeTokenAmount > 0 && stakeTokenAmount <= amountMax, "not enough stake token amount");

        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), stakeTokenAmount);
        IERC20(lp).safeTransferFrom(msg.sender, address(this), lpAmount);

        // incease total supply in stake token
        _totalSupply = _totalSupply.add(stakeTokenAmount);

        // set balances
        _balances[msg.sender][stakeToken] = _balances[msg.sender][stakeToken].add(stakeTokenAmount);
        _balances[msg.sender][lp] = _balances[msg.sender][lp].add(lpAmount);
        // save lp token stake, and also stakeToken by default
        if (tokensIndex[lp] == 0) {
            stakeTokens.push(lp);
            tokensIndex[lp] = stakeTokens.length;
        }
        // if first stake, save exit timeout
        if (exitLimits[msg.sender] == 0) {
            exitLimits[msg.sender] = block.timestamp + exitTimeOut;
        }
        emit Staked(msg.sender, lp, lpAmount, stakeTokenAmount);
    }

    /**
     * @dev calcilate stake value from LP token amount
     * @param _lp LP token address
     * @param _lpAmount LP token amount
     * @return  stakeValue LP amount value nominated in stake tokens
     */

    function getStakeValuebyLP(address _lp, uint256 _lpAmount) public view returns (uint256 stakeValue) {
        uint256 lpInStable = getLPValueInStable(_lp, _lpAmount);
        uint256 stakeTokenPrice = getTokenPrice(stakeToken);
        uint256 oneStakeTokenValue = 10**uint256(IERC20Extented(stakeToken).decimals());
        stakeValue = oneStakeTokenValue.mul(lpInStable).div(stakeTokenPrice);
    }

    /**
     * @dev calcilate LP value from stake token amount, function is reverse to getStakeValuebyLP
     * @param _lp LP token address
     * @param _amount stake token amount
     * @return lpValue stake amount value nominated in LP tokens
     */

    function getLPValuebyStake(address _lp, uint256 _amount) public view returns (uint256 lpValue) {
        uint256 oneLpAmount = 10**uint256(IERC20Extented(_lp).decimals());
        uint256 oneStakeToken = 10**uint256(IERC20Extented(stakeToken).decimals());
        uint256 oneLPInStable = getLPValueInStable(_lp, oneLpAmount);
        uint256 stakeTokenValueinStable = _amount.mul(getTokenPrice(stakeToken)).div(oneStakeToken);
        lpValue = oneLpAmount.mul(stakeTokenValueinStable).div(oneLPInStable);
    }

    /**
     * @dev get LP value in stable coins
     * @param _lp lp address
     * @param _lpAmount lp tokens amount
     */

    function getLPValueInStable(address _lp, uint256 _lpAmount) public view returns (uint256 lpValueInStable) {
        for (uint256 i = 0; i <= 1; i++) {
            address componentToken = address(IEmiswap(_lp).tokens(i));
            uint256 oneTokenValue = 10**uint256(IERC20Extented(componentToken).decimals());
            uint256 tokenPrice = getTokenPrice(componentToken);
            uint256 tokensInLP = getTokenAmountinLP(_lp, _lpAmount, componentToken);
            // calc token value from one of parts and multiply 2
            lpValueInStable = tokensInLP.mul(tokenPrice).mul(2).div(oneTokenValue);
            if (lpValueInStable > 0) {
                break;
            }
        }
    }

    /**
     * @dev get token price using existing token routes
     * @param token address of token
     */
    function getTokenPrice(address token) public view returns (uint256 tokenPrice) {
        require(IERC20Extented(token).decimals() > 0, "token must have decimals");
        uint256 oneTokenValue = 10**uint256(IERC20Extented(token).decimals());

        // go throuout all path and find minimal token price > 0
        for (uint256 i = 0; i < routeToStable.length; i++) {
            if (routeToStable[i].isActive) {
                // route must not contain token
                bool skipRoute;
                for (uint256 k = 0; k < routeToStable[i].route.length; k++) {
                    if (routeToStable[i].route[k] == token) {
                        skipRoute = true;
                        break;
                    }
                }
                if (skipRoute) {
                    break;
                }

                // prepare route to get price from token
                address[] memory route = new address[](routeToStable[i].route.length + 1);
                route[0] = token;
                for (uint256 j = 1; j < route.length; j++) {
                    route[j] = routeToStable[i].route[j - 1];
                }

                // get price by route
                uint256 _price = EmiswapLib.getAmountsOut(address(emiFactory), oneTokenValue, route)[route.length - 1];

                // choose minimum not zero price
                if (tokenPrice == 0) {
                    tokenPrice = _price;
                } else {
                    if (_price > 0 && _price < tokenPrice) {
                        tokenPrice = _price;
                    }
                }
            }
        }
    }

    /**
     * @dev get component token amount in passed amount of LP token
     * @param lp addres of LP token
     * @param lpAmount amount of LP token
     * @param component component token address (of LP)
     */
    function getTokenAmountinLP(
        address lp,
        uint256 lpAmount,
        address component
    ) public view returns (uint256 tokenAmount) {
        tokenAmount = IERC20(component).balanceOf(lp).mul(lpAmount).div(IERC20(lp).totalSupply());
    }

    /**
     * @dev get staked tokens by wallet
     * @param wallet address
     * @return tokens list of staked tokens
     */

    function getStakedTokens(address wallet) public view returns (address[] memory tokens) {
        if (wallet == address(0)) {
            return (stakeTokens);
        } else {
            // calc elems
            uint8 count;
            for (uint256 index = 0; index < stakeTokens.length; index++) {
                if (_balances[wallet][stakeTokens[index]] > 0) {
                    count++;
                }
            }
            // get token adresses
            address[] memory _tokens = new address[](count);
            for (uint256 index = stakeTokens.length; index > 0; index--) {
                if (_balances[wallet][stakeTokens[index - 1]] > 0) {
                    _tokens[count - 1] = stakeTokens[index - 1];
                    count--;
                }
            }
            return (_tokens);
        }
    }

    /**
     * @dev withdraw all staked tokens at once and reset exit date limits
     */

    function withdraw() internal virtual {
        uint256 amount = _balances[msg.sender][stakeToken];

        // set balances
        _totalSupply = _totalSupply.sub(amount);

        for (uint256 index = 0; index < stakeTokens.length; index++) {
            IERC20(stakeTokens[index]).safeTransfer(msg.sender, _balances[msg.sender][stakeTokens[index]]);
            _balances[msg.sender][stakeTokens[index]] = 0;
        }

        // reset exit date limits
        exitLimits[msg.sender] = 0;
    }
}


// File contracts/RewardPoolMulti.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;





contract RewardPoolMulti is LPTokenWrapper, IRewardDistributionRecipient, ReentrancyGuard {
    uint256 public totalStakeLimit; // max value in USD coin (last in route), rememeber decimals!
    address[] public route;

    IERC20 public rewardToken;
    uint256 public duration = 90 days;

    uint256 public periodFinish = 0;
    uint256 public periodStop = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    /**
     * @dev seting main farming config
     * @param _rewardToken reward token, staketokeStakedss
     * @param _stableCoin stable token contract addres
     * @param _duration farming duration from start
     * @param _exitTimeOut exit and withdraw stakes allowed only when time passed from first wallet stake
     */

    constructor(
        address _rewardToken,
        address _rewardAdmin,
        address _emiFactory,
        address _stableCoin,
        uint256 _duration,
        uint256 _exitTimeOut
    ) public {
        rewardToken = IERC20(_rewardToken);
        stakeToken = _rewardToken;
        setRewardDistribution(_rewardAdmin);
        stakeTokens.push(_rewardToken);
        emiFactory = IEmiswapRegistry(_emiFactory);
        stableCoin = _stableCoin;
        duration = _duration;
        exitTimeOut = _exitTimeOut;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOfStakeToken(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(
                rewards[account]
            );
    }

    /**
     * @dev stake function, starts farming on stale, user stake two tokens: "Emiswap LP" + "ESW"
     * @param lp address of Emiswap LP token
     * @param lpAmount amount of Emiswap LP tokens
     * @param amount stake token maximum amount to take in
     */

    function stake(
        address lp,
        uint256 lpAmount,
        uint256 amount
    ) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        require(block.timestamp <= periodFinish && block.timestamp <= periodStop, "Cannot stake yet");
        super.stake(lp, lpAmount, amount);
    }

    // TODO: т.к. общая ставка это ESW и множество LP то для простоты вывод делается только польностью
    function withdrawAll() internal nonReentrant updateReward(msg.sender) {
        require(balanceOfStakeToken(msg.sender) > 0, "no balance");
        super.withdraw();
        emit Withdrawn(msg.sender, balanceOfStakeToken(msg.sender));
    }

    function exit() external {
        withdrawAll();
        getReward();
    }

    function getReward() internal nonReentrant updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // use it after create and approve of reward token

    function notifyRewardAmount(uint256 reward) external override onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        periodStop = periodFinish;
        rewardToken.safeTransferFrom(msg.sender, address(this), reward);
        emit RewardAdded(reward);
    }

    function addRoutes(address[] memory _route) public override onlyOwner {
        super.addRoutes(_route);
    }

    function activationRoute(address[] memory _route, bool _isActive) public override onlyOwner {
        super.activationRoute(_route, _isActive);
    }

    function setPeriodStop(uint256 _periodStop) external onlyRewardDistribution {
        require(periodStop <= periodFinish, "Incorrect stop");
        periodStop = _periodStop;
    }

    /**
     * @dev get staked values nominated in stable coin for the wallet and for all
     * @param wallet wallet for getting staked value
     * @return senderStake staked value for the wallet
     * @return totalStake staked value for all wallet on the contract
     */
    function getStakedValuesinUSD(address wallet) public view returns (uint256 senderStake, uint256 totalStake) {
        uint256 oneStakeToken = 10**uint256(IERC20Extented(stakeToken).decimals());
        senderStake = balanceOfStakeToken(wallet).mul(getTokenPrice(stakeToken)).div(oneStakeToken);
        totalStake = totalSupply().mul(getTokenPrice(stakeToken)).div(oneStakeToken);
    }

    function getAmountOut(uint256 amountIn, address[] memory path) public view returns (uint256) {
        return EmiswapLib.getAmountsOut(address(emiFactory), amountIn, path)[path.length - 1];
    }

    // ------------------------------------------------------------------------
    //
    // ------------------------------------------------------------------------
    /**
     * @dev Owner can transfer out any accidentally sent ERC20 tokens
     * @param tokenAddress Address of ERC-20 token to transfer
     * @param beneficiary Address to transfer to
     * @param amount of tokens to transfer
     */
    function transferAnyERC20Token(
        address tokenAddress,
        address beneficiary,
        uint256 amount
    ) public onlyOwner returns (bool success) {
        require(tokenAddress != address(0), "address 0!");
        require(tokenAddress != address(stakeToken), "not staketoken");

        return IERC20(tokenAddress).transfer(beneficiary, amount);
    }
}