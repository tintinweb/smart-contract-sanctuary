/**
 *Submitted for verification at Etherscan.io on 2021-08-23
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

// File: contracts/Dependencies/IERC721.sol

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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

// File: contracts/proxy/Sales721.sol

contract Sales721 is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint private saleIDCounter;
    bool private onlyInitOnce;

    struct BaseSale {
        // the sale setter
        address seller;
        // addresses of token to sell
        address[] tokenAddresses;
        // tokenIDs of token to sell
        uint[] tokenIDs;
        // address of token to pay
        address payTokenAddress;
        // price of token to pay
        uint price;
        // address of receiver
        address receiver;
        uint startTime;
        uint endTime;
        // whether the sale is available
        bool isAvailable;
    }

    struct FlashSale {
        BaseSale base;
        // max number of token could be bought from an address
        uint purchaseLimitation;
    }

    struct Auction {
        BaseSale base;
        // the minimum increment in a bid
        uint minBidIncrement;
        // the highest price so far
        uint highestBidPrice;
        // the highest bidder so far
        address highestBidder;
    }

    // whitelist to set sale
    mapping(address => bool) public whitelist;
    // sale ID -> flash sale
    mapping(uint => FlashSale) flashSales;
    // sale ID -> mapping(address => how many tokens have bought)
    mapping(uint => mapping(address => uint)) flashSaleIDToPurchaseRecord;
    // sale ID -> auction
    mapping(uint => Auction) auctions;
    // filter to check repetition
    mapping(address => mapping(uint => bool)) repetitionFilter;

    event SetWhitelist(address _member, bool _isAdded);
    event SetFlashSale(uint _saleID, address _flashSaleSetter, address[] _tokenAddresses, uint[] _tokenIDs, address _payTokenAddress,
        uint _price, address _receiver, uint _purchaseLimitation, uint _startTime, uint _endTime);
    event UpdateFlashSale(uint _saleID, address _operator, address[] _newTokenAddresses, uint[] _newTokenIDs, address _newPayTokenAddress,
        uint _newPrice, address _newReceiver, uint _newPurchaseLimitation, uint _newStartTime, uint _newEndTime);
    event CancelFlashSale(uint _saleID, address _operator);
    event FlashSaleExpired(uint _saleID, address _operator);
    event Purchase(uint _saleID, address _buyer, address[] _tokenAddresses, uint[] _tokenIDs, address _payTokenAddress, uint _totalPayment);
    event SetAuction(uint _saleID, address _auctionSetter, address[] _tokenAddresses, uint[] _tokenIDs, address _payTokenAddress,
        uint _initialPrice, address _receiver, uint _minBidIncrement, uint _startTime, uint _endTime);
    event UpdateAuction(uint _saleID, address _operator, address[] _newTokenAddresses, uint[] _newTokenIDs, address _newPayTokenAddress,
        uint _newInitialPrice, address _newReceiver, uint _newMinBidIncrement, uint _newStartTime, uint _newEndTime);
    event RefundToPreviousBidder(uint _saleID, address _previousBidder, address _payTokenAddress, uint _refundAmount);
    event CancelAuction(uint _saleID, address _operator);
    event NewBidderTransfer(uint _saleID, address _newBidder, address _payTokenAddress, uint _bidPrice);
    event SettleAuction(uint _saleID, address _operator, address _receiver, address _highestBidder, address[] _tokenAddresses, uint[] _tokenIDs, address _payTokenAddress, uint _highestBidPrice);

    modifier onlyWhitelist() {
        require(whitelist[msg.sender],
            "the caller isn't in the whitelist");
        _;
    }

    function init(address _newOwner) public {
        require(!onlyInitOnce, "already initialized");

        _transferOwnership(_newOwner);
        onlyInitOnce = true;
    }

    function setWhitelist(address _member, bool _status) external onlyOwner {
        whitelist[_member] = _status;
        emit SetWhitelist(_member, _status);
    }

    // set auction by the member in whitelist
    function setAuction(
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        address _payTokenAddress,
        uint _initialPrice,
        address _receiver,
        uint _minBidIncrement,
        uint _startTime,
        uint _duration
    ) external nonReentrant onlyWhitelist {
        // 1. check the validity of params
        _checkAuctionParams(msg.sender, _tokenAddresses, _tokenIDs, _initialPrice, _minBidIncrement, _startTime, _duration);

        // 2. build auction
        Auction memory auction = Auction({
        base : BaseSale({
        seller : msg.sender,
        tokenAddresses : _tokenAddresses,
        tokenIDs : _tokenIDs,
        payTokenAddress : _payTokenAddress,
        price : _initialPrice,
        receiver : _receiver,
        startTime : _startTime,
        endTime : _startTime.add(_duration),
        isAvailable : true
        }),
        minBidIncrement : _minBidIncrement,
        highestBidPrice : 0,
        highestBidder : address(0)
        });

        // 3. store auction
        uint currentSaleID = saleIDCounter;
        saleIDCounter = saleIDCounter.add(1);
        auctions[currentSaleID] = auction;
        emit SetAuction(currentSaleID, auction.base.seller, auction.base.tokenAddresses, auction.base.tokenIDs,
            auction.base.payTokenAddress, auction.base.price, auction.base.receiver, auction.minBidIncrement,
            auction.base.startTime, auction.base.endTime);
    }

    // update auction by the member in whitelist
    function updateAuction(
        uint _saleID,
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        address _payTokenAddress,
        uint _initialPrice,
        address _receiver,
        uint _minBidIncrement,
        uint _startTime,
        uint _duration
    ) external nonReentrant onlyWhitelist {
        Auction memory auction = _getAuctionByID(_saleID);
        // 1. make sure that the auction doesn't start
        require(auction.base.startTime > now,
            "it's not allowed to update the auction after the start of it");
        require(auction.base.isAvailable,
            "the auction has been cancelled");
        require(auction.base.seller == msg.sender,
            "the auction can only be updated by its setter");

        // 2. check the validity of params to update
        _checkAuctionParams(msg.sender, _tokenAddresses, _tokenIDs, _initialPrice, _minBidIncrement, _startTime, _duration);

        // 3. update the auction
        auction.base.tokenAddresses = _tokenAddresses;
        auction.base.tokenIDs = _tokenIDs;
        auction.base.payTokenAddress = _payTokenAddress;
        auction.base.price = _initialPrice;
        auction.base.receiver = _receiver;
        auction.base.startTime = _startTime;
        auction.base.endTime = _startTime.add(_duration);
        auction.minBidIncrement = _minBidIncrement;
        auctions[_saleID] = auction;
        emit UpdateAuction(_saleID, auction.base.seller, auction.base.tokenAddresses, auction.base.tokenIDs,
            auction.base.payTokenAddress, auction.base.price, auction.base.receiver, auction.minBidIncrement,
            auction.base.startTime, auction.base.endTime);
    }

    // cancel the auction
    function cancelAuction(uint _saleID) external nonReentrant onlyWhitelist {
        Auction memory auction = _getAuctionByID(_saleID);
        require(auction.base.isAvailable,
            "the auction isn't available");
        require(auction.base.seller == msg.sender,
            "the auction can only be cancelled by its setter");

        if (auction.highestBidPrice != 0) {
            // some bid has paid for this auction
            IERC20(auction.base.payTokenAddress).safeTransfer(auction.highestBidder, auction.highestBidPrice);
            emit RefundToPreviousBidder(_saleID, auction.highestBidder, auction.base.payTokenAddress, auction.highestBidPrice);
        }

        auctions[_saleID].base.isAvailable = false;
        emit CancelAuction(_saleID, msg.sender);
    }

    // bid for the target auction
    function bid(uint _saleID, uint _bidPrice) external nonReentrant {
        Auction memory auction = _getAuctionByID(_saleID);
        // check the validity of the target auction
        require(auction.base.isAvailable,
            "the auction isn't available");
        require(auction.base.seller != msg.sender,
            "the setter can't bid for its own auction");
        uint currentTime = now;
        require(currentTime >= auction.base.startTime,
            "the auction doesn't start");
        require(currentTime < auction.base.endTime,
            "the auction has expired");

        IERC20 payToken = IERC20(auction.base.payTokenAddress);
        // check bid price in auction
        if (auction.highestBidPrice != 0) {
            // not first bid
            require(_bidPrice.sub(auction.highestBidPrice) >= auction.minBidIncrement,
                "the bid price must be larger than the sum of current highest one and minimum bid increment");
            // refund to the previous highest bidder from this contract
            payToken.safeTransfer(auction.highestBidder, auction.highestBidPrice);
            emit RefundToPreviousBidder(_saleID, auction.highestBidder, auction.base.payTokenAddress, auction.highestBidPrice);
        } else {
            // first bid
            require(_bidPrice == auction.base.price,
                "first bid must follow the initial price set in the auction");
        }

        // update storage auctions
        auctions[_saleID].highestBidPrice = _bidPrice;
        auctions[_saleID].highestBidder = msg.sender;

        // transfer the bid price into this contract
        payToken.safeApprove(address(this), 0);
        payToken.safeApprove(address(this), _bidPrice);
        payToken.safeTransferFrom(msg.sender, address(this), _bidPrice);
        emit NewBidderTransfer(_saleID, msg.sender, auction.base.payTokenAddress, _bidPrice);
    }

    // settle the auction by the member in whitelist
    function settleAuction(uint _saleID) external nonReentrant onlyWhitelist {
        Auction memory auction = _getAuctionByID(_saleID);
        // check the validity of the target auction
        require(auction.base.isAvailable,
            "only the available auction can be settled");
        require(auction.base.endTime <= now,
            "the auction can only be settled after its end time");

        if (auction.highestBidPrice != 0) {
            // the auction has been bidden
            // transfer pay token to the receiver from this contract
            IERC20(auction.base.payTokenAddress).safeTransfer(auction.base.receiver, auction.highestBidPrice);
            // transfer erc721s to the bidder who keeps the highest price
            for (uint i = 0; i < auction.base.tokenAddresses.length; i++) {
                IERC721(auction.base.tokenAddresses[i]).safeTransferFrom(auction.base.seller, auction.highestBidder, auction.base.tokenIDs[i]);
            }
        }

        // close the auction
        auctions[_saleID].base.isAvailable = false;
        emit SettleAuction(_saleID, msg.sender, auction.base.receiver, auction.highestBidder, auction.base.tokenAddresses,
            auction.base.tokenIDs, auction.base.payTokenAddress, auction.highestBidPrice);

    }

    // set flash sale by the member in whitelist
    // NOTE: set 0 duration if you don't want an endTime
    function setFlashSale(
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        address _payTokenAddress,
        uint _price,
        address _receiver,
        uint _purchaseLimitation,
        uint _startTime,
        uint _duration
    ) external nonReentrant onlyWhitelist {
        // 1. check the validity of params
        _checkFlashSaleParams(msg.sender, _tokenAddresses, _tokenIDs, _price, _startTime, _purchaseLimitation);

        // 2.  build flash sale
        uint endTime;
        if (_duration != 0) {
            endTime = _startTime.add(_duration);
        }

        FlashSale memory flashSale = FlashSale({
        base : BaseSale({
        seller : msg.sender,
        tokenAddresses : _tokenAddresses,
        tokenIDs : _tokenIDs,
        payTokenAddress : _payTokenAddress,
        price : _price,
        receiver : _receiver,
        startTime : _startTime,
        endTime : endTime,
        isAvailable : true
        }),
        purchaseLimitation : _purchaseLimitation
        });

        // 3. store flash sale
        uint currentSaleID = saleIDCounter;
        saleIDCounter = saleIDCounter.add(1);
        flashSales[currentSaleID] = flashSale;
        emit SetFlashSale(currentSaleID, flashSale.base.seller, flashSale.base.tokenAddresses, flashSale.base.tokenIDs,
            flashSale.base.payTokenAddress, flashSale.base.price, flashSale.base.receiver, flashSale.purchaseLimitation,
            flashSale.base.startTime, flashSale.base.endTime);
    }

    // update the flash sale before starting
    // NOTE: set 0 duration if you don't want an endTime
    function updateFlashSale(
        uint _saleID,
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        address _payTokenAddress,
        uint _price,
        address _receiver,
        uint _purchaseLimitation,
        uint _startTime,
        uint _duration
    ) external nonReentrant onlyWhitelist {
        FlashSale memory flashSale = _getFlashSaleByID(_saleID);
        // 1. make sure that the flash sale doesn't start
        require(flashSale.base.startTime > now,
            "it's not allowed to update the flash sale after the start of it");
        require(flashSale.base.isAvailable,
            "the flash sale has been cancelled");
        require(flashSale.base.seller == msg.sender,
            "the flash sale can only be updated by its setter");

        // 2. check the validity of params to update
        _checkFlashSaleParams(msg.sender, _tokenAddresses, _tokenIDs, _price, _startTime, _purchaseLimitation);

        // 3. update flash sale
        uint endTime;
        if (_duration != 0) {
            endTime = _startTime.add(_duration);
        }

        flashSale.base.tokenAddresses = _tokenAddresses;
        flashSale.base.tokenIDs = _tokenIDs;
        flashSale.base.payTokenAddress = _payTokenAddress;
        flashSale.base.price = _price;
        flashSale.base.receiver = _receiver;
        flashSale.base.startTime = _startTime;
        flashSale.base.endTime = endTime;
        flashSale.purchaseLimitation = _purchaseLimitation;
        flashSales[_saleID] = flashSale;
        emit UpdateFlashSale(_saleID, flashSale.base.seller, flashSale.base.tokenAddresses, flashSale.base.tokenIDs,
            flashSale.base.payTokenAddress, flashSale.base.price, flashSale.base.receiver, flashSale.purchaseLimitation,
            flashSale.base.startTime, flashSale.base.endTime);
    }

    // cancel the flash sale
    function cancelFlashSale(uint _saleID) external onlyWhitelist {
        FlashSale memory flashSale = _getFlashSaleByID(_saleID);
        require(flashSale.base.isAvailable,
            "the flash sale isn't available");
        require(flashSale.base.seller == msg.sender,
            "the flash sale can only be cancelled by its setter");

        flashSales[_saleID].base.isAvailable = false;
        emit CancelFlashSale(_saleID, msg.sender);
    }

    // rush to purchase by anyone
    function purchase(uint _saleID, uint _amount) external nonReentrant {
        FlashSale memory flashSale = _getFlashSaleByID(_saleID);
        // check the validity
        require(_amount > 0,
            "amount should be > 0");
        require(flashSale.base.isAvailable,
            "the flash sale isn't available");
        require(flashSale.base.seller != msg.sender,
            "the setter can't make a purchase from its own flash sale");
        uint currentTime = now;
        require(currentTime >= flashSale.base.startTime,
            "the flash sale doesn't start");
        // check whether the end time arrives
        if (flashSale.base.endTime != 0 && flashSale.base.endTime <= currentTime) {
            // the flash sale has been set an end time and expired
            flashSales[_saleID].base.isAvailable = false;
            emit FlashSaleExpired(_saleID, msg.sender);
            return;
        }
        // check the purchase record of the buyer
        uint newPurchaseRecord = flashSaleIDToPurchaseRecord[_saleID][msg.sender].add(_amount);
        require(newPurchaseRecord <= flashSale.purchaseLimitation,
            "total amount to purchase exceeds the limitation of an address");
        // check whether the amount of token rest in flash sale is sufficient for this trade
        require(_amount <= flashSale.base.tokenIDs.length,
            "insufficient amount of token for this trade");

        // pay the receiver
        flashSaleIDToPurchaseRecord[_saleID][msg.sender] = newPurchaseRecord;
        uint totalPayment = flashSale.base.price.mul(_amount);
        IERC20(flashSale.base.payTokenAddress).safeTransferFrom(msg.sender, flashSale.base.receiver, totalPayment);

        // transfer erc721 tokens to buyer
        address[] memory tokenAddressesRecord = new address[](_amount);
        uint[] memory tokenIDsRecord = new uint[](_amount);
        uint targetIndex = flashSale.base.tokenIDs.length - 1;
        for (uint i = 0; i < _amount; i++) {
            IERC721(flashSale.base.tokenAddresses[targetIndex]).safeTransferFrom(flashSale.base.seller, msg.sender, flashSale.base.tokenIDs[targetIndex]);
            tokenAddressesRecord[i] = flashSale.base.tokenAddresses[targetIndex];
            tokenIDsRecord[i] = flashSale.base.tokenIDs[targetIndex];
            targetIndex--;
            flashSales[_saleID].base.tokenAddresses.pop();
            flashSales[_saleID].base.tokenIDs.pop();
        }

        if (flashSale.base.tokenIDs.length == 0) {
            flashSales[_saleID].base.isAvailable = false;
        }

        emit Purchase(_saleID, msg.sender, tokenAddressesRecord, tokenIDsRecord, flashSale.base.payTokenAddress, totalPayment);
    }

    function getFlashSaleTokenRemaining(uint _saleID) public view returns (uint){
        // check whether the flash sale ID exists
        FlashSale memory flashSale = _getFlashSaleByID(_saleID);
        return flashSale.base.tokenIDs.length;
    }

    function getFlashSalePurchaseRecord(uint _saleID, address _buyer) public view returns (uint){
        // check whether the flash sale ID exists
        _getFlashSaleByID(_saleID);
        return flashSaleIDToPurchaseRecord[_saleID][_buyer];
    }


    function getAuction(uint _saleID) public view returns (Auction memory){
        return _getAuctionByID(_saleID);
    }

    function getFlashSale(uint _saleID) public view returns (FlashSale memory){
        return _getFlashSaleByID(_saleID);
    }

    function _getAuctionByID(uint _saleID) internal view returns (Auction memory auction){
        auction = auctions[_saleID];
        require(auction.base.seller != address(0),
            "the target auction doesn't exist");
    }

    function _getFlashSaleByID(uint _saleID) internal view returns (FlashSale memory flashSale){
        flashSale = flashSales[_saleID];
        require(flashSale.base.seller != address(0),
            "the target flash sale doesn't exist");
    }

    function _checkAuctionParams(
        address _baseSaleSetter,
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        uint _initialPrice,
        uint _minBidIncrement,
        uint _startTime,
        uint _duration
    ) internal {
        _checkBaseSaleParams(_baseSaleSetter, _tokenAddresses, _tokenIDs, _initialPrice, _startTime);
        require(_minBidIncrement > 0,
            "minBidIncrement must be > 0");
        require(_duration > 0,
            "duration must be > 0");
    }

    function _checkFlashSaleParams(
        address _baseSaleSetter,
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        uint _price,
        uint _startTime,
        uint _purchaseLimitation
    ) internal {
        uint standardLen = _checkBaseSaleParams(_baseSaleSetter, _tokenAddresses, _tokenIDs, _price, _startTime);
        require(_purchaseLimitation > 0,
            "purchaseLimitation must be > 0");
        require(_purchaseLimitation <= standardLen,
            "purchaseLimitation must be <= the length of tokenAddresses");
    }

    function _checkBaseSaleParams(
        address _baseSaleSetter,
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        uint _price,
        uint _startTime
    ) internal returns (uint standardLen){
        standardLen = _tokenAddresses.length;
        require(standardLen > 0,
            "length of tokenAddresses must be > 0");
        require(standardLen == _tokenIDs.length,
            "length of tokenIDs is wrong");
        // check whether the sale setter has the target tokens && approval
        IERC721 tokenAddressCached;
        uint tokenIDCached;
        for (uint i = 0; i < standardLen; i++) {
            tokenAddressCached = IERC721(_tokenAddresses[i]);
            tokenIDCached = _tokenIDs[i];
            // check repetition
            require(!repetitionFilter[address(tokenAddressCached)][tokenIDCached],
                "repetitive ERC721 tokens");
            repetitionFilter[address(tokenAddressCached)][tokenIDCached] = true;
            require(tokenAddressCached.ownerOf(tokenIDCached) == _baseSaleSetter,
                "unmatched ownership of target ERC721 token");
            require(
                tokenAddressCached.getApproved(tokenIDCached) == address(this) ||
                tokenAddressCached.isApprovedForAll(_baseSaleSetter, address(this)),
                "the contract hasn't been approved for ERC721 transferring");
        }

        require(_price > 0,
            "the price or the initial price must be > 0");
        require(_startTime >= now,
            "startTime must be >= now");

        // clear filter
        for (uint i = 0; i < standardLen; i++) {
            repetitionFilter[_tokenAddresses[i]][_tokenIDs[i]] = false;
        }
    }
}