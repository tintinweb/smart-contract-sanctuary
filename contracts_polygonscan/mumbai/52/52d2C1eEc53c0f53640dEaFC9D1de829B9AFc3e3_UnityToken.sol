/**
 *Submitted for verification at polygonscan.com on 2021-12-31
*/

// SPDX-License-Identifier: MIT


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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/Locker.sol



pragma solidity 0.8.10;




contract Locker is ReentrancyGuard {
	using SafeERC20 for IERC20;
	IERC20 unity;
	uint256 _initTime;
	uint256 _releaseTime;
	mapping(address => uint256) _balances;
	mapping(address => bool) _approved;

	constructor(address _unity, address deployer) {
		unity = IERC20(_unity);
		_initTime = block.timestamp;
		_releaseTime = _initTime + 182 days;
		_approved[deployer] = true;
		_approved[_unity] = true;
	}

	function releaseTime() external view returns (uint256) {
		return _releaseTime;
	}

	function totalSupply() public view returns (uint256) {
		return unity.balanceOf(address(this));
	}

	function claimable() external view returns (uint256) {
		return _balances[msg.sender];
	}

	function balanceOf(address account) external view returns (uint256) {
		return _balances[account];
	}

	function addAmountToAccount(address account, uint256 amount) external onlyApproved nonReentrant {
		_balances[account] = amount;
	}

	function withdraw() external nonReentrant returns (bool) {
		require(block.timestamp >= _releaseTime, "It's too early to claim this");
		require(msg.sender == tx.origin, "Contracts cannot call this function");
		uint256 userShare = _balances[msg.sender];
		require(userShare > 0, "There are no tokens available for you.");

		delete _balances[msg.sender];
		return unity.transfer(msg.sender, userShare);
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
}

// File: contracts/UnityToken.sol


pragma solidity 0.8.10;







contract UnityToken is Context, IERC20, Ownable {
	using SafeMath for uint256;
	using Address for address;

	mapping(address => bool) private _isExcluded;
	mapping(address => bool) private _isLockerOrPool;
	mapping(address => mapping(address => uint256)) private _allowances;
	mapping(address => uint256) private reflectionOwned;
	mapping(address => uint256) private tokensOwned;

	// Delayed dispersion, staking, and LP Pools stored by index.
	address[] private _excluded;
	address[] private _monthlyLockers;

	uint256 private constant MAX = ~uint256(0);
	uint256 private _tokenTotal = 1_000_000_000 * 10**18;        /// For testing
	uint256 private _reflectTotal = (MAX - (MAX % _tokenTotal));
	uint256 private _tFeeTotal;

	string private constant _name = "Unity";
	string private constant _symbol = "UNITY";
	uint8 private constant _decimals = 18;

	constructor() {
                /// For testing
		reflectionOwned[_msgSender()] = _reflectTotal;
		emit Transfer(address(0), _msgSender(), _tokenTotal);
	}

	//// UI testing function, this will be removed upon deployment. Specifically for people trying to test Unity Token.
	function test() external {
		_mint(msg.sender, 1e24);
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
		return _tokenTotal;
	}

	function lockerByIndex(uint256 index) external view returns (address) {
		return _monthlyLockers[index];
	}

	function lockers() external view returns (address[] memory) {
		return _monthlyLockers;
	}

	function isExcluded(address account) external view returns (bool) {
		return _isExcluded[account];
	}

	function totalFees() external view returns (uint256) {
		return _tFeeTotal;
	}

	function balanceOf(address account) external view override returns (uint256) {
		if (_isExcluded[account]) return tokensOwned[account];
		return tokenFromReflection(reflectionOwned[account]);
	}

	function approve(address spender, uint256 amount) external override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function allowance(address owner, address spender) external view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

	/// @dev Deploys a new locker contract.
	function deployLocker() external onlyOwner returns (address) {
		Locker locker = new Locker(address(this), msg.sender);
		_monthlyLockers.push(address(locker));
		_isLockerOrPool[address(locker)] = true;

		return address(locker);
	}

	function addPool(address pool) external onlyOwner {
		_isLockerOrPool[pool] = true;
	}

	function disperse(
		address[] calldata addresses,
		uint256[] calldata amounts,
		address _locker
	) external onlyOwner {
		Locker locker = Locker(_locker);
		for (uint16 i = 0; i < addresses.length; i++) {
			// Mint each address the corresponding amount in the amounts array.
			uint256 userShare = amounts[i].mul(1e18).div(3).div(1e18);
			_mint(addresses[i], userShare);
			_mintToLocker(_locker, amounts[i].sub(userShare));
			locker.addAmountToAccount(addresses[i], amounts[i].sub(userShare));
		}
	}

	function tokenFromReflection(uint256 reflectAmount) public view returns (uint256) {
		require(reflectAmount <= _reflectTotal, "Amount must be less than total reflections");
		uint256 currentRate = _getRate();
		return reflectAmount.div(currentRate);
	}

	function excludeAccount(address account) external onlyOwner {
		require(!_isExcluded[account], "Account is already excluded");
		if (reflectionOwned[account] > 0) {
			tokensOwned[account] = tokenFromReflection(reflectionOwned[account]);
		}
		_isExcluded[account] = true;
		_excluded.push(account);
	}

	function includeAccount(address account) external onlyOwner {
		require(_isExcluded[account], "Account is already excluded");
		for (uint256 i = 0; i < _excluded.length; i++) {
			if (_excluded[i] == account) {
				_excluded[i] = _excluded[_excluded.length - 1];
				tokensOwned[account] = 0;
				_isExcluded[account] = false;
				_excluded.pop();
				break;
			}
		}
	}

	function _approve(
		address owner,
		address spender,
		uint256 amount
	) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/// @dev Specialized mint function for dispersion. This avoids reflections.
	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		uint256 reflectAmount = amount.mul(_getRate());

		reflectionOwned[account] = reflectionOwned[account].add(reflectAmount);

		emit Transfer(address(0), account, amount);
	}

	/// @dev Specific mint function for locker.
	/// This avoids reflecting when minting to the locker and uses a static token number, which isn't influenced by reflect.
	function _mintToLocker(address account, uint256 amount) internal {
		require(account != address(0), "ERC20: mint to the zero address");

		uint256 reflectAmount = amount.mul(_getRate());

		tokensOwned[account] = tokensOwned[account].add(amount);
		reflectionOwned[account] = reflectionOwned[account].add(reflectAmount);

		emit Transfer(address(0), account, amount);
	}

	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) private {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		if (_isLockerOrPool[sender]) {
			_transferFromLockerOrPool(sender, recipient, amount);
		} else if (_isExcluded[sender] && !_isExcluded[recipient]) {
			_transferFromExcluded(sender, recipient, amount);
		} else if (!_isExcluded[sender] && _isExcluded[recipient]) {
			_transferToExcluded(sender, recipient, amount);
		} else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
			_transferStandard(sender, recipient, amount);
		} else if (_isExcluded[sender] && _isExcluded[recipient]) {
			_transferBothExcluded(sender, recipient, amount);
		} else {
			_transferStandard(sender, recipient, amount);
		}
	}

	/// @dev Specialized transfer function for locker and pool transfers. This avoids reflecting the transfers when people withdraw;
	function _transferFromLockerOrPool(
		address sender,
		address recipient,
		uint256 tokenAmount
	) private {
		uint256 reflectAmount = tokenAmount.mul(_getRate());

		reflectionOwned[sender] = reflectionOwned[sender].sub(reflectAmount);

		tokensOwned[sender] = tokensOwned[sender].sub(tokenAmount);

		reflectionOwned[recipient] = reflectionOwned[recipient].add(reflectAmount);

		emit Transfer(sender, recipient, tokenAmount);
	}

	function _transferStandard(
		address sender,
		address recipient,
		uint256 tokenAmount
	) private {
		(uint256 reflectAmount, uint256 reflectTransferAmount, uint256 reflectFee, uint256 tokenTransferAmount, uint256 tokenFee) = _getValues(tokenAmount);
		reflectionOwned[sender] = reflectionOwned[sender].sub(reflectAmount);
		reflectionOwned[recipient] = reflectionOwned[recipient].add(reflectTransferAmount);
		_reflectFee(reflectFee, tokenFee);
		emit Transfer(sender, recipient, tokenTransferAmount);
	}

	function _transferToExcluded(
		address sender,
		address recipient,
		uint256 tokenAmount
	) private {
		(uint256 reflectAmount, uint256 reflectTransferAmount, uint256 reflectFee, uint256 tokenTransferAmount, uint256 tokenFee) = _getValues(tokenAmount);
		reflectionOwned[sender] = reflectionOwned[sender].sub(reflectAmount);
		tokensOwned[recipient] = tokensOwned[recipient].add(tokenTransferAmount);
		reflectionOwned[recipient] = reflectionOwned[recipient].add(reflectTransferAmount);
		_reflectFee(reflectFee, tokenFee);
		emit Transfer(sender, recipient, tokenTransferAmount);
	}

	function _transferFromExcluded(
		address sender,
		address recipient,
		uint256 tokenAmount
	) private {
		(uint256 reflectAmount, uint256 reflectTransferAmount, uint256 reflectFee, uint256 tokenTransferAmount, uint256 tokenFee) = _getValues(tokenAmount);
		tokensOwned[sender] = tokensOwned[sender].sub(tokenAmount);
		reflectionOwned[sender] = reflectionOwned[sender].sub(reflectAmount);
		reflectionOwned[recipient] = reflectionOwned[recipient].add(reflectTransferAmount);
		_reflectFee(reflectFee, tokenFee);
		emit Transfer(sender, recipient, tokenTransferAmount);
	}

	function _transferBothExcluded(
		address sender,
		address recipient,
		uint256 tokenAmount
	) private {
		(uint256 reflectAmount, uint256 reflectTransferAmount, uint256 reflectFee, uint256 tokenTransferAmount, uint256 tokenFee) = _getValues(tokenAmount);
		tokensOwned[sender] = tokensOwned[sender].sub(tokenAmount);
		reflectionOwned[sender] = reflectionOwned[sender].sub(reflectAmount);
		tokensOwned[recipient] = tokensOwned[recipient].add(tokenTransferAmount);
		reflectionOwned[recipient] = reflectionOwned[recipient].add(reflectTransferAmount);
		_reflectFee(reflectFee, tokenFee);
		emit Transfer(sender, recipient, tokenTransferAmount);
	}

	function _reflectFee(uint256 reflectFee, uint256 tokenFee) private {
		_reflectTotal = _reflectTotal.sub(reflectFee);
		_tFeeTotal = _tFeeTotal.add(tokenFee);
	}

	function _getValues(uint256 tokenAmount)
		private
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		(uint256 tokenTransferAmount, uint256 tokenFee) = _getTokenValues(tokenAmount);
		uint256 currentRate = _getRate();
		(uint256 reflectAmount, uint256 reflectTransferAmount, uint256 reflectFee) = _getReflectValues(tokenAmount, tokenFee, currentRate);
		return (reflectAmount, reflectTransferAmount, reflectFee, tokenTransferAmount, tokenFee);
	}

	function _getTokenValues(uint256 tokenAmount) private pure returns (uint256, uint256) {
		uint256 tokenFee = tokenAmount.div(100);
		uint256 tokenTransferAmount = tokenAmount.sub(tokenFee);
		return (tokenTransferAmount, tokenFee);
	}

	function _getReflectValues(
		uint256 tokenAmount,
		uint256 tokenFee,
		uint256 currentRate
	)
		private
		pure
		returns (
			uint256,
			uint256,
			uint256
		)
	{
		uint256 reflectAmount = tokenAmount.mul(currentRate);
		uint256 reflectFee = tokenFee.mul(currentRate);
		uint256 reflectTransferAmount = reflectAmount.sub(reflectFee);
		return (reflectAmount, reflectTransferAmount, reflectFee);
	}

	/*	
	function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        //_beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        //_afterTokenTransfer(account, address(0), amount);
    }
*/
	function _getRate() private view returns (uint256) {
		(uint256 reflectSupply, uint256 tokenSupply) = _getCurrentSupply();
		return reflectSupply.div(tokenSupply);
	}

	function _getCurrentSupply() private view returns (uint256, uint256) {
		uint256 reflectSupply = _reflectTotal;
		uint256 tokenSupply = _tokenTotal;
		for (uint256 i = 0; i < _excluded.length; i++) {
			if (reflectionOwned[_excluded[i]] > reflectSupply || tokensOwned[_excluded[i]] > tokenSupply) return (_reflectTotal, _tokenTotal);
			reflectSupply = reflectSupply.sub(reflectionOwned[_excluded[i]]);
			tokenSupply = tokenSupply.sub(tokensOwned[_excluded[i]]);
		}
		if (reflectSupply < _reflectTotal.div(_tokenTotal)) return (_reflectTotal, _tokenTotal);
		return (reflectSupply, tokenSupply);
	}
}