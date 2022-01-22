/**
 *Submitted for verification at polygonscan.com on 2022-01-22
*/

/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// SPDX-License-Identifier: MIT
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
            for {let i := 0
            } lt(i, len) {
            } { i := add(i, 3)
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
                resultPtr := add(resultPtr, 4)}
            switch mod(len, 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
            mstore(result, encodedLen)
        }return string(result);
    }
}

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
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
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
    function transferFrom(address from,address to,uint256 tokenId) external;

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
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;}
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

        if (value == 0) {return "0";}
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
        if (value == 0) {return "0x00";}
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

//gasless
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

interface IHasSecondarySaleFees {
    function getFeeBps(uint256 id) external view returns (uint256[] memory);
    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
}

contract HasSecondarySaleFees is IERC165, IHasSecondarySaleFees {
    
    event ChangeCommonRoyalty(
        address payable[] royaltyAddresses,
        uint256[] royaltiesWithTwoDecimals
    );
    
    event ChangeRoyalty(
        uint256 id,
        address payable[] royaltyAddresses,
        uint256[] royaltiesWithTwoDecimals
    );
    
    struct RoyaltyInfo {
        bool isPresent;
        address payable[] royaltyAddresses;
        uint256[] royaltiesWithTwoDecimals;
    }
    
    mapping(bytes32 => RoyaltyInfo) royaltyInfoMap;
    mapping(uint256 => bytes32) tokenRoyaltyMap;
    
    address payable[] public commonRoyaltyAddresses;
    uint256[] public commonRoyaltiesWithTwoDecimals;

    constructor(
        address payable[] memory _commonRoyaltyAddresses,
        uint256[] memory _commonRoyaltiesWithTwoDecimals
    ) {
        _setCommonRoyalties(_commonRoyaltyAddresses, _commonRoyaltiesWithTwoDecimals);
    }

    function _setRoyaltiesOf(
        uint256 _tokenId,
        address payable[] memory _royaltyAddresses,
        uint256[] memory _royaltiesWithTwoDecimals
    ) internal {
        require(_royaltyAddresses.length == _royaltiesWithTwoDecimals.length, "input length must be same");
        bytes32 key = 0x0;
        for (uint256 i = 0; i < _royaltyAddresses.length; i++) { 
            require(_royaltyAddresses[i] != address(0), "Must not be zero-address");
            key = keccak256(abi.encodePacked(key, _royaltyAddresses[i], _royaltiesWithTwoDecimals[i]));
        }
        
        tokenRoyaltyMap[_tokenId] = key;
        emit ChangeRoyalty(_tokenId, _royaltyAddresses, _royaltiesWithTwoDecimals);
        
        if (royaltyInfoMap[key].isPresent) { 
            return;
        }
        royaltyInfoMap[key] = RoyaltyInfo(
            true,
            _royaltyAddresses,
            _royaltiesWithTwoDecimals
        );
    }

    function _setCommonRoyalties(
        address payable[] memory _commonRoyaltyAddresses,
        uint256[] memory _commonRoyaltiesWithTwoDecimals
    ) internal {
        require(_commonRoyaltyAddresses.length == _commonRoyaltiesWithTwoDecimals.length, "input length must be same");
        for (uint256 i = 0; i < _commonRoyaltyAddresses.length; i++) { 
            require(_commonRoyaltyAddresses[i] != address(0), "Must not be zero-address");
        }
        
        commonRoyaltyAddresses = _commonRoyaltyAddresses;
        commonRoyaltiesWithTwoDecimals = _commonRoyaltiesWithTwoDecimals;
        
        emit ChangeCommonRoyalty(_commonRoyaltyAddresses, _commonRoyaltiesWithTwoDecimals);
    }

    function getFeeRecipients(uint256 _tokenId)
    public view override returns (address payable[] memory)
    {
        RoyaltyInfo memory royaltyInfo = royaltyInfoMap[tokenRoyaltyMap[_tokenId]];
        if (!royaltyInfo.isPresent) {
            return commonRoyaltyAddresses;
        }
        uint256 length = commonRoyaltyAddresses.length + royaltyInfo.royaltyAddresses.length;
        address payable[] memory recipients = new address payable[](length);
        for (uint256 i = 0; i < commonRoyaltyAddresses.length; i++) {
            recipients[i] = commonRoyaltyAddresses[i];
        }
        for (uint256 i = 0; i < royaltyInfo.royaltyAddresses.length; i++) {
            recipients[i + commonRoyaltyAddresses.length] = royaltyInfo.royaltyAddresses[i];
        }
        return recipients;
    }

    function getFeeBps(uint256 _tokenId) public view override returns (uint256[] memory) {
        RoyaltyInfo memory royaltyInfo = royaltyInfoMap[tokenRoyaltyMap[_tokenId]];
        if (!royaltyInfo.isPresent) {
            return commonRoyaltiesWithTwoDecimals;
        }
        uint256 length = commonRoyaltiesWithTwoDecimals.length + royaltyInfo.royaltiesWithTwoDecimals.length;

        uint256[] memory fees = new uint256[](length);
        for (uint256 i = 0; i < commonRoyaltiesWithTwoDecimals.length; i++) {
            fees[i] = commonRoyaltiesWithTwoDecimals[i];
        }
        for (uint256 i = 0; i < royaltyInfo.royaltiesWithTwoDecimals.length; i++) {
            fees[i + commonRoyaltyAddresses.length] = royaltyInfo.royaltiesWithTwoDecimals[i];
        }
        return fees;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165)
    returns (bool)
    {
        return interfaceId == type(IHasSecondarySaleFees).interfaceId;
    }
}

// FullyOnChain_KanjiNFT
contract KanjiNFT_7th is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Strings for uint256;
  uint256 public constant maxSupply = 100;
  uint256 public numClaimed = 0;
  string[] private bg = ["n","kasumi","hishi","ichimatsu","shippo","yagasuri","karakusa","seigaiha"];
  uint8[] private bg_w =[10, 5, 10, 5, 10, 10, 10, 5];
  string[] private ccol = ["black","blue","green","yellow","purple","red","gold","silver","white"];
  uint8[] private ccol_w =[100, 20, 20, 20, 20, 20, 5, 5, 5];
  string[] public cha = ["\u958b","\u81d3","\u6e90","\u4ed6","\u51fa","\u8a70","\u75db","\u5857","\u6bbf","\u638c","\u614c","\u7d19","\u89aa","\u904e","\u548c","\u6843","\u68a8","\u5211","\u8cab","\u6c11","\u82b8","\u671f","\u6ec5","\u67ff","\u4eba","\u5e7b","\u6458","\u62fe","\u63a1","\u7d75","\u99d2","\u8c5a","\u6795","\u677e","\u5834","\u7b56","\u690d","\u76bf","\u622f","\u594f","\u904a","\u6885","\u8a69","\u70b9","\u6bd2","\u78e8","\u6c60","\u8caa","\u8ca7","\u934b",
"\u9262","\u828b","\u7c89","\u529b","\u8a89","\u7948","\u8aac","\u9632","\u4fa1","\u8a87","\u5983","\u59eb","\u5237","\u8208","\u8a3c","\u6804","\u76db","\u8b77","\u4eee","\u64ec","\u516c","\u7f70","\u77b3","\u7d14","\u7d2b","\u62bc","\u7f6e","\u8cea","\u554f","\u9759","\u66b4","\u8679","\u96e8","\u4f4d","\u5e0c","\u751f","\u8aad","\u8a33","\u85a6","\u8d64","\u723d","\u60dc","\u983c","\u8cc3","\u6068","\u6b8b","\u8f9e","\u8cc7","\u656c","\u8cac"];
  string[] public meanx = ["open","organs","origin","other","out","pack","pain","paint","palace","palm","panic","paper","parent","pass","peace","peach","pear","penalty","penetrate","people","performance","period","perish","persimmon","person","phantom","pick","pick up","picking","picture","piece","pig","pillow","pine","place","plan","plant","plate","play","play","play","plum","poetry","point","poison","polish","pond","poor","poor","pot",
"pot","potato","powder","power","praise","pray","preach","prevent","price","pride","princess","princess","printing","promote","proof","prosper","prosperous","protection","provisional","pseudo","public","punishment","pupil","pure","purple","push","put","quality","question","quiet","rage","rainbow","rainy","rank","rare","raw","read","reason","recommendation","red","refreshing","regret","rely","rent","resentment","residue","resign","resource","respect","responsibility"];
  string[] private zf = ['<svg width="512" height="512" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><defs><linearGradient gradientUnits="userSpaceOnUse" id="lg_light" x1="0" y1="0" x2="256" y2="512" spreadMethod="pad"><stop offset="0%" stop-opacity="0"/><stop offset="70%" stop-color="white" stop-opacity=".25"/><stop offset="75%" stop-color="white" stop-opacity=".15"/><stop offset="100%" stop-opacity="0"/></linearGradient><radialGradient gradientUnits="userSpaceOnUse" id="rg1" cx="470" cy="256" r="512" spreadMethod="pad"><stop offset="30%" stop-color="#5d5"><animate attributeName="stop-color" values="#9f4;#2eb;#76f;#f4e;red;#9f4;" dur="',
  's" repeatCount="indefinite"/></stop><stop offset="100%" stop-color="#5d5" stop-opacity="0"><animate attributeName="stop-color" values="#9f4;#2eb;#76f;#f4e;red;#9f4;" dur="10s" repeatCount="indefinite"/></stop></radialGradient><radialGradient gradientUnits="userSpaceOnUse" id="rg2" cx="112" cy="100" r="380" spreadMethod="pad"><stop offset="20%" stop-color="red"><animate attributeName="stop-color" values="red;#f90;#9f4;#2e7;#76f;red;" dur="',
  's" repeatCount="indefinite"/></stop><stop offset="100%" stop-color="red" stop-opacity="0"><animate attributeName="stop-color" values="red;#f90;#9f4;#2e7;#76f;red;" dur="11s" repeatCount="indefinite"/></stop></radialGradient><radialGradient gradientUnits="userSpaceOnUse" id="rg3" cx="12" cy="470" r="400" spreadMethod="pad"><stop offset="10%" stop-color="blue" ><animate attributeName="stop-color" values="#76f;#f4e;#f90;#9f4;#2e7;#76f;" dur="',
  's" repeatCount="indefinite"/></stop><stop offset="100%" stop-color="blue" stop-opacity="0"><animate attributeName="stop-color" values="#76f;#f4e;#f90;#9f4;#2e7;#76f;" dur="12s" repeatCount="indefinite"/></stop></radialGradient>'];
  string private bg_0='<rect id="n" fill-opacity="0" x="0" y="0" width="512" height="512"/>';
  string private bg_1='<path id ="a" d="M 160 64 A 8 8 0 0 1 160 80 L 80 80 A 6 8 0 0 0 80 96 L 112 96 A 8 8 0 0 1 112 112 L 64 112 A 6 8 0 0 0 64 128 L 80 128 A 8 8 0 0 1 80 144 L -48 144 A 8 8 0 0 1 -48 128 L 32 128 A 6 8 0 0 0 32 112 L 16 112 A 8 8 0 0 1 16 96 L 48 96 A 6 8 0 0 0 48 80 L 32 80 A 8 8 0 0 1 32 64 L 160 64"/><path id ="b" d="M 96 160 A 8 8 0 0 1 96 176 L 80 176 A 6 8 0 0 0 80 192 L 144 192 A 8 8 0 0 1 144 208 L 32 208 A 8 8 0 0 1 32 192 L 48 192 A 6 8 0 0 0 48 176 L 16 176 A 8 8 0 0 1 16 160 L 96 160"/><path id ="c" d="M 128 0 A 8 8 0 0 1 128 16 L 88 16 A 6 8 0 0 0 88 32 L 96 32 A 8 8 0 0 1 96 48 L -16 48 A 8 8 0 0 1 -16 32 L -8 32 A 6 8 0 0 0 -8 16 L -40 16 A 8 8 0 0 1 -40 0 L 24 0 A 8 8 0 0 1 24 16 L 16 16 A 6 8 0 0 0 16 32 L 64 32 A 6 8 0 0 0 64 16 L 56 16 A 8 8 0 0 1 56 0 L 128 0"/><g id="kasumi" fill-opacity=".1" fill="#fff" ><use href="#a" x="32" y="0"/><use href="#b" x="0" y="0"/><use href="#b" x="388" y="-80"/><use href="#c" x="0" y="368"/><use href="#c" x="356" y="16"/><use href="#a" x="356" y="304"/><animate attributeName="fill-opacity" values=".1;.4;.2;.1;" dur="5s" repeatCount="indefinite"/></g>';
  string private bg_2='<path id="aa" fill-opacity="0.1" fill="#000" d="M 64 25.403 L 84 36.95 64 48.497 44 36.95 z"/><g id="sq"><path stroke="#000" stroke-width="8" stroke-opacity=".05" fill="none" d="M 64 0 L 128 36.95 64 73.9 0 36.95 z"/><use href="#aa" x="0" y="-13.279"/><use href="#aa" x="23" y="0"/><use href="#aa" x="0" y="13.279"/><use href="#aa" x="-23" y="0"/></g><pattern id="p6" x="0" y="0" width=".25" height=".146"><use href="#sq" x="0" y="0"/><use href="#sq" x="-64" y="-36.95"/><use href="#sq" x="64" y="-36.95"/><use href="#sq" x="-64" y="36.95"/><use href="#sq" x="64" y="36.95"/></pattern><rect id="hishi" fill="url(#p6)" stroke="none" x="0" y="0" width="512" height="512"/>';
  string private bg_3='<pattern fill-opacity="0.1" fill="#fff" id="p5" x="0" y="0" width=".25" height=".25"><rect x="0" y="0" width="64" height="64"/><rect x="64" y="64" width="64" height="64"/></pattern><rect id="ichimatsu" fill="url(#p5)" stroke="none" x="0" y="0" width="512" height="512"/>';
  string private bg_4='<pattern id="p4" x="0" y="0" width=".125" height=".125"><path fill-opacity=".1" fill="#000" stroke-width="4" d="M 32 0 A 32 32 0 0 1 32 64 A 32 32 0 0 1 32 0 A 32 32 0 0 1 0 32 A 32 32 0 0 1 32 64 A 32 32 0 0 1 64 32 A 32 32 0 0 1 32 0 z"/></pattern><rect id="shippo" fill="url(#p4)" x="0" y="0" width="512" height="512"/>';
  string private bg_5='<pattern id="p3" x="0" y="0" width=".25" height=".5"><path fill-opacity="0.1" fill="#000" d="M 0 0 L 32 32 32 160 0 128 z M 64 0 L 64 128 32 160 32 32 z M 64 0 L 128 0 96 32 z M 64 128 L 96 160 96 288 64 256 z M 128 128 L 128 256 96 288 96 160 z M 64 0 L 128 0 96 32 z "/><path stroke-opacity="0.1" stroke="#000" fill="none" stroke-width="3" d="M 32 0 L 32 32 M 96 32 L 96 160 M 32 160 L 32 288"/><path stroke="#fff" stroke-opacity=".1" stroke-width="3" d="M 32 32 L 32 160 M 96 0 L 96 0 96 32 M 96 160 L 96 288"/></pattern><rect id="yagasuri" fill="url(#p3)" x="0" y="0" width="512" height="512"/>';
  string private bg_6='<pattern id="p2" x="0" y="0" width=".5" height=".25"><path stroke-opacity=".1" stroke="#000" fill="transparent" stroke-width="4" stroke-linecap="round" d="M 22 15 C 50 -5, 90 0, 90 40 C 90 53, 80 73, 55 65 C 45 60, 40 50, 45 40 C 55 20, 75 25, 75 40 C 75 45, 70 53, 60 50 M 80 63 C 100 105, 85 135, 50 130 C 40 127, 33 122, 33 105 C 38 78, 68 75, 73 100 C 75 105, 70 115, 60 115 C 50 115, 50 105, 53 105 M 88 110 C 95 155, 120 165, 140 158 C 165 150, 165 110, 130 115 C 120 115, 110 130, 120 140 C 140 155, 150 130, 133 130 M 88 90 C 100 110, 125 110, 140 102 C 160 90, 160 50, 125 50 C 105 50, 97 70, 110 82 C 135 95, 135 70, 128 65 M 143 100 C 190 60, 210 80, 215 100 C 220 135, 180 130, 175 110 C 172 93, 198 85, 200 108 M 150 62 C 130 10, 200 -15, 210 30 C 215 60, 180 60, 175 35 C 175 20, 200 25, 195 38 M 88 -18 C 95 27, 120 37, 140 30 C 165 22, 165 -18, 130 -13 C 120 -13, 110 2, 120 13 C 140 27, 150 2, 133 2 M 210 30 C 210 0, 285 -10, 280 30 C 275 50, 255 50, 245 35 C 235 20, 265 10, 265 30 M -46 30 C -46 0, 29 -10, 24 30 C 19 50, -1 50, -11 35 C -21 20, 9 10, 9 30 M 265 46 C 210 55, 220 110, 250 115 C 280 120, 280 75, 255 80 C 240 85, 250 105, 257 100 M 9 46 C -41 55, -36 110, -6 115 C 24 120, 24 75, -1 80 C -16 85, -6 105, 1 100 M 80 -65 C 100 -23, 85 7, 50 2 C 40 -1, 33 -6, 33 -23 C 38 -50, 68 -53, 73 -28 C 75 -23, 70 -13, 60 -113 C 50 -13, 50 -23, 53 -123"/></pattern><rect id="karakusa" fill="url(#p2)" x="0" y="0" width="512" height="512"/>';
  string private bg_7='<filter id="feComposite3" filterUnits="userSpaceOnUse" x="0" y="0" width="512" height="512"><feImage href="#cir" dx="0" dy="0"/><feComposite in2="SourceGraphic" operator="out"/></filter><g id="cir" fill-opacity="0" stroke-opacity=".1" stroke="#000" stroke-width="12"><circle cx="128" cy="128" r="64"/><circle cx="128" cy="128" r="40"/><circle cx="128" cy="128" r="16"/></g><g id="cir2" fill="black" stroke="black" stroke-width="12"><circle cx="64" cy="160" r="64"/><circle cx="192" cy="160" r="64"/><path fill="white" fill-opacity="1" d="M 64 192 A 64 64 0 0 1 192 192 z"/></g><g id="cirs"><use href="#cir2" filter="url(#feComposite3)" x="0" y="0"/></g><pattern id="p1" x="0" y="0" width=".25" height=".125"><use href="#cirs" x="-64" y="-96"/><use href="#cirs" x="-128" y="-64"/><use href="#cirs" x="0" y="-64"/><use href="#cirs" x="-64" y="-32"/><use href="#cirs" x="0" y="0"/><use href="#cirs" x="-128" y="0"/></pattern><rect id="seigaiha" fill="url(#p1)" x="0" y="0" width="512" height="512"/>';
  string[] private zb = ['<g id="chara" text-anchor="middle" font-family="serif" font-weight="700" ><text xml:space="preserve" font-size="220" x="256" y="320">',
  '</text><text xml:space="preserve" font-size="42" x="256" y="410" >',
  '</text></g></defs><rect x="0" y="0" width="512" height="512" fill="#f7f"/><rect x="0" y="0" width="512" height="512" fill="url(#rg1)"/><rect x="0" y="0" width="512" height="512" fill="url(#rg2)"/><rect x="0" y="0" width="512" height="512" fill="url(#rg3)"/><use href="#',
  '"/><rect x="0" y="0" width="512" height="512" fill="url(#lg_light)"/>',
  '<use href="#chara" fill="',
  '"/></svg>'];
  string private zz='"/>';
  string private co1=', ';
  string private tr1='", "attributes": [{"trait_type": "Background","value": "';
  string private tr2='"},{"trait_type": "chara_color","value": "';
  string private tr3='"}],"image": "data:image/svg+xml;base64,';
  string private ra1='A';
  string private ra2='C';
  string private ra3='D';
  string private ra4='E';
  string private ra5='F';
  string private rl1='{"name": "KanjiNFT_7th #';
  string private rl3='"}';
  string private rl4='data:application/json;base64,';

  struct Kanji {
    uint8 bg;
    uint8 ccol;
    string rg1;
    string rg2;
    string rg3;
  }

  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function usew(uint8[] memory w,uint256 i) internal pure returns (uint8) {
    uint8 ind=0;
    uint256 j=uint256(w[0]);
    while (j<=i) {
      ind++;
      j+=uint256(w[ind]);
    }
    return ind;
  }

  function randomOne(uint256 tokenId) internal view returns (Kanji memory) {
    Kanji memory kanji;
    kanji.bg = usew(bg_w,random(string(abi.encodePacked(ra1,meanx[tokenId-1]))) % 65);
    kanji.ccol = usew(ccol_w,random(string(abi.encodePacked(ra3,meanx[tokenId-1]))) % 215);
    kanji.rg1 = uint256(random(string(abi.encodePacked(ra4,meanx[tokenId-1]))) % 13+7).toString();
    kanji.rg2 = uint256(random(string(abi.encodePacked(ra5,meanx[tokenId-1]))) % 13+7).toString();
    kanji.rg3 = uint256(random(string(abi.encodePacked(ra2,meanx[tokenId-1]))) % 13+7).toString();
    return kanji;
  }

  // get string attributes of properties, used in tokenURI call
  function getTraits(Kanji memory kanji) internal view returns (string memory) {
    string memory o=string(abi.encodePacked(tr1,bg[kanji.bg],tr2,ccol[kanji.ccol]));
    return string(abi.encodePacked(o,tr3));
  }

  function getAttributes(uint256 tokenId) public view returns (string memory) {
    Kanji memory kanji = randomOne(tokenId);
    return string(abi.encodePacked(bg[kanji.bg],co1,ccol[kanji.ccol]));
  }

  function genBg(uint8 h) internal view returns (string memory) {
    string memory out = '';
    if (h<1) { out = bg_0; }
    if (h>0) { out = bg_1; }
    if (h>1) { out = bg_2; }
    if (h>2) { out = bg_3; }
    if (h>3) { out = bg_4; }
    if (h>4) { out = bg_5; }
    if (h>5) { out = bg_6; }
    if (h>6) { out = bg_7; }
    return out;
  }

  function genSVG1(Kanji memory kanji) internal view returns (string memory) {
    string memory output = string(abi.encodePacked(zf[0],kanji.rg1,zf[1],kanji.rg2,zf[2],kanji.rg3,zf[3]));
    return string(abi.encodePacked(output,genBg(kanji.bg),zb[0]));
  }
    function genSVG2(Kanji memory kanji,uint256 tokenId) internal view returns (string memory) {
    string memory b=ccol[kanji.ccol];
    string memory output= string(abi.encodePacked(zb[1],meanx[tokenId-1],zb[2],bg[kanji.bg]));
    return string(abi.encodePacked(output,zb[3],zb[4],b,zb[5]));
  }

    function genSVG(Kanji memory kanji,uint256 tokenId) internal view returns (string memory) {
      string memory chara = cha[tokenId-1];
    return string(abi.encodePacked(genSVG1(kanji),chara,genSVG2(kanji,tokenId)));
  }

//  function tokenURI(uint256 tokenId) override public view returns (string memory) {
//    Kanji memory kanji = randomOne(tokenId);
//    string memory title = string(abi.encodePacked(rl1,tokenId.toString()," ",meanx[tokenId]));
//    string memory output1= string(abi.encodePacked(title,getTraits(kanji),genSVG1(kanji)));
//    return string(abi.encodePacked(rl4,Base64.encode(bytes(output1)),bytes(cha[tokenId]),Base64.encode(bytes(genSVG2(kanji,tokenId)))));
//}


  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    Kanji memory kanji = randomOne(tokenId);
    string memory id=(tokenId+600).toString();
    string memory title = string(abi.encodePacked(rl1,id," ",meanx[tokenId-1],getTraits(kanji)));
    return string(abi.encodePacked(rl4,Base64.encode(bytes(string(abi.encodePacked(title,Base64.encode(bytes(genSVG(kanji,tokenId))),rl3))))));
  }

  function claim(uint256 tokenId) public nonReentrant onlyOwner{
    require(tokenId > 0 && tokenId < 31, "invalid claim");
    _safeMint(owner(), tokenId);
    numClaimed += 1;
  }

  function ownerClaim() public nonReentrant onlyOwner {
    for(uint256 i = 31; i <=maxSupply; i++){
    _safeMint(owner(), i);
    }
  }

//gasless
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public override view returns (bool isOperator) {
    if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
    return true;
  }
    return ERC721.isApprovedForAll(_owner, _operator);
  }
    
  constructor() ERC721("KanjiNFT_7th", "KNJ7") Ownable() {}
}