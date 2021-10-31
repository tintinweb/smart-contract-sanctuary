/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: MIT

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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


// pragma solidity ^0.8.0;



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

interface SIBLINGS {
    function doesPropositionExist(string memory _proposition) external view returns (bool);
}

// File: PropositionToken.sol

pragma solidity ^0.8.0;


/**
 * Welcome to Dimenschen Propositions
 * Special thanks to those who have assisted me in reaching this point
 * From theory to software, I stand on the shoulders of giants
 */

contract PropositionToken is ERC721Enumerable, Ownable {
    uint public constant MAX_PROPOSITIONS = 10000;
    uint256 public constant mintPrice = 25000000000000000; //0.025 ETH
    uint256 public constant batchMintPrice = 100000000000000000; //0.1 ETH
    bool public saleIsActive = false;
    string public constant tokenName = "Dimenschen Propositions";
    string public constant tokenSymbol = "PROPOSITION";

    constructor() ERC721(tokenName, tokenSymbol) {}

    mapping (string => bool) private propositionToId;
    mapping (uint => string) private idToProposition;
    mapping (uint => bool) private idToPropAssignment;
    
    event SingleMint(address indexed _from, uint indexed _id, string _proposition);
    event BatchMint(address indexed _from, uint indexed _id);
    event PropositionAssigned(address indexed _from, uint indexed _id, string _proposition);
    
    string[4] public templateColors = [
        '#000033', // dark purple
        '#20d1cc', // med aqua
        '#000033', // dark purple
        '#ffd700'  // light gold
    ];
    
    string[10] public skyColors = [
        '#000033', // dark dark purple
        '#006e0b', // dark green
        '#1178c9', // light blue
        '#b31400', // dark red
        '#f56500', // orange
        '#007b90', // dark aqua
        '#001e60', // dark blue
        '#940f9d', // bright purple
        '#3d028a', // dark purple
        '#000000'  // black
    ];
    
    string[10] public planetColors = [
        '#20d1cc', // med aqua
        '#ffd700', // light gold
        '#53ffa7', // light green
        '#ff8e53', // light orange
        '#fc459e', // hot pink
        '#ff5562', // light red
        '#fffb9d', // light yellow
        '#a67af1', // light purple
        '#85dbf5', // light blue
        '#ffffff'  // white
    ];
    
    string[10] public heavenlyBodyColors = [
        '#ff5562', // light red
        '#000000', // black
        '#20d1cc', // med aqua
        '#53ffa7', // light green
        '#000033', // dark dark purple
        '#fffb9d', // light yellow
        '#b31400', // dark red
        '#ff8e53', // light orange
        '#1178c9', // dark green
        '#f56500'  // orange
    ];
    
    string[10] public heavenlyReflectionColors = [
        '#ff5562', // light red
        '#ffd700', // light gold
        '#f56500', // orange
        '#fc459e', // hot pink
        '#20d1cc', // med aqua
        '#20d186', // med green
        '#000000', // black
        '#ffffff', // white
        '#ffb52e', // light orange
        '#58caf6'  // light blue
    ];

    string[6] public epochs = [
        'The Commencement of the Empire',
        'The Pastoral State',
        'The Consummation of Empire',
        'Pandemonium',
        'Destruction',
        'Desolation'
    ];
    
    address[] public siblings;
    
    function getPropositionById( uint _propositionId ) public view returns(string memory){
        return idToProposition[_propositionId];
    }
    
    // function isPropositionValid( string memory _proposition ) public view returns(string memory){
    //     string memory transformedProp = transformString(_proposition);
    //     string memory message = "Proposition can be created";
    //     if (bytes(transformedProp).length > 350) {
    //         message = "Proposition is over MAX 350 characters";
    //     } else if (propositionToId[transformedProp]) {
    //         message = "Proposition is not unique";
    //     }
    //     return message;
    // }
    
    // function doesPropositionExist( string memory _proposition ) internal view returns(bool){
    //     return propositionToId[_proposition];
    // }
    
    function isPropositionValid( string memory _proposition ) public view returns(string memory){
        string memory transformedProp = transformString(_proposition);
        string memory message = "Proposition can be created";
        if (bytes(transformedProp).length > 350) {
            message = "Proposition is over MAX 350 characters";
        } else if (doesPropositionExist(transformedProp) != false) {
        // } else if (propositionToId[transformedProp]) {
            message = "Proposition is not unique";
        }
        return message;
    }
    
    function doesPropositionExist( string memory _proposition ) internal view returns(bool){
        // for each sibling check if propositionToId
        if (siblings.length > 0) {
            bool exists = false;
            for (uint i = 0; i < siblings.length; i++) {
                bool doesPropExist = SIBLINGS(siblings[i]).doesPropositionExist(_proposition);
                if (doesPropExist == true) {
                    exists = true;
                }
            }
            return exists;
        } else {
            return propositionToId[_proposition];
        }
    }
    
    function addSibling ( address _sibling ) public onlyOwner {
        siblings.push(_sibling);
    }
    
    function checkPropositionLength( string memory _proposition ) internal pure returns(uint){
        return bytes(_proposition).length;
    }
    
    function getImageCodePreview( uint256 tokenId, string memory _proposition ) public pure returns(uint){
        string memory transformedProp = transformString(_proposition);
        uint imageCode = getImageCode(checkPropositionLength(transformedProp), tokenId);
        return imageCode;
    }
    
    function mintWithProposition( string memory _proposition ) public payable {
        uint id = totalSupply();
        require(saleIsActive, "Sale is not active");
        require(id < MAX_PROPOSITIONS, "Sale has already ended");
        require(msg.value >= mintPrice, "Ether value sent is below the mint price");
        
        string memory transformedProp = transformString(_proposition);
        
        require(checkPropositionLength(transformedProp) <= 350, "Proposition exceeds max length of 350 chars");
        require(doesPropositionExist(transformedProp) == false, "Proposition already exists");
    
        // assign prop data to avoid duplication
        propositionToId[transformedProp] = true;
        idToProposition[id] = transformedProp;
        idToPropAssignment[id] = true;
        
        _mint(msg.sender, id);
        emit SingleMint(msg.sender, id, transformedProp);
    }
    
    function batchMint( uint256 _num ) public payable {
        require(saleIsActive, "Sale is not active");
        require(_num > 0 && _num <= 10, "Must mint between 1-10 propositions");
        require((totalSupply() + _num) <= MAX_PROPOSITIONS, "Exceeds MAX_PROPOSITIONS");
        require(msg.value >= (batchMintPrice * _num), "Ether value sent is below the price");

        for (uint i = 0; i < _num; i++) {
            uint mintIndex = totalSupply();
            idToPropAssignment[mintIndex] = false;
            _mint(msg.sender, mintIndex);
            emit BatchMint(msg.sender, mintIndex);
        }
    }
    
    function assignProposition( uint256 tokenId, string memory _proposition ) public {
        // verify that msg.sender is owner of the token
        require(ownerOf(tokenId) == msg.sender, "Only the owner can assign a proposition to their token");
        
        // verify that the tokenId is yet to have a proposition assigned
        require(idToPropAssignment[tokenId] == false, "Proposition has already been assigned to token");
        
        string memory transformedProp = transformString(_proposition);
        
        // verify proposition is of valid length
        require(checkPropositionLength(transformedProp) <= 350, "Proposition exceeds max length of 350 chars");
        // verify proposition is unique
        require(doesPropositionExist(transformedProp) == false, "Proposition already exists");
    
        // assign prop data to avoid duplication
        propositionToId[transformedProp] = true;
        idToProposition[tokenId] = transformedProp;
        idToPropAssignment[tokenId] = true;
        
        // _mint(msg.sender, id);
        emit PropositionAssigned(msg.sender, tokenId, transformedProp);
    }
    
    function testStringLength(string memory str) public pure returns (uint) {
      bytes memory bStr = bytes(str);
      return bStr.length;
    }
     
    
    function testCalculateEndSpaces(string memory str) public pure returns (uint) {
      bytes memory bStr = bytes(str);
      uint endStringSpaces = 0;
        
        // TODO CALLING THIS FUNCTION ON A STRING OF SPACES crashes

        // calculate number of spaces at end of string in order to ignore
        uint endIndex = 1;
        bool recentCharIsASpace = true;
        while (recentCharIsASpace) {
            uint index = bStr.length - endIndex;
            // 3, 2, 1, 0
            if (bStr.length == endStringSpaces) {
                // 4 == 1, 2, 3, 4
                // exit while loops for strings that are only empty spaces
                recentCharIsASpace = false;
            } else if (uint8(bStr[index]) == 32) {
                endIndex++;
                endStringSpaces++;
                // 1, 2, 3, 4
            } else {
                recentCharIsASpace = false;
            }
        }
        return endStringSpaces;
    }

    
    function calculateSpacesAtEndOfString(bytes memory _bstr) public pure returns (uint) {
       uint endStringSpaces = 0;
        
        // TODO CALLING THIS FUNCTION ON A STRING OF SPACES crashes

        // calculate number of spaces at end of string in order to ignore
        uint endIndex = 1;
        bool recentCharIsASpace = true;
        while (recentCharIsASpace) {
            uint index = _bstr.length - endIndex;
            if (_bstr.length == endStringSpaces) {
                // exit while loops for strings that are only empty spaces
                recentCharIsASpace = false;
            } else if (uint8(_bstr[index]) == 32) {
                endIndex++;
                endStringSpaces++;
            } else {
                recentCharIsASpace = false;
            }
        }
        
        return endStringSpaces;
    }

    /**
    * @dev Converts string to lowercase & replaces multiple spaces
    */
    function transformString(string memory str) public pure returns (string memory){
        uint newStringCount = 0;
        bytes memory bStr = bytes(str);
        bool previousCharIsSpace = true;
        // uint endStringSpaces = 0;
        
        // // TODO CALLING THIS FUNCTION ON A STRING OF SPACES crashes

        // // calculate number of spaces at end of string in order to ignore
        // uint endIndex = 1;
        // bool recentCharIsASpace = true;
        // while (recentCharIsASpace) {
        //     uint index = bStr.length - endIndex;
        //     if (bStr.length == endStringSpaces) {
        //         // exit while loops for strings that are only empty spaces
        //         recentCharIsASpace = false;
        //     } else if (uint8(bStr[index]) == 32) {
        //         endIndex++;
        //         endStringSpaces++;
        //     } else {
        //         recentCharIsASpace = false;
        //     }
        // }
        
        uint spacesAtEndOfString = calculateSpacesAtEndOfString(bStr);
        
        // if string is only spaces then return empty string
        if (bStr.length == spacesAtEndOfString) {
            return "";
        }
        
        // calculate number of bytes in new string
        for (uint i = 0; i < (bStr.length - spacesAtEndOfString); i++) {
            if (uint8(bStr[i]) == 32) {
                // only add space if previous char is not a space and char isn't first char or last char 
                if (previousCharIsSpace == false && i != bStr.length - 1) {
                    // add char and update history
                    previousCharIsSpace = true;
                    newStringCount++;
                }
            } else {
                previousCharIsSpace = false;
                // count char
                newStringCount++;
            }
        }
        
        // reset value
        previousCharIsSpace = true;
        bytes memory bLower = new bytes(newStringCount);
        uint bLowerIndex = 0;
        
        // create new string
        for (uint i = 0; i < (bStr.length - spacesAtEndOfString); i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[bLowerIndex] = bytes1(uint8(bStr[i]) + 32);
                bLowerIndex++;
                previousCharIsSpace = false;
            } else {
                if (uint8(bStr[i]) == 32) {
                    // only add space if previous char is not a space and char isn't first char or last char 
                    if (previousCharIsSpace == false && i != bStr.length - 1) {
                        // add char and update history
                        previousCharIsSpace = true;
                        bLower[bLowerIndex] = bStr[i];
                        bLowerIndex++;
                    }
                } else {
                    previousCharIsSpace = false;
                    // add char
                    bLower[bLowerIndex] = bStr[i];
                    bLowerIndex++;
                }
            }
        }
        return string(bLower);
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
    
    function stringToUint(bytes memory b) internal pure returns (uint) {
        uint value; 
        for (uint i = 0; i < b.length; i++) { 
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                value = value * 10 + (uint(uint8(b[i])) - 48);
            }
        }
        return value; 
    }
    
    function getIndexes(uint initial, uint index) public pure returns (uint) {
        if (index == 0) {
            return initial % 10;
        } else if (index == 1) {
            return initial % 100 / 10;
        } else if (index == 2) {
            return initial % 1000 / 100;
        } else {
            return initial % 10000 / 1000;
        }
    }
    
    function buildString(string memory _prop) internal pure returns (string memory) {
        uint256 j = 25;
        bytes memory b = bytes(_prop);
        string memory textOutput;
        
        //calculate word wrapping 
        uint i = 0;
        uint e = 0;    
        uint ll = 37; //max length of each line
        
        while (true) {
            e = i + ll;
            if (e >= b.length) {
	            e = b.length;
            } else {
        	    while (b[e] != ' ' && e > i) { 
        	        e--;
        	    }
            }
            
            // splice the line in
            bytes memory line = new bytes(e-i);
            for (uint k = i; k < e; k++) {
    	        line[k-i] = b[k];
            }
    
            textOutput = string(abi.encodePacked(textOutput,'<text class="base" x="15" y = "',toString(j),'">',line,'</text>'));

            j += 22;
            if (e >= b.length) break; // finished
            i = e + 1;
        }
        textOutput = string(abi.encodePacked(textOutput,'<text class="title" alignment-baseline="baseline" x="15" y="330">Dimenschen</text></svg>'));
        return textOutput;
    }
    
    function getImageCode(uint propLength, uint256 tokenId) public pure returns (uint) {
        uint256 calcCode = (propLength * tokenId) + tokenId + propLength + 1000;
        string memory imageCode = string(abi.encodePacked(toString(calcCode)));
        bytes memory s = bytes(imageCode);
        return stringToUint(s);
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId < totalSupply(), "Token id not yet minted");
        
        string memory tokenEpoch;
        
        if (tokenId < 100) {
            tokenEpoch = epochs[0];
        } else if (tokenId >= 100 && tokenId < 1000) {
            tokenEpoch = epochs[1];
        } else if (tokenId >= 1000 && tokenId < 7000) {
            tokenEpoch = epochs[2];
        } else if (tokenId >= 7000 && tokenId < 9000) {
            tokenEpoch = epochs[3];
        } else if (tokenId >= 9000 && tokenId < 9750) {
            tokenEpoch = epochs[4];
        } else {
            tokenEpoch = epochs[5];
        }
        
        if (idToPropAssignment[tokenId] == false) {
            // return template token visuals and metadata
            string memory output = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><defs><linearGradient id="rectGradient" gradientTransform="rotate(90)"><stop offset="69%"  stop-color="',templateColors[0],'" /><stop offset="79%" stop-color="',templateColors[1],'" /></linearGradient><linearGradient id="circleGradient" gradientTransform="rotate(315)"><stop offset="10%" stop-color="',templateColors[2],'" /><stop offset="90%" stop-color="',templateColors[3],'" /></linearGradient></defs><style>.title { fill: ',templateColors[0],'; font-family: Liberation Mono; font-size: 22px; } .base { fill: white; font-family: Liberation Mono; font-size: 18px; font-weight: 300; }</style><rect width="100%" height="100%" fill="url(#rectGradient)" /><circle cx="275" cy="150" r="50" fill="url(#circleGradient)" />'));
            output = string(abi.encodePacked(output, '<path d="M325,150 L100,150" stroke="',templateColors[0],'" stroke-width="0.5" /><path d="M325,155 L100,155" stroke="',templateColors[0],'" stroke-width="1" /><path d="M325,161 L100,161" stroke="',templateColors[0],'" stroke-width="1.5" /><path d="M325,167 L100,167" stroke="',templateColors[0],'" stroke-width="2" /><path d="M325,174 L100,174" stroke="',templateColors[0],'" stroke-width="2.5" /><path d="M325,181 L100,181" stroke="',templateColors[0],'" stroke-width="3" /><path d="M325,189 L100,189" stroke="',templateColors[0],'" stroke-width="3.2" /><path d="M325,197 L100,197" stroke="',templateColors[0],'" stroke-width="3.5" />'));
            
            // add title text
            output = string(abi.encodePacked(output,'<text class="title" alignment-baseline="baseline" x="15" y="330">Dimenschen</text></svg>'));

            // Add metadata to json
            string memory jsonMeta = string(abi.encodePacked('{"name": "Proposition: ',toString(tokenId),'", "description": "Beliefs are not private. Beliefs are not free.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '",'));
            jsonMeta = string(abi.encodePacked(jsonMeta, ' "attributes": [{ "trait_type": "Epoch", "value": "',tokenEpoch,'" }, { "trait_type": "Proposition Set", "value": "false" }]}'));
            string memory json = Base64.encode(bytes(jsonMeta));
            output = string(abi.encodePacked('data:application/json;base64,', json));
            
            return output;
        } else {
            // return finalized token visuals and metadata
            string memory _proposition = getPropositionById(tokenId);
            uint imageCode = getImageCode(checkPropositionLength(_proposition), tokenId);
            // start svg
            string memory output = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><defs><linearGradient id="rectGradient" gradientTransform="rotate(90)"><stop offset="69%"  stop-color="',skyColors[getIndexes(imageCode, 0)],'" /><stop offset="79%" stop-color="',planetColors[getIndexes(imageCode, 1)],'" /></linearGradient><linearGradient id="circleGradient" gradientTransform="rotate(315)"><stop offset="10%" stop-color="',heavenlyBodyColors[getIndexes(imageCode, 2)],'" /><stop offset="90%" stop-color="',heavenlyReflectionColors[getIndexes(imageCode, 3)],'" /></linearGradient></defs><style>.title { fill: ',skyColors[getIndexes(imageCode, 0)],'; font-family: Liberation Mono; font-size: 22px; } .base { fill: white; font-family: Liberation Mono; font-size: 18px; font-weight: 300; }</style><rect width="100%" height="100%" fill="url(#rectGradient)" /><circle cx="275" cy="150" r="50" fill="url(#circleGradient)" />'));
            output = string(abi.encodePacked(output, '<path d="M325,150 L100,150" stroke="',skyColors[getIndexes(imageCode, 0)],'" stroke-width="0.5" /><path d="M325,155 L100,155" stroke="',skyColors[getIndexes(imageCode, 0)],'" stroke-width="1" /><path d="M325,161 L100,161" stroke="',skyColors[getIndexes(imageCode, 0)],'" stroke-width="1.5" /><path d="M325,167 L100,167" stroke="',skyColors[getIndexes(imageCode, 0)],'" stroke-width="2" /><path d="M325,174 L100,174" stroke="',skyColors[getIndexes(imageCode, 0)],'" stroke-width="2.5" /><path d="M325,181 L100,181" stroke="',skyColors[getIndexes(imageCode, 0)],'" stroke-width="3" /><path d="M325,189 L100,189" stroke="',skyColors[getIndexes(imageCode, 0)],'" stroke-width="3.2" /><path d="M325,197 L100,197" stroke="',skyColors[getIndexes(imageCode, 0)],'" stroke-width="3.5" />'));
            
            // add text to image
            string memory textString = buildString(_proposition);
            output = string(abi.encodePacked(output, textString));
    
            // Add metadata to json
            string memory jsonMeta = string(abi.encodePacked('{"name": "',_proposition,'", "description": "Beliefs are not private. Beliefs are not free.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '",'));
            jsonMeta = string(abi.encodePacked(jsonMeta, ' "attributes": [{ "trait_type": "Epoch", "value": "',tokenEpoch,'" }, { "trait_type": "Proposition Set", "value": "true" }, { "trait_type": "Image DNA", "value": "',toString(imageCode),'" }, { "trait_type": "Sky", "value": "',skyColors[getIndexes(imageCode, 0)],'" }, { "trait_type": "Planet", "value": "',planetColors[getIndexes(imageCode, 1)],'" }, { "trait_type": "Heavenly Body", "value": "',heavenlyBodyColors[getIndexes(imageCode, 2)],'" }, { "trait_type": "Heavenly Reflection", "value": "',heavenlyReflectionColors[getIndexes(imageCode, 3)],'" }]}'));
            string memory json = Base64.encode(bytes(jsonMeta));
            output = string(abi.encodePacked('data:application/json;base64,', json));
            
            return output;
        }
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function getBalance() public view returns (uint256) {
        uint balance = address(this).balance;
        return balance;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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