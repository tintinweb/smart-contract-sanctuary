/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

// SPDX-License-Identifier: GPL-3.0-only

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

    constructor () {
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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

// File: @openzeppelin/contracts/utils/Context.sol


pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

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
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// File: contracts/ContextMixin.sol

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// File: contracts/SharedOwnership.sol

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";



/// @title Shared Ownership
/// @author Mathieu Lecoq
/// @notice Allows multiple addresses to share ownership of the contract
/// owners are able to transfer their ownership and renounce to it
contract SharedOwnership is ContextMixin {

    /// @dev Storage of MADE token owners
    address[] internal owners;

    address internal standardOwner;

    /// @dev Storage ownership transfers, current_owner => future_owner => relinquishment_token 
    mapping(address => mapping(address => bytes32)) internal relinquishmentTokens;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address[] memory _owners) {
        owners = _owners;
    }

    /// @dev forbidden zero address check
    modifier validAddress(address addr) {
        require(addr != address(0), 'invalid address');
        _;
    }

    /// @dev owner right check
    modifier onlyOwner() {
        require(isOwner(msgSender()), 'access denied');
        _;
    }

    /// @dev check if an address is one of the owners
    function isOwner(address addr) public view returns(bool isOwnerAddr) {
        for (uint i = 0; i < owners.length; i++) {
            if (address(owners[i]) == address(addr)) 
            isOwnerAddr = true;
        }
    }

    /// @dev internally add a new owner to `owners`
    function addOwner(address _owner) internal validAddress(_owner) {
        owners.push(_owner);
    }

    /// @dev internally remove an owner from `owners`
    function removeOwner(address _owner) internal validAddress(_owner) {
        require(isOwner(_owner), 'address is not an owner');

        uint afterLength = (owners.length - 1);

        for (uint ownerIndex = 0; ownerIndex < owners.length; ownerIndex++) {
            if (address(owners[ownerIndex]) == address(_owner)) {
                if (ownerIndex >= owners.length) return;

                for (uint i = ownerIndex; i < owners.length-1; i++){
                    owners[i] = owners[i+1];
                }

                owners.pop();
            }
        }

        require(owners.length == afterLength, 'owner can not be removed');

    }


    /// @dev Allows any current owner to relinquish its part of control over the contract
    /// @notice the calling contract owner must call this method to get the `relinquishmentToken` 
    /// prior calling `renounceOwnership` method and definitively loose his ownership
    /// @param _newOwner address of the futur new owner
    /// @return _relinquishmentToken bytes32 ownership transfer key for msg.sender => _newOwner
    function preTransferOwnership(address _newOwner) public onlyOwner returns(bytes32 _relinquishmentToken) {
        address stillOwner = msgSender();
        uint salt = uint(keccak256(abi.encodePacked(block.timestamp, stillOwner)));
        bytes32 _rToken = bytes32(salt);
        relinquishmentTokens[stillOwner][_newOwner] = _rToken;
        _relinquishmentToken = _rToken;
    }

    /// @dev Retrieve the ownership transfer key preset by a current owner to a new owner
    /// preTransferOwnership method must be called prior to calling this method
    function getRelinquishmentToken(address _newOwner) public onlyOwner view returns (bytes32 _rToken) {
        _rToken = relinquishmentTokens[msgSender()][_newOwner];
    }

    /// IRREVERSIBLE ACTION
    /// @dev Allows any current owner to definitively and safely relinquish its part of control over the contract to a new address
    function transferOwnership(bytes32 _relinquishmentToken, address _newOwner) public onlyOwner {
        address previousOwner = msgSender();
        bytes32 rToken = relinquishmentTokens[previousOwner][_newOwner];
        
        // make sure provided _relinquishmentToken matchs sender storage for _newOwner
        require(
            ((rToken != bytes32(0)) && (rToken == _relinquishmentToken)), 
            'denied : a relinquishment token must be pre-set calling the preTransferOwnership method'
        );

        // transfer contract ownership
        removeOwner(previousOwner);
        addOwner(_newOwner);

        // remove relinquishment token from storage
        relinquishmentTokens[previousOwner][_newOwner] = bytes32(0);

        emit OwnershipTransferred(previousOwner, _newOwner);

    }

    function setStandardOwner(address stdOwner) public onlyOwner {
        require(isOwner(stdOwner), 'standard owner must be a an owner');
        standardOwner = stdOwner;
    }

    /// @notice Returns one of :
    ///     - one of owners address precedently set as `standardOwner` by one of the owners
    ///     - the first indexed owner
    /// @dev Mock for OpenZeppelin Ownable.owner method
    function owner() public view returns(address stdOwner) {
        return(
            address(standardOwner) != address(0)
            ? standardOwner
            : owners[0]
        );
    }

    
    
}

// File: contracts/OpenSeaERC721Metadatas.sol

pragma solidity ^0.8.0;




abstract contract OpenSeaERC721Metadatas is ERC721, SharedOwnership {
    using Strings for string;

    string _baseTokenURI;

    event BaseTokenUriUpdated(string uri); 

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory ba = bytes(ab);
        uint k = 0;

        for (uint i = 0; i < _ba.length; i++) ba[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) ba[k++] = _bb[i];
        
        return string(ba);
    }

    function _baseURI() internal override view returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
    * @dev Retrieve all NFTs base token uri 
    */
    function baseTokenURI() public view returns (string memory) {
        return _baseURI();
    }

    /**
    * @dev Set the base token uri for all NFTs
    */
    function setBaseTokenURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
        emit BaseTokenUriUpdated(uri);
    }

    /**
    * @dev Retrieve the uri of a specific token 
    * @param _tokenId the id of the token to retrieve the uri of
    * @return computed uri string pointing to a specific _tokenId
    */
    function tokenURI(uint256 _tokenId) public override view returns (string memory) {
        return strConcat(
            baseTokenURI(),
            Strings.toString(_tokenId)
        );
    }

    

}

// File: contracts/PIXSMarket.sol

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";



/**                        
 * @title PIXSMarket
 * @author Mathieu L
 * @dev Established on JUNE 23rd, 2021    
 * @dev Deployed with solc version 0.8.4
 * @dev Contact us at [email protected]                                  
*/
contract PIXSMarket is OpenSeaERC721Metadatas, ReentrancyGuard {

    struct Offer {
        address offerer;
        uint amount;
        uint timestamp;
    }

    /// @notice token Id => sale price
    mapping (uint => uint) public salePrices;

    /// @notice token Id => owner => buyer => price
    mapping (uint => mapping(address => mapping(address => uint))) public privateSalePrices;

    /// @notice token ID => offers
    mapping(uint => Offer[]) internal offers;

    function getOffers(uint _tokenId) public view returns(Offer[] memory tokenOffers) {
        return offers[_tokenId];
    }

    /// @dev Check that caller is owner of a spacific token
    function onlyOwnerOf(uint tokenId) internal view returns(address tokenOwner) {
        address tOwner = ownerOf(tokenId);
        require(address(tOwner) == address(_msgSender()), 'denied : token not owned');
        tokenOwner = tOwner;
    }

    constructor(address[] memory _owners) ERC721('Pixsale', 'PIXS') SharedOwnership(_owners) {}
    
    /// @dev Allows holders to sell their PIXS at chosen price to anyone
    function sell(uint _tokenId, uint _amount) public {
        onlyOwnerOf(_tokenId);
        salePrices[_tokenId] = _amount;
    }

    /// @dev Allows holders to sell their PIXS at chosen price to a specific address
    function privateSellTo(uint _tokenId, uint _amount, address _buyer) public {
        address tokenOwner = onlyOwnerOf(_tokenId);
        privateSalePrices[_tokenId][tokenOwner][_buyer] = _amount;
    }

    /// @dev Remove a token from public sale or remove a private buyer from approved private buyers
    /// @param _tokenId token Id to remove from sale OR to remove `_optBuyer` from sale
    /// @param _optBuyer *optional* if a valid buyer address is provided, 
    /// the buyer will be removed from allowedBuyers
    function removeFromSale(uint _tokenId, address _optBuyer) public {
        address tokenOwner = onlyOwnerOf(_tokenId);

        if (
            (address(_optBuyer) != address(0))
            && privateSalePrices[_tokenId][tokenOwner][_optBuyer] != 0
        ) {
            privateSalePrices[_tokenId][tokenOwner][_optBuyer] = 0;
        }
        else if(salePrices[_tokenId] != 0) {
            salePrices[_tokenId] = 0;
        }
    }

    function _getTokenPrice(uint _tokenId, address _tokenOwner, address _sender) internal view returns(uint tokenPrice) {

        uint pubSale = salePrices[_tokenId];
        uint privateSale = privateSalePrices[_tokenId][_tokenOwner][_sender];

        bool isPrivateSale = privateSale > 0;

        tokenPrice = (
            (isPrivateSale)
            ? privateSale
            : pubSale
        );
    }

    function getTokenPrice(uint _tokenId, address _sender) public view returns(uint tokenPrice) {
        address _tokenOwner = ownerOf(_tokenId);
        tokenPrice = _getTokenPrice(_tokenId, _tokenOwner, _sender);
    }

    /// @dev Allow users to propose a price for the purchase of a token that is or not for sale
    /// @param _tokenId Token targeted by sender
    /// @param _amount amount in MATIC that sender proposes to buy the token
    function makeOffer(uint _tokenId, uint _amount) external {
        offers[_tokenId].push(Offer(_msgSender(), _amount, block.timestamp));
    }




}

// File: contracts/Pixsale.sol

pragma solidity ^0.8.0;


/**                 
 *      ▌ ▘ ▀ ▗ ▜    ▐    ▀       ▀    ▀ ▀▀▀ ▀ ▀        ▀       ▒           ▀ ▀ ▘▀ ▀ 
 *      ▀       ▓          ▀     ▀     ▒              ▀   ▚     ▀           ▓
 *      ▙ ▀ ▀▝▐ ▀    ▀       ▚ ▞       ▖ ▀ ▝ ▀ ▚    ▞      ▀    ░           ▀ ▂ ▂ ▂         
 *      ▀            ▀       ▞ ▚               ▀    ▀ ▀ ▔ ▀ ▟   ▆           ▀▝▝ ▀ ▀  
 *      ▀            ▓      ▀   ▀              ▀    ░       ▀   ▀           ▀
 *      ░            ▀    ▘       ▚    ▘ ▀ ▀ ▀▀▀    ▟       ▀   ▆ ▍▀▀ ▀ ▘   ▙ ▀ ▀ ▀ ▞ 
 *                                                          ▔
 *      VISIT HTTPS://PIXSALE.IO
 *      JOIN THE MAP !
 *             
 * @title Pixsale
 * @author Mathieu L
 * @dev Established on JUNE 23rd, 2021    
 * @dev Deployed with solc version 0.8.4
 * @dev Contact us at [email protected]                                  
*/                       
contract Pixsale is PIXSMarket {
    using Address for address payable;

    /// @notice PIXS token properties
    struct PIXS {
        /// address of owner
        address owner; 
        /// total number of pixels used
        uint pixels;
        /// position of the image fetched at `link` : left, top, right, bottom
        uint[] coords;       
        /// url address pointing to an image
        string image;
        /// url pointing to a website
        string link;
        /// title and description - format must contains a coma(,) 
        /// ex.:  My Project, catch phrase for my project
        string titledDescription;
    }

    /// @notice Token ids counter
    uint internal lastTokenId;

    /// @notice Date of birth of the smart-contract
    uint public birthTime;

    /// @notice Minimum pixel amount to purchase
    /// @dev PIXS tokens minimum pixels amount must be greater or equal 5px
    /// @dev value is immutable and can not be changed
    uint public immutable minimumPixelsAmount = 25;

    /// @notice Minimum pixel length
    /// @dev PIXS tokens widths and heights must be greater or equal 5px
    /// @dev value is immutable and can not be changed
    uint public immutable minimumPixelsLength = 5;
    
    /// @notice Total supply of available pixels
    uint public totalPixels = 8294400;
    
    /// @notice MATIC price 0.4 MATIC / pixel
    uint public immutable pixelPrice = 400000000000000000;

    /// @notice Total Reflection to distribute among all holders prorata to the ratio totalPixels / balance
    uint public totalReflection;

    /// @notice Total received value dedicated to communication / marketing 
    uint public totalCom;

    /// @notice Total that has been withdrawn by marketing partner
    uint public totalComWithdrawn;

    /// @notice Total received value dedicated to final auction of the artwork
    uint public totalAuction;

    /// @notice Total that has been withdrawn from auction part
    uint public totalAuctionWithdrawn;

    /// @notice Total amount of pixels reserved to team members
    uint public teamPixelsSupply;

    /// @notice Total amount of pixels owners have gaveaway
    uint public totalPixelsGaveway;

    /// @notice Reflection release date
    uint public reflectionReleaseTimestamp;

    /// @notice Communication / Marketing partner wallet
    address public comWallet;

    /// @notice Track reflection withdraws
    /// @dev tokenId => boolean
    mapping (uint => bool) public reflectionWithdrawn;

    /// @notice Total number of pixels held from a giveaway
    mapping(address => uint) public pixelsBalance;

    /// @notice Signature for agreement between owners to abandon the project and release the reflection
    /// @dev Settable from one year after contract deployment
    mapping (address => bool) internal abandonOwnersSignatures;

    /// @notice all PIXS tokens
    PIXS[] public pixs;


    event Refunded(address indexed orderer, uint refundAmount);
    event ReflectionIsReleased();

    /// @dev Pixsale construction
    /// @param _owners : array of 2 addresses for shared ownership
    constructor(
        address[] memory _owners, 
        string memory baseTokenURI
    ) PIXSMarket(_owners) {

        // set base token uri
        _baseTokenURI = baseTokenURI;

        // reserve team pixels part
        teamPixelsSupply = 294400;

        // set contract birth date
        birthTime = block.timestamp;
    }

    modifier reflectionIsReleased() {
        require(
            reflectionReleased(),
            'reflection must be released'
        );
        _;
    }

    /**
    * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    */
    function isApprovedForAll(
        address owner,
        address operator
    )
    public override
    view
    returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if (address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE) == operator) {
            return true;
        }
        return ERC721.isApprovedForAll(owner, operator);
    }

    function setComWallet(address _comAccount) public onlyOwner {
        comWallet = _comAccount;
    }

    function totalComAvailable() public view returns(uint ttlComAvail) {
        ttlComAvail = totalCom - totalComWithdrawn;
    }

    /// @notice Allow owners to withdraw the allocation of 1% dedicated to final artwork auction
    /// @notice funds are handled by owners in order to be able to pay the chosen art gallery with fiat
    function auctionWithdraw() public onlyOwner reflectionIsReleased {
        uint availableAuctionPart = totalAuction - totalAuctionWithdrawn;
        require(availableAuctionPart > 0, 'currently there is no available funds dedicated to final auction');

        totalAuctionWithdrawn += availableAuctionPart;
        payable(_msgSender()).sendValue(availableAuctionPart);
    }

    /// @notice Allow marketing/com partner to withdraw its allocation of 5%
    function comPartnerWithdraw(uint _amount) public {
        address sender = _msgSender();
        require(address(sender) == address(comWallet), 'reserved to marketing partner');
        require(_amount <= totalComAvailable(), 'not enough funds available for marketing');

        totalComWithdrawn += _amount;
        payable(address(comWallet)).sendValue(_amount);

    }

    /// @dev Returns the total amount of pixels that owners have gaveaway
    function availableGivewayPixels() public view returns(uint aGiveawayPixels) {
        aGiveawayPixels = (teamPixelsSupply - totalPixelsGaveway);
    }

    /// @dev Transfer pixels from owner
    function _giveawayPixelsFromOwner(uint amount, address account) internal returns(bool trfFromOwner) {

        require(
            amount <= availableGivewayPixels(), 
            'pixels transfer from owner denied : owner pixels balance too low'
        );

        totalPixelsGaveway += amount;
        pixelsBalance[account] += amount;
        
        return true;
    }

    /// @dev Transfer pixels for non-owners
    function _transferPixels(uint amount, address account) internal returns(bool pixelsTrf) {
        address sender = _msgSender();
        
        require(pixelsBalance[sender] >= amount, 'pixels transfer denied : pixels balance too low');
        
        pixelsBalance[sender] -= amount;
        pixelsBalance[account] += amount;

        return true;
    }

    /// @dev Pixels holders can transfer pixels
    function transferPixels(uint amount, address account) public {
        

        // transfer pixels
        bool trf = isOwner(_msgSender())
        ? _giveawayPixelsFromOwner(amount, account)
        : _transferPixels(amount, account);

        require(trf, 'pixels transfer failed');
    }
    
    /// @dev Get the next available tokenId
    function nextId() internal view returns(uint nId) {
        nId = lastTokenId + 1;
    }

    /// @dev Get a fraction of a number from a percentage value (0-100)
    function fraction(uint amount, uint _percentage) internal pure returns(uint per) {
        require(_percentage < 100, 'bad fraction percentage');
        per = (amount / 100) * _percentage;
    }

    /// @dev Get one PIXS token from its id
    function getPixs(uint tokenId) public view returns(PIXS memory _pixs) {
        _pixs = pixs[tokenId-1];
    }

    /// @dev Get the total supply of PIXS NFT tokens
    function totalSupply() public view returns(uint tSupply) {
        tSupply = pixs.length;
    } 

    /// @dev Get the total number of PIXS token that have been sold / consumed
    function soldPixels() public view returns(uint totalPixelsSold) {
        uint totalSold;
        for (uint i = 0; i < pixs.length; i++) {
            // PIXS memory _pixs = pixs[i];
            totalSold += pixs[i].pixels;
        }
        totalPixelsSold = totalSold;
    }

    function availablePixels() public view returns(uint totalPixelsAvailable) {
        totalPixelsAvailable = totalPixels - teamPixelsSupply - soldPixels();
    }

    /// @dev Check that the number of `_pixels` equals the number of pixels computed from `_coords` values
    function consistentCoords(uint _pixels, uint[] memory _coords) internal pure {
        uint pixels = (
            (_coords[2] - _coords[0])
            * (_coords[3] - _coords[1])
        );

        require(pixels == _pixels, 'denied : coordinates pixels count must be equal to ordered pixels amount');

        // check that minimum amount of pixels is respected
        require(_pixels >= minimumPixelsAmount, 'minimum pixels amount to purchase must be greater or equal 25');
        // check that minimum amount of pixels on each length respects the preset `minimumPixelsLength`
        require(
            (
                ((_coords[2] - _coords[0]) >= minimumPixelsLength)
                && ((_coords[3] - _coords[1]) >= minimumPixelsLength)
            ),
            'denied : minimum coordinates length must be 5px'
        );
    }

    /// @dev Check pixels superposition with existing PIXS occupied space 
    function mapConflict(uint[] memory _coords) internal view {
        uint l = _coords[0]; 
        uint t = _coords[1]; 
        uint r = _coords[2]; 
        uint b = _coords[3];

        uint _limit = 5;

        // look for 4K map borders overflow (3840 x 2160 pixels) and check that space from nearest boundary is min 5 or 0
        require(
            (
                ((l == 0) || (l >= _limit)) 
                && ((t == 0) || (t >= _limit)) 
                && (
                    r >= _limit
                    && ((r == 3840) || (r <= (3840-_limit)))
                )
                && (
                    b >= _limit
                    && ((b == 2160) || (b <= (2160-_limit)))
                )
            ),
            'map borders overflow or not enough space of 5px'
        );

        // check that there is no conflict with existing coordinates
        uint i;
        for (i = 0; i < pixs.length; i++) {

            // PIXS memory _pixs = pixs[i];
            uint[] memory eCoords = pixs[i].coords;

            bool isOnLimit = (
                (l == (eCoords[2]-_limit)) 
                || (r == (eCoords[0]+_limit))
                || (t == (eCoords[3]-_limit))
                || (b == (eCoords[1]+_limit))
            );
            
            // check conflict on X axis
            bool xConflict = (
                (
                    isOnLimit 
                    ? false
                    : (
                        // L: left, R: right, n: new, e: existing
                        // nL < eL && nR > eL 
                        ((l < eCoords[0]) && (r > eCoords[0]))
                        // nR > eL && nL < eR
                        || ((r > eCoords[0]) && (l < eCoords[2]))     
                    )
                )
               
            );
            
            /// example :
            // EXISTING:       L    T   R    B
            //              [ 10, 20, 110, 120 ]
            // new:            l    t    r    b
            //              [ 10, 120, 110, 220 ]
            if (xConflict) {
                // and conflict on Y 
                bool yConflict = (
                    // T: top, B: bottom, n: new, e: existing
                    //     nT > eT && nB < eB
                    ((t > eCoords[1]) && ((b < eCoords[3])))
                    //  || nB > eT && nT < eB
                    || ((b > eCoords[1]) && (t < eCoords[3]))
                );

                require(!yConflict, 'denied : pixels position conflict');
            }
        }
    }

    /// @dev Spread NFT value according to the rules
    /// @notice Distribution is organised as follow :
    /// - 30% to owner 1
    /// - 30% to owner 2
    /// - 5% to com
    /// - 1% to final auction
    /// - 34% to total reflection distributed among holders according to Pixsale reflection rules (dont 4% pour la reflection influenceurs (giveway pixels))
    function spreadEthValue(uint _value) internal returns (bool trfok) {
        require(thisBalance() >= _value, 'contract balance too low to spread');

        uint onePerc = fraction(_value, 1);

        // to owners
        for (uint i = 0; i < 2; i++) {
            // to contract balance : use ownersWithdraw
            payable(address(owners[i])).sendValue((onePerc * 30));
        }

        // to reflection
        totalReflection += (onePerc * 34);

        // to com
        totalCom += (onePerc * 5);

        // to final auction
        totalAuction += onePerc;

        return true;

    }

    /// @notice mint a new PIXS NFT from ETH
    /// @dev consumes pixels from `totalPixels`
    /// @param _pixelsAmount is the amount of pixels sender wants to purchase
    /// @param _coords is an array of coordinates indicating where the pixels will be positioned on the map at https://pixsale.io
    /// @param _image is the url pointing to an image chosen by sender / owner
    /// @param _link is the url where users will be redirected when clicking on the to be consumed pixels
    /// @param _titledDescription is the text data associated with the PIXS token. it is formated this way :
    ///     title,(comma)description
    ///     ex. My Old Cars Project, collection cars dealer in Bruxelles, Belgium
    /// @param _owner address of the new created NFT holder/owner
    function _mintTo(
        uint _pixelsAmount, 
        uint[] memory _coords, 
        string memory _image, 
        string memory _link, 
        string memory _titledDescription, 
        address _owner
    ) internal validAddress(_owner) returns (uint _pixsId) {
        // check that there is enought available pixels
        // ISSUE HERE : ununsed giveway pixels will be locked after reflection release
        

        // check that _coords respects the number of requested pixels
        consistentCoords(_pixelsAmount, _coords);
        
        // check that space for `_coords` is available
        mapConflict(_coords);

        // check than sender has transferred enough value
        uint heldPixelsValue = pixelsBalance[_owner] * pixelPrice;

        uint purchaseEthPrice = pixelPrice * _pixelsAmount;

        uint priceToPay = (
            (heldPixelsValue >= purchaseEthPrice)
            ? 0
            : purchaseEthPrice - heldPixelsValue
        );

        require(
            (
                priceToPay > 0
                ? (
                    (priceToPay / pixelPrice) <= availablePixels()
                )
                : availablePixels() >= 25
            ),
            'Pixels sold out'
        );
        
        require(msg.value >= priceToPay, 'transferred eth value is too low to receive request amount of pixels');
       
        uint giveawayPixelsCost = (
            ((purchaseEthPrice - priceToPay) > 0)   // has pixels
            ? (
                // how many giveway pixels _owner will consume 
                (purchaseEthPrice - priceToPay) / pixelPrice
            )
            : 0
        );

        if (giveawayPixelsCost > 0) {
            // consume pixels
            pixelsBalance[_owner] -= giveawayPixelsCost;
        }

        PIXS memory _pixs = PIXS(_owner, _pixelsAmount, _coords, _image, _link, _titledDescription);

        if (spreadEthValue(priceToPay)) {

            uint tokenId = nextId();

            _mint(_owner, tokenId);

            // add to PIXS
            pixs.push(_pixs);

            // increment token ids
            lastTokenId++;

            // optionally refund 
            uint refund = msg.value - priceToPay;

            if (refund > 0) {
                payable(_msgSender()).transfer(refund);
                emit Refunded(_msgSender(), refund);
            }
            
            // release reflection
            if (allPixelsSold()) {
                releaseReflection();
            }

            // return the new created token id
            return(tokenId);
        }
    }

    /// @notice mint PIXS Pixsale NFT token to sender
    /// @dev see `_mintTo`
    function mint(
        uint _pixelsAmount, 
        uint[] memory _coords, 
        string memory _image, 
        string memory _link, 
        string memory _titledDescription
    ) public payable returns (uint pixsId) { 
        return _mintTo(_pixelsAmount, _coords, _image, _link, _titledDescription, _msgSender());
    }

    /// @notice mint PIXS Pixsale NFT token to a specific `owner` address
    /// @notice if any refund occurs, value goes back to sender (msg.sender) 
    /// @dev see `_mintTo`
    function mintTo(
        uint _pixelsAmount, 
        uint[] memory _coords, 
        string memory _image, 
        string memory _link, 
        string memory _titledDescription, 
        address _owner
    ) public payable returns (uint pixsIdTo) { 
        return _mintTo(_pixelsAmount, _coords, _image, _link, _titledDescription, _owner);
    }

    /// @dev Get the ether balance of the contract itself
    function thisBalance() public view returns(uint balance) {
        balance = payable(address(this)).balance;
    }

    /// @dev Get the total amount of pixels used by all PIXS tokens of an holder
    function pixelsOf(address _holder) public view returns (uint ownerPixels) {
        uint tPixs;

        for (uint i = 0; i < pixs.length; i++) {

            if (address(pixs[i].owner) == address(_holder)) {
                tPixs += pixs[i].pixels;
            }
        }

        ownerPixels = tPixs;
    }

    /// @dev Know weither or not holders can withdraw their part on total reflection 
    /// and owners can spend the allocation for the final artwork auction sale organization
    /// @dev Remaining space on `The Map` must be low enough not to be able to mint a new PIXS
    /// or project must have been abandoned by both owners
    function reflectionReleased() public view returns(bool released) {
        released = (
            allPixelsSold()
            || (reflectionReleaseTimestamp > 0)
        );
    }

    /// @notice Returns weither or not all pixels have been sold
    /// @dev minimum PIXS surface in pixels is 25
    function allPixelsSold() public view returns(bool noMorePixels) {
        noMorePixels = availablePixels() < 25;
    }

    /// @dev Get the reflection ether amount that an address is or will be able to withdraw 
    /// once 99.9997% of the pixels supply have been consumed
    function reflectionBalanceOf(address _holder) public view returns(uint rAmount) {
        return computeReflection(_holder);
    }

    /// @dev Returns the total prorata on total reflection for all PIXS
    function pixsProratas() internal view returns(uint totalProratas) {
        uint tPixs = pixs.length;
        uint _totalProratas;

        for (uint i = 0; i < tPixs; i++) {
            uint totalHoldersAfter = tPixs - i;
            uint prorata = (pixs[i].pixels * pixelPrice) * totalHoldersAfter;

            _totalProratas += prorata;
        }

        return _totalProratas;
    }

    /// @dev Simulate reflection calculation from pixels amount and tokenId (aka `position`)
    function simulateReflection(uint pixels, uint position) public view returns(uint pixelsReflection) {
        uint tPixs = pixs.length;
        uint multip = 1e18;
        uint totalHoldersAfter = tPixs - position;
        uint inflatedProrata = pixels * pixelPrice * totalHoldersAfter * multip;
        uint inflatedCoef = inflatedProrata / pixsProratas();
        
        return( (inflatedCoef * totalReflection) / multip );
    }

    /// @dev Compute reflection of a single token
    function tokenReflection(uint _tokenId) public view returns(uint tReflection) {
        if (reflectionWithdrawn[_tokenId]) 
            return 0;
        else {
            return simulateReflection(pixs[_tokenId-1].pixels, _tokenId-1);
        }
    }


    /// @dev Computes the reflection amount of a PIXS holder according to Pixsale reflection policy
    /// @notice Token with already withdrawn reflection are excluded from addition
    function computeReflection(address _holder) internal view returns(uint holderTotalReflectionBalance) {

        uint tPixs = pixs.length;
        uint multip = 1e18; 
        uint holderTotalRef = 0;

        uint totalProratas = pixsProratas();

        for (uint i = 0; i < tPixs; i++) {
            uint tokenId = i+1;
            
            if ((address(pixs[i].owner) == address(_holder)) && !reflectionWithdrawn[tokenId]) {
                uint totalHoldersAfter = tPixs - i;
                uint inflatedProrata = pixs[i].pixels * pixelPrice * totalHoldersAfter * multip;
                uint inflatedCoef = inflatedProrata / totalProratas;
                
                holderTotalRef += ( (inflatedCoef * totalReflection) / multip );

            }
        }

        return holderTotalRef;
            
    }

    /// @dev Computes the reflection tokens and 
    function setReflectionWithrawnForTokensOf(address _holder) internal returns(uint balCheck, uint pixelsCheck) {
        uint hBalanceCheck = 0;
        uint hPixelsCheck = 0;

        for (uint i = 0; i < pixs.length; i++) {
            uint tokenId = i+1;

            if ((address(pixs[i].owner) == address(_holder)) && !reflectionWithdrawn[tokenId]) {
               
                reflectionWithdrawn[tokenId] = true;
                hBalanceCheck += 1;
                hPixelsCheck += pixs[i].pixels;
            }

        }

        return(hBalanceCheck, hPixelsCheck);
        
    }
    
   
    /// @dev Allow holders to withdraw their part of the reflection after all pixels have been consumed
    function holdersReflectionWithdraw() public reflectionIsReleased nonReentrant {

        address sender = _msgSender();
        uint reflectionPart = computeReflection(sender);

        uint pixelsOfSender = pixelsOf(sender);
        uint balanceOfSender = balanceOf(sender);

        require(reflectionPart > 0, 'denied : no reflection allowance');

        (uint balCheck, uint pixelsCheck) = setReflectionWithrawnForTokensOf(sender);

        require(
            (
                (pixelsCheck >= 5) 
                && (pixelsCheck <= pixelsOfSender)
            ), 
            'cant withdraw more than held pixels'
        );
        require(
            (
                (balCheck >= 1)
                && (balCheck <= balanceOfSender)
            ),
            'PIXS tokens must be owned to withdraw reflection'
        );

        payable(address(sender)).sendValue(reflectionPart);

    }

    
    /// @dev Avoid locked MATIC after reflection in the case of holders that did not withdraw within one year after the release of the reflection
    function ownersWithdrawOneYearAfterRelease() public onlyOwner reflectionIsReleased {
        uint oneYear = 31536000;
        if (block.timestamp >= (reflectionReleaseTimestamp + oneYear)) {

            uint ownerPart = thisBalance() / 2;

            // totalOwnersWithdrawn += 50 * 2
            for (uint i = 0; i < 2; i++) {
                payable(address(owners[i])).sendValue(ownerPart);
            }
        }
    }

    function releaseReflection() internal {
        reflectionReleaseTimestamp = block.timestamp;
        emit ReflectionIsReleased();
    }

    /// @dev Allow owners to abandon the project and release reflection 
    /// one year after Pixsale start time
    /// This feature avoid locking funds within the smart-contract
    /// @notice Pixels sale and PIXS minting will be definitely finished
    /// @notice Reflection will be released for all PIXS holders
    function signProjectAbandonAndReflectionRelease() public onlyOwner {
        uint oneYear = 31536000;
        require(block.timestamp >= (birthTime + oneYear), 'abandon is possible after one year of contract existence from deployment time');
        
        address sender = _msgSender();
        address otherOwner = (
            address(sender) == address(owners[0])
            ? owners[1]
            : owners[0]
        );

        // other owner has signed the agreement : release
        if (abandonOwnersSignatures[otherOwner]) {

            releaseReflection();
        } 
        // sign the agreement, wait other signature
        else {
            abandonOwnersSignatures[sender] = true;
        }
    }


    /// @notice Unsign pre-signed agreement to abandon Pixsale project by an owner
    function unsignProjectAbandonAndReflectionRelease() public onlyOwner{
        abandonOwnersSignatures[_msgSender()] = false;
    }


    /* PIXS INTEGRATED MARKET PUBLIC BUY */

    /// @dev Internal transfer for existing PIXS tokens
    function internalTransfer(address tOwner, uint tokenId, address receiver) 
    validAddress(receiver) internal returns(bool transferred) {
                
        if (address(pixs[tokenId-1].owner) == address(tOwner)) {
            pixs[tokenId-1].owner = receiver;
        }
    
        _transfer(tOwner, receiver, tokenId);

        return true;
        
    }


    /// @dev Allow users to buy PIXS tokens if on sale
    function buy(uint _tokenId) public payable nonReentrant {
        address buyer = _msgSender();
        address seller = ownerOf(_tokenId);

        require(seller != buyer, 'cant buy to self');

        uint tokenPrice = _getTokenPrice(_tokenId, seller, buyer);

        require(
            tokenPrice > 0, 
            'PIXS must be on sale'
        );

        require(
            msg.value >= tokenPrice 
        );

        payable(address(seller)).sendValue(tokenPrice);
        
        // transfer and clear old owner approvals
        internalTransfer(seller, _tokenId, buyer);

        // remove from public sale
        salePrices[_tokenId] = 0;

    }

    /// @dev Public PIXS transfer method
    function transfer(uint tokenId, address receiver) public returns(bool transferred) {
        
        address tOwner = onlyOwnerOf(tokenId);

        return internalTransfer(tOwner, tokenId, receiver);

    }

    function sameString(string memory a, string memory b) internal pure returns(bool sameStr) {
        sameStr = (
            keccak256(abi.encodePacked(a)) 
            == keccak256(abi.encodePacked(b))
        );
    }

    /// @dev Edit owned token metadatas titledDescription, image and link
    /// @notice pass empty strings ("") as arguments to keep existing value
    function editPixsMetadatas(uint tokenId, string memory tDes, string memory image, string memory link) public {
        onlyOwnerOf(tokenId);
        
        string memory emptyString = "";

        uint pixsIndex = tokenId-1;

        if (!sameString(tDes, emptyString)) {
            pixs[pixsIndex].titledDescription = tDes;
        }
        if (!sameString(image, emptyString)) {
            pixs[pixsIndex].image = image;
        }
        if (!sameString(link, emptyString)) {
            pixs[pixsIndex].link = link;
        }

    }

}