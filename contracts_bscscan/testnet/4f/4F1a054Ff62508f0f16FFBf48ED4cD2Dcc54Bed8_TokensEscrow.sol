/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

// Dependency file: D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\security\ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

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


// Dependency file: D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol


// pragma solidity ^0.8.0;

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


// Dependency file: D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol


// pragma solidity ^0.8.0;

// import "D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol";

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


// Dependency file: D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\utils\Context.sol


// pragma solidity ^0.8.0;

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


// Dependency file: D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\access\Ownable.sol


// pragma solidity ^0.8.0;

// import "D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\utils\Context.sol";
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


// Dependency file: D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\utils\math\SafeMath.sol


// pragma solidity ^0.8.0;

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


// Dependency file: D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\utils\Address.sol


// pragma solidity ^0.8.0;

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


// Dependency file: D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol


// pragma solidity ^0.8.0;

// import "D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol";
// import "D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\utils\Address.sol";

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


// Dependency file: contracts\utils\FullMath.sol

// pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}


// Root file: contracts\TokensEscrow.sol

// import 'D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\security\ReentrancyGuard.sol';
// import 'D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol';
// import 'D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol';
// import 'D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\access\Ownable.sol';
// import 'D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\utils\math\SafeMath.sol';
// import 'D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\utils\Address.sol';
// import 'D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol';
// import 'D:\repos\VRM\VRM-ESCROW\smart-contract\node_modules\@openzeppelin\contracts\security\ReentrancyGuard.sol';
// import 'contracts\utils\FullMath.sol';

contract TokensEscrow is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;

    enum Status {FUNDED, RELEASED, RECLAIMED}

    struct CommisionInfo {
        uint8 pctDigits;
        uint256 limitValue;
        uint8 limitValueDigits;
        uint32 beforeLimitPct;
        uint32 afterLimitPct;
    }

    struct Deal {
        uint256 valueBuy;
        uint256 valueSell;
        address buyTokenAddress; //address of ERC20 token
        address sellTokenAddress; //address of ERC20 token
        uint256 lastModified;
        Status status;
        uint32 timeoutHours;
        address buyer;
        address seller;
        bytes32 comment;
        uint256 gasCostBuyer;
        uint256 gasCostSeller;
    }

    event Finished(
        bytes32 indexed scriptHash,
        address[2] destinations,
        uint256[2] amounts,
        address[2] tokens,
        string[2] symbols
    );

    event FundAdded(bytes32 indexed scriptHash, address indexed from, uint256 valueAdded);

    event Funded(bytes32 indexed scriptHash, address indexed from, uint256 value);

    event Reclaimed(address indexed user, uint256 amount);

    modifier nonZeroAddress(address addressToCheck) {
        require(addressToCheck != address(0), 'Zero address passed');
        _;
    }

    modifier transactionExists(bytes32 scriptHash) {
        require(deals[scriptHash].valueSell != 0, 'Deal does not exist');
        _;
    }

    modifier transactionDoesNotExist(bytes32 scriptHash) {
        require(deals[scriptHash].valueSell == 0, 'Deal exists');
        _;
    }

    modifier inFundedState(bytes32 scriptHash) {
        require(deals[scriptHash].status == Status.FUNDED, 'Deal is not in FUNDED state');
        _;
    }

    modifier onlyBuyer(bytes32 scriptHash) {
        require(msg.sender == deals[scriptHash].buyer, 'The initiator of the deal is not buyer');
        _;
    }

    modifier onlySeller(bytes32 scriptHash) {
        require(msg.sender == deals[scriptHash].seller, 'The initiator of the deal is not seller');
        _;
    }

    modifier allowedBuyValue(bytes32 scriptHash, uint256 value) {
        require(value >= deals[scriptHash].valueBuy, 'Wrong buy value for Deal');
        _;
    }

    IERC20 public FLyToken;
    IUniswapV2Factory private uniswapV2Factory;
    IUniswapV2Router02 private uniswapV2Router02;
    IUniswapV2Pair private flyEthPair;

    CommisionInfo public commisionInfo;
    mapping(bytes32 => Deal) public deals;
    mapping(bytes32 => mapping(address => bool)) isOwner;

    uint256 public transactionCount = 0;

    //maps address to array of scriptHashes of all deals for
    //which they are either the buyer or the seller
    mapping(address => bytes32[]) private partyVsDeals;

    constructor(address _FLyTokenAddress, address _Factory, address _Router) {
        require(_FLyTokenAddress != address(0), 'Empty FLy address');
        require(_Factory != address(0), 'Empty Factory address');
        require(_Router != address(0), 'Empty Router address');

        FLyToken = IERC20(_FLyTokenAddress);
        uniswapV2Factory = IUniswapV2Factory(_Factory);
        uniswapV2Router02 = IUniswapV2Router02(_Router);

        IERC20Metadata meta = IERC20Metadata(_FLyTokenAddress);
        updateCommissionInfo(4, 10000 * 10**meta.decimals(), meta.decimals(), 5000, 2500);

        flyEthPair = IUniswapV2Pair(uniswapV2Factory.getPair(_FLyTokenAddress, uniswapV2Router02.WETH()));
        require(address(flyEthPair) != address(0), 'FLy/ETH pair was not found');
    }

    function updateCommissionInfo(
        uint8 pctDigits,
        uint256 limitValue,
        uint8 limitValueDigits,
        uint32 beforeLimitPct,
        uint32 afterLimitPct
    ) public onlyOwner {
        commisionInfo = CommisionInfo(pctDigits, limitValue, limitValueDigits, beforeLimitPct, afterLimitPct);
    }

    function getFLyAmount(uint256 ethAmount) public view returns (uint256) {
        (uint256 Res0, uint256 Res1, ) = flyEthPair.getReserves();
        return FullMath.mulDiv(ethAmount, Res0, Res1); // return amount of token1 needed to buy token0
    }

    /**
     * @notice Calculating scriptHash for a given deal transaction
     * @param valueSell The number of tokens to be held in escrow
     * @param valueBuy The number of tokens to be waited in escrow
     * @param timeoutHours The number hours after which the seller can
     * unilaterally release funds from escrow. When timeoutHours is set to 0
     * it means the seller can never unilaterally release funds from escrow
     * @param buyer The buyer associated with the deal transaction
     * @param seller The seller associated with the deal transaction
     * @param buyTokenAddress The address of the ERC20 token contract
     * @param sellTokenAddress The address of the ERC20 token contract
     * @return a bytes32 hash
     */
    function calculateRedeemScriptHash(
        uint256 valueSell,
        uint256 valueBuy,
        uint32 timeoutHours,
        address buyer,
        address seller,
        address buyTokenAddress,
        address sellTokenAddress
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    valueSell,
                    valueBuy,
                    timeoutHours,
                    buyer,
                    seller,
                    buyTokenAddress,
                    sellTokenAddress,
                    address(this)
                )
            );
    }

    /**
     * @notice Registers a new deal transaction to the contract
     * @param buyer The buyer associated with the deal transaction
     * @param seller The seller associated with the deal transaction
     * @param timeoutHours The number hours after which the seller can
     * unilaterally release funds from escrow. When timeoutHours is set to 0
     * it means the seller can never unilaterally release funds from escrow
     * @param valueSell The number of tokens to be held in escrow
     * @param valueBuy The number of tokens to be waited in escrow
     * @param sellTokenAddress The address of the ERC20 token contract
     * @param buyTokenAddress The address of the ERC20 token contract
     */
    function addTokensDeal(
        address buyer,
        address seller,
        uint32 timeoutHours,
        uint256 valueSell,
        uint256 valueBuy,
        address sellTokenAddress,
        address buyTokenAddress,
        bytes32 comment
    )
        external
        nonReentrant
        nonZeroAddress(buyer)
        nonZeroAddress(seller)
        nonZeroAddress(sellTokenAddress)
        nonZeroAddress(buyTokenAddress)
        returns (bytes32 scriptHash)
    {
        uint256 startGas = gasleft();
        require(sellTokenAddress != buyTokenAddress, 'addresses are same');
        scriptHash = _addTransaction(
            buyer,
            seller,
            timeoutHours,
            valueSell,
            valueBuy,
            sellTokenAddress,
            buyTokenAddress,
            comment
        );
        emit Funded(scriptHash, msg.sender, valueSell);
        IERC20(sellTokenAddress).safeTransferFrom(msg.sender, address(this), valueSell);
        deals[scriptHash].gasCostSeller = (startGas + 21000 + 5000 - gasleft()).mul(tx.gasprice);
    }

    /**
     * @notice Allows the buyer in an deal transaction to add more ERC20
     * tokens to an existing transaction
     * @param scriptHash The scriptHash of the deal transaction to which
     * funds will be added
     * @param value The number of tokens to be added
     */
    function addTokensToDeal(bytes32 scriptHash, uint256 value)
        external
        nonReentrant
        transactionExists(scriptHash)
        inFundedState(scriptHash)
        onlyBuyer(scriptHash)
        allowedBuyValue(scriptHash, value)
    {
        uint256 startGas = gasleft();
        Deal storage deal = deals[scriptHash];

        bool timeLockExpired = _isTimeLockExpired(deal.timeoutHours, deal.lastModified);
        require(!timeLockExpired, 'Deal is expired');

        IERC20 sellToken = IERC20(deal.sellTokenAddress);
        IERC20 buyToken = IERC20(deal.buyTokenAddress);
        IERC20Metadata sellMeta = IERC20Metadata(deal.sellTokenAddress);
        IERC20Metadata buyMeta = IERC20Metadata(deal.buyTokenAddress);

        emit FundAdded(scriptHash, msg.sender, value);
        buyToken.safeTransferFrom(msg.sender, address(this), value);

        sellToken.safeTransfer(deal.buyer, deal.valueSell);

        uint256 commission = getCommision(scriptHash);

        buyToken.safeTransfer(deal.seller, deal.valueBuy.sub(commission));
        buyToken.safeTransfer(owner(), commission); //collect comission

        uint256 diff = value - deal.valueBuy;

        if (diff > 0) {
            buyToken.safeTransfer(deal.buyer, diff);
        }

        deal.status = Status.RELEASED;

        //solium-disable-next-line security/no-block-members
        deal.lastModified = block.timestamp;
        emit Finished(
            scriptHash,
            [deal.seller, deal.buyer],
            [deal.valueSell, deal.valueBuy],
            [deal.sellTokenAddress, deal.buyTokenAddress],
            [sellMeta.symbol(), buyMeta.symbol()]
        );

        uint256 flyToSeller = getFLyAmount(deal.gasCostSeller);
        FLyToken.safeTransfer(deal.seller, flyToSeller);
        uint256 gasToBuyer = (startGas + 21000 + 5000 + 2300 - gasleft()).mul(tx.gasprice);
        uint256 flyToBuyer = getFLyAmount(gasToBuyer);
        deal.gasCostBuyer = gasToBuyer;
        FLyToken.safeTransfer(deal.buyer, flyToBuyer);
    }

    function getCommision(bytes32 scriptHash) private view transactionExists(scriptHash) returns (uint256 commission) {
        Deal storage deal = deals[scriptHash];
        IERC20 sellToken = IERC20(deal.sellTokenAddress);
        uint256 flyBalance = FLyToken.balanceOf(deal.seller);
        if (address(FLyToken) == address(sellToken) && flyBalance > 0) {
            flyBalance = flyBalance.sub(deal.valueSell);
        }
        commission = FullMath.mulDiv(deal.valueBuy, commisionInfo.beforeLimitPct, 100 * 10**commisionInfo.pctDigits);
        if (flyBalance >= commisionInfo.limitValue) {
            commission = FullMath.mulDiv(deal.valueBuy, commisionInfo.afterLimitPct, 100 * 10**commisionInfo.pctDigits);
        }
    }

    function reclame(bytes32 scriptHash)
        external
        nonReentrant
        transactionExists(scriptHash)
        inFundedState(scriptHash)
        onlySeller(scriptHash)
    {
        Deal storage deal = deals[scriptHash];
        bool timeLockExpired = _isTimeLockExpired(deal.timeoutHours, deal.lastModified);
        require(timeLockExpired, 'Deal is not expired');
        IERC20 sellToken = IERC20(deal.sellTokenAddress);
        sellToken.safeTransfer(deal.seller, deal.valueSell);
        deal.status = Status.RECLAIMED;
        emit Reclaimed(deal.seller, deal.valueSell);
    }

    /**
     * @notice Returns an array of scriptHashes associated with trades in which
     * a given address was listed as a buyer or a seller
     * @param partyAddress The address to look up
     * @return an array of scriptHashes
     */
    function getAllTransactionsForParty(address partyAddress) external view returns (bytes32[] memory) {
        return partyVsDeals[partyAddress];
    }

    /**
     * @notice Checks whether a timeout has occured
     * @param timeoutHours The number hours after which the seller can
     * unilaterally release funds from escrow. When `timeoutHours` is set to 0
     * it means the seller can never unilaterally release funds from escrow
     * @param lastModified The timestamp of the last modification of escrow for
     * a particular OpenBazaar transaction
     * @return true if and only if `timeoutHours` hours have passed since
     * `lastModified`
     */
    function _isTimeLockExpired(uint32 timeoutHours, uint256 lastModified) private view returns (bool) {
        //solium-disable-next-line security/no-block-members
        uint256 timeSince = block.timestamp.sub(lastModified);
        return (timeoutHours == 0 ? false : timeSince > uint256(timeoutHours).mul(1 hours));
    }

    /**
     * @dev Private method for adding a new deal transaction to the
     * contract. Used to reduce code redundancy
     * @param buyer The buyer associated with the deal transaction
     * @param seller The seller associated with the deal transaction
     * @param timeoutHours The number hours after which the seller can
     * unilaterally release funds from escrow. When timeoutHours is set to 0
     * it means the seller can never unilaterally release funds from escrow
     * @param valueSell The amount of currency to add to escrow
     * @param valueBuy The number of tokens to be waited in escrow
     * ERC20 tokens for payment
     * @param sellTokenAddress The address of the ERC20 token being used for
     * payment.
     * @param buyTokenAddress The address of the ERC20 token being used for
     * payment.
     */
    function _addTransaction(
        address buyer,
        address seller,
        uint32 timeoutHours,
        uint256 valueSell,
        uint256 valueBuy,
        address sellTokenAddress,
        address buyTokenAddress,
        bytes32 comment
    ) private returns (bytes32 scriptHash) {
        require(buyer != seller, 'Buyer and seller are same');
        require(valueSell > 0, 'Value to sell passed is 0');
        require(valueBuy > 0, 'Value to buy passed is 0');

        scriptHash = calculateRedeemScriptHash(
            valueSell,
            valueBuy,
            timeoutHours,
            buyer,
            seller,
            buyTokenAddress,
            sellTokenAddress
        );
        require(deals[scriptHash].valueSell == 0, 'Deal exists');

        deals[scriptHash] = Deal({
            buyer: buyer,
            seller: seller,
            valueSell: valueSell,
            valueBuy: valueBuy,
            status: Status.FUNDED, //solium-disable-next-line security/no-block-members
            lastModified: block.timestamp,
            timeoutHours: timeoutHours,
            sellTokenAddress: sellTokenAddress,
            buyTokenAddress: buyTokenAddress,
            comment: comment,
            gasCostBuyer: 0,
            gasCostSeller: 0
        });

        isOwner[scriptHash][seller] = true;
        isOwner[scriptHash][buyer] = true;

        transactionCount++;

        partyVsDeals[buyer].push(scriptHash);
        partyVsDeals[seller].push(scriptHash);
    }

    receive() external payable {}

    function emergencyWithdraw(address _token) external onlyOwner {
        if (_token == address(0)) {
            Address.sendValue(payable(owner()), address(this).balance);
        } else {
            IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
        }
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);
}