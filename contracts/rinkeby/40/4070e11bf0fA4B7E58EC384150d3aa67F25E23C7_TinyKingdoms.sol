// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/Counters.sol";


/**
 * @title TinyKingdoms
 * @dev Generates beautiful tiny kingdoms
 */
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


contract TinyKingdoms is ERC721Enumerable,ReentrancyGuard,Ownable {

    using Counters for Counters.Counter;
    uint256 public maxSupply = 4096;
    uint256 public mintPrice = 0.01 ether;
    Counters.Counter private _tokenIdCounter;
    

    bool public saleIsActive = true; // turn it off
    uint256 public numTokensMinted;
      
    

    constructor() ERC721("Tiny Kingdoms", "TNY") Ownable() {
        _tokenIdCounter.increment();
    }
       
    function setPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }
    
    
    //TODO: Remove irrelevant words from nouns list
    
    string[] private nouns = [ 
        "Eagle","Meditation","Folklore","Star","Light","Play","Palace","Wildflower","Rescue","Fish","Painting",
        "Shadow","Revolution","Planet","Storm","Land","Surrounding","Spirit","Oceans","Night","Snow","River",
        "Sheep","Poison","State","Flame","River","Clouds","Patterns","Water","Forest","Tactics","Fire","Strategy",
        "Space","Time","Art","Stream","Spectrum","Fleet","Ship","Spring","Shore","Plant","Meadow","System","Past",
        "Parrot","Throne","Ken","Buffalo","Perspective","Tear","Moon","Moon","Wing","Summer","Broad","Owls",
        "Serpent","Desert","Fools","Spirit","Crystal","Persona","Dove","Rice","Crow","Ruin","Voice","Destiny",
        "Seashell","Structure","Toad","Shadow","Sparrow","Sun","Sky","Mist","Wind","Smoke","Division","Oasis",
        "Tundra","Blossom","Dune","Tree","Petal","Peach","Birch","Space","Flower","Valley","Cattail","Bulrush",
        "Wilderness","Ginger","Sunset","Riverbed","Fog","Leaf","Fruit","Country","Pillar","Bird","Reptile","Melody","Universe",
        "Majesty","Mirage","Lakes","Harvest","Warmth","Fever","Stirred","Orchid","Rock","Pine","Hill","Stone","Scent","Ocean",
        "Tide","Dream","Bog","Moss","Canyon","Grave","Dance","Hill","Valley","Cave","Meadow","Blackthorn","Mushroom","Bluebell",
        "Water","Dew","Mud","Family","Garden","Stork","Butterfly","Seed","Birdsong","Lullaby","Cupcake","Wish",
        "Laughter","Ghost","Gardenia","Lavender","Sage","Strawberry","Peaches","Pear","Rose","Thistle","Tulip",
        "Wheat","Thorn","Violet","Chrysanthemum","Amaranth","Corn","Sunflower","Sparrow","Sky","Daisy","Apple",
        "Oak","Bear","Pine","Poppy","Nightingale","Mockingbird","Ice","Daybreak","Coral","Daffodil","Butterfly",
        "Plum","Fern","Sidewalk","Lilac","Egg","Hummingbird","Heart","Creek","Bridge","Falling Leaf","Lupine","Creek",
        "Iris Amethyst","Ruby","Diamond","Saphire","Quartz","Clay","Coal","Briar","Dusk","Sand","Scale","Wave","Rapid",
        "Pearl","Opal","Dust","Sanctuary","Phoenix","Moonstone","Agate","Opal","Malachite","Jade","Peridot","Topaz",
        "Turquoise","Aquamarine","Amethyst","Garnet","Diamond","Emerald","Ruby","Sapphire","Typha","Sedge","Wood"
        ];
    
    string[] private adjectives = [
        "Central","Free","United","Socialist","Ancient Republic of","Third Republic of",
        "Eastern","Cyber","Northern","Northwestern","Galactic Empire of","Southern","Solar",
        "Islands of","Kingdom of","State of","Federation of","Confederation of",
        "Alliance of","Assembly of","Region of","Ruins of","Caliphate of","Republic of",
        "Province of","Grand","Duchy of","Capital Federation of","Autonomous Province of",
        "Free Democracy of","Federal Republic of","Unitary Republic of","Autonomous Regime of","New","Old Empire of"
        ];
    
    string[] private suffixes = [
        "Beach", "Center","City", "Coast","Creek","Estates", "Falls", "Grove",
        "Heights","Hill","Hills","Island","Lake","Lakes","Park","Point","Ridge",
        "River","Springs","Valley","Village","Woods", "Waters", "Rivers", "Points", 
        "Mountains", "Volcanic Ridges", "Dunes", "Cliffs", "Summit"
        ];
      
    string [] private specialty = [
        "Cavalry",
        "Defense",
        "Infantry",
        "Monks",
        "Navy"
        ];
    
        string[3][12] private colors = [
            
            ["#006d77", "#83c5be", "#ffddd2"],
            ["#351f39", "#726a95", "#719fb0"],
            ["#472e2a", "#e78a46", "#fac459"],
            ["#e95145", "#f8b917", "#ffb2a2"],
            ["#ff7bac", "#ff921e", "#3ea8f5"],
            ["#e72e81", "#f0bf36", "#3056a2"],
            ["#ff5937", "#f6f6f4", "#4169ff"],
            ["#ed7e62", "#f4b674", "#4d598b"],
            ["#F7F7F7","#006838", "#96CF24"],
            ["#FFE8F5","#8000FF", "#DE00FF"],
            ["#533549","#F6B042", "#F9ED4E"],
            ["#072C50","#B88746", "#FDF5A6"]

            // from: https://looka.com/blog/logo-color-combinations/
            // #AA96DA, Mint #C5FAD5, Yellow #FFFFD2
            // Hex Codes: Grey #F7F7F7, Green gradient #006838 and #96CF24
            // Hex Codes: Blue #234E70, Yellow #FBF8BE
            // Hex Codes: Pink #FFE8F5, Purple gradient #8000FF and #DE00FF
            // Hex Codes: Black #191919, Gold #B88746 and #FDF5A6
            //Hex Codes: Red #CC313D, Pink #F7C5CC
            //Hex Codes: Purple #E2D3F4, Blue #013DC4
            //Hex Code: Eggplant #533549, Yellow gradient #F6B042 and #F9ED4E
            //Hex Codes: Green #99F443, Pink #EC449B

            //Hex Code: Orange #EE4E34, Beige #FCEDDA
            //Hex Codes: Blue #072C50, Orange gradient #B88746 and #FDF5A6
            //Hex Codes: Terracotta #96351E, Sand #DBB98F
            //Hex Codes: Purple #E2D1F9, Teal #317773

            // from: https://digitalsynopsis.com/design/beautiful-color-palettes-combinations-schemes/
            // #fe4a49 • #2ab7ca • #fed766
            //  #3da4ab • #f6cd61 • #fe8a71
            // • #fdf498 • #7bc043 • #0392cf
            // #ff6f69 • #ffcc5c • #88d8b0
            // #d62d20 • #ffa700 • #ffffff
            //#a8e6cf • #dcedc1 • #ffd3b6 
            //#00aedb • #f37735 • #ffc425
            //#d11141 • #00b159 • #00aedb
            //#edc951 • #eb6841 • #cc2a36

        ];

    struct TinyFlag {
    
        string placeName;
        string specialty;

        uint256 themeIndex;
    }

    function getThemeIndex (uint256 tokenId) internal pure returns (uint256){
        uint256 rand = random(tokenId,"THEME") % 1000;
        uint256 themeIndex =0;

        if      (rand <80){themeIndex = 0;} 
        else if (rand <160){themeIndex = 1;} 
        else if (rand <240){themeIndex = 2;} 
        else if (rand <320){themeIndex = 3;} 
        else if (rand <400){themeIndex = 4;} 
        else if (rand <480){themeIndex = 5;} 
        else if (rand <560){themeIndex = 6;} 
        else if (rand <640){themeIndex = 7;} 
        else if (rand <720){themeIndex = 8;} 
        else if (rand <800){themeIndex = 9;} 
        else if (rand <880){themeIndex = 10;} 
        // else if (rand <960){themeIndex = 11;} 
        else {themeIndex = 11;}
        return themeIndex;
    }

     function getSpecialty (uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(tokenId, "SPECIALTY");
        string memory s = specialty[rand % 5];    
        return s;
    }

    function getflagType(uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(tokenId,"FLAG");
        
        string memory f1= flags[rand % flags.length]; //change to len flags
        return string(abi.encodePacked(f1));
    }

    function getKingdom (uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(tokenId, "PLACE");
        
        string memory a1 = adjectives[(rand / 7) % adjectives.length];
        string memory n1 =nouns[(rand / 200) % nouns.length];
        string memory s1 = suffixes[(rand /11) % suffixes.length];
        
        return string(abi.encodePacked(a1,' ',n1,' ',s1));
    }

    function getKingdomOutput (uint256 tokenId) public view returns (string memory){
        string memory output;
        bytes memory b = bytes(getKingdom(tokenId));
    
        uint256 y = 449;
        uint256 i = 0;
        uint256 e = 0;    
        uint256 ll = 20;
    
        while (true) {
        e = i + ll;
        if (e >= b.length) {
            e = b.length;
        } else {
            while (b[e] != ' ' && e > i) { e--; }
        }

      bytes memory line = new bytes(e-i);
      for (uint k = i; k < e; k++) {
        line[k-i] = _upper(b[k]);
      }
      
      output = string(abi.encodePacked(output,'<text text-anchor="middle" class="place" x="303" y="',Strings.toString(y),'">',line,'</text>'));
    //   output = string(abi.encodePacked(output,'<text x="160" y="',Strings.toString(y),'">',line,'</text>'));
      //text-anchor="middle"
      if (y > 450) break;
      
      y += 38; //do not change
      if (e >= b.length) break;
      i = e + 1;
    }

    return output;
    }


    function randomFlag(uint256 tokenId) internal view  returns (TinyFlag memory) {
        TinyFlag memory flag;
        
        flag.placeName= getKingdom(tokenId);
        flag.specialty= getSpecialty(tokenId);

        flag.themeIndex=getThemeIndex(tokenId);

        return flag;
    }

    function getTraits(TinyFlag memory flag) internal view returns (string memory) {
        string[20] memory parts;

        parts[0] = ', "attributes": [{"trait_type": "Primary Color","value": "';
        parts[1] = colors[flag.themeIndex][0];
        parts[2] = '"}, {"trait_type": "Secondary Color","value": "';
        parts[3] = colors[flag.themeIndex][1];
        parts[4] = '"}, {"trait_type": "Tertiary Color","value": "';
        parts[5] = colors[flag.themeIndex][2];
        parts[6] ='"},{"trait_type": "Kingdom","value": "';
        parts[7] = flag.placeName;
        parts[8]= '"}],';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5],parts[6],parts[7],parts[8]));
        
        return output;
    }
    
    string [] private flags = [
        
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="140" width="382" x="113" y="226" /><rect class="cls-2" style="filter: url(#displacementFilter)" height="140" width="382" x="113" y="86" /><circle class="cls-3" style="filter: url(#displacementFilter)" cx="304" cy="226" r="84"/><rect class="contour" style="filter: url(#displacementFilter)" x="113.5" y="86.5" width="382" height="279"/>', //sample07
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="279" width="127" x="113" y="86" /><rect class="cls-2" style="filter: url(#displacementFilter)" height="279" width="128" x="240" y="86" /><rect class="cls-3" style="filter: url(#displacementFilter)" height="279" width="128" x="367" y="86" /><rect class="contour" style="filter: url(#displacementFilter)" x="113.5" y="86.5" width="2" height="279"/>', //sample08
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="279" width="382" x="113.65" y="86.26"/> <polygon class="cls-2" style="filter: url(#displacementFilter)" points="113.65 86.27 304.65 225.76 113.65 365.26 113.65 86.27"/> <rect class="cls-5" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="86"/>', //009
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="279" width="381" x="113.77" y="86.13"/> <polygon class="cls-2" style="filter: url(#displacementFilter)" points="112.77 178.87 208.27 178.87 208.27 86.13 302.77 86.13 302.77 178.87 494.49 178.87 494.49 272.24 302.77 272.24 303.83 365.13 208.29 365.63 208.27 272.24 112.89 272.24 112.77 178.87"/> <rect class="cls-5" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="86"/>', //10
	    '<rect class="cls-1" style="filter: url(#displacementFilter)" height="62"  width="381" x="114" y="86"/> <rect class="cls-2" style="filter: url(#displacementFilter)" height="156" width="381" x="114" y="148"/> <rect class="cls-1" style="filter: url(#displacementFilter)" height="62" width="381" x="114" y="304"/> <rect class="cls-5" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="86"/>', //11
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="155" width="381" x="114" y="148"/> <rect class="cls-2" style="filter: url(#displacementFilter)" height="62" width="381" x="114" y="86"/> <rect class="cls-2" style="filter: url(#displacementFilter)" height="62" width="381" x="114" y="195"/> <rect class="cls-2" style="filter: url(#displacementFilter)" height="62" width="381" x="114" y="303"/> <rect class="cls-5" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="86"/>', //12
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="87"/> <rect class="cls-2" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="86"/> <circle style="filter: url(#displacementFilter)" class="cls-3" cx="303.5" cy="224.5" r="95.5"/>' //13 ,
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="279" width="190" x="114" y="86"/> <rect class="cls-2" style="filter: url(#displacementFilter)" height="279" width="191" x="304" y="86"/> <rect class="cls-5" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="86"/>', //14
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="279" width="381" x="114" y="86"/> <polygon class="cls-2" style="filter: url(#displacementFilter)" points="165.74 86.5 113.85 86.5 113.85 125.1 252.77 225.84 113.85 326.58 113.85 364.9 165.47 364.9 304.79 263.56 445.19 365.38 495.45 365.38 495.45 325.6 358.44 226.25 495.45 126.09 495.45 87.59 444.92 87.59 304.79 188.12 165.74 86.5"/> <rect style="filter: url(#displacementFilter)" class="cls-5" height="279" width="382" x="113" y="86"/>', //15
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="140" width="382" x="114" y="225"/> <rect class="cls-2" style="filter: url(#displacementFilter)" height="140" width="382" x="114" y="85"/> <rect class="cls-5" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="86"/>', //16
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="279" width="381" x="114" y="86"/> <rect class="cls-2" style="filter: url(#displacementFilter)" height="279" width="128" x="177" y="86"/> <rect class="cls-5" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="86"/>',//17
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="279" width="381" x="114" y="85"/> <rect class="cls-2" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="86"/> <rect class="cls-3" style="filter: url(#displacementFilter)" height="155" width="256" x="176" y="148"/>', //18
		'<rect class="cls-1" style="filter: url(#displacementFilter)" height="279" width="382" x="112.75" y="86.62"/> <polyline class="cls-2" style="filter: url(#displacementFilter)" points="113.07 365.29 391.75 365.62 112.85 226.33"/> <polyline class="cls-2" style="filter: url(#displacementFilter)"  points="113.07 85.96 391.75 85.62 112.85 226.58"/> <rect class="cls-5" style="filter: url(#displacementFilter)"  height="279" width="382" x="113" y="86"/>', //19
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="280" width="381" x="114" y="85"/> <rect class="cls-2" style="filter: url(#displacementFilter)"  height="68.63" width="63" x="113.83" y="86.69"/><rect class="cls-2" style="filter: url(#displacementFilter)"  height="68.63" width="63" x="240.83" y="86.69"/><rect class="cls-2" style="filter: url(#displacementFilter)"  height="68.63" width="63" x="367.83" y="86.69"/><rect class="cls-2" style="filter: url(#displacementFilter)"  height="68.63" width="63" x="113.83" y="226.19"/><rect class="cls-2" style="filter: url(#displacementFilter)"  height="68.63" width="63" x="240.83" y="226.19"/><rect class="cls-2" style="filter: url(#displacementFilter)"  height="68.63" width="63" x="367.83" y="226.19"/><rect class="cls-2" style="filter: url(#displacementFilter)"  height="68.63" width="63" x="176.83" y="156.44"/><rect class="cls-2" style="filter: url(#displacementFilter)"  height="68.63" width="63" x="303.83" y="156.44"/><rect class="cls-2" style="filter: url(#displacementFilter)"  height="68.63" width="63" x="430.83" y="156.44"/><rect class="cls-2" style="filter: url(#displacementFilter)"  height="68.63" width="63" x="176.83" y="297.07"/><rect class="cls-2" style="filter: url(#displacementFilter)"  height="68.63" width="63" x="303.83" y="297.07"/><rect class="cls-2" style="filter: url(#displacementFilter)"  height="68.63" width="63" x="430.83" y="297.07"/><rect class="cls-5" style="filter: url(#displacementFilter)"  height="279" width="382" x="113" y="86"/>', //20
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="278" width="382" x="112" y="87"/> <polygon class="cls-2" style="filter: url(#displacementFilter)"  points="113.1 85 289.69 85 494.1 364 318.1 363 113.1 85"/> <rect class="cls-5" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="86"/>', //21 
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="93" width="381.13" x="113.65" y="86.25"/> <rect class="cls-2" style="filter: url(#displacementFilter)" height="93" width="381.13" x="113.65" y="272.25"/> <rect class="cls-3" style="filter: url(#displacementFilter)" height="93" width="382" x="112.77" y="179.25"/><rect class="cls-5" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="86"/>', //22
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="278" width="382" x="113" y="87"/> <polygon class="cls-2" style="filter: url(#displacementFilter)"  points="494.66 86 318.06 86 113.66 365 289.66 364 494.66 86"/><rect class="cls-5" style="filter: url(#displacementFilter)"  height="279" width="382" x="113" y="86"/>', //23
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="279" width="381" x="114" y="86"/> <rect class="cls-2" style="filter: url(#displacementFilter)"  height="139" width="191" x="113" y="86"/><rect class="cls-2" style="filter: url(#displacementFilter)"  height="139" width="191" x="304" y="226"/><rect class="cls-5" style="filter: url(#displacementFilter)"  height="279" width="382" x="113" y="86"/>', //24
        '<polygon class="cls-1" style="filter: url(#displacementFilter)" points="495.47 86.16 290.47 364.16 495.47 364.16 495.47 86.16"/> <polygon class="cls-2" style="filter: url(#displacementFilter)" points="114.47 365.16 319.47 87.16 114.47 87.16 114.47 365.16"/> <polygon class="cls-3" style="filter: url(#displacementFilter)" points="495.47 86.16 318.88 86.16 114.47 365.16 290.47 364.16 495.47 86.16"/>',//25
        '<rect class="cls-1" style="filter: url(#displacementFilter)" height="279" width="190" x="304" y="87"/><rect class="cls-2" style="filter: url(#displacementFilter)" height="279" width="190" x="114" y="86"/><path class="cls-1" style="filter: url(#displacementFilter)" d="M304,310a84,84,0,0,1,0-168"/><path class="cls-2" style="filter: url(#displacementFilter)" d="M304,142a84,84,0,0,1,0,168"/><rect class="cls-5" style="filter: url(#displacementFilter)" height="279" width="382" x="113" y="86"/>' //26
        

        ];

    
    function getFlagSVG(TinyFlag memory flag, uint256 tokenId) internal view returns (string memory){
        string[15] memory parts;

        parts[0]='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 609 602" style="background-color:#f0f0e8"> <defs> <style> .shadow{stroke-linecap:round;stroke-linejoin:round;fill:#565656;stroke:#565656} .cls-1{fill:';
        parts[1]=colors[flag.themeIndex][0];
        parts[2]=';}.cls-2{fill:';
        parts[3]=colors[flag.themeIndex][1];
        parts[4]=';}.cls-3{fill:';
        parts[5]=colors[flag.themeIndex][2];
        parts[6]=';}.cls-5{fill:none;stroke:#565656;stroke-miterlimit:10;stroke-width:2px;} .contour{fill:none;stroke:#565656;stroke-miterlimit:10;stroke-width:2px;height:279,width:382, x:113, y:86}.place{font-size:36px;font-family:serif;fill:#565656}</style></defs> <filter id="displacementFilter"><feTurbulence type="turbulence" baseFrequency="0.05" numOctaves="2" result="turbulence"/><feDisplacementMap in2="turbulence" in="SourceGraphic" scale="3" xChannelSelector="R" yChannelSelector="G"/></filter>';
        parts[7]=getflagType(tokenId);
        parts[8]='<rect class="contour"  x="113.5" y="86.5" width="382" height="279" style="filter: url(#displacementFilter)"/>';
        parts[9]=' <polygon class="shadow" points="112.5 365.5 112.5 87.92 108 97 108 370 490 370 494.67 365.5 112.5 365.5" style="filter: url(#displacementFilter)"/>';
        parts[10]=getKingdomOutput(tokenId);
        parts[11]='</svg>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2],parts[3],parts[4],parts[5],parts[6],parts[7],parts[8],parts[9],parts[10],parts[11]));

        
        return output;
    }


   
    function random(uint256 tokenId, string memory seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, Strings.toString(tokenId))));
    }
    
    function _upper(bytes1 _b1) private pure returns (bytes1) {
          if (_b1 >= 0x61 && _b1 <= 0x7A) {
              return bytes1(uint8(_b1) - 32);
              }
              return _b1;
    }

    
    function tokenURI(uint256 tokenId) override public view  returns (string memory) {
        TinyFlag memory flag = randomFlag(tokenId);
        
        string memory json = Base64.encode(
            bytes(
                string(abi.encodePacked(
                    '{"name": "Tiny Flag #',
                     Strings.toString(tokenId),
                     '", "description": "Flags are fully on-chain, randomly generated tiny flags."',
                     getTraits(flag), 
                     '"image": "data:image/svg+xml;base64,', 
                     Base64.encode(bytes(getFlagSVG(flag,tokenId))), 
                     '"}'))));
        
        // string memory json = Base64.encode(bytes(string(abi.encodePacked('{"data:image/svg+xml;base64,', Base64.encode(bytes(getFlagSVG(flag,tokenId))), '"}'))));

        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
        }

    function claim() public payable {
        require(saleIsActive, "Sale is not active");
        uint256 nextId = _tokenIdCounter.current();
        require(mintPrice <= msg.value, "Ether value sent is not correct");
        require(nextId <= 4096, "Token limit reached");
        _safeMint(_msgSender(), nextId);
        _tokenIdCounter.increment();
  }
  
  function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
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