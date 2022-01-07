/**
 *Submitted for verification at Etherscan.io on 2022-01-07
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

// File: contracts/SFT/ISFT.sol

pragma solidity ^0.8.0;


interface ISFT is IERC721{
    /**
        @dev This emits when `_value` tokens of semi-fungible token (SFT) type are minted.
        The `_operator` argument MUST be the address of an account/contract that is approved to
        mint this type of token.
     */
    event SemiTypeMinted(address indexed _operator, address indexed _to, uint256 indexed _tokenType, bytes _data, uint256 _value);

    /**
        @dev This emits when approval for a second party/operator address to manage `_tokenType` of SFTs
        for an owner address is enabled or disabled.
     */
    event ApprovalForSemi(address indexed _owner, address indexed _operator, uint256 indexed _tokenType, bool _approved);

    /**
        @dev This emits when approval for a second party/operator address to manage all types of SFTs
        for an owner address is enabled or disabled.
      */
    event ApprovalForAllSemi(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev This emits when a new NFT is minted from one type of SFT
     */
    event SemiMinted(address _operator, address indexed _from, address indexed _to, uint256 indexed _tokenId, uint256 _tokenType);

    /* ERC-1155 events compatible*/
    /**
        @dev Either `SemiTransferSingle` or `SemiTransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_tokenType` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event SemiTransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _tokenType, uint256 _value);

    /**
        @dev Either `SemiTransferSingle` or `SemiTransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_tokenTypes` argument MUST be the list of token types being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event SemiTransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _tokenTypes, uint256[] _values);

    /**
        @notice Create `_value` tokens of `_tokenType` to `_to`.
        @dev Caller must be owner or approved to create new SFT type
        `to` cannot be zero address.
        MUST emit `SemiTypeMinted` event to reflect the new sem-fungible token type creation.
        @param _to          address that `_tokenType` tokens assigned to.
        @param _tokenType   SFT type
        @param _data        The metadata for `_tokenType`
        @param _value       The number of tokens for `_tokenType`
     */
    function semiTypeMint(address _to, uint256 _tokenType, uint256 _value, bytes calldata _data) external;

    /**
        @notice Enable or disable approval for a third party ("operator") to manage caller's '_tokenType' tokens.
        @dev MUST emit `ApprovalForSemi` event on success.
        MUST revert if `_tokenType` doesn't exist
        @param _operator    Address of authorized operators
        @param _tokenType   SFT type
        @param _approved    True if the operator is approved, false to revoke approval
    */
    function setApprovalForSemi(address _operator, uint256 _tokenType, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner and `_tokenType`.
        @param _owner      The address of the token holder
        @param _operator   Address of authorized operator
        @param _tokenType  SFT type
        @return            True if the operator is approved, false if not
    */
    function isApprovedForSemi(address _owner, address _operator, uint256 _tokenType) external view returns (bool);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage caller's all SFT tokens.
        @dev MUST emit `SemiApprovalForAll` event on success.
        @param _operator  Address of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAllSemi(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The address of the token holder
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAllSemi(address _owner, address _operator) external view returns (bool);

    /**
       @notice Mint one SFT type of NFT from the `_from` to the `_to` as ownership of converted NFT with `_tokenId`.
       @dev Caller must be approved to manage the token being transferred out of the `_from` account.
       MUST emit `SemiTransferSingle` event to reflect the SFT converted to NFT information.
       MUST emit `SemiMinted` event to reflect the new NFT creation information.
       MUST emit `Transfer` event to reflect NFT creation.
       MUST revert if `_to` is the zero address.
       MUST revert if semiBalance of `_from` is lower than 1.
       MUST revert if `_tokenType` is invalid
       MUST revert on any other error.
       would generate unique tokenId across the contract as the NFT id to caller.
       unique tokenId is recorded in `SemiMinted` event.
       SFT owner calling this function to mint one SFT type of NFT to `_to`, accordingly, the SFT
       balance of `_from` is decreased by 1, while NFT balance of `_to` is increased by 1.
       @param _from        Source address
       @param _to          Target address
       @param _tokenType   SFT type
       @param _data        The metadata for `_tokenType`
     */
    function semiMint(address _from, address _to, uint256 _tokenType, bytes calldata _data) external;

    /**
        @notice Transfers `_value` amount of a `_tokenType` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for `_tokenType` tokens is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `SemiTransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERCSFTReceived` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from        Source address
        @param _to          Target address
        @param _tokenType   SFT type
        @param _value       Transfer amount
        @param _data        Additional data with no specified format, MUST be sent unaltered in call to `onERCSFTReceived` on `_to`
    */
    function semiSafeTransferFrom(address _from, address _to, uint256 _tokenType, uint256 _value, bytes calldata _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_tokenTypes` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_tokenTypes` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_tokenTypes` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `SemiTransferSingle` or `SemiTransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERCSFTTokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from            Source address
        @param _to              Target address
        @param _tokenTypes      SFT types (order and length must match _values array)
        @param _values          Transfer amounts per token type (order and length must match _tokenTypes array)

        @param _data        Additional data with no specified format, MUST be sent unaltered in call to `onERCSFTReceived` on `_to`
    */
    function semiSafeBatchTransferFrom(address _from, address _to, uint256[] calldata _tokenTypes, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's tokens for `_tokenType`.
        @param _owner         The address of the token holder
        @param _tokenType     The token type
        @return               The _owner's balance of the token type requested
     */
    function balanceOfSemi(address _owner, uint256 _tokenType) external view returns (uint256);

    /**
     * @dev Total amount of SFTs in with a given `_tokenType`.
     */
    function totalSupplyForSemi(uint256 _tokenType) external view returns (uint256);
}

// File: contracts/SFT/ISFTReceiver.sol

pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is TODO.
*/
interface ISFTReceiver {
    /**
        @notice Handle the receipt of a single ERCSFT token type.
        @dev An ERCSFT-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERCSFTReceived(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERCSFTReceived(address,address,uint256,uint256,bytes)"))`
    */
    function onERCSFTReceived(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERCSFT token types.
        @dev An ERCSFT-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERCSFTBatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERCSFTBatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERCSFTBatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}

// File: contracts/SFT/ISFTMetadata.sol

pragma solidity ^0.8.0;

interface ISFTMetadata /* is ISFT */{
    /// @notice A descriptive name for a collection of SFTs in this contract
    function semiName(uint256 _tokenType) external view returns (string memory);
    /// @notice An abbreviated name for SFTs in this contract
    function semiSymbol(uint256 _tokenType) external view returns (string memory);
    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_id` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function semiURI(uint256 _tokenType) external view returns (string memory);
}

// File: contracts/SFT/SFT.sol

pragma solidity ^0.8.0;










/**
 * @dev Implementation of the basic standard semi-fungible token.
 * @notice Copy some codes from openzeppelin/contract/token/ERC1155/ERC1155.sol with MIT license
 */

contract SFT is Context, ISFT, ISFTMetadata, ERC721 {
    using Address for address;
    using Strings for uint256;

    // Mapping from semi-fungible token (SFT) type to metadata
    mapping(uint256 => bytes) private _semiMetadatas;

    // Mapping from SFT type to totalSupply
    mapping(uint256 => uint256) private _semiTotals;


    // Used as default URI for all types of SFT.
    string private _semiBaseUri;

    // Used as the URI for one type of SFT.
    mapping(uint256 => string) private _semiUri;

    // Mapping from SFT type to name
    mapping(uint256 => string) private _semiName;

    //Mapping from SFT type to symbol
    mapping(uint256 => string) private _semiSymbol;

    // Mapping from SFT type to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from one type of SFT owner to operator approvals
    mapping(uint256 => mapping(address => mapping(address => bool))) private _semiApprovals;

    // Mapping from all types of SFT owner to operator approvals
    mapping(address => mapping(address => bool)) private _semiAllApprovals;

    // NFT token index
    uint256 private _nftId = 0;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(ISFT).interfaceId ||
            interfaceId == type(ISFTMetadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns whether `operator` is the contract owner or get approval.
     */
    function _isSemiTypeMintApproved(address, address, uint256, uint256, bytes memory) internal virtual returns (bool) {
        return true;
    }

    /**
     * `_tokenType` process after minting operation.
     */
    function _afterSemiTypeMint(address, address, uint256 _tokenType, uint256, bytes memory _data) internal virtual {
        _semiMetadatas[_tokenType] = _data;
    }

    function _getSemiTypeData(uint256 _tokenType) internal view virtual returns (bytes memory) {
        return _semiMetadatas[_tokenType];
    }

    /**
     * @dev See {ISFT-semiTypeMint}.
     */
    function semiTypeMint(address _to, uint256 _tokenType, uint256 _value, bytes memory _data) public virtual override {
        require(_to != address(0), "SFT: mint to the zero address");

        address _operator = _msgSender();
        require(_isSemiTypeMintApproved(_operator, _to, _tokenType, _value, _data),
                "SFT: semiTypeMint caller is not owner nor approved");

        _beforeSemiTokenTransfer(_operator, address(0), _to, _asSingletonArray(_tokenType), _asSingletonArray(_value), _data);

        _balances[_tokenType][_to] += _value;
        emit SemiTypeMinted(_operator, _to, _tokenType, _data, _value);
        emit SemiTransferSingle(_operator, address(0), _to, _tokenType, _value);

        _doSafeTransferAcceptanceCheck(_operator, address(0), _to, _tokenType, _value, _data);
        _afterSemiTypeMint(_operator, _to, _tokenType, _value, _data);
    }

    function _setSemiName(uint256 _tokenType, string memory name) internal virtual {
        _semiName[_tokenType] = name;
    }

    function semiName(uint256 _tokenType) public view virtual override returns (string memory) {
        return _semiName[_tokenType];
    }

    function _setSemiSymbol(uint256 _tokenType, string memory symbol) internal virtual {
        _semiSymbol[_tokenType] = symbol;
    }

    function semiSymbol(uint256 _tokenType) public view virtual override returns (string memory) {
        return _semiSymbol[_tokenType];
    }

    function _setSemiBaseURI(string memory baseUri) internal virtual {
        _semiBaseUri = baseUri;
    }

    function _semiBaseURI() internal view virtual returns (string memory) {
        return _semiBaseUri;
    }

    function _setSemiURI(uint256 _tokenType, string memory _uri) internal virtual {
        _semiUri[_tokenType] = _uri;
    }

    function semiURI(uint256 _tokenType) public view virtual override returns (string memory) {
        // TODO(linb): SVG refers to uniswap3 LP token
        if (bytes(_semiUri[_tokenType]).length > 0) {
            return _semiUri[_tokenType];
        }
        return _semiBaseUri;
    }

    function totalSupplyForSemi(uint256 _tokenType) public view virtual override returns (uint256) {
        return _semiTotals[_tokenType];
    }

    function balanceOfSemi(address _owner, uint256 _tokenType) public view virtual override returns (uint256) {
        require(_owner != address(0), "SFT: balance query for the zero address");
        return _balances[_tokenType][_owner];
    }

    function _setApprovalForSemi(address _owner, address _operator, uint256 _tokenType, bool _approved) internal virtual {
        require(_owner != _operator, "SFT: setting approval status for self");
        _semiApprovals[_tokenType][_owner][_operator] = _approved;
        emit ApprovalForSemi(_owner, _operator, _tokenType, _approved);
    }

    function setApprovalForSemi(address _operator, uint256 _tokenType, bool _approved) public virtual override {
        _setApprovalForSemi(_msgSender(), _operator, _tokenType, _approved);
    }

    function isApprovedForSemi(address _owner, address _operator, uint256 _tokenType) public view virtual override returns (bool) {
        return
            _semiAllApprovals[_owner][_operator] ||
            _semiApprovals[_tokenType][_owner][_operator];
    }

    function _setApprovalForAllSemi(
        address _owner,
        address _operator,
        bool _approved
    ) internal virtual {
        require(_owner != _operator, "SFT: setting approval status for self");
        _semiAllApprovals[_owner][_operator] = _approved;
        emit ApprovalForAllSemi(_owner, _operator, _approved);
    }

    function setApprovalForAllSemi(address _operator, bool _approved) public virtual override {
        _setApprovalForAllSemi(_msgSender(), _operator, _approved);
    }

    function isApprovedForAllSemi(address _owner, address _operator) public view virtual override returns (bool) {
        return _semiAllApprovals[_owner][_operator];
    }

    /**
     * Approve the semi-fungible token transfer operation from `_tokenType` if:
     *   `_operator` is the `_tokenTypes` owner `_owner`
     *   `_operator` has approval on `_tokenType` of `_owner`
     *   `_operator` has all semi-fungible token types' approval for `_owner`
     */
    function _isSemiTransferApproved(address _owner, address _operator, uint256[] memory _tokenTypes) internal virtual returns (bool) {
        if (_owner == _operator ||
            isApprovedForAllSemi(_owner, _operator)) {
            return true;
        }

        for (uint256 i = 0; i < _tokenTypes.length; i++) {
            if (!isApprovedForSemi(_owner, _operator, _tokenTypes[i])) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Destroys `amount` tokens of `_tokenType` SFT from `from`
     *
     * This is a reverse operation of semiTypeMint
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */

    function _semiTypeBurn(
        address _from,
        uint256 _tokenType,
        uint256 _value
    ) internal virtual {
        require(_from != address(0), "SFT: burn from the zero address");

        uint256 _balance = _balances[_tokenType][_from];
        require(_balance >= _value, "SFT: burn amount exceeds balance");

        address _operator = _msgSender();
        _beforeSemiTokenTransfer(_operator, _from, address(0), _asSingletonArray(_tokenType), _asSingletonArray(_value), "");

        _balances[_tokenType][_from] -= _value;

        emit SemiTransferSingle(_operator, _from, address(0), _tokenType, _value);
    }

    function _getNftId() internal virtual returns (uint256) {
        return _nftId;
    }

    /**
     * @notice find one available non-fungible token id for use
     */
    function _findNftId() internal virtual returns (uint256) {
        return _nftId++;
    }

    function _semiMint(address _owner, address _operator, address _to,
                       uint256 _tokenType, uint256 tokenId, bytes memory _data) internal virtual {
        _balances[_tokenType][_owner] -= 1;
        emit SemiTransferSingle(_msgSender(), _owner, address(0), _tokenType, 1);
        // call safe minting operation to mint the NFT from `_tokenType`
        _safeMint(_to, tokenId, _data);
        emit SemiMinted(_operator, _owner, _to, tokenId, _tokenType);
    }

    function _isSemiMintApproved(address, address, address, uint256, uint256, bytes memory) internal virtual returns (bool) {
        return true;
    }

    /**
     * @dev See {ISFT-semiMint}.
     */
    function semiMint(
        address _from,
        address _to,
        uint256 _tokenType,
        bytes memory _data) public virtual override {
        uint256 tokenId = _findNftId();
        require(_isSemiMintApproved(_msgSender(), _from, _to, _tokenType, tokenId, _data),
                "SFT: caller is not mint owner nor approved");
        require(_isSemiTransferApproved(_from, _msgSender(), _asSingletonArray(_tokenType)),
                "SFT: caller is not owner nor approved");
        require(_to != address(0), "SFT: semi-mint to the zero address");
        require(_balances[_tokenType][_from] > 0, "SFT: owner has no sft balance");

        _semiMint(_from, _msgSender(), _to, _tokenType, tokenId, _data);
    }

    /**
     * @dev Hook that is called before any SFT token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeSemiTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual {
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _semiTotals[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _semiTotals[ids[i]] -= amounts[i];
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try ISFTReceiver(to).onERCSFTReceived(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != ISFTReceiver.onERCSFTReceived.selector) {
                    revert("ERCSFT: ERCSFTReceiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERCSFT: transfer to non ERCSFTReceiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _tokenTypes,
        uint256[] memory _values,
        bytes memory _data) private {

        if (_to.isContract()) {
            try ISFTReceiver(_to).onERCSFTBatchReceived(_operator, _from, _tokenTypes, _values, _data) returns (
                bytes4 response
            ) {
                if (response != ISFTReceiver.onERCSFTBatchReceived.selector) {
                    revert("SFT: ERCSFTReceiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("SFT: transfer to non SFTReceiver implementer");
            }
        }
    }

    /**
     * @dev See {ISFT-semiSafeTransferFrom}
     */
    function semiSafeTransferFrom(address _from, address _to, uint256 _tokenType, uint256 _value, bytes memory _data) public virtual override {
        require(_isSemiTransferApproved(_from, _msgSender(), _asSingletonArray(_tokenType)),
                "SFT: caller is not owner nor approved");
        require(_to != address(0), "SFT: transfer to the zero address");

        address _operator = _msgSender();

        _beforeSemiTokenTransfer(_operator, _from, _to, _asSingletonArray(_tokenType), _asSingletonArray(_value), _data);

        uint256  _balance  = _balances[_tokenType][_from];
        require(_balance >= _value, "SFT: insufficient balance for transfer");
        _balances[_tokenType][_from] -= _value;
        _balances[_tokenType][_to] += _value;

        emit SemiTransferSingle(_operator, _from, _to, _tokenType, _value);

        _doSafeTransferAcceptanceCheck(_operator, _from, _to, _tokenType, _value, _data);
    }

    function _semiSafeBatchTransferFrom(address _from, address _to, uint256[] memory _tokenTypes, uint256[] memory _values, bytes memory _data) internal virtual {
        require(_tokenTypes.length == _values.length, "SFT: _tokenTypes and _values length mismatch");
        require(_to != address(0), "SFT: transfer to the zero address");

        address _operator = _msgSender();

        _beforeSemiTokenTransfer(_operator, _from, _to, _tokenTypes, _values, _data);

        for (uint256 i = 0; i < _tokenTypes.length; i++) {
            uint256 _tokenType = _tokenTypes[i];
            uint256 _value = _values[i];

            uint256 _balance = _balances[_tokenType][_from];
            require(_balance >= _value, "SFT: insufficient balance for transfer");
            _balances[_tokenType][_from] -= _value;
            _balances[_tokenType][_to] += _value;

        }
        emit SemiTransferBatch(_operator, _from, _to, _tokenTypes, _values);
        _doSafeBatchTransferAcceptanceCheck(_operator, _from, _to, _tokenTypes, _values, _data);
    }

    function semiSafeBatchTransferFrom(address _from, address _to, uint256[] memory _tokenTypes, uint256[] memory _values, bytes memory _data) public virtual override {
        require(_isSemiTransferApproved(_from, _msgSender(), _tokenTypes),
                "SFT: caller is not owner nor approved");
        _semiSafeBatchTransferFrom(_from, _to, _tokenTypes, _values, _data);
    }

}

// File: contracts/LNFT/ILNFT.sol

pragma solidity ^0.8.0;




interface ILNFT is ISFT, ISFTMetadata, IERC721Metadata {

    /**
        @dev this emits when `_value` of new license type are minted.
     */
    event LicenseTypeMinted(address indexed _operator, address indexed _to, uint256 indexed _licenseType, uint256 _value, string _licensorName, string _desc, string _licenseName, string _licenseSymbol, bytes _data);

    /**
        @notice get the license issuer name who is the Licensor.
     */
	function licensorName(uint256 _licenseType) external view returns (string memory);

    /**
        @notice get the license issuer address.
     */
	function licensorAddress(uint256 _licenseType) external view returns (address);

    /**
        @notice get the license type name and symbol
        license name call {ISFTMetadata-semiName}
        license symbol call {ISFTMetadata-semiSymbol}
     */

	/**
        @notice a simple introduction of this licensing contract purpose, use and some notices.
     */
	function description(uint256 _licenseType) external view returns (string memory);

    /**
        @notice The license agreement URI of `_licenseType` license.
        call {ISFTMetadata-semiURI}
      */
	function agreementURI(uint256 _licenseType) external view returns (string memory);

	/**
		@notice create `_value` of new type of licenses
        @dev the caller would be the Licensor
        @dev only Licensor can do already minted `_licenseType` metadata change.
        call {ISFT-semiTypeMint}
	*/
	function licenseTypeMint(address _to, uint256 _licenseType, uint256 _value, string calldata _licensorName, string calldata _desc, string calldata _licenseName, string calldata _licenseSymbol, bytes calldata _data) external;

    /**
        @notice assign one new license from `_from` to `_to`
        call {ISFT-semiMint}
     */
	function licenseMint(address _from, address _to, uint256 _licenseType, bool _active, bytes calldata _data) external;

    /**
        @notice get the license type of `_licenseId`.
     */
    function licenseType(uint256 _licenseId) external view returns (uint256 _licenseType);

	/**
		@notice activate/deactivate one license.
		@dev the caller must be approved to do this operation
	 */
	function setActive(uint256 _licenseId, bool _active) external;

    /**
        @notice check the license is activated.
     */
	function isActive(uint256 _licenseId) external view returns (bool);

    /**
        @notice check the license is valid for use.
     */
	function isValid(uint256 _licenseId) external view returns (bool);

    /**
        @notice validate _owner is the owner of `_licenseId` and `_licenseId` is valid. 
     */
    function validate(address _owner, uint256 _licenseId) external view returns (bool);

    /**
        @notice get license expired time with timestamp in seconds.
        2**256 -1 means inifinite
     */
	function expireOn(uint256 _licenseId) external view returns (uint256);

    /*
        @notice Get license metadata URI.
        call {IERC721Metadata-tokenURI}
        {
	    	license_type: _licenseType
	    	licensor_name: The entity issued the license who is the Licensor name
            licensor_address: The Licensor address who first minted the new `_licenseType` licenses
	    	vendor_address: The entity sold the product to Licensee
            is_valid: true/false,
            is_active: true/false,
            factory_time: Licensor first created this type of license (timestamp in seconds).
	    	issue_time: time when this type of license is minted to Licensee (timestamp in seconds).
	    	expire_time: time when license is expired (seconds in timestamp).
	    }
     */
    function licenseURI(uint256 _licenseId) external view returns (string memory);
}

// File: contracts/LNFT/LNFT.sol

pragma solidity ^0.8.0;







contract LNFT is ILNFT, SFT {
    using Address for address;
    using Strings for uint256;

    struct licenseTypeMeta {
        address licensor_address;
        string  licensor_name;
        string  name;
        string  symbol;
        string  description;
        uint256 mint_time;
    }

    struct licenseMeta {
        uint256 license_type;
        uint256 issue_time;
        address vendor_address;
        uint256 expire_time;
        bool    is_active;
    }

    // infinite timestamp
    uint256 public TIME_INFINITE = type(uint256).max;

    // Mapping from _licenseType to type metadata.
    mapping(uint256 => licenseTypeMeta) private _licenseTypeDatas;

    // Mapping from _licenseId to license metadata.
    mapping(uint256 => licenseMeta) private _licenseDatas;

    function _licenseTypeExists(uint256 _licenseType) internal virtual returns (bool) {
        return licensorAddress(_licenseType) != address(0);
    }

    function _licenseExists(uint256 _licenseId)  internal view virtual returns (bool) {
        return _licenseDatas[_licenseId].issue_time > 0;
    }

    constructor(string memory name_, string memory symbol_) SFT(name_, symbol_) {
    }

    function licensorAddress(uint256 _licenseType) public view virtual override returns (address) {
        return _licenseTypeDatas[_licenseType].licensor_address;
    }

    function licensorName(uint256 _licenseType) public view virtual override returns (string memory) {
        return _licenseTypeDatas[_licenseType].licensor_name;
    }

    function semiName(uint256 _licenseType) public view virtual override(ISFTMetadata, SFT) returns (string memory) {
        return _licenseTypeDatas[_licenseType].name;
    }

    function semiSymbol(uint256 _licenseType) public view virtual override(ISFTMetadata, SFT) returns (string memory) {
        return _licenseTypeDatas[_licenseType].symbol;
    }

    function description(uint256 _licenseType) public view virtual override returns (string memory) {
        return _licenseTypeDatas[_licenseType].description;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(SFT, IERC165) returns (bool) {
        return
            interfaceId == type(ILNFT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _isSemiTypeMintApproved(address _operator, address, uint256 _licenseType, uint256, bytes memory) internal virtual override returns (bool) {
        return
            _licenseTypeExists(_licenseType) &&
            _operator == licensorAddress(_licenseType);
    }

    function agreementURI(uint256 _licenseType) public view virtual override returns (string memory) {
        return semiURI(_licenseType);
    }

    function _licenseTypeBeforeMint(address _operator, address, uint256 _licenseType, uint256,
                                string memory, string memory, string memory, string memory, bytes memory) internal virtual {
        if (_licenseTypeExists(_licenseType)) {
            require (_operator == licensorAddress(_licenseType), "LNFT: licenseTypeMint caller is not the owner");
        } else {
            licenseTypeMeta storage _typeMeta = _licenseTypeDatas[_licenseType];
            _typeMeta.licensor_address = _operator;
            _typeMeta.mint_time = block.timestamp;
        }
    }

    function _licenseTypeAfterMint(address _operator, address _to, uint256 _licenseType, uint256 _value,
                                string memory _licensorName, string memory _desc, string memory _licenseName, string memory _licenseSymbol, bytes memory _data) internal virtual {
        licenseTypeMeta storage _typeMeta = _licenseTypeDatas[_licenseType];
        if (bytes(_licensorName).length > 0) {
            _typeMeta.licensor_name = _licensorName;
        }
        if (bytes(_desc).length > 0) {
            _typeMeta.description = _desc;
        }
        if (bytes(_licenseName).length > 0) {
            _typeMeta.name = _licenseName;
        }
        if (bytes(_licenseSymbol).length > 0) {
            _typeMeta.symbol = _licenseSymbol;
        }

        emit LicenseTypeMinted(_operator, _to, _licenseType, _value, _licensorName, _desc, _licenseName, _licenseSymbol, _data);
    }

	function licenseTypeMint(address _to, uint256 _licenseType, uint256 _value, string memory _licensorName, string memory _desc, string memory _licenseName, string memory _licenseSymbol, bytes memory _data) public virtual override {
        address _operator = _msgSender();
        _licenseTypeBeforeMint(_operator, _to, _licenseType, _value, _licensorName, _desc, _licenseName, _licenseSymbol, _data);
        semiTypeMint(_to, _licenseType, _value, _data);
        _licenseTypeAfterMint(_operator, _to, _licenseType, _value, _licensorName, _desc, _licenseName, _licenseSymbol, _data);
    }

    function _isSemiMintApproved(address, address, address, uint256 _licenseType, uint256 _licenseId, bytes memory) internal virtual override returns (bool) {
        return
            _licenseExists(_licenseId) &&
            _licenseDatas[_licenseId].license_type == _licenseType;
    }

    function _licenseBeforeMint(address, address, uint256 _licenseType, uint256 _licenseId, bool, bytes memory) public virtual {
        licenseMeta storage _meta = _licenseDatas[_licenseId];
        _meta.license_type = _licenseType;
        _meta.issue_time = block.timestamp;
    }

    function _setExpireTime(uint256, uint256 _licenseId, uint256 time, bytes memory) internal virtual {
        _licenseDatas[_licenseId].expire_time = time;
    }

    function _licenseAfterMint(address _from, address, uint256 _licenseType, uint256 _licenseId, bool _active, bytes memory _data) public virtual {
        licenseMeta storage _meta = _licenseDatas[_licenseId];
        _meta.vendor_address = _from;
        _setExpireTime(_licenseType, _licenseId, TIME_INFINITE, _data);
        _meta.is_active = _active;
    }

    function licenseMint(address _from, address _to, uint256 _licenseType, bool _active, bytes memory _data) public virtual override {
        uint256 _licenseId = _getNftId();
        _licenseBeforeMint(_from, _to, _licenseType, _licenseId, _active, _data);
        semiMint(_from, _to, _licenseType, _data);
        _licenseAfterMint(_from, _to, _licenseType, _licenseId, _active, _data);
    }

    function licenseType(uint256 _licenseId) public view virtual override returns (uint256) {
        require(_licenseExists(_licenseId), "LNFT: _licenseId should exist");
        return _licenseDatas[_licenseId].license_type;
    }

    function expireOn(uint256 _licenseId) public view virtual override returns (uint256) {
        require(_licenseExists(_licenseId), "LNFT: _licenseId should exist");
        return _licenseDatas[_licenseId].expire_time;
    }

    function _isExpired(uint256 _licenseId) internal view virtual returns (bool) {
        if (!_licenseExists(_licenseId)) {
            return true;
        }
        return expireOn(_licenseId) <= block.timestamp;
    }

    function setActive(uint256 _licenseId, bool _active) public virtual override {
        require(_licenseExists(_licenseId), "LNFT: _licenseId should exist");
        require(_isApprovedOrOwner(_msgSender(), _licenseId),
                "LNFT: caller is not owner nor approved");
        _licenseDatas[_licenseId].is_active = _active;
    }

    function isActive(uint256 _licenseId) public view virtual override returns (bool) {
        return _licenseDatas[_licenseId].is_active;
    }

    function isValid(uint256 _licenseId) public view virtual override returns (bool) {
        return
            isActive(_licenseId) &&
            !_isExpired(_licenseId);
    }

    function validate(address _owner, uint256 _licenseId) public view virtual override returns (bool) {
        return
            _exists(_licenseId) &&
            ownerOf(_licenseId) == _owner &&
            isValid(_licenseId);
    }

    function licenseURI(uint256 _licenseId) public view virtual override returns (string memory) {
        return tokenURI(_licenseId);
    }
}

// File: contracts/LicenseRegistrar/DAppVIP.sol

pragma solidity ^0.8.0;



contract DAppVIP is Ownable, LNFT {
    string public name = "DApp years of VIP License";
    string public symbol = "DVIP";
    uint256 public year1 = 365 * 24 * 60 * 60;

    constructor(address _owner) LNFT(name, symbol) Ownable() {
        if (_owner != address(0)) {
            transferOwnership(_owner);
        }
    }

    function description(uint256 _licenseType) public view override returns (string memory _desc) {
        _desc = super.description(_licenseType);
        if (bytes(_desc).length == 0) {
            _desc = name;
        }
        return _desc;
    }

    /// the first byte of _data is used as the year unit of valid duration.
    function _isSemiTypeMintApproved(address _operator, address _to, uint256 _licenseType, uint256 _value, bytes memory _data) internal override returns (bool) {
        require(_data.length >= 1, "_data should has the duration");
        return super._isSemiTypeMintApproved(_operator, _to, _licenseType, _value, _data);
    }

    function getDuration(uint256 _licenseType) public view virtual returns (uint256) {
        bytes memory _licenseTypeData = _getSemiTypeData(_licenseType);
        return uint256(uint8(_licenseTypeData[0]));
    }

    function _setExpireTime(uint256 _licenseType, uint256 _licenseId, uint256, bytes memory _data) internal override {
        uint256 expire_time = block.timestamp + getDuration(_licenseType) * year1;
        super._setExpireTime(_licenseType, _licenseId, expire_time, _data);
    }

}