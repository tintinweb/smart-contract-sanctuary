/**
 *Submitted for verification at polygonscan.com on 2021-10-29
*/

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

    function lastOwnedTokenOfOwner(address owner) public view virtual returns (uint256){
        require( ERC721.balanceOf(owner) >= 0, "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][ERC721.balanceOf(owner)];
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;


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


pragma solidity ^0.8.0;


library SvgBeforeImage{
    function getBefore() public pure returns (string memory){
        string memory beforeSvg = '<svg     xmlns="http://www.w3.org/2000/svg"     xmlns:xlink="http://www.w3.org/1999/xlink" width="320.5mm" height="106.892mm" version="1.2" baseProfile="tiny">     <desc>Created by HiQPdf</desc>     <defs>         <linearGradient gradientUnits="userSpaceOnUse" x1="-35.8614" y1="98.5284" x2="367.861" y2="245.472" id="gradient1">             <stop offset="1e-07" stop-color="#fdbb2d" stop-opacity="1"/>             <stop offset="1" stop-color="#3a1c71" stop-opacity="1"/>         </linearGradient>     </defs>     <g fill="none" stroke="black" stroke-width="1" fill-rule="evenodd" stroke-linecap="square" stroke-linejoin="bevel">         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>';
        return beforeSvg;
    }
}

library FirstHalf{
    
    function getFirstHalf() public pure returns (string memory){
            string memory imageFirstHalf = '<g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)">             <image x="13" y="19" width="397" height="397" preserveAspectRatio="none" xlink:href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAY0AAAGNCAYAAADtpy3RAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAgAElEQVR4nOzdy3Lb5rY17DHmC5A6WEl2ubIbbqTx19dLMzeQm1j34/tZN7FuIM30vvoaq+HG2uXacWSKIoF3jr8BgKIUyYZjidZhPFUwJFEHkCYxON8TADMzs5n4rQ/gE+Yemx70KMzMbKf51gew5zMh8faO29/e+4HM4KAysxfpW1Yat/ztu4IB+Ad+v/W2f+Lnb3ACf3vov+mQMrNH4VuExo2/eT0obobD/+Dna5+f//Lu2uf/32//m5/6/ofwLyA/+0336uAhBTiozOwWhwyNO8NiCor9E/5+OFxevrn2sz9t3u8+/8/3mwOfwIGz394c9IT6r4OHFOCgMrPbHCo09v7OEBafCorLyzfcD4Z1/5oAsOk/XDveba743yfLuv+16Xsf0vnrd/Xz33V/Dh1SwIsJKoeU2Rd66BPsrdXFP/A7p7C4LSjW/WtOAbHNFQHgdf1u/Pxi9zs7veLl4o8vPoFPv+vv2h6/OmhoHDqkgJcSVA4psy/1kKHxyeri/Jd3nJqdftq85xQU+yGxzQt2ekUA6H9Ys88TAsBZbq6C4+Pi2gm1/2H94JXG9+fLg57EDx1SwMsIqn89/5ACHFR2zw4QGrdXF1NlsR8W+0ExhcRZbtjnEWtuWLUlAJzoiABQc0stTvv9P1r3AuWh5FHff/677s+hQwp4GUH1/EMKcDVl9+2hTrC3BsZdYXHWNbEfFMc9YwqJEx2x5pZVS9aTjqkFj9QRADIXjG7dAUDVcvZ9qSfdV93v6KL7mp//UocOKeBlBNVzDynA1ZTdv4cIjc8Gxh+XTUyVxapG9D+sedyX6POI23oeJzritjLqScdFMjIXTHVM9VyqZaIy1RAA2JQudT0EUv3DVhuLw4bGoUMKeBlB9dxDCnA19YBebFA9UGh8PjDOuibW35fYD4tljdgeRyyS0VdGqmeriFTDZsFIDWEh9UxUtmrYt7ldjAEySdUHDY2u9tuH/P1/ceCQAl5GUD33kAJcTT2cTwbVsw6U+z657qqMuwLjrCsxVRft9rTcDIttX0uriH7BaJJRE5GobJJRW0arwkRSqpQKI3MLAImr4FD7sKHRiJuH/P03HTykgBcRVM89pABXU1/jR/x+6+/96yoUn610nlWI3OfJ9VpgAMMoqf/5GXEzMC6/Yxz3jKbvyrYyylFf+soomSXatvTJiKylitE0iKouqhhFjBSiaQqlpJCswqZVGfo4kFfBoXiw4FCblw/1u29z6JACXkZQPfeQAlxNPYSbq1B8eimjWwPlSYfIg4XGVGX894dlTE1SR9sfyuV3jMV2W5YZsV72pemXpdS+bBdZorYlspa+yRKZJbIpVYjSMGpmiTE0hGQpDCEpxWVBUmNwaC84gAcLj/UD/M47HTqkgBcSVA6pe/ecqqnj5v2tJ/dpFYqbFc7NymRGRfIkw+OeQ2Poy/gViKlZ6scV4nz7Ls66Js7Pzspxz+B21VweHZWm70vJLGii6bKWyLawdE1kU1DY1MxCqaQQUVSYpQjJFCPKEB5QXBaIUzhMoSE8XKUBHTY0cOCQAl5GUDmk7t9TCar35c+/dcJexKl+OOrz38vX137+6Ojd7vP9MJmC5HqAPO3wuPfQmKqMqVnqPxebMnV6t9vT0vRdWS2iafq+sEaDJprIWljYbLNvmGwYbJBsoqgg2SQQiNoMlUaUCIQgSoiALjEGxNBkdRUWRXqQ4KjkxUP83jsdPqQAV1P37rmHFPC8gqr54/gvJ/OWH7VZXoXUsvlewPWq5N/L15pC5NMBci08nkxw3MdJlfv9GP/vl/+KqUlq6sNoX20LtqVZL/sSXTRTWLBuGzTRqKplsFEOeyQbFDbI2qSiMFQgNhIiApHICCEkBMaTmxAMjCERvPN+CV8fJFGx+trf8SUOHlKAq6kH8OxDCnhWQVViee1E3sTl8Plq2wPAIk4EXFUtizgVMATJFCK3BciP+F13BAfwBMLjXi/C9D/4mZeX4LoHt/mO22x4+d1Z5JbBymj6ZWFuCloU9X2jolY9W5ZsskaLQJsVbYls2bOpwQZAI6ghWAIqAiLEEBgCAsAQFgFqF4K6MxxCdwfKHCJWWXD6Nb/jS5V6+OdR/bqH6ct9g5cKuzjo3+vbw44Mbcvhr7HWbQ/eOoVcfPnPlIv2s8+4xHBfCjcCgAqgxEI4XeB8DJQmLnT0xw8ChipkESd6n+90vh1C5MceOt4s9e/la13+DB4dvRN++xn/wO8AgH/uLiK3Cw/ikQfHvVUav479GPtVxoezTZmapGpbW3bRoI0m+2xV1GbPBUKtUm0TaJNcINUq0CKjBdVCbBDZUGxAFiGDiqKhtBgrDVEQ9wPh7ori6/o6CB20ygCGoDr033Q19SDc5PcAHqKiCja6/vkQMhFbla50FxyqjsKFSizVxKXOY6kmLtT8caxdgJQ/tYhTTdXHVHl8pup41KHxtW9F9ifx7b64zRW32bDPM6qeR7dsSnQRWmRR3zeL0jZZc6ww2BbGorIuSuVCgRbgAshWRAuxBdAIaAgUCo2gCCASKgTJoZmKAsdOcPGuPAx9XVB+ZaHyt1CHfw5lOezfczV1/w5dSQGHr6aAh6moguXa/9aWW8WmqKIAiwrxRMGteFFEroRYqPCjggvxJHTenOVUhbT8qPN8l5t+r/L4GdqvOobgeMsxOB51tXFvj/Y0Wmrdg6/rR64UPO4ZjY5Ys4YyCzKiZlu26JsmoskabRPZDoERi6SWIlqCS5DtWHi2AJoQW1EFiCaEUKiEOIaFKDD2AuETfRr5dZWGDv9CfAlBdeiQAg4fVM89pIDnE1Tsrl4AgV4FAEPq2Cs66hhVG6bUViWPhdiK0SQviprSZamX0ZazbF5dat2UPPrjFU9L5vt8p01/qp/wPv+NN8Av7/DUguMeQuMtMbbPAeOFknLDy+/OYrHdMGsJBUMLhPpamgZFPRuQDUJjk1S0GVgIWBBYKrEgc0FwQWBxVW2oGY5ZhUAIUQCEAHKcvwEAGjvC4x46vW9SHv6d1EsIKldT9+/gIQU8+aAic7gHrAiEAKAjFAiRvRoWJZsEey25VL9VkhttMzPYRDnqcx3ich25wTmAszzuL2P9wzq3HypRhkfoj8smZgTHo3QvlcbUAf7T5j3/kxuGfuBZbogssTpmHG8ZfW2KhnkXTZQsgFpVtKTaoBZJLAgumViKWhJcCFwktQhgIail2BBsMlAghKASYECgAhFThTFWHFNz1XVf90piHD40XkJQuZq6fy+iyQ+4l6DahcX0OUICQNYxMFJEEREKpjpKpeuyFqVQ1EZkH0ptlWAmlqUyIrle5UXJXOQZ19+vMFUc5239xIv68QYGcM+jp4ZLrb5D/8Oa3J6SueKiHkcvRtUmmqaUvleJZAOwYagZmqOijdQiwQWIBZHLJJZMLEAsxw7xBca+DQAFQCFYJMUQGKKGMw9vBgOvVRxf9/+hb/Cu/yUElaup+/cSmvyA+wmqoVsUIHbhMe6p8WMBUN/XBKAgsg9kIbIwsu+RDZVZSl2GMrsuIqJiyWwul7VRR+AU6++U+DNwBuAPAFO1cTb+vX/gdw4jqh5vcNxbaPy0ec81XuN1/Y4fsEHNDfM4IrqO7aIEO0aPLKWgENGAbEqvtjJaIRdgLAgsCU2BsSS5BLAEtBj6ONSOx1yGjnEVQBFgSOQ4BBcx9HHsjaTaf1J9XZMVv0H9/RKCytXU/XsJTX7A/QVVJTWFB5Aih6lggVQOK+kKYBIUgQwog1H7XlmIzOhrRtbso2ZZhEoX3EblIrhuNvV4AywyefndAvgzsC1/6o/L0/gJ7/M/v2yI336+uRTJo+zX+MrQeLu7Et/xh+WuP6PPMxZ9pHTCZdboyShNU0qtQUUhs1RlQaABsxHQcgiEVuCCqSUZSw2BsUxwGVALopXQAigcqo1GwRjfJjDG0LgKjFsC4itniX+TZpQXEFSupu7fS2jyA748qDhUD38RAJDDHUiEoKHqIJFQCESWQikzhxlfWfteNYisZC1sa/TqM/qqyl7KyIbBfsNQcLUIHl1ua4ml1t8BZ+eNzttVrvs3vLwEp74NAI+6X+OrK41/4Hf+P/zXta+d5YbQEas6JsSqPgBElLb0fS0cOrCHTm2xJdUIaENDHwbIBcbA0Fh1JLEA0AbUIlVANhgm/O0m+Q37OwLjvpYU+QYvipcQVK6m7t9LaPIDvjyo8kb/xe73gLtCg4CYVIKCUkFlAkkwhUgyq4AkoyeQpPraqyJUVKNX9LGItlcVsyzIPtmgx+XREU63nY7RYv190dkH4Bzv8FOz1NRMNTRRfWrl3G/r3pqn1v1rbvMdQz+QGWSumHnMuthG2xV2qAH0UUqEoIKxX0IYAgPTRrUUF2QucuwYJ7EEsIDQCmiHwEDBMJqqYCjjYtiG7ivcHHZ79WT+umf1NwiNlxBUrqbu30to8gO+/LlK3f6C4l5TUDKFoAhIGQkgQ0pRiSk4oF5ABbOCpQ+qx9BbXsiIWmuwkOy3VLMAe6BBj/UydbwBmijqdKzXNfnHZd01U/342+Nrktp377Ni+h/WjMuG1JJSx4UadlK0KARqVCBiDA0hGoJlN5RWbAJsJbVCtAG1Y4WxgHYVSKuheWro2xACxK6JiuO8jbtHSX1lxfFNRoc8/6ByNXX/XkKTH/DlQZW8vXlqmBwx3EZpCAwqGZQSOQyxyhpACqyCKsA+wb702SvU18qOwVAlWZLZB1lE1i3YhtCnol9qW1PqGdvvqPb8QtvsOTVT/Q/ecBh++xYYlhl5VCHyNaGxe5VfXr7hGbDrBAeAetIR22QKVCvWLoJgcFw/SogyhQeCBVCTzCaABmCDsQ8DQAuhnQIDYMsxZDT1bWgMDe7Wn+InwuEbnPW/0ksIKldT9+4lNPkBXx5U1O2hAVxVG0OwKCkqmQqwJpAUUsGEVAH001bJDlQXVICMiGRfSYao2oCNhEpF2wpdLx2lSley9NT6+6LX5yc67z/wp03Px15t3Fulsek/cIGCPk92neDHquxV2CLZoRIKYhgnGyqIITxUQihDkxWbBBqCY+UxTeZDS6KRphFUbAA1Y7VRAQSoEBichkrxWjg8vaD41g4+e9nV1H17CU1+wN8Jqr8+Ljl1jufY+T2M4E8MJ5ZUICNZh69haJaaQoPDtA2AhVSwImoRCwtrJqKkVKkooU3diosQe+Z22RdtL1XzVW7znNvsCSwBDHPfbj3QR+BBl8FMVEpiEiyFQQ4r06YUQsawDEiUhEooyjgOoihQAhgCJNWAbIZRU2qAaa8G4tB+KBBkEEO1gU80T925KNVMj/J/8TlwNXX/f+4lNPmBF1K8+sKf+stBThUGY6w0ADGRJCQwiazDcCpWAn2INakOQ3A0YBQAJSmSilIDtVQ0omotiiJts8/INktmRWZpkll0xL5ndHqVr2ty3b/i5SV41SGOR7ekyFeFxnTBpenzbV4QOMPJOHJKGIJjePdPQkPz0XDxJAzLm+8+zgA5TNoTSk5NT7tOb1yNuIKGJiyicJiGMXSCawoNAlfhcO2V87WP/LcoWR7Ns+W5ee7VlJv8Pks3ht9KwyS+oJRBIZUihkGggQyxJrIn2MewvFEnsAAZyggGKYJJClmUoeHKP8mkmNFk7bIWLiLZM2plKDa5/W4R7fmFNn0l8D3Of3n3aJuo7r3SOMvNOIUCSDVsJdahf4FgUoph9jaC0/LmAoJiGa6RoUKwDBP3OI2wKhwm9I19GCxjYDQChKkzfAiPm2Fxr8/ib/G/6KB6Fi5BHh/0L7rJ7w6392kQUk5PfTGDkKAkIgFVAFVApdgL6gl0SZWhrxYhKpjDWWho0YKUkMREUQZUWaMJtZU1ssla18eM023EMjfZ6RW3+cfQr3E0vQQf33yNewmNnzbv+cfer6q5ZeYxh2Y/IJEMBDTMxNsFxvDxtNggyKlaQIaCEVBRKjhVIFNwcBquO6bTVGlcDb0Frp9rn3SfxqGfMQR6An/j0jZ/36N6VTwXbvK73a3lCTU0WQy/UMM0PymYlHKvD2O/L2N4A5uKDAUFiiElFEAimGImhYpkBdj0yloalj67CrWxqIyaWypP2f+wIi6G6QvTKCo8wpfGvVUa21xxeePX5bKSWxEECpJjPhBKBkiN1/oGQIExTMATOc7yFhAg94fUDv0WV01R+0ExfcwxgJ5NaByaqyn7255Ck9/0M9eG3gpTcIzfMKwxBaSA5FXn9xAaZIepVYQgUlQAIWlsiU8MM8ezSFUNK8UmkH2fKk0yyoLR1Y79cUR0GwLDCNTDX6P3y9xr81SnV8PEvhsXfWtVhhM5h1EOQoyXZ02GSIEMgBnDxZXG/7lpi6shtYphtZBdYABXgbELjvFp+yDNU/YwnntQOaAeyN8Lqbv+O7SXQomr9aYqoMpUT6KC6CCVHJrRp3E4QCYUTEDDCCuiAtlXsUFmKVCBSinIiKaUPhltMtZaULpgzVfc5jk3feVPm55rvP479+3BPcjoqbo3sa/i6prvUgxBAe5GxmpsosIwXpZ7Cw/ugoPDANppRNQ4ge9ahXEtNMY/59CwTzrkidyV1GNy1zyNcUIfxlVtiZSwCwGQjYaKowNQmAjFUJ8IhEhBqjG0SfUE+2GawDDCqoJFymEZPnVRhQiQR0oWHRG5ufY0Of/lHfHbGzy2fo0Hv/J8oiFReVUYTHRVZWioOqalzWOvmQl7ITE1O0lTiPylOermts/hYd/Mc6+kJo/mzPZJd7ZpXQXGMIpqqjYqhj7UnsPozg5ADM1SQxtWIAUxRQ39HlSrod+j5zigB0AJMFJ9VDFaFfaLjFIXRK6pPKW04Db/2M3XeIzrUD14aEzGq+pRiKGX4jNPL12tH8Wp32OoA0WQ18LhjsB4qD6Nw89eMvsbXkJQ3cN91N5HQyf4UDQkwMTQp1E5bAGwB7SERJEQMUz+Q1RINRAtNM7dGCYql2E/zEHLYUJHhAqrGMMySx2lJZUb5g/9rjMcePf19+4BHCw0brrqAB+DIbibzzF8TXsnfw6f7zVRAZ+sMvbd9/P4W7yBc1DZk/ANRvp9Md11mJQwXCtDABNCariC2zhiitN5qR37UjTUGqiQKogezCY5rWrBwtQYFlGIDEIlx/lpaitTZKonTpIxXrb2sXeGf7PQuCefapZ6qD6Nl/AGziFlT8I9vRin4VTjHI0xDIgkkJhaOK7exLakJCEhVOzWy0OT2k1ALgRKxjCPI4BgZVROk5yTrQqrgkuRa5VdZ/g0VeHy8g2B/72fe3iPnnpofAsvoanY1ZS9JLq259ifoSE4rlo4dit6NOPM8aTUZLAJqElgV1kQUZIqVBRCkcxgYcS43JHESCSlZCI5TTmbbPoPBL7f/9KjmbPxXEPjIfs0XkKl8RLuI+CgsuvP9f3htjE2PSWnEmQYXSsM583EuMzRjWWPhonHGtbWy3GuWUjDx7u+3SQkJsAC4kgdi454jmk5puXhHoEv9HdCg8BbTutOHf+f9+U/F5tytP2h8CSa3PSt2tq2pSy6TkuyHgE4HrfnwJXGw3juQeWAepy094H2ywlc9ZsON3M3umpvWaNptYph2aNxGaTgcDGmoapIBBgMJFOMcTklAmArMkWWsUnq7Maw2//Bz+O1NR5HlQF8ZaUxXRt8LiFOInCayFMKpwKHfeCUwiuAJwBOAZ1gFzQ8AjRcuW/YdsulY6jpPrWEyHMZZutK42E896kaDqp5hhVurzdT5bXbxxUohhFU2C1rBGUwWBIIZsYYGLFbHokaJi6Le8ERBIbllcq0Tl8Ow27LjWaqx+hvh8awuu273dCw/oc12+3pfR7bl3ouAfEYPPcT+OSQ9/O537/JUwwq3bG/up23TCQmAuNIKALBYChFCdSwbOEwEjQYkRouBsjgsKSSmACkylySpf41LH7avH+Us8LvpU9jumJfzQ2JglS/u2IfuqEMw3Dxpd1M8H0xTcXH7beP9qsHB8Tz89yD6rnfv8lTGuk3PT7c+3z3tZvD+bmbIqCAeHMVCmpYDykSiKuJy2JSRASV3C16IhW2ADU2S036PPrLBL/H5t47wofLvN59u26ZCT7cMo1OEIfZ/Bgn8e2GumHXIWV2P1xp3L+n1P/2qRFJfxnOf7USBXcrUuj698Sw3uqu2pjOX8B443Dp8bh2zPsT/J5CmfZcR0+ZPTYv4QQOPL3+t5vBca1F41q1MYaAhnezf6lCpu8flkMSQ0FxqDZE/eVxSSSFho+/F+M6h4bZ8/XUTuB/x9fex5ujpbS/8WrtqXFjx2HBwq3ADYDLYdNawArABaSPRKxErAiNe14kcEFoLeQlgEupXLYtN12tW3ali2XT6SL7y8Uf9b9PlnX9f1/XH/G7/ol/jqvtPg4ODTO7Ly+omrrWdM6rtfJEBYfra0yfj+1Zz4VDw8yesq85G0/Vxf7n9hlPod/FzMweCYeGmb1UN6uUm8P6Pbz/Fg4NM7MrDonPcGiYmdlsDg0zs0/bb6Y6WCVy/su78W+9fVTNZA4NM7MZ+JkTN8fZ34G/TuQDgGEZpaA0bm1lqg5X7gNQc8P+hzWB6XKv0xp/j4tDw8zsy1zN0dC07NEUFNPyUsNySUCMyybdHiSTetLtbn9dv3t0QbHPoWFmZrM5NMzMbDaHhpmZzebQMDOz2RwaZmY2m0PDzMxmc2iYmdlsDg0zM5vNoWFmZrM5NMzMbDaHhpmZzebQMDOz2RwaZmY225eGBoG3/BWI81/e8ez9m7JYfywfzjYlLpsm22yxzbYtzaKnluziCMAxiOMinWTBKYVTgeM+Txk4leIVoRMBp5BOhp/hMYAjAEsACwILAQ2utnKfD4SZmX3eU680Ym+7eZGUR728sJnZU/TUQ8PMzA7IoWFmZrM5NMzMbDaHhpm9VLpln3tbBdAD6An0AraHP8THx6FhZjbfFsAGwCWkNYA1yAsCK4EXZH5UYkXESsSK0ErEKipWlbyAsAawVpuXjbjpar/FIrroosujvv/+fFm3x6/q+et39ey3N/oXkMBb4SrYvjmHhpmZzebQMDOz2RwaZmY2m0PDzMxmc2iYmdlsDg0zM5vNoWFmZrM5NMzMbDaHhpmZzebQMDOz2RwaZmY2m0PDzMxmc2iYmdlsDg0zM5vNoWFmZrM5NMzMbDaHhpmZzebQMDOz2RwaZmY2m0PDzMxmc2iYmdlsDg0zM5vtS0KDwFv+CsT5L+949v5NWaw/lg9nmxKXTZNttthm25Zm0VNLdnEE4BjEcZFOsuCUwqnAcZ+nDJxK8YrQiYBTSCfDz/AYwBGAJYAFgYWABldbGY992nh1jNf2ZmZ2j1xpmJnZbA4NMzObzaFhZmazOTTMzGw2h4aZvUS6ZZ97WwXQA+gJ9AK2GLYNgEtIawBrkBcEVgIvyPyoxIqIlYgVoZWIVVSsKnkBYQ1grTYvG3Fz0Ht7jxwaZmbfQFf7LRbRRRddHvX99+fLuj1+Vc9fv6tnv73Rv4AE3gpXwfYoODTMzGw2h4aZmc3m0DAzs9kcGmZmNptDw8zMZnNomJnZbA4NMzObzaFhZmazOTTMzGw2h4aZmc3m0DAzs9kcGmZmNptDw8zMZnNomJnZbA4NMzObzaFhZmazOTTMzGw2h4aZmc3m0DAzs9kcGmZmNptDw8zMZpsbGgTe8lcgzn95x7P3b8pi/bF8ONuUuGyabLPFNtu2NIueWrKLIwDHII6LdJIFpxROBZ5SOH3A+2NmZg/om1QaQp4ycCrFK0InAk4hnQA4BnkM4AjAEsCCwEJAg6utjMc9bRx/7c29mZndMzdPmZnZbA4NMzObzaFhZmazOTTMzGw2h4aZvTS6ZZ97WwXQA+gJ9AK2GLYNgEtIawBrkBcEVgIvyPyoxIqIlYgVoZWIVVSsKnkBYQ1grTYvG3HT1X6LRXTRRZdHff/9+bJuj1/V89fv6tlvb/QvIIG32jvGR8OhYWZmszk0zMxsNoeGmZnN5tAwM7PZHBpmZjabQ8PMzGZzaJiZ2WwODTMzm82hYWZmszk0zMxsNoeGmZnN5tAwM7PZHBpmZjabQ8PMzGZzaJiZ2WwODTMzm82hYWZmszk0zMxsNoeGmZnN5tAwM7PZHBpmZjabQ8PMzGabExoE3vJXIM5/ecez92/KYv2xfDjblLhsmmyzxTbbtjSLnlqyiyMAxyCOi3SSBacUTgWO+zxl4FSKV4ROBJxCOhl+hscAjgAsASwILAQ0uNrKeMzTxod4UMzM7HbPpdLgjb2ZmT2A5xIaZmZ2AA4NMzObzaFhZmazOTTM7CXRLfvc2yqAHkBPoBewxbBtAFxCWgNYH/aQHxeHhpnZlyIvCKwEXpD5UYkVESsRK0IrEauoWFXyAsIawFptXjbipqv9Fovooosuj/r++/Nl3R6/quev39Wz397oX0ACb4WrYHtUHBpmZjabQ8PMzGZzaJiZ2WwODTMzm82hYWZmszk0zMxsNoeGmZnN5tAwM7PZHBpmZjabQ8PMzGZzaJiZ2WwODTMzm82hYWZmszk0zMxsNoeGmZnN5tAwM7PZHBpmZjabQ8PMzGZzaJiZ2WwODTMzm82hYWZms30uNAi85a9AnP/yjoc4IDMze7y+qNI4e/';
            return imageFirstHalf;
    }
}

library SecondHalf{
     function getSecondHalf() public pure returns (string memory){            
            string memory imageSecondHalf = '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"/>         </g>';            
            string memory afterString = '<g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="none" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="url(#gradient1)" stroke="none" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)">             <path vector-effect="none" fill-rule="evenodd" d="M0,0 L332,0 L332,344 L0,344 L0,0"/>         </g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="0.701961" stroke="none" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)">             <path vector-effect="none" fill-rule="evenodd" d="M19,16 L313,16 C314.657,16 316,17.3431 316,19 L316,32 L16,32 L16,19 C16,17.3431 17.3431,16 19,16 "/>         </g>         <g fill="#ffffff" fill-opacity="0.65098" stroke="none" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)">             <path vector-effect="none" fill-rule="evenodd" d="M16,32 L316,32 L316,325 C316,326.657 314.657,328 313,328 L19,328 C17.3431,328 16,326.657 16,325 L16,32"/>         </g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="bevel" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)">             <text fill="#000000" fill-opacity="1" stroke="none" xml:space="preserve" x="87.6875" y="71" font-family="Arial" font-size="24" font-weight="700" font-style="normal">Battle Royale</text>         </g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="bevel" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)">             <text fill="#000000" fill-opacity="1" stroke="none" xml:space="preserve" x="50" y="115" font-family="Arial" font-size="16" font-weight="400" font-style="normal">';
            return string(abi.encodePacked(imageSecondHalf,afterString));
    }
}

library BetweenCode{
    
    
    function getFirstHalf(string memory x, string memory y) public pure returns (string memory){

            string memory firstHalf = '</text>         </g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="bevel" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)">             <text fill="#000000" fill-opacity="1" stroke="none" xml:space="preserve" x="';
            string memory secondHalf = '" y="';
            string memory thirdHalf = '" font-family="Arial" font-size="16" font-weight="400" font-style="normal">';
            
            return string(abi.encodePacked(firstHalf,x,secondHalf,y,thirdHalf));
    }
}


library AfterCode{
     function getLast(string memory tokenId) public pure returns (string memory){
            
            string memory before = '</text>         </g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#c08a53" fill-opacity="1" stroke="none" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,259.339,50.118)">             <path vector-effect="none" fill-rule="evenodd" d="M2,0 L71,0 C72.1046,0 73,0.89543 73,2 L73,26 C73,27.1046 72.1046,28 71,28 L2,28 C0.89543,28 0,27.1046 0,26 L0,2 C0,0.89543 0.89543,0 2,0 "/>         </g>         <g fill="#ffffff" fill-opacity="1" stroke="#ffffff" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="bevel" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,259.339,50.118)">             <text fill="#ffffff" fill-opacity="1" stroke="none" xml:space="preserve" x="10" y="21" font-family="Arial" font-size="19" font-weight="400" font-style="normal">#';
            string memory afterString  = '</text>         </g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(0.999391,0.0348995,-0.0348995,0.999391,36.1038,24.3115)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>         <g fill="#000000" fill-opacity="1" stroke="#000000" stroke-opacity="1" stroke-width="1" stroke-linecap="square" stroke-linejoin="miter" stroke-miterlimit="2" transform="matrix(1,0,0,1,0,0)"></g>     </g> </svg>';
            return string(abi.encodePacked(before,tokenId,afterString));
    }
}




pragma solidity ^0.8.0;

contract Loot is ERC721Enumerable, ReentrancyGuard, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    
        string[] private weapons = [
        "Warhammer",
        "Quarterstaff",
        "Maul",
        "Mace",
        "Club",
        "Katana",
        "Falchion",
        "Scimitar",
        "Long Sword",
        "Short Sword",
        "Ghost Wand",
        "Grave Wand",
        "Bone Wand",
        "Wand",
        "Grimoire",
        "Chronicle",
        "Tome",
        "Book"
    ];
    
    string[] private chestArmor = [
        "Divine Robe",
        "Silk Robe",
        "Linen Robe",
        "Robe",
        "Shirt",
        "Demon Husk",
        "Dragonskin Armor",
        "Studded Leather Armor",
        "Hard Leather Armor",
        "Leather Armor",
        "Holy Chestplate",
        "Ornate Chestplate",
        "Plate Mail",
        "Chain Mail",
        "Ring Mail"
    ];
    
    string[] private headArmor = [
        "Ancient Helm",
        "Ornate Helm",
        "Great Helm",
        "Full Helm",
        "Helm",
        "Demon Crown",
        "Dragon Crown",
        "War Cap",
        "Leather Cap",
        "Cap",
        "Crown",
        "Divine Hood",
        "Silk Hood",
        "Linen Hood",
        "Hood"
    ];
    
    string[] private waistArmor = [
        "Ornate Belt",
        "War Belt",
        "Plated Belt",
        "Mesh Belt",
        "Heavy Belt",
        "Demonhide Belt",
        "Dragonskin Belt",
        "Studded Leather Belt",
        "Hard Leather Belt",
        "Leather Belt",
        "Brightsilk Sash",
        "Silk Sash",
        "Wool Sash",
        "Linen Sash",
        "Sash"
    ];
    
    string[] private footArmor = [
        "Holy Greaves",
        "Ornate Greaves",
        "Greaves",
        "Chain Boots",
        "Heavy Boots",
        "Demonhide Boots",
        "Dragonskin Boots",
        "Studded Leather Boots",
        "Hard Leather Boots",
        "Leather Boots",
        "Divine Slippers",
        "Silk Slippers",
        "Wool Shoes",
        "Linen Shoes",
        "Shoes"
    ];
    
    string[] private handArmor = [
        "Holy Gauntlets",
        "Ornate Gauntlets",
        "Gauntlets",
        "Chain Gloves",
        "Heavy Gloves",
        "Demon Hands",
        "Dragonskin Gloves",
        "Studded Leather Gloves",
        "Hard Leather Gloves",
        "Leather Gloves",
        "Divine Gloves",
        "Silk Gloves",
        "Wool Gloves",
        "Linen Gloves",
        "Gloves"
    ];
    
    string[] private necklaces = ["Necklace", "Amulet","Pendant"];
    
    string[] private rings = [  "Gold Ring",
        "Silver Ring",
        "Bronze Ring",
        "Platinum Ring",
        "Titanium Ring"
    ];
    
    string[] private suffixes = [ "of Power", "of Giants", "of Titans", "of Skill",
        "of Perfection",
        "of Brilliance",
        "of Enlightenment",
        "of Protection",
        "of Anger",
        "of Rage",
        "of Fury",
        "of Vitriol",
        "of the Fox",
        "of Detection",
        "of Reflection",
        "of the Twins"
    ];
    
    string[] private namePrefixes = [
        "Agony", "Apocalypse", "Armageddon", "Beast", "Behemoth", "Blight", "Blood", "Bramble", 
        "Brimstone", "Brood", "Carrion", "Cataclysm", "Chimeric", "Corpse", "Corruption", "Damnation", 
        "Death", "Demon", "Dire", "Dragon", "Dread", "Doom", "Dusk", "Eagle", "Empyrean", "Fate", "Foe", 
        "Gale", "Ghoul", "Gloom", "Glyph", "Golem", "Grim", "Hate", "Havoc", "Honour", "Horror", "Hypnotic", 
        "Kraken", "Loath", "Maelstrom", "Mind", "Miracle", "Morbid", "Oblivion", "Onslaught", "Pain", 
        "Pandemonium", "Phoenix", "Plague", "Rage", "Rapture", "Rune", "Skull", "Sol", "Soul", "Sorrow", 
        "Spirit", "Storm", "Tempest", "Torment", "Vengeance", "Victory", "Viper", "Vortex", "Woe", "Wrath",
        "Light", "Shimmering"  
    ];
    
    string[] private nameSuffixes = [
        "Bane",
        "Root",
        "Bite",
        "Song",
        "Roar",
        "Grasp",
        "Instrument",
        "Glow",
        "Bender",
        "Shadow",
        "Whisper",
        "Shout",
        "Growl",
        "Tear",
        "Peak",
        "Form",
        "Sun",
        "Moon"
    ];
    

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(string(abi.encodePacked(keyPrefix, toString(tokenId))))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
        }
        return output;
    }
    


    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[9] memory parts;
        parts[0] = string(abi.encodePacked(SvgBeforeImage.getBefore(),FirstHalf.getFirstHalf(),SecondHalf.getSecondHalf()));
        
        parts[1] = string(abi.encodePacked(pluck(tokenId, "WEAPON", weapons),BetweenCode.getFirstHalf("50","140")));

        parts[2] = string(abi.encodePacked(pluck(tokenId, "CHEST", chestArmor),BetweenCode.getFirstHalf("50","165")));

        parts[3] = string(abi.encodePacked(pluck(tokenId, "HEAD", headArmor),BetweenCode.getFirstHalf("50","190")));


        parts[4] = string(abi.encodePacked(pluck(tokenId, "WAIST", headArmor),BetweenCode.getFirstHalf("50","215")));


        parts[5] = string(abi.encodePacked(pluck(tokenId, "FOOT", headArmor),BetweenCode.getFirstHalf("50","240")));


        parts[6] =string(abi.encodePacked(pluck(tokenId, "HAND", headArmor),BetweenCode.getFirstHalf("50","265")));


        parts[7] = string(abi.encodePacked(pluck(tokenId, "NECK", headArmor),BetweenCode.getFirstHalf("50","290")));


        parts[8] = string(abi.encodePacked(pluck(tokenId, "RING", headArmor),AfterCode.getLast(toString(tokenId))));


        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));

        string memory json = string(abi.encodePacked('{"name": "Bag #', toString(tokenId), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'));
        return json;
    }
    
    mapping(address => uint256) private lastNftId;

    function claim() public payable nonReentrant {
        require(10**16 wei == msg.value, "Amount required is 0.01 MATIC");
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        address payable contractOwner = payable(owner());
        bool sent = contractOwner.send(msg.value);
        require(sent, "Failed to send Ether");
        _safeMint(_msgSender(), tokenId);
        lastNftId[_msgSender()] = tokenId;
    }
    
    function getLastMintedId(address owner) public view returns (uint256){
        return lastNftId[owner];
    } 
    
    

    function toString(uint256 value) internal pure returns (string memory) {
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
    
    constructor() ERC721("Loot", "BLOOT") Ownable() {}
}