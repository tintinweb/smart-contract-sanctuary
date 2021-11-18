/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/security/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/[email protected]



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


// File contracts/interface/INFT.sol



pragma solidity ^0.8.0;

interface INFT is IERC721 {
    // event Lock(uint256 indexed tokenId);
    // event UnLock(uint256 indexed tokenId);

    function lock(uint256 tokenId) external;
    function unlock(uint256 tokenId) external;
}


// File contracts/NFTMarket.sol


pragma solidity ^0.8.4;




contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemsLent;
    Counters.Counter private _isCancelLent;
    Counters.Counter private _itemLendIds;
    Counters.Counter private _itemsCancelled;
    address payable owner;
    uint256 listingPrice = 0.0025 ether;
    //address of erc721 nft contract
    //address nftContract;

    event MarketItemCreated(
        address nftContract,
        uint256 itemId,
        uint256 tokenId,
        address seller,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 endBlock
    );

    event LendItemCreated(
        address nftContract,
        uint256 itemId,
        uint256 tokenId,
        address lender,
        uint256 priceLend,
        uint256 lendBlockDuration
    );

    struct LendHistory {
        uint256 id;
        uint256 itemMarketId;
        uint256 tokenId;
        address payable lender;
        address payable borrower;
        uint256 priceLend;
        uint256 blockNumber;
    }

    event ItemBorrow(
        address nftContract,
        uint256 itemId,
        uint256 tokenId,
        address sender
    );

    event LendCanceled(
        address nftContract,
        uint256 itemId,
        uint256 tokenId,
        address lender
    );

    event OfferPlaced(
        address nftContract,
        uint256 itemId,
        uint256 tokenId,
        uint256 offerId,
        address asker,
        uint256 amount,
        uint256 blockTime
    );
    event RewardClaimed(
        address nftContract,
        uint256 itemId,
        uint256 tokenId,
        uint256 offerId,
        address sender,
        uint256 blockTime,
        uint256 currentPrice
    );
    event ItemCanceled(
        address nftContract,
        uint256 itemId,
        uint256 tokenId,
        address sender
    );
    event ItemBuyDirectly(
        address nftContract,
        uint256 itemId,
        uint256 tokenId,
        address sender,
        uint256 currentPrice
    );
    event RetrieveItem(
        address nftContract,
        uint256 itemId,
        uint256 tokenId,
        uint256 blockTime,
        uint256 timestamp,
        address sender
    );
    //store offer of an item
    struct Offer {
        uint256 offerId;
        address asker;
        uint256 amount;
        bool refundable;
        uint256 blockTime;
    }
    //store a sell market item of a token
    struct MarketItem {
        address nftContract;
        uint256 itemId;
        uint256 tokenId;
        address payable seller;
        address payable buyer; //buyer
        uint256 minPrice;
        uint256 maxPrice;
        uint256 currentPrice;
        uint256 endBlock;
        bool sold;
        bool isCanceled;
        Counters.Counter offerCount;
    }

    struct LendItem {
        address nftContract;
        uint256 itemId;
        uint256 tokenId;
        address payable lender;
        address payable borrower;
        uint256 priceLend;
        bool lent;
        bool paid;
        bool isCanceled;
        uint256 lendBlockDuration;
    }

    struct SellHistory {
        uint256 id;
        uint256 itemMarketId;
        uint256 tokenId;
        address payable seller;
        address payable buyer;
        uint256 price;
        uint256 blockNumber;
    }

    //use itemIdToMarketItem[itemId] to get Item
    mapping(uint256 => MarketItem) private idToMarketItem;
    //use itemIdToOffer[itemId][offerId] to get offer
    mapping(uint256 => mapping(uint256 => Offer)) private itemIdToOffer;
    //use tokenSellCount[tokenId] to get how many time token was sold
    mapping(uint256 => Counters.Counter) private tokenSellCount;
    //use tokenIdToSellHistory[tokenId][sellHistoryId] to get sell history
    mapping(uint256 => mapping(uint256 => SellHistory))
        private tokenIdToSellHistory;
    // use lendHistory
    mapping(uint256 => mapping(uint256 => LendHistory))
        private tokenIdToLendHistory;
    mapping(uint256 => Counters.Counter) private tokenLendCount;

    mapping(uint256 => LendItem) private lendItems;

    constructor() {
        owner = payable(msg.sender);
    }

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* Returns the market item by item id */
    function getMarketItem(uint256 itemId)
        public
        view
        returns (MarketItem memory)
    {
        return idToMarketItem[itemId];
    }

    /// @notice Make an market item for sell token. Token must be approved first
    /// @param tokenId id of token
    /// @param minPrice minimum price to make offer
    /// @param maxPrice maximum price to make offer
    /// @param endBlock block that item stops receiving offer
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 endBlock
    ) public payable nonReentrant {
        require(
            msg.value == listingPrice,
            'Order fee must be equal to listing price'
        );
        require(
            minPrice <= maxPrice,
            'max price must be greater than min price'
        );
        require(minPrice > 0);
        uint256 itemId = _itemIds.current();
        Counters.Counter memory offercount;
        idToMarketItem[itemId] = MarketItem(
            nftContract,
            itemId,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            minPrice,
            maxPrice,
            0,
            endBlock,
            false,
            false,
            offercount
        );
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        _itemIds.increment();
        emit MarketItemCreated(
            nftContract,
            itemId,
            tokenId,
            msg.sender,
            minPrice,
            maxPrice,
            endBlock
        );
    }

    /// @notice user not owner make offer. set the value want to make offer
    /// @param itemId id of market item
    function makeOffer(uint256 itemId) public payable nonReentrant {
        require(
            msg.sender != idToMarketItem[itemId].seller,
            'asker must not be owner'
        );
        require(idToMarketItem[itemId].sold == false, 'item has been sold');
        require(
            idToMarketItem[itemId].endBlock >= block.number,
            'Item has been expired'
        );
        require(!idToMarketItem[itemId].isCanceled, 'Item has been cancelled');
        require(
            msg.value >= idToMarketItem[itemId].minPrice,
            'Offer must greater than min price'
        );
        require(
            msg.value > idToMarketItem[itemId].currentPrice,
            'Offer must greater than current price'
        );
        require(
            msg.value < idToMarketItem[itemId].maxPrice,
            'Offer must less than max price'
        );
        //payable(address(this)).transfer(msg.value);
        uint256 offerId = idToMarketItem[itemId].offerCount.current();
        Offer memory newOffer;
        newOffer.offerId = offerId;
        newOffer.asker = msg.sender;
        newOffer.amount = msg.value;
        newOffer.refundable = true;
        newOffer.blockTime = block.number;
        itemIdToOffer[itemId][offerId] = newOffer;
        idToMarketItem[itemId].currentPrice = msg.value;
        // refund lower offer
        if (offerId > 0 && itemIdToOffer[itemId][offerId - 1].refundable) {
            uint256 amount = itemIdToOffer[itemId][offerId].amount;
            itemIdToOffer[itemId][offerId - 1].refundable = false;
            payable(itemIdToOffer[itemId][offerId - 1].asker).transfer(amount);
        }
        idToMarketItem[itemId].offerCount.increment();
        emit OfferPlaced(
            idToMarketItem[itemId].nftContract,
            itemId,
            idToMarketItem[itemId].tokenId,
            offerId,
            msg.sender,
            msg.value,
            block.number
        );
    }

    /// @notice Directly buy an token from market item. value must be set by item maximum price
    /// @param itemId id of market item
    function buyDirectly(uint256 itemId) public payable nonReentrant {
        uint256 currentBlock = block.number;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        require(
            msg.sender != idToMarketItem[itemId].seller,
            'asker must not be owner'
        );

        require(idToMarketItem[itemId].sold == false, 'item has been sold');
        require(!idToMarketItem[itemId].isCanceled, 'Item has been cancelled');
        require(
            idToMarketItem[itemId].maxPrice == msg.value,
            'Price must equal to max price to buy directly'
        );

        idToMarketItem[itemId].buyer = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        idToMarketItem[itemId].currentPrice = msg.value;
        uint256 newSellHistoryId = tokenSellCount[tokenId].current();
        _itemsSold.increment();
        SellHistory memory sellHistory = SellHistory(
            newSellHistoryId,
            itemId,
            tokenId,
            idToMarketItem[itemId].seller,
            idToMarketItem[itemId].buyer,
            msg.value,
            currentBlock
        );
        tokenIdToSellHistory[tokenId][newSellHistoryId] = sellHistory;
        tokenSellCount[tokenId].increment();
        idToMarketItem[itemId].seller.transfer(msg.value);
        IERC721(idToMarketItem[itemId].nftContract).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        payable(owner).transfer(listingPrice);
        //idToMarketItem[itemId].seller.transfer(listingPrice);
        emit ItemBuyDirectly(
            idToMarketItem[itemId].nftContract,
            itemId,
            tokenId,
            msg.sender,
            idToMarketItem[itemId].currentPrice
        );
    }

    /// @notice user claim token if won the audit
    /// @param itemId id of market item
    /// @param offerId id of offer that user won
    function claimReward(uint256 itemId, uint256 offerId)
        public
        payable
        nonReentrant
    {
        uint256 currentBlock = block.number;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        uint256 amount = itemIdToOffer[itemId][offerId].amount;
        require(
            msg.sender != idToMarketItem[itemId].seller,
            'asker must not be owner'
        );
        require(idToMarketItem[itemId].sold == false, 'item has been sold');
        require(
            idToMarketItem[itemId].endBlock < currentBlock,
            "item hasn't exceeded claim stage"
        );
        require(!idToMarketItem[itemId].isCanceled, 'item has been cancelled');
        require(
            itemIdToOffer[itemId][offerId].asker == msg.sender,
            'sender is not offer owner'
        );
        require(
            itemIdToOffer[itemId][offerId].refundable,
            'offer has been refunded'
        );
        require(
            amount == idToMarketItem[itemId].currentPrice,
            'sender is not item winner'
        );

        idToMarketItem[itemId].buyer = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        itemIdToOffer[itemId][offerId].refundable == false;
        uint256 newSellHistoryId = tokenSellCount[tokenId].current();
        SellHistory memory sellHistory = SellHistory(
            newSellHistoryId,
            itemId,
            tokenId,
            idToMarketItem[itemId].seller,
            payable(msg.sender),
            amount,
            block.number
        );
        tokenIdToSellHistory[tokenId][newSellHistoryId] = sellHistory;
        _itemsSold.increment();
        tokenSellCount[tokenId].increment();
        idToMarketItem[itemId].seller.transfer(amount);
        IERC721(idToMarketItem[itemId].nftContract).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        payable(owner).transfer(listingPrice);
        emit RewardClaimed(
            idToMarketItem[itemId].nftContract,
            itemId,
            tokenId,
            offerId,
            msg.sender,
            block.number,
            amount
        );
    }

    /// @notice market item owner cancel and refund nft
    /// @param itemId id of market item
    function cancelMarketItemAuction(uint256 itemId) public nonReentrant {
        require(
            idToMarketItem[itemId].seller == msg.sender,
            'sender must be seller'
        );
        require(!idToMarketItem[itemId].isCanceled, 'item has been cancelled');
        require(
            idToMarketItem[itemId].offerCount.current() == 0,
            'there are offers placed on this market item'
        );
        require(
            idToMarketItem[itemId].buyer == address(0),
            'item has been sold'
        );
        IERC721(idToMarketItem[itemId].nftContract).transferFrom(
            address(this),
            idToMarketItem[itemId].seller,
            idToMarketItem[itemId].tokenId
        );
        idToMarketItem[itemId].isCanceled = true;
        idToMarketItem[itemId].seller.transfer(listingPrice);
        _itemsCancelled.increment();
        emit ItemCanceled(
            idToMarketItem[itemId].nftContract,
            itemId,
            idToMarketItem[itemId].tokenId,
            msg.sender
        );
    }

    /// @notice Returns all available market items
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() -
            _itemsSold.current() -
            _itemsCancelled.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (
                idToMarketItem[i].buyer == address(0) &&
                idToMarketItem[i].isCanceled == false
            ) {
                uint256 currentId = i;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /// @notice Returns only items that a user had bought
    /// @param _user id of market item
    function fetchMyNFTs(address _user)
        public
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i].buyer == _user) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i].buyer == _user) {
                uint256 currentId = i;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /// @notice Returns only items a user had sold
    /// @param _user id of market item
    function fetchItemsCreated(address _user)
        public
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i].seller == _user && idToMarketItem[i].sold) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i].seller == _user && idToMarketItem[i].sold) {
                MarketItem storage currentItem = idToMarketItem[i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /// @notice get all offers for an item
    /// @param itemId id of market item
    function fetchOffersOfItem(uint256 itemId)
        public
        view
        returns (Offer[] memory)
    {
        uint256 offerCount = idToMarketItem[itemId].offerCount.current();
        uint256 currentIndex = 0;
        Offer[] memory offersOfItem = new Offer[](offerCount);
        for (uint256 i = 0; i < offerCount; i++) {
            Offer storage currentOffer = itemIdToOffer[itemId][i];
            offersOfItem[currentIndex] = currentOffer;
            currentIndex += 1;
        }
        return offersOfItem;
    }

    /// @notice get sell history of an nft
    /// @param tokenId unique id of nft
    function fetchSellHistoryOfToken(uint256 tokenId)
        public
        view
        returns (SellHistory[] memory)
    {
        uint256 historyCount = tokenSellCount[tokenId].current();
        SellHistory[] memory sellHistoriesOfToken = new SellHistory[](
            historyCount
        );
        for (uint256 i = 0; i < historyCount; i++) {
            sellHistoriesOfToken[i] = tokenIdToSellHistory[tokenId][i];
        }
        return sellHistoriesOfToken;
    }

    function cancelMarketItem(uint256 _itemId) public nonReentrant {
        require(
            idToMarketItem[_itemId].seller == msg.sender,
            'sender must be the seller'
        );
        require(!idToMarketItem[_itemId].isCanceled, 'item has been cancelled');
        require(
            idToMarketItem[_itemId].buyer == address(0),
            'item has been sold'
        );
        IERC721(idToMarketItem[_itemId].nftContract).transferFrom(
            address(this),
            idToMarketItem[_itemId].seller,
            idToMarketItem[_itemId].tokenId
        );
        idToMarketItem[_itemId].isCanceled = true;
        idToMarketItem[_itemId].seller.transfer(listingPrice);
        _itemsCancelled.increment();
        emit ItemCanceled(
            idToMarketItem[_itemId].nftContract,
            _itemId,
            idToMarketItem[_itemId].tokenId,
            msg.sender
        );
    }

    function lend(
        address nftContract,
        uint256 tokenId,
        uint256 priceLend,
        uint256 lendBlockDuration
    ) public payable {
        require(
            msg.value == listingPrice,
            'Order fee must be equal to listing price'
        );
        require(priceLend > 0, 'The price you set is less than 0');
        require(lendBlockDuration > block.number);
        uint256 itemId = _itemLendIds.current();
        lendItems[itemId] = LendItem(
            nftContract,
            itemId,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            priceLend,
            false,
            false,
            false,
            lendBlockDuration
        );
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        _itemLendIds.increment();
        emit LendItemCreated(
            nftContract,
            itemId,
            tokenId,
            msg.sender,
            priceLend,
            lendBlockDuration
        );
    }

    function borrow(uint256 itemId) public payable {
        uint256 currentBlock = block.number;
        uint256 tokenId = lendItems[itemId].tokenId;
        require(
            msg.value == lendItems[itemId].priceLend,
            'Price must equal to priceLend'
        );
        require(
            msg.sender != lendItems[itemId].lender,
            'asker must not be owner'
        );
        require(lendItems[itemId].lent == false, 'item has been lent');
        require(
            lendItems[itemId].lendBlockDuration >= currentBlock,
            'Item has been expired'
        );
        require(!lendItems[itemId].isCanceled);
        lendItems[itemId].borrower = payable(msg.sender);
        lendItems[itemId].lent = true;
        uint256 newLendHistoryId = tokenLendCount[tokenId].current();
        _itemsLent.increment();
        LendHistory memory lendHistory = LendHistory(
            newLendHistoryId,
            itemId,
            tokenId,
            lendItems[itemId].lender,
            lendItems[itemId].borrower,
            msg.value,
            currentBlock
        );
        tokenIdToLendHistory[tokenId][newLendHistoryId] = lendHistory;
        tokenLendCount[tokenId].increment();
        lendItems[itemId].lender.transfer(msg.value);
        IERC721(lendItems[itemId].nftContract).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        INFT(lendItems[itemId].nftContract).lock(tokenId);
        payable(owner).transfer(listingPrice);
        emit ItemBorrow(
            lendItems[itemId].nftContract,
            itemId,
            tokenId,
            msg.sender
        );
    }

    function retrieve(uint256 itemId) public {
        uint256 tokenId = lendItems[itemId].tokenId;
        require(!lendItems[itemId].paid);
        require(block.number >= lendItems[itemId].lendBlockDuration);
        require(msg.sender == lendItems[itemId].lender);
        INFT(lendItems[itemId].nftContract).unlock(tokenId);
        IERC721(lendItems[itemId].nftContract).transferFrom(
            lendItems[itemId].borrower,
            msg.sender,
            tokenId
        );
        lendItems[itemId].paid = true;
        emit RetrieveItem(
            lendItems[itemId].nftContract,
            itemId,
            tokenId,
            block.number,
            block.timestamp,
            msg.sender
        );
    }

    function cancelLend(uint256 _itemId) public {
        require(
            lendItems[_itemId].lender == msg.sender,
            'caller must be the lender'
        );
        require(!lendItems[_itemId].isCanceled, 'item has been cancelled');
        require(
            lendItems[_itemId].borrower == address(0),
            'item has been sold'
        );
        IERC721(lendItems[_itemId].nftContract).transferFrom(
            address(this),
            lendItems[_itemId].lender,
            lendItems[_itemId].tokenId
        );
        lendItems[_itemId].isCanceled = true;
        lendItems[_itemId].lender.transfer(listingPrice);
        emit LendCanceled(
            lendItems[_itemId].nftContract,
            _itemId,
            lendItems[_itemId].tokenId,
            msg.sender
        );
    }

    function getLend(uint256 _itemId) public view returns (LendItem memory) {
        return lendItems[_itemId];
    }

    function fetchAllLendItem() public view returns (LendItem[] memory) {
        uint256 itemCount = _itemLendIds.current();
        uint256 unLendItemCount = _itemLendIds.current() -
            _itemsLent.current() -
            _isCancelLent.current();
        uint256 currentIndex = 0;

        LendItem[] memory items = new LendItem[](unLendItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (
                lendItems[i].borrower == address(0) &&
                lendItems[i].isCanceled == false
            ) {
                uint256 currentId = i;
                LendItem storage currentItem = lendItems[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyBorrow(address _user)
        public
        view
        returns (LendItem[] memory)
    {
        uint256 totalMyBorrowCount = _itemLendIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalMyBorrowCount; i++) {
            if (lendItems[i].borrower == _user) {
                itemCount += 1;
            }
        }

        LendItem[] memory items = new LendItem[](itemCount);

        for (uint256 i = 0; i < totalMyBorrowCount; i++) {
            if (lendItems[i].borrower == _user) {
                uint256 currentId = i;
                LendItem storage currentItem = lendItems[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyLend(address _user)
        public
        view
        returns (LendItem[] memory)
    {
        uint256 totalMyLendCount = _itemLendIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalMyLendCount; i++) {
            if (lendItems[i].lender == _user) {
                itemCount += 1;
            }
        }

        LendItem[] memory items = new LendItem[](itemCount);

        for (uint256 i = 0; i < totalMyLendCount; i++) {
            if (lendItems[i].lender == _user) {
                uint256 currentId = i;
                LendItem storage currentItem = lendItems[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchLendHistory(uint256 tokenId)
        public
        view
        returns (LendHistory[] memory)
    {
        uint256 historyCount = tokenLendCount[tokenId].current();
        LendHistory[] memory lendHistories = new LendHistory[](historyCount);
        for (uint256 i = 0; i < historyCount; i++) {
            lendHistories[i] = tokenIdToLendHistory[tokenId][i];
        }
        return lendHistories;
    }
}