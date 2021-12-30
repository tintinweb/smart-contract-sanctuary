/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-27
*/

pragma solidity >=0.8.0<=0.8.9;


// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)
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


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)
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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)
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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)
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


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)
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


// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)
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
interface IERC20Mintable is IERC20 {
    function mint(address to, uint256 amount) external;
}


contract Founder is IERC721Receiver, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Mintable;
    using SafeERC20 for IERC20;
   
    IERC721 public mercenary;
    IERC20 public token;

    Join[] public joins;
    
    struct Join {
        uint256 amount;
        address userAddress;
    }

    struct StakerInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 timestamp;
        address ref;
    }
    InfoNft[] public infoNfts;
    struct InfoNft {
        uint256 price;
        uint256 tokenId;
        bool status;
    }

    StakeDetail[] public StakeDetails;

    struct StakeDetail {
        address payable author;
        uint256 price;
        uint256 tokenId;
    }

    mapping ( uint256 => InfoNft ) public _infoNft;
    mapping ( uint256 => StakeDetail ) stakeDetail;
    mapping (address => StakerInfo) public _stakers;
    uint256 public _stakeRewardMinted;
    uint256 public _stakeRewardPerBlock;
    uint256 public _totalStake;
    uint256 public _stakeRewardLeft;
    uint256 public _accAmountPerShare;
    uint256 public _lastRewardBlock;
    uint256 public _finalRewardBlock;
    IERC20Mintable public _rewardToken;
    IERC20Mintable public _lpToken;
    uint256 public _totalShare;
    uint256 public _startBlock;
    uint256 totalLockedAmount;
    uint256[] public stakedNft;
    

    event StakeNft(address indexed _from, uint256 _tokenId, uint256 _price);
    event UnstakeNft(address indexed _from,uint256 _tokenId);
    event BuyNft(address indexed _from,uint256 _tokenId, uint256 _price);


    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function getJoinsv1() public view returns(address[] memory, uint256[] memory){
        address[] memory userAddresses = new address[](joins.length);
        uint256[] memory amounts = new uint256[](joins.length);

        for(uint256 i = 0; i < joins.length; i++){

            userAddresses[i] = joins[i].userAddress;
            amounts[i] = joins[i].amount;

        }
        return (userAddresses, amounts);
    }

    function getJoinsv2() public view returns(Join[] memory){
        return  joins;
    }
    // function joins() public view returns(address[] memory)
    // {
    //     return arrJoins;
    // }

    function getStakeerAmount(address _staker) public view returns(uint256 amount)
    {
        return _stakers[_staker].amount;
    }

    function getStakerRewardDebt(address _staker) public view returns(uint256 rewardDebt)
    {
        return _stakers[_staker].rewardDebt;
    }

    function getStakerTimestamp(address _staker) public view returns(uint256 timestamp)
    {
        return _stakers[_staker].timestamp;
    }

        function getStakerRef(address _staker) public view returns(address ref)
    {
        return _stakers[_staker].ref;
    }


   function startStaking(uint256 startBlock) external onlyOwner {
        require(block.number <= startBlock, "invalid start block");

        _startBlock = startBlock;
    }
    constructor(address rewardToken,  address lpToken,
            uint256 stakeRewardCap, uint256 stakeRewardPerBlock, IERC721 _mercenary, IERC20 _token) {
        _rewardToken = IERC20Mintable(rewardToken);        
        _lpToken = IERC20Mintable(lpToken);    
        _stakeRewardLeft = stakeRewardCap;
        _stakeRewardPerBlock = stakeRewardPerBlock;  
        mercenary = _mercenary;
        token = _token;     
    }
    function setRewardToken(address rewardToken) public onlyOwner {
        _rewardToken = IERC20Mintable(rewardToken);
    } 

    function mintRewardToken(uint256 amount) public onlyOwner {
        _rewardToken.mint(address(this), amount);
    } 
    function setLpToken(address lpToken) public onlyOwner {
        _lpToken = IERC20Mintable(lpToken);
    } 

    // in effect from last reward block
    function changeStakeReward(uint256 reward) external onlyOwner {
        require(reward != _stakeRewardPerBlock, "no change");
        _stakeRewardPerBlock = reward;
    }

    function update() internal {
        uint256 lastRewardBlock = _lastRewardBlock;
        uint256 rewardPerBlock = _stakeRewardPerBlock;
        uint256 rewardLeft = _stakeRewardLeft;
        uint256 blockNum = block.number;

        if (_finalRewardBlock > 0) {
            blockNum = _finalRewardBlock;
        }

        if (_totalStake == 0) {
            _lastRewardBlock = block.number;
            return;
        }

        if (block.number <= _startBlock) {
            return;
        }

        uint256 multiplier = block.number.sub(lastRewardBlock);
        uint256 reward = multiplier.mul(rewardPerBlock);
        if (reward > rewardLeft) {
            reward = rewardLeft.div(rewardPerBlock).mul(rewardPerBlock);
            _finalRewardBlock = lastRewardBlock.add(reward.div(rewardPerBlock));
        }

        _stakeRewardLeft = rewardLeft.sub(reward);
        _accAmountPerShare = _accAmountPerShare.add(reward.mul(1e12).div(_totalStake));
        _lastRewardBlock = block.number;
        _rewardToken.mint(address(this), reward);
    }

    function push(uint256[] storage array, uint256 element) private {
        for (uint256 index = 0; index < array.length; index++) {
            if (array[index] == element) {
                return;
            }
        }
        array.push(element);
    }
    function pop(uint256[] storage array, uint256 element) private {
        for (uint256 index = 0; index < array.length; index++) {
            if (array[index] == element) {
                array[index] = array[array.length - 1];
                array.pop();
                // delete array[index];
                return;
            }
        }
    }

    function stakeNft(uint256 _tokenId, uint256 _price) public onlyOwner{
        // require(mercenary.ownerOf(_tokenId) == msg.sender);
        // require(mercenary.getApproved(_tokenId) == address(this));

        // push(stakedNft, _tokenId);
        _infoNft[_tokenId] = InfoNft(_price, _tokenId, true);

        // InfoNft memory arrJoins = InfoNft(_price, _tokenId, true);
        // infoNfts.push(arrJoins);
        // stakeDetail[_tokenId] = StakeDetail(payable(msg.sender), _price, _tokenId);

        // mercenary.safeTransferFrom(msg.sender, address(this), _tokenId);

        // emit StakeNft(msg.sender,_tokenId, _price);
    }

    function getStakingAmount() view public returns (uint256) {
        return stakedNft.length;
    }
    function getStakingAmount(address _address) view public returns (uint256) {
        uint256 total = 0;
        for (uint256 index = 0; index < stakedNft.length; index++) {
            if (stakeDetail[stakedNft[index]].author == _address) {
                total += 1;
            }
        }

        return total;
    }
    
    function getStakedNft() view public returns (StakeDetail [] memory) {
        uint256 length = getStakingAmount();
        StakeDetail[] memory myNft = new StakeDetail[](length);
        uint count = 0;

        for (uint256 index = 0; index < stakedNft.length; index++) {
            myNft[count++] = stakeDetail[stakedNft[index]];
        }
        
        return myNft;
    }

    function getStakedNft(address _address) view public returns (StakeDetail [] memory) {
        uint256 length = getStakingAmount(_address);
        StakeDetail[] memory myNft = new StakeDetail[](length);
        uint count = 0;

        for (uint256 index = 0; index < stakedNft.length; index++) {
            if (stakeDetail[stakedNft[index]].author == _address) {
                myNft[count++] = stakeDetail[stakedNft[index]];
            }
        }
        
        return myNft;
    }

    function unstakeNft(uint256 _tokenId, uint256 _price, bool status) public onlyOwner{
        _infoNft[_tokenId] = InfoNft(_tokenId, _price, status);
    }

    function getTest(uint256 _tokenId) view public returns (uint256) {
        return _infoNft[_tokenId].price;
    }

    function stake(uint256 _tokenId) public {
        // require(_infoNft[_tokenId].price > 0, 'chua ton tai token');
        require(_infoNft[_tokenId].status == true, 'token not working');
        require(mercenary.ownerOf(_tokenId) == msg.sender, 'not the owner');
        require(mercenary.getApproved(_tokenId) == address(this), 'unlicensed');

        uint256 amount = _infoNft[_tokenId].price;

        push(stakedNft, _tokenId);
        stakeDetail[_tokenId] = StakeDetail(payable(msg.sender), amount, _tokenId);

        mercenary.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit StakeNft(msg.sender,_tokenId, amount);


        
        StakerInfo storage staker = _stakers[msg.sender];
        update();

        if (staker.amount > 0) {
            uint256 pending = staker.amount.mul(_accAmountPerShare).div(1e12).sub(staker.rewardDebt);

            _stakeRewardMinted = _stakeRewardMinted.add(pending);
            _rewardToken.mint(msg.sender, pending);
           // _rewardToken.safeTransfer(msg.sender, pending); // return pending reward
        }

        _totalStake = _totalStake.add(amount);
        staker.timestamp = staker.amount.add(block.timestamp);
        staker.amount = staker.amount.add(amount);
        staker.rewardDebt = staker.amount.mul(_accAmountPerShare).div(1e12);

        // _lpToken.safeTransferFrom(msg.sender, address(this), amount); // move staking amount in
        
        Join memory arrJoins = Join(amount, msg.sender);
        joins.push(arrJoins);
    }

    function unstake(uint256 _tokenId) public {
        require(mercenary.ownerOf(_tokenId) == address(this), "This NFT doesn't exist on market");
        require(stakeDetail[_tokenId].author == msg.sender, "Only owner can unstake this NFT");
        pop(stakedNft, _tokenId);
        mercenary.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit UnstakeNft(msg.sender,_tokenId);

        uint256 amount = _infoNft[_tokenId].price;
        // require(amount > 0, "amount must be greater than zero");

        StakerInfo storage staker = _stakers[msg.sender];
        require(staker.amount >= amount, "staked amount not enough");
        update();

        uint256 pending = staker.amount.mul(_accAmountPerShare).div(1e12).sub(staker.rewardDebt);
        _rewardToken.safeTransfer(msg.sender, pending); // return pending reward
        _stakeRewardMinted = _stakeRewardMinted.add(pending);

        staker.amount = staker.amount.sub(amount);
        staker.rewardDebt = staker.amount.mul(_accAmountPerShare).div(1e12);
        _totalStake = _totalStake.sub(amount);
        
        // _lpToken.safeTransfer(msg.sender, amount);
    }

    function getStakeReward(address stakerAddr) external view returns (uint256) {
        StakerInfo storage staker = _stakers[stakerAddr];

        uint256 accAmountPerShare = _accAmountPerShare;

        if (block.number > _lastRewardBlock && _totalStake != 0) {
            uint256 multiplier = block.number.sub(_lastRewardBlock);
            uint256 reward = multiplier.mul(_stakeRewardPerBlock);
            accAmountPerShare = accAmountPerShare.add(reward.mul(1e12).div(_totalStake));
        }

        return staker.amount.mul(accAmountPerShare).div(1e12).sub(staker.rewardDebt);
    }

    function redeemStakeReward() external {
        StakerInfo storage staker = _stakers[msg.sender];
        update();

        uint256 pending = staker.amount.mul(_accAmountPerShare).div(1e12).sub(staker.rewardDebt);
        staker.rewardDebt = staker.amount.mul(_accAmountPerShare).div(1e12);

        _stakeRewardMinted = _stakeRewardMinted.add(pending);
        _rewardToken.safeTransfer(msg.sender, pending); // return pending reward
    }


    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawErc20(IERC20 _token) public onlyOwner {
        token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

}