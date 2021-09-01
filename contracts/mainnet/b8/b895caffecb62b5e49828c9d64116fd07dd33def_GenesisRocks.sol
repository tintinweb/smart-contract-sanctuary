/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

/******************************************/
/*           IERC165 starts here          */
/******************************************/

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

/******************************************/
/*           ERC165 starts here           */
/******************************************/

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

/******************************************/
/*          Strings starts here           */
/******************************************/

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

/******************************************/
/*          Context starts here           */
/******************************************/

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

/******************************************/
/*           Ownable starts here          */
/******************************************/

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

/******************************************/
/*          Address starts here           */
/******************************************/

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

/******************************************/
/*       IERC721Receiver starts here      */
/******************************************/

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

/******************************************/
/*           IERC721 starts here          */
/******************************************/

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

/******************************************/
/*       IERC721Metadata starts here      */
/******************************************/

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

/******************************************/
/*           ERC721 starts here           */
/******************************************/

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

interface EtherRock {
  function sellRock (uint rockNumber, uint price) external;
  function giftRock (uint rockNumber, address receiver) external;
}

contract RockWarden is Ownable {
  function claim(uint256 id, EtherRock rocks) public onlyOwner {
    rocks.sellRock(id, type(uint256).max);
    rocks.giftRock(id, owner());
  }
  
  function withdraw(uint256 id, EtherRock rocks, address recipient) public onlyOwner {
    rocks.giftRock(id, recipient);
  }
}

contract GenesisRocks is ERC721 {
  EtherRock public rocks = EtherRock(0x37504AE0282f5f334ED29b4548646f887977b7cC);

  using Address for address;

  string private _baseTokenURI;
  uint256 private _totalSupply;

  mapping(address => address) public wardens;
  
  string[] hashes = [
    'bafyreieoiyches3w2yyxim63yhuqj2esbvxqmkfepr4wd7qdr46etshoee',
    'bafyreiebbwh7h4ygryalx33p63kbkve2im72c6lj7746in2ts3trxqr5xi',
    'bafyreif5igmqc5zapujnmridh4ttysvvrtt2kx2pcoddozngcj72rkbrym',
    'bafyreifypwtxfwcwno5totiyj6jei2564hq3xxjebj7ocgalub45vzsd34',
    'bafyreid6ew5m3vunwalc45ddvsrsdwmeaz6tgvqzo6nfpotffbh3i643iy',
    'bafyreiays5vqnvgqyxasvmoiu4cnoi4slck3yhnqt45cklitn6pdzreoce',
    'bafyreigxhynuriuoc2gd25yjpanym56yukv2sai7vtkl2p7llzdw3x6koq',
    'bafyreidl3qg6cwzudsjmjp2dgr7poy7mzrtpcxrddvfo2h4blbgzgiujeq',
    'bafyreicyy4cjbhmvsx7ev7jvda4figj7mf3gz6ylw7fafin4cct6m26cle',
    'bafyreicuivxwgbp6y4p3co6weqqzpysa7gmunwg32eytkmppolsbme5loi',
    'bafyreiac6slo6qxkwz7nqfomsh6ghjusu7wazyoe62vv5hhjtmhx7b75wa',
    'bafyreic2hb7wpgi5k3u3s52ak6sht234fcvwuv4a6vo5vc7x3uns7hljwe',
    'bafyreiajisvfhle3nz4kpugb3fy2edulrqgc4yd3vsmyqce7jwchpvv7lq',
    'bafyreihx2jrxteirjche4he3ioilkp4evbkyfcw7pi3dentliejsfae5se',
    'bafyreihuj7ddlcrco4wwkz3cfyjgrjgto3cuqtatsupy3wk3axwzudkani',
    'bafyreigfc5hqfzec2m4g4ibnxtm4xlqgyasdni5ugvisrj25ocla47b34e',
    'bafyreid5qleu2yqcbg5j3gap33gjkxpnqy43irbnkigekzq5cixj56bvg4',
    'bafyreieo35bcrls7hnirgadbgqe5ytfj4qhib4vq22fl4tpc73ptjubrqi',
    'bafyreidrwa33rh4cwvaa7xnya6u62xkvms4jj7qxubqdzxxuswnrhjsdru',
    'bafyreig4525gf5v5g25n57cgmefkr7g5klysajlwljkvkwskq53fckmzfe',
    'bafyreihu35tdhnv5vuhmb3vxmdhlittgvh2yvjro3bykrguo6ys44wyuxm',
    'bafyreiekacg4zpxlltkykbgjnhsf42wgi7akotukvnp6gicpajkhzrwdmu',
    'bafyreifjnwce4lctvwbmvmbci3dncdlahsvnts33yxkgb37d3qxp753eea',
    'bafyreiebxct5l7kahnfkdncp3rkty36y2nxogtmv4rvtzyxw4fdjoefdny',
    'bafyreib22cfbrsug2fokofrndu5awayyn3ij7y752gvnh2ehlynxakvxvq',
    'bafyreihhvio66f3mkbbkxleztpa34g572yl2mjfxbzs3677oyi5pxeag6u',
    'bafyreiahzltde3hqg2wxf4ewysj3x4i6qozshbu4hthflriy62zi64dwmu',
    'bafyreic4fldbzcn6j4zt5fi7owsavksrqkuuly2gg3saazvkyno5ggkx6a',
    'bafyreifcrv3kkw6jgpmj4bagxbeh6dkv2oab757ueaacvzq4xzswbhffv4',
    'bafyreiaxxhss3jepyy24yvugcaruf2wtr73plcv67cwypiknnbufqvk7gy',
    'bafyreihqe356tzs2w27rlckgyj3x4dqp7prtdrt3nh5vgorwkxqoxumpnq',
    'bafyreiat5xghn5upnuik7cg63x664bzijvlifla2nayncofwx5tavz5p2q',
    'bafyreiamhlscfklp7simix3c6znffmmwyncs3iqfhk3kni7i22a3x2vpqa',
    'bafyreihrtss4xppucluh7v3pfdihyc62nk5ff3pgt54cgc626fnhkawji4',
    'bafyreicpfiordskkahxmlzkkrccsjcsuiz7fplhtr75mzqswnovmfk4u7e',
    'bafyreidptpol2xi5jqnxen3aug563destp7vdjexkxfjcpvkjor6fko6mu',
    'bafyreicpweuqoz32ce5zcqx2yofp7wudo6vmkimxib2f3vvfnd6wzdm5ou',
    'bafyreihicdm3ga62g6terqytj76jcj4q5fqptbjgr5s2twnpqfdxq6hnpa',
    'bafyreia5xn7ev7nrcboxi6smrwnd4pedttgb3qf4xuxrrjepatrez4yse4',
    'bafyreihfypx557ipvheqf3qolt6fllgt3tszoaerfjp65dboycpcmfzlny',
    'bafyreifqsdqayngmuc3kp5nhnkjbqgj7uoc6nm6szw3fovm23b27mj7gfi',
    'bafyreiebswrzpx2eqqr5sb4lxjayvvufccqvzhzc6cvds7hu7tw5v2pwoi',
    'bafyreignlctk2l4nxtfmrwfu2qgq2zr5j45tsdo4lv4gobod5pewzzjray',
    'bafyreihxalsghdr322q2iql63sdxnowvi5gvvy3n45yzceb64u4ryi2l5m',
    'bafyreicb3lnlv4r66tn3smeu6cdiseymxqywiaxcvh7hqpnno35ud5tjaq',
    'bafyreiaxvy7vwqnll4ya65lntq2usreclrc6ivs2jypn4agkuxltccpjfu',
    'bafyreifw4shigdpeeltimpkab7iamfpxcwflz5ex3zwbcsh4dtv6vd2bam',
    'bafyreigaw626gxpmj5igre4anqjs3aiiyc2odmftvryyxc7izcgv2treku',
    'bafyreib7f5rhn5sx6z57sinidc6clz5h7xxxen7kxrbqst5exmygmy7h3i',
    'bafyreifq22ly7wr26tjham7zn5am3zycrto2sarqb23miqj5345loa3bfm',
    'bafyreic2awaltcxydeumqgza2tz27xxao232pcrwoes6huhkernaa4xn6m',
    'bafyreihtphtv32vbh7xkxpym6xj72mehimoygvhrrm7bn76p6qtmqcccfq',
    'bafyreid2nxjhw5clyap4ynpeb2cxk47drfcthmc3ft6vedn36blb6rpf2y',
    'bafyreidavkuxuqogngjwq44q57th6nm6nnz3ysthda2ahcpgo45lqoabb4',
    'bafyreidxzh2xdmbrxz6zmdgibw5rpsi5v3okltsot5xijd4kxoqwccqrmm',
    'bafyreidmpasgiskdejiyu7ls7rtohjjk4z6yg4sitnfyjjbxfdd32j3orq',
    'bafyreidftv2bb4gs4ga455v635kb2qjcicsk5d35pl6jk27smhfrsklxiy',
    'bafyreihb3lzzz7ix4trwrcgy7lejdqoj55m6nhx2hdukfqhpx57xy3mvrq',
    'bafyreibubwkh26mwqjenabtdanmmorp5y6tkd3t7s4iyep6uck5esuvnw4',
    'bafyreig53sxnz5mtryqf7zszohc653xqbasi6htizzt7ljat7vqw3w272u',
    'bafyreifh6egt53wiw4em5npl3lnuklturg3qcgxdnjozptrkhfpa3th3xe',
    'bafyreiax5kuanglij4jgtm3qy3mmie3bblc4ewuuk6p7eoxqjicd7bgmhe',
    'bafyreibzlnhdhkcnqu3hj3icagb6ksfvkfhdkfreok2vyiabx3itodp43i',
    'bafyreif4rhaukizla3ze7zoldbdrn3rvrf2o4vpiq4uvboz2hckemvppqy',
    'bafyreiaz5cv3qz2ogth3zt6ppj2txdpxboeyjlxh2r44llgbuctkpsgcm4',
    'bafyreigcawhwy4ydqxpt2t2p245xhmykqlxdmjl5dtd4tjfnpasklnkq3i',
    'bafyreifyrkr4u2gra75k7saomlc7za4eve5666ay2slvmshnxkmxlkhplu',
    'bafyreic6q5s6crfll75dpmblygzp4ioan5r6kha4vymbfqp5vokhpp7eu4',
    'bafyreig2r2yfx46m4wia6t4uaap3ypca7gedulb5nkzpli4dttvtdos4hm',
    'bafyreiemv4cd6mym2xecsdi476gsialw5z2x6xzsifxy3x4lawws7cqony',
    'bafyreighevjewuigkrxdjbfkq2esxf2obcrlywj2dinkvagt2g7esspi3m',
    'bafyreigpocnftdr2ge2zdqpy5pbdtpfqnqyxt3f4zp6si7uxxib5zh5usq',
    'bafyreidmtaetfcl3r3l3wgcg37hi6iqx2jbcutsoecyeqtjhpfkafcknsu',
    'bafyreifcroutmcauorazt3nikkqjsijxz54btk5jmmatcvmrzbibr3gtnq',
    'bafyreihyhvvqjvql3qiuoeqw52j5liljovlogx756psyea7kb3a3bwywyi',
    'bafyreifcsgxo2ykisavx2dka6qxp6ogup74kepkxxfaoxy5eipidyzrvoi',
    'bafyreibinyymtskbtxvtwjyxh45snhcj4e5ndaxgazohe6glumunehbykq',
    'bafyreifl7mkpeam33dh5ivcqn5bfw4qcygr55u5wnmfe4hxyu2lgnjauaa',
    'bafyreicrkuxqcj7gehpzirtrsda4o5cyg6r46gsfpxdo2vfbzi2yzwecya',
    'bafyreifanwtx5gwgyt6r3nbrcy6732qgcd6ortlhivx7kzxmeasj7w6qzu',
    'bafyreie3llx4gst63uuqyvjhl6ektfvzbstjqoie335iehwjgky2r3k7le',
    'bafyreibhipkz5toooqxd2gnjkhtzlxtgrsf563mbhgahz7667g63st7ura',
    'bafyreibrougha2kgrzixuux46qnfuq5xb2mw24dkdt6vrjuzbdns56kzim',
    'bafyreifbns6dbwfpk4mmy7vsehovi6mjrxldz5w2zojzwcttfqkwql4mu4',
    'bafyreibw2z3w6um45oq4jlnwpvoppcgyl47qjewztgxh56lrerjznn6xse',
    'bafyreiftfpryvqtymuawqzy263hp2lo2szf4jctllidnw7w7h3tpgqrubu',
    'bafyreiazomnwgr5urfc7jydz7iglls6gygpnsbf4oe6zzdujgotcee5faq',
    'bafyreiaileqd5plia43nhww3xuhnvkihlt5gqgc6jm3vuyuyzpsx54xpvi',
    'bafyreibtr57dnt4pcisnhfmnvgcqyqe2c6vnu7vf7hefttk23rtg52xiea',
    'bafyreiexg4elf3gusrbyomcelv37tyen7zxhmhha52csljsfox74p376ia',
    'bafyreidqieggnvly34kpkdnc4vvr7up2ypc7udqq464cc6pwehg7jkmxhu',
    'bafyreibvq4luzc5fwtb5shvk3c5plqwati6iyifzsa5mp4irzlrfjvvqmi',
    'bafyreihi7gzvefo3rrttdoeqf2dmoun6pk2rjulnac4izl5ldeas7nkd5y',
    'bafyreic5lud6g33mldlwwj47d4lmjfbwbxqy3ns6rluk7qimw6tq7fyf5m',
    'bafyreihx4qmoc24pclhroquufvotsolt6lslylluc4skdfe3shvun25oee',
    'bafyreibikvvnzlpt6ugjhmmrqk3txi4gffdupdwmcah5aw4tabed32ih6i',
    'bafyreidygh7d2mlwykkmwupg3mq3kwabtovltfr6vfmoqvwdl6ubzhszie',
    'bafyreib7godh3ldf3bgb6wwbk2xhby4xjbkhm263r3lgmjzvrmiarmptrm',
    'bafyreifn6qlky3xqo3a53537dcus5syfqikrnok4zrjegmee53roy7trrq',
    'bafyreiaxkuuooo7fsn76rzqg2t7f65ndaspwvlbjyyts7iacrppzra7mpq'
  ];
    
  constructor() ERC721("Genesis Rocks", "ROCKS") {}

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(tokenId < 100, "0 to 99");

    string memory baseURI = _baseURI();
    string memory tokenHash = _hash(tokenId);
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenHash, "/metadata.json")) : "";
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
    return "ipfs://";
  }
  
  function _hash(uint256 id) internal view virtual returns (string memory) {
    return hashes[id];
  }
  
  function totalSupply() public view virtual returns (uint256) {
    return _totalSupply;
  }
    
  function wrap(uint256 id) public {
    // get warden address
    address warden = wardens[_msgSender()];
    require(warden != address(0), "Warden not registered");
    require(id < 100, "0 to 99");
    
    // claim rock
    RockWarden(warden).claim(id, rocks);
    
    // mint wrapped rock
    _mint(_msgSender(), id);
    
    // increment supply
    _totalSupply += 1;
  }
  
  function unwrap(uint256 id) public {
    require(_msgSender() == ownerOf(id));
    
    // burn wrapped rock
    _burn(id);
    
    // decrement supply
    _totalSupply -= 1;
    
    // send rock to user
    rocks.giftRock(id, _msgSender());
  }
  
  function rescue(uint256 id) public {
    // get warden address
    address warden = wardens[_msgSender()];
    require(warden != address(0), "Warden not registered");

    // withdraw rock
    RockWarden(warden).withdraw(id, rocks, _msgSender());
  }
  
  function createWarden() public {
    address warden = address(new RockWarden());
    require(warden != address(0), "Warden address incorrect");
    require(wardens[_msgSender()] == address(0), "Warden already created");
    wardens[_msgSender()] = warden;
  }
}