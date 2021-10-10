/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

// SPDX-License-Identifier: GPL-3.0-only
// File: @openzeppelin/contracts/GSN/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/math/SafeMath.sol


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721Holder.sol


pragma solidity >=0.6.0 <0.8.0;


  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


pragma solidity >=0.6.2 <0.8.0;


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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Metadata.sol


pragma solidity >=0.6.2 <0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: contracts/v1.5/SafeERC721.sol

pragma solidity ^0.6.0;



library SafeERC721
{
	function safeName(IERC721Metadata _metadata) internal view returns (string memory _name)
	{
		try _metadata.name() returns (string memory _n) { return _n; } catch {}
	}

	function safeSymbol(IERC721Metadata _metadata) internal view returns (string memory _symbol)
	{
		try _metadata.symbol() returns (string memory _s) { return _s; } catch {}
	}

	function safeTokenURI(IERC721Metadata _metadata, uint256 _tokenId) internal view returns (string memory _tokenURI)
	{
		try _metadata.tokenURI(_tokenId) returns (string memory _t) { return _t; } catch {}
	}

	function safeTransfer(IERC721 _token, address _to, uint256 _tokenId) internal
	{
		address _from = address(this);
		try _token.transferFrom(_from, _to, _tokenId) { return; } catch {}
		// attempts to handle non-conforming ERC721 contracts
		_token.approve(_from, _tokenId);
		_token.transferFrom(_from, _to, _tokenId);
	}
}

// File: contracts/v1.5/CollectivePurchase.sol

pragma solidity ^0.6.0;









interface IAuctionFractionalizer
{
	function fractionalize(address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice, address _paymentToken, uint256 _kickoff, uint256 _duration, uint256 _fee) external returns (address _fractions);
}

contract CollectivePurchase is ERC721Holder, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;
	using SafeERC721 for IERC721;
	using SafeMath for uint256;

	enum State { Created, Funded, Started, Ended }

	struct BuyerInfo {
		uint256 amount;
	}

	struct ListingInfo {
		State state;
		address payable seller;
		address collection;
		uint256 tokenId;
		address paymentToken;
		uint256 reservePrice;
		uint256 limitPrice;
		uint256 extension;
		uint256 priceMultiplier;
		bytes extra;
		uint256 amount;
		uint256 cutoff;
		uint256 fractionsCount;
		address fractions;
		mapping (address => BuyerInfo) buyers;
	}

	uint8 constant public FRACTIONS_DECIMALS = 6;
	uint256 constant public FRACTIONS_COUNT = 100000e6;

	uint256 public immutable fee;
	address payable public immutable vault;
	mapping (bytes32 => address) public fractionalizers;

	mapping (address => uint256) private balances;
	mapping (address => mapping (uint256 => bool)) private items;

	ListingInfo[] public listings;

	modifier onlySeller(uint256 _listingId)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(msg.sender == _listing.seller, "access denied");
		_;
	}

	modifier inState(uint256 _listingId, State _state)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(_state == _listing.state, "not available");
		_;
	}

	modifier notInState(uint256 _listingId, State _state)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(_state != _listing.state, "not available");
		_;
	}

	constructor (uint256 _fee, address payable _vault) public
	{
		require(_fee <= 1e18, "invalid fee");
		require(_vault != address(0), "invalid address");
		fee = _fee;
		vault = _vault;
	}

	function listingCount() external view returns (uint256 _count)
	{
		return listings.length;
	}

	function buyers(uint256 _listingId, address _buyer) external view returns (uint256 _amount)
	{
		ListingInfo storage _listing = listings[_listingId];
		BuyerInfo storage _info = _listing.buyers[_buyer];
		return _info.amount;
	}

	function status(uint256 _listingId) external view returns (string memory _status)
	{
		ListingInfo storage _listing = listings[_listingId];
		if (_listing.state == State.Created) return "CREATED";
		if (_listing.state == State.Funded) return "FUNDED";
		if (_listing.state == State.Started) return now <= _listing.cutoff ? "STARTED" : "ENDING";
		return "ENDED";
	}

	function maxJoinAmount(uint256 _listingId) external view returns (uint256 _amount)
	{
		ListingInfo storage _listing = listings[_listingId];
		return _listing.limitPrice - _listing.amount;
	}

	function buyerFractionsCount(uint256 _listingId, address _buyer) external view inState(_listingId, State.Ended) returns (uint256 _fractionsCount)
	{
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.buyers[_buyer].amount;
		_fractionsCount = (_amount * _listing.fractionsCount) / _listing.reservePrice;
		return _fractionsCount;
	}

	function sellerPayout(uint256 _listingId) external view returns (uint256 _netAmount, uint256 _feeAmount, uint256 _netFractionsCount, uint256 _feeFractionsCount)
	{
		ListingInfo storage _listing = listings[_listingId];
		uint256 _reservePrice = _listing.reservePrice;
		uint256 _amount = _listing.amount;
		_feeAmount = (_amount * fee) / 1e18;
		_netAmount = _amount - _feeAmount;
		_feeFractionsCount = 0;
		_netFractionsCount = 0;
		if (_reservePrice > _amount) {
			uint256 _missingAmount = _reservePrice - _amount;
			uint256 _missingFeeAmount = (_missingAmount * fee) / 1e18;
			uint256 _missingNetAmount = _missingAmount - _missingFeeAmount;
			uint256 _fractionsCount = _issuing(_listing.extra);
			_feeFractionsCount = _fractionsCount * _missingFeeAmount / _reservePrice;
			_netFractionsCount = _fractionsCount * _missingNetAmount / _reservePrice;
		}
	}

	function addFractionalizer(bytes32 _type, address _fractionalizer) external onlyOwner
	{
		require(fractionalizers[_type] == address(0), "already defined");
		fractionalizers[_type] = _fractionalizer;
		emit AddFractionalizer(_type, _fractionalizer);
	}

	function list(address _collection, uint256 _tokenId, address _paymentToken, uint256 _reservePrice, uint256 _limitPrice, uint256 _extension, uint256 _priceMultiplier, bytes calldata _extra) external nonReentrant returns (uint256 _listingId)
	{
		address payable _seller = msg.sender;
		require(_limitPrice * 1e18 / _limitPrice == 1e18, "price overflow");
		require(0 < _reservePrice && _reservePrice <= _limitPrice, "invalid price");
		require(30 minutes <= _extension && _extension <= 731 days, "invalid duration");
		require(0 < _priceMultiplier && _priceMultiplier <= 10000, "invalid multiplier"); // from 1% up to 100x
		_validate(_extra);
		IERC721(_collection).transferFrom(_seller, address(this), _tokenId);
		items[_collection][_tokenId] = true;
		_listingId = listings.length;
		listings.push(ListingInfo({
			state: State.Created,
			seller: _seller,
			collection: _collection,
			tokenId: _tokenId,
			paymentToken: _paymentToken,
			reservePrice: _reservePrice,
			limitPrice: _limitPrice,
			extension: _extension,
			priceMultiplier: _priceMultiplier,
			extra: _extra,
			amount: 0,
			cutoff: uint256(-1),
			fractionsCount: 0,
			fractions: address(0)
		}));
		emit Listed(_listingId);
		return _listingId;
	}

	function cancel(uint256 _listingId) external nonReentrant onlySeller(_listingId) inState(_listingId, State.Created)
	{
		ListingInfo storage _listing = listings[_listingId];
		_listing.state = State.Ended;
		items[_listing.collection][_listing.tokenId] = false;
		IERC721(_listing.collection).safeTransfer(_listing.seller, _listing.tokenId);
		emit Canceled(_listingId);
	}

	function updatePrice(uint256 _listingId, uint256 _newReservePrice, uint256 _newLimitPrice) external onlySeller(_listingId) inState(_listingId, State.Created)
	{
		require(_newLimitPrice * 1e18 / _newLimitPrice == 1e18, "price overflow");
		require(0 < _newReservePrice && _newReservePrice <= _newLimitPrice, "invalid price");
		ListingInfo storage _listing = listings[_listingId];
		uint256 _oldReservePrice = _listing.reservePrice;
		uint256 _oldLimitPrice = _listing.limitPrice;
		_listing.reservePrice = _newReservePrice;
		_listing.limitPrice = _newLimitPrice;
		emit UpdatePrice(_listingId, _oldReservePrice, _oldLimitPrice, _newReservePrice, _newLimitPrice);
	}

	function accept(uint256 _listingId) external onlySeller(_listingId) inState(_listingId, State.Funded)
	{
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.reservePrice - _listing.amount;
		uint256 _feeAmount = (_amount * fee) / 1e18;
		uint256 _netAmount = _amount - _feeAmount;
		_listing.state = State.Started;
		_listing.cutoff = now - 1;
		_listing.buyers[vault].amount += _feeAmount;
		_listing.buyers[_listing.seller].amount += _netAmount;
		emit Sold(_listingId);
	}

	function join(uint256 _listingId, uint256 _amount) external payable nonReentrant notInState(_listingId, State.Ended)
	{
		address payable _buyer = msg.sender;
		uint256 _value = msg.value;
		ListingInfo storage _listing = listings[_listingId];
		require(now <= _listing.cutoff, "not available");
		uint256 _leftAmount = _listing.limitPrice - _listing.amount;
		require(_amount <= _leftAmount, "limit exceeded");
		_safeTransferFrom(_listing.paymentToken, _buyer, _value, payable(address(this)), _amount);
		balances[_listing.paymentToken] += _amount;
		_listing.amount += _amount;
		_listing.buyers[_buyer].amount += _amount;
		if (_listing.state == State.Created) _listing.state = State.Funded;
		if (_listing.state == State.Funded) {
			if (_listing.amount >= _listing.reservePrice) {
				_listing.state = State.Started;
				_listing.cutoff = now + _listing.extension;
				emit Sold(_listingId);
			}
		}
		if (_listing.state == State.Started) _listing.reservePrice = _listing.amount;
		emit Join(_listingId, _buyer, _amount);
	}

	function leave(uint256 _listingId) external nonReentrant inState(_listingId, State.Funded)
	{
		address payable _buyer = msg.sender;
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.buyers[_buyer].amount;
		require(_amount > 0, "insufficient balance");
		_listing.buyers[_buyer].amount = 0;
		_listing.amount -= _amount;
		balances[_listing.paymentToken] -= _amount;
		if (_listing.amount == 0) _listing.state = State.Created;
		_safeTransfer(_listing.paymentToken, _buyer, _amount);
		emit Leave(_listingId, _buyer, _amount);
	}

	function relist(uint256 _listingId) public nonReentrant inState(_listingId, State.Started)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(now > _listing.cutoff, "not available");
		uint256 _fractionPrice = (_listing.reservePrice + (FRACTIONS_COUNT - 1)) / FRACTIONS_COUNT;
		uint256 _relistFractionPrice = (_listing.priceMultiplier * _fractionPrice + 99) / 100;
		_listing.state = State.Ended;
		_listing.fractions = _fractionalize(_listingId, _relistFractionPrice);
		_listing.fractionsCount = _balanceOf(_listing.fractions);
		items[_listing.collection][_listing.tokenId] = false;
		balances[_listing.fractions] = _listing.fractionsCount;
		emit Relisted(_listingId);
	}

	function payout(uint256 _listingId) public nonReentrant inState(_listingId, State.Ended)
	{
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.amount;
		require(_amount > 0, "insufficient balance");
		uint256 _feeAmount = (_amount * fee) / 1e18;
		uint256 _netAmount = _amount - _feeAmount;
		_listing.amount = 0;
		balances[_listing.paymentToken] -= _amount;
		_safeTransfer(_listing.paymentToken, vault, _feeAmount);
		_safeTransfer(_listing.paymentToken, _listing.seller, _netAmount);
		emit Payout(_listingId, _listing.seller, _netAmount, _feeAmount);
	}

	function claim(uint256 _listingId, address payable _buyer) public nonReentrant inState(_listingId, State.Ended)
	{
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.buyers[_buyer].amount;
		require(_amount > 0, "insufficient balance");
		uint256 _fractionsCount = (_amount * _listing.fractionsCount) / _listing.reservePrice;
		_listing.buyers[_buyer].amount = 0;
		balances[_listing.fractions] -= _fractionsCount;
		_safeTransfer(_listing.fractions, _buyer, _fractionsCount);
		emit Claim(_listingId, _buyer, _amount, _fractionsCount);
	}

	function relistPayoutAndClaim(uint256 _listingId, address payable[] calldata _buyers) external
	{
		ListingInfo storage _listing = listings[_listingId];
		if (_listing.state != State.Ended) {
			relist(_listingId);
		}
		if (_listing.amount > 0) {
			payout(_listingId);
		}
		if (_listing.buyers[vault].amount > 0) {
			claim(_listingId, vault);
		}
		if (_listing.buyers[_listing.seller].amount > 0) {
			claim(_listingId, _listing.seller);
		}
		for (uint256 _i = 0; _i < _buyers.length; _i++) {
			address payable _buyer = _buyers[_i];
			if (_listing.buyers[_buyer].amount > 0) {
				claim(_listingId, _buyer);
			}
		}
	}

	function recoverLostFunds(address _token, address payable _to) external onlyOwner nonReentrant
	{
		uint256 _balance = balances[_token];
		uint256 _current = _balanceOf(_token);
		if (_current > _balance) {
			uint256 _excess = _current - _balance;
			_safeTransfer(_token, _to, _excess);
		}
	}

	function recoverLostItem(address _collection, uint256 _tokenId, address _to) external onlyOwner nonReentrant
	{
		if (items[_collection][_tokenId]) return;
		IERC721(_collection).safeTransfer(_to, _tokenId);
	}

	function _validate(bytes calldata _extra) internal view
	{
		(bytes32 _type,,, uint256 _duration, uint256 _fee) = abi.decode(_extra, (bytes32, string, string, uint256, uint256));
		require(fractionalizers[_type] != address(0), "unsupported type");
		require(30 minutes <= _duration && _duration <= 731 days, "invalid duration");
		require(_fee <= 1e18, "invalid fee");
	}

	function _issuing(bytes storage _extra) internal pure returns (uint256 _fractionsCount)
	{
		(,,,, uint256 _fee) = abi.decode(_extra, (bytes32, string, string, uint256, uint256));
		return FRACTIONS_COUNT - (FRACTIONS_COUNT * _fee / 1e18);
	}

	function _fractionalize(uint256 _listingId, uint256 _fractionPrice) internal returns (address _fractions)
	{
		ListingInfo storage _listing = listings[_listingId];
		(bytes32 _type, string memory _name, string memory _symbol, uint256 _duration, uint256 _fee) = abi.decode(_listing.extra, (bytes32, string, string, uint256, uint256));
		IERC721(_listing.collection).approve(fractionalizers[_type], _listing.tokenId);
		return IAuctionFractionalizer(fractionalizers[_type]).fractionalize(_listing.collection, _listing.tokenId, _name, _symbol, FRACTIONS_DECIMALS, FRACTIONS_COUNT, _fractionPrice, _listing.paymentToken, 0, _duration, _fee);
	}

	function _balanceOf(address _token) internal view returns (uint256 _balance)
	{
		if (_token == address(0)) {
			return address(this).balance;
		} else {
			return IERC20(_token).balanceOf(address(this));
		}
	}

	function _safeTransfer(address _token, address payable _to, uint256 _amount) internal
	{
		if (_token == address(0)) {
			_to.transfer(_amount);
		} else {
			IERC20(_token).safeTransfer(_to, _amount);
		}
	}

	function _safeTransferFrom(address _token, address payable _from, uint256 _value, address payable _to, uint256 _amount) internal
	{
		if (_token == address(0)) {
			require(_value == _amount, "invalid value");
			if (_to != address(this)) _to.transfer(_amount);
		} else {
			require(_value == 0, "invalid value");
			IERC20(_token).safeTransferFrom(_from, _to, _amount);
		}
	}

	event AddFractionalizer(bytes32 indexed _type, address indexed _fractionalizer);
	event Listed(uint256 indexed _listingId);
	event Sold(uint256 indexed _listingId);
	event Relisted(uint256 indexed _listingId);
	event Canceled(uint256 indexed _listingId);
	event UpdatePrice(uint256 indexed _listingId, uint256 _oldReservePrice, uint256 _oldLimitPrice, uint256 _newReservePrice, uint256 _newLimitPrice);
	event Join(uint256 indexed _listingId, address indexed _buyer, uint256 _amount);
	event Leave(uint256 indexed _listingId, address indexed _buyer, uint256 _amount);
	event Payout(uint256 indexed _listingId, address indexed _seller, uint256 _netAmount, uint256 _feeAmount);
	event Claim(uint256 indexed _listingId, address indexed _buyer, uint256 _amount, uint256 _fractionsCount);
}