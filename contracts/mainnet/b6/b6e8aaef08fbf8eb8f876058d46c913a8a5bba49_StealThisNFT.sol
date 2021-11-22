/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



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

// File: @openzeppelin/contracts/utils/Strings.sol



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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol



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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol



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

// File: @openzeppelin/contracts/access/IAccessControl.sol



pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/access/AccessControl.sol



pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/StealThisNFT.sol


pragma solidity 0.8.9;





contract StealThisNFT is
    ERC721,
    ERC721Enumerable,
    AccessControl,
    ReentrancyGuard
{
    address payable private constant ADMIN_ADDR =
        payable(0x2018Da50d1b3A102CA990ccEfe7DfDdb957Fe5A3);
    address payable private constant ADMIN_ADDR_2 =
        payable(0x2560d2dF9813c82b160323268453a52fBe428898);

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private constant TOKEN_ID = 1;
    string[4] private MESSAGE = ["", "", "", ""];

    uint256 public CEIL_PRICE = 1000000000000000000000; // 1000 ETH
    uint256 public LAST_PRICE = 0;
    uint256 public MIN_PRICE_INCREASE = 4; // 4 wei, needed for correct math
    uint256 public TIMES_STOLEN = 0;

    constructor() ERC721("StealThisNFT", "STLN") {
        _setupRole(MINTER_ROLE, ADMIN_ADDR);
    }

    function safeMint() public onlyRole(MINTER_ROLE) {
        _safeMint(_msgSender(), TOKEN_ID);
    }

    function steal(string[4] memory message) public payable {
        require(LAST_PRICE < CEIL_PRICE, "Ceiling price reached.");
        require(msg.value > LAST_PRICE, "Offer lower than last price.");
        require(msg.value >= LAST_PRICE + MIN_PRICE_INCREASE, "Offer too low.");
        require(message.length == 4, "Malformed input data.");

        address payable previousOwner = payable(ownerOf(TOKEN_ID));

        uint256 left_value = msg.value - LAST_PRICE;
        uint256 admin_share = left_value / 4;

        (bool success, ) = ADMIN_ADDR.call{value: admin_share}("");
        require(success);
        left_value = left_value - admin_share;

        (success, ) = ADMIN_ADDR_2.call{value: admin_share}("");
        require(success);
        left_value = left_value - admin_share;

        (success, ) = previousOwner.call{value: LAST_PRICE + left_value}("");
        require(success);

        _burn(TOKEN_ID);
        _safeMint(_msgSender(), TOKEN_ID);

        MESSAGE = message;
        LAST_PRICE = msg.value;
        TIMES_STOLEN++;
    }

    function buildTokenURI() private view returns (string memory) {
        string
            memory svg_part_0 = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 540 540" fill-rule="evenodd" stroke-linejoin="bevel" stroke-miterlimit="1.5"><style type="text/css">@import url("https://fonts.googleapis.com/css2?family=Rubik+Mono+One");</style><style>.B{stroke-linejoin:round}.C{stroke:#404040}.D{font-family:RubikMonoOne-Regular,Rubik Mono One}.E{fill:#393939}.F{fill:#c6c6c6}.G{fill:#737373}.H{fill:#1c1c1c}.I{stroke:#595959}.J{font-size:20px;white-space:pre}.K{fill:#2c2c2c}.L{font-size:13px}.M{font-size:12px}@font-face{font-family:"RubikMonoOne-Regular";src:url(data:application/font-woff;charset=utf-8;base64,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) format("woff2");font-weight:400;font-style:normal}</style><path d="M0 0h540v540H0z" fill-opacity=".8"/><clipPath id="A"><path d="M0 0h540v540H0z"/></clipPath><g clip-path="url(#A)"><path d="M0 0h540v540H0z" fill="url(#B)"/><g class="H"><path d="M81.5 448.5V540h64v-59.5l-64-32z" class="I"/><path d="M0 439.8v32l49.5 24.7v-32L0 439.7z" class="B C"/></g><path d="M305.5 272.5v32l32 16v-32l-32-16zm32 144 96-48V540l-96 .5v-124z" class="E B C"/><g class="K B C"><path d="m241.5 432.5-64 32 32 16 32-16 64 32 96-48-64-32 96-48 64 32 42.5-21.3v-64l-74.5 37.3-32-16-96 48-64-32 64-32-32-16-128 64 64 32v32z"/><path d="m337.5 352.5 96-48 32 16 96-48-96-48-32 16-32-16-96 48 32 16-64 32 64 32zm-64 64-128-64-64 32-31.8-15.9L0 393.2v46.6l49.5 24.7 32-16 64 32 128-64z"/></g><path d="m497.5 400.5 74.5-37.3v128l-74.5 37.3v-128z" class="B C E"/><path d="M241.5 464.5V540l64 .5v-44l-64-32zm192-96V540h64V400.5l-64-32z" class="H B C"/><path d="m145.5 480.5 128-64v32l-32 16v76l-96-.5v-59.5z" class="B C E"/><path d="M433.5 304.5v32l32 16v-32l-32-16z" class="B C H"/><path d="m337.5 352.5 96-48v32l-96 48v-32z" class="B C E"/><path d="M273.5 320.5v32l64 32v-32l-64-32z" class="B C H"/><path d="M401.5 540h-96v-43.5l96-48V540z" class="B C E"/><g class="I B"><path d="M98.4 408.7c0-1.4 1.1-2.9 3.3-4a19.8 19.8 0 0 1 15.8-.1c2.3 1.1 3.3 2.7 3.1 4.2v8c-.2 1.3-1.3 2.6-3.3 3.6a19.8 19.8 0 0 1-15.8.2c-2-1-3.1-2.5-3.1-3.9v-8z" fill="url(#C)"/><path d="M101.8 404.7c4.4-2.2 11.4-2.3 15.7-.1s4.2 5.6-.3 7.8-11.4 2.3-15.7.2-4.2-5.7.3-8z" fill="#595959"/><path d="M101 338c-.1-1.1.7-2.3 2.5-3.3 3.3-1.6 8.7-1.6 12 0 1.8 1 2.6 2.2 2.5 3.4v68.6c0 1.1-.8 2.2-2.5 3a15.1 15.1 0 0 1-12 0c-1.7-.8-2.5-2-2.5-3V338z" fill="url(#D)"/><path d="M392 262c0-1.5 1.2-3 3.4-4.1a19.9 19.9 0 0 1 15.8-.2c2.2 1.2 3.3 2.7 3 4.3v7.2c.1.2.1.5 0 .8-.1 1.3-1.2 2.6-3.3 3.6a19.8 19.8 0 0 1-15.7.1c-2.1-1-3.2-2.4-3.2-3.8v-8z" fill="url(#E)"/><path d="M395.4 257.9c4.4-2.2 11.5-2.3 15.8-.2s4.1 5.7-.3 8-11.5 2.2-15.7 0-4.2-5.6.2-7.8z" fill="#595959"/><path d="M394.7 191.2c-.2-1.2.6-2.4 2.5-3.3 3.3-1.6 8.6-1.6 12 0 1.8 1 2.6 2.1 2.4 3.3V260c0 1.1-.8 2.2-2.4 3a15.1 15.1 0 0 1-12 0c-1.8-.8-2.6-2-2.5-3.1v-68.6z" fill="url(#F)"/><path d="m409.5 28.5-320 160 15.5 8 320.6-160-16.1-8z" class="F"/><path d="M89.5 348.5v-160l15.5 8v159.6l-15.5-7.6z" class="G"/><g fill="#fff"><path d="M425.6 36.5 105.2 196.1l-.2 160 320.4-159.5.2-160z"/><path d="M416.1 52.5 114.6 202.6l-.1 137.4L416 190l.1-137.4z"/></g><path d="m416.1 190-5.8-3 .3-131.8 5.5-2.7V190z" class="G"/><path d="m114.5 334.7 295.8-147.6 5.8 2.9-301.6 150v-5.3z" class="F"/></g><text x="117.8" y="225.2" transform="rotate(-26.5 67.7 -9.8) skewX(-26.3)" class="D J T0">';

        string
            memory svg_part_1 = '</text><text x="118" y="257.1" transform="rotate(-26.5 60 -11.3) skewX(-26.3)" class="D J T1">';

        string
            memory svg_part_2 = '</text><text x="118.1" y="289" transform="rotate(-26.5 52.2 -12.9) skewX(-26.3)" class="D J T2">';

        string
            memory svg_part_3 = '</text><text x="118.2" y="320.9" transform="rotate(-26.5 44.4 -14.4) skewX(-26.3)" class="D J T3">';

        string
            memory svg_part_4 = '</text><g class="B I"><path d="M-21.3 40 93 97l43-21.5L21.7 18.4l-43 21.5z" class="F"/><path d="M-27 37.1v29.6l120 60V97.1l-120-60z" class="G"/><path d="M136.1 75.6v29.6l-43 21.5V97.1l43-21.5z" fill="#fff"/></g><text x="100" y="115.1" transform="matrix(.89443 -.44721 0 1.11803 9.8 30.2)" class="D L">NFT</text><g class="B I"><path d="M-59.8-15.7 54.6 41.5 111 13.3-3.3-44l-56.5 28.2z" class="F"/><path d="M-65.4-18.5v29.7l120 60V41.5l-120-60z" class="G"/><path d="M111 13.3v29.6L54.7 71.2V41.5L111 13.3z" fill="#fff"/></g><text x="57.8" y="59.2" transform="matrix(.89443 -.44721 0 1.11803 5.8 19.8)" class="D L">STEAL</text><g class="B I"><path d="M-87 40.6 27.2 97.8l48.4-24.2-114.4-57.2-48.4 24.2z" class="F"/><path d="M-92.7 37.8v29.6l120 60V97.8l-120-60z" class="G"/><path d="M75.7 73.6v29.6l-48.4 24.2V97.8l48.4-24.2z" fill="#fff"/></g><text x="31.5" y="115.8" transform="matrix(.89443 -.44721 0 1.11803 2.9 .7)" class="D L">THIS</text><g class="B C"><path d="M0 521.3v-49.5l49.5 24.7L0 521.3z" class="K"/><path d="M465.5 352.5v-32l74.5-37.3v32l-74.5 37.3z" class="E"/><path d="m457.5 540.5-56-28 96-48 42.5 21.3V540l-82.5.5z" class="K"/><path d="m474.1 488.5 23-11.8 22.8 11.8-22.9 11.8-22.9-11.8z" class="F"/><path d="m474.1 512.1 23 11.8v-23.6l-23-11.8v23.6z" class="G"/><path d="M519.9 512.1 497 524v-23.6l22.9-11.8v23.6z" fill="#fff"/></g><text x="501.2" y="467.9" transform="matrix(.86128 -.44579 -.00255 1.12733 69.3 211.5)" class="D M">SC</text><text x="483.4" y="457.2" transform="matrix(.86142 .44551 -.00255 1.12451 66 -220.6)" class="D M">B</text><text x="911.8" y="654.9" transform="matrix(.86142 .44551 -1.09546 .55927 420.3 -283.9)" class="D M">H</text><g class="B C"><path d="M49.5 464.5v32L0 521.3V540h81.5v-91.5l-32 16z" class="E"/><path d="M401.5 512.5V540h55l-55-27.5z" class="H"/></g></g><defs><linearGradient id="B" x1="13.5" y1="-1.5" x2="573.5" y2="278.5" xlink:href="#G"><stop offset="0" stop-color="#7471d9"/><stop offset="1" stop-color="#80f2c9"/></linearGradient><linearGradient id="C" x1="98.4" y1="416" x2="109.5" y2="416" xlink:href="#G"><stop offset="0" stop-color="#161616"/><stop offset="1" stop-color="#5e5e5e"/></linearGradient><linearGradient id="D" x1="109.5" y1="373.7" x2="101" y2="373.7" xlink:href="#G"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#b3b3b3"/></linearGradient><linearGradient id="E" x1="392" y1="269.2" x2="403.2" y2="269.2" xlink:href="#G"><stop offset="0" stop-color="#161616"/><stop offset="1" stop-color="#5e5e5e"/></linearGradient><linearGradient id="F" x1="403.2" y1="226.9" x2="394.7" y2="226.9" xlink:href="#G"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#b3b3b3"/></linearGradient><linearGradient id="G" gradientUnits="userSpaceOnUse"/></defs></svg>';

        bytes memory data;

        data = abi.encodePacked(
            svg_part_0,
            MESSAGE[0],
            svg_part_1,
            MESSAGE[1],
            svg_part_2,
            MESSAGE[2],
            svg_part_3,
            MESSAGE[3],
            svg_part_4
        );

        string memory json_data = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "#1", "description": "Steal me while you can.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(string(data))),
                        '"}'
                    )
                )
            )
        );

        string memory uri = string(
            abi.encodePacked("data:application/json;base64,", json_data)
        );
        return uri;
    }

    function getMessage() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    MESSAGE[0],
                    "\n",
                    MESSAGE[1],
                    "\n",
                    MESSAGE[2],
                    "\n",
                    MESSAGE[3]
                )
            );
    }

    function totalSupply() public view virtual override returns (uint256) {
        return 1;
    }

    function contractURI() public pure returns (string memory) {
        return
            "https://stealthisnft.io/opensea-metadata.json";
    }

    // TODO remove from prod build
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        super.tokenURI(tokenId);
        return buildTokenURI();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}