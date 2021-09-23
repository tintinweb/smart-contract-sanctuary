/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// File: contracts/Dependencies/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

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
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/proxy/Dependencies/Ownable.sol

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
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Dependencies/ReentrancyGuard.sol

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

// File: contracts/Dependencies/SafeMath.sol

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

// File: contracts/Dependencies/IERC20.sol

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

// File: contracts/Dependencies/Address.sol

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
        assembly {size := extcodesize(account)}
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
        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
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

// File: contracts/Dependencies/SafeERC20.sol

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
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/Dependencies/IERC165.sol

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: contracts/Dependencies/IERC1155.sol

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: contracts/proxy/FlashSales1155.sol

contract FlashSales1155 is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint private _saleIdCounter;
    bool private _onlyInitOnce;

    struct FlashSale {
        // The sale setter
        address seller;
        // Address of ERC1155 token to sell
        address tokenAddress;
        // Id of ERC1155 token to sell
        uint id;
        // Remaining amount of ERC1155 token in this sale
        uint remainingAmount;
        // ERC20 address of token for payment
        address payTokenAddress;
        // Price of token to pay
        uint price;
        // Address of receiver
        address receiver;
        // Max number of ERC1155 token could be bought from an address
        uint purchaseLimitation;
        uint startTime;
        uint endTime;
        // Whether the sale is available
        bool isAvailable;
    }

    // Payment whitelist for the address of ERC20
    mapping(address => bool) private _paymentWhitelist;

    // Whitelist to set sale
    mapping(address => bool) private _whitelist;

    // Mapping from sale id to FlashSale info
    mapping(uint => FlashSale) private _flashSales;

    // Mapping from sale ID to mapping(address => how many tokens have bought)
    mapping(uint => mapping(address => uint)) _flashSaleIdToPurchaseRecord;

    event PaymentWhitelistChange(address erc20Addr, bool jurisdiction);
    event SetWhitelist(address memberAddr, bool jurisdiction);
    event SetFlashSale(uint saleId, address flashSaleSetter, address tokenAddress, uint id, uint remainingAmount,
        address payTokenAddress, uint price, address receiver, uint purchaseLimitation, uint startTime,
        uint endTime);
    event UpdateFlashSale(uint saleId, address operator, address newTokenAddress, uint newId, uint newRemainingAmount,
        address newPayTokenAddress, uint newPrice, address newReceiver, uint newPurchaseLimitation, uint newStartTime,
        uint newEndTime);
    event CancelFlashSale(uint saleId, address operator);
    event FlashSaleExpired(uint saleId, address operator);
    event Purchase(uint saleId, address buyer, address tokenAddress, uint id, uint amount, address payTokenAddress,
        uint totalPayment);


    modifier onlyWhitelist() {
        require(_whitelist[msg.sender],
            "the caller isn't in the whitelist");
        _;
    }

    modifier onlyPaymentWhitelist(address erc20Addr) {
        require(_paymentWhitelist[erc20Addr],
            "the pay token address isn't in the whitelist");
        _;
    }

    function init(address _newOwner) public {
        require(!_onlyInitOnce, "already initialized");

        _transferOwnership(_newOwner);
        _onlyInitOnce = true;
    }

    /**
     * @dev External function to set flash sale by the member in whitelist.
     * @param tokenAddress address Address of ERC1155 token contract
     * @param id uint Id of ERC1155 token to sell
     * @param amount uint Amount of target ERC1155 token to sell
     * @param payTokenAddress address ERC20 address of token for payment
     * @param price uint Price of each ERC1155 token
     * @param receiver address Address of the receiver to gain the payment
     * @param purchaseLimitation uint Max number of ERC1155 token could be bought from an address
     * @param startTime uint Timestamp of the beginning of flash sale activity
     * @param duration uint The duration of this flash sale activity
     */
    function setFlashSale(
        address tokenAddress,
        uint id,
        uint amount,
        address payTokenAddress,
        uint price,
        address receiver,
        uint purchaseLimitation,
        uint startTime,
        uint duration
    )
    external
    nonReentrant
    onlyWhitelist
    onlyPaymentWhitelist(payTokenAddress)
    {
        // 1. check the validity of params
        _checkFlashSaleParams(msg.sender, tokenAddress, id, amount, price, purchaseLimitation, startTime);

        // 2.  build flash sale
        uint endTime;
        if (duration != 0) {
            endTime = startTime.add(duration);
        }

        FlashSale memory flashSale = FlashSale({
        seller : msg.sender,
        tokenAddress : tokenAddress,
        id : id,
        remainingAmount : amount,
        payTokenAddress : payTokenAddress,
        price : price,
        receiver : receiver,
        purchaseLimitation : purchaseLimitation,
        startTime : startTime,
        endTime : endTime,
        isAvailable : true
        });

        // 3. store flash sale
        uint currentSaleId = _saleIdCounter;
        _saleIdCounter = _saleIdCounter.add(1);
        _flashSales[currentSaleId] = flashSale;
        emit SetFlashSale(currentSaleId, flashSale.seller, flashSale.tokenAddress, flashSale.id,
            flashSale.remainingAmount, flashSale.payTokenAddress, flashSale.price, flashSale.receiver,
            flashSale.purchaseLimitation, flashSale.startTime, flashSale.endTime);
    }

    /**
     * @dev External function to update the existing flash sale by its setter in whitelist.
     * @param saleId uint The target id of flash sale to update
     * @param newTokenAddress address New Address of ERC1155 token contract
     * @param newId uint New id of ERC1155 token to sell
     * @param newAmount uint New amount of target ERC1155 token to sell
     * @param newPayTokenAddress address New ERC20 address of token for payment
     * @param newPrice uint New price of each ERC1155 token
     * @param newReceiver address New address of the receiver to gain the payment
     * @param newPurchaseLimitation uint New max number of ERC1155 token could be bought from an address
     * @param newStartTime uint New timestamp of the beginning of flash sale activity
     * @param newDuration uint New duration of this flash sale activity
     */
    function updateFlashSale(
        uint saleId,
        address newTokenAddress,
        uint newId,
        uint newAmount,
        address newPayTokenAddress,
        uint newPrice,
        address newReceiver,
        uint newPurchaseLimitation,
        uint newStartTime,
        uint newDuration
    )
    external
    nonReentrant
    onlyWhitelist
    onlyPaymentWhitelist(newPayTokenAddress)
    {
        FlashSale memory flashSale = getFlashSale(saleId);
        // 1. make sure that the flash sale doesn't start
        require(
            flashSale.startTime > now,
            "it's not allowed to update the flash sale after the start of it"
        );
        require(
            flashSale.isAvailable,
            "the flash sale has been cancelled"
        );
        require(
            flashSale.seller == msg.sender,
            "the flash sale can only be updated by its setter"
        );

        // 2. check the validity of params to update
        _checkFlashSaleParams(msg.sender, newTokenAddress, newId, newAmount, newPrice, newPurchaseLimitation,
            newStartTime);

        // 3. update flash sale
        uint endTime;
        if (newDuration != 0) {
            endTime = newStartTime.add(newDuration);
        }

        flashSale.tokenAddress = newTokenAddress;
        flashSale.id = newId;
        flashSale.remainingAmount = newAmount;
        flashSale.payTokenAddress = newPayTokenAddress;
        flashSale.price = newPrice;
        flashSale.receiver = newReceiver;
        flashSale.purchaseLimitation = newPurchaseLimitation;
        flashSale.startTime = newStartTime;
        flashSale.endTime = endTime;
        _flashSales[saleId] = flashSale;
        emit  UpdateFlashSale(saleId, flashSale.seller, flashSale.tokenAddress, flashSale.id, flashSale.remainingAmount,
            flashSale.payTokenAddress, flashSale.price, flashSale.receiver, flashSale.purchaseLimitation,
            flashSale.startTime, flashSale.endTime);
    }

    /**
     * @dev External function to cancel the existing flash sale by its setter in whitelist.
     * @param saleId uint The target id of flash sale to be cancelled
     */
    function cancelFlashSale(uint saleId) external onlyWhitelist {
        FlashSale memory flashSale = getFlashSale(saleId);
        require(
            flashSale.isAvailable,
            "the flash sale isn't available"
        );
        require(
            flashSale.seller == msg.sender,
            "the flash sale can only be cancelled by its setter"
        );

        _flashSales[saleId].isAvailable = false;
        emit CancelFlashSale(saleId, msg.sender);
    }

    /**
      * @dev External function to purchase ERC1155 from the target sale by anyone.
      * @param saleId uint The target id of flash sale to purchase
      * @param amount uint The amount of target ERC1155 to purchase
      */
    function purchase(uint saleId, uint amount) external nonReentrant {
        FlashSale memory flashSale = getFlashSale(saleId);
        // 1. check the validity
        require(
            amount > 0,
            "amount should be > 0"
        );
        require(
            flashSale.isAvailable,
            "the flash sale isn't available"
        );
        require(
            flashSale.seller != msg.sender,
            "the setter can't make a purchase from its own flash sale"
        );
        uint currentTime = now;
        require(
            currentTime >= flashSale.startTime,
            "the flash sale doesn't start"
        );
        // 2. check whether the end time arrives
        if (flashSale.endTime != 0 && flashSale.endTime <= currentTime) {
            // the flash sale has been set an end time and expired
            _flashSales[saleId].isAvailable = false;
            emit FlashSaleExpired(saleId, msg.sender);
            return;
        }

        // 3. check whether the amount of token rest in flash sale is sufficient for this trade
        require(amount <= flashSale.remainingAmount,
            "insufficient amount of token for this trade");
        // 4. check the purchase record of the buyer
        uint newPurchaseRecord = _flashSaleIdToPurchaseRecord[saleId][msg.sender].add(amount);
        require(newPurchaseRecord <= flashSale.purchaseLimitation,
            "total amount to purchase exceeds the limitation of an address");

        // 5. pay the receiver
        _flashSaleIdToPurchaseRecord[saleId][msg.sender] = newPurchaseRecord;
        uint totalPayment = flashSale.price.mul(amount);
        IERC20(flashSale.payTokenAddress).safeTransferFrom(msg.sender, flashSale.receiver, totalPayment);

        // 6. transfer ERC1155 tokens to buyer
        uint newRemainingAmount = flashSale.remainingAmount.sub(amount);
        _flashSales[saleId].remainingAmount = newRemainingAmount;
        if (newRemainingAmount == 0) {
            _flashSales[saleId].isAvailable = false;
        }

        IERC1155(flashSale.tokenAddress).safeTransferFrom(flashSale.seller, msg.sender, flashSale.id, amount, "");
        emit Purchase(saleId, msg.sender, flashSale.tokenAddress, flashSale.id, amount, flashSale.payTokenAddress,
            totalPayment);
    }

    /**
     * @dev Public function to set the whitelist of setting flash sale only by the owner.
     * @param memberAddr address Address of member to be added or removed
     * @param jurisdiction bool In or out of the whitelist
     */
    function setWhitelist(address memberAddr, bool jurisdiction) external onlyOwner {
        _whitelist[memberAddr] = jurisdiction;
        emit SetWhitelist(memberAddr, jurisdiction);
    }

    /**
     * @dev Public function to set the payment whitelist only by the owner.
     * @param erc20Addr address Address of erc20 for paying
     * @param jurisdiction bool In or out of the whitelist
     */
    function setPaymentWhitelist(address erc20Addr, bool jurisdiction) public onlyOwner {
        _paymentWhitelist[erc20Addr] = jurisdiction;
        emit PaymentWhitelistChange(erc20Addr, jurisdiction);
    }

    /**
     * @dev Public function to query whether the target erc20 address is in the payment whitelist.
     * @param erc20Addr address Target address of erc20 to query about
     */
    function getPaymentWhitelist(address erc20Addr) public view returns (bool){
        return _paymentWhitelist[erc20Addr];
    }

    /**
     * @dev Public function to query whether the target member address is in the whitelist.
     * @param memberAddr address Target address of member to query about
     */
    function getWhitelist(address memberAddr) public view returns (bool){
        return _whitelist[memberAddr];
    }

    /**
     * @dev Public function to query the flash sale by sale Id.
     * @param saleId uint Target sale Id of flash sale to query about
     */
    function getFlashSale(uint saleId) public view returns (FlashSale memory flashSale){
        flashSale = _flashSales[saleId];
        require(flashSale.seller != address(0), "the target flash sale doesn't exist");
    }

    /**
     * @dev Public function to query the purchase record of the amount that an address has bought.
     * @param saleId uint Target sale Id of flash sale to query about
     * @param buyer address Target address to query the record with
     */
    function getFlashSalePurchaseRecord(uint saleId, address buyer) public view returns (uint){
        // check whether the flash sale Id exists
        getFlashSale(saleId);
        return _flashSaleIdToPurchaseRecord[saleId][buyer];
    }


    function _checkFlashSaleParams(
        address saleSetter,
        address tokenAddress,
        uint id,
        uint amount,
        uint price,
        uint purchaseLimitation,
        uint startTime
    )
    private
    view
    {
        // check whether the sale setter has the target tokens && approval
        IERC1155 tokenAddressCached = IERC1155(tokenAddress);
        require(
            tokenAddressCached.balanceOf(saleSetter, id) >= amount,
            "insufficient amount of ERC1155"
        );
        require(
            tokenAddressCached.isApprovedForAll(saleSetter, address(this)),
            "the contract hasn't been approved for ERC1155 transferring"
        );
        require(amount > 0, "the amount must be > 0");
        require(price > 0, "the price must be > 0");
        require(startTime >= now, "startTime must be >= now");
        require(purchaseLimitation > 0, "purchaseLimitation must be > 0");
        require(purchaseLimitation <= amount, "purchaseLimitation must be <= amount");
    }
}