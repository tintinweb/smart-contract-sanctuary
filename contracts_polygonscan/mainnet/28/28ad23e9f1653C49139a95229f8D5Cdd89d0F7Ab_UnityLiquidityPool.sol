/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

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

// File: contracts/IRewardDistributionRecipient.sol

pragma solidity 0.8.11;


abstract contract IRewardDistributionRecipient is Ownable {
    //address public rewardDistribution;

    mapping (address => bool) rewardDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;
	function notifyRewardAndAddTime(uint256 reward, uint256 time) external virtual;

    modifier onlyRewardDistribution() {
        require(rewardDistribution[_msgSender()], "Caller is not reward distribution");
        _;
    }

    modifier onlyRewardDistributionOrAccount(address account) {
        require(
            rewardDistribution[_msgSender()] || _msgSender() == account,
            "Caller is not reward distribution or account"
        );
        _;
    }

    function setRewardDistribution(address _rewardDistribution) public onlyOwner {
        rewardDistribution[_rewardDistribution] = true;
    }
}
// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

// File: contracts/Locker.sol



pragma solidity 0.8.11;





contract Locker is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    //	using Address for address;
    IERC20 unity;
    uint256 _initTime;
    uint256 _releaseTime;
    uint256 _initialClaimTime;

    mapping(address => bool) _approved;
    mapping(address => UserInfo) userInfo;

    struct UserInfo {
        uint256 initialTotal; // Doesn't change, used for maths.
        uint256 initialClaimed;
        uint256 initialBalance;
        uint256 lockedBalance;
    }

    constructor(
        address _unity,
        address master,
        address deployer
    ) {
        unity = IERC20(_unity);
        _initTime = block.timestamp;
        _initialClaimTime = _initTime + 30 days;
        _releaseTime = _initTime + 182 days;
        _approved[deployer] = true;
        _approved[_unity] = true;
        _approved[master] = true;
    }

    function releaseTime() external view returns (uint256) {
        return _releaseTime;
    }

    function totalSupply() public view returns (uint256) {
        return unity.balanceOf(address(this));
    }

    function claimable(address account) external view returns (uint256) {
        UserInfo storage user = userInfo[account];
        if (block.timestamp < _releaseTime) return _getAmount(user);

        uint256 total = _getAmount(user).add(user.lockedBalance);
        return total;
    }

    function balanceOf(address account) external view returns (uint256) {
        UserInfo storage user = userInfo[account];
        return user.initialBalance.add(user.lockedBalance);
    }

    function changeInitialClaimTime(uint256 time) external onlyApproved {
        _initialClaimTime = _initTime.add(time);
    }

    function changeReleaseTime(uint256 time) external onlyApproved {
        _releaseTime = _initTime.add(time);
    }

    function addAmountToAccount(address account, uint256 amount)
        external
        onlyApproved
        nonReentrant
    {
        UserInfo storage user = userInfo[account];

        uint256 initialValue = amount.div(3);
        uint256 lockedValue = amount.sub(initialValue);

        user.initialBalance = user.initialBalance.add(initialValue);
        user.initialTotal = user.initialTotal.add(initialValue);
        user.lockedBalance = user.lockedBalance.add(lockedValue);
    }

    function withdraw(address account) external nonReentrant {
        if (block.timestamp < _releaseTime) {
            _withdrawInitial(account);
        } else {
            _withdrawLocked(account);
        }
    }

    modifier onlyApproved() {
        require(_approved[msg.sender], "Not approved for emergency withdrawal");
        _;
    }

    function addEmergencyApproval(address account) external onlyApproved {
        _approved[account] = true;
    }

    /// @dev ONLY FOR EMERGENCY. Emergency withdrawal. for if somebody is unable to claim or something unusual happens.
    function emergencyWithdraw() external onlyApproved returns (bool) {
        uint256 supply = totalSupply();
        return unity.transfer(msg.sender, supply);
    }

    /// @dev Gets the rate at which tokens should be rewarded over the initial period (default: 1 month);
    function _getRate(UserInfo storage user) internal view returns (uint256) {
        uint256 totalTime = _initialClaimTime.sub(_initTime);
        uint256 rate = user.initialTotal.div(totalTime);
        return rate;
    }

    /// @dev Gets the total amount the user should receive during a claim occurring during the initial claim period.
    function _getAmount(UserInfo storage user) internal view returns (uint256) {
        if (block.timestamp >= _initialClaimTime) return user.initialBalance;
        uint256 rate = _getRate(user);
        uint256 difference = block.timestamp.sub(_initTime);
        uint256 adjustedAmount = rate.mul(difference).sub(user.initialClaimed);
        if (adjustedAmount > user.initialBalance) return user.initialBalance;
        return adjustedAmount;
        //return rate.mul(difference);
    }

    /// @dev Internal logic dispersing the alotted initially claimable amount to user.
    function _withdrawInitial(address account) internal {
        UserInfo storage user = userInfo[account];
        if (user.initialBalance == 0) return;

        uint256 amount = _getAmount(user);

        if (amount >= user.initialBalance) {
            amount = user.initialBalance;
        }

        unity.transfer(account, amount);
        user.initialClaimed = user.initialClaimed.add(amount);
        user.initialBalance = user.initialBalance.sub(amount);
    }

    /// @dev This function runs only after the 6 month period has passed.
    function _withdrawLocked(address account) internal {
        UserInfo storage user = userInfo[account];

        if (user.initialBalance > 0) {
            _withdrawInitial(account);
        }

        unity.transfer(account, user.lockedBalance);
        delete userInfo[account];
    }
}

// File: contracts/UnityToken.sol


pragma solidity 0.8.11;







interface IMasterLocker {
	function addLocker(address locker) external;	
	function allLockers() external view returns (address[] memory);
	function lockerByIndex(uint256 index) external view returns (address);
}

interface IPool {
	function notifyRewardAmount(uint256) external;
}

contract UnityToken is Context, IERC20, Ownable {
	using SafeMath for uint256;
	using Address for address;

	mapping(address => bool) private _isBlacklisted;
	mapping(address => bool) private _isExcluded; // This is for pools, lockers, etc. Excludes these addresses from reflection tax;
	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;

	IPool public stakingPool;
	IPool public liquidityPool;
	IMasterLocker public masterLocker;

	uint256 private _totalSupply = 0;
	uint256 private _stakeReflection = 10000;
	uint256 private _liquidityReflection = 10100;

	uint8 private constant _decimals = 18;
	bool internal _reflectionDisabled = true;
	string private constant _name = "Unity";
	string private constant _symbol = "UNITY";

	constructor() {
		_mint(0xC5c0A131303dfAB5fB8bcE3052BaB9326629da3d, 42829546700000000000000000);
	}

	function name() external pure returns (string memory) {
		return _name;
	}

	function symbol() external pure returns (string memory) {
		return _symbol;
	}

	function decimals() external pure returns (uint8) {
		return _decimals;
	}

	function totalSupply() external view override returns (uint256) {
		return _totalSupply;
	}

	function lockerByIndex(uint256 index) external view returns (address) {
		return masterLocker.lockerByIndex(index);
	}

	function lockers() external view returns (address[] memory) {
		return masterLocker.allLockers();
	}

	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	}

	function setStakingPool(address account) external onlyOwner {
		stakingPool = IPool(account);
		_isExcluded[account] = true;
	}

	function setLiquidityPool(address account) external onlyOwner {
		liquidityPool = IPool(account);
		_isExcluded[account] = true;
	}

	function setMasterLocker(address account) external onlyOwner {
		masterLocker = IMasterLocker(account);
		_isExcluded[account] = true;
	}

	function excludeAddress(address toExclude) external onlyOwner {
		_isExcluded[toExclude] = true;
	}

	/// @dev Contingency
	function blacklist(address account) external onlyOwner {
		_isBlacklisted[account] = true;
	}

	function removeBlacklist(address account) external onlyOwner {
		_isBlacklisted[account] = false;
	}

	/// @dev Amount should be ranged between 10001 and 19999, where 10001 = 0.01%, and 19999 = 99.99%
	/// If you want to disable reflection, use switchReflectionState;
	function setStakeReflection(uint256 amount) external onlyOwner {
		require(amount >= 10000, "Amount too low");
		require(amount < 20000, "Amount would be over 100%");
		_stakeReflection = amount;
	}

	/// @dev Amount should be ranged between 10001 and 19999, where 10001 = 0.01% and 19999 = 99.99%
	/// If you want to disable reflection, use switchReflectionState;
	function setLiquidityReflection(uint256 amount) external onlyOwner {
		require(amount >= 10000, "Amount too low.");
		require(amount < 20000, "Amount would be over 100%");
		_liquidityReflection = amount;
	}

	/// @dev Switches reflection state, disabling or enabling reflections.
	function switchReflectionState () external onlyOwner {
		_reflectionDisabled = !_reflectionDisabled;
	}

	/// @dev Deploys a new locker contract. Required for dispersion.
	function deployLocker() external onlyOwner returns (address) {
		Locker locker = new Locker(address(this), msg.sender, address(masterLocker));
		masterLocker.addLocker(address(locker));
		_isExcluded[address(locker)] = true;

		return address(locker);
	}

	/// @dev Disperse unity tokens to holders.
	/// Sends 33% of funds to users, and 66% of funds to the locker contract passed as an argument.
	/// Adds an additional 4% to the total of tokens sent, dispersing 3% to the LP pool, and 1% to the staking pool.
	function disperse(
		address[] calldata addresses,
		uint256[] calldata amounts,
		uint256 totalAmount, // Reduce gas consumption not having to increment amount every iteration.
		address _locker
	) external onlyOwner {
		require(address(stakingPool) != address(0), "Staking pool is not set.");
		require(address(liquidityPool) != address(0), "Liquidity pool is not set.");

		Locker locker = Locker(_locker);

		for (uint16 i = 0; i < addresses.length; i++) {
			_mint(_locker, amounts[i]);
			locker.addAmountToAccount(addresses[i], amounts[i]);
		}

		uint256 liquidityAmount = totalAmount.mul(_liquidityReflection).div(10000).sub(totalAmount);
		uint256 stakeAmount = totalAmount.mul(_stakeReflection).div(10000).sub(totalAmount);

		_mint(address(liquidityPool), liquidityAmount);
		_mint(address(stakingPool), stakeAmount);

		liquidityPool.notifyRewardAmount(liquidityAmount);
		stakingPool.notifyRewardAmount(stakeAmount);
	}

	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		uint256 currentAllowance = _allowances[sender][_msgSender()];
		require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
		unchecked {
			_approve(sender, _msgSender(), currentAllowance - amount);
		}
		_transfer(sender, recipient, amount);

		return true;
	}

	function allowance(address owner, address spender) external view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		uint256 currentAllowance = _allowances[_msgSender()][spender];
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
		unchecked {
			_approve(_msgSender(), spender, currentAllowance - subtractedValue);
		}

		return true;
	}

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

	/// @dev ERC20 standard
	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply += amount;
		_balances[account] += amount;
		emit Transfer(address(0), account, amount);

		_afterTokenTransfer(address(0), account, amount);
	}

	/// @dev Modified _transfer function. Reflection 1% and 3% to staking and liquidity pools respectively.
	/// This can be disabled.
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(!_isBlacklisted[sender], "Sender blacklisted");
		require(!_isBlacklisted[recipient], "Recipient blacklisted");
		//require(recipient != address(0), "ERC20: transfer to the zero address");

		if (recipient == address(0)) {
			return _burn(sender, amount);
		}

		_beforeTokenTransfer(sender, recipient, amount);

		if (_isExcluded[sender]) {
			/// If the sender address is excluded, don't do reflection. 
			/// This applies to the Pool and Lockers by default, since they are added to this list when added or deployed by this contract
			_transferStandard(sender, recipient, amount);
		} else if (_isExcluded[recipient]) {
			/// If recipient address is excluded, don't do reflection. 
			/// This applies to the Pool and Lockers by default, since they are added to this list when added or deployed by this contract
			_transferStandard(sender, recipient, amount);
		} else if (_reflectionDisabled) {
			_transferStandard(sender, recipient, amount);
		} else {
			_transferWithReflection(sender, recipient, amount);
		}

		_afterTokenTransfer(sender, recipient, amount);
	}

	/// @dev This is the standardized ERC20 transfer.
	function _transferStandard(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		uint256 senderBalance = _balances[sender];
		require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

		unchecked {
			_balances[sender] = senderBalance - amount;
		}

		_balances[recipient] += amount;

		emit Transfer(sender, recipient, amount);
	}

	/// @dev This sends 1% and 3% of the funds to staking and liquidity pool respectively;
	function _transferWithReflection(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		uint256 senderBalance = _balances[sender];
		(uint256 newAmount, uint256 toLiquidity, uint256 toStake) = _getReflectAmounts(amount);
		require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

		unchecked {
			_balances[sender] = senderBalance - amount;
		}

		_balances[recipient] += newAmount;
		_balances[address(liquidityPool)] += toLiquidity;
		_balances[address(stakingPool)] += toStake;

		emit Transfer(sender, recipient, amount);
	}

	/// @dev Calculates reflection amounts. Deducts 4% from total transferred funds and sends 3% to liquidity pool, 1% to staking pool.
	function _getReflectAmounts(uint256 amount)
		internal
		view
		returns (
			uint256,
			uint256,
			uint256
		)
	{
		uint256 toStake = amount.mul(_stakeReflection).div(10000).sub(amount);
		uint256 toLiquidity = amount.mul(_liquidityReflection).div(10000).sub(amount);
		uint256 afterTax = amount.sub(toStake).sub(toLiquidity);
		require(toStake + toLiquidity + afterTax == amount, "Amounts don't add up");
		return (afterTax, toLiquidity, toStake);
	}

	/// @dev ERC20 standard burn.
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

// File: contracts/Libraries/SafeMathWithRequire.sol

pragma solidity 0.8.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert
 */
library SafeMathWithRequire {
    using SafeMath for uint256;

    uint256 private constant DECIMALS_18 = 1000000000000000000;
    uint256 private constant DECIMALS_12 = 1000000000000;
    uint256 private constant DECIMALS_9 = 1000000000;
    uint256 private constant DECIMALS_6 = 1000000;

    function sqrt6(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_12);
        uint256 tmp = a.add(1) / 2;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            tmp = ((a / tmp) + tmp) / 2;
        }
    }

    function sqrt3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_6);
        uint256 tmp = a.add(1) / 2;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            tmp = ((a / tmp) + tmp) / 2;
        }
    }

    function cbrt6(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_18);
        uint256 tmp = a.add(2) / 3;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpSquare = tmp**2;
            require(tmpSquare > tmp, "overflow");
            tmp = ((a / tmpSquare) + (tmp * 2)) / 3;
        }
        return c;
    }

    function cbrt3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_9);
        uint256 tmp = a.add(2) / 3;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpSquare = tmp**2;
            require(tmpSquare > tmp, "overflow");
            tmp = ((a / tmpSquare) + (tmp * 2)) / 3;
        }
        return c;
    }
}
// File: contracts/UnityLiquidityPool.sol



pragma solidity 0.8.11;









contract UnityPoolWrapper is Ownable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	IERC20 _lpToken;

	uint256 internal constant DECIMALS_18 = 1000000000000000000;
	uint256 public _taxTime = 182 days;
	uint256 private _tax = 0; // 0%
	uint256 private _totalSupply;
	uint256 private _rewardSupply;

	mapping(address => uint256) userStartTime;

	mapping(address => uint256) private _balances;

	constructor(IERC20 lpToken) {
		_lpToken = lpToken;
	}

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function rewardSupply() public view returns (uint256) {
		return _rewardSupply;
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	function stake(uint256 amount) public virtual {
		_totalSupply = _totalSupply.add(amount);
		_balances[msg.sender] = _balances[msg.sender].add(amount);
		_lpToken.safeTransferFrom(msg.sender, address(this), amount);
	}

	function withdraw(uint256 amount) public virtual {
		require(_balances[msg.sender] >= amount, "Withdrawing too much");

		_totalSupply = _totalSupply.sub(amount);
		_balances[msg.sender] = _balances[msg.sender].sub(amount);

		_lpToken.safeTransfer(msg.sender, amount);
	}

	function _addReward(uint256 amount) internal {
		_rewardSupply = _rewardSupply.add(amount);
	}

	function _subReward(uint256 amount) internal {
		_rewardSupply = _rewardSupply.sub(amount);
	}
}

contract UnityLiquidityPool is UnityPoolWrapper, IRewardDistributionRecipient, ReentrancyGuard {
	using SafeMath for uint256;
	using SafeMathWithRequire for uint256;
	using SafeERC20 for IERC20;
	using Address for address;

	event RewardAdded(uint256 reward);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RewardPaid(address indexed user, uint256 reward);

	uint256 public immutable duration;

	uint256 public periodFinish = 0;
	uint256 public rewardRate = 0;
	uint256 public lastUpdateTime;
	uint256 public rewardPerTokenStored;
	mapping(address => uint256) public userRewardPerTokenPaid;
	mapping(address => uint256) public rewards;

	uint256 internal constant DECIMALS_9 = 1000000000;
	uint256 internal constant MIDPOINT_9 = 500000000;
	uint256 internal withdrawFee = 1000;
	uint256 internal constant ROOT3_FACTOR = 697;

	IERC20 internal _unityToken;

	uint256 internal _totalContributions;
	mapping(address => uint256) internal _contributions;

	constructor(
		IERC20 lpToken,
		address unityToken,
		uint256 rewardDuration
	) UnityPoolWrapper(lpToken) {
		_unityToken = IERC20(unityToken);
		duration = rewardDuration;
		setRewardDistribution(msg.sender);
		setRewardDistribution(unityToken);
	}

	function totalContributions() public view returns (uint256) {
		return _totalContributions;
	}

	function contributionOf(address account) public view returns (uint256) {
		return _contributions[account];
	}

	modifier updateReward(address account) {
		rewardPerTokenStored = rewardPerToken();

		if (block.timestamp >= periodFinish || _totalContributions != 0) {
			// ensure reward past the first staker do not get lost
			lastUpdateTime = lastTimeRewardApplicable();
		}
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
		if (totalContributions() == 0) {
			return rewardPerTokenStored;
		}
		return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e24).div(totalContributions()));
	}

	function earned(address account) public view returns (uint256) {
		return contributionOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e24).add(rewards[account]);
	}

	function updateContribution(address account) internal {
		_totalContributions = _totalContributions.sub(contributionOf(account));

		uint256 contribution = balanceOf(account);

		_totalContributions = _totalContributions.add(contribution);
		_contributions[account] = contribution;
	}

	function stake(uint256 amount) public override nonReentrant updateReward(msg.sender) {
		require(amount > 0, "Cannot stake 0");
		super.stake(amount);

		if (userStartTime[msg.sender] == 0) {
			userStartTime[msg.sender] = block.timestamp;
		}

		updateContribution(msg.sender);
		emit Staked(msg.sender, amount);
	}

	function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
		require(amount > 0, "Cannot withdraw 0");

		super.withdraw(amount);

		if (balanceOf(msg.sender) == 0) {
			userStartTime[msg.sender] = 0;
		}

		updateContribution(msg.sender);

		emit Withdrawn(msg.sender, amount);
	}

	function exit() external {
		withdraw(balanceOf(msg.sender));
		userStartTime[msg.sender] = block.timestamp;
		getReward();
	}

	function getReward() public nonReentrant updateReward(msg.sender) {
		uint256 reward = rewards[msg.sender];
		if (reward > 0) {
			rewards[msg.sender] = 0;
			_subReward(reward);
			_unityToken.safeTransfer(msg.sender, reward);
			emit RewardPaid(msg.sender, reward);
		}
	}

	/// @notice to be called after the amount of reward tokens (specified by the reward parameter) has been sent to the contract
	/// that the reward should be divisible by the duration to avoid reward token lost
	/// @param reward number of token to be distributed over the duration
	function notifyRewardAmount(uint256 reward) external override onlyRewardDistribution updateReward(address(0)) {
		if (block.timestamp >= periodFinish) {
			rewardRate = reward.div(duration);
		} else {
			uint256 remaining = periodFinish.sub(block.timestamp);
			uint256 leftover = remaining.mul(rewardRate);
			rewardRate = reward.add(leftover).div(duration);
		}
		_addReward(reward);
		lastUpdateTime = block.timestamp;
		periodFinish = block.timestamp.add(duration);
		emit RewardAdded(reward);
	}

	function notifyRewardAndAddTime(uint256 reward, uint256 time) external override onlyRewardDistribution updateReward(address(0)) {
		if (block.timestamp >= periodFinish) {
			lastUpdateTime = block.timestamp;
			periodFinish = block.timestamp.add(time);
			rewardRate = reward.div(time);
		} else {
			uint256 remainingTime = periodFinish.sub(block.timestamp);
			uint256 leftoverFunds = remainingTime.mul(rewardRate);

			_addReward(reward);
			lastUpdateTime = block.timestamp;
			periodFinish = periodFinish.add(time);
			rewardRate = reward.add(leftoverFunds).div(periodFinish.sub(block.timestamp));
		}
		emit RewardAdded(reward);
	}

	// Add Setter functions for every external contract

	function SetRewardToken(address newRewardToken) external onlyOwner {
		require(newRewardToken.isContract(), "Bad RewardToken address");

		_unityToken = IERC20(newRewardToken);
	}

	function SetStakeLPToken(address newStakeLPToken) external onlyOwner {
		require(newStakeLPToken.isContract(), "Bad StakeToken address");

		_lpToken = IERC20(newStakeLPToken);
	}
}