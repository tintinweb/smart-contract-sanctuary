/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// File: base64-sol/base64.sol



pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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

// File: contracts/Loomie.sol



pragma solidity ^0.8.0;



contract Loomie is ERC721 {
    constructor() ERC721("Loomie", "LOOM") {
        _mint(0x3D7D3Ce2832C5b256DeDEd02B4B04537F7F3BAc2, 0);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory image = string(abi.encodePacked(
            '<svg viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg"><defs><radialGradient id="a" cx="193.93" cy="159.67" r="81.225" gradientTransform="matrix(1.4252 -1.1819 .63834 .76975 -185.33 217.07)" gradientUnits="userSpaceOnUse"><stop stop-color="#002aff" offset="0"/><stop stop-color="#141e4d" offset="1"/></radialGradient><radialGradient id="b" cx="96.771" cy="187.13" r="40.819" gradientTransform="matrix(2.0247 -.20106 .09881 .99511 -117.66 20.372)" gradientUnits="userSpaceOnUse"><stop stop-color="rgba(0, 0, 0, 1)" offset="0"/><stop stop-color="#1a1250" offset="1"/></radialGradient><radialGradient id="c" cx="160.59" cy="150.28" r="18.504" gradientTransform="matrix(.76392 .02781 -.02853 .78374 45.756 29.81)" gradientUnits="userSpaceOnUse" spreadMethod="reflect"><stop stop-color="#efefef" offset="0"/><stop stop-color="#fff" offset="1"/></radialGradient><radialGradient id="e" cx="160.59" cy="150.28" r="18.504" gradientTransform="matrix(.76392 .02781 -.02853 .78374 -16.467 30.318)" gradientUnits="userSpaceOnUse" spreadMethod="reflect"><stop stop-color="#efefef" offset="0"/><stop stop-color="#fff" offset="1"/></radialGradient><radialGradient id="g" cx="134.73" cy="76.96" r="72.852" gradientTransform="matrix(.9713 -.66015 .56212 .82706 -45.922 80.309)" gradientUnits="userSpaceOnUse"><stop stop-color="red" offset="0"/><stop stop-color="#7a0000" offset="1"/></radialGradient><radialGradient id="h" cx="33.503" cy="104.13" r="75.456" gradientTransform="matrix(1.0974 -.36519 .31574 .94884 4.43 37.726)" gradientUnits="userSpaceOnUse"><stop stop-color="#bfbfbf" offset="0"/><stop stop-color="#fff" offset="1"/></radialGradient><radialGradient id="i" cx="10.163" cy="118.08" r="14.795" gradientTransform="matrix(1.2544 -1.1024 .66013 .75115 -78.56 47.387)" gradientUnits="userSpaceOnUse"><stop stop-color="#c6c6c6" offset="0"/><stop stop-color="#fff" offset="1"/></radialGradient><linearGradient id="d" x1="102.65" x2="102.65" y1="130.21" y2="167.22" gradientTransform="matrix(.68535 .72821 -1.162 1.0936 274.6 -93.153)" gradientUnits="userSpaceOnUse"><stop stop-color="#312bb2" offset="0"/><stop stop-color="#06042e" offset="1"/></linearGradient><linearGradient id="f" x1="102.65" x2="102.65" y1="130.21" y2="167.22" gradientTransform="matrix(.64189 .7668 -1.6055 1.344 289.95 -140.33)" gradientUnits="userSpaceOnUse"><stop stop-color="#1d1879" offset="0"/><stop stop-color="#06042e" offset="1"/></linearGradient></defs><circle cx="128.72" cy="155.68" fill="url(#a)" stroke="#000" stroke-width="4" style="paint-order:fill" r="81.225"/><path d="m93.81 186.85 81.637-.493" fill="#d8d8d8" stroke="url(#b)" stroke-width="3"/><circle cx="164.15" cy="152.05" fill="url(#c)" stroke="url(#d)" stroke-width="3" style="paint-order:fill" r="18.504"/><circle cx="101.93" cy="152.56" fill="url(#e)" stroke="url(#f)" stroke-width="3" style="paint-order:fill" r="18.504"/><g><path transform="translate(-112.608 -43.63) scale(.60729)" d="M321.47 125.28a7.699 7.699 0 0 0-2.393.375 3.715 3.715 0 0 0-.398.15c-.743.263-1.412.54-1.68.627-19.034 6.213-34.556 20.93-45.99 36.994-10.38 14.583-17.21 30.093-20.236 42.35-1.313-.092-2.647-.014-3.902.383a3.715 3.715 0 0 0-.012.004c-3.488 1.117-6.138 4.257-6.99 7.795-.01.003-.022 0-.033.004a3.715 3.715 0 0 0-.004 0c-5.245 1.675-8.496 7.971-6.822 13.217a3.715 3.715 0 0 0 .002.004c.955 2.981 3.39 5.351 6.285 6.512.08.567.128 1.143.3 1.69a3.715 3.715 0 0 0 .003.007c1.674 5.247 7.972 8.498 13.219 6.823a3.715 3.715 0 0 0 .006-.002c2.494-.8 4.538-2.654 5.841-4.92 1.195.04 2.4-.094 3.54-.455a3.715 3.715 0 0 0 .005-.002c1.47-.47 2.723-1.355 3.815-2.424-1.033 3.002-1.174 6.296-.1 9.281a3.715 3.715 0 0 0 .002.004c1.056 2.922 3.203 5.358 5.836 7.021 3.721 4.876 10.713 7.02 16.555 4.918a3.715 3.715 0 0 0 .01-.004c1.556-.564 2.951-1.462 4.239-2.5 3.385 1.395 7.295 1.555 10.762.305a3.715 3.715 0 0 0 .006-.002c2.486-.902 4.657-2.54 6.345-4.566 3.51 1.623 7.671 1.915 11.338.597a3.715 3.715 0 0 0 .012-.006c1.626-.59 3.072-1.55 4.4-2.654 2.83.686 5.866.558 8.616-.433a3.715 3.715 0 0 0 .002-.002c3.027-1.094 5.581-3.271 7.341-5.948 3.346 1.323 7.167 1.517 10.572.29a3.715 3.715 0 0 0 .006-.003c2.85-1.032 5.276-3.031 7.026-5.492 3.47 1.546 7.536 1.84 11.139.547a3.715 3.715 0 0 0 .01-.004c2.745-.994 5.157-2.833 6.894-5.166 1.73.002 3.46-.181 5.09-.766a3.715 3.715 0 0 0 .012-.004c2.754-.999 5.162-2.866 6.9-5.21 2.943.665 6.07.527 8.912-.495a3.715 3.715 0 0 0 .012-.004c2.465-.894 4.555-2.546 6.3-4.502 1.308-.107 2.605-.323 3.84-.765a3.715 3.715 0 0 0 .014-.004c4.35-1.576 7.737-5.339 9.053-9.733 4.984-3.676 7.54-10.504 5.45-16.32a3.715 3.715 0 0 0-.005-.01c-1.412-3.896-4.692-6.982-8.601-8.402-3.388-3.513-8.538-5.03-13.371-4.111-27.514-38.378-53.611-54.72-79.166-54.988zm69.686 59.014c-15.17-.514 15.476.879.344.016a3.715 3.715 0 0 0-.145-.004 15.385 15.385 0 0 0-.744.004c3.04-.104 10.82-.42.277-.014zm-30.447 11.604c-7.585.056 7.88.1.303.002-6.495-.084 1.913.091.258.006a15.304 15.304 0 0 0-.743.002 3.715 3.715 0 0 0-.191.01c-15.255 1.222 15.398-1.09.139-.01zm-3.777.611c-.266.074-.53.156-.791.244l-.006.002a3.715 3.715 0 0 0-.31.12l.325-.127c-7.241 2.425 7.721-2.348.414-.133-6.45 1.955 2.768-.718.368-.106zm-11.771 5.93.271.002c-15.164-.663 15.42.975.291.016a3.715 3.715 0 0 0-.166-.006 14.825 14.825 0 0 0-.73.004c2.389-.032 11.306-.339.334-.016zm-18.535 4.959c-7.587.049 7.87.103.293.002-6.424-.085 1.63.082.25.006a14.904 14.904 0 0 0-.733.002 3.715 3.715 0 0 0-.18.01c-15.255 1.164 15.407-1.025.147-.01zm-11.49 3.527.289.006c-15.15-.925 15.317 1.135.193.014a3.715 3.715 0 0 0-.213-.01 15.15 15.15 0 0 0-.707.004c1.82-.065 5.183-.18.174-.008-7.598.262 7.858-.133.264-.006zm-14.746 3.625h.306c-15.155-.698 15.436 1.044.32.02a3.715 3.715 0 0 0-.173-.008 14.904 14.904 0 0 0-.733.002c3.378-.12 10.544-.388.28-.014zm-25.03 2.184c.175 1.52.379 3.085.622 4.7-2.211 1.556-3.944 3.73-5.026 6.194-.751.59-1.502 1.18-2.119 1.909.581-1.943.818-3.978.198-5.92a3.715 3.715 0 0 0-.002-.008c-.055-.169-.198-.294-.26-.46 2.033-1.723 4.217-3.823 6.588-6.415zm9.227 1.969c-15.17-.452 15.501.843.37.015a3.715 3.715 0 0 0-.14-.004h-.046a3.715 3.715 0 0 0-.184-.011zm-.256.004.012.01c-.083 0-.167-.001-.25.002 3.49-.138 10.39-.41.238-.012z" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4.94" style="paint-order:markers stroke"/><path d="M90.646 18.718c-36.881 8.035-62.522 59.764-67.081 83.58a6.794 6.794 0 0 1 1.641 1.295 6.803 6.803 0 0 1 9.841 3.844 6.802 6.802 0 0 1-1.257 6.417c.174.161.339.331.494.509 3.854-2.835 7.837-8.136 12.409-16.623.908.664 1.824-3.673 2.379-5.463 1.049-3.404 2.757-7.291 5.361-11.63.321-.537.654-1.079.999-1.621 2.364-3.715 4.807-6.68 7.44-9.02 1.657-1.48 3.212-2.498 4.738-3.146 2.883-1.249 4.575-.461 4.553-.246-.03.3-1.645.337-3.818 1.674-1.266.792-2.468 1.816-3.931 3.327-2.32 2.408-4.436 5.211-6.747 8.834-.334.524-.661 1.047-.98 1.565-2.622 4.273-4.381 7.707-5.802 10.936-.762 1.743-1.782 7.952-1.81 7.976-.522 3.032-3.153 10.069-2.099 16.668.245-.113 3.658-2.392 3.911-2.487 3.323-1.195 6.998-.769 9.872 1.145 1.277-2.446 3.458-4.342 6.094-5.298 2.988-1.076 6.281-.845 9.024.633a11.202 11.202 0 0 1 5.469-4.256 11.204 11.204 0 0 1 7.208-.144 11.237 11.237 0 0 1 4.823-3.392c3.952-1.42 8.339-.531 11.296 2.287.977-3.33 3.54-6.027 6.877-7.237 3.004-1.082 6.314-.843 9.065.653.984-3.316 3.542-5.999 6.868-7.205 2.851-1.023 5.985-.859 8.655.453.863-3.541 3.509-6.449 7.02-7.716 2.784-1 5.84-.869 8.474.363a11.18 11.18 0 0 1 5.764-4.696 11.198 11.198 0 0 1 7.001-.201 11.177 11.177 0 0 1 4.872-4.054c-13.281-20.524-48.479-64.291-78.623-57.724z" fill="url(#g)" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4.94" style="paint-order:markers stroke" transform="translate(26.978 21.946) scale(.60729)"/><path d="M51.643 116.24a10.583 10.952 70.161 0 1 9.872 1.145 10.583 10.952 70.161 0 1 6.094-5.298 10.583 10.952 70.161 0 1 9.024.633 10.583 10.952 70.161 0 1 5.47-4.255 10.583 10.952 70.161 0 1 7.207-.145 10.583 10.952 70.161 0 1 4.823-3.392 10.583 10.952 70.161 0 1 11.295 2.287 10.583 10.952 70.161 0 1 6.878-7.237 10.583 10.952 70.161 0 1 9.065.654 10.583 10.952 70.161 0 1 6.867-7.205 10.583 10.952 70.161 0 1 8.656.452 10.583 10.952 70.161 0 1 7.02-7.716 10.583 10.952 70.161 0 1 8.473.363 10.583 10.952 70.161 0 1 5.765-4.696 10.583 10.952 70.161 0 1 7-.2 10.583 10.952 70.161 0 1 5.51-4.313 10.583 10.952 70.161 0 1 12.326 3.41 10.583 10.952 70.161 0 1 7.042 6.479 10.583 10.952 70.161 0 1-5.13 12.946 10.583 10.952 70.161 0 1-7.142 8.358 10.583 10.952 70.161 0 1-4.235.654 12.095 12.125 70.161 0 1-5.922 4.618 12.095 12.125 70.161 0 1-9.322-.46 10.583 10.952 70.161 0 1-6.499 6.168 10.583 10.952 70.161 0 1-5.82.48 10.583 10.952 70.161 0 1-6.176 5.455 10.583 10.952 70.161 0 1-11.295-2.287 10.583 10.952 70.161 0 1-6.878 7.237 10.583 10.952 70.161 0 1-10.931-1.94 10.583 10.952 70.161 0 1-6.987 7.6 10.583 10.952 70.161 0 1-8.243-.249 10.583 10.952 70.161 0 1-4.78 3.34 10.583 10.952 70.161 0 1-11.195-2.192 10.583 10.952 70.161 0 1-6.498 6.166 10.583 10.952 70.161 0 1-10.102-1.294 10.583 10.952 70.161 0 1-4.906 3.493 10.583 10.952 70.161 0 1-12.838-4.136 10.583 10.952 70.161 0 1-4.803-5.572 10.583 10.952 70.161 0 1 4.594-12.64 10.583 10.952 70.161 0 1 6.72-6.711z" fill="url(#h)" style="paint-order:markers stroke" transform="translate(26.978 21.946) scale(.60729)"/><path d="M16.633 102.86a6.804 6.804 0 0 1 7.06 1.869 6.804 6.804 0 0 1 1.29-.568 6.804 6.804 0 0 1 8.551 4.412 6.804 6.804 0 0 1-1.257 6.416 6.804 6.804 0 0 1 1.857 2.915 6.804 6.804 0 0 1-4.412 8.551 6.804 6.804 0 0 1-4.723-.225 6.804 6.804 0 0 1-4.67 5.604 6.804 6.804 0 0 1-8.55-4.411 6.804 6.804 0 0 1-.165-3.487 6.804 6.804 0 0 1-6.425-4.726 6.804 6.804 0 0 1 4.412-8.55 6.804 6.804 0 0 1 2.376-.311 6.804 6.804 0 0 1 4.656-7.49z" fill="url(#i)" style="paint-order:markers stroke" transform="translate(26.978 21.946) scale(.60729)"/></g></svg>'
        ));

        return string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                    abi.encodePacked('{"name": "Festive Loomie", "description": "Loomies, entirely on-chain!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}')
                )
            )
        ));
    }
}