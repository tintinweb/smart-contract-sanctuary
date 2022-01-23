/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC721/[email protected]

// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC721/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File contracts/PRNG.sol


pragma solidity 0.8.11;

contract PRNG {
    int256 public seed;

    /**
        Retrive a new pseudo random number and rotate the seed.

        IMPORTANT:
        As stated in the official solidity 0.8.11 documentation in the first warning
        on top of the following permalink:
        https://docs.soliditylang.org/en/v0.8.11/abi-spec.html#encoding-of-indexed-event-parameters

        """
        If you use keccak256(abi.encodePacked(a, b)) and both a and b are dynamic types, it is easy 
        to craft collisions in the hash value by moving parts of a into b and vice-versa. More 
        specifically, abi.encodePacked("a", "bc") == abi.encodePacked("ab", "c"). If you use 
        abi.encodePacked for signatures, authentication or data integrity, make sure to always use 
        the same types and check that at most one of them is dynamic. Unless there is a compelling 
        reason, abi.encode should be preferred.
        """

        This is why in this PRNG generator we will always use abi.encode
     */
    function rotate() public returns (uint256) {
        // Allow overflow of the seed, what we want here is the possibility for
        // the seed to rotate indiscriminately over all the number in range without
        // ever throwing an error.
        // This give the possibility to call this function every time possible.
        // The seed presence gives also the possibility to call this function subsequently even in
        // the same transaction and receive 2 different outputs
        int256 previousSeed;
        unchecked {
            previousSeed = seed - 1;
            seed++;
        }

        return
            uint256(
                keccak256(
                    // The data encoded into the abi should give enough entropy for an average security but
                    // as solidity's source code is publicly accessible under certain conditions
                    // the value may be partially manipulated by evil actors
                    abi.encode(
                        seed,                                   // can be manipulated calling an arbitrary number of times this method
                        // keccak256(abi.encode(seed)),         // can be manipulated calling an arbitrary number of times this method
                        block.coinbase,                         // can be at least partially manipulated by miners (actual miner address)
                        block.difficulty,                       // defined by the network (cannot be manipulated)
                        block.gaslimit,                         // defined by the network (cannot be manipulated)
                        block.number,                           // can be manipulated by miners
                        block.timestamp,                        // can be at least partially manipulated by miners (+-15s allowed on eth for block acceptance)
                        // blockhash(block.number - 1),         // defined by the network (cannot be manipulated)
                        // blockhash(block.number - 2),         // defined by the network (cannot be manipulated)
                        block.basefee,                          // can be at least partially manipulated by miners
                        block.chainid,                          // defined by the network (cannot be manipulated)
                        gasleft(),                              // can be at least partially manipulated by users
                        // msg.data,                            // not allowed as strongly controlled by users, this can help forging a partially predictable hash
                        msg.sender,                             // can be at least partially manipulated by users (actual caller address)
                        msg.sig,                                // current function identifier (cannot be manipulated)
                        // msg.value,                           // not allowed as strongly controlled by users, this can help forging a partially predictable hash
                        previousSeed                            // can be manipulated calling an arbitrary number of times this method
                        // keccak256(abi.encode(previousSeed))  // can be manipulated calling an arbitrary number of times this method
                    )
                )
            );
    }
}


// File contracts/StackingPanda.sol


pragma solidity 0.8.11;





contract StackingPanda is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

	struct StackingBonus {
        uint8 decimals;
        uint256 meldToMeld;
        uint256 toMeld;
    }

    struct Metadata {
        string name;
        string picUrl;
        StackingBonus bonus;
    }

    Metadata[] private metadata;

    address public masterchef;
    PRNG private prng;

    event NewPandaMinted(uint256 pandaId, string pandaName);

    // Init the NFT contract with the ownable abstact in order to let only the owner
    // mint new NFTs
    constructor(address _prng) ERC721("Melodity Stacking Panda", "STACKP") Ownable() {
        masterchef = msg.sender;
        prng = PRNG(_prng);
    }

    /**
        Mint new NFTs, the maximum number of mintable NFT is 100.
        Only the owner of the contract can call this method.
        NFTs will be minted to the owner of the contract (alias, the creator); in order
        to let the Masterchef sell the NFT immediately after minting this contract *must*
        be deployed onchain by the Masterchef itself.

        @param _name Panda NFT name
        @param _picUrl The url where the picture is stored
        @param _stackingBonus As these NFTs are designed to give stacking bonuses this 
                value defines the reward bonuses
        @return uint256 Just minted nft id
     */
    function mint(
        string calldata _name,
        string calldata _picUrl,
        StackingBonus calldata _stackingBonus
    ) public nonReentrant onlyOwner returns (uint256) {
        prng.rotate();

        // Only 100 NFTs will be mintable
        require(_tokenIds.current() < 100, "All pandas minted");

        uint256 newItemId = _tokenIds.current();
        _tokenIds.increment();

        // incrementing the counter after taking its value makes possible the aligning
        // between the metadata array and the panda id, this let us simply push the metadata
        // to the end of the array instead of calculating where to place the data
        metadata.push(
            Metadata({name: _name, picUrl: _picUrl, bonus: _stackingBonus})
        );
        _mint(owner(), newItemId);

        emit NewPandaMinted(newItemId, _name);

        return newItemId;
    }

    /**
        Retrieve and return the metadata for the provided _nftId
        @param _nftId Identifier of the NFT whose data should be returned
        @return Metadata
     */
    function getMetadata(uint256 _nftId) public view returns (Metadata memory) {
        return metadata[_nftId];
    }
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}


// File contracts/Marketplace/Auction.sol


pragma solidity 0.8.11;





contract Auction is ERC721Holder, ReentrancyGuard {
    PRNG public prng;

    address payable public beneficiary;
    uint256 public auctionEndTime;

    // Current state of the auction.
    address public highestBidder;
    uint256 public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint256) public pendingReturns;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool public ended;

    address public nftContract;
    uint256 public nftId;
    uint256 public minimumBid;

    address public royaltyReceiver;
    uint256 public royaltyPercent;

    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event AuctionNotFullfilled(uint256 nftId, address nftContract, uint256 minimumBid);
    event RoyaltyPaid(address receiver, uint256 amount, uint256 royaltyPercentage);

    /**
        Create an auction with `biddingTime` seconds bidding time on behalf of the
        beneficiary address `beneficiaryAddress`.

        @param _biddingTime Number of seconds the auction will be valid
        @param _beneficiaryAddress The address where the highest big will be credited
        @param _nftId The unique identifier of the NFT that is being sold
        @param _nftContract The address of the contract of the NFT
        @param _minimumBid The minimum bid that must be placed in order for the auction to start.
                Bid lower than this amount are refused.
                If no bid is higher than this amount at the end of the auction the NFT will be sent
                to the beneficiary
        @param _royaltyReceiver The address of the royalty receiver for a given auction
        @param _royaltyPercentage The 18 decimals percentage of the highest bid that will be sent to 
                the royalty receiver
		@param _prng The address of the masterchef who deployed the prng
    */
    constructor(
        uint256 _biddingTime,
        address payable _beneficiaryAddress,
        uint256 _nftId,
        address _nftContract,
        uint256 _minimumBid,
        address _royaltyReceiver,
        uint256 _royaltyPercentage,
		address _prng
    ) {
        prng = PRNG(_prng);
        prng.rotate();

        beneficiary = _beneficiaryAddress;
        auctionEndTime = block.timestamp + _biddingTime;
        nftContract = _nftContract;
        nftId = _nftId;
        minimumBid = _minimumBid;
        royaltyReceiver = _royaltyReceiver;
        royaltyPercent = _royaltyPercentage;
    }

    /** 
        Bid on the auction with the value sent together with this transaction.
        The value will only be refunded if the auction is not won.
    */
    function bid() public nonReentrant payable {
        prng.rotate();

        // check that the auction is still in its bidding period
        require(block.timestamp <= auctionEndTime, "Auction already ended");
        
        // check that the bid is higher or equal to the minimum bid to participate
        // in this auction
        require(msg.value >= minimumBid, "Bid not high enough to participate in this auction");

        // check that the current bid is higher than the previous
        require(msg.value > highestBid, "Higher or equal bid already present");

        if (highestBid != 0) {
            // save the previously highest bid in the pending return pot
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /**
        Withdraw a bids that were overbid.
    */
    function withdraw() public nonReentrant {
        prng.rotate();

        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            // send the previous bid back to the sender
            Address.sendValue(payable(msg.sender), amount);
        }
    }

    /** 
        End the auction and send the highest bid to the beneficiary.
        If defined split the bid with the royalty receiver
    */
    function endAuction() public nonReentrant {
        prng.rotate();

        // check that the auction is ended
        require(block.timestamp >= auctionEndTime, "Auction not ended yet");
        // check that the auction end call have not already been called
        require(!ended, "Auction already ended");

        // mark the auction as ended
        ended = true;

        if (highestBid == 0) {
            // send the NFT to the beneficiary if no bid has been accepted
            ERC721(nftContract).safeTransferFrom(address(this), beneficiary, nftId);
            emit AuctionNotFullfilled(nftId, nftContract, minimumBid);
        }
        else {
            // send the NFT to the bidder
            ERC721(nftContract).safeTransferFrom(address(this), highestBidder, nftId);

            // check if the royalty receiver and the payee are the same address
            // if they are make a transfer only, otherwhise split the bid based on
            // the royalty percentage and send the values

            if (beneficiary == royaltyReceiver) {
                // send the highest bid to the beneficiary
                Address.sendValue(beneficiary, highestBid);
            }
            else {
                // the royalty percentage has 18 decimals + 2 per percentage
                uint256 royalty = highestBid * royaltyPercent / 10 ** 20;
                uint256 beneficiaryEarning = highestBid - royalty;

                // send the royalty funds
                Address.sendValue(payable(royaltyReceiver), royalty);
                emit RoyaltyPaid(royaltyReceiver, royalty, royaltyPercent);

                // send the beneficiary earnings
                Address.sendValue(beneficiary, beneficiaryEarning);
            }

            emit AuctionEnded(highestBidder, highestBid);
        }
    }
}


// File contracts/Marketplace/BlindAuction.sol


pragma solidity 0.8.11;





contract BlindAuction is ERC721Holder, ReentrancyGuard {
    PRNG public prng;

    struct Bid {
        bytes32 blindedBid;
        uint256 deposit;
    }

    address payable public beneficiary;
    uint256 public biddingEnd;
    uint256 public revealEnd;
    bool public ended;

    address public nftContract;
    uint256 public nftId;
    uint256 public minimumBid;

    address public royaltyReceiver;
    uint256 public royaltyPercent;

    mapping(address => Bid[]) public bids;

    address public highestBidder;
    uint256 public highestBid;

    // Allowed withdrawals of previous bids that were overbid
    mapping(address => uint256) private pendingReturns;

    event BidPlaced(address bidder);
    event AuctionEnded(address winner, uint256 highestBid);
    event AuctionNotFullfilled(uint256 nftId, address nftContract, uint256 minimumBid);
    event RoyaltyPaid(address receiver, uint256 amount, uint256 royaltyPercentage);

    // Modifiers are a convenient way to validate inputs to
    // functions. `onlyBefore` is applied to `bid` below:
    // The new function body is the modifier's body where
    // `_` is replaced by the old function body.
    modifier onlyBefore(uint256 time) {
        require(block.timestamp < time, "Method called too late");
        _;
    }
    modifier onlyAfter(uint256 time) {
        require(block.timestamp > time, "Method called too early");
        _;
    }

    constructor(
        uint256 _biddingTime,
        uint256 _revealTime,
        address payable _beneficiaryAddress,
        uint256 _nftId,
        address _nftContract,
        uint256 _minimumBid,
        address _royaltyReceiver,
        uint256 _royaltyPercentage,
        address _prng
    ) {
        prng = PRNG(_prng);
        prng.rotate();

        beneficiary = _beneficiaryAddress;
        biddingEnd = block.timestamp + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
        nftContract = _nftContract;
        nftId = _nftId;
        minimumBid = _minimumBid;
        royaltyReceiver = _royaltyReceiver;
        royaltyPercent = _royaltyPercentage;
    }

    /** 
		Place a blinded bid with 
		`blindedBid` = keccak256(abi.encode(value, fake, secret)).
    	The sent ether is only refunded if the bid is correctly
     	revealed in the revealing phase. 
		The bid is valid if the ether sent together with the bid 
		is at least "value" and "fake" is not true. 
		Setting "fake" to true and sending not the exact amount 
		are ways to hide the real bid but still make the required 
		deposit. 
		The same address can place multiple bids.
	*/
    function bid(bytes32 blindedBid) public payable nonReentrant onlyBefore(biddingEnd) {
        prng.rotate();

        bids[msg.sender].push(
            Bid({blindedBid: blindedBid, deposit: msg.value})
        );

        emit BidPlaced(msg.sender);
    }

    /** 
		Reveal blinded bids. The user will get a refund for all
    	correctly blinded invalid bids and for all bids except for
    	the totally highest.
	*/
    function reveal(
        uint256[] calldata values,
        bool[] calldata fakes,
        bytes32[] calldata secrets
    ) public nonReentrant onlyAfter(biddingEnd) onlyBefore(revealEnd) {
        prng.rotate();

		// check that the list of provided bids has the same length of
		// the list saved in the contract
        uint256 length = bids[msg.sender].length;
		require(values.length == length, "You're not revealing all your bids");
		require(fakes.length == length, "You're not revealing all your bids");
		require(secrets.length == length, "You're not revealing all your bids");

        uint256 refund;
		// loop through each bid
        for (uint256 i = 0; i < length; i++) {
            Bid storage bidToCheck = bids[msg.sender][i];

            (uint256 value, bool fake, bytes32 secret) = (
                values[i],
                fakes[i],
                secrets[i]
            );

			// if the bid do not match the original value it is skipped
            if (
                bidToCheck.blindedBid !=
                keccak256(abi.encode(value, fake, secret))
            ) {
                continue;
            }

            refund += bidToCheck.deposit;
			// check that a bid is not fake, if it is not than check that
			// the deposit is >= to the value reported in the bid
            if (!fake && bidToCheck.deposit >= value) {
				// try to place a public bid
                if (placeBid(msg.sender, value)) {
                    refund -= value;
                }
            }

            // Make it impossible for the sender to re-claim
            // the same deposit.
            bidToCheck.blindedBid = bytes32(0);
        }

		// refund fake or invalid bids
        Address.sendValue(payable(msg.sender), refund);
    }

    /** 
		Withdraw a bid that was overbid.
	*/
    function withdraw() public nonReentrant {
        prng.rotate();

        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            // send the previous bid back to the sender
            Address.sendValue(payable(msg.sender), amount);
        }
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function endAuction() public nonReentrant onlyAfter(revealEnd) {
        prng.rotate();

        // check that the auction end call have not already been called
        require(!ended, "Auction already ended");

        // mark the auction as ended
        ended = true;

        if (highestBid == 0) {
            // send the NFT to the beneficiary if no bid has been accepted
            ERC721(nftContract).transferFrom(address(this), beneficiary, nftId);
            emit AuctionNotFullfilled(nftId, nftContract, minimumBid);
        }
        else {
            // send the NFT to the bidder
            ERC721(nftContract).safeTransferFrom(address(this), highestBidder, nftId);

            // check if the royalty receiver and the payee are the same address
            // if they are make a transfer only, otherwhise split the bid based on
            // the royalty percentage and send the values
            if (beneficiary == royaltyReceiver) {
                // send the highest bid to the beneficiary
                Address.sendValue(beneficiary, highestBid);
            }
            else {
                // the royalty percentage has 18 decimals + 2 percetage positions
                uint256 royalty = highestBid * royaltyPercent / 10 ** 20;
                uint256 beneficiaryEarning = highestBid - royalty;

                // send the royalty funds
                Address.sendValue(payable(royaltyReceiver), royalty);
                emit RoyaltyPaid(royaltyReceiver, royalty, royaltyPercent);

                // send the beneficiary earnings
                Address.sendValue(beneficiary, beneficiaryEarning);
            }

            emit AuctionEnded(highestBidder, highestBid);
        }
    }

    /**
		Place a public bid.
		This method is called internally by the reveal method.

		@return success True if the bid is higher than the current highest
			if true is returned the highet bidder is updated
	 */
    function placeBid(address bidder, uint256 value)
        private
        returns (bool success)
    {
		// refuse revealed bids that are lower than the current
		// highest bid or that are lower than the minimum bid
        if (value <= highestBid || value < minimumBid) {
            return false;
        }

        if (highestBidder != address(0)) {
            // Refund the previously highest bidder.
            pendingReturns[highestBidder] += highestBid;
        }

        highestBid = value;
        highestBidder = bidder;
        return true;
    }
}


// File contracts/Marketplace/Marketplace.sol


pragma solidity 0.8.11;







contract Marketplace is ReentrancyGuard {
    PRNG public prng;

    Auction[] public auctions;
    BlindAuction[] public blindAuctions;

    struct Royalty {
        // number of decimal position to include in the royalty percent
        uint8 decimals;
        // royalty percent from 0 to 100% with `decimals` decimal position
        uint256 royaltyPercent;
        // address that will receive the royalties for future sales via this
        // smart contract. Other smart contracts functionalities cannot be
        // controlled in any way
        address royaltyReceiver;
        // address of the one who can edit all this royalty settings
        address royaltyInitializer;
    }

    /**
        This mapping is a workaround for a double map with 2 indexes.
        index: keccak256(
            abi.encode(
                nft smart contract address,
                nft identifier
            )
        )
        map: Royalty
     */
    mapping(bytes32 => Royalty) public royalties;

    /*
     *     bytes4(keccak256("balanceOf(address)")) == 0x70a08231
     *     bytes4(keccak256("ownerOf(uint256)")) == 0x6352211e
     *     bytes4(keccak256("approve(address,uint256)")) == 0x095ea7b3
     *     bytes4(keccak256("getApproved(uint256)")) == 0x081812fc
     *     bytes4(keccak256("setApprovalForAll(address,bool)")) == 0xa22cb465
     *     bytes4(keccak256("isApprovedForAll(address,address)")) == 0xe985e9c5
     *     bytes4(keccak256("transferFrom(address,address,uint256)")) == 0x23b872dd
     *     bytes4(keccak256("safeTransferFrom(address,address,uint256)")) == 0x42842e0e
     *     bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)")) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256("name()")) == 0x06fdde03
     *     bytes4(keccak256("symbol()")) == 0x95d89b41
     *     bytes4(keccak256("tokenURI(uint256)")) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    event AuctionCreated(address auction, uint256 nftId, address nftContract);
    event BlindAuctionCreated(
        address auction,
        uint256 nftId,
        address nftContract
    );
    event RoyaltyUpdated(
        uint256 nftId,
        address nftContract,
        uint256 royaltyPercent,
        address royaltyReceiver,
        address royaltyInitializer
    );

    modifier onlyERC721(address _contract) {
        prng.rotate();

        require(
            // check the SC doesn't supports the ERC721 openzeppelin interface
            ERC165Checker.supportsInterface(_contract, _INTERFACE_ID_ERC721) &&
                // check the SC doesn't supports the ERC721-Metadata openzeppelin interface
                ERC165Checker.supportsInterface(
                    _contract,
                    _INTERFACE_ID_ERC721_METADATA
                ),
            "The provided address does not seem to implement the ERC721 NFT standard"
        );

        _;
    }

    constructor(address _prng) {
        prng = PRNG(_prng);
    }

    /**
        Create a public auction. The auctioner *must* own the NFT to sell.
        Once the auction ends anyone can trigger the release of the funds raised.
        All the participant can also release their bids at anytime if they are not the
        higher bidder.
        This contract is not responsible for handling the real auction but only for its creation.

        NOTE: Before actually starting the creation of the auction the user needs
        to allow the transfer of the nft.

        @param _nftId The unique identifier of the NFT that is being sold
        @param _nftContract The address of the contract of the NFT
        @param _payee The address where the highest big will be credited
        @param _auctionDuration Number of seconds the auction will be valid
        @param _minimumPrice The minimum bid that must be placed in order for the auction to start.
                Bid lower than this amount are refused.
                If no bid is higher than this amount at the end of the auction the NFT will be sent
                to the beneficiary
        @param _royaltyReceiver The address of the royalty receiver for a given auction
        @param _royaltyPercentage The 18 decimals percentage of the highest bid that will be sent to 
                the royalty receiver
		@param _blind Whether the auction to be created is a blind auction or a simple one
     */
    function createAuction(
        uint256 _nftId,
        address _nftContract,
        address _payee,
        uint256 _auctionDuration,
        uint256 _minimumPrice,
        address _royaltyReceiver,
        uint256 _royaltyPercentage,
        bool _blind
    ) private returns (address) {
        prng.rotate();

        // do not run any check on the contract as the checks are already performed by the
        // parent call

        // load the instance of the nft contract into the ERC721 interface in order
        // to expose all its methods
        ERC721 nftContractInstance = ERC721(_nftContract);

        address _auctionAddress;

        if (!_blind) {
            // create a new auction for the user
            Auction auction = new Auction(
                _auctionDuration,
                payable(_payee),
                _nftId,
                _nftContract,
                _minimumPrice,
                _royaltyReceiver,
                _royaltyPercentage,
                address(prng)
            );
            auctions.push(auction);
            _auctionAddress = address(auction);

            emit AuctionCreated(_auctionAddress, _nftId, _nftContract);
        } else {
            // create a new blind auction for the user
            BlindAuction blindAuction = new BlindAuction(
                _auctionDuration,
                1 days,
                payable(_payee),
                _nftId,
                _nftContract,
                _minimumPrice,
                _royaltyReceiver,
                _royaltyPercentage,
                address(prng)
            );
            blindAuctions.push(blindAuction);
            _auctionAddress = address(blindAuction);

            emit BlindAuctionCreated(_auctionAddress, _nftId, _nftContract);
        }

        // move the NFT from the owner to the auction contract
        nftContractInstance.safeTransferFrom(
            msg.sender,
            _auctionAddress,
            _nftId
        );

        return _auctionAddress;
    }

    /**
		Initialize a new royalty or return the already initialized for a
		(contract, nft id) pair

		@param _nftId The unique identifier of the NFT that is being sold
        @param _nftContract The address of the contract of the NFT
		@param _royaltyPercent The 18 decimals percentage of the highest bid that will be sent to 
                the royalty receiver
        @param _royaltyReceiver The address of the royalty receiver for a given auction
        @param _royaltyInitializer The address that will be allowed to edit the royalties, if the
                null address is provided sender address will be used
     */
    function initializeRoyalty(
        uint256 _nftId,
        address _nftContract,
        uint256 _royaltyPercent,
        address _royaltyReceiver,
        address _royaltyInitializer
    ) private returns (Royalty memory) {
        prng.rotate();

        bytes32 royaltyIdentifier = keccak256(abi.encode(_nftContract, _nftId));

        // check if the royalty is already defined, in case it is this is not
        // the call to edit it, the user *must* use the correct call to edit it
        Royalty memory royalty = royalties[royaltyIdentifier];

        // if the royalty initializer is the null address then the royalty is not
        // yet initialized and can be initialized now
        if (royalty.royaltyInitializer == address(0)) {
            // Check that _royaltyPercent is less or equal to 50% of the sold amount
            require(
                _royaltyPercent <= 50 ether,
                "Royalty percentage too high, max value is 50%"
            );

            // if the royalty initializer is set to the null address automatically
            // use the caller address
            if (_royaltyInitializer == address(0)) {
                _royaltyInitializer = msg.sender;
            }

            royalties[royaltyIdentifier] = Royalty({
                decimals: 18,
                royaltyPercent: _royaltyPercent, // the provided value *MUST* be padded to 18 decimal positions
                royaltyReceiver: _royaltyReceiver,
                royaltyInitializer: _royaltyInitializer
            });

            emit RoyaltyUpdated(
                _nftId,
                _nftContract,
                _royaltyPercent,
                _royaltyReceiver,
                _royaltyInitializer
            );

            return royalties[royaltyIdentifier];
        }

        return royalty;
    }

    /**
        Create a public auction and if not initialized yet, init the royalty for the
        (smart contract address, nft identifier) pair

        NOTE: This method cannot be used to edit royalties values
        WARNING: Only ERC721 compliant NFTs can be sold, other standards are not supported

        @param _nftId The unique identifier of the NFT that is being sold
        @param _nftContract The address of the contract of the NFT
        @param _payee The address where the highest big will be credited
        @param _auctionDuration Number of seconds the auction will be valid
        @param _minimumPrice The minimum bid that must be placed in order for the auction to start.
                Bid lower than this amount are refused.
                If no bid is higher than this amount at the end of the auction the NFT will be sent
                to the beneficiary
        @param _royaltyPercent The 18 decimals percentage of the highest bid that will be sent to 
                the royalty receiver
        @param _royaltyReceiver The address of the royalty receiver for a given auction
        @param _royaltyInitializer The address that will be allowed to edit the royalties, if the
                null address is provided sender address will be used
     */
    function createAuctionWithRoyalties(
        uint256 _nftId,
        address _nftContract,
        address _payee,
        uint256 _auctionDuration,
        uint256 _minimumPrice,
        uint256 _royaltyPercent,
        address _royaltyReceiver,
        address _royaltyInitializer
    ) public nonReentrant onlyERC721(_nftContract) returns (address) {
        // load the instance of the nft contract into the ERC721 interface in order
        // to expose all its methods
        ERC721 nftContractInstance = ERC721(_nftContract);

        // check that the marketplace is allowed to transfer the provided nft
        // for the user
        // ALERT: checking the approval does not check that the user actually owns the nft
        // as parameters can per forged to pass this check without the caller to actually
        // own the it. This won"t be a problem in a standard context but as we"re setting
        // up the royalty base here a check must be done in order to check if it is should be
        // set by the caller or not
        require(
            nftContractInstance.getApproved(_nftId) == address(this),
            "Trasfer not allowed for Marketplace operator"
        );

        // check if the caller is the owner of the nft in case it is then proceed with further setup
        require(
            nftContractInstance.ownerOf(_nftId) == msg.sender,
            "Not owning the provided NFT"
        );

        Royalty memory royalty = initializeRoyalty(
            _nftId,
            _nftContract,
            _royaltyPercent,
            _royaltyReceiver,
            _royaltyInitializer
        );

        return
            createAuction(
                _nftId,
                _nftContract,
                _payee,
                _auctionDuration,
                _minimumPrice,
                royalty.royaltyReceiver,
                royalty.royaltyPercent,
                false
            );
    }

    /**
        This call let the royalty initializer of a (smart contract, nft) pair
        edit the royalty settings.

        NOTE: The maximum royalty that can be taken is 50%
        WARNING: Only ERC721 compliant NFTs can be sold, other standards are not supported

		@param _nftId The unique identifier of the NFT that is being sold
		@param _nftContract The address of the contract of the NFT
		@param _royaltyPercent The 18 decimals percentage of the highest bid that will be sent to 
                the royalty receiver
		@param _royaltyReceiver The address of the royalty receiver for a given auction
		@param _royaltyInitializer The address that will be allowed to edit the royalties, if the
                null address is provided sender address will be used
     */
    function updateRoyalty(
        uint256 _nftId,
        address _nftContract,
        uint256 _royaltyPercent,
        address _royaltyReceiver,
        address _royaltyInitializer
    ) public nonReentrant onlyERC721(_nftContract) returns (Royalty memory) {
        bytes32 royaltyIdentifier = keccak256(abi.encode(_nftContract, _nftId));

        Royalty memory royalty = royalties[royaltyIdentifier];

        require(
            msg.sender == royalty.royaltyInitializer,
            "You're not the owner of the royalty"
        );

        // Check that _royaltyPercent is less or equal to 50% of the sold amount
        require(
            _royaltyPercent <= 50 ether,
            "Royalty percentage too high, max value is 50%"
        );

        // if the royalty initializer is set to the null address automatically
        // use the caller address
        if (_royaltyInitializer == address(0)) {
            _royaltyInitializer = msg.sender;
        }

        royalties[royaltyIdentifier] = Royalty({
            decimals: 18,
            royaltyPercent: _royaltyPercent, // the provided value *MUST* be padded to 18 decimal positions
            royaltyReceiver: _royaltyReceiver,
            royaltyInitializer: _royaltyInitializer
        });

        emit RoyaltyUpdated(
            _nftId,
            _nftContract,
            _royaltyPercent,
            _royaltyReceiver,
            _royaltyInitializer
        );

        return royalties[royaltyIdentifier];
    }

    function createBlindAuction(
        uint256 _nftId,
        address _nftContract,
        address _payee,
        uint256 _auctionDuration,
        uint256 _minimumPrice,
        uint256 _royaltyPercent,
        address _royaltyReceiver,
        address _royaltyInitializer
    ) public nonReentrant onlyERC721(_nftContract) returns (address) {
        // load the instance of the nft contract into the ERC721 interface in order
        // to expose all its methods
        ERC721 nftContractInstance = ERC721(_nftContract);

        // check that the marketplace is allowed to transfer the provided nft
        // for the user
        // ALERT: checking the approval does not check that the user actually owns the nft
        // as parameters can per forged to pass this check without the caller to actually
        // own the it. This won"t be a problem in a standard context but as we"re setting
        // up the royalty base here a check must be done in order to check if it is should be
        // set by the caller or not
        require(
            nftContractInstance.getApproved(_nftId) == address(this),
            "Trasfer not allowed for Marketplace operator"
        );

        // check if the caller is the owner of the nft in case it is then proceed with further setup
        require(
            nftContractInstance.ownerOf(_nftId) == msg.sender,
            "Not owning the provided NFT"
        );
        Royalty memory royalty = initializeRoyalty(
            _nftId,
            _nftContract,
            _royaltyPercent,
            _royaltyReceiver,
            _royaltyInitializer
        );

        return
            createAuction(
                _nftId,
                _nftContract,
                _payee,
                _auctionDuration,
                _minimumPrice,
                royalty.royaltyReceiver,
                royalty.royaltyPercent,
                true
            );
    }
}


// File contracts/Masterchef.sol


pragma solidity 0.8.11;





contract Masterchef is ERC721Holder, ReentrancyGuard {
    StackingPanda public stackingPanda;
    PRNG public prng;
    Marketplace public marketplace;

    uint256 public mintingEpoch = 7 days;
    uint256 public lastMintingEvent;

    address public DoIncMultisigWallet =
        0x01Af10f1343C05855955418bb99302A6CF71aCB8;

    struct PandaIdentification {
        string name;
        string url;
    }

    PandaIdentification[] public pandas;

    event StackingPandaMinted(uint256 id);
    event StackingPandaForSale(address auction, uint256 id);

	bool initializedMelodityDao;

    /**
     * Network: Binance Smart Chain (BSC)     
     * Melodity Bep20: 0x13E971De9181eeF7A4aEAEAA67552A6a4cc54f43

	 * Network: Binance Smart Chain TESTNET (BSC)     
     * Melodity Bep20: 0x5EaA8Be0ebe73C0B6AdA8946f136B86b92128c55
     */
    constructor() {
        _deployPRNG();
        _deployStackingPandas(address(prng));
        _deployMarketplace(address(prng));
    }

    /**
        Deploy stacking pandas NFT contract, deploying this contract let only the
        Masterchef itself mint new NFTs
     */
    function _deployStackingPandas(address _prng) private {
        stackingPanda = new StackingPanda(_prng);
    }

    /**
        Deploy the Pseudo Random Number Generator using the create2 method,
        this gives the possibility for other generated smart contract to compute the
        PRNG address and call it
     */
    function _deployPRNG() private {
        prng = new PRNG();
    }

    /**
        Deploy the Marketplace using the create2 method,
        this gives the possibility for other generated smart contract to compute the
        PRNG address and call it
     */
    function _deployMarketplace(address _prng) private {
        marketplace = new Marketplace(_prng);
    }

    /**
        Trigger the minting of a new stacking panda, this function is publicly callable
        as the minted NFT will be given to the Masterchef contract.
     */
    function mintStackingPanda() public nonReentrant returns (address) {
        prng.rotate();

        // check that a new panda can be minted
        require(
            block.timestamp >= lastMintingEvent + mintingEpoch,
            "New pandas can be minted only once every 7 days"
        );

        // immediately update the last minting event in order to avoid reetracy
        lastMintingEvent = block.timestamp;

        // retrieve the random number and set the bonus percentage using 18 decimals.
        // NOTE: the maximum percentage here is 7.499999999999999999%
        uint256 meld2meldBonus = prng.rotate() % 7.5 ether;

        // retrieve the random number and set the bonus percentage using 18 decimals.
        // NOTE: the maximum percentage here is 3.999999999999999999%
        uint256 toMeldBonus = prng.rotate() % 4 ether;

        // mint the panda using its name-url from the stored pair and randomly compute the bonuses
        uint256 pandaId = stackingPanda.mint(
            "test",
            "url",
            StackingPanda.StackingBonus({
                decimals: 18,
                meldToMeld: meld2meldBonus,
                toMeld: toMeldBonus
            })
        );

        emit StackingPandaMinted(pandaId);

        return _listForSale(pandaId);
    }

    function _listForSale(uint256 _pandaId) private returns (address) {
        // approve the marketplace to create and start the auction
        stackingPanda.approve(address(marketplace), _pandaId);

        address auction = marketplace.createAuctionWithRoyalties(
            _pandaId,
            address(stackingPanda),
            // Melodity's multisig wallet address
            DoIncMultisigWallet,
            7 days,
            0.1 ether,
            1 ether,
            DoIncMultisigWallet,
            DoIncMultisigWallet
        );

        emit StackingPandaForSale(auction, _pandaId);
        return auction;
    }
}