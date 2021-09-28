/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

/** 
 *  SourceUnit: /Users/etl/Projects/Hoardable/Contract/contracts/Hoardable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: /Users/etl/Projects/Hoardable/Contract/contracts/Hoardable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /Users/etl/Projects/Hoardable/Contract/contracts/Hoardable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: /Users/etl/Projects/Hoardable/Contract/contracts/Hoardable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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




/** 
 *  SourceUnit: /Users/etl/Projects/Hoardable/Contract/contracts/Hoardable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IERC165.sol";

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




/** 
 *  SourceUnit: /Users/etl/Projects/Hoardable/Contract/contracts/Hoardable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: /Users/etl/Projects/Hoardable/Contract/contracts/Hoardable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: /Users/etl/Projects/Hoardable/Contract/contracts/Hoardable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../IERC721.sol";

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




/** 
 *  SourceUnit: /Users/etl/Projects/Hoardable/Contract/contracts/Hoardable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: /Users/etl/Projects/Hoardable/Contract/contracts/Hoardable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../../../utils/Address.sol";

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




/** 
 *  SourceUnit: /Users/etl/Projects/Hoardable/Contract/contracts/Hoardable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IERC721.sol";
////import "./IERC721Receiver.sol";
////import "./extensions/IERC721Metadata.sol";
////import "../../utils/Address.sol";
////import "../../utils/Context.sol";
////import "../../utils/Strings.sol";
////import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
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
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
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
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


/** 
 *  SourceUnit: /Users/etl/Projects/Hoardable/Contract/contracts/Hoardable.sol
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

////import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
////import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";




interface IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}
interface HoardableTradeHandler {
    function handleTrade(address _from, address _to, uint256 _tokenId) external;
}




contract Hoardable is ERC721 {
    using SafeERC20 for IERC20;
    constructor() ERC721("Hoardable", "HRDBL") {
        hoardableAddress = msg.sender;
        hoardableRoyaltyAddress = msg.sender;
    }

    event projectCreated(address indexed to, uint256 indexed projectId);

    event projectPublished(uint256 indexed unlockBlock, uint256 indexed projectId);




    // Admin
    address public hoardableAddress;
    uint256 public hoardablePercentage = 1000;
    uint256 public projectCreationPriceInWei = 0.01 ether;

    address public hoardableRoyaltyInfoContract;
    address public hoardableRoyaltyAddress;

    mapping(address => uint256) public hoardableBalances;

    string public hoardableBaseUri = 'https://api.hoardable.io/token/';
    string public hoardableContractUri = 'https://api.hoardable.io/contract';

    uint256 constant public SIZE_CONSTRAINT = 1_000_000_000;

    mapping(address => bool) public whitelistedMintingContracts;
    mapping(address => bool) public whitelistedTradingContracts;
    mapping(address => bool) public whitelistedExtensionContracts;


    // Contract Level
    mapping(uint256 => mapping(address => uint256)) public projectIdToBalances;

    uint256 public nextProjectId;
    

    // Project Level
    mapping(uint256 => address) public projectIdToArtistAddress;
    mapping(address => uint256[]) internal artistAddressToProjectIds;


    mapping(uint256 => uint32) public projectIdToTokens;
    mapping(uint256 => uint256) public projectIdToUnlockBlock;


    mapping(uint256 => address) public projectIdToMintingContract;
    mapping(uint256 => address) public projectIdToTradingContract;

    mapping(uint256 => mapping(address => uint256)) public projectIdToExtensionContracts;
    mapping(uint256 => address[]) public projectIdToAllExtensionContracts;


    mapping(uint256 => mapping(address => uint256[])) public projectIdToSettings;

    
    mapping(uint256 => string) public projectIdToBaseURI;
    mapping(uint256 => string) public projectIdToArchiveURI;


    // Token Level
    mapping(uint256 => mapping(uint256 => uint256)) public tokenIdToProperties;






    modifier onlyArtist(uint256 _projectId) {
        require(
            msg.sender == projectIdToArtistAddress[_projectId],
            "Only artist"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == hoardableAddress, "Only admin");
        _;
    }

    modifier onlyExistingToken(uint256 _tokenId) {
        require(_exists(_tokenId), "Nonexistent token");
        _;
    }






    //// Admin Commands
    function adminTransferContractOwnership(address _to)
        external
        onlyAdmin
    {
        hoardableAddress = _to;
    }


    function adminSetHoardableSalesPercentage(uint256 _hoardablePercentage)
        external
        onlyAdmin
    {
        hoardablePercentage = _hoardablePercentage;
    }


    function adminSetProjectCreationPrice(uint256 _priceInWei)
        external
        onlyAdmin
    {
        projectCreationPriceInWei = _priceInWei;
    }


    function adminSetHoardableRoyaltyInfoContract(address _royaltyInfoContract)
        external
        onlyAdmin
    {
        hoardableRoyaltyInfoContract = _royaltyInfoContract;
    }

    function adminSetHoardableRoyaltyAddress(address _RoyaltyAddress)
        external
        onlyAdmin
    {
        hoardableRoyaltyAddress = _RoyaltyAddress;
    }


    function adminSetBaseUri(string calldata _baseUri)
        external
        onlyAdmin
    {
        hoardableBaseUri = _baseUri;
    }
    function adminSetContractUri(string calldata _contractUri)
        external
        onlyAdmin
    {
        hoardableContractUri = _contractUri;
    }

    
    function adminWhitelistMintingContract(address _contract, bool _whitelist)
        external
        onlyAdmin
    {
        whitelistedMintingContracts[_contract] = _whitelist;
    }
    function adminWhitelistTradingContract(address _contract, bool _whitelist)
        external
        onlyAdmin
    {
        whitelistedTradingContracts[_contract] = _whitelist;
    }
    function adminWhitelistExtensionContract(address _contract, bool _whitelist)
        external
        onlyAdmin
    {
        whitelistedExtensionContracts[_contract] = _whitelist;
    }





    //// User Commands
    function createProject() external payable returns (uint256 _projectId) {
        return createProjectTo(msg.sender);
    }


    function createProjectTo(address _to)
        public
        payable
        returns (uint256 _projectId)
    {
        require(msg.value >= projectCreationPriceInWei, "Insufficient ETH");
        
        _projectId = nextProjectId;

        hoardableBalances[address(0)] += projectCreationPriceInWei;
        if (msg.value > projectCreationPriceInWei) {
            projectIdToBalances[_projectId][address(0)] += (msg.value - projectCreationPriceInWei);
        }
        
        require(_projectId * SIZE_CONSTRAINT >= 0);
        projectIdToArtistAddress[_projectId] = _to;
        artistAddressToProjectIds[_to].push(_projectId);
        emit projectCreated(_to, _projectId);
        nextProjectId ++;
    }

    function adminCreateProjectTo(address _to)
        external
        onlyAdmin
        returns (uint256 _projectId)
    {
        _projectId = nextProjectId;
        require(_projectId * SIZE_CONSTRAINT >= 0);
        projectIdToArtistAddress[_projectId] = _to;
        artistAddressToProjectIds[_to].push(_projectId);
        emit projectCreated(_to, _projectId);
        nextProjectId ++;
    }


    function setProjectSettings(uint256 _projectId, uint256[] calldata _projectSettings) external onlyArtist(_projectId) {
        require(projectIdToUnlockBlock[_projectId] == 0, "Project published");

        projectIdToSettings[_projectId][address(0)] = _projectSettings;

    }

    function setProjectMinter(uint256 _projectId, address _contractAddress, uint256[] calldata _contractSettings) external onlyArtist(_projectId) {
        require(projectIdToUnlockBlock[_projectId] == 0, "Project published");
        require(whitelistedMintingContracts[_contractAddress] == true, "Invalid Minting Contract");

        projectIdToMintingContract[_projectId] = _contractAddress;
        projectIdToSettings[_projectId][_contractAddress] = _contractSettings;
    }

    function setProjectTradingContract(uint256 _projectId, address _contractAddress, uint256[] calldata _contractSettings) external onlyArtist(_projectId) {
        require(projectIdToUnlockBlock[_projectId] == 0, "Project published");
        require(whitelistedTradingContracts[_contractAddress] == true, "Invalid Trading Contract");

        projectIdToTradingContract[_projectId] = _contractAddress;
        projectIdToSettings[_projectId][_contractAddress] = _contractSettings;
    }

    function addProjectExtensionContracts(uint256 _projectId, address _extensionAddress, uint256[] calldata _extensionSettings) external onlyArtist(_projectId){
        require(projectIdToUnlockBlock[_projectId] == 0, "Project published");
        require(whitelistedExtensionContracts[_extensionAddress] == true, "Invalid Extension Contract");
        require(projectIdToExtensionContracts[_projectId][_extensionAddress] == 0, "Already added");

        projectIdToExtensionContracts[_projectId][_extensionAddress] = projectIdToAllExtensionContracts[_projectId].length + 1;
        projectIdToAllExtensionContracts[_projectId].push(_extensionAddress);

        projectIdToSettings[_projectId][_extensionAddress] = _extensionSettings;

    }

    function updateProjectExtensionSettings(uint256 _projectId, address _extensionAddress, uint256[] calldata _extensionSettings) external onlyArtist(_projectId){
        require(projectIdToUnlockBlock[_projectId] == 0, "Project published");
        require(projectIdToExtensionContracts[_projectId][_extensionAddress] != 0, "Invalid extension");

        projectIdToSettings[_projectId][_extensionAddress] = _extensionSettings;

    }

    function removeProjectExtensionContracts(uint256 _projectId, address _extensionAddress) external onlyArtist(_projectId){
        require(projectIdToUnlockBlock[_projectId] == 0, "Project published");
        require(projectIdToExtensionContracts[_projectId][_extensionAddress] == 0, "Invalid extension");

        uint256 lastExtensionIndex = projectIdToAllExtensionContracts[_projectId].length;
        uint256 extensionIndex = projectIdToExtensionContracts[_projectId][_extensionAddress] - 1;

        if (extensionIndex != lastExtensionIndex) {
            address lastExtension = projectIdToAllExtensionContracts[_projectId][lastExtensionIndex];

            projectIdToAllExtensionContracts[_projectId][extensionIndex] = lastExtension;
            projectIdToExtensionContracts[_projectId][projectIdToAllExtensionContracts[_projectId][extensionIndex]] = extensionIndex + 1;
        }

        delete projectIdToExtensionContracts[_projectId][_extensionAddress];
        delete projectIdToAllExtensionContracts[_projectId][lastExtensionIndex];
        delete projectIdToSettings[_projectId][_extensionAddress];

    }



    function publishProject(
        uint256 _projectId,
        uint256 _unlockBlock
    ) external onlyArtist(_projectId) {
        require(projectIdToUnlockBlock[_projectId] == 0, "Already published");
        require(_unlockBlock != 0, "Invalid unlockBlock: 0");

        projectIdToUnlockBlock[_projectId] = _unlockBlock;

        emit projectPublished(_unlockBlock, _projectId);
    }




    function mint(uint256 _projectId, address _to) public returns (uint256 _tokenId) {
        require(projectIdToMintingContract[_projectId] == msg.sender, 'Invalid minting contract');

        require(projectIdToTokens[_projectId] < SIZE_CONSTRAINT, 'Project full');

        _tokenId = (_projectId * SIZE_CONSTRAINT) + projectIdToTokens[_projectId]; 

        _safeMint(_to, _tokenId);

        projectIdToTokens[_projectId] ++;
    }
    function tradeMint(uint256 _projectId, address _to) public returns (uint256 _tokenId) {
        require(projectIdToTradingContract[_projectId] == msg.sender, 'Invalid trading contract');

        require(projectIdToTokens[_projectId] < SIZE_CONSTRAINT, 'Project full');

        _tokenId = (_projectId * SIZE_CONSTRAINT) + projectIdToTokens[_projectId]; 

        _safeMint(_to, _tokenId);

        projectIdToTokens[_projectId] ++;
    }    
    function extensionMint(uint256 _projectId, address _to) public returns (uint256 _tokenId) {
        require(projectIdToExtensionContracts[_projectId][msg.sender] != 0, 'Invalid extension contract');

        require(projectIdToTokens[_projectId] < SIZE_CONSTRAINT, 'Project full');

        _tokenId = (_projectId * SIZE_CONSTRAINT) + projectIdToTokens[_projectId]; 

        _safeMint(_to, _tokenId);

        projectIdToTokens[_projectId] ++;
    }


    function mintSetTokenData(uint256 _tokenId, uint256 _property, uint256 _value, bool _redraw) external {
        require(projectIdToMintingContract[_tokenId / SIZE_CONSTRAINT] == msg.sender, 'Invalid minting contract');

        tokenIdToProperties[_tokenId][_property] = _value;

        if (_redraw) {
           emit Transfer(ownerOf(_tokenId), ownerOf(_tokenId), _tokenId); 
        }
    }
    
    function tradeSetTokenData(uint256 _tokenId, uint256 _property, uint256 _value, bool _redraw) external {
        require(projectIdToTradingContract[_tokenId / SIZE_CONSTRAINT] == msg.sender, 'Invalid trading contract');

        tokenIdToProperties[_tokenId][_property] = _value;

        if (_redraw) {
           emit Transfer(ownerOf(_tokenId), ownerOf(_tokenId), _tokenId); 
        }
    }
    
    function extensionSetTokenData(uint256 _tokenId, uint256 _property, uint256 _value, bool _redraw) external {
        require(projectIdToExtensionContracts[_tokenId / SIZE_CONSTRAINT][msg.sender] != 0, 'Invalid extension contract');

        tokenIdToProperties[_tokenId][_property] = _value;

        if (_redraw) {
           emit Transfer(ownerOf(_tokenId), ownerOf(_tokenId), _tokenId); 
        }
    }


    function tradeTransfer(uint256 _tokenId, address _to, address _from) public {
        require(projectIdToTradingContract[_tokenId / SIZE_CONSTRAINT] == msg.sender, 'Invalid trading contract');        
        
        _safeTransfer(_from, _to, _tokenId, "");
    }
    function extensionTransfer(uint256 _tokenId, address _to, address _from) public {
        require(projectIdToExtensionContracts[_tokenId / SIZE_CONSTRAINT][msg.sender] != 0, 'Invalid extension contract');
        
        _safeTransfer(_from, _to, _tokenId, "");
    }


    function tradeBurn(uint256 _tokenId) public {
        require(projectIdToTradingContract[_tokenId / SIZE_CONSTRAINT] == msg.sender, 'Invalid trading contract');        
        
        _burn(_tokenId);
    }
    function extensionBurn(uint256 _tokenId) public {
        require(projectIdToExtensionContracts[_tokenId / SIZE_CONSTRAINT][msg.sender] != 0, 'Invalid extension contract');
        
        _burn(_tokenId);
    }




    function minterUpdateBalances(uint256 _projectId, address _sender, address _currencyAddress, uint256 _projectIncome, uint256 _hoardableIncome) external payable {
        require(projectIdToMintingContract[_projectId] == msg.sender, 'Invalid minting contract');

        _updateBalances(_projectId, _sender, _currencyAddress, _projectIncome, _hoardableIncome);
    }


    function royaltiesUpdateBalances(uint256 _projectId, address _sender, address _currencyAddress, uint256 _projectIncome, uint256 _hoardableIncome) external payable {
        require(hoardableRoyaltyAddress == msg.sender, 'Not royalties contract');

        _updateBalances(_projectId, _sender, _currencyAddress, _projectIncome, _hoardableIncome);
    }


    function extensionUpdateBalances(uint256 _projectId, address _sender, address _currencyAddress, uint256 _projectIncome, uint256 _hoardableIncome) external payable {
        require(projectIdToExtensionContracts[_projectId][msg.sender] != 0, 'Invalid extension contract');

        _updateBalances(_projectId, _sender, _currencyAddress, _projectIncome, _hoardableIncome);
    }

    function _updateBalances(uint256 _projectId, address _sender, address _currencyAddress, uint256 _projectIncome, uint256 _hoardableIncome) internal {

        uint256 _amount = _projectIncome + _hoardableIncome;

        if (_currencyAddress == address(0)) {

            require(msg.value >= _amount, "Insufficient ETH");

            _projectIncome += msg.value - (_amount);

        } else {

            require(msg.value == 0, "Sent ETH with ERC20");

            IERC20(_currencyAddress).safeTransferFrom(_sender, address(hoardableAddress), _amount);

        }

        projectIdToBalances[_projectId][_currencyAddress] += _projectIncome;
        hoardableBalances[_currencyAddress] += _hoardableIncome;
    }


    function projectWithdraw(uint256 _projectId, address _currencyAddress, uint256 _amount) external onlyArtist(_projectId) {
        projectWithdrawTo(_projectId, _currencyAddress, _amount, msg.sender);
    }

    function projectWithdrawTo(uint256 _projectId, address _currencyAddress, uint256 _amount, address _to) public onlyArtist(_projectId) {
        if (_currencyAddress == address(0)) {
            projectIdToBalances[_projectId][_currencyAddress] -= _amount;
            payable(_to).transfer(_amount);
        } else {
            projectIdToBalances[_projectId][_currencyAddress] -= _amount;  
            IERC20(_currencyAddress).safeTransfer(_to, _amount);
        }
    }

    function hoardableWithdraw(address _currencyAddress, uint256 _amount) external onlyAdmin {
        hoardableWithdrawTo(_currencyAddress, _amount, msg.sender);
    }

    function hoardableWithdrawTo(address _currencyAddress, uint256 _amount, address _to) public onlyAdmin {
        if (_currencyAddress == address(0)) {
            hoardableBalances[_currencyAddress] -= _amount;
            payable(_to).transfer(_amount);
        } else {
            hoardableBalances[_currencyAddress] -= _amount;  
            IERC20(_currencyAddress).safeTransfer(_to, _amount);
        }
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return IERC2981(hoardableRoyaltyInfoContract).royaltyInfo(_tokenId, _salePrice);
    }





    // Overides
    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 _tokenId) override(ERC721) public view onlyExistingToken(_tokenId) returns (string memory) {
        if (bytes(projectIdToBaseURI[_tokenId / SIZE_CONSTRAINT]).length > 0) {
            return string(abi.encodePacked(projectIdToBaseURI[_tokenId / SIZE_CONSTRAINT], uintToString(_tokenId)));
        }
    
        return string(abi.encodePacked(hoardableBaseUri, uintToString(_tokenId)));
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {

        super._transfer(from, to, tokenId);

        if (projectIdToTradingContract[tokenId / SIZE_CONSTRAINT] != address(0)) {
            HoardableTradeHandler(projectIdToTradingContract[tokenId / SIZE_CONSTRAINT]).handleTrade(from, to, tokenId);
        }
    }

    //TODO Change address for mainnet
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xF57B2c51dED3A29e6891aba85459d600256Cf317)) {
            return true;
        }
        return super.isApprovedForAll(_owner, _operator);
    }

    function artistAddressToAllProjectIds(address _artistAddress)
        public
        view
        returns (uint256[] memory)
    {
        return artistAddressToProjectIds[_artistAddress];
    }

    function projectIdToAllSettings(uint256 _projectId, address _contractAddress)
        public
        view
        returns (uint256[] memory)
    {
        return projectIdToSettings[_projectId][_contractAddress];
    }






    // Internal
    function uintToString(uint256 value) internal pure returns (string memory) {
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
}