/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT

// File: contracts/Base64.sol


pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}


// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: contracts/hips.sol



// Amended by HashLips
/**
    !Disclaimer!
    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    HashLips will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
*/

pragma solidity >=0.7.0 <0.9.0;




contract hips is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseExtension = ".json";
  uint256 public cost = 0.05 ether;
  uint256 public maxSupply = 10000;


  constructor() ERC721("hips","OCN"){}


  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(_mintAmount > 0);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }


 function buildImage() public pure returns(string memory) {
   return Base64.encode(bytes(abi.encodePacked(
       '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 1600"><defs>'
       '<style>.a,.b{fill:#fad3b6;}.a,.b,.c{stroke:#231815;stroke-miterlimit:10;}.a,.c{stroke-width:2px;}.b{stroke-linecap:round;}.c,.f{fill:none;}.d{fill:#e32d8b;}.e{fill:#231815;}</style></defs><path class="a" d="M1368.73,765.76c-.72-4.68-4.17-27.27-23.73-37.75-22.52-12.06-47,2.31-48.54,3.24a1068.48,1068.48,0,0,1-124.77,6.41,1066.75,1066.75,0,0,1-143.27-10.72c-59.81-13.59-106.81-14.07-172.16-19-13.26-.55-25.78.08-31.93-8.92,26.88-55.76,27.54-208.48-.25-266.41,202-228.71-2.61-273.45-57.26-492.75-77.16-.15-247,8.34-263.65-1-36.95,188.17-70.82,306.83-25,506.24C509.25,579,505.66,681.72,537.42,838.39c6.7,14.19,10.83,21.15,13.52,20.06a55.14,55.14,0,0,0-1.42,7.08c16.17,22.51-1.76,61.41,28,100.92a115.21,115.21,0,0,0,17.64,41.73,31.75,31.75,0,0,0,8.41,8.32c11.24,6.8,2.52,23.65-8.5,20.18-3.24,35.51,28.51,57.7,41.75,87.6,4.74,10.92,6.41,24.46,14,33.94,3.51,4.4,4.48,10.28.7,14.79,3.18,17.69,14.64,32.71,19.68,49.87,18.93,12.3,1.56,82.11-6.44,101.3a19.21,19.21,0,0,1,2.44,3.4c5.23-2.32,12.55-.6,15.25,5.14,5.41-7.07,16-8.07,21.19-1.72,15.22-2.82,20.27,17.07,16.51,28.63a10.12,10.12,0,0,1,1.17,2.58,9.6,9.6,0,0,1,2.33,1.22A56.53,56.53,0,0,1,723,1350c.85-5,3.72-8.1,1.6-13.2-2.78-15.47-5.26-31-6.7-46.7-10.06-4-7.06-15.15-1.2-21.42.78-19.57,1.74-38.65.09-58.19-30.17,5,.86-104.11,1.82-122.59-.66-133.33,1.67-134.45-23.23-223.19-2.43-28,1.92-48,6.47-74.54,21.9,36.44,21.29,63.5,73.19,58,71.61-13.25,143,13.14,215,.83,126.4-26,221.29-45.13,254.15-51.42,5.76-1.1,21.78-6.63,32.81,1.47,11.82,8.67,11.8,28,10.87,39-3.11,12.33-2.54,19.89-1.31,24.62.28,1.08,1.71,6.26,3,13.3.74,4.06.94,5.94,1,6.58a56.1,56.1,0,0,1-.27,12.67,82,82,0,0,0,2.7,17.26,96.36,96.36,0,0,0,4.85,13.48c2.66,6.78,4,17.6-2.43,35.06.27,7.49,2.59,9.72,4,10.52,8.93,4.9,29.66-19.28,30.56-20.36-3.64,7,1,5.21,5.3,1.21,9.77-8.72,5.52-34.63,6.9-19.48-6.08,24.65,13.08,2.09,10.22-7.47.57,1.41,1,1.68,1.34,1.67,0,0,.87,0,3.21-7.89a15,15,0,0,1,.06-4.47c.76-7.44.38,3.74,2,4.29a51.18,51.18,0,0,0,3.27-6.74c11.8-29.69-13.16-48.13-12.19-81.76C1351,799.12,1373.21,795.08,1368.73,765.76Zm-37.85,182.92a29.28,29.28,0,0,0-.18-16A28.08,28.08,0,0,1,1330.88,948.68Zm22.21-34.24c.1,0-.06,2-.93,8.91C1351.75,918.33,1352.94,914.42,1353.09,914.44Z"/><path class="a" d="M740.39,1412.92c-1-3.53-2.16-7-3.46-10.49-3.37,7-10.37,12.59-16.12,17.33-9.67,8-20.39,14.25-31,20.68,9.05,2.46,18.43,4.39,29.37,2.78C716.34,1427.06,748.41,1429,740.39,1412.92Z"/>'
       '<path class="a" d="M552.09,841.81s0,0,0,.12S552.09,841.85,552.09,841.81Z"/><path class="a" d="M552.64,853.29h0a1,1,0,0,0,0-.13A.93.93,0,0,1,552.64,853.29Z"/><line class="b" x1="705.63" y1="1367.92" x2="688.1" y2="1402.71"/><line class="b" x1="723.16" y1="1371.7" x2="733.67" y2="1417.27"/><line class="b" x1="661.67" y1="1367.11" x2="629.58" y2="1425.63"/><path class="a" d="M537.44,838.39c3.36,18.79,8.36,45.42,15.14,77.4,3.3,15.54,6.38,29.3,8,36.14,5.79,25.06,17.12,68,39.79,130.4a886.09,886.09,0,0,1,44.34,142.34,883.62,883.62,0,0,1,14.94,88.9c.72,4.34.45,8.87.24,13.22-.27,5.31.41,10.44,0,15.66a58.67,58.67,0,0,1-.3,7.77c-.48,4.65-1.43,8.25-5.26,19.23-3.61,10.33-5.53,15.53-7.77,19.63a58,58,0,0,1-6.9,10c-8.6,12.46-14.94,22.37-19.23,29.29-2.46,4-4,6.57-6.91,10.86-8.35,12.38-9.94,12.23-14.38,19.78-5.63,9.58-4.38,12.07-9.71,19.41a51.91,51.91,0,0,1-12,11.87c-2.9,1.55-37.3,20.12-41.57,30-.65,1.5-2.07,4.81-.66,7.63a8.59,8.59,0,0,0,5.16,4,12.67,12.67,0,0,0,2.55.36,17.6,17.6,0,0,0,3.82-.17c3.83-.65,6.3-2.72,6.61-2.3s-1.37,1.33-1.2,2.69a3.2,3.2,0,0,0,2.27,2.23c2.38.77,3.81-1.5,5.4-.79,1.81.81.79,4.09,2.88,5.58,1.62,1.15,4,.4,5.1,0,5-1.6,7.18-6.87,7.66-8.13-1,1.64-4.36,7.54-2.92,8.85,1.16,1,4.1.42,5.08.19,3-.71,4.18-2.24,6-1.66,1,.34,1.07,1,2,1.61,2.41,1.67,5.84-.77,13.3-3.42,5.08-1.8,5.92-1.54,9-3.22a29.41,29.41,0,0,0,5.82-4.18c1.86-1.64,4.42-3.92,7.44-6.64,12.85-11.59,21.35-19.27,30.82-28.89,7.66-7.79,15.79-15.14,23.15-23.23a41.14,41.14,0,0,1,13.12-9.71,39.73,39.73,0,0,1,5.21-2q2-.56,4-1.08,4.28-1.14,8.45-2.16c5.45-1,10.2-2.13,14.14-3.19a53.6,53.6,0,0,0,8.59-2.76,38.43,38.43,0,0,0,11.83-8.57,44.41,44.41,0,0,0,7.58-10.39,25.39,25.39,0,0,0,3.3-7,24.76,24.76,0,0,0,1-6.75,12.34,12.34,0,0,0-.21-2.39,16.87,16.87,0,0,0-2.39-6.26,29.72,29.72,0,0,1-2.23-3.23,16.5,16.5,0,0,1-1.54-3c-11.47-29.91-27.63-83.55-27.82-244.5,0-11.17,0-25.49.12-41.62.26-61.86.71-73.42.19-99.48-.62-31.35-.93-47-2.76-63.54a403.76,403.76,0,0,0-20.25-89.25"/><line class="a" x1="563.7" y1="1530.53" x2="567.62" y2="1527.29"/><path class="a" d="M583.5,1538.81c.67-1.89,8.28-8.28,8.28-8.28"/><path class="c" d="M844.07,243.12a140.59,140.59,0,0,1,.36,37c-4,32.14-18.07,54.19-24.43,63.89-23.39,35.67-55.24,53-70.86,60.12-1.69,1-3.55,2.05-5.6,3.05-1.56.77-3.08,1.43-4.52,2-1.84.83-4.83,2.15-8.54,3.74-23.37,10-33.86,12.75-44.48,22.08-3.31,2.91-7.31,7-8,12.73a17.23,17.23,0,0,0,1,8.27c20,59,31,119,35,181a559.89,559.89,0,0,1-2,93c-.64,5.39-1.52,11.52-1.52,11.52q-4.49,25.11-9,50.22"/><path class="c" d="M695.29,864.05c-.19-1.25-.1-.73-.1-.73"/><path class="d" d="M842.13,232.33l-.41-1.22h0c-5.4-12.13-31.17-99.74-7.33-126.37,1.32-1.49,2.14-2,3.36-3.34,1.55-1.76,2.33-2.64,2.47-3.56.28-1.9-1.52-2.72-4.22-6.51s-2.36-5.14-4.45-7.63a22.49,22.49,0,0,1-2.92-4.44c0-.1-.07-.13-.13-.26-1.85-3.84-2.77-5.76-4.08-6.4s-2.64.1-4.5.73c-2,.68-5.1,1-11.24.87-28.06-.58-202.63-2.73-268-2-13,.15-33.26.53-58.35,1.73-.71-.14-2.7-.46-4,.7-.62.54-.9,1.25-1.34,3.5a53.44,53.44,0,0,0-.81,5.67q-1.17,4.13-2.43,8.36c-.9,3-1.8,5.95-2.72,8.85a7.06,7.06,0,0,1,.23,3.2,7.84,7.84,0,0,1-.3,1.14c-.68,2.12-1.33,4.47-1.88,7a75.63,75.63,0,0,0-1.32,8.67C662,120.72,789.34,86.5,842.13,232.33Z"/><path class="e" d="M842.86,232.13c-1.49-4.42-3.21-8.74-4.57-13.21-2.35-7.71-4.38-15.52-6.17-23.38-4.32-19-7.63-38.75-6.86-58.3.32-8.32,1.41-16.93,4.81-24.62a30.42,30.42,0,0,1,7-9.87c1.33-1.27,3.87-3.34,3.9-5.4s-2.39-3.78-3.47-5.18c-1.79-2.3-2.74-4.85-4.23-7.29-1.27-2.1-2.93-3.83-4-6.07-1-2-1.85-4.87-3.7-6.22s-4.06-.06-5.93.52c-3.86,1.18-8.2.77-12.18.7l-5.79-.1q-19.87-.33-39.75-.56-28.93-.36-57.87-.65-32.37-.33-64.74-.55-30.19-.21-60.37-.26c-16.44,0-32.89,0-49.34.32q-20.89.38-41.78,1.32a54.13,54.13,0,0,1-5.55.15,7.71,7.71,0,0,0-2.87.21c-2.24.72-2.69,2.41-3.11,4.54-.29,1.43-.51,2.88-.68,4.33A37.07,37.07,0,0,1,474,88.75c-1.14,3.91-2.38,7.78-3.54,11.69-.42,1.43.27,2.91-.12,4.47s-1,3.22-1.4,4.86a75.5,75.5,0,0,0-2,11.37c0,.23.26.25.43.25,35.34-.06,70.66-1.33,106-2.46,30-1,60-1.91,89.94-.7,25.07,1,50.4,3.52,74.56,10.62,21.4,6.28,41.56,16.5,58.15,31.55,18.7,16.95,32,38.89,41.48,62.09q2,5,3.86,10c.16.43,1.59,0,1.45-.39-8.83-24.33-21.21-47.78-39.4-66.44-15.62-16-35-27.57-56.12-34.85-23.29-8-48-11.29-72.51-12.78-29.46-1.79-59-1.11-88.53-.23-34.87,1-69.73,2.45-104.62,2.77q-6.82.08-13.65.08l.42.25a75.63,75.63,0,0,1,2-11.38c.41-1.63,1-3.22,1.4-4.86s-.16-3.21.23-4.8c.95-3.94,2.4-7.81,3.53-11.7a33.33,33.33,0,0,0,1.4-5.52c.17-1.56.4-3.11.71-4.65.2-1,.34-2.44,1.11-3.25,1-1,4.89-.57,6.2-.63q5.85-.27,11.71-.49,10.53-.42,21.08-.68c17.18-.44,34.36-.55,51.55-.56q28.67,0,57.34.18,31.92.18,63.84.5,29.58.27,59.17.63,22.11.27,44.22.59,6.52.09,13.06.22c3.91.07,8,.32,11.83-.57,1-.24,2-.7,3-1,2-.52,2.81.27,3.75,1.8,1.54,2.49,2.49,5.28,4.19,7.68a33.2,33.2,0,0,1,3.3,5.21,32.85,32.85,0,0,0,5,7.25,5,5,0,0,1,1.47,2.39c.17,1.26-.82,2.25-1.57,3.13-1.76,2.05-3.87,3.73-5.51,5.89-4.5,5.91-6.55,13.39-7.64,20.62-2.79,18.59-.18,38,3.27,56.34a293.3,293.3,0,0,0,11.49,44.23c.6,1.67,1.31,3.3,1.88,5C841.56,233,843,232.54,842.86,232.13Z"/><path class="f" d="M416,212.33l5-2.33"/><path class="e" d="M1470.73,857.46c-21.62-28.3-57.14-45-74-76.33-8.56-15.89-6.85-22.41-19.48-37.6-1.5-1.81-21.38-25.35-32.35-20.37-3.41,1.54-5,5.42-8.09,21-5.24,26.69-5.81,37.93-5.81,37.93-1.48,31.26-1.49,70.36-1.48,82.21,0,12.06.06,21.5-3.57,33.68-3.56,12-6.35,12.11-9.77,25.37-2.34,9.07-2,12.76-5.26,31.15-1.21,6.83-2.34,12.41-3.1,16.06-.27,3,1.39,5.49,3.59,6a5,5,0,0,0,3.9-.88c3-.69,6-1.45,9-2.22A24.45,24.45,0,0,0,1331,972c1.26-.5,4.92-2.07,12.27-10.16,0,0,5.22-5.88,13.36-18.26a32.11,32.11,0,0,0,2-3.58,29.83,29.83,0,0,0,1.48-3.78c1.51-4.76,6.61-15.64,6.61-15.64a40.9,40.9,0,0,0,3.64-15.81c-.88-5.27-2.45-13.84-5-24.28-6.29-25.47-10.83-30.7-11.14-46.56-.34-17.66,5-27.07,7.52-30.91a44,44,0,0,1,6.63-7.83c10-4.8,21.53,2.29,25,6.42C1405.82,814.64,1487.08,881.71,1470.73,857.46Z"/><path class="e" d="M740.74,1580c-1.43-35.54,3.21-70.56,6.69-105.58,0-6.89,7-17.18,7-17.26,4.45-12.93,15.5-44.76-5.63-49.57-.19.38,4.21,4.66,6.57,5.88,5.32,11.6-14.14,30.54-13.61,29.76a70.68,70.68,0,0,1-27.55,15.37c-2.75.85-10.21.45-18.46,4.58-43,38.64-45.27,54-106,82.43-22.91,1.85-17.31,1.5-39.16-6.71-8.66-3.15-14.34-6.63-18.53-13.07,10.33-17.42,12.31-16.6,46-37.23-7.26,2.17-18.42,8.67-24.59,13.77a46.58,46.58,0,0,0-7.14,4.9,47.5,47.5,0,0,0-5,4.86c-.76.6-1.55,1.28-2.36,2s-1.59,1.6-2.25,2.35a15.41,15.41,0,0,0-5.44,11.46c12.32,15.86,46.64,28.62,63.58,26.25,35-16.9,82.79-58.56,102.47-86.29,7.86-2.84,24.84-3.59,33-1.41,1.74,52,3,95.14,3,115.48C735.76,1581.65,738.25,1580.63,740.74,1580Z"/><path class="e" d="M662.21,1375.2c3.11,8.66,5.13,16,5.94,18.61,5.35,17.48,21.9,39.15,28.07,47.23a93.24,93.24,0,0,1,8,12.27c1.65,3,2.8,5.53,3.41,6.91-2.56.07-4.92,1.71-7.47,1.77-7.62-5.35-12.84-13.38-17.86-21.22-8.15-12.68-26.78-45.79-29.71-63.25a31.28,31.28,0,0,1-.09-9.06c.56-4.22,2.74-11,4.31-10.79,1.15.13,1,3.85,3.47,12C661,1371.84,661.4,1372.94,662.21,1375.2Z"/><path class="e" d="M718.43,1350.31c-29.31,9.65-30,9.49-62.15,9.79-2.65-8-2-15.28,5.66-12.67q5.34.36,11,.53c5.74.17,11.24.16,16.49,0,6.15-1.4,12.66-3.09,19.46-5.14,8-2.43,15.43-5.06,22.22-7.75,1.8.75,2.35,5.2,1.09,8.17C731.07,1346,726.84,1347.45,718.43,1350.31Z"/><path class="e" d="M692.22,1358,681,1359.51"/><path class="e" d="M608.82,1537.9a76.89,76.89,0,0,1-14.57-14.06c-6.77-8.52-9.53-15.76-13.47-26.08-3.09-8.07-3.26-10.75-2.43-13.34,2.1-6.54,9.54-9.35,11.95-10.16a9.69,9.69,0,0,0-1.7,3.62c-.87,3.75,1.29,6.91,1.88,9,2.34,8.1,6.55,14.22,14.86,26.12a20,20,0,0,0,5,6c6.94,5.61,16.07,4.85,16.11,6.67,0,.64-1.13,1-3.11,2a37.89,37.89,0,0,0-8,5.57"/><path class="e" d="M1276.1,800.82c-2.5-2.58-3.7-6.67-3.64-15,.09-11.86,2.67-22.81,6.5-36.8,1.23-4.47,3-10.72,5.23-18.21-2.71-1.11-7.91-2.82-10.92-.4-2.12,1.7-2.17,4.66-2.43,7.68-.76,9.08-2.31,6.15-4.45,19.82-1.34,8.57-1.55,15-1.86,24.27-.21,6.33-.33,16.14-.34,16.14h0s4.63,1.43,6.65,2.07c10.73,3.38,11,4.14,13.35,4,3.29-.14,4.92-1.68,9.3-4.45,12.45-7.85,14.42-5,25.12-12.21,7.23-4.88,10.83-9.21,12.55-8,1.45,1,.38,5.12-.41,7.24-.66,1.79-3.15,7.62-13.66,13.25-8,4.29-11.1,3.32-21.15,7.8a85.3,85.3,0,0,0-11.34,6.13c-.28-.69-.68-1.67-1.22-2.83a47.19,47.19,0,0,0-2.85-5.43A26.83,26.83,0,0,0,1276.1,800.82Z"/><path class="e" d="M1289.91,917.55a5.42,5.42,0,0,1-1.16-3.86,4.56,4.56,0,0,1,.43-1.23c1.32-3.09-1.27-6.81-.54-7.28.43-.28,1.41.93,3.55,2.37h0a36.93,36.93,0,0,0,4.14,2.18c1.55.68,11.55,1.9,25.05-.32a32.65,32.65,0,0,0-2.54,6c-1.64,5.37-1.06,8.5-3.18,9.94-1.27.86-2.77.71-5.45,0C1299.08,922.49,1292.14,920.78,1289.91,917.55Z"/></svg> '
   )));
   }


  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
 return string(abi.encodePacked(

'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
    '{"name": "OnChainTest',
'", "description": "First test'
'", "image": "data:image/svg+xml;base64,',
buildImage(),
'"}'
  ))) 
));  
 

 
  }

  //only owner
  function reveal() public onlyOwner {
 
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  
  
  function withdraw() public payable onlyOwner {
    // This will pay HashLips 5% of the initial sale.
    // You can remove this if you want, or keep it in to support HashLips and his channel.
    // =============================================================================
    (bool hs, ) = payable(0x943590A42C27D08e3744202c4Ae5eD55c2dE240D).call{value: address(this).balance * 5 / 100}("");
    require(hs);
    // =============================================================================
    
    // This will payout the owner 95% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
 }