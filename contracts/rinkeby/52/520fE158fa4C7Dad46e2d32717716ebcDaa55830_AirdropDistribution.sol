/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: IVesting

interface IVesting {
   function vest(address _beneficiary, uint256 _amount, uint256 _isRevocable) external payable;
}

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/ReentrancyGuard

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

// Part: OpenZeppelin/[email protected]/SafeMath

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

// Part: OpenZeppelin/[email protected]/Pausable

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

// Part: OpenZeppelin/[email protected]/SafeERC20

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

// File: AirdropDistribution.sol

/// @title AirdropDistribution
/// @dev This contract manages the distribution of Swerve Airdrop for active Swerve Governance Participants
///      Eligible participant addresses and their allocations are hardcoded

contract AirdropDistribution is Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address[210] airdropArray = [
    0x28d6037EDEAf8ec2c91c9b2cF9A1643111d8F198,
    0xcfc50541c3dEaf725ce738EF87Ace2Ad778Ba0C5,
    0xF9e11762d522ea29Dd78178c9BAf83b7B093aacc,
    0xED60d8590019e5E145ea81455c01F3e817Fe54EB,
    0x052564eB0fd8b340803dF55dEf89c25C432f43f4,
    0x21F3B2C8646B4fFA809406BB31dE325a3E5E9b9F,
    0xd9A93390c487b954EB1Ad4c8a4Acc73840409869,
    0xe15DD1510E39E9980C0dC47e404eb7298872bc64,
    0x3BA21b6477F48273f41d241AA3722FFb9E07E247,
    0x2326D4fb2737666DDA96bd6314e3D4418246cFE8,
    0xa0f75491720835b36edC92D06DDc468D201e9b73,
    0xAc6559dF1F410Feba9a6cbf395272189461D8463,
    0xAE60C874eE07f44fB7BBbD1a5087cDB66E90BEd8,
    0x600b8A34ec1CfD8B8aF78cFC49708419A16ea2e8,
    0x89689dB564BF4b67BD7116B3f71e68A379FAad98,
    0xCaEDCaaFE4C596e89704c5e6B499B8D3474F750f,
    0xbC90B3Ce40fc3Ed921D910f3e046C65954fFF7cB,
    0x303985ba2209b5c0c745885Fa6fdd2eC1FEB81A5,
    0x3991ADBDf461D6817734555efDC8ef056fEfBF21,
    0xADEEb9d09B8Bcee10943198FB6F6a4229bAB3675,
    0xb9a954BF995bDEAcBDfE4B1F5f85cD6122c6E341,
    0x86aF94E5E8d3D583575bBafDD2DcB6b898A555e4,
    0x270d2924cA13F54632601647FB225DB8eb61fB49,
    0x02e05dbBF4df5d17cb3A0140F9643fE68cc4Ae39,
    0xd8D3d8ab22E30c5402AB2A2E216a4A53F4e09e9E,
    0x28a55C4b4f9615FDE3CDAdDf6cc01FcF2E38A6b0,
    0x78Bc49be7bae5e0eeC08780c86F0e8278B8B035b,
    0xf0E12c7218cB38DF7A3A231Bb91EE82F732625b6,
    0x99eb33756a2eAa32f5964A747722c4b59e6aF351,
    0xB0ff496dF3860504ebdFF61590A13c1D810C97cc,
    0x40d2Ce4C14f04bD91c59c6A1CD6e28F2A0fc81F8,
    0xF07F2B6C340d8D303615710451C11e93fe56774D,
    0x6979B914f3A1d8C0fec2C1FD602f0e674cdf9862,
    0x90be4e1Da4BB2F464576749abAc99774148bC9a2,
    0x681148725731F213b0187A3CBeF215C291D85a3E,
    0x1678b549Be696b1DfCe9F0639D996a82409E1Ea1,
    0x4f58985B75EeC8f14C536878A19EAdF4a1960D6c,
    0x55b9c56668365d11f5aF18E8b7232bC6e4d20658,
    0xA423fE4CFb811E9CF6a61a02e80E372c0970d4b0,
    0x7432b5212F19af018b33b73a55d1996960E59c51,
    0x0Af14239FAA4f19034f3334502ED592B0083e108,
    0x9fA933f60BCc5E63F75F210929839f91F55b919C,
    0xB680f628C56C8Fa368Dacbb0C27beEf8C98355b9,
    0x4EC7CdF61405758f5cED5E454c0B4b0F4F043DF0,
    0xFCa7C5CF95821f3D45b9949De6E2846D66aF819F,
    0xA7758B30e93d2ED6CEA7c85e5B12a1d46F0f091f,
    0x84740F97Aea62C5dC36756DFD9F749412534220E,
    0xcE968c0fC101C4FB8e08EB5dB73E7E169A2A3562,
    0xC151AE135F50AaBE78e0b9D13A90FBb2d648AAbB,
    0x975f5ffB9C3B624351634889944355D47Ab8a367,
    0x9B5ea8C719e29A5bd0959FaF79C9E5c8206d0499,
    0xF1fb5dEa21337FEB46963C29d04A95F6CA8B71e6,
    0x71F12a5b0E60d2Ff8A87FD34E7dcff3c10c914b0,
    0x918A97AD195DD111C54Ea82E2F8B8D22E9f48726,
    0x25431341A5800759268a6aC1d3CD91C029D7d9CA,
    0x52Ad87832400485DE7E7dC965D8Ad890f4e82699,
    0xF38140985B5a5746F160F133049E83F79cc0B819,
    0xbE93d14C5dEFb8F41aF8FB092F58e3C71C712b85,
    0xa0a6Dc36041fb386378458006FEcbDdD02555DdD,
    0x5F82C97e9b1755237692a946aE814998Bc0e2124,
    0xdD709cAE362972cb3B92DCeaD77127f7b8D58202,
    0x8b7B509c01838a0D197a8154C5BF00A3F56fF615,
    0x640E0118b2C5a3C0Ea29B94A62d9108ce2c6ced7,
    0x1B51cCe51E2531C478daA9b68eb80D47247dCbec,
    0xcCa71809E8870AFEB72c4720d0fe50d5C3230e05,
    0x2dE640a18fE3480aa802aca91f70177aDA103391,
    0x14Ce500a86F1e3aCE039571e657783E069643617,
    0x6019D32e59Ef480F2215eE9773AE507645B47bdc,
    0xB67D92DC830F1a24E4BFfd1a6794fCf8f497c7de,
    0x6f9BB7e454f5B3eb2310343f0E99269dC2BB8A1d,
    0xE95d3DAbA7495d42DCC20810f33eeb5207512a9f,
    0x39c09fdc4E5C5AB72F6319dDbc2CAe40E67b2A60,
    0xFadAFCE89EA2221fa33005640Acf2C923312F2b9,
    0x7122FC3588fB9E9B93b7c42Ba02FC85ef15c442b,
    0x25AfD857C7831C91951Cd94ba63AF237d28604D0,
    0x6fcF92925e0281D957B0076d3751caD76916C96B,
    0xd026bFdB74fe1bAF1E1F1058f0d008cD1EEEd8B5,
    0xbdC38612397355e10A2d6DD697a92f35BF1C9935,
    0x339Dab47bdD20b4c05950c4306821896CFB1Ff1A,
    0x1EBb814C9EF016E6012bE299ED834f1dDcEd1529,
    0xF625DCa051B5AE56f684C072c09969C9Aa91478a,
    0x5eBdC5C097F9378c3113DC2f9E8B51246E641896,
    0xD45FBD8F2B0A84743D2606DE8094f86Fac5B6ed3,
    0x3e89F0eCACDC9b1f8BB892367610cAd0cE421C92,
    0xC77C0EDc7067a76972481484B87c1226E410547C,
    0x0F763341b448bb0f02370F4037FE4A2c84c9283f,
    0x0035Fc5208eF989c28d47e552E92b0C507D2B318,
    0xB8C30017B375bf675c2836c4c6B6ed5BE214739d,
    0x286ed1111c29592cC6240194b8d66E64B1c05e50,
    0x4Cd52B37fdDD19CcD24B0d0e9a048785C7aaFCEf,
    0x0D779D67a428457CAbEC145A0f94703D14cd496B,
    0x0000A441fBB1fBAADF246539BF253A42ABD31494,
    0xECB949c68C825650fD9D0Aebe0cd3796FD126e66,
    0x8C4d5F3eaC04072245654E0BA480f1a5e1d91Dd5,
    0xFca32B89d0981e69C8dadCDcc0668b0E01c810CF,
    0x22fa8Cc33a42320385Cbd3690eD60a021891Cb32,
    0x23Be060093Db74f38B1a3daF57AfDc1a23dB0077,
    0xfc80d0867822b8eD010bafcC195c21617C01f943,
    0x526C7665C5dd9cD7102C6d42D407a0d9DC1e431d,
    0x6c5384bBaE7aF65Ed1b6784213A81DaE18e528b2,
    0xAE667Ed58c0d9198fc0b9261156d48296C1bB3da,
    0xe1DE283EAb72A68f7Ff972fcA13f8953c6e15e51,
    0xdae88e81e10d848BA6b0Ad64B19783e807064696,
    0x0a8A06071c878DF9Ec2B5f9663A4b08B0F8c08f4,
    0x3E95fEF1176acF5e5d2EF67D9C856E4ECAc73E1F,
    0x9C3c75c9D269aa8282BDE7BE3352D81CC91C2b6A,
    0xD72B03B7F2E0b8D92b868E73e12b1f888BEFBeDA,
    0xC23ef3AdF050f4Ca50b30998D37Eb6464e387577,
    0xD56705548111F08CCB3e1A73806c53Dc706F2e75,
    0x32802F989B4348A51DD0E61D23B78BE1a0543469,
    0xc7ca02DC88A2750031DC04515438C3a505bcC994,
    0x1eccd61c9fa53a8D2e823A26cD72A7efD7D0E92e,
    0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6,
    0x6b30E020E9517c519C408f51C2593E12D55B55fA,
    0x57d1E246D2E32F6F9D10EC55Fc41E8B2E2988308,
    0xEd557994671DddA053a582e73F2e8aa32bDE7D68,
    0xceA077172675bf31e879Bba71fb46C3188591070,
    0x3fC925E779F148f2d843cfD63296E5E12C36d632,
    0xC369B30c8eC960260631E20081A32e4c61E5Ea9d,
    0x8d4BfE71379a197ae0c3ea8B41b75f30294d6afb,
    0x455d7Eb74860d0937423b9184f9e8461aa354Ebb,
    0x14559df3FBe66Cab6F893D8dD53F7BFE68DE9C65,
    0x238F24101876377E9178d125D0747DE7fad9C3b2,
    0x4BB633f0e7E0F3FbC95a7f7fd223652882977573,
    0x9BdFAeB9CB28DC05b09B37c0F14ECBc9A876CEe0,
    0x7904aDB48351aF7b835Cb061316795d5226b7f1a,
    0xF96dA4775776ea43c42795b116C7a6eCcd6e71b5,
    0x418Efa84214F9810AF9119909D5bEe2c56ebd5Eb,
    0x2c9dB5597a4a9d2ba6780CD9722e25A9140552EE,
    0xe1163DCFb598F74da146a83CC878731d553abBfe,
    0x0991D02f28a5283338e9591CBf7dE2eb25da46Cd,
    0x7374bB48A5FDc16C9b216F3fCc60b105c73D1806,
    0xe4f9E812Fe379128f17258A2b3Db7CF28613f190,
    0x2CA3a2b525E75b2F20f59dEcCaE3ffa4bdf3EAa2,
    0x8522885d735F75b3FAEEa5CD39ab3d1291dA2C77,
    0xA4bd4E4D2e8c72720839823f6c20f411f7DDb1f1,
    0x1729f93e3c3C74B503B8130516984CED70bF47D9,
    0x94Da725DBA289B96f115ec955aDcAAA806d2085d,
    0x38857Ed3a8fC5951289E58e20fB56A00e88f0BBD,
    0x767D222a509D107522e50161CA17FfCF0e5AA3dE,
    0xA4f2b2557D78E31D48E1ffa8AF8b25Db8524Ea3c,
    0xDEC1BcdF22A6e77F10e3bF7df8a5F6A6a38E6376,
    0xC1a0fC4a40253B04a1aE2F40655d73b16CAf268c,
    0x285E4f019a531e20f673B634D31922d408970798,
    0x2848b9f2D4FaEBaA4838c41071684c70688B455d,
    0xa734288DA3aCE7F9a5e5CAa6Df929126f2e67d52,
    0xD18001F022154654149ed45888C9c29Def6d3CE6,
    0x7ea1a45f0657D2Dbd77839a916AB83112bdB5590,
    0x058B10CbE1872ad139b00326686EE8CCef274C58,
    0xc78CE4E51611ed720eC96bf584bf1b1658FD2379,
    0xFbEd5277E524113Df313F9f6B29fDE8677F4E936,
    0xA652565dB815Ad3B138fD98830D14Cfd1826693A,
    0x43E553fC1D064C125764E9D534a4F7D89B9bb1BE,
    0x1712fdDC84EFa346D51261f0fa5a809fF457aBDc,
    0xD0a5266b2515c3b575e30cBC0cfC775FA4fC6660,
    0x507E964A2fabE1921278b640b0813a5626844145,
    0x51A7EaD10340AF963C3124b026b86dd2807c2b1C,
    0x215D67998DaCd9DA4118E4a4899bec60b79987A0,
    0x8fC548B6B071bf0f2Fe64aD1Aa6032A6d2037366,
    0x102902245322aAd61D55cfAD8213472A5702a593,
    0x4B4De68ef03aE45c0d1026801Da71258DDC6BCF6,
    0x32a59b87352e980dD6aB1bAF462696D28e63525D,
    0xE582794320FA7424A1f9db360A46446244065Cb5,
    0xD71C552a4954673a30893BF1Db0A77f1aFA1accD,
    0xEE4a267E98260aCf829Ca9dC6c9f3d5d82183Bce,
    0x54683a50f0D2B3F3d1b32780524AE01AA1A583c2,
    0xdc34F2a567dFE0E7512108b24EcEa2d92754751C,
    0xD09c6b71b1a7841e7dFb244D90d2a146201BF78B,
    0xbB48c430C3cA821755547E514A8Fe9CC82BDD975,
    0x7F326eA697EF0dd2BbD628B62F569017c1D43FCB,
    0x7f048Fe4176AB39E225907F777F658a6eFDD42ce,
    0x66EA1467282FFf8df570a1f732F0C6Ab8749154E,
    0xc1cAd6df277106222Dd45cF5B0300fBd4d1193D5,
    0x963D071201275fD5FA3dC9bB34fd3d0275ba97a7,
    0x0707FD320C96b54182475B22a9D47b4045E74668,
    0xfE2353C808F2409cCb81508005A62cef29457706,
    0xE580aB95EBE6156c9717e20D513dD788B341934c,
    0x4EC355d5780c9554EbdF1B40e9734A573D81052C,
    0x3DdbbbB4C18f1e745A3F65ffC84E9197629Ac6B4,
    0x05c0F2d1978a1Da91E5D82B8935c610b3F93f36B,
    0x5221ce255906a61cf3DC2506143cd38D46A92be1,
    0x573fA57407Bb0e4b761DBe801b5cbD160A8E8C21,
    0x4Dacd010e15e220bC6C5C3210d166505d2b6c63A,
    0x2FA26aD1BfAE9e66b5c3F364a9E8EcEc8520dB4a,
    0xa357Cb3CE710a4f90fB9d56979C2C3634E3965bA,
    0x1b74fcf3A084d13a9D910DB12469251988985413,
    0xa948DE8A9205f1fE473490d2114c6616a90fD8d6,
    0x101D5810f8841BcE68cB3e8CFbadB3f8C71fdff0,
    0x9F7610115501abD147d1d82Ce92cea2A716690ED,
    0xf600fd970Bc2054d81AFb1646B50531D7567b22c,
    0x59cc72743488Aa24Caa92a521E74e633bb1f9096,
    0x20BFFFdB086D35e1eE06b1e0Beb849eE0a0E945c,
    0xa2040D6b10595EcBa2F751737b4A931A868f0655,
    0x0900a13FB9382c6668a74500cccE70Eb96385e0C,
    0x33d01F8BaA2319882440FE8Cf2978fb137B59Dc1,
    0x7329c9ead9b5BB0AD240B75C3CFdc2828AC2EFCf,
    0x77CB8c64e42ea076594A0C1E08115D8444Fa9fAc,
    0x228a671629bE7a9436019AF909a1629c94bF4cAf,
    0x7FF3552031C441f3F01AeDEb0C2C680FBA6dD5Df,
    0x2D52F7BaE61912f7217351443eA8a226996a3Def,
    0x6bac48867BC94Ff20B4C62b21d484a44D04d342C,
    0xA42830eE059c77cAF8c8200B44AA9813CB0720c5,
    0xf88d3412764873872aB1FdED5F168a6c1A3bF7bB,
    0x3AA667D05a6aa1115cF4A533C29Bb538ACD1300c,
    0xb92667E34cB6753449ADF464f18ce1833Caf26e0,
    0x7BFEe91193d9Df2Ac0bFe90191D40F23c773C060,
    0x1f0a6d7Db80E0C5Af146FDb836e04FAC0B1E8202,
    0x2053e0218793eEc7107ec50b09B696D4431C1Ff8,
    0xB8C2C00cC883d087C0Cbd443CeC51a4D04f8b147,
    0xc8e99dd497ae1fc981c1dd48f49FB804FBFCB99D
    ];

    uint256[210] airdropBalances = 

    [
    4297396,
    1728358,
    1505261,
    1332003,
    727506,
    182291,
    750722,
    625052,
    505013,
    465932,
    485597,
    395709,
    63621,
    282190,
    339931,
    65686,
    184250,
    262345,
    239002,
    206374,
    210330,
    192425,
    197415,
    66379,
    172905,
    158272,
    152257,
    166385,
    168117,
    36747,
    4760,
    117953,
    111187,
    109898,
    89898,
    94390,
    85323,
    82567,
    81233,
    80992,
    68640,
    64138,
    62431,
    59644,
    62799,
    61129,
    55179,
    51915,
    48305,
    47379,
    45361,
    44710,
    43459,
    43725,
    42692,
    40472,
    43858,
    36506,
    601,
    33822,
    32612,
    542,
    31773,
    28432,
    21291,
    25655,
    25360,
    25258,
    23591,
    23366,
    23422,
    21365,
    20012,
    19919,
    19240,
    19638,
    18884,
    17133,
    16639,
    15337,
    14773,
    14824,
    14644,
    12760,
    12503,
    9,
    12208,
    2092,
    11859,
    11672,
    11192,
    10321,
    1629,
    10303,
    9539,
    9200,
    9115,
    3925,
    8894,
    8531,
    8399,
    8151,
    7665,
    7634,
    165,
    595,
    6865,
    6522,
    6496,
    6454,
    6374,
    3960,
    622,
    5993,
    5971,
    5930,
    5930,
    5722,
    5645,
    123,
    5105,
    5040,
    813,
    2220,
    4618,
    4482,
    4448,
    4447,
    233,
    4121,
    3863,
    3833,
    3875,
    3836,
    3638,
    3558,
    3241,
    2965,
    2965,
    34,
    2965,
    2965,
    2699,
    2687,
    139,
    2372,
    2130,
    384,
    2172,
    2092,
    2083,
    314,
    2075,
    475,
    1769,
    1769,
    1559,
    1511,
    1490,
    1482,
    248,
    1361,
    1251,
    1245,
    1180,
    1180,
    222,
    1010,
    965,
    947,
    889,
    620,
    28,
    810,
    767,
    619,
    96,
    593,
    494,
    221,
    474,
    84,
    320,
    445,
    362,
    56,
    331,
    280,
    272,
    38,
    34,
    5,
    118,
    17,
    89,
    88,
    59,
    8,
    1,
    30,
    29,
    504793,
    430006,
    39045,
    15187,
    8275,
    141303,
    195,
    113110,
    82615
    ];

    //Airdrop Shares
    struct Airdrop {
        uint256 total;
        uint256 remaining;
    }

    mapping(address => Airdrop) public airdrop;
    mapping(address => uint256) public validated; //Are they validated to claim?

    uint256 private airdrop_supply = 20160000 * 10 ** 18; //Total Allocation for Airdrop

    // General constants
    uint256 constant HOUR = 3600;
    uint256 constant DAY = 86400;
    uint256 constant WEEK = 86400 * 7;
    uint256 constant YEAR = WEEK * 52;

    uint256 constant RATE_TIME = WEEK;                          // How often the rate goes to the next epoch
    uint256 constant INITIAL_RATE = 247_262 * 10 ** 18 / WEEK;  // per second
    uint256 constant EPOCH_INFLATION = 98_831;                  // 98.831 % of prior week
    uint256 constant INITIAL_RATE_EPOCH_CUTTOF = 260;           // airdrop stops after this many weeks

    // Supply variables
    uint256 public miningEpoch;
    uint256 public startEpochTime;
    uint256 public rate;

    uint256 startEpochSupply;
   
    event updateMiningParameters(uint256 time, uint256 rate, uint256 supply);
    event Validated(address indexed investor, uint256 amount, uint256 timeStamp);
    event Claimed(address indexed investor, uint256 amount, uint256 timeStamp);

    IERC20 public mainToken;    //BOOT token address
    IVesting public vestLock;   //Vesting contract address

    // define all the mining calculations here so that it doesn't have to
    // called from MainToken contract
    constructor(IERC20 _mainToken, IVesting _vestLock) {
        require(address(_mainToken) != address(0), "Invalid address");
        require(address(_vestLock) != address(0), "Invalid address");
        mainToken = _mainToken;
        vestLock = _vestLock;
        rate = INITIAL_RATE;
        startEpochTime = block.timestamp;

        mainToken.approve(address(vestLock), 2**256-1);
    }

    // At first run, user has to validate - it checks if they are indeed in the airdrop, if yes, set the internal mappings for their address so they can claim.
    //
    function validate() external nonReentrant {
        require(msg.sender != address(0));
        require(validated[msg.sender] == 0, "Already validated.");

        for (uint i = 0; i < airdropArray.length; i++) {
            if (airdropArray[i] == msg.sender) {
                uint256 award = airdropBalances[i] * 10 ** 18;
                airdrop[msg.sender] = Airdrop(award, award);
                validated[msg.sender] = 1;
                emit Validated(msg.sender, award, block.timestamp);
                break;
            }
        }
    }

    // Claim function can only be called if validated, and found to exist in hardcoded array.
    //
    function claim() external nonReentrant {
        _claim(0);
    }

    // Allow users to claim a specific amount instead of the entire amount
    function claimExact(uint256 _value) external nonReentrant {
        require(_value > 0, "Cannot claim 0.");
        _claim(_value);
    }

    function _claim(uint256 _value) private {
        require(msg.sender != address(0));
        require(validated[msg.sender] == 1, "Address not validated to claim.");
        uint256 _total = airdrop[msg.sender].total;
        uint256 _remaining = airdrop[msg.sender].remaining;
        uint256 _claimed = _total - _remaining;
        require(_remaining > 0, "Nothing remaining to claim.");

        _updateEmission();

        uint256 claimable = _available_supply() * _total / airdrop_supply;
        assert(claimable <= _total);

        require(claimable > _claimed, "Not yet claimable.");
        claimable -= _claimed;

        if (_value == 0) {
            _value = claimable;
        }
        else {
            require(_value <= claimable, "Amount not claimable.");
        }

        assert(_remaining >= _value);
        airdrop[msg.sender].remaining -= _value;

        emit Claimed(msg.sender, _value, block.timestamp);

        uint256 to_lock = 7 * _value / 10;  // 70% locked
        uint256 to_send = _value - to_lock; // 30% instant
        if (to_send == 0) {
            // 100% locked in vesting contract to prevent small magnitude _value
            // from being used to bypass vesting by repeatedly leaking dust.
            vestLock.vest(msg.sender, _value, 0); 
        }
        else {
            vestLock.vest(msg.sender, to_lock, 0);   
            mainToken.safeTransfer(msg.sender, to_send); 
        }
    }

    function updateEmission() public {
        require(block.timestamp >= startEpochTime + RATE_TIME, "Too soon");
        _updateEmission();
    }

    /// @notice release of BOOT public sale tokens from this contract 
    /// based on emission rules
    ///
    function _updateEmission() private {
        if (block.timestamp >= startEpochTime + RATE_TIME) {
            miningEpoch += 1;
            startEpochTime = startEpochTime.add(RATE_TIME);
            startEpochSupply = startEpochSupply.add(rate.mul(RATE_TIME));

            if (startEpochSupply >= airdrop_supply) {
                startEpochSupply = airdrop_supply;
                rate = 0;
            }
            else {
                rate = rate.mul(EPOCH_INFLATION).div(100000);
            }

            emit updateMiningParameters(block.timestamp, rate, startEpochSupply);
        }
    }

    function available_supply() public view returns(uint256) {
        assert(block.timestamp - startEpochTime <= RATE_TIME);
        return _available_supply();
    }

    function _available_supply() private view returns(uint256) {
        return startEpochSupply + (block.timestamp - startEpochTime) * rate;
    }
}