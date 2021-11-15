/**
 *Submitted for verification at polygonscan.com on 2021-11-14
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File contracts/IERC721Receiver.sol
// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/introspection/[email protected]



pragma solidity ^0.8.0;

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


// File contracts/IERC721.sol



pragma solidity >= 0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
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
    ) payable external;

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
    ) payable external;

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
    ) payable external;
}


// File contracts/IERC721Metadata.sol



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File contracts/SparkLink.sol



pragma solidity >= 0.8.4;













contract SparkLink is Ownable, ERC165, IERC721, IERC721Metadata{
    using Address for address;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    Counters.Counter private _issueIds;
    /*
    Abstract struct Issue {
        uint32 total_amount;
        bool is_free
        bool is_ND;
        bool is_NC;
        uint16 shill_times;
        uint8 royalty_fee;
    }
    This structure records some common attributes of a series of NFTs:
        - `royalty_fee`: the proportion of royaltyes
        - `shill_times`: the number of times a single NFT can been shared
        - `total_amount`: the total number of NFTs in the series
    To reduce gas cost, this structure is actually stored in the `father_id` attibute of root NFT
        - 0~31  `total_amount`
        - 37 `is_free`
        - 38 `is_NC`
        - 39 `is_ND`
        - 40~55 `shill_times`
        - 56~63 `royalty_fee`
    */

    struct Edition {
        // This structure stores NFT related information:
        //  - `father_id`: For root NFT it stores issue abstract sturcture
        //                 For other NFTs its stores the NFT Id of which NFT it `acceptShill` from
        // - `shill_price`: The price should be paid when others `accpetShill` from this NFT
        // - remaining_shill_times: The initial value is the shilltimes of the issue it belongs to
        //                       When others `acceptShill` from this NFT, it will subtract one until its value is 0  
        // - `owner`: record the owner of this NFT
        // - `ipfs_hash`: IPFS hash value of the URI where this NTF's metadata stores
        // - `transfer_price`: The initial value is zero
        //                   Set by `determinePrice` or `determinePriceAndApprove` before `transferFrom`
        //                   It will be checked wether equal to msg.value when `transferFrom` is called
        //                   After `transferFrom` this value will be set to zero
        // - `profit`: record the profit owner can claim (include royalty fee it should conduct to its father NFT)
        uint64 father_id;
        uint128 shill_price;
        uint16 remaining_shill_times;
        address owner;
        bytes32 ipfs_hash;
        uint128 transfer_price;
        uint128 profit;
    }

    // Emit when `determinePrice` success
    event DeterminePrice(
        uint64 indexed NFT_id,
        uint128 transfer_price
    );

    // Emit when `determinePriceAndApprove` success
    event DeterminePriceAndApprove(
        uint64 indexed NFT_id,
        uint128 transfer_price,
        address indexed to
    );

    // Emit when `publish` success
    // - `rootNFTId`: Record the Id of root NFT given to publisher 
    event Publish(
        address indexed publisher,
        uint64  indexed rootNFTId,
        address token_addr
    );

    // Emit when claimProfit success
    //- `amount`: Record the actual amount owner of this NFT received (profit - profit*royalty_fee/100)
    event Claim(
        uint64 indexed NFT_id,
        address indexed receiver,
        uint128 amount
    );
    // Emit when setURI success
    event SetURI(
        uint64 indexed NFT_id,
        bytes32 old_URI,
        bytes32 new_URI
    );

    event Label(
        uint64 indexed NFT_id,
        string content
    );

    event SetDAOFee(
        uint8 old_DAO_fee,
        uint8 new_DAO_fee
    );

    event SetLoosRatio(
        uint8 old_loss_ratio,
        uint8 new_loss_ratio
    );

    event SetDAORouter01(
        address old_router_address,
        address new_router_address
    );

    event SetDAORouter02(
        address old_router_address,
        address new_router_address
    );

    //----------------------------------------------------------------------------------------------------
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(address DAO_router_address01,address DAO_router_address02, address uniswapRouterAddress, address factoryAddress) {
        uniswapV2Router =  IUniswapV2Router02(uniswapRouterAddress);
        uniswapV2Factory = IUniswapV2Factory(factoryAddress);
        DAO_router01 = DAO_router_address01;
        DAO_router02 = DAO_router_address02;
        _name = "SparkLink";
        _symbol = "SPL";
    } 
    
   /**
     * @dev Create a issue and mint a root NFT for buyer acceptShill from
     *
     * Requirements:
     *
     * - `_first_sell_price`: The price should be paid when others `accpetShill` from this NFT
     * - `_royalty_fee`: The proportion of royaltyes, it represents the ratio of the father NFT's profit from the child NFT
     *                   Its value should <= 100
     * - `_shill_times`: the number of times a single NFT can been shared
     *                   Its value should <= 65536
     * - `_ipfs_hash`: IPFS hash value of the URI where this NTF's metadata stores
     *
     * - `token_address`: list of tokens(address) can be accepted for payment.
     *                 `A token address` can be ERC-20 token contract address or `address(0)`(ETH).
     *
     * - `_is_free`:
     * - `_is_NC`: 
     * 
     * - `_is_ND`: 
     * Emits a {Publish} event.
     * - Emitted {Publish} event contains root NFT id.
     */
    function publish(
        uint128 _first_sell_price,
        uint8 _royalty_fee,
        uint16 _shill_times,
        bytes32 _ipfs_hash,
        address _token_addr,
        bool _is_free,
        bool _is_NC,
        bool _is_ND
    ) 
        external 
    {
        require(_royalty_fee <= 100, "SparkLink: Royalty fee should be <= 100%.");
        _issueIds.increment();
        require(_issueIds.current() <= type(uint32).max, "SparkLink: Value doesn't fit in 32 bits.");
        if (_token_addr != address(0))
            require(IERC20(_token_addr).totalSupply() > 0, "Not a valid ERC20 token address");
        uint32 new_issue_id = uint32(_issueIds.current());
        uint64 rootNFTId = getNftIdByEditionIdAndIssueId(new_issue_id, 1);
        require(
            _checkOnERC721Received(address(0), msg.sender, rootNFTId, ""),
            "SparkLink: Transfer to non ERC721Receiver implementer"
        );

        Edition storage new_NFT = editions_by_id[rootNFTId];
        uint64 information;
        information = reWriteUint8InUint64(56, _royalty_fee, information);
        information = reWriteUint16InUint64(40, _shill_times, information);
        information = reWriteBoolInUint64(37, _is_free, information);
        information = reWriteBoolInUint64(38, _is_NC, information);
        information = reWriteBoolInUint64(39, _is_ND, information);
        information += 1;
        token_addresses[new_issue_id] = _token_addr;
        new_NFT.father_id = information;
        new_NFT.remaining_shill_times = _shill_times;
        new_NFT.shill_price = _first_sell_price;
        new_NFT.owner = msg.sender;
        new_NFT.ipfs_hash = _ipfs_hash;
        _balances[msg.sender] += 1;
        emit Transfer(address(0), msg.sender, rootNFTId);
        emit Publish(
            msg.sender,
            rootNFTId,
            _token_addr
        );
    }

    /**
     * @dev Buy a child NFT from the _NFT_id buyer input
     *
     * Requirements:
     *
     * - `_NFT_id`: _NFT_id the father NFT id buyer mint NFT from
     *              remain shill times of the NFT_id you input should greater than 0
     * Emits a {Ttansfer} event.
     * - Emitted {Transfer} event from 0x0 address to msg.sender, contain new NFT id.
     * - New NFT id will be generater by edition id and issue id
     *   0~31 edition id
     *   32~63 issue id
     */
    function acceptShill(
        uint64 _NFT_id
    ) 
        external 
        payable 
    {
        require(isEditionExisting(_NFT_id), "SparkLink: This NFT does not exist");
        require(editions_by_id[_NFT_id].remaining_shill_times > 0, "SparkLink: There is no remaining shill time for this NFT");
        if (!getIsFreeByNFTId(_NFT_id)||!isRootNFT(_NFT_id)){
            address token_addr = getTokenAddrByNFTId(_NFT_id);
            if (token_addr == address(0)){
                require(msg.value == editions_by_id[_NFT_id].shill_price, "SparkLink: Wrong price");
                _addProfit( _NFT_id, editions_by_id[_NFT_id].shill_price);
            }
            else {
                uint256 before_balance = IERC20(token_addr).balanceOf(address(this));
                IERC20(token_addr).safeTransferFrom(msg.sender, address(this), editions_by_id[_NFT_id].shill_price);
                _addProfit( _NFT_id, uint256toUint128(IERC20(token_addr).balanceOf(address(this))-before_balance));
            }
        }
        editions_by_id[_NFT_id].remaining_shill_times -= 1;
        _mintNFT(_NFT_id, msg.sender);
        if (editions_by_id[_NFT_id].remaining_shill_times == 0)
            _mintNFT(_NFT_id, ownerOf(_NFT_id));
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *      
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `transfer_price` has been set, caller should give same value in msg.sender.
     * - Will call `claimProfit` before transfer and `transfer_price` will be set to zero after transfer. 
     * Emits a {TransferAsset} events
     */
    function transferFrom(address from, address to, uint256 tokenId) external payable override {
        _transfer(from, to, uint256toUint64(tokenId));
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable override{
       _safeTransfer(from, to, uint256toUint64(tokenId), "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data) external payable override {
        _safeTransfer(from, to, uint256toUint64(tokenId), _data);
    }
    
    /**
     * @dev Claim profit from reward pool of NFT.
     *      
     * Requirements:
     *
     * - `_NFT_id`: The NFT id of NFT caller claim, the profit will give to its owner.
     * - If its profit is zero the event {Claim} will not be emited.
     * Emits a {Claim} events
     */
    function claimProfit(uint64 _NFT_id) public {
        require(isEditionExisting(_NFT_id), "SparkLink: This edition does not exist");
        
        if (editions_by_id[_NFT_id].profit != 0) {
            uint128 amount = editions_by_id[_NFT_id].profit;
            address token_addr = getTokenAddrByNFTId(_NFT_id);
            if (DAO_fee != 0) {
                uint128 DAO_amount = calculateFee(amount, DAO_fee);
                amount -= DAO_amount;
                if (token_addr == address(0)) {
                    payable(DAO_router01).transfer(DAO_amount);
                }
                else if (uniswapV2Factory.getPair(token_addr, uniswapV2Router.WETH()) == address(0)) {
                    IERC20(token_addr).safeTransfer(DAO_router02,DAO_amount);
                }
                else {
                    _swapTokensForEth(token_addr, DAO_amount);
                }
            }
            editions_by_id[_NFT_id].profit = 0;
            if (!isRootNFT(_NFT_id)) {
                uint128 _royalty_fee = calculateFee(amount, getRoyaltyFeeByNFTId(_NFT_id));
                _addProfit(getFatherByNFTId(_NFT_id), _royalty_fee);
                amount -= _royalty_fee;
            }
            if (token_addr == address(0)){
                payable(ownerOf(_NFT_id)).transfer(amount);
            }
            else {
                IERC20(token_addr).safeTransfer(ownerOf(_NFT_id), amount);
            }
            emit Claim(
                _NFT_id,
                ownerOf(_NFT_id),
                amount
            );
        }
    }

    /**
     * @dev Set token URI.
     *
     * Requirements:
     *
     * - `_NFT_id`: transferred token id.
     * - `ipfs_hash`: ipfs hash value of the URI will be set.
     * Emits a {SetURI} events
     */
    function setURI(uint64 _NFT_id, bytes32 ipfs_hash) public {
        if (getIsNDByNFTId(_NFT_id)) {
            require(_NFT_id == getRootNFTIdByNFTId(_NFT_id), "SparkLink: NFT follows the ND protocol, only the root NFT's URI can be set.");
        }
        require(ownerOf(_NFT_id) == msg.sender, "SparkLink: Only owner can set the token URI");
        _setTokenURI(_NFT_id, ipfs_hash);
    }

     /**
     * @dev update token URI.
     *
     * Requirements:
     *
     * - `_NFT_id`: transferred token id.
     */
    function updateURI(uint64 _NFT_id) public{
        require(ownerOf(_NFT_id) == msg.sender, "SparkLink: Only owner can update the token URI");
        editions_by_id[_NFT_id].ipfs_hash = editions_by_id[getRootNFTIdByNFTId(_NFT_id)].ipfs_hash;
    }

    function label(uint64 _NFT_id, string memory content) public {
        require(ownerOf(_NFT_id) == msg.sender, "SparkLink: Only owner can label this NFT");
        emit Label(_NFT_id, content);
    }
    /**
     * @dev Determine NFT price before transfer.
     *
     * Requirements:
     *
     * - `_NFT_id`: transferred token id.
     * - `_price`: The amount of ETH should be payed for `_NFT_id`
     * Emits a {DeterminePrice} events
     */
    function determinePrice(
        uint64 _NFT_id,
        uint128 _price
    ) 
        public 
    {
        require(isEditionExisting(_NFT_id), "SparkLink: This NFT does not exist");
        require(msg.sender == ownerOf(_NFT_id), "SparkLink: Only owner can set the price");
        editions_by_id[_NFT_id].transfer_price = _price;
        emit DeterminePrice(_NFT_id, _price);
    }

    /**
     * @dev Determine NFT price before transfer.
     *
     * Requirements:
     *
     * - `_NFT_id`: transferred token id.
     * - `_price`: The amount of ETH should be payed for `_NFT_id`
     * - `_to`: The account address `approve` to. 
     * Emits a {DeterminePriceAndApprove} events
     */
    function determinePriceAndApprove(
        uint64 _NFT_id,
        uint128 _price,
        address _to
    ) 
        public 
    {
        determinePrice(_NFT_id, _price);
        approve(_to, _NFT_id);
        emit DeterminePriceAndApprove(_NFT_id, _price, _to);
    }

    function setDAOFee(uint8 _DAO_fee) public onlyOwner {
        require(_DAO_fee <= MAX_DAO_FEE, "SparkLink: DAO fee can not exceed 5%");
        emit SetDAOFee(DAO_fee, _DAO_fee);
        DAO_fee = _DAO_fee;
    }

    function setDAORouter01(address _DAO_router01) public onlyOwner {
        emit SetDAORouter01(DAO_router01, _DAO_router01);
        DAO_router01 = _DAO_router01;
    }

    function setDAORouter02(address _DAO_router02) public onlyOwner {
        emit SetDAORouter01(DAO_router02, _DAO_router02);
        DAO_router02 = _DAO_router02;
    }

    function setUniswapV2Router(address _uniswapV2Router) public onlyOwner {
        uniswapV2Router =  IUniswapV2Router02(_uniswapV2Router);
    }
    function setUniswapV2Factory(address _uniswapV2Factory) public onlyOwner {
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Factory);
    }

    function setLoosRatio(uint8 _loss_ratio) public onlyOwner {
        require(_loss_ratio <= MAX_LOSS_RATIO, "SparkLink: Loss ratio can not below 50%");
        emit SetLoosRatio(loss_ratio, _loss_ratio);
        loss_ratio = _loss_ratio;
    }
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "SparkLink: Approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "SparkLink: Approve caller is not owner nor approved for all"
        );

        _approve(to, uint256toUint64(tokenId));
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "SparkLink: Approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "SparkLink: Balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = editions_by_id[uint256toUint64(tokenId)].owner;
        require(owner != address(0), "SparkLink: Owner query for nonexistent token");
        return owner;
    }

    /**
     *                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    /**
     * @dev Query NFT information set.
     *
     * Requirements:
     * - `_NFT_id`: The id of the edition queryed.
     * Return :
     * - `issue_information`: For root NFT it stores issue abstract sturcture
     * - 0~31   `total_amount`
     * - 37     `is_free`
     * - 38     `is_NC`
     * - 39     `is_ND`
     * - 40~55  `shill_times`
     * - 56~63 `royalty_fee`
     * - `father_id`: For root NFT it stores issue abstract sturcture
     *                For other NFTs its stores the NFT Id of which NFT it `acceptShill` from
     * - `shill_price`: The price should be paid when others `accpetShill` from this NFT
     * - `remaining_shill_times`: The initial value is the shilltimes of the issue it belongs to
     *                      When others `acceptShill` from this NFT, it will subtract one until its value is 0  
     * - `owner`: record the owner of this NFT
     * - `transfer_price`: The initial value is zero
     *                  Set by `determinePrice` or `determinePriceAndApprove` before `transferFrom`
     *                  It will be checked wether equal to msg.value when `transferFrom` is called
     *                  After `transferFrom` this value will be set to zero
     * - `profit`: record the profit owner can claim (include royalty fee it should conduct to its father NFT)
     * - `metadata`: IPFS hash value of the URI where this NTF's metadata stores
     */

    function getNFTInfoByNFTID(uint64 _NFT_id) 
        public view  
        returns (
            uint64 issue_information,
            uint64 father_id,
            uint128 shill_price,
            uint16 remain_shill_times,
            uint128 profit,
            string memory metadata
            ) 
    {
        require(isEditionExisting(_NFT_id), "SparkLink: Approved query for nonexistent token");
        return(
            editions_by_id[getRootNFTIdByNFTId(_NFT_id)].father_id,
            getFatherByNFTId(_NFT_id),
            getShillPriceByNFTId(_NFT_id),
            getRemainShillTimesByNFTId(_NFT_id),
            getProfitByNFTId(_NFT_id),
            tokenURI(_NFT_id)
        );
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(isEditionExisting(uint256toUint64(tokenId)), "SparkLink: Approved query for nonexistent token");

        return _tokenApprovals[uint256toUint64(tokenId)];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /** 
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(isEditionExisting(uint256toUint64(tokenId)), "SparkLink: URI query for nonexistent token");
        bytes32 _ipfs_hash = editions_by_id[uint256toUint64(tokenId)].ipfs_hash;
        string memory encoded_hash = _toBase58String(_ipfs_hash);
        string memory base = _baseURI();
        return string(abi.encodePacked(base, encoded_hash));
    }

  /**
     * @dev Query is issue free for first lever buyer.
     *
     * Requirements:
     * - `_NFT_id`: The id of the edition queryed.
     * Return a bool value.
     */
    function getIsFreeByNFTId(uint64 _NFT_id) public view returns (bool) {
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        return getBoolFromUint64(37, editions_by_id[getRootNFTIdByNFTId(_NFT_id)].father_id);
    }

    /**
     * @dev Query is issue follows the NC protocol by any NFT belongs to this issue.
     *
     * Requirements:
     * - `_NFT_id`: The id of the edition queryed.
     * Return a bool value.
     */
    function getIsNCByNFTId(uint64 _NFT_id) public view returns (bool) {
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        return getBoolFromUint64(38, editions_by_id[getRootNFTIdByNFTId(_NFT_id)].father_id);
    }

    /**
     * @dev Query is issue follows the ND protocol by any NFT belongs to this issue.
     *
     * Requirements:
     * - `_NFT_id`: The id of the edition queryed.
     * Return a bool value.
     */
    function getIsNDByNFTId(uint64 _NFT_id) public view returns (bool) {
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        return getBoolFromUint64(39, editions_by_id[getRootNFTIdByNFTId(_NFT_id)].father_id);
    }

    /**
     * @dev Query is edition exist.
     *
     * Requirements:
     * - `_NFT_id`: The id of the edition queryed.
     * Return a bool value.
     */
    function isEditionExisting(uint64 _NFT_id) public view returns (bool) {
        return (editions_by_id[_NFT_id].owner != address(0));
    }

    /**
     * @dev Query the amount of ETH a NFT can be claimed.
     *  
     * Requirements:
     * - `_NFT_id`: The id of the NFT queryed.
     * Return the value this NFT can be claimed.
     * If the NFT is not root NFT, this value will subtract royalty fee percent.
     */
    function getProfitByNFTId(uint64 _NFT_id) public view returns (uint128){
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        uint128 amount = editions_by_id[_NFT_id].profit;
         if (DAO_fee != 0) {
                uint128 DAO_amount = calculateFee(amount, DAO_fee);
                amount -= DAO_amount;
        }
        if (!isRootNFT(_NFT_id)) {
            uint128 _total_fee = calculateFee(amount, getRoyaltyFeeByNFTId(_NFT_id));            
            amount -= _total_fee;
        }
        return amount;
    }

    /**
     * @dev Query royalty fee percent of an issue by any NFT belongs to this issue.
     *  
     * Requirements:
     * - `_NFT_id`: The id of the NFT queryed.
     * Return royalty fee percent of this issue.
     */
    function getRoyaltyFeeByNFTId(uint64 _NFT_id) public view returns (uint8) {
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        return getUint8FromUint64(56, editions_by_id[getRootNFTIdByNFTId(_NFT_id)].father_id);
    }

    /**
     * @dev Query max shill times of an issue by any NFT belongs to this issue.
     *  
     * Requirements:
     * - `_NFT_id`: The id of the NFT queryed.
     * Return max shill times of this issue.
     */
    function getShillTimesByNFTId(uint64 _NFT_id) public view returns (uint16) {
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        return getUint16FromUint64(40, editions_by_id[getRootNFTIdByNFTId(_NFT_id)].father_id);
    }

    /**
     * @dev Query total NFT number of a issue by any NFT belongs to this issue.
     *  
     * Requirements:
     * - `_NFT_id`: The id of the NFT queryed.
     * Return total NFT number of this issue.
     */
    function getTotalAmountByNFTId(uint64 _NFT_id) public view returns (uint32) {
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        return getBottomUint32FromUint64(editions_by_id[getRootNFTIdByNFTId(_NFT_id)].father_id);
    }

    /**
     * @dev Query supported token address of a issue by any NFT belongs to this issue.
     *  
     * Requirements:
     * - `_NFT_id`: The id of the NFT queryed.
     * Return supported token address of this NFT.
     * Address 0 represent ETH.
     */
    function getTokenAddrByNFTId(uint64 _NFT_id) public view returns (address) {
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        return token_addresses[uint32(_NFT_id>>32)];
    }

    /**
     * @dev Query the id of this NFT's father NFT.
     *  
     * Requirements:
     * - `_NFT_id`: The id of the NFT queryed.
     * - This NFT should exist and not be root NFT.
     * Return the father NFT id of this NFT.
     */
    function getFatherByNFTId(uint64 _NFT_id) public view returns (uint64) {
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        if (isRootNFT(_NFT_id)) {
            return 0;
        }
        return editions_by_id[_NFT_id].father_id;
    }    
    
    /**
     * @dev Query transfer_price of this NFT.
     *  
     * Requirements:
     * - `_NFT_id`: The id of the NFT queryed.
     * Return transfer_price of this NFT.
     */
    function getTransferPriceByNFTId(uint64 _NFT_id) public view returns (uint128) {
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        return editions_by_id[_NFT_id].transfer_price;
    }

    /**
     * @dev Query shill_price of this NFT.
     *  
     * Requirements:
     * - `_NFT_id`: The id of the NFT queryed.
     * Return shill_price of this NFT.
     */
    function getShillPriceByNFTId(uint64 _NFT_id) public view returns (uint128) {
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        if (getIsFreeByNFTId(_NFT_id)&&isRootNFT(_NFT_id))
            return 0;
        else
            return editions_by_id[_NFT_id].shill_price;
    }

    /**
     * @dev Query remaining_shill_times of this NFT.
     *  
     * Requirements:
     * - `_NFT_id`: The id of the NFT queryed.
     * Return remaining_shill_times of this NFT.
     */
    function getRemainShillTimesByNFTId(uint64 _NFT_id) public view returns (uint16) {
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        return editions_by_id[_NFT_id].remaining_shill_times;
    }

    /**
     * @dev Query depth of this NFT.
     *  
     * Requirements:
     * - `_NFT_id`: The id of the NFT queryed.
     * Return depth of this NFT.
     */
    function getDepthByNFTId(uint64 _NFT_id) public view returns (uint64) {
        require(isEditionExisting(_NFT_id), "SparkLink: Edition is not exist.");
        uint64 depth = 0;
        for (depth = 0; !isRootNFT(_NFT_id); _NFT_id = getFatherByNFTId(_NFT_id)) {
            depth += 1;
        }
        return depth;
    }

    /**
     * @dev Query is this NFT is root NFT by check is its edition id is 1.
     *  
     * Requirements:
     * - `_NFT_id`: The id of the NFT queryed.
     * Return a bool value to indicate wether this NFT is root NFT.
     */
    function isRootNFT(uint64 _NFT_id) public pure returns (bool) {
        return getBottomUint32FromUint64(_NFT_id) == uint32(1);
    }

    /**
     * @dev Query root NFT id by NFT id.
     *  
     * Requirements:
     * - `_NFT_id`: The id of the NFT queryed.
     * Return a bool value to indicate wether this NFT is root NFT.
     */
    function getRootNFTIdByNFTId(uint64 _NFT_id) public pure returns (uint64) {
        return ((_NFT_id>>32)<<32 | uint64(1));
    }

    /**
     * @dev Query loss ratio of this contract.
     *  
     * Return loss ratio of this contract.
     */
    function getLossRatio() public view returns (uint8) {
        return loss_ratio;
    }
    
    /**
     * @dev Calculate edition id by NFT id.
     *  
     * Requirements:
     * - `_NFT_id`: The NFT id of the NFT caller want to get.
     * Return edition id.
     */
    function getEditionIdByNFTId(uint64 _NFT_id) public pure returns (uint32) {
        return getBottomUint32FromUint64(_NFT_id);
    }
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    uint8 public loss_ratio = 50;
    uint8 public DAO_fee = 2;
    uint8 public constant MAX_DAO_FEE = 2;
    uint8 public constant MAX_LOSS_RATIO = 50;
    address public DAO_router01;
    address public DAO_router02;
    IUniswapV2Router02 public  uniswapV2Router;
    IUniswapV2Factory public  uniswapV2Factory;
    // Mapping owner address to token count
    mapping(address => uint64) private _balances;
    // Mapping from token ID to approved address
    mapping(uint64 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping (uint64 => Edition) private editions_by_id;
    // mapping from issue ID to support ERC20 token address
    mapping(uint32 => address) private token_addresses;

    bytes constant private sha256MultiHash = hex"1220"; 
    bytes constant private ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

    function _swapTokensForEth(address token_addr, uint128 token_amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = token_addr;
        path[1] = uniswapV2Router.WETH();

        IERC20(token_addr).approve(address(uniswapV2Router), token_amount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            token_amount,
            0, // accept any amount of ETH
            path,
            DAO_router01,
            block.timestamp
        );
    }


     /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint64 tokenId,
        bytes memory _data
    ) 
        private 
        returns (bool) 
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("SparkLink: Transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint64 tokenId, bytes32 ipfs_hash) internal virtual {
        bytes32 old_URI = editions_by_id[tokenId].ipfs_hash;
        editions_by_id[tokenId].ipfs_hash = ipfs_hash;
        emit SetURI(tokenId, old_URI, ipfs_hash);
    }
    
     /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param _NFT_id NFT id of father NFT
     * @param _owner indicate the address new NFT transfer to
     * @return a uint64 store new NFT id
     **/
    function _mintNFT(
        uint64 _NFT_id,
        address _owner
    ) 
        internal 
        returns (uint64) 
    {
        _addTotalAmount(_NFT_id);
        uint32 new_edition_id = getTotalAmountByNFTId(_NFT_id);
        uint64 new_NFT_id = getNftIdByEditionIdAndIssueId(uint32(_NFT_id>>32), new_edition_id);
        require(
            _checkOnERC721Received(address(0), _owner, new_NFT_id, ""),
            "SparkLink: Transfer to non ERC721Receiver implementer"
        );
        Edition storage new_NFT = editions_by_id[new_NFT_id];
        new_NFT.remaining_shill_times = getShillTimesByNFTId(_NFT_id);
        new_NFT.father_id = _NFT_id;
        if (getIsFreeByNFTId(_NFT_id)&&isRootNFT(_NFT_id))
            new_NFT.shill_price = editions_by_id[_NFT_id].shill_price;
        else
            new_NFT.shill_price = calculateFee(editions_by_id[_NFT_id].shill_price, loss_ratio);
        if (new_NFT.shill_price == 0) {
            new_NFT.shill_price = editions_by_id[_NFT_id].shill_price;
        }
        new_NFT.owner = _owner;
        new_NFT.ipfs_hash = editions_by_id[_NFT_id].ipfs_hash;
        _balances[_owner] += 1;
        emit Transfer(address(0), _owner, new_NFT_id);
        return new_NFT_id;
    }

    /**
     * @dev Internal function to clear approve and transfer_price
     *
     * @param _NFT_id NFT id of father NFT
     **/
    function _afterTokenTransfer (uint64 _NFT_id) internal {
        // Clear approvals from the previous owner
        _approve(address(0), _NFT_id);
        editions_by_id[_NFT_id].transfer_price = 0;
    }

    /**
     * @dev Internal function to support transfer `tokenId` from `from` to `to`.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint64 tokenId
    ) 
        internal 
        virtual 
    {
        require(ownerOf(tokenId) == from, "SparkLink: Transfer of token that is not own");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "SparkLink: Transfer caller is not owner nor approved");
        require(to != address(0), "SparkLink: Transfer to the zero address");
        if (msg.sender != ownerOf(tokenId)) {
            address token_addr = getTokenAddrByNFTId(tokenId);
            uint128 transfer_price = editions_by_id[tokenId].transfer_price;
            if (token_addr == address(0)){
                require(msg.value == transfer_price, "SparkLink: Price not met");
                _addProfit(tokenId, transfer_price);
            }
            else {
                uint256 before_balance = IERC20(token_addr).balanceOf(address(this));
                IERC20(token_addr).safeTransferFrom(msg.sender, address(this), transfer_price);
                _addProfit(tokenId, uint256toUint128(IERC20(token_addr).balanceOf(address(this))-before_balance));
            }
            claimProfit(tokenId);
        }
        else {
            claimProfit(tokenId);
        }
        _afterTokenTransfer(tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        editions_by_id[tokenId].owner = to;
        emit Transfer(from, to, tokenId);
    }

     /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint64 tokenId,
        bytes memory _data
    ) 
        internal 
        virtual 
    {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "SparkLink: Transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint64 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _addProfit(uint64 _NFT_id, uint128 _increase) internal {
        editions_by_id[_NFT_id].profit = editions_by_id[_NFT_id].profit+_increase;
    }

    function _addTotalAmount(uint64 _NFT_Id) internal {
        require(getTotalAmountByNFTId(_NFT_Id) < type(uint32).max, "SparkLink: There is no left in this issue.");
        editions_by_id[getRootNFTIdByNFTId(_NFT_Id)].father_id += 1;
    }

    function _isApprovedOrOwner(address spender, uint64 tokenId) internal view virtual returns (bool) {
        require(isEditionExisting(tokenId), "SparkLink: Operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
        
    function _baseURI() internal pure returns (string memory) {
        return "https://ipfs.io/ipfs/";
    } 


    /**
     * @dev Calculate NFT id by issue id and edition id.
     *  
     * Requirements:
     * - `_issue_id`: The issue id of the NFT caller want to get.
     * - `_edition_id`: The edition id of the NFT caller want to get.
     * Return NFT id.
     */
    function getNftIdByEditionIdAndIssueId(uint32 _issue_id, uint32 _edition_id) internal pure returns (uint64) {
        return (uint64(_issue_id)<<32)|uint64(_edition_id);
    }

    function getBoolFromUint64(uint8 position, uint64 data64) internal pure returns (bool flag) {
        // (((1 << size) - 1) & base >> position)
        assembly {
            flag := and(1, shr(position, data64))
        }
    }

    function getUint8FromUint64(uint8 position, uint64 data64) internal pure returns (uint8 data8) {
        // (((1 << size) - 1) & base >> position)
        assembly {
            data8 := and(sub(shl(8, 1), 1), shr(position, data64))
        }
    }
    function getUint16FromUint64(uint8 position, uint64 data64) internal pure returns (uint16 data16) {
        // (((1 << size) - 1) & base >> position)
        assembly {
            data16 := and(sub(shl(16, 1), 1), shr(position, data64))
        }
    }
    function getBottomUint32FromUint64(uint64 data64) internal pure returns (uint32 data32) {
        // (((1 << size) - 1) & base >> position)
        assembly {
            data32 := and(sub(shl(32, 1), 1), data64)
        }
    }

    function reWriteBoolInUint64(uint8 position, bool flag, uint64 data64) internal pure returns (uint64 boxed) {
        assembly {
            // mask = ~((1 << 8 - 1) << position)
            // _box = (mask & _box) | ()data << position)
            boxed := or( and(data64, not(shl(position, 1))), shl(position, flag))
        }
    }

    
    function reWriteUint8InUint64(uint8 position, uint8 flag, uint64 data64) internal pure returns (uint64 boxed) {
        assembly {
            // mask = ~((1 << 8 - 1) << position)
            // _box = (mask & _box) | ()data << position)
            boxed := or(and(data64, not(shl(position, 1))), shl(position, flag))
        }
    }

    function reWriteUint16InUint64(uint8 position, uint16 data16, uint64 data64) internal pure returns (uint64 boxed) {
        assembly {
            // mask = ~((1 << 16 - 1) << position)
            // _box = (mask & _box) | ()data << position)
            boxed := or( and(data64, not(shl(position, sub(shl(16, 1), 1)))), shl(position, data16))
        }
    }

    function uint256toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SparkLink: Value doesn't fit in 64 bits");
        return uint64(value);
    }

    function uint256toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SparkLink: Value doesn't fit in 128 bits");
        return uint128(value);
    }
    
    function calculateFee(uint128 _amount, uint8 _fee_percent) internal pure returns (uint128) {
        return _amount*_fee_percent/10**2;
    }

    function _toBase58String(bytes32 con) internal pure returns (string memory) {
        
        bytes memory source = bytes.concat(sha256MultiHash,con);

        uint8[] memory digits = new uint8[](64); //TODO: figure out exactly how much is needed
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint256 i = 0; i<source.length; ++i) {
        uint carry = uint8(source[i]);
        for (uint256 j = 0; j<digitlength; ++j) {
            carry += uint(digits[j]) * 256;
            digits[j] = uint8(carry % 58);
            carry = carry / 58;
        }
        
        while (carry > 0) {
            digits[digitlength] = uint8(carry % 58);
            digitlength++;
            carry = carry / 58;
        }
        }
        //return digits;
        return string(toAlphabet(reverse(truncate(digits, digitlength))));
    }

    function toAlphabet(uint8[] memory indices) internal pure returns (bytes memory) {
        bytes memory output = new bytes(indices.length);
        for (uint256 i = 0; i<indices.length; i++) {
            output[i] = ALPHABET[indices[i]];
        }
        return output;
    }
    
    function truncate(uint8[] memory array, uint8 length) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i<length; i++) {
            output[i] = array[i];
        }
        return output;
    }
  
    function reverse(uint8[] memory input) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i<input.length; i++) {
            output[i] = input[input.length-1-i];
        }
        return output;
    }
}