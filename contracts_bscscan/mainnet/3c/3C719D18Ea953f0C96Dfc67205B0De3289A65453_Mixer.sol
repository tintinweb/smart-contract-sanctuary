/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
pragma solidity ^0.6.0;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
contract Ownable is Context {
    address private _owner;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
pragma solidity ^0.6.0;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
// File: @openzeppelin/contracts/utils/Address.sol
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
pragma solidity ^0.6.2;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
pragma solidity ^0.6.0;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
// File: @openzeppelin/contracts/introspection/IERC165.sol
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
pragma solidity ^0.6.0;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
// File: @openzeppelin/contracts/token/ERC721/IERC721.sol
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
pragma solidity ^0.6.2;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
pragma solidity ^0.6.0;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
// File: @openzeppelin/contracts/token/ERC721/ERC721Holder.sol
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
pragma solidity ^0.6.0;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
library EnumerableSet {
    struct Set {
        bytes32[] _values;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        mapping (bytes32 => uint256) _indexes;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        if (valueIndex != 0) { 
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
            delete set._indexes[value];
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
            return true;
        } else {
            return false;
        }
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    struct AddressSet {
        Set _inner;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    struct UintSet {
        Set _inner;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
pragma solidity >=0.6.0;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
library EnumerableMap {
    struct MapEntry {
        uint256 _key;
        uint256 _value;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    struct Map {
        MapEntry[] _entries;
        mapping(uint256 => uint256) _indexes;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _set(
        Map storage map,
        uint256 key,
        uint256 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        if (keyIndex == 0) {
            map._entries.push(MapEntry({_key: key, _value: value}));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _remove(Map storage map, uint256 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        if (keyIndex != 0) {
            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;
            MapEntry storage lastEntry = map._entries[lastIndex];
            map._entries[toDeleteIndex] = lastEntry;
            map._indexes[lastEntry._key] = toDeleteIndex + 1;
            map._entries.pop();
            delete map._indexes[key];
            return true;
        } else {
            return false;
        }
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _contains(Map storage map, uint256 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _at(Map storage map, uint256 index) private view returns (uint256, uint256) {
        require(map._entries.length > index, 'EnumerableMap: index out of bounds');
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _get(Map storage map, uint256 key) private view returns (uint256) {
        return _get(map, key, 'EnumerableMap: nonexistent key');
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function _get(
        Map storage map,
        uint256 key,
        string memory errorMessage
    ) private view returns (uint256) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage);
        return map._entries[keyIndex - 1]._value;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    struct UintToUintMap {
        Map _inner;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, key, value);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, key);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, key);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        return _at(map._inner, index);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return _get(map._inner, key);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return _get(map._inner, key, errorMessage);
    }
}
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
pragma solidity ^0.6.0;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
library Math {
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
pragma solidity ^0.6.0;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
library SafeMath {
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        return c;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        return c;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        return c;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
        return c;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
interface MixerInterface {
    struct ListingInfo {
        uint tokenId;
        uint pricing;
        address seller;
    }
    struct UserListingInfo {
        uint tokenId;
        uint pricing;
        uint state;
    }
    struct BidInfo {
        address bidder;
        uint offering;
    }
    struct UserBidInfo {
        uint tokenId;
        uint offering;
        uint state;
    }
    function placeSellOrder(uint tokenId,uint pricing) external returns (bool);
    function bidBuyOrder(uint tokenId,uint offering) external returns (bool);
    function takeBuyOrder(uint tokenId) external returns (bool);
    function executeSellBid(uint tokenId,address bidder) external returns (bool);
    function updateSellOrder(uint tokenId,uint newPricing) external returns (bool);
    function updateBidOrder(uint tokenId,uint newOffering) external returns (bool);
    function cancelSellOrder(uint tokenId) external returns (bool);
    function cancelBid(uint tokenId) external returns (bool);
    function cancelBidAll() external returns (bool);
    function cancelBidInactiveAll() external returns (bool);
    function VoteForNFT(uint tokenId) external returns (bool);
    function getListingInfo() external view returns (ListingInfo[] memory); 
    function getListingInfoIndex(uint from,uint to) external view returns (ListingInfo[] memory); 
    function getUserListingInfo(address user) external view returns (UserListingInfo[] memory);
    function getUserListingInfoIndex(address user,uint from,uint to) external view returns (UserListingInfo[] memory);
    function getBidInfo(uint tokenId) external view returns (BidInfo[] memory);
    function getBidInfoIndex(uint tokenId,uint from,uint to) external view returns (BidInfo[] memory);
    function getUserBidInfo(address user) external view returns (UserBidInfo[] memory);
    function getUserBidInfoIndex(address user,uint from,uint to) external view returns (UserBidInfo[] memory);
    function getUserBidInactiveInfo(address user) external view returns (UserBidInfo[] memory);
    function getUserBidInactiveInfoIndex(address user,uint from,uint to) external view returns (UserBidInfo[] memory);
    function getPastUserListingInfo(address user) external view returns (UserListingInfo[] memory);
    function getPastUserListingInfoIndex(address user,uint from,uint to) external view returns (UserListingInfo[] memory);
    function getPastUserBidInfo(address user) external view returns (UserBidInfo[] memory);
    function getPastUserBidInfoIndex(address user,uint from,uint to) external view returns (UserBidInfo[] memory);
    function getStats() external view returns (uint256[] memory);
    function MixerLen(uint8 flags,address user,uint256 tokenId) external view returns (uint256);
    function getTokenPrice(uint tokenId) external view returns (uint256);
    function getTokenOwner(uint tokenId) external view returns (address);
    function FeeUpdater(uint fbp,uint vsb,address to) external returns (bool);
}
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
contract Mixer is MixerInterface, ERC721Holder, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    IERC20 public quoteERC20;
    IERC721 public quoteERC721;
    uint256 public Fees;
    uint256 public VoteSubstance;
    address public FeeTo;
    EnumerableMap.UintToUintMap private _listingMap;
    mapping(address => UserBidInfo[]) public userBidInfo;
    mapping(address => UserListingInfo[]) public userListingInfo;
    mapping(address => EnumerableSet.UintSet) private _userListingSet;
    mapping(address => EnumerableSet.UintSet) private _userBidSet;
    mapping(address => mapping(uint256 => uint256)) public userBidMap;
    mapping(address => mapping(uint256 => uint256)) public userListingMap;
    mapping(uint256 => EnumerableMap.UintToUintMap) private bidEntry;
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => uint256) public votes;
    mapping(address => mapping(uint256 => uint256)) public userVotes;
    uint256[] public stats;
    string public MARKETPLACE_IDENTIFIER;
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    event SellOrderPlaced(uint tokenId,uint pricing,address seller);
    event BuyOrderTaken(uint tokenId,uint pricing,address buyer,address seller);
    event BuyOrderBidden(uint tokenId,uint offering,address bidder);
    event BidOrderUpdated(uint tokenId,uint prevOffering,uint newOffering,address bidder);
    event SellBidExecuted(uint tokenId,uint offering,address bidder,address seller);
    event SellOrderCancelled(uint tokenId,address seller,uint pricing);
    event SellOrderUpdated(uint tokenId,uint prevPricing,uint newPricing,address seller);
    event BidCancelled(uint tokenId,address bidder);
    event VotedForNFT(uint tokenId,address user,address tokenOwner);
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    constructor(
        IERC20 _quoteERC20,
        IERC721 _quoteERC721,
        uint256 _Fees,
        uint256 _VoteSubstance,
        address _FeeTo,
        string memory _Identifier
        ) public {
        quoteERC20 = _quoteERC20;
        quoteERC721 = _quoteERC721;
        Fees = _Fees;
        VoteSubstance = _VoteSubstance;
        FeeTo = _FeeTo;
        MARKETPLACE_IDENTIFIER = _Identifier;
        for(uint i=0;i<9;++i) {
            stats.push(1);
        }
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function placeSellOrder(uint tokenId,uint pricing) external override returns (bool) {
       require(!(_listingMap.contains(tokenId)),"Mixer:Cannot override existing order");
       require(pricing>0,"Mixer:Listing price should be greater");
       quoteERC721.transferFrom(_msgSender(), address(this), tokenId);
       _listingMap.set(tokenId, pricing);
       _userListingSet[_msgSender()].add(tokenId);
       tokenOwner[tokenId] = _msgSender();
       userListingMap[_msgSender()][tokenId] = userListingInfo[_msgSender()].length;
       userListingInfo[_msgSender()].push(UserListingInfo({
           tokenId: tokenId,
           pricing: pricing,
           state: 0
       }));
       stats[0] = stats[0].add(1);
       emit SellOrderPlaced(tokenId,pricing,_msgSender());
       return true;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function bidBuyOrder(uint tokenId,uint offering) external override returns (bool) {
        require(_listingMap.contains(tokenId),"Mixer:Order does not exist");
        require(tokenOwner[tokenId]!=_msgSender(),"Mixer:Seller could not bid");
        require(offering>0,"Mixer:Offering should be greater");
        require(!(_userBidSet[_msgSender()].contains(tokenId)),"Mixer:Bid already exist");
        if(_listingMap.get(tokenId)<=offering) {
            takeBuyOrder(tokenId);
            return true;
        }
        quoteERC20.transferFrom(_msgSender(),address(this),offering);
        address user = _msgSender();
        uint256 userInt = uint256(user);
        bidEntry[tokenId].set(userInt,offering);
        _userBidSet[_msgSender()].add(tokenId);
        userBidMap[_msgSender()][tokenId] = userBidInfo[_msgSender()].length;
        userBidInfo[_msgSender()].push(UserBidInfo({
            tokenId: tokenId,
            offering: offering,
            state: 0
        }));
        stats[1] = stats[1].add(1);
        emit BuyOrderBidden(tokenId,offering,_msgSender());
        return true;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function takeBuyOrder(uint tokenId) public override returns (bool) {
        require(_listingMap.contains(tokenId),"Mixer:Order does not exist");
        require(tokenOwner[tokenId]!=_msgSender(),"Mixer:Seller could not take");
        address _tokenOwner = tokenOwner[tokenId];
        uint _tokenPrice = _listingMap.get(tokenId);
        uint MixerFee = _tokenPrice.mul(Fees).div(10000);
        uint MixerSend = _tokenPrice.sub(MixerFee);
        quoteERC20.transferFrom(_msgSender(),FeeTo,MixerFee);
        quoteERC20.transferFrom(_msgSender(),_tokenOwner,MixerSend);
        quoteERC721.transferFrom(address(this),_msgSender(),tokenId);
        _listingMap.remove(tokenId);
        _userListingSet[_tokenOwner].remove(tokenId);
        delete tokenOwner[tokenId];
        uint userInt = uint(_msgSender());
        if(_userBidSet[_msgSender()].contains(tokenId)) {
            uint offering = bidEntry[tokenId].get(userInt);
            quoteERC20.transfer(_msgSender(),offering);
            _userBidSet[_msgSender()].remove(tokenId);
            bidEntry[tokenId].remove(userInt);
            uint bidderIndex = userBidMap[_msgSender()][tokenId];
            userBidInfo[_msgSender()][bidderIndex].state = 2;
        }
        uint256 index = userListingMap[_tokenOwner][tokenId];
        userListingInfo[_tokenOwner][index].state = 2;
        stats[2] = stats[2].add(1);
        emit BuyOrderTaken(tokenId,_tokenPrice,_msgSender(),_tokenOwner);
        return true;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function executeSellBid(uint tokenId,address bidder) external override returns (bool) {
        require(_listingMap.contains(tokenId),"Mixer:Order does not exist");
        require(tokenOwner[tokenId]==_msgSender(),"Mixer:Caller is not the Seller");
        require(_userBidSet[bidder].contains(tokenId),"Mixer:Could not found bid for the user");
        uint256 bidderInt = uint256(bidder);
        uint256 toOffering = bidEntry[tokenId].get(bidderInt);
        uint MixerFee = toOffering.mul(Fees).div(10000);
        uint MixerSend = toOffering.sub(MixerFee);
        quoteERC20.transfer(FeeTo,MixerFee);
        quoteERC20.transfer(_msgSender(),MixerSend);
        quoteERC721.transferFrom(address(this),bidder,tokenId);
        _listingMap.remove(tokenId);
        _userListingSet[_msgSender()].remove(tokenId);
        delete tokenOwner[tokenId];
        _userBidSet[bidder].remove(tokenId);
        bidEntry[tokenId].remove(bidderInt);
        uint256 sellerIndex = userListingMap[_msgSender()][tokenId];
        userListingInfo[_msgSender()][sellerIndex].state = 2;
        uint256 bidderIndex = userBidMap[bidder][tokenId];
        userBidInfo[bidder][bidderIndex].state = 2;
        stats[3] = stats[3].add(1); 
        emit SellBidExecuted(tokenId,toOffering,bidder,_msgSender());
        return true;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function updateSellOrder(uint tokenId,uint newPricing) external override returns (bool) {
        require(_listingMap.contains(tokenId),"Mixer:Order does not exist");
        require(tokenOwner[tokenId]==_msgSender(),"Mixer:Caller is not the Seller");
        require(newPricing>0,"Mixer:Listing price should be greater");
        uint256 prevPricing = _listingMap.get(tokenId);
        _listingMap.set(tokenId,newPricing);
        uint256 index = userListingMap[_msgSender()][tokenId];
        userListingInfo[_msgSender()][index].pricing = newPricing;
        stats[4] = stats[4].add(1);
        emit SellOrderUpdated(tokenId,prevPricing,newPricing,_msgSender());
        return true;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function updateBidOrder(uint tokenId,uint newOffering) external override returns (bool) {
        require(_listingMap.contains(tokenId),"Mixer:Order does not exist");
        require(_userBidSet[_msgSender()].contains(tokenId),"Mixer:Caller is not the bidder");
        require(newOffering>0,"Mixer:Offering should be greater");
        if(_listingMap.get(tokenId)<=newOffering) {
            takeBuyOrder(tokenId);
            return true;
        }
        address user = _msgSender();
        uint256 userInt = uint256(user);
        uint256 prevOffering = bidEntry[tokenId].get(userInt);
        if(newOffering>prevOffering) {
            uint toRCV = newOffering.sub(prevOffering);
            quoteERC20.transferFrom(_msgSender(),address(this),toRCV);
        } else if (newOffering<prevOffering) {
            uint toRCV = prevOffering.sub(newOffering);
            quoteERC20.transfer(_msgSender(),toRCV);
        }
        bidEntry[tokenId].set(userInt,newOffering);
        uint256 index = userBidMap[_msgSender()][tokenId];
        userBidInfo[_msgSender()][index].offering = newOffering;
        stats[5] = stats[5].add(1);
        emit BidOrderUpdated(tokenId,prevOffering,newOffering,_msgSender());
        return true;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function cancelSellOrder(uint tokenId) external override returns (bool) {
        require(_listingMap.contains(tokenId),"Mixer:Order does not exist");
        require(tokenOwner[tokenId]==_msgSender(),"Mixer:Caller is not the Seller");
        uint256 pricing = _listingMap.get(tokenId);
        quoteERC721.transferFrom(address(this),_msgSender(),tokenId);
        _listingMap.remove(tokenId);
        _userListingSet[_msgSender()].remove(tokenId);
        delete tokenOwner[tokenId];
        uint256 index = userListingMap[_msgSender()][tokenId];
        userListingInfo[_msgSender()][index].state = 1;
        stats[6] = stats[6].add(1);
        emit SellOrderCancelled(tokenId,_msgSender(),pricing);
        return true;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function cancelBid(uint tokenId) public override returns (bool) {
        require(_userBidSet[_msgSender()].contains(tokenId),"Mixer:Caller is not the bidder");
        address user = _msgSender();
        uint256 userInt = uint256(user);
        uint256 toRCV = bidEntry[tokenId].get(userInt);
        quoteERC20.transfer(_msgSender(),toRCV);
        _userBidSet[_msgSender()].remove(tokenId);
        bidEntry[tokenId].remove(userInt);
        uint256 index = userBidMap[_msgSender()][tokenId];
        userBidInfo[_msgSender()][index].state = 1;
        stats[7] = stats[7].add(1); 
        emit BidCancelled(tokenId,_msgSender());
        return true;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function cancelBidAll() external override returns (bool) {
        uint256 len = _userBidSet[_msgSender()].length();
        uint256[] memory tokenIds = new uint256[](len);
        for(uint i=0;i<len;++i) {
            tokenIds[i] = _userBidSet[_msgSender()].at(i);
        }
        for(uint i=0;i<len;++i) {
            cancelBid(tokenIds[i]);
        }
        return true;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function cancelBidInactiveAll() external override returns (bool) {
        uint256 len = _userBidSet[_msgSender()].length();
        uint256[] memory tokenIds = new uint256[](len);
        uint c = 0;
        for(uint i=0;i<len;++i) {
            uint256 tokenId = _userBidSet[_msgSender()].at(i);
            if(!(_listingMap.contains(tokenId))) {
                tokenIds[c] = tokenId;
                c++;
            }
        }
        for(uint i=0;i<c;++i) {
            cancelBid(tokenIds[i]);
        }
        return true;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function VoteForNFT(uint tokenId) external override returns (bool) {
        require(_listingMap.contains(tokenId),"Mixer:Order does not exist");
        require(tokenOwner[tokenId]!=_msgSender(),"Mixer:Seller could not vote");
        address _tokenOwner = tokenOwner[tokenId];
        uint _VoteSubstance = VoteSubstance;
        uint MixerFee = _VoteSubstance.mul(Fees).div(10000);
        uint MixerSend = _VoteSubstance.sub(MixerFee);
        quoteERC20.transferFrom(_msgSender(),FeeTo,MixerFee);
        quoteERC20.transferFrom(_msgSender(),_tokenOwner,MixerSend);
        votes[tokenId] = votes[tokenId].add(1);
        userVotes[_msgSender()][tokenId] = userVotes[_msgSender()][tokenId].add(1);
        stats[8] = stats[8].add(1);
        emit VotedForNFT(tokenId,_msgSender(),_tokenOwner);
        return true;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getListingInfo() external override view returns (ListingInfo[] memory) {
        uint256 len = _listingMap.length();
        ListingInfo[] memory LFInfo = new ListingInfo[](len);
        for(uint i=0;i<len;++i) {
            (uint tokenId,uint pricing) = _listingMap.at(i);
            address seller = tokenOwner[tokenId];
            LFInfo[i] = ListingInfo({
                tokenId: tokenId,
                pricing: pricing,
                seller:  seller
            });
        }
        return LFInfo;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getListingInfoIndex(uint from,uint to) external override view returns (ListingInfo[] memory) {
        uint len = to.sub(from);
        ListingInfo[] memory LFInfo = new ListingInfo[](len);
        uint c = 0;
        for(uint i=from;i<to;++i) {
            (uint tokenId,uint pricing) = _listingMap.at(i);
            address seller = tokenOwner[tokenId];
            LFInfo[c] = ListingInfo({
                tokenId: tokenId,
                pricing: pricing,
                seller:  seller
            });
            c++;
        }
        return LFInfo;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getUserListingInfo(address user) external override view returns (UserListingInfo[] memory) {
        uint len = _userListingSet[user].length();
        UserListingInfo[] memory UFInfo = new UserListingInfo[](len);
        for(uint i=0;i<len;++i) {
            uint tokenId = _userListingSet[user].at(i);
            uint pricing = _listingMap.get(tokenId);
            uint index = userListingMap[user][tokenId];
            uint state = userListingInfo[user][index].state;
            UFInfo[i] = UserListingInfo({
                tokenId: tokenId,
                pricing: pricing,
                state: state
            });
        }
        return UFInfo;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getUserListingInfoIndex(address user,uint from,uint to) external override view returns (UserListingInfo[] memory) {
        uint len = to.sub(from);
        UserListingInfo[] memory UFInfo = new UserListingInfo[](len);
        uint c = 0;
        for(uint i=from;i<to;++i) {
            uint tokenId = _userListingSet[user].at(i);
            uint pricing = _listingMap.get(tokenId);
            uint index = userListingMap[user][tokenId];
            uint state = userListingInfo[user][index].state;
            UFInfo[c] = UserListingInfo({
                tokenId: tokenId,
                pricing: pricing,
                state: state
            });
            c++;
        }
        return UFInfo;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getBidInfo(uint tokenId) external override view returns (BidInfo[] memory) {
        uint len = bidEntry[tokenId].length();
        BidInfo[] memory BFInfo = new BidInfo[](len);
        for(uint i=0;i<len;++i) {
            (uint bidderInt, uint offering) = bidEntry[tokenId].at(i);
            address bidder = address(bidderInt);
            BFInfo[i] = BidInfo({
                bidder: bidder,
                offering: offering
            });
        }
        return BFInfo;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getBidInfoIndex(uint tokenId,uint from,uint to) external override view returns (BidInfo[] memory) {
        uint len = to.sub(from);
        BidInfo[] memory BFInfo = new BidInfo[](len);
        uint c = 0;
        for(uint i=from;i<to;++i) {
            (uint bidderInt, uint offering) = bidEntry[tokenId].at(i);
            address bidder = address(bidderInt);
            BFInfo[c] = BidInfo({
                bidder: bidder,
                offering: offering
            });
            c++;
        }
        return BFInfo;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getUserBidInfo(address user) external override view returns (UserBidInfo[] memory) {
        uint len = _userBidSet[user].length();
        uint userInt = uint(user);
        UserBidInfo[] memory UBInfo = new UserBidInfo[](len);
        for(uint i=0;i<len;++i) {
            uint tokenId = _userBidSet[user].at(i);
            uint offering = bidEntry[tokenId].get(userInt);
            uint index = userBidMap[user][tokenId];
            uint state = userBidInfo[user][index].state;
            UBInfo[i] = UserBidInfo({
                tokenId: tokenId,
                offering: offering,
                state: state
            });
        }
        return UBInfo;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getUserBidInfoIndex(address user,uint from,uint to) external override view returns (UserBidInfo[] memory) {
        uint len = to.sub(from);
        uint userInt = uint(user);
        UserBidInfo[] memory UBInfo = new UserBidInfo[](len);
        uint c = 0;
        for(uint i=from;i<to;++i) {
            uint tokenId = _userBidSet[user].at(i);
            uint offering = bidEntry[tokenId].get(userInt);
            uint index = userBidMap[user][tokenId];
            uint state = userBidInfo[user][index].state;
            UBInfo[c] = UserBidInfo({
                tokenId: tokenId,
                offering: offering,
                state: state
            });
            c++;
        }
        return UBInfo;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getUserBidInactiveInfo(address user) external override view returns (UserBidInfo[] memory) {
        uint len = _userBidSet[user].length();
        uint userInt = uint(user);
        uint e = 0;
        for(uint i=0;i<len;++i) {
            uint tokenId = _userBidSet[user].at(i);
            if(!(_listingMap.contains(tokenId))) {
                e++;
            }
        }
        UserBidInfo[] memory UBInfo = new UserBidInfo[](e);
        uint c = 0;
        for(uint i=0;i<len;++i) {
            uint tokenId = _userBidSet[user].at(i);
             if(!(_listingMap.contains(tokenId))) {
                 uint offering = bidEntry[tokenId].get(userInt);
                uint index = userBidMap[user][tokenId];
                uint state = userBidInfo[user][index].state;
                UBInfo[c] = UserBidInfo({
                    tokenId: tokenId,
                    offering: offering,
                    state: state
                });
                c++;
             }
        }
        return UBInfo;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getUserBidInactiveInfoIndex(address user,uint from,uint to) external override view returns (UserBidInfo[] memory) {
        uint userInt = uint(user);
        uint e = 0;
        for(uint i=from;i<to;++i) {
            uint tokenId = _userBidSet[user].at(i);
            if(!(_listingMap.contains(tokenId))) {
                e++;
            }
        }
        UserBidInfo[] memory UBInfo = new UserBidInfo[](e);
        uint c = 0;
        for(uint i=from;i<to;++i) {
            uint tokenId = _userBidSet[user].at(i);
             if(!(_listingMap.contains(tokenId))) {
                 uint offering = bidEntry[tokenId].get(userInt);
                uint index = userBidMap[user][tokenId];
                uint state = userBidInfo[user][index].state;
                UBInfo[c] = UserBidInfo({
                    tokenId: tokenId,
                    offering: offering,
                    state: state
                });
                c++;
             }
        }
        return UBInfo;
    } 
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getPastUserListingInfo(address user) external override view returns (UserListingInfo[] memory) {
        uint len = userListingInfo[user].length;
        uint e = 0;
        for(uint i=0;i<len;++i) {
            if(userListingInfo[user][i].state!=0) {
                e++;
            }
        }
        UserListingInfo[] memory UFInfo = new UserListingInfo[](e);
        uint c = 0;
        for(uint i=0;i<len;++i) {
            uint tokenId = userListingInfo[user][i].tokenId;
            uint pricing = userListingInfo[user][i].pricing;
            uint state = userListingInfo[user][i].state;
            if(state!=0) {
                UFInfo[c] = UserListingInfo({
                    tokenId: tokenId,
                    pricing: pricing,
                    state: state
                });
                c++;
            }
        }
        return UFInfo;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getPastUserListingInfoIndex(address user,uint from,uint to) external override view returns (UserListingInfo[] memory) {
        uint e = 0;
        for(uint i=from;i<to;++i) {
            if(userListingInfo[user][i].state!=0) {
                e++;
            }
        }
        UserListingInfo[] memory UFInfo = new UserListingInfo[](e);
        uint c = 0;
        for(uint i=from;i<to;++i) {
            uint tokenId = userListingInfo[user][i].tokenId;
            uint pricing = userListingInfo[user][i].pricing;
            uint state = userListingInfo[user][i].state;
            if(state!=0) {
                UFInfo[c] = UserListingInfo({
                    tokenId: tokenId,
                    pricing: pricing,
                    state: state
                });
                c++;
            }
        }
        return UFInfo;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getPastUserBidInfo(address user) external override view returns (UserBidInfo[] memory) {
        uint len = userBidInfo[user].length;
        uint e = 0;
        for(uint i=0;i<len;++i) {
            if(userBidInfo[user][i].state!=0) {
                e++;
            }
        }
        UserBidInfo[] memory UBInfo = new UserBidInfo[](e);
        uint c = 0;
        for(uint i=0;i<len;++i) {
            uint tokenId = userBidInfo[user][i].tokenId;
            uint offering = userBidInfo[user][i].offering;
            uint state = userBidInfo[user][i].state;
            if (state!=0) {
                UBInfo[c] = UserBidInfo({
                    tokenId: tokenId,
                    offering: offering,
                    state: state
                });
                c++;
            }
        }
        return UBInfo;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getPastUserBidInfoIndex(address user,uint from,uint to) external override view returns (UserBidInfo[] memory) {
        uint e = 0;
        for(uint i=from;i<to;++i) {
            if(userBidInfo[user][i].state!=0) {
                e++;
            }
        }
        UserBidInfo[] memory UBInfo = new UserBidInfo[](e);
        uint c = 0;
        for(uint i=from;i<to;++i) {
            uint tokenId = userBidInfo[user][i].tokenId;
            uint offering = userBidInfo[user][i].offering;
            uint state = userBidInfo[user][i].state;
            if (state!=0) {
                UBInfo[c] = UserBidInfo({
                    tokenId: tokenId,
                    offering: offering,
                    state: state
                });
                c++;
            } 
        }
        return UBInfo;
    }   
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getStats() external override view returns (uint256[] memory) {
        uint256[] memory statistics = new uint256[](9);
        for(uint i=0;i<9;++i) {
            statistics[i] = stats[i];
        }
        return statistics;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function MixerLen(uint8 flags,address user,uint256 tokenId) external view override returns (uint256) {
        return (
           flags == 1 ? _listingMap.length()            : 
           flags == 2 ? _userListingSet[user].length() :
           flags == 3 ? _userBidSet[user].length()     :
           flags == 4 ? bidEntry[tokenId].length()     :
           flags == 5 ? userListingInfo[user].length   :
           flags == 6 ? userBidInfo[user].length       :
                                                         0
        );
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getTokenPrice(uint tokenId) external override view returns (uint256) {
        return _listingMap.get(tokenId);
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function getTokenOwner(uint tokenId) external override view returns (address) {
        return tokenOwner[tokenId];
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
    function FeeUpdater(uint fbp,uint vsb,address to) external override onlyOwner returns (bool) {
        Fees = fbp;
        VoteSubstance = vsb;
        FeeTo = to;
        return true;
    }
//PREFLIGHT EXPERIMENTAL USE ONLY v1.2!!!
}