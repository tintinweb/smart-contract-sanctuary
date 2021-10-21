/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// File: @openzeppelin/contracts/utils/Context.sol
// SPDX-License-Identifier: MIT
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

// File: contracts/Base64.sol
pragma solidity ^0.8.9;

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

// File: contracts/HeadscapesStorage.sol
pragma solidity ^0.8.9;

contract HeadscapesStorage {
    constructor() {}

    function getPalettes(uint256 index) public pure returns (string memory) {
        return
            [
                "b: #281C2D; --s: #695E93; --a: #8155BA; --m: #BEAFC2",
                "b: #738FA7; --s: #0C4160; --a: #C3CEDA; --m: #071330",
                "b: #1A5653; --s: #107869; --a: #5CD85A; --m: #08313A",
                "b: #E95670; --s: #713770; --a: #B34270; --m: #432F70",
                "b: #E1A140; --s: #532200; --a: #EFCFA0; --m: #914110",
                "b: #0B0909; --s: #44444C; --a: #8C8C8C; --m: #D6D6D6",
                "b: #F1D26C; --s: #2B1200; --a: #CF5C00; --m: #8D1E00",
                "b: #8C9B88; --s: #F5E8DA; --a: #735E93; --m: #EFF1EF",
                "b: #676E7F; --s: #0F0D12; --a: #F9F6F0; --m: #B6737C"
            ][index];
    }

    function getPatterns(uint256 index) public pure returns (string memory) {
        return
            [
                'x="-7.25" y="142.5" patternUnits="userSpaceOnUse" width="126" height="200" viewBox="0 0 10 16"><g id="cube"><path fill="var(--a)" d="M0 0l5 3v5l-5 -3z"></path><path d="M10 0l-5 3v5l5 -3"></path></g><use x="5" y="8" href="#cube"></use><use x="-5" y="8" href="#cube"></use>',
                'x="12" y="-5" width="375" height="62.5" patternUnits="userSpaceOnUse"><linearGradient id="g1"><stop offset="5%" stop-color="var(--s)"/><stop offset="50%" stop-color="var(--m)"/><stop offset="95%" stop-color="var(--s)"/></linearGradient><radialGradient id="g2"><stop offset="10%" stop-color="var(--s)"/><stop offset="50%" stop-color="var(--a)"/></radialGradient><rect fill="url(#g1)" height="10" width="375" x="0" y="0"/><g fill-opacity="0.5" stroke="var(--s)" fill="url(#g2)"><circle cx="20" cy="40" r="5" stroke-width="1"/><circle cx="82.5" cy="40" r="7" stroke-width="3" /><circle cx="145" cy="40" r="4" stroke-width="3"/><circle cx="207.5" cy="40" r="8" stroke-width="2"/><circle cx="270" cy="40" r="2" stroke-width="3"/><circle cx="332.5" cy="40" r="3.5" stroke-width="1"/></g>',
                'x="-12.5" y="15.625" width="150" height="62.5" patternUnits="userSpaceOnUse" stroke-width="4"><path d="M0 0 L0 0 25 25 M25 0 L25 0 0 25" stroke="var(--a)"/><path d="M12.5 25 v50" stroke="var(--m)"/><path d="M25 12.5 h45" stroke="var(--m)"/><path d="M87 29.25 v30" stroke="var(--a)"/><circle cx="87" cy="13" r="11.5" fill="transparent" stroke="var(--s)" fill-opacity="0.5"/><path d="M103 12.5 h45" stroke="var(--m)"/>',
                'x="-12.5" y="15.625" width="150" height="62.5" patternUnits="userSpaceOnUse"><linearGradient id="g1" gradientTransform="rotate(90)"><stop offset="5%" stop-color="var(--m)"/><stop offset="95%" stop-color="var(--s)"/></linearGradient><path d="M0 0 v62.5 h150z" stroke="var(--a)" fill="url(#g1)" stroke-width="4"/>',
                'x="0" y="0" width="750" height="250" patternUnits="userSpaceOnUse"><radialGradient id="g1"><stop offset="10%" stop-color="var(--b)"/><stop offset="95%" stop-color="var(--m)"/></radialGradient><circle cx="0" cy="125" r="95" fill="transparent" stroke-width="2" stroke="var(--m)" /><circle cx="0" cy="125" r="45" fill="var(--s)"/><circle cx="750" cy="125" r="75" fill="var(--a)"/><circle cx="375" cy="250" r="80" fill="var(--s)"/><circle cx="375" cy="0" r="30" fill="transparent" stroke-width="2" stroke="var(--a)"/><circle cx="375" cy="250" r="30" fill="transparent" stroke-width="2" stroke="var(--a)"/><circle cx="375" cy="125" r="25" fill="var(--m)"/><circle cx="750" cy="250" r="31" fill="var(--s)"/><circle cx="750" cy="0" r="31" fill="var(--a)"/><circle cx="0" cy="0" r="22" fill="var(--m)"/><circle cx="750" cy="0" r="22" fill="var(--s)"/><circle cx="0" cy="250" r="22" fill="var(--a)"/><circle cx="750" cy="250" r="22" fill="url(#g1)"/>',
                'x="0" y="0" width="750" height="100" patternUnits="userSpaceOnUse" stroke-width="4"><radialGradient cx="10%" cy="10%" id="g1"><stop offset="5%" stop-color="var(--a)"/><stop offset="95%" stop-color="var(--m)"/></radialGradient><radialGradient cx="90%" cy="90%" id="g2"><stop offset="5%" stop-color="var(--m)"/><stop offset="95%" stop-color="var(--a)"/></radialGradient><path d="M0 0 v100 h375 z" stroke="var(--s)" fill="url(#g1)"/><path d="M375 100 h375 V0 z" stroke="var(--s)" fill="url(#g2)"/>',
                'x="0" y="0" width="300" height="125" patternUnits="userSpaceOnUse" stroke-width="4" fill="transparent"><path d="M20 0 Q-30 75, 100 20 T65 120 " stroke="var(--s)" /><path d="M 20 0 C -30 75, 65 10, 100 10 S -180 150, 280 20 S -100 200, -100 200" transform="scale(0.5) translate(200 10) rotate(180 150 75)" stroke="var(--a)" /><path d="M275 100 q-20 -30, -30 -40 t-20 30 t-20 -30 t20 -30" stroke="var(--m)" />',
                'x="-12.5" y="0" width="125" height="125" patternUnits="userSpaceOnUse" stroke-width="4" fill-opacity="0.75"><rect x="25" y="12.5" height="100" width="100" fill="var(--m)"/><rect x="50" y="37.5" height="50" width="50" fill="var(--m)"/><rect x="0" y="0" height="10" width="150" fill="var(--s)"/><rect x="0" y="115" height="10" width="150" fill="var(--s)"/><rect x="0" y="10" height="2.5" width="125" fill="var(--a)"/><rect x="0" y="112.5" height="2.5" width="125" fill="var(--a)"/><rect x="0" y="22.5" height="2.5" width="125" fill="var(--a)"/><rect x="0" y="100" height="2.5" width="125" fill="var(--a)"/><rect x="37.5" y="0" height="125" width="2.5" fill="var(--s)" /><rect x="110" y="0" height="125" width="2.5" fill="var(--s)"/><rect x="0" y="60" height="5" width="375" fill="var(--a)"/><rect x="72.5" y="0" height="375" width="5" fill="var(--a)"/>',
                ""
            ][index];
    }

    function getTurbs(uint256 index) public pure returns (string memory) {
        return
            [
                'type="fractalNoise" baseFrequency="0.0029, .0009" numOctaves="5"',
                'type="fractalNoise" baseFrequency="0.069, .0420" numOctaves="5"',
                'type="fractalNoise" baseFrequency="0.002, .029" numOctaves="50"',
                'type="fractalNoise" baseFrequency=".0420, .069" numOctaves="6.9"',
                'type="turbulence" baseFrequency="0.09, .06" numOctaves="1"',
                'type="fractalNoise" baseFrequency="0.2, .9" numOctaves="50"',
                'type="turbulence" baseFrequency=".00888, .0888" numOctaves="88"',
                'type="turbulence" baseFrequency="2, .029" numOctaves="10"',
                'type="fractalNoise" baseFrequency="0, 0" numOctaves="0"'
            ][index];
    }

    function getBlurs(uint256 index) public pure returns (string memory) {
        return
            ["0.0", "0.0", "0.0", "0.0", "0.04", "0.2", "0.7", "1.7", "7"][index];
    }

    function getGrads(uint256 index) public pure returns (string memory) {
        return
            [
                "var(--b)",
                "linear-gradient(var(--s), var(--b))",
                "radial-gradient(var(--s), var(--b))",
                "repeating-linear-gradient(var(--s), var(--b) 125px)",
                "repeating-radial-gradient(var(--s), var(--b) 1px)",
                "conic-gradient(var(--b), var(--s))",
                "repeating-linear-gradient(0.85turn, transparent, var(--s) 100px),repeating-linear-gradient(0.15turn, transparent, var(--b) 50px),repeating-linear-gradient(0.5turn, transparent, var(--a) 20px),repeating-linear-gradient(transparent, var(--m) 1px)",
                "repeating-conic-gradient(var(--b) 0 9deg, var(--s) 9deg 18deg)",
                "repeating-conic-gradient(from 0deg at 50% 50%, red, orange, yellow, green, blue, indigo, violet)"
            ][index];
    }

    function getLights(uint256 index) public pure returns (string memory) {
        return
            [
                "",
                "",
                "",
                "",
                "",
                'surfaceScale="100"><fePointLight x="750" y="250" z="200"/></feDiffuseLighting>',
                'surfaceScale="6"><feDistantLight azimuth="10" elevation="43"/></feDiffuseLighting>',
                'surfaceScale="10"><fePointLight x="750" y="250" z="200"/></feDiffuseLighting>',
                'surfaceScale="22"><feDistantLight azimuth="5" elevation="40"/></feDiffuseLighting>'
            ][index];
    }

    function getMaps(uint256 index) public pure returns (string memory) {
        return
            [
                'in="SourceGraphic" scale="10" xChannelSelector="A" yChannelSelector="B"',
                'in="SourceGraphic" scale="20" xChannelSelector="R" yChannelSelector="B"',
                'in="FillPaint" scale="100" xChannelSelector="B" yChannelSelector="G"',
                'in="FillPaint" scale="300" xChannelSelector="A" yChannelSelector="R"',
                'in="FillPaint" scale="600" xChannelSelector="R" yChannelSelector="R"',
                'in="FillPaint" scale="1000" xChannelSelector="G" yChannelSelector="R"',
                'in="SourceAlpha" scale="987" xChannelSelector="B" yChannelSelector="A"',
                'in="[redacted]" scale="69" xChannelSelector="A" yChannelSelector="R"',
                'in="[redacted]" scale="420" xChannelSelector="A" yChannelSelector="A"'
            ][index];
    }
}

// File: contracts/Headscapes.sol
pragma solidity ^0.8.9;

//  ▄▄   ▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄ ▄▄▄▄▄▄  ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄
// █  █ █  █       █      █      ██       █       █      █       █       █       █
// █  █▄█  █    ▄▄▄█  ▄   █  ▄    █  ▄▄▄▄▄█       █  ▄   █    ▄  █    ▄▄▄█  ▄▄▄▄▄█
// █       █   █▄▄▄█ █▄█  █ █ █   █ █▄▄▄▄▄█     ▄▄█ █▄█  █   █▄█ █   █▄▄▄█ █▄▄▄▄▄
// █   ▄   █    ▄▄▄█      █ █▄█   █▄▄▄▄▄  █    █  █      █    ▄▄▄█    ▄▄▄█▄▄▄▄▄  █
// █  █ █  █   █▄▄▄█  ▄   █       █▄▄▄▄▄█ █    █▄▄█  ▄   █   █   █   █▄▄▄ ▄▄▄▄▄█ █
// █▄▄█ █▄▄█▄▄▄▄▄▄▄█▄█ █▄▄█▄▄▄▄▄▄██▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄█ █▄▄█▄▄▄█   █▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█
// On Chain generative banner art

contract Headscapes is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 private nonce = 0;

    HeadscapesStorage private store =
        HeadscapesStorage(0x4e7a909736Aa3efb6bB7bDbbbFfB901a0917e055);

    mapping(string => bool) private hashToMinted;
    mapping(uint256 => string) private tokenIdToHash;
    mapping(uint256 => string) private tokenIdToTitle;
    mapping(bytes32 => bool) public titleToIsTaken;

    struct Headscape {
        uint8 blur;
        uint8 gradient;
        uint8 light;
        uint8 map;
        uint8 palette;
        uint8 pattern;
        uint8 turbulence;
    }

    constructor() ERC721("Headscapes", "HDSCP") {}

    function generateSvg(Headscape memory headscape, uint256 tokenId) internal view returns (string memory) {
        string memory header = getSvgHeader(headscape, tokenId);
        string memory rectTail = headscape.pattern == 8
            ? ' fill="var(--b)" />'
            : ' fill="url(#p0)" />';

        return
            string(
                abi.encodePacked(
                    header,
                    '<rect height="500" width="1500" filter="url(#f0)"',
                    rectTail,
                    "</svg>"
                )
            );
    }

    function getSvgHeader(Headscape memory headscape, uint256 tokenId) internal view returns (string memory) {
        string memory o = string(
            abi.encodePacked(
                '<svg width="1500" height="500" version="1.1" xmlns="http://www.w3.org/2000/svg" style="position: relative; background: ',
                store.getGrads(headscape.gradient),
                ';" class="c0">',
                "<style>.c0{--",
                store.getPalettes(headscape.palette),
                ";}</style>",
                "<defs>",
                headscape.pattern == 8
                    ? ""
                    : string(
                        abi.encodePacked(
                            '<pattern id="p0" ',
                            store.getPatterns(headscape.pattern),
                            "</pattern>"
                        )
                    ),
                getFilter(headscape, tokenId),
                "</defs>"
            )
        );
        return o;
    }

    function getFilter(Headscape memory headscape, uint256 tokenId) internal view returns (string memory) {
        // pattern == 8 means no pattern
        string memory r = headscape.pattern == 8
            ? 'in="r2" result="r3" '
            : 'in="r3" result="r4" ';
        string memory light = store.getLights(headscape.light);
        string memory l = compareStrings(light, "")
            ? ""
            : string(
                abi.encodePacked(
                    '<feDiffuseLighting lighting-color="var(--a)" ',
                    r,
                    store.getLights(headscape.light)
                )
            );
        // Every other token gets a merge node
        string memory f = tokenId % 2 == 0
            ? "</filter>"
            : '<feMerge><feMergeNode in="r4" /><feMergeNode in="r2" /></feMerge></filter>';
        string memory o;
        if (headscape.pattern == 8) {
            o = string(
                abi.encodePacked(
                    '<filter id="f0">',
                    "<feTurbulence ",
                    store.getTurbs(headscape.turbulence),
                    ' seed="',
                    toString(tokenId),
                    '" result="r1" />',
                    '<feGaussianBlur stdDeviation="',
                    store.getBlurs(headscape.blur),
                    '" in="r1" result="r2" />',
                    l,
                    "</filter>"
                )
            );
        } else {
            o = string(
                abi.encodePacked(
                    '<filter id="f0">',
                    "<feTurbulence ",
                    store.getTurbs(headscape.turbulence),
                    ' seed="',
                    toString(tokenId),
                    '" result="r1" />',
                    '<feDisplacementMap in2="r1" result="r2" ',
                    store.getMaps(headscape.map),
                    " />",
                    '<feGaussianBlur stdDeviation="',
                    store.getBlurs(headscape.blur),
                    '" in="r2" result="r3" />',
                    l,
                    f
                )
            );
        }
        return o;
    }

    function getAttributes(Headscape memory headscape) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '", "attributes": [{"trait_type": "Blur","value": "',
                    [
                        "None",
                        "None",
                        "None",
                        "None",
                        "Faint",
                        "Bleary",
                        "Fuzzy",
                        "Hazy",
                        "Myopia"
                    ][headscape.blur],
                    '"},{"trait_type": "Gradient","value": "',
                    [
                        "None",
                        "Linear",
                        "Radial",
                        "Repeating Linear",
                        "Repeating Radial",
                        "Conic",
                        "Pyramid Flannel",
                        "Rising Sun",
                        "Rainbow Wheel"
                    ][headscape.gradient],
                    '"},{"trait_type": "Light","value": "',
                    [
                        "None",
                        "None",
                        "None",
                        "None",
                        "None",
                        "High Point Light",
                        "Low Distance Light",
                        "Low Point Light",
                        "High Distance Light"
                    ][headscape.light],
                    '"},{"trait_type": "Displacement Map","value": "',
                    [
                        "10",
                        "20",
                        "100",
                        "300",
                        "600",
                        "1000",
                        "987 Alpha",
                        "[redacted] I",
                        "[redacted] II"
                    ][headscape.map],
                    '"},{"trait_type": "Palette","value": "',
                    [
                        "Purple Fabric",
                        "Mountain Haze",
                        "Northern Lights",
                        "Lava Sky",
                        "Autumn Crush",
                        "Dark Metal",
                        "Fall Fire",
                        "Secret Spring",
                        "Winter Musings"
                    ][headscape.palette],
                    '"},{"trait_type": "Pattern","value": "',
                    [
                        "Cubes",
                        "Dots & Lines",
                        "Xs and Os",
                        "Banners",
                        "Circles",
                        "Triangles",
                        "Squiggles",
                        "Plaid",
                        "None"
                    ][headscape.pattern],
                    '"},{"trait_type": "Turbulence","value": "',
                    [
                        "Fractal 1",
                        "Fractal 2",
                        "Fractal 3",
                        "Fractal 4",
                        "Turbulence 1",
                        "Fractal 5",
                        "Turbulence 2",
                        "Turbulence 3",
                        "None"
                    ][headscape.turbulence]
                )
            );
    }

    function getHeadscape(uint256 tokenId) internal view returns (Headscape memory) {
        // substring locations for each relevant index are alphabetical (blur, gradient, light, etc)
        // blur index is at tokenIdToHash[tokenId][0]
        // gradient index is at tokenIdToHash[tokenId][1]. etc
        Headscape memory headscape;
        headscape.blur = uint8(
            charToInt(substring(tokenIdToHash[tokenId], 0, 1))
        );
        headscape.gradient = uint8(
            charToInt(substring(tokenIdToHash[tokenId], 1, 2))
        );
        headscape.light = uint8(
            charToInt(substring(tokenIdToHash[tokenId], 2, 3))
        );
        headscape.map = uint8(
            charToInt(substring(tokenIdToHash[tokenId], 3, 4))
        );
        headscape.palette = uint8(
            charToInt(substring(tokenIdToHash[tokenId], 4, 5))
        );
        headscape.pattern = uint8(
            charToInt(substring(tokenIdToHash[tokenId], 5, 6))
        );
        headscape.turbulence = uint8(
            charToInt(substring(tokenIdToHash[tokenId], 6, 7))
        );
        return headscape;
    }

    function hash(uint256 tokenId) internal returns (string memory) {
        uint8 blur = usew(
            [240, 232, 180, 90, 80, 70, 60, 58, 55],
            random(
                string(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        tokenId,
                        nonce
                    )
                )
            ) % 1065
        );
        uint8 gradient = usew(
            [250, 240, 232, 180, 110, 90, 80, 70, 55],
            random(
                string(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        tokenId,
                        nonce
                    )
                )
            ) % 1307
        );
        uint8 light = usew(
            [240, 230, 220, 210, 200, 150, 140, 130, 120],
            random(
                string(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        tokenId,
                        nonce
                    )
                )
            ) % 1640
        );
        uint8 map = usew(
            [240, 232, 210, 188, 130, 100, 90, 78, 69],
            random(
                string(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        tokenId,
                        nonce
                    )
                )
            ) % 1337
        );
        uint8 palette = usew(
            [250, 245, 240, 235, 230, 225, 220, 215, 210],
            random(
                string(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        tokenId,
                        nonce
                    )
                )
            ) % 2070
        );
        uint8 pattern = usew(
            [240, 232, 200, 180, 170, 160, 140, 130, 120],
            random(
                string(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        tokenId,
                        nonce
                    )
                )
            ) % 1572
        );
        uint8 turbulence = usew(
            [240, 232, 180, 110, 90, 80, 70, 60, 55],
            random(
                string(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        tokenId,
                        nonce
                    )
                )
            ) % 1117
        );

        // Hack to get around the fact that blur and light have multiple 'None's and need
        // to be ranked the same using the same index
        blur = blur < 5 ? 0 : blur;
        light = light < 5 ? 0 : light;

        string memory h = string(
            abi.encodePacked(
                toString(blur),
                toString(gradient),
                toString(light),
                toString(map),
                toString(palette),
                toString(pattern),
                toString(turbulence)
            )
        );
        // no dupes
        if (hashToMinted[h]) {
            nonce++;
            return hash(tokenId);
        }
        return h;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        Headscape memory headscape = getHeadscape(tokenId);
        string memory name = bytes(tokenIdToTitle[tokenId]).length > 0
            ? string(tokenIdToTitle[tokenId])
            : string(abi.encodePacked("Headscape #", toString(tokenId)));
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    name,
                                    getAttributes(headscape),
                                    '"},{"trait_type": "Titled","value": "',
                                    compareStrings(tokenIdToTitle[tokenId], "")
                                        ? "false"
                                        : "true",
                                    '"}], "image": "data:image/svg+xml;base64,',
                                    Base64.encode(
                                        bytes(generateSvg(headscape, tokenId))
                                    ),
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    // Write Functions

    // Adds a user-defined title to a Headscape
    function addTitle(uint256 tokenId, string memory text) public nonReentrant {
        require(
            _msgSender() == ownerOf(tokenId),
            "You don't own this Headscape"
        );
        require(
            bytes(tokenIdToTitle[tokenId]).length == 0,
            "This Headscape already has a title!"
        );
        require(
            !titleToIsTaken[(keccak256(abi.encodePacked((text))))],
            "This title has already been taken"
        );
        require(
            bytes(text).length > 0 && bytes(text).length < 65,
            "Enter a title at least 1 and up to 64 chars long"
        );
        tokenIdToTitle[tokenId] = cleanString(text);
        titleToIsTaken[(keccak256(abi.encodePacked((text))))] = true;
    }

    // Claim from 1 and up to 10 at a time.
    // Unfortunately, this contract is not ERC1155 so batch minting is not possible.
    // Transfer event will be emitted for each call to _safeMint.
    function claim(uint256 num) public payable nonReentrant {
        require(
            num > 0 && num < 11,
            "Choose at least 1 and at most 10 to mint"
        );
        require(
            num + totalSupply() < 9500,
            "Enter a different quantity - there arent that many left to mint"
        );
        require(msg.value >= num * 15000000000000000, "Price is .015 per mint");
        uint256 numClaimed = totalSupply();
        for (uint256 i = 0; i < num; i++) {
            string memory h = hash(numClaimed);
            tokenIdToHash[numClaimed] = h;
            hashToMinted[h] = true;
            _safeMint(_msgSender(), numClaimed);
            numClaimed = totalSupply();
            nonce++;
        }
        // Send half to EFF!
        // Verify their address here: https://www.eff.org/pages/other-ways-give-and-donor-support#crypto
        // and here: https://etherscan.io/address/0x095f1fD53A56C01c76A2a56B7273995Ce915d8C4
        if (msg.value > 0) {
            payable(0x095f1fD53A56C01c76A2a56B7273995Ce915d8C4).transfer(
                msg.value / 2
            );
        }
    }

    // Owner can claim ids 9500 - 9999, one at a time
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(
            tokenId >= 9500 && tokenId < 10000,
            "Choose an unclaimed index between 9500 and 9999, inclusive"
        );
        string memory h = hash(tokenId);
        tokenIdToHash[tokenId] = h;
        hashToMinted[h] = true;
        _safeMint(owner(), tokenId);
        nonce++;
    }

    function withdraw() public payable nonReentrant onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Util functions

    // Random number generator
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // This function sucks, don't use it. Really dumb way to turn the hashed
    // 'DNA' of each Headscape into useable integers.
    function charToInt(string memory c) internal pure returns (uint256) {
        if (compareStrings(c, "0")) return 0;
        if (compareStrings(c, "1")) return 1;
        if (compareStrings(c, "2")) return 2;
        if (compareStrings(c, "3")) return 3;
        if (compareStrings(c, "4")) return 4;
        if (compareStrings(c, "5")) return 5;
        if (compareStrings(c, "6")) return 6;
        if (compareStrings(c, "7")) return 7;
        if (compareStrings(c, "8")) return 8;
        return 0;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    // Weight function to get a weighted random number
    // Tweaked from OnChainMonkeys - thank you!
    function usew(uint8[9] memory w, uint256 i) internal pure returns (uint8) {
        uint8 ind = 0;
        uint256 j = uint256(w[0]);
        while (j <= i) {
            ind++;
            j += uint256(w[ind]);
        }
        return ind;
    }

    // Turns a double quote character into a single quote character
    function cleanString(string memory str) internal pure returns (string memory) {
        bytes memory bytesStr = bytes(str);
        for (uint256 i = 0; i < bytesStr.length; i++) {
            if (bytesStr[i] == 0x22) {
                bytesStr[i] = 0x27;
            }
        }
        return string(bytesStr);
    }

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
}