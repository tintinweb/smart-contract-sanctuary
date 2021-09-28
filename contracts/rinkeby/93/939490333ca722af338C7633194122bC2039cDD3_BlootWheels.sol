// This one keeps randomization of selects on row1/2

// SPDX-License-Identifier: MIT

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
    // back. This is the compiler's field8 against contract upgrades and
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

contract BlootWheels is ERC721Enumerable, ReentrancyGuard, Ownable {
    bool private toggle = false;
    uint256 public limit = 8888;
    uint256 public constant price = 1 ether / 100;
    bool public isFree = true;
    string[] private colors = [
        "250, 150, 0",
        "255, 0, 142",
        "111, 0, 255",
        "255, 200, 200",
        "80, 0, 10",
        "30, 130, 230",
        "170, 210, 220",
        "150, 90, 25"
    ];

    string[] private field4 = [
        "Metallic Yellow","Glossy Black","Matte Black","Electric Blue","Crazy Orange","Jet Grey","Classic Red","White","Lime Green","Gold","Purple","Black Candy","Static Grey","Scarlet Red","Ruby Red","Bubblegum Pink","Emerald","Sea Foam","Teal","Turquoise","Olive Green","Rust ","Cobalt","Banana Yellow","Frost Blue","Icy White","Tuscan Sun","Moss Green","Lemon Yellow","Lilac","African Violet","Salmon Pink","Raspberry","Marine Green","Kelp Green","Espresso","Chestnut","China Blue","Bloot Green"
    ];

    string[] private field1 = [
        "Desdamona","Eleanor","Terminator","Indestructible","Brum","Bumblebee","Oatmeal","Party Wagon","Gina","Bessie","Battle Shell","Beast","Rascal","Arrowcar","Boomer Siren","Underdog","Turtle Taxi","Waggy","Guardian","Spit Fires","Jitter Bug","Wired","Road Sniper","Lucky","Robocar","Purple Dove","Viper","Laser Sword","The Duke","Black Jack","Raven","Jet","Black Ace","Dementor","Spooky","Blade","Magic Grease","Zorro","Venom","Black Cat","Dusk","Sirius Black","Nightmare","Nyx","Black Bob","Vader","Bloodshot","Bloody Wheels","Annie","Rosy Roadster","Ferris Bueller","Hellcat","Christine","Crimson Engine","Rosanne","Naughty Santa","Lola","Red Wine","Cherry Bomb","Phoenix","Pebbles","Flame On","Blazing Saddles","Firefox","Clifford","Red Rock","Frosty","Alaska","Jon Snow","Milky White","Crossbones","Chalky","Diamond","Waxen","Marshmallow","Moby Dick","Fang","Ivory","Polar Bear","Sugar","White Rabbit","Bleach","Fluffer Nutter","Yang","Ghost","Elsa","Metalhead","Iron Man","Shine","Raiden","Bullet","Mystic","Magneto","Soul Ride","Ash","Dorian","Flintstones","Scythe","Specter","Tron","Shiny Gaze","Invincible","Conquest","Zeus","Death Dealer","Blitz","Rims","Payday","Drop Head","Captain Americar","Tokyo Drift","Grande","Hammer","Jolly Roger","Voyager","Everest","Fist","Carzilla","Wheels","Gorilla","Ace","Slick","Grandpa","Lazy Bones","Crasher","Big Booty Judy","New Noise","Little Piggy","Angry Bird","Slugger","Smelly Joe","Dirty Gerty","Squeaker","Shaguar","Doughsboy","Buckaroo","Crawler","Unwashed","Clown Mobile","Distress","Junkyard","Addict","Lightning","Knockout","Drag","Speed","Nitro","Flash","Light","Smoke","Race Machine","Bolt","Scorch","Sonic","Godspeed","Clockwork","Wildcard","Blink","Quickster","Angry Bull","Zinger","Bob","Madonna","Belle","Courtney","Austin","Barney","Jack","Scarlett","Selena","Reggie","Max","Hercules","Cleopatra","Duke","Marley","Cliff","Elton","Kitty","Sheldon","Rusty","Uno","Young Blood","Square One","Neoteric","Intro","The Core","Crisp Comer","Pioneer","Alien","Modernist","Swank","Expedient","Leading Edge","Starter","Upshot","Bright","Spring Chicken","Lambo Ghandi","Phat Dragon","Big Bull","McQueen"
    ];

    string[] private field6 = [
        "Engine: V69 69-litre Twin Turbo","Engine: V100 52-litre","Engine: V120 65-litre","Engine: V120 62-litre","Engine: V120 69-litre","Engine: V12 57-litre","Engine: V88 35-litre","Engine: V88 30-litre","Engine: V120 52-litre","Engine: V120 50-litre","Engine: V120 40-litre","Engine: V88 69-litre","Engine: V88 25-litre","Engine: V88 20-litre","Engine: V69 42.0-litre","Engine: V69 69-litre","Engine: V42.0 42.0-Litre","Engine: V42.0 69-Litre","Engine: X120 69-litre","Engine: X88 35-litre","Engine: X88 30-litre","Engine: X88 69-litre","Engine: X88 25-litre","Engine: X88 20-litre","Engine: X69 42.0-litre","Engine: X69 69-litre","Engine: X42.0 42.0-Litre","Engine: X42.0 69-Litre","Engine: X120 69-litre Turbo","Engine: X88 35-litre Turbo","Engine: X88 30-litre Turbo","Engine: X88 69-litre Turbo","Engine: X88 25-litre Turbo","Engine: X88 20-litre Turbo","Engine: X69 42.0-litre Turbo","Engine: X69 69-litre Turbo","Engine: X42.0 42.0-Litre Turbo","Engine: X42.0 69-Litre Turbo"
    ];

    string[] private field7 = [
        "Top Speed: 1600 mph","Top Speed: 1640 mph","Top Speed: 1690 mph","Top Speed: 1720 mph","Top Speed: 1750 mph","Top Speed: 1790 mph","Top Speed: 1830 mph","Top Speed: 1850 mph","Top Speed: 1880 mph","Top Speed: 1920 mph","Top Speed: 1950 mph","Top Speed: 1980 mph","Top Speed: 2010 mph","Top Speed: 2040 mph","Top Speed: 2069 mph","Top Speed: 2090 mph","Top Speed: 2150 mph","Top Speed: 2170 mph","Top Speed: 2420 mph"
    ];

    string[] private field8 = [
        "Weapon: Laser Blaster","Weapon: Flamethrower","Weapon: Bloot Blaster","Weapon: Bloot Launcher","Weapon: Laser Cannon","Weapon: Bloot Cannon","Weapon: Light Cannon","Weapon: EMF","Weapon: Cock Ring Cannon","Weapon: Ball Gag Blaster","Weapon: Plasma Cannon","Weapon: Machine Gun Turret","Weapon: M4 Cannon","Weapon: Missile Launcher","Weapon: Ball Gag Cannon","Weapon: Cock Ring Blaster","Weapon: Turbolaser","Weapon: Particle Beam Cannon","Weapon: Phase Cannon","Weapon: Pulse Cannon","Weapon: Karma Cannon","Weapon: Meme Blaster","Weapon: Dildo Blaster","Weapon: Dildo Cannon","Weapon: Dildo Launcher","Weapon: Bloot Beam Cannon","Weapon: Particle Beam Cannon","Weapon: Particle Meme Cannon","Weapon: Ban Hammer","Weapon: Bagel Blaster","Weapon: Dorsal Gun Turret","Weapon: Baguette Blaster","Weapon: Baguette Cannon","Weapon: Baguette Launcher","Weapon: Lemon Launcher","Weapon: Brass Knuckle Launcher","Weapon: GM Post Launcher","Weapon: Trinket Launcher","Weapon: Capitulation Grenade","Weapon: Capitulation EMF","Weapon: Capitulation Bomb"
    ];

    string[] private field9 = [
        "Thruster: Light Boost","Thruster: Light Trail","Thruster: Plasma Boost","Thruster: Bokeh Effect","Thruster: Dust Cloud","Thruster: Flowers","Thruster: Rainbow","Thruster: Geode","Thruster: Gemstones","Thruster: Rumble Strip","Thruster: Tire Tracks","Thruster: Vapor Stream","Thruster: Red Licorice ","Thruster: Ice Storm","Thruster: Xmas Lights","Thruster: Candy Cane","Thruster: Binary","Thruster: Lightning Bolt","Thruster: Shark Infested Water","Thruster: Yarn Trail","Thruster: Kitty Cat Paws","Thruster: Tentacles","Thruster: Egyptian Hieroglyphs","Thruster: Ancient Ruins","Thruster: Feathers","Thruster: Sandstorm","Thruster: Butterflies","Thruster: Roses","Thruster: Lobster Claws","Thruster: Meteor Shower","Thruster: Shooting Stars","Thruster: Dildo Trail","Thruster: Shooting Shitpost","Thruster: Laser Boost","Thruster: Plasma Trail","Thruster: Laser Trail","Thruster: Meme Trail","Thruster: Meme Stream","Thruster: Cloud Burst"
    ];

    string[] private field10 = [
        "Accessory: Packed Lunch from Mom","Accessory: Fish in a Bottle","Accessory: Rooftop Cat Carrier","Accessory: Rooftop Dog Carrier","Accessory: Real Men Use Three Pedals Flag","Accessory: Blow-up Doll","Accessory: Neon Beer Sign","Accessory: UFO attatchment","Accessory: Waterslide Attatchment","Accessory: Rooftop Waterbed","Accessory: Rooftop Hottub","Accessory: Stripper Pole","Accessory: Pineapple Upside Down Cake","Accessory: Detective Hat","Accessory: Cow Skull","Accessory: Clucking Hen","Accessory: Stack of Pancakes","Accessory: Chocolate Bunny","Accessory: Tombstone","Accessory: Gingerbread House","Accessory: Freindly Ghost","Accessory: Lucky Clover","Accessory: Non-Fat Extra Hot No Foam Latte","Accessory: Drink Helmet","Accessory: Fedora","Accessory: German Beer Boot","Accessory: Homunculus","Accessory: Guitar and Amp","Accessory: Baguette","Accessory: Campfire","Accessory: Propeller Beanie","Accessory: Popcorn Machine","Accessory: Birthday Cake","Accessory: Craft Beer Sampler","Accessory: Party Keg","Accessory: Rotary Phone","Accessory: Christmas Tree","Accessory: Chastity Belt","Accessory: Bonus Cup Holder","Accessory: Dildo Gearstick","Accessory: Erotic Sat Nav","Accessory: New Car Smell","Accessory: Up Only Doors","Accessory: Junk In The Trunk","Accessory: Secret Cock Ring Compartment","Accessory: Hidden Ball Gag Compartment","Accessory: Leather Seats","Accessory: Heated Seats","Accessory: Suede Interior","Accessory: Automatic Transmission","Accessory: Go Faster Stripes","Accessory: Carbon Fiber Bonnet","Accessory: Bloot Dogg Spoiler","Accessory: Blootsuit"
    ];

    string[] private field11 = [
        "Rims: Steampunk","Rims: Vortex","Rims: Sweet Tooth","Rims: Alchemist","Rims: Mountain Climber","Rims: Spider","Rims: Stallion","Rims: Rat Rod","Rims: Tempest","Rims: Sundial ","Rims: Time Machine","Rims: Ice Crusher","Rims: Grim Reaper","Rims: Tnt","Rims: Cassette Tape","Rims: Cupcake","Rims: Cyber Space","Rims: Emerald","Rims: ET's Finger","Rims: Flower Child","Rims: Ferris Wheel","Rims: Ghostbusters","Rims: Hamster Ball","Rims: Party Llama","Rims: Mandala","Rims: Ninja Stealth","Rims: Powder Keg","Rims: Propeller","Rims: Rocky","Rims: Short Circuit","Rims: Jitterbug","Rims: Sk8er","Rims: Sprocket","Rims: Stay Puft","Rims: Stuffed Crust","Rims: Sunset","Rims: Watermelon","Rims: Road Whisperer","Rims: Good and Evil","Rims: Mothership","Rims: Time Bender","Rims: Doughnut","Rims: Garden Gnome","Rims: Gremlin","Rims: Moon Print","Rims: Peppermint Twist","Rims: Submarine","Rims: Witch's Brew","Rims: Clockwork","Rims: Lone Wolf","Rims: Disco"
    ];

    string[] private field2 = [
        "The Rally","The Labyrinth","The Electrical Storm","The Upstream","The Tigress","The Webs","The Pain Bringer","The Firework","The Flash Freeze","The Lattice Pie Crust","The Camo","The Falling Leaf","The Chance of Rain","The Snowstorm","The Ectoplasm","The Kaleidoscope","The Violet Haze","The Rally Stripe","The Seismic","The Tribal","The Checkerboard","The Plaid","The Angel Wing","The Skull","The Blue Flame","The Inferno","The Eruption","The Typhoon","The Tropical Thunder","The City Smog","The Baby on Board","The Tornado","The Paisley","The Mountain Range","The Zipper","The Outerspace","The Wet Paint","The Zebra","The Cheeta","The Dildo","The Cock Ring","The Pendant","The Chain","The Choker","The Trinket","The Ball Gag","The Bear","The Bull","The Zombie","The Alien","The Ape"
    ];

    string[] private field3 = [
        "'00","'01","'02","'03","'04","'05","'06","'07","'08","'09","'10","'11","'12","'13","'14","'15","'16","'17","'18","'19","'20","'21","'22","'23","'24","'25","'26","'27","'28","'29","'30","'31","'32","'33","'34","'35","'36","'37","'38","'39","'40","'41","'42","'43","'44","'45","'46","'47","'48","'49","'50","'51","'52","'53","'54","'55","'56","'57","'58","'59","'60","'61","'62","'63","'64","'65","'66","'67","'68","'69","'70","'71","'72","'73","'74","'75","'76","'77","'78","'79","'80","'81","'82","'83","'84","'85","'86","'87","'88","'89","'90","'91","'92","'93","'94","'95","'96","'97","'98","'99"
    ];

    string[] private field5 = [
        "Beach Wagon","California Top","Convertible","Coupe de Ville","Dickey","Dual Cowl","Formal","Fast Back","Glass Saloon","Imperial","Hatchback","Liftback","Minivan","Phaeton","Pillarless","Pullman","Roi des Belges","Rumble Seat","Saloon","Speedster","Roadster","Spyder","Suicide Door","Superleggera","Surrey","Targa","Tulip Back","Barouche","Barrel-Side","Barchetta","Chassis","Coach","Craftsman Top","Dorsay","Station Wagon","Lambro","Innenlenker","Limo","Meowyura","Countache","Jailpapa","Deeyablo","Centurian","Hurricane","Aventaduh","Sports Roadster","Yellow Flash","Hayai","Rapido","Velocity"
    ];

    function setFree(bool _isFree) external onlyOwner {
        isFree = _isFree;
    }

    function withdraw(address treasury) external onlyOwner {
        require(address(this).balance > 0, "No ether");
        (bool sent,) = treasury.call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getField4(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIELD4", field4);
    }

    function getField1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIELD1", field1);
    }

    function getField6(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIELD6", field6);
    }

    function getField7(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIELD7", field7);
    }

    function getField8(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIELD8", field8);
    }

    function getField9(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIELD9", field9);
    }

    function getField10(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIELD10", field10);
    }

    function getField11(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIELD11", field11);
    }

    function getColor(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "COLOR", colors);
    }

    function getWave(uint256 tokenId) public view returns (string memory) {
        string memory wave;
        string memory color = getColor(tokenId);
        wave = string(abi.encodePacked(
            '<defs> <path id="gentle-wave" d="M-310 250c30 0 58-18 88-18s 58 18 88 18s 58-18 88-18s 58 18 88 18s 58-18 88-18s 58 18 88 18s 58-18 88-18s 58 18 88 18 v100h-590z"/></defs><g class="parallax"><use xlink:href="#gentle-wave" x="48" y="0" fill="rgba(', color, ' ,0.7)" /><use xlink:href="#gentle-wave" x="48" y="3" fill="rgba(', color, ', 0.5)" /><use xlink:href="#gentle-wave" x="48" y="5" fill="rgba(', color, ',0.3)" /><use xlink:href="#gentle-wave" x="48" y="7" fill="rgba(', color, ',1)" /></g></svg>'
        ));
        
        return wave;
    }

    function getDurationFromTime() public view returns (string[4] memory) {
        string[4] memory durations;
        uint curTime = uint256(block.timestamp) % 1000;

        for(uint i = 0; i < 4; i++)
        {
            curTime = (curTime * curTime) % 1000;
            durations[i] = string(abi.encodePacked(4 + (curTime / 100) % 10, '.', (curTime / 10) % 10));
        }
        return durations;
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;

        if (keccak256(abi.encodePacked(keyPrefix)) == keccak256("FIELD4") && greatness > 14) {
            string[2] memory name;
            name[0] = field3[rand % field3.length];
            name[1] = field5[rand % field5.length];
            output = string(abi.encodePacked(name[0], " ", output, " ", name[1]));

        }
        if (keccak256(abi.encodePacked(keyPrefix)) == keccak256("FIELD1") && greatness >= 19) {
            output = string(abi.encodePacked(output, " ", field2[rand % field2.length]));
        }
        return output;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[18] memory parts;
        string[4] memory durations = getDurationFromTime();
        parts[
            0
        //] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="#01ff01" /><text x="10" y="20" class="base">';
        //] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <style>.base { fill: #f2d88a; font-family: sans-serif; font-size:14px; -webkit-animation: glow 4.2s ease-in-out infinite alternate; -moz-animation: glow 4.2s ease-in-out infinite alternate; animation: glow 4.2s ease-in-out infinite alternate; } @-webkit-keyframes glow {from {text-shadow: 0 0 2px #9c8c54, 0 0 3px #9c8c54, 0 0 5px #9c8c54, 0 0 9px #9c8c54;} to { text-shadow: 0 0 2px #9c8c54, 0 0 3px #9c8c54, 0 0 6px #9c8c54, 0 0 10px #9c8c54, 0 0 13px #9c8c54;}}</style> <rect width="100%" height="100%" fill="#003C5F" /><text x="10" y="20" class="base">';
        ] = string(abi.encodePacked(
            '<svg class="waves" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 350 350" shape-rendering="auto"> <style>.base { fill: #d4af37; font-family: serif; font-size:14px; } .waves { position: relative; width: 100%; height: 15vh; margin-bottom: -7px; min-height: 100px; max-height: 150px;} .parallax > use { animation: move-forever 25s cubic-bezier(0.55, 0.5, 0.45, 0.5) infinite; } .parallax > use:nth-child(0) {animation-delay: -2s; animation-duration: ',durations[0], 's;} .parallax > use:nth-child(1) {animation-delay: -2s; animation-duration: ',durations[1], 's;} .parallax > use:nth-child(2) {animation-delay: -2s; animation-duration: ',durations[2], 's;} .parallax > use:nth-child(3) {animation-delay: -2s; animation-duration: ',durations[3], 's;} @keyframes move-forever { 0% { transform: translate3d(-90px, 0, 0);} 100% { transform: translate3d(85px, 0, 0);}}</style> <rect width="100%" height="100%" fill="#003C5F" /><text x="10" y="20" class="base">'
        ));
        parts[1] = toggle == true ? getField4(tokenId) : getField1(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = toggle ? getField1(tokenId) : getField4(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getField6(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getField7(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getField8(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getField9(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getField10(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getField11(tokenId);

        parts[16] = "</text>";

        parts[17] = getWave(tokenId);

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );

        output = string(abi.encodePacked(output, parts[17]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Wheels #',
                        toString(tokenId),
                        '", "description": "Located in the fastest region of the metaverse you can find 8,888 rocket powered Bloot Wheels racing around on the the ETH blockchain.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function mint(uint256 tokenId) payable external nonReentrant {
        require((isFree && msg.value == 0) || (!isFree && msg.value == price), "invalid price");
        require(limit == 0 || totalSupply() < limit, "Limit reached");
        _safeMint(_msgSender(), tokenId);
    }

    function multiMint(uint256[] memory tokenIds) payable external nonReentrant {
        require((isFree && msg.value == 0) || (!isFree && msg.value == price * tokenIds.length), "invalid price");
        require(limit == 0 || totalSupply() + tokenIds.length <= limit, "Limit reached");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeMint(_msgSender(), tokenIds[i]);
        }
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

    constructor() ERC721("Bloot Wheels", "WHEELS") Ownable() {}
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

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}