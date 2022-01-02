/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: GPL-3.0
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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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

// File: contracts/ProjectSandlot.sol



pragma solidity >=0.7.0 <0.9.0;



contract ProjectSandlot is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.042 ether;
  uint256 public maxSupply = 4200;
  uint256 public maxMintAmount = 5;
  uint256 public nftPerAddressLimit = 5;
  bool public paused = true;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping (address => uint256) public addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "The contract is currently paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "You need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "Max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "Max NFT limit exceeded");

    if (msg.sender != owner()) {
        if (onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "User is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "Max NFT per address exceeded");
        }
        require(msg.value >= cost * _mintAmount, "Insufficient Funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance [msg.sender]++;
        _safeMint(msg.sender, supply + i);
    }
  }

  function isWhitelisted(address _user) public view returns (bool) {
      for(uint256 i = 0; i < whitelistedAddresses.length; i++) {
          if (whitelistedAddresses[i] == _user) {
              return true;
          }
      }
      return false;
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
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }  
  
  function setNFTPerAddressLimit(uint256 _limit) public onlyOwner(){
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

 function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
 

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }
}

/**
["0x801aE573Cf64A3733d51DEc4292464778020CEC6","0xE39f7D36Bd272302661551bEEa94C054000A5C73","0x3d771D6E60Ebb5A719698B57355902cDF92E0CA6","0x7333aAb680200bEe460F4Fc77d3134131EB23A36","0x9e156ab53e2801084145e50ac85f0701fd6ba7cc","0xc97b85ffdf68f86557408f2a7888f3464ac1fe93","0x4f68817763FE005da83c6e50A15f91772eb60DCb","0xaEA329e2B5fCC39884132050c632D9A03bA86F28","0x86409963CE24d4d22B11AB0530Ba992F54C9bC95","0x864b26bf0951910975a6de0bbce7be0842d6470d","0xc3394a64b9071e415B1AdD3c4944DCB5Ec93936D","0xCdB5A26B43e3c7A4d16e0F33a5410963700713EA","0xF4b3fB72dEA3569548697505e7A6f133BC1A6b54","0x9e156ab53e2801084145e50ac85f0701fd6ba7cc","0x67c772d5bc77ea0c32a1bfb9881950ece11396ce","0x1d5f2d9ce618bd6596bcaf37d843a35371033936","0x9E3c116AAAF1b453fbf6a5A71ddA7A907E38BD39","0x166876d8188b736E8F596099641Fb54c2Ca9D020","0xFA0FeE5CDC732ea135ba99Be35990D2C72006e40","0x1B6697f4817B9806063Fe0c4B04F6a2026EE5A97","0x55A83a0c8731a23F4d3B8FDf7E9833092FE59BA5","0x6E1B1548960711Cb7d2FCc41C97B3D93E6452974","0x5E9f96ceC38B684BeE7634244a4679Ca77df4FAE","0xFc0D94352de289174B0F03a45c532E5977eb5a1f","0x1C9c8d9429A9c113EC9Ab1f228bd15dE271e1757","0x39AfaF2431b33f8812E50FC45357022db7d3dAD9","0xE825dcD630aB478ccAC708a8b1f6Ed5Ee7D2901E","0x700BffCeF206B488f6bdf203CEa8C896ED112AC8","0xa5442b7eEBe30Ff0c72d8aaF3c03E9c19271FF12","0x68C9066e14967dC72e3Fc62270209d8FEA3a719c","0x3d95b53fbdF1F390Dd28CEa74cE519659Ccd92b4","0xa9298aa95B72C3aF90ce500024918230C17294A3","0xa981de1e47Eb42603D944F4e3Fc64F49787fc9c9","0x504D086811Db2B720cd51443F2b3d497743086Df","0x9a75a30ebD0fCe2ffa00445007bA530E334066c7","0x765022C21943cfCD76AE0db5e545EBB6f8122394","0x3Ce470B8Fe17348533Aea293a4E97E6a57a131fC","0x5D3ab04FBD50F0DB3D0F13e9C22F7E9e0431A0b8","0x8941F736d02646cb45A23b85B1f3310734841308","0x93a37FafeA759585B0D616bd06b384544E03E17D","0x5838180e009fe46878a127f5f8e20e572276f73d","0x37e1843574cc8d750c71275602a4e001a6e0f492","0x38d3a709357f0d937456b3ae66cf307ee43d23c4","0xaA5Bc6A355089899D82CEB417f914022Fc0FA9cb","0xc447086AE080b9Bde4c369E6bBCd668a247E9fb0","0x09994f7f7108e358b0d485ea5bd130948692f29d","0x48f46281777fb384b89EcDFBca3283ba304d6207","0x45530fe88321fF6e6F1Af604901bEcb8DfB8756B","0xe80d75e8fa54a77188d712e70ddaef0a81c41d29","0x71d2A5913d062816CB2e16947642bF40A32eAD61","0xDFFdf1262377f46866DFEAC3E9598e85b5388389","0x8d19Bc89eB4d694FbfE5eDF35FbeB18FC82fba85","0x596aCd26e6381Ccee76d8A012dBE85E18DE30f8B","0xaF612f60a7dBBDf3487B051281b2cdd8090de060","0x59F3B5B3A2a8AAC38975C233C55dF1cE7743891E","0xbb63aE1f22d66628E341D3a30f784B4292cB2a13","0x59032df1c9d4694488468B6C7742B0b621EADC0D","0xb8cbC55eAcE480F7A838c3a29c4FcfA8aB4163c7","0x3271160Da8311F3dD142964d09E2285484eF95B8","0xbDBBBbB06ded0514Ee8155edd434d6697f66B111","0x7905E599c18BAa403f01d90f11A097470aC306c6","0x64e06c110921052A6eE90a30D92F5133783eb019","0x3a4bBC8222fc21b82e3465f59b6e37BC52392160","0x58a532DDFf8fDE054603a683358a98e98007CcB1","0x6536FeD97dC52568D87c6491ddCbE77643991A7f","0x32492340ce379Da400dE9Db18E49F09c2d9503Ae","0x031134288bB3d4030ACA276A56Af290dC104B3b3","0x2a90Db4494fbA546fCbb3d1F9e7E307021A507c9","0x4CD39A3Ab0307B51AeeF3335Fc6259f4181E179a","0xd4b8C8e98386BcFdc52cd71835e21864ab97Ec76","0x8668F8B1542afaF8FF314E763e729CCe128Cc535","0xFaE6F92378A5b23fcccc19D021F2B2E586F00870","0x7ddb9F9e242b5C6beD3468542d8948fC0Dc68a86","0x4e6532bA8773e6d602DE8dc1ef2DF7cb1B97BD96","0x7EF30E206d0aF8681189dF0E45d89BF9660F7d17","0x47e2d2ef5d8cd3bffad8eb01b793e7de30e62345","0x9f9c17cd2Ed0a19cF4c77Da78559eF16e09EF4Db","0xC9598d75d4E1cEb96714d1AD1474dA5f4Ab52bB4","0x42BB83548AeeC60cee878d36D1110DAff479bF4E","0x5A9ddBBAcE01340a0095D5406d086929168d5C15","0xc97b85ffdf68f86557408f2a7888f3464ac1fe93","0x8d2ed328F87Ad0400641999C0Ef8157e4d54a6df","0xEc744006A432Aefd90127Ef36e2283A92ce2187F","0x6dB6c702fA5E74BDf21794504B3F35d21B205A42","0x1A621CE0b8a22335efF6FB6E17EbE9512c62967F","0x51e25ffA17A7f4b39057B86e4Ff160281C798fAD","0x7166bB19dbdfCA1587A5b245b73199B54d2678A6","0x5Ddc27447F1Df6184c9f13B935335b31367a4fe0","0x7Ce0d3E1D44EE9fD85Bc4bF15A8Ede0E101e2297","0xB67770530650CeE2f0e2862b50408D5B3d18F6BF","0x194b7eaef8d1876748f8b3a880b592d8da93a7c1","0x04295BA1d19e601d69f4bbdB9507F21E8590b8c1","0x957120b809aA71f4c74d5DAd406Aaf01C8994DA0","0xff6e54fce4ca04b21cdbad1a08fec7826fe0e5b5","0xa753b6f22fd72357edd50daf248a641c28bc2ac4","0x62b29c8365ea81E3788a78a0b5BBfcEC7E2174E6","0xab71685234f0807A57B33b3b55e0cda120d7A3cc","0xc5839F9098975e90B2560f76db18C659412052E1","0x8091260ae8d1AF378e57497a013da6607a5dc6Af","0x30F04A9A124972D91c9A31a64b25049288ed27D7","0x7A8bd70101F51908d83A8eff785f167f7142aA07","0x485cf6EE90a76269b40faCfB319BFCAA42CBE28B","0xEA0C03f67D457660Aef3F917013DE93cD760C4c2","0x3e1b4f49837c73849812af57abbb1ec570dc5bc2","0x362b28743eC677f56e3Bc8de1067fAb4Aeb31F58","0x0Bc7De18782B662a686822566D776e1d6139b016","0x55E71FC1a5A68ab2E420368147a210027B1e3b9F","0xAC21C8524f3E2248d85dfE1fFeAc0F716F04A91d","0x7775a0e8b0de121aB5E0eB56b53498e86814a2f5","0x2414B9308b2a468FC7DE7c3e0e632613e4c55AcA","0x2941b21c352d3d1201079284230cf15ddad590d2","0x05eE8576807ed52138c5b2983e33539bF104C264","0xD35cA26A6e25F954EC3F8b4C7e9552B6c7Ff9EF4","0xC3f0496B59F720a00c0a31B5114ac0698fdF0896","0xa0b87e0d3e301e4de876a2fe2fc1a72a71d9efce","0xC469623A43a420664E8F5e2c5D1B048e46F507ED","0xC365B481cD9c3a980ee92B3ff4C754150A34f2Ae","0x43C59a0B50bf8893af1f9aA1Ba3888d2d0b7c898","0x75F142Cbe6715A0c9b305584543AB7f9B835cCaa","0xf2441a4dad2060434ca5a9c2d053352e63bb72bf","0xD3d6b9dA01FE75522A0BED1301F207CF8DeB0602","0x6be8EAc932C0e0b95040f1ccf7209A37331d4109","0x25A304E4d1eAeE5C2eD3381F9D7ccD102b5DD24C","0xfaE7604CFB91B4ADCCB27177065Ba00eA622bdd3","0xe97c8a65bfaf3db6491181d8aa1dcca6782b4e85","0x8a65e7699c853c1dbcc910b09e61e1f8359ee5d9","0x65dABfe189e7d6Bd5dE97EE1a88d3cBEb319a9E3","0x754C6EF6e5cFE7D740B3375FB3d0a7a98b2A6b0e","0xb3ec944aC209aE896378F6d133A42aCA07365069","0x7886DBA2263D1fCF912199Fd064D591ed40BA6BC","0x061b6e995246c30c32f403639f72224d0a06a25f","0x7b5453c76D508208774e2e5a78f68758E9f770b5","0x3d6F52E22eC933F848CAdfa1DEb0464B4035758E","0xc838a6237dba14629212276cc28f017929a096fb","0x560bDF9419DEc9Fd66ff1FBa0F91D669bE116952","0xb0abd5e82d81ad7a69d0cfead5a8e0d133717fb5","0x1F2cdd73135473716F3408b25B6fe50b067f5a1F","0xc91338f3312b3540edDBF62F726E5780e4f421Ea","0xC60972c01325292eF315cb0Db78C2B07B0Dff273","0x50e7811c95698af9ad4b630351c0eb94627383a7","0x8d8ccb957763afaecba6a906665ab1e237d99fd0","0x7bdc7389A344Fb92C45d2a059b2D4C4F5B6eeADE","0x99eE4CC2a252BCA34578225EBc603A6f0978Bd78","0xceEf176dCfD70408160663da7015d9F1E48a8B49","0x8C3c2C2e7719a74cD42D53218b9E6E8295B3c584","0x8c60c18820BCa32e75bB96322292D4A85d6bfE31","0x285Acae09291CFBc7980619aA0c0166a0dE39bA4","0x82515A0B21BA2BF8C711050AB6F0E1522B03d12e","0x1D7fcc8697faF3ffBFc3797B5707E709758F4333","0xf5BECB24d4cC6F910D26218B05ba6C8B7E7F4052","0x8044D05D8B87213A92a6D4DdC1A212c1BfD1d818","0x9605879A4Cd2c4307825780E14986a04604fE68D","0x50052c2F571b36e68371958D01534eBc98c8f91B","0x17C3aFaD88c016d1807eFB7E7528E5bCFDa70CEf","0x147DffA9e729DAa9054c296C163Df0c9F937C01d","0x1b8f0495f81F9cA0a48d3839Dc94e54284B42705","0x6F69242222a16781294A257d1fd399B8551Ce468","0x8EB8b0787e019EBa0b4c516a9A0054d884Fa3A06","0xbDB5C7752a36b60578d306DD4D6b9Ba93723Bb6e","0xF30052A6217aefDB1624B9745ebCEc1EFDF8c20E","0xbb63b721ba41969bc4d740d7ff5c260290894122","0xe9aB6182a9991CcDbD7a03A42057670a4ebbb464","0xb60253BbF2614c00F99bC100aFD0CA0BE5215cA9","0xa88C37d634679BC892AA3d5c8B7a28604Ab3Af8e","0xD4a681dfc8652aDf509599267b6C03ad11e0Ea1d","0xC46ed81C2502bF6751B692CdeA3Da75Da800A532","0x3D6e177791F02298e29516dd95085Cb1200C2B47","0xf0585696abA6BE68E4f99473607C6db0CDD08FAE","0x9f062cf88456ac60f873a55dd95ea81d1d87b548","0x6563Af1eD39167F9655d31380b7765BdB3957099","0xa91efC789Aec492C37325535764a56334E3269Af","0xaD31d108723a2d0a4a05E1A5F2df8719Ba297834","0x74aCeC96591cF1852f1836F7b65C67D0742b1907","0x8f5212b02d8460abc259565764039bf042680a53","0x7c4d66195c8255b418d41b1b2e83309162ac806f","0x021199ba49F344A3CbfB0D88d086d5A561e532DC","0xa4BFc58c2237Dd448ac1dF6D7d44978eced962a1","0xeFAA0ab976e8628e19B1bAC6B2334E1D6AdA789b","0x7ebA3Fe8f6ccDbd8c81632E8d1b29C6cb3223258","0xC4DaF64B51b16C25a7015F878EcD9609a295E19B","0xcfEB94769C14949334f1d70DBd720D4e905e6C14","0x63633B39523DF3aC2d64b355C5B18B3402035Bd9","0x7f107debb79b15aeBecA39c584aA71B22871f560","0x0A133944166Fdb5dAfa29534a33D6c7709885516","0x3abD78aAbBdC35984Ec7823BD51e77a1Cbfe2E73","0x4ae3fa85BF419FB30Cd5bA1b0604AD295914219B","0x1AC4773d9A0B626eA14a152f6e4211588935E49e","0x8454bB21aFF9c6108c19571C2b2cc3b8cEEb1850","0x26504c6C7aAf26fF1ff69B7025A25EBba2610137","0x36011fFea941cFa6d8fA8c096270375E42804129","0x37bf0519f152a3aab7f13fbd0b92486e9f5d6a35","0x3211e1b58164F56Fd5fC5dD9e108aa34f1c298CC","0xEe4ca246Eee0C11cF98D9534f5B8262f058B1d5f","0x7627657ec44B108434b1E4aA54e1Bb47f4eC049e","0xa15fd1b0289e6fc90c152cf2450e6b6d2f419b77","0x3F036A9755f16F9fE548D92f08DB36ce9CC1F9E3","0xE9483b66F9775B7B02a62E1D9e09836B6d2a4b3d","0x8d48aD9cB1289f21279402b4CBEC4c54eB6DB7e6","0xf947881415a63cc186fc3706e615a8bbdb87c912","0x294241337c0c09ea33bb0aa9502932b4cbda704c","0x361613Da3F6082F650f2152C49eCd5BF2901bF12","0x3d844c391e7806157aE42D653d1D7E2919926a61","0xe27247481ca9AAA5518da004e030D1fa6C465986","0xcc160544e55b2E9d2b30d3FF32320982712f7639","0x5D3CAAc80F527D5Df48bB66e46086f2B36BC28A8","0x21a002acfac6a3433f313ed5622cab05ab5499f0","0x0845e294019E41662E3292426A8CA0F71b54Fb8A","0xc07fB98300C41120E5Bb3F4641e6Eb82f9DC0aFD","0x628ED6016197Cd6Ff0b3a8c285BA4AA0744c20aC","0xdb6428c5fa405b9ba438bba5c1c2c4f099684004","0x21A05ef2659993D556EBaD4bd6dfaC27c50EC863","0xa151A5fD66C3838B8D295da4Da60d96c6162821f","0x55D9FC8D5f84Cf151D9578C6713A0c0eC35E0e5f","0x00939Db1c2ec7582b56A3e89dCc6D595e252a6B9","0xe4D876257c2Ad0857337234d56dF5298C12D1132","0xeCa5D0b717FbC513802Bc809b2F4192EEC1821c6","0xE8c6a4CA74c43445a75330556Fac7e3f1E06E3c5","0x9e58DB24680F47d932a7e0D60a55E053425ED387","0x3e486DaE19407c7772030a0fC3Aa689ED92B8c49","0x64517d6c504D02F50089cc30E5F6A2E7280964A5","0x61d022513732Cb9F034D5da7DA7811D9353f1B78","0x4b2f318c82D1A94a01a645233Fcf01F5E811Db4D","0x0F1265b60C1ed1a21F689ebC1E52cD3C24724649","0xC0A779ef7C443A3A7C8E03B49ea97372f6D32569","0xccCF5493c75860d998b31bE68B8aC188a30FC0f9",
"0xAd79ae126b2644C5B8C0b0C1610Fc24bb4828DfF","0x9aA55526AF86a95f477A1940Ab9B296AA5B5Df08","0xd683a7e18b9a2f2A55BdF58b4C06F46f2dDaEB53","0x441311060454adc0a569f1fc425ec6a5741003f3","0xb39a7f6bfb506236bb1049c9c2404e845fcb455c","0x08646201768fcd19b58a34CA012b5BaD75db3870","0xef486d5B9f4859107c1795E26f0035718E0b09a3","0x4ebe485c1df060f6fc6e3c3b200ebc21fe11a94d","0x8eC6e0f6239703604C344Bd6755e1C7b6a4d5988","0x32bfac34fbc1fc356c79d07971e7f245ec1d9bca","0x4F97066b22875CC666739928c48C328A39d2C9B7","0x54ca169cD926E0284a08f0777068D88D51670A36","0x840baA2595f45c3080eAf48B4bfeaD40Ccd8aa23","0x0a89e15EFCE55918a8Db221b6DD7Ae2516D3d77f","0xdd33f858213217a03ca150633da5dfc8f6d52850","0x9a0527f463C66FaF4d16f80607DFCd94075D88D7","0x762140ccde6372e9ebf99da144e78331c3936931","0x770C9AC2E2710C82fBab6049E97DAC7f17015E6a","0x823EF5455faCBE1e26A072714bEdd5071c01d27a","0x4f4b83f5157960fa566b5ae8a3dbd720d2e119db","0x38CC4b2eD70f9D44aEBfB48e84cE98ed42741F75","0x6f20Ca4ea7147D238df7ebF16cF7Bd55cA849573","0x9b930C9289F4172Ade3Ac4eA0bc508c3eaeD38Ca","0x136f8e2e4de3F18fAd5aA9Ef6167A3aBD748D8c6","0x859eAcdD7fC775c0F1ba12CdCc1e88ec6C085e94","0x4f9499bff005309fa809e5557f32a35cf31b1e98","0xe5897d53954e8e7b0491c52c0b6fb967a117aa42","0x1299ebbd37b485dcc1fc2ec720671cb97f65a069","0xe39f7d36bd272302661551beea94c054000a5c73","0xeDCdDCd24673C97b6DA5508Bf918Ab82eDb18E6a","0x20b997184e5C0c11f7a67F313Cc989d496B63774","0x83d98b8BdeEF5CEAbEe93d37075D63c634fF1745","0x0fc4c74ecc85169dd1bc87d088f06c586b6d78b3","0x0A67595121228690D7a550ae0ab9F395368aCfc5","0xde7B18949997c0B41F8dE86987278c23d5242d85","0xD29BdaC3BcAA96b2F2E60675d4f0F2a3Bec1551e","0xfbac3516677cc50dea378bc6452377e3bdfae7dc","0x85a9093fc93b12ED9Fbf3a9bD56eaFcB0125d29D","0xE3aC02F59D2014A43475B7b8D457cE2331b3e6e2","0xfC3b273Ec8b57867bB13251989bd43E2B7C28c1a","0x4C75a149051355781Da82aE9364b8Fc884e2d309","0x9EB177785aeb034bf46481ff7C56F4E94f88C9E3","0x5802f2ce3ddf754a84a9602095410b49cda44682","0x6e85E758AEd0e2a452607c7Ba1895a03c8500750","0x303CeDb1a88e0Fd09594dFFCb43ea1AccEd7C842","0xE9EF2A9652D6207beFd0B61C3b3917f5a226008B","0x7bF5B2dCA8C3975D516C999b108D528A5238C2A3","0xde60d6ec63dfd40f1014f1173a2aa3659cd7710e","0x82d1b6ae058c62a9ea6648512fb2ea84f87399f7","0x651aa29ccbaff0ed91300cfd4ffa4d73e617a006","0xE02789c5A804e178754D868Bc20499a2DfD4b038","0x5C6019f08844d755dE46A650DA1e4E50f440B970","0xD01c98b8dB1A364a9c37FD213F18db32294e2E2a","0x504D086811Db2B720cd51443F2b3d497743086Df","0xAefEe802A4b29b94963Fe62a3DD490D9C7f34c19","0xa897c9D9482037C5B40C91B230414F5A0b70F701","0x2f157a5723ef081f5180f0b76785fd40d4a5e675","0x1376D82C20Ad860E8d9A3a7389a62974732995ea","0xf53BB1c82f00fB842750287FEDf4C1D92cB732Db","0xc447086AE080b9Bde4c369E6bBCd668a247E9fb0","0x4b91a4c44fe9a0e4fB18134dDb4572c932BFAA7A","0x421CA4bA76828d61926EB0Bbd00c5205F70A922e","0x385b98E94d2D15E19B83C14983ffd2cA2E30342e","0x566538978e11d716730ad62a519ee7c9aa595b10","0x3343CE7d8410cc6Ff906b99D5c3a3cbDfAEA3ab2","0x49DF9478bcbf1867b6cDFdC667AD604E3744B6ad","0x63633B39523DF3aC2d64b355C5B18B3402035Bd9","0x5FbB94e984e675e52CB92Bca9a72516a725b5064","0x1890a1c04c66a42BE26b8Df121336620B1137b45","0x333d2601B1bcd456B79ebd07d79EA66B33004164","0xa761c9301407a36C6b26D5F4b9393f5Ab601717b","0x686c83B39bB744a455d849978Ae32cC3D50D694D","0xfA5E2931e3A48209B5D0d5D8F857f97f1818A87B","0x1376D82C20Ad860E8d9A3a7389a62974732995ea","0xD5Ea006057772C428A4718732523C4772f466A37","0x1f27eCfEa2c6B575560955662166D2781B0c5111","0x3D6e177791F02298e29516dd95085Cb1200C2B47","0x455237074B7dcf29eC3303817E5A51C74A2c253E","0x0ad0e4eA5B897dCD30752B511316972ACC7dA016","0xe202b69DCCF5883C4a6D605d3dBdB6F30858b80e","0xf8DF491Ae6d454461bE51306440A74Ef94C59788","0xcF3694f4E76837Fb5444b9bd93724212e449eafd","0xd2C67689a0033a53DbE3392d89cD6175d4b5465c","0xDb6428c5FA405b9BA438bba5C1c2c4f099684004","0x64fc678d17baefa06d96e214544d5d82fa8f1734","0x09cCc5EbAe37a0ed322649ae03Fbc5cDf9683508","0x0c7cf39362441d4637c9434a764241d6f31668aa","0x62633F5670DfF2eA044DCDf3FD27168e9846Aa49","0xab897f8A63CAd6d76D91AA799eEe5903D5367021","0x9B05E02F7d1639c54C1BD6980eB64A11D2cd708f","0x3C841eE6bf7b6e7546b6EFc04B356504727fEF62","0x11436EE79814f04b71594D651E8A23D16f0eA519","0xE0f2c379BeDc3392bDe10f8352Eb51340AD35405","0xe2545B6138873E3b7cDC12e078d3fc71a165092e","0xc9d72cB5d19a1FE78a144f7FC80531418B6b67D4","0xBdFC087A5C32F6B6E425697c1A19a10E378136eE","0xb9950696E4EE05Ea2030C3eBcEA9a4a8f276F746","0x8bb8fc35375650d38fe68b026bd1a38a14ccb551","0xA8fBe0452eedFC4598d4C64C33615d942a70Af6e","0x8f289FDee17AC14fD4F6Af03663Aae19A6959015","0xfB631e9cA881bd9cbd717B1D211a420Dc32e3352","0x4C68f443036faA64a200B0c6AE654D779D7b6969","0xDcD082a4520929dcE240cD1E5233339f7e15c661","0x3b826A060319E5067883887153b88Df04f2FF0D4","0xA0E3387Ca51f6a5877F52Fe2FC70aDfaD15d6B63","0xe4254cf33F8E1276549F010989dE8Eb9251Fb917","0x1b19fCA9EAD4248BD27b26ea135194Fce270c440","0x003960E60110FbD8E2b790f1dB1948A798258016","0xdbe5bF83415D69344C451438E10e4Ce4c7Ad3868","0x39e11416c6A152850b7d27F9899DFC179b865cAF","0xb433f89264aA9300A1EeFe799776fbd53719D82b","0x0d8C5e8a3399A4f98C744d32A7aDb1613c03ee04","0x11093F75cd269327ee966770EF308b4269d146Ca","0x380606e57b28C11aAEf06217e5dD8F94A75F6BF2","0x3DcDf0239911954a4b30A38818d3D35909b3b110","0x3DcDf0239911954a4b30A38818d3D35909b3b110","0xD0C34b90B43A2A2e6F7929b6D477e846D5Ae7BB6","0x527Cc9cFBC3d9dcc6ecBe318eA87E9E25cBD114a","0x12d4182B4125fcd4251302c034613daaAdA66396","0xd8a75Fa01e12Afc0223B5b394e0a03d33A9589a5","0x53a245D400ceba92dE13BB24efE3C457A2146A63","0x104C411E9acF483c7d15FA246f21A516c9DB9504","0x16921f39b5172d0E558eca9f429CaE718C6c2cc4","0x2fDCDf5BE7683c6000b93DaE4EeCcaE8F4c06C0f","0x570315A30684Db24221E43dAfB9c5FC3c63781dF","0x2d91C4d517443F3265726F00BdEa495769E8C5Ea","0x75c8dB318612FA80b39bE6169C108A4AA417098d","0xd160412d3a9ac2c9488ab877f08be9d49ad5074d","0x4376B9A7558b20BbD9700819859BD3CbEec02e34","0xe9b0F81Bd05A232F9153fb7e23A752dC467959dA","0xcdBc8cd9299808F377C420d2E9fb6E6076F6ee81","0xC1e5f5D34630044aAa08fB543F77d16714E74b14","0xf1a9b96032aB9898B7DE9738b77aa8e3211A4437","0xb197C4EB43029B9D80Cb72Da90366D8700399e1B","0xAdD448f2F1603B810762EeBEa7bBE893002b7b08","0x950DFff6C1E00c05491774e3883316e6895B0DD1","0x9ccd56aa8f9a1a39cb98331cc40804f70c1af5e1","0x7187B2eACBE4a878876A9885a04E111EAE5C8286","0xeB10b8584b41ff0961f519bBe76504679CD22c65","0x909e9308ad396eC9b6cff99a3F8272E30df47071","0xd3F332cF93Cb42dBF4f39dF4001f157165eaC1E6","0x4d331aCABA7138674fD7c5f9C214595010aFb54f","0x08908d18DDD4dbE255fceB3762EaeC37eB68B61D","0x30156BF005f98CFDee572C96E7ec946EfF8282F9","0x37c9494dc38DD56236D857F2676F8B61Cd67bE2f","0xC93620784FAceae8B644C905de0eaB95A68cb45e","0x843af2E0B80bF12843549de413353634BC4fB702","0x617fFB54868076B7E9ac5f527c80a920bd295C88","0x36BEF46Dfd4E17f9c6CAE37e408540DC7C6527d6","0xcF1561890d28eae36194E3A589E77B2E98de2F80","0x177285a6B63Aa2F01D6914432a35aDf0855b5Af4","0xbb1b447a421CFe5F8BceFdFc501Ec86d3f0b7CDB","0xA72041Df6391e940cfAeE65A6a04bB73de1D6787","0xc59f7a2c055e594b7088cf2ab13111e68c6b2036","0x508Cd390E93853748Ee1BdEf0ae326E12e390cB5","0xc37FEe96390421274CdaE6515427da083cb638F8","0x792570f2775700a2ad7f0a3a0a8d834491713bf0","0xcFE0FC16bAF9459E9c7F4f0234A04Dc994580D0e","0xc5AA32182a7BfcCBCAD5907A334DE1957CE4Ccd6","0x3447449ACE6691f9D1eB9EfDD2b1Eb847e045D41","0x0B49C3EC016224beFf20D3F410E1F1C508295810","0xfe6814a34dccc54de31bf3a4577a27aee88b3d5d","0x26c03Df4f1710f01F6595e54e6d966506A3eC12C","0x15cb1f0d4cd7925A4A542Ae39c5C742C5d164DC3","0xc798024440b9cECBB3C8F8Db40C21B7947C6B2F9","0xC109d5Db062C15544129Df5a4f20F7c8CFFf57F8","0x8537643CC87d0f88E9CA84BF951E46dBb96b333d","0x15F202D284e777E0df2963da6e31F250Eed278A5","0x760eD8aB2d44120FEE69F794B6A38154F5Ad2d2F","0x65f63255f230751de8fadb2c9469398b888aa5ff","0x562f6ac10723ef6af9f077a83cf25135fb369612","0x15F7C941287a5Cb1d2303dbF34Af1cD7DF7A5877","0xC721777ede7d0133D7302d8D464e073a5244Db07","0x9eCde9196484527388E3e05cC2fb5efD846ED498","0x6E0467F35fBE9F94E90A1cF57de72e27F8694D3D","0xB26af1D869B0e240F7701061892B68456344Ccb1","0xCD283D906Ad26efe66390Af164ee9332FFBA61b0","0x31Ea254A433b013fc3E848549b89D5Dea5459d54","0x98b68f4967a242b13F9253a73A0Ca7d65cAC7e13","0x9b0d58C7F636Cf97b289D8CD4e21E3a0d1A30320","0xc78787b9b422679fE55F8E093ff355FD6C3765F9","0xaa9120109c02f48d24b9f48f6ca6db46cf82c2e8","0x277e03AC0911AfBE52C004F1D1a42a83d1dDad12","0x314c0f3e51acb3cb5af5665a00aa4ef87bc6f4d1","0x050D2364f1241cb8380B7bc245fbe0561651112A","0xF6F3a98db74cB159550488660AA5B616b7B019BC","0x25cC8Fa0A46467a01f6ac33EC78360391D7b0C6a","0x3C469cbb8A35d753abcFb364b121647a4E6FEbc2","0x25c9abf0e3135368d5d7ebc3b82e94d59233d5de","0xd1907b6f10eb35006f701b749df93d9812f23c48","0xE6bbe9F9F98369bBAb70BD6308C9C522734cCF83","0x6D084D38dD12c1F44c0Ba170145dA70cD57E3907","0x34929bC7065B3E433cE1c1f097B9D25a573db15C","0x15cb1f0d4cd7925A4A542Ae39c5C742C5d164DC3"]
*/