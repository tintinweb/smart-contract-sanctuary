/**
 *Submitted for verification at Etherscan.io on 2021-11-05
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

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
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


    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
     * by making the `nonReentrant` function external, and making it call a
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

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is ERC165, IERC2981Royalties {
    address private _royaltiesRecipient;
    uint256 private _royaltiesValue;

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royaltiesRecipient = recipient;
        _royaltiesValue = value;
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltiesRecipient, (value * _royaltiesValue) / 10000);
    }
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
     * plain`call` is an unsafe replacement for a function call: use this
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



contract Vibes is ERC721Enumerable, ERC2981ContractWideRoyalties, ReentrancyGuard, Ownable {
    using Strings for uint256;

    // 0.07 ETH
    uint256 public constant MINT_COST = 70000000000000000;

    bool public mintingActive = false;
    bool public useAnimation = false;
    bool public useOnChainAnimation = false;
    string private baseVibeURI = "ipfs://QmYJBegzL7JNTkrgjUqJTwiSQ3QDcyEX3aj2ekjFmmLMc6/";

    mapping(uint256 => bytes32) private entropyHashes;

    struct ColorInfo {
        uint256[] colorInts;
        uint256[] colorIntsChosen;
        uint256 colorIntCount;
        bool ordered;
        bool shuffle;
        bool restricted;
        string palette;
        uint256 colorCount;
    }

    struct TokenInfo {
        string entropyHash;
        string element;
        string palette;
        uint256 colorCount;
        string style;
        string gravity;
        string grain;
        string display;
        string[14] html;
    }

    constructor() ERC721("Vibes", "VIBES") Ownable() {
        // set voluntary royalties, according to ERC2981, @ 1 / 77, or 1.3%, 130 basis points
        _setRoyalties(owner(), 130);
    }

    function getElement(uint256 tokenId) private view returns (string memory) {
        return Art.getElementByRoll(roll1000(tokenId, Art.ROLL_ELEMENT));
    }

    function getPalette(uint256 tokenId) private view returns (string memory) {
        return Art.getPaletteByRoll(roll1000(tokenId, Art.ROLL_PALETTE), getElement(tokenId));
    }

    function getColorByIndex(uint256 tokenId, uint256 lookupIndex) public view returns (string memory) {
        ColorInfo memory info;
        info.colorCount = getColorCount(tokenId);
        if (lookupIndex >= info.colorCount || tokenId == 0 || tokenId > super.totalSupply()) {
            return 'null';
        }

        (info.colorInts, info.colorIntCount, info.ordered, info.shuffle, info.restricted) = ColorData.getPaletteColors(getPalette(tokenId));

        uint256 i;
        uint256 temp;
        uint256 startIndex;
        uint256 currIndex;
        uint256 codeCount;

        info.colorIntsChosen = new uint256[](12);

        if (info.ordered) {
            temp = roll1000(tokenId, Art.ROLL_ORDERED);
            startIndex = temp % info.colorIntCount;
            for (i = 0; i < info.colorIntCount; i++) {
                currIndex = startIndex + i;
                if (currIndex >= info.colorIntCount) {
                    currIndex -= info.colorIntCount;
                }
                info.colorIntsChosen[i] = info.colorInts[currIndex];
            }
        } else if (info.shuffle) {
            codeCount = info.colorIntCount;

            while (codeCount > 0) {
                i = roll1000(tokenId, string(abi.encodePacked(Art.ROLL_SHUFFLE, toString(codeCount)))) % codeCount;
                codeCount -= 1;

                temp = info.colorInts[codeCount];
                info.colorInts[codeCount] = info.colorInts[i];
                info.colorInts[i] = temp;
            }

            for (i = 0; i < info.colorIntCount; i++) {
                info.colorIntsChosen[i] = info.colorInts[i];
            }
        } else {
            for (i = 0; i < info.colorIntCount; i++) {
                info.colorIntsChosen[i] = info.colorInts[i];
            }
        }

        if (info.restricted) {
            temp = getWobbledColor(info.colorIntsChosen[lookupIndex % info.colorIntCount], tokenId, lookupIndex);
        } else if (lookupIndex >= info.colorIntCount) {
            temp = getRandomColor(tokenId, lookupIndex);
        } else {
            temp = getWobbledColor(info.colorIntsChosen[lookupIndex], tokenId, lookupIndex);
        }

        return Art.getColorCode(temp);
    }

    function getWobbledColor(uint256 color, uint256 tokenId, uint256 index) private view returns (uint256) {
        uint256 r = (color >> uint256(16)) & uint256(255);
        uint256 g = (color >> uint256(8)) & uint256(255);
        uint256 b = color & uint256(255);
        uint256 offsetR = rollMax(tokenId, string(abi.encodePacked(Art.ROLL_RED, toString(index)))) % uint256(8);
        uint256 offsetG = rollMax(tokenId, string(abi.encodePacked(Art.ROLL_GREEN, toString(index)))) % uint256(8);
        uint256 offsetB = rollMax(tokenId, string(abi.encodePacked(Art.ROLL_BLUE, toString(index)))) % uint256(8);
        uint256 offsetDirR = rollMax(tokenId, string(abi.encodePacked(Art.ROLL_DIRRED, toString(index)))) % uint256(2);
        uint256 offsetDirG = rollMax(tokenId, string(abi.encodePacked(Art.ROLL_DIRGREEN, toString(index)))) % uint256(2);
        uint256 offsetDirB = rollMax(tokenId, string(abi.encodePacked(Art.ROLL_DIRBLUE, toString(index)))) % uint256(2);

        if (offsetDirR == uint256(0)) {
            if (r > offsetR) {
                r -= offsetR;
            } else {
                r = uint256(0);
            }
        } else {
            if (r + offsetR <= uint256(255)) {
                r += offsetR;
            } else {
                r = uint256(255);
            }
        }

        if (offsetDirG == uint256(0)) {
            if (g > offsetG) {
                g -= offsetG;
            } else {
                g = uint256(0);
            }
        } else {
            if (g + offsetG <= uint256(255)) {
                g += offsetG;
            } else {
                g = uint256(255);
            }
        }

        if (offsetDirB == uint256(0)) {
            if (b > offsetB) {
                b -= offsetB;
            } else {
                b = uint256(0);
            }
        } else {
            if (b + offsetB <= uint256(255)) {
                b += offsetB;
            } else {
                b = uint256(255);
            }
        }

        return uint256((r << uint256(16)) | (g << uint256(8)) | b);
    }

    function getRandomColor(uint256 tokenId, uint256 index) private view returns (uint256) {
        return rollMax(tokenId, string(abi.encodePacked(Art.ROLL_RANDOMCOLOR, toString(index)))) % uint256(16777216);
    }

    function getStyle(uint256 tokenId) private view returns (string memory) {
        return Art.getStyleByRoll(roll1000(tokenId, Art.ROLL_STYLE));
    }

    function getColorCount(uint256 tokenId) private view returns (uint256) {
        return Art.getColorCount(roll1000(tokenId, Art.ROLL_COLORCOUNT), getStyle(tokenId));
    }

    function getGravity(uint256 tokenId) private view returns (string memory) {
        string memory gravity;
        string memory style = getStyle(tokenId);
        uint256 colorCount = getColorCount(tokenId);
        uint256 roll = roll1000(tokenId, Art.ROLL_GRAVITY);

        if (colorCount >= uint256(5) && Art.compareStrings(style, Art.STYLE_SMOOTH)) {
            gravity = Art.getGravityLimitedByRoll(roll);
        } else {
            gravity = Art.getGravityByRoll(roll);
        }

        return gravity;
    }

    function getGrain(uint256 tokenId) private view returns (string memory) {
        return Art.getGrainByRoll(roll1000(tokenId, Art.ROLL_GRAIN));
    }

    function getDisplay(uint256 tokenId) private view returns (string memory) {
        return Art.getDisplayByRoll(roll1000(tokenId, Art.ROLL_DISPLAY));
    }

    function getRandomBlockhash(uint256 tokenId) private view returns (bytes32) {
        uint256 decrement = (tokenId % uint256(255)) % (block.number - uint256(1));
        uint256 blockIndex = block.number - (decrement + uint256(1));
        return blockhash(blockIndex);
    }

    function getEntropyHash(uint256 tokenId) private view returns (string memory) {
        return uint256(entropyHashes[tokenId]).toHexString();
    }

    function rollMax(uint256 tokenId, string memory key) private view returns (uint256) {
        string memory hashEntropy = getEntropyHash(tokenId);
        string memory tokenEntropy = string(abi.encodePacked(key, toString(tokenId)));
        return random(hashEntropy) ^ random(tokenEntropy);
    }

    function roll1000(uint256 tokenId, string memory key) private view returns (uint256) {
        return uint256(1) + rollMax(tokenId, key) % uint256(1000);
    }

    function random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function tokenScript(uint256 tokenId) public view returns (string memory) {
        require(tokenId > 0 && tokenId <= super.totalSupply(), 'invalid tokenId');

        TokenInfo memory info;
        info.entropyHash = getEntropyHash(tokenId);
        info.colorCount = getColorCount(tokenId);
        info.style = getStyle(tokenId);
        info.gravity = getGravity(tokenId);
        info.grain = getGrain(tokenId);
        info.display = getDisplay(tokenId);

        info.html[0] = '<!doctype html><html><head><script>';
        info.html[1] = string(abi.encodePacked('H="', info.entropyHash, '";'));
        info.html[2] = string(abi.encodePacked('Y="', info.style, '";'));
        info.html[3] = string(abi.encodePacked('G="', info.gravity, '";'));
        info.html[4] = string(abi.encodePacked('A="', info.grain, '";'));
        info.html[5] = string(abi.encodePacked('D="', info.display, '";'));

        string memory colorString;
        string memory partString;
        uint256 i;
        for (i = 0; i < 6; i++) {
            if (i < info.colorCount) {
                colorString = getColorByIndex(tokenId, i);
            } else {
                colorString = '';
            }

            if (i == 0) {
                partString = string(abi.encodePacked('P=["', colorString, '",'));
            } else if (i < info.colorCount - 1) {
                partString = string(abi.encodePacked('"', colorString, '",'));
            } else if (i < info.colorCount) {
                partString = string(abi.encodePacked('"', colorString, '"];'));
            } else {
                partString = '';
            }

            info.html[6 + i] = partString;
        }

        info.html[12] = Art.getScript();
        info.html[13] = '</script></head><body></body></html>';

        string memory output = string(abi.encodePacked(info.html[0], info.html[1], info.html[2], info.html[3], info.html[4], info.html[5], info.html[6]));
        return string(abi.encodePacked(output, info.html[7], info.html[8], info.html[9], info.html[10], info.html[11], info.html[12], info.html[13]));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(tokenId > 0 && tokenId <= super.totalSupply(), 'invalid tokenId');

        TokenInfo memory info;
        info.element = getElement(tokenId);
        info.palette = getPalette(tokenId);
        info.colorCount = getColorCount(tokenId);
        info.style = getStyle(tokenId);
        info.gravity = getGravity(tokenId);
        info.grain = getGrain(tokenId);
        info.display = getDisplay(tokenId);

        string memory imagePath = string(abi.encodePacked(baseVibeURI, toString(tokenId), '.jpg'));
        string memory json = string(abi.encodePacked('{"name": "vibe #', toString(tokenId), '", "description": "vibes is a generative art collection, randomly created and stored on chain. each token is an interactive html page that allows you to render your vibe at any size. vibes make their color palette available on chain, so feel free to carry your colors with you on your adventures.", "image": "', imagePath));

        if (useOnChainAnimation) {
            string memory script = tokenScript(tokenId);
            json = string(abi.encodePacked(json, '", "animation_url": "data:text/html;base64,', Base64.encode(bytes(script))));
        } else if (useAnimation) {
            json = string(abi.encodePacked(json, '", "animation_url": "', string(abi.encodePacked(baseVibeURI, toString(tokenId), '.html'))));
        }

        json = string(abi.encodePacked(json, '", "attributes": [{ "trait_type": "element", "value": "', info.element, '" }, { "trait_type": "palette", "value": "', info.palette, '" }, { "trait_type": "colors", "value": "', toString(info.colorCount), '" }, { "trait_type": "style", "value": "', info.style));
        json = string(abi.encodePacked(json, '" }, { "trait_type": "gravity", "value": "', info.gravity, '" }, { "trait_type": "grain", "value": "', info.grain, '" }, { "trait_type": "display", "value": "', info.display, '" }]}'));

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }

    function mintVibes(uint256 mintCount) public payable nonReentrant {
        uint256 lastTokenId = super.totalSupply();
        require(mintingActive, 'gm friend. minting vibes soon.');
        require(mintCount <= uint256(7), 'whoa friend. max 7 vibes a mint.');
        require(lastTokenId + mintCount <= uint256(7777), 'gn friend. only so many vibes.');
        require(MINT_COST * mintCount <= msg.value, 'hey friend. minting vibes costs more.');
        require(!isContract(_msgSender()), 'yo friend. no bot vibes. get a fresh wallet.');

        for (uint256 i = 1; i <= mintCount; i++) {
            mintVibe(_msgSender(), lastTokenId + i);
        }
    }

    function reserveVibes(uint256 reserveCount) public nonReentrant onlyOwner {
        uint256 lastTokenId = super.totalSupply();
        require(lastTokenId + reserveCount <= uint256(77), 'no worries friend. vibes already reserved.');

        for (uint256 i = 1; i <= reserveCount; i++) {
            mintVibe(owner(), lastTokenId + i);
        }
    }

    function mintVibe(address minter, uint256 tokenId) private {
        entropyHashes[tokenId] = getRandomBlockhash(tokenId);
        _safeMint(minter, tokenId);
    }

    function vibeCheck() public onlyOwner {
        mintingActive = !mintingActive;
    }

    function toggleAnimation() public onlyOwner {
        useAnimation = !useAnimation;
    }

    function toggleOnChainAnimation() public onlyOwner {
        useOnChainAnimation = !useOnChainAnimation;
    }

    function setVibeURI(string memory uri) public onlyOwner {
        baseVibeURI = uri;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981ContractWideRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

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

}

library ColorData {

    function getPaletteColors(string memory palette) public pure returns (uint256[] memory, uint256, bool, bool, bool) {
        uint256[] memory colorInts = new uint256[](12);
        uint256 colorIntCount = 0;
        bool ordered = false;
        bool shuffle = true;
        bool restricted = true;

        if (Art.compareStrings(palette, Art.NAT_PAL_JUNGLE)) {
            ordered = true;
            colorInts[0] = uint256(3299866);
            colorInts[1] = uint256(1256965);
            colorInts[2] = uint256(2375731);
            colorInts[3] = uint256(67585);
            colorInts[4] = uint256(16749568);
            colorInts[5] = uint256(16776295);
            colorInts[6] = uint256(16748230);
            colorInts[7] = uint256(16749568);
            colorInts[8] = uint256(67585);
            colorInts[9] = uint256(2375731);
            colorIntCount = uint256(10);
        } else if (Art.compareStrings(palette, Art.NAT_PAL_SPRING)) {
            colorInts[0] = uint256(11003600);
            colorInts[1] = uint256(14413507);
            colorInts[2] = uint256(16765879);
            colorInts[3] = uint256(16755365);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.NAT_PAL_CAMOUFLAGE)) {
            colorInts[0] = uint256(10328673);
            colorInts[1] = uint256(6245168);
            colorInts[2] = uint256(2171169);
            colorInts[3] = uint256(4610624);
            colorInts[4] = uint256(5269320);
            colorInts[5] = uint256(4994846);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.NAT_PAL_BLOSSOM)) {
            colorInts[0] = uint256(16749568);
            colorInts[1] = uint256(16776295);
            colorInts[2] = uint256(15348552);
            colorInts[3] = uint256(16748230);
            colorInts[4] = uint256(11826656);
            colorInts[5] = uint256(16769505);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.NAT_PAL_LEAF)) {
            shuffle = false;
            colorInts[0] = uint256(16773276);
            colorInts[1] = uint256(7790506);
            colorInts[2] = uint256(13888432);
            colorInts[3] = uint256(13140270);
            colorInts[4] = uint256(12822363);
            colorIntCount = uint256(5);
        } else if (Art.compareStrings(palette, Art.NAT_PAL_LEMONADE)) {
            colorInts[0] = uint256(16285109);
            colorInts[1] = uint256(16759385);
            colorInts[2] = uint256(16182422);
            colorInts[3] = uint256(616217);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.NAT_PAL_BIOLUMINESCENCE)) {
            colorInts[0] = uint256(2434341);
            colorInts[1] = uint256(4194315);
            colorInts[2] = uint256(6488209);
            colorInts[3] = uint256(7270568);
            colorInts[4] = uint256(9117400);
            colorInts[5] = uint256(1599944);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.NAT_PAL_RAINFOREST)) {
            ordered = true;
            colorInts[0] = uint256(2205512);
            colorInts[1] = uint256(558463);
            colorInts[2] = uint256(7195497);
            colorInts[3] = uint256(3116642);
            colorInts[4] = uint256(7131409);
            colorInts[5] = uint256(1673472);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.LIG_PAL_PASTEL)) {
            colorInts[0] = uint256(16761760);
            colorInts[1] = uint256(16756669);
            colorInts[2] = uint256(16636817);
            colorInts[3] = uint256(13762047);
            colorInts[4] = uint256(8714928);
            colorInts[5] = uint256(9425908);
            colorInts[6] = uint256(16499435);
            colorInts[7] = uint256(10587345);
            colorIntCount = uint256(8);
        } else if (Art.compareStrings(palette, Art.LIG_PAL_HOLY)) {
            colorInts[0] = uint256(16776685);
            colorInts[1] = uint256(16706239);
            colorInts[2] = uint256(16568740);
            colorInts[3] = uint256(15646621);
            colorInts[4] = uint256(11178648);
            colorIntCount = uint256(5);
        } else if (Art.compareStrings(palette, Art.LIG_PAL_SYLVAN)) {
            colorInts[0] = uint256(16691652);
            colorInts[1] = uint256(15987447);
            colorInts[2] = uint256(7580394);
            colorInts[3] = uint256(12809355);
            colorInts[4] = uint256(12821954);
            colorInts[5] = uint256(7718129);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.LIG_PAL_GLOW)) {
            colorInts[0] = uint256(8257501);
            colorInts[1] = uint256(12030203);
            colorInts[2] = uint256(9338616);
            colorInts[3] = uint256(16751583);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.LIG_PAL_SUNSET)) {
            colorInts[0] = uint256(15887184);
            colorInts[1] = uint256(14837651);
            colorInts[2] = uint256(16748936);
            colorInts[3] = uint256(11817579);
            colorInts[4] = uint256(8473468);
            colorIntCount = uint256(5);
        } else if (Art.compareStrings(palette, Art.LIG_PAL_INFRARED)) {
            ordered = true;
            colorInts[0] = uint256(16642938);
            colorInts[1] = uint256(16755712);
            colorInts[2] = uint256(15883521);
            colorInts[3] = uint256(13503623);
            colorInts[4] = uint256(8257951);
            colorInts[5] = uint256(327783);
            colorInts[6] = uint256(13503623);
            colorInts[7] = uint256(15883521);
            colorIntCount = uint256(8);
        } else if (Art.compareStrings(palette, Art.LIG_PAL_ULTRAVIOLET)) {
            colorInts[0] = uint256(14200063);
            colorInts[1] = uint256(5046460);
            colorInts[2] = uint256(16775167);
            colorInts[3] = uint256(16024318);
            colorInts[4] = uint256(11665662);
            colorInts[5] = uint256(1507410);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.LIG_PAL_YANG)) {
            restricted = false;
            colorInts[0] = uint256(16777215);
            colorIntCount = uint256(1);
        } else if (Art.compareStrings(palette, Art.WAT_PAL_ARCHIPELAGO)) {
            colorInts[0] = uint256(10079171);
            colorInts[1] = uint256(15261129);
            colorInts[2] = uint256(43954);
            colorInts[3] = uint256(13742713);
            colorInts[4] = uint256(15854035);
            colorInts[5] = uint256(2982588);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.WAT_PAL_FROZEN)) {
            colorInts[0] = uint256(13034750);
            colorInts[1] = uint256(4102128);
            colorInts[2] = uint256(826589);
            colorInts[3] = uint256(346764);
            colorInts[4] = uint256(6707);
            colorInts[5] = uint256(1277652);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.WAT_PAL_VAPOR)) {
            colorInts[0] = uint256(9361904);
            colorInts[1] = uint256(15724747);
            colorInts[2] = uint256(2781329);
            colorInts[3] = uint256(6194589);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.WAT_PAL_DAWN)) {
            colorInts[0] = uint256(334699);
            colorInts[1] = uint256(610965);
            colorInts[2] = uint256(5408708);
            colorInts[3] = uint256(16755539);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.WAT_PAL_GLACIER)) {
            colorInts[0] = uint256(13298921);
            colorInts[1] = uint256(1792100);
            colorInts[2] = uint256(6342370);
            colorInts[3] = uint256(5484740);
            colorInts[4] = uint256(2787216);
            colorInts[5] = uint256(1327172);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.WAT_PAL_SHANTY)) {
            colorInts[0] = uint256(600905);
            colorInts[1] = uint256(625330);
            colorInts[2] = uint256(30334);
            colorInts[3] = uint256(1552554);
            colorInts[4] = uint256(1263539);
            colorInts[5] = uint256(577452);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.WAT_PAL_VICE)) {
            colorInts[0] = uint256(41952);
            colorInts[1] = uint256(46760);
            colorInts[2] = uint256(16491446);
            colorInts[3] = uint256(16765877);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.WAT_PAL_OPALESCENT)) {
            ordered = true;
            colorInts[0] = uint256(15985337);
            colorInts[1] = uint256(15981758);
            colorInts[2] = uint256(15713994);
            colorInts[3] = uint256(13941977);
            colorInts[4] = uint256(8242919);
            colorInts[5] = uint256(15985337);
            colorInts[6] = uint256(15981758);
            colorInts[7] = uint256(15713994);
            colorInts[8] = uint256(13941977);
            colorInts[9] = uint256(8242919);
            colorIntCount = uint256(10);
        } else if (Art.compareStrings(palette, Art.EAR_PAL_ARID)) {
            restricted = false;
            colorInts[0] = uint256(16494931);
            colorInts[1] = uint256(14979685);
            colorInts[2] = uint256(4989197);
            colorInts[3] = uint256(15158540);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.EAR_PAL_RIDGE)) {
            colorInts[0] = uint256(273743);
            colorInts[1] = uint256(2175795);
            colorInts[2] = uint256(7837380);
            colorInts[3] = uint256(1975345);
            colorInts[4] = uint256(8228210);
            colorInts[5] = uint256(6571631);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.EAR_PAL_COAL)) {
            colorInts[0] = uint256(3613475);
            colorInts[1] = uint256(1577233);
            colorInts[2] = uint256(4407359);
            colorInts[3] = uint256(2894892);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.EAR_PAL_TOUCH)) {
            colorInts[0] = uint256(13149573);
            colorInts[1] = uint256(13012609);
            colorInts[2] = uint256(11044194);
            colorInts[3] = uint256(8145729);
            colorInts[4] = uint256(6046249);
            colorInts[5] = uint256(5123882);
            colorInts[6] = uint256(13934738);
            colorInts[7] = uint256(12096624);
            colorInts[8] = uint256(12024688);
            colorInts[9] = uint256(7426613);
            colorInts[10] = uint256(6634804);
            colorInts[11] = uint256(4731682);
            colorIntCount = uint256(12);
        } else if (Art.compareStrings(palette, Art.EAR_PAL_BRONZE)) {
            colorInts[0] = uint256(16166768);
            colorInts[1] = uint256(10578500);
            colorInts[2] = uint256(7555631);
            colorInts[3] = uint256(16105363);
            colorInts[4] = uint256(11894865);
            colorInts[5] = uint256(5323820);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.EAR_PAL_SILVER)) {
            colorInts[0] = uint256(16053492);
            colorInts[1] = uint256(15329769);
            colorInts[2] = uint256(10132122);
            colorInts[3] = uint256(6776679);
            colorInts[4] = uint256(3881787);
            colorInts[5] = uint256(1579032);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.EAR_PAL_GOLD)) {
            colorInts[0] = uint256(16373583);
            colorInts[1] = uint256(12152866);
            colorInts[2] = uint256(12806164);
            colorInts[3] = uint256(4725765);
            colorInts[4] = uint256(2557441);
            colorIntCount = uint256(5);
        } else if (Art.compareStrings(palette, Art.EAR_PAL_PLATINUM)) {
            colorInts[0] = uint256(15466475);
            colorInts[1] = uint256(14215669);
            colorInts[2] = uint256(7962760);
            colorInts[3] = uint256(13101564);
            colorInts[4] = uint256(7912858);
            colorInts[5] = uint256(3703413);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.WIN_PAL_BERRY)) {
            shuffle = false;
            colorInts[0] = uint256(5428970);
            colorInts[1] = uint256(13323211);
            colorInts[2] = uint256(15385745);
            colorInts[3] = uint256(13355851);
            colorInts[4] = uint256(15356630);
            colorInts[5] = uint256(14903600);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.WIN_PAL_BREEZE)) {
            colorInts[0] = uint256(9952971);
            colorInts[1] = uint256(14020036);
            colorInts[2] = uint256(16766134);
            colorInts[3] = uint256(16755367);
            colorInts[4] = uint256(1091816);
            colorIntCount = uint256(5);
        } else if (Art.compareStrings(palette, Art.WIN_PAL_JOLT)) {
            colorInts[0] = uint256(16240492);
            colorInts[1] = uint256(3083849);
            colorInts[2] = uint256(15463155);
            colorInts[3] = uint256(12687431);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.WIN_PAL_THUNDER)) {
            colorInts[0] = uint256(924722);
            colorInts[1] = uint256(9464002);
            colorInts[2] = uint256(470093);
            colorInts[3] = uint256(6378394);
            colorInts[4] = uint256(16246484);
            colorInts[5] = uint256(12114921);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.WIN_PAL_WINTER)) {
            colorInts[0] = uint256(16051966);
            colorInts[1] = uint256(14472694);
            colorInts[2] = uint256(10924255);
            colorInts[3] = uint256(4474995);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.WIN_PAL_HEATHERMOOR)) {
            colorInts[0] = uint256(16774653);
            colorInts[1] = uint256(10915755);
            colorInts[2] = uint256(16750253);
            colorInts[3] = uint256(208472);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.WIN_PAL_ZEUS)) {
            colorInts[0] = uint256(12361355);
            colorInts[1] = uint256(10243124);
            colorInts[2] = uint256(13747897);
            colorInts[3] = uint256(9925744);
            colorInts[4] = uint256(8026744);
            colorInts[5] = uint256(12945517);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.WIN_PAL_MATRIX)) {
            shuffle = false;
            colorInts[0] = uint256(4609);
            colorInts[1] = uint256(803087);
            colorInts[2] = uint256(2062109);
            colorInts[3] = uint256(11009906);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.ARC_PAL_PLASTIC)) {
            colorInts[0] = uint256(16772570);
            colorInts[1] = uint256(4043519);
            colorInts[2] = uint256(16758832);
            colorInts[3] = uint256(16720962);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.ARC_PAL_COSMIC)) {
            ordered = true;
            colorInts[0] = uint256(1182264);
            colorInts[1] = uint256(10834562);
            colorInts[2] = uint256(4269159);
            colorInts[3] = uint256(16769495);
            colorInts[4] = uint256(3351916);
            colorInts[5] = uint256(12612224);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.ARC_PAL_BUBBLE)) {
            colorInts[0] = uint256(11065577);
            colorInts[1] = uint256(11244760);
            colorInts[2] = uint256(16628178);
            colorInts[3] = uint256(16777172);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.ARC_PAL_ESPER)) {
            shuffle = false;
            colorInts[0] = uint256(15651304);
            colorInts[1] = uint256(5867181);
            colorInts[2] = uint256(12929115);
            colorInts[3] = uint256(11896986);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.ARC_PAL_SPIRIT)) {
            colorInts[0] = uint256(590090);
            colorInts[1] = uint256(4918854);
            colorInts[2] = uint256(8196724);
            colorInts[3] = uint256(16555462);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.ARC_PAL_COLORLESS)) {
            colorInts[0] = uint256(1644825);
            colorInts[1] = uint256(15132390);
            colorIntCount = uint256(2);
        } else if (Art.compareStrings(palette, Art.ARC_PAL_ENTROPY)) {
            restricted = false;
            colorIntCount = uint256(0);
        } else if (Art.compareStrings(palette, Art.ARC_PAL_YINYANG)) {
            restricted = false;
            colorInts[0] = uint256(0);
            colorInts[1] = uint256(16777215);
            colorIntCount = uint256(2);
        } else if (Art.compareStrings(palette, Art.SHA_PAL_MOONRISE)) {
            colorInts[0] = uint256(1180799);
            colorInts[1] = uint256(16753004);
            colorInts[2] = uint256(5767292);
            colorInts[3] = uint256(1179979);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.SHA_PAL_UMBRAL)) {
            colorInts[0] = uint256(4479070);
            colorInts[1] = uint256(16377469);
            colorInts[2] = uint256(1845042);
            colorInts[3] = uint256(11285763);
            colorInts[4] = uint256(16711577);
            colorIntCount = uint256(5);
        } else if (Art.compareStrings(palette, Art.SHA_PAL_DARKNESS)) {
            colorInts[0] = uint256(2885188);
            colorInts[1] = uint256(1572943);
            colorInts[2] = uint256(1179979);
            colorInts[3] = uint256(657930);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.SHA_PAL_SHARKSKIN)) {
            colorInts[0] = uint256(2304306);
            colorInts[1] = uint256(3817287);
            colorInts[2] = uint256(44469);
            colorInts[3] = uint256(15658734);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.SHA_PAL_VOID)) {
            colorInts[0] = uint256(1572943);
            colorInts[1] = uint256(4194415);
            colorInts[2] = uint256(6488209);
            colorInts[3] = uint256(13051525);
            colorInts[4] = uint256(657930);
            colorIntCount = uint256(5);
        } else if (Art.compareStrings(palette, Art.SHA_PAL_IMMORTAL)) {
            colorInts[0] = uint256(1642512);
            colorInts[1] = uint256(7084837);
            colorInts[2] = uint256(8720180);
            colorInts[3] = uint256(16121899);
            colorInts[4] = uint256(138580);
            colorIntCount = uint256(5);
        } else if (Art.compareStrings(palette, Art.SHA_PAL_UNDEAD)) {
            shuffle = false;
            colorInts[0] = uint256(3546937);
            colorInts[1] = uint256(50595);
            colorInts[2] = uint256(7511983);
            colorInts[3] = uint256(7563923);
            colorInts[4] = uint256(10535352);
            colorIntCount = uint256(5);
        } else if (Art.compareStrings(palette, Art.SHA_PAL_YIN)) {
            restricted = false;
            colorInts[0] = uint256(0);
            colorIntCount = uint256(1);
        } else if (Art.compareStrings(palette, Art.FIR_PAL_VOLCANO)) {
            colorInts[0] = uint256(3152931);
            colorInts[1] = uint256(15027482);
            colorInts[2] = uint256(14690821);
            colorInts[3] = uint256(16167309);
            colorInts[4] = uint256(6320499);
            colorInts[5] = uint256(1512470);
            colorIntCount = uint256(6);
        } else if (Art.compareStrings(palette, Art.FIR_PAL_HEAT)) {
            shuffle = false;
            colorInts[0] = uint256(590337);
            colorInts[1] = uint256(12141574);
            colorInts[2] = uint256(15908162);
            colorInts[3] = uint256(6886400);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.FIR_PAL_FLARE)) {
            shuffle = false;
            colorInts[0] = uint256(16353609);
            colorInts[1] = uint256(11580);
            colorInts[2] = uint256(16513713);
            colorInts[3] = uint256(12474923);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.FIR_PAL_SOLAR)) {
            shuffle = false;
            colorInts[0] = uint256(984066);
            colorInts[1] = uint256(6300419);
            colorInts[2] = uint256(16368685);
            colorInts[3] = uint256(16570745);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.FIR_PAL_SUMMER)) {
            colorInts[0] = uint256(16428419);
            colorInts[1] = uint256(16738152);
            colorInts[2] = uint256(16727143);
            colorInts[3] = uint256(11022726);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.FIR_PAL_EMBER)) {
            shuffle = false;
            colorInts[0] = uint256(1180162);
            colorInts[1] = uint256(7929858);
            colorInts[2] = uint256(7012357);
            colorInts[3] = uint256(16744737);
            colorIntCount = uint256(4);
        } else if (Art.compareStrings(palette, Art.FIR_PAL_COMET)) {
            shuffle = false;
            colorInts[0] = uint256(197130);
            colorInts[1] = uint256(803727);
            colorInts[2] = uint256(4441816);
            colorInts[3] = uint256(602997);
            colorIntCount = uint256(4);
        } else {
            shuffle = false;
            colorInts[0] = uint256(197391);
            colorInts[1] = uint256(3604610);
            colorInts[2] = uint256(6553778);
            colorInts[3] = uint256(14305728);
            colorIntCount = uint256(4);
        }

        return (colorInts, colorIntCount, ordered, shuffle, restricted);
    }

}

library Art {

    string public constant ROLL_ELEMENT = 'ELEMENT';
    string public constant ROLL_PALETTE = 'PALETTE';
    string public constant ROLL_ORDERED = 'ORDERED';
    string public constant ROLL_SHUFFLE = 'SHUFFLE';
    string public constant ROLL_RED = 'RED';
    string public constant ROLL_GREEN = 'GREEN';
    string public constant ROLL_BLUE = 'BLUE';
    string public constant ROLL_DIRRED = 'DIRRED';
    string public constant ROLL_DIRGREEN = 'DIRGREEN';
    string public constant ROLL_DIRBLUE = 'DIRBLUE';
    string public constant ROLL_RANDOMCOLOR = 'RANDOMCOLOR';
    string public constant ROLL_STYLE = 'STYLE';
    string public constant ROLL_COLORCOUNT = 'COLORCOUNT';
    string public constant ROLL_GRAVITY = 'GRAVITY';
    string public constant ROLL_GRAIN = 'GRAIN';
    string public constant ROLL_DISPLAY = 'DISPLAY';

    string public constant ELEM_NATURE = 'nature';
    string public constant ELEM_LIGHT = 'light';
    string public constant ELEM_WATER = 'water';
    string public constant ELEM_EARTH = 'earth';
    string public constant ELEM_WIND = 'wind';
    string public constant ELEM_ARCANE = 'arcane';
    string public constant ELEM_SHADOW = 'shadow';
    string public constant ELEM_FIRE = 'fire';

    string public constant NAT_PAL_JUNGLE = 'jungle';
    string public constant NAT_PAL_SPRING = 'spring';
    string public constant NAT_PAL_CAMOUFLAGE = 'camouflage';
    string public constant NAT_PAL_BLOSSOM = 'blossom';
    string public constant NAT_PAL_LEAF = 'leaf';
    string public constant NAT_PAL_LEMONADE = 'lemonade';
    string public constant NAT_PAL_BIOLUMINESCENCE = 'bioluminescence';
    string public constant NAT_PAL_RAINFOREST = 'rainforest';

    string public constant LIG_PAL_PASTEL = 'pastel';
    string public constant LIG_PAL_HOLY = 'holy';
    string public constant LIG_PAL_SYLVAN = 'sylvan';
    string public constant LIG_PAL_GLOW = 'glow';
    string public constant LIG_PAL_SUNSET = 'sunset';
    string public constant LIG_PAL_INFRARED = 'infrared';
    string public constant LIG_PAL_ULTRAVIOLET = 'ultraviolet';
    string public constant LIG_PAL_YANG = 'yang';

    string public constant WAT_PAL_ARCHIPELAGO = 'archipelago';
    string public constant WAT_PAL_FROZEN = 'frozen';
    string public constant WAT_PAL_VAPOR = 'vapor';
    string public constant WAT_PAL_DAWN = 'dawn';
    string public constant WAT_PAL_GLACIER = 'glacier';
    string public constant WAT_PAL_SHANTY = 'shanty';
    string public constant WAT_PAL_VICE = 'vice';
    string public constant WAT_PAL_OPALESCENT = 'opalescent';

    string public constant EAR_PAL_ARID = 'arid';
    string public constant EAR_PAL_RIDGE = 'ridge';
    string public constant EAR_PAL_COAL = 'coal';
    string public constant EAR_PAL_TOUCH = 'touch';
    string public constant EAR_PAL_BRONZE = 'bronze';
    string public constant EAR_PAL_SILVER = 'silver';
    string public constant EAR_PAL_GOLD = 'gold';
    string public constant EAR_PAL_PLATINUM = 'platinum';

    string public constant WIN_PAL_BERRY = 'berry';
    string public constant WIN_PAL_BREEZE = 'breeze';
    string public constant WIN_PAL_JOLT = 'jolt';
    string public constant WIN_PAL_THUNDER = 'thunder';
    string public constant WIN_PAL_WINTER = 'winter';
    string public constant WIN_PAL_HEATHERMOOR = 'heathermoor';
    string public constant WIN_PAL_ZEUS = 'zeus';
    string public constant WIN_PAL_MATRIX = 'matrix';

    string public constant ARC_PAL_PLASTIC = 'plastic';
    string public constant ARC_PAL_COSMIC = 'cosmic';
    string public constant ARC_PAL_BUBBLE = 'bubble';
    string public constant ARC_PAL_ESPER = 'esper';
    string public constant ARC_PAL_SPIRIT = 'spirit';
    string public constant ARC_PAL_COLORLESS = 'colorless';
    string public constant ARC_PAL_ENTROPY = 'entropy';
    string public constant ARC_PAL_YINYANG = 'yinyang';

    string public constant SHA_PAL_MOONRISE = 'moonrise';
    string public constant SHA_PAL_UMBRAL = 'umbral';
    string public constant SHA_PAL_DARKNESS = 'darkness';
    string public constant SHA_PAL_SHARKSKIN = 'sharkskin';
    string public constant SHA_PAL_VOID = 'void';
    string public constant SHA_PAL_IMMORTAL = 'immortal';
    string public constant SHA_PAL_UNDEAD = 'undead';
    string public constant SHA_PAL_YIN = 'yin';

    string public constant FIR_PAL_VOLCANO = 'volcano';
    string public constant FIR_PAL_HEAT = 'heat';
    string public constant FIR_PAL_FLARE = 'flare';
    string public constant FIR_PAL_SOLAR = 'solar';
    string public constant FIR_PAL_SUMMER = 'summer';
    string public constant FIR_PAL_EMBER = 'ember';
    string public constant FIR_PAL_COMET = 'comet';
    string public constant FIR_PAL_CORRUPTED = 'corrupted';

    string public constant STYLE_SMOOTH = 'smooth';
    string public constant STYLE_PAJAMAS = 'pajamas';
    string public constant STYLE_SILK = 'silk';
    string public constant STYLE_RETRO = 'retro';
    string public constant STYLE_SKETCH = 'sketch';

    string public constant GRAV_LUNAR = 'lunar';
    string public constant GRAV_ATMOSPHERIC = 'atmospheric';
    string public constant GRAV_LOW = 'low';
    string public constant GRAV_NORMAL = 'normal';
    string public constant GRAV_HIGH = 'high';
    string public constant GRAV_MASSIVE = 'massive';
    string public constant GRAV_STELLAR = 'stellar';
    string public constant GRAV_GALACTIC = 'galactic';

    string public constant GRAIN_NULL = 'null';
    string public constant GRAIN_FADED = 'faded';
    string public constant GRAIN_NONE = 'none';
    string public constant GRAIN_SOFT = 'soft';
    string public constant GRAIN_MEDIUM = 'medium';
    string public constant GRAIN_ROUGH = 'rough';
    string public constant GRAIN_RED = 'red';
    string public constant GRAIN_GREEN = 'green';
    string public constant GRAIN_BLUE = 'blue';

    string public constant DISPLAY_NORMAL = 'normal';
    string public constant DISPLAY_MIRRORED = 'mirrored';
    string public constant DISPLAY_UPSIDEDOWN = 'upsideDown';
    string public constant DISPLAY_MIRROREDUPSIDEDOWN = 'mirroredUpsideDown';

    string public constant SCRIPT = 'UDS=window.UDS!==void 0&&window.UDS,FVCS=window.FVCS===void 0?0:window.FVCS;var b,d,dcE,baC,R,C=P.length,MRCS=9600,DCS=.8,MCS=.0625,PAD=8,L={r:.9,d:.1},BC2=[{x:.5,y:.5},{x:.75,y:0}],BC3=[{x:.65,y:.15},{x:.5,y:.5},{x:.75,y:.75}],BC4=[{x:.5,y:0},{x:0,y:.5},{x:.5,y:1},{x:1,y:.5}],BC5=[{x:.5,y:.5},{x:.5,y:0},{x:0,y:.5},{x:.5,y:1},{x:1,y:.5}],BC6=[{x:.5,y:.5},{x:.5,y:0},{x:1,y:0},{x:1,y:1},{x:0,y:1},{x:0,y:0}],BC=[,,BC2,BC3,BC4,BC5,BC6],a="absolute",p="1px solid",c="canvas",q="2d",e="resize",o="px",wRE=window.removeEventListener,mn=Math.min,mx=Math.max,pw=Math.pow,f=Math.floor,pC=BC[C],sM=SD,sSZ=1/3;"pajamas"==Y&&(sM=SS,sSZ=1/99),"silk"==Y&&(sM=SS,sSZ=1/3),"retro"==Y&&(sM=SS,sSZ=3/2),"sketch"==Y&&(sM=SRS);var fX=!("mirrored"!=D&&"mirroredUpsideDown"!=D),fY=!("upsideDown"!=D&&"mirroredUpsideDown"!=D),gv=3;"lunar"==G&&(gv=.5),"atmospheric"==G&&(gv=1),"low"==G&&(gv=2),"high"==G&&(gv=6),"massive"==G&&(gv=9),"stellar"==G&&(gv=12),"galactic"==G&&(gv=24);var gr={r:{o:0,r:0},g:{o:0,r:0},b:{o:0,r:0}};"null"==A&&(gr={r:{o:0,r:-512},g:{o:0,r:-512},b:{o:0,r:-512}}),"faded"==A&&(gr={r:{o:0,r:-128},g:{o:0,r:-128},b:{o:0,r:-128}}),"soft"==A&&(gr={r:{o:-4,r:8},g:{o:-4,r:8},b:{o:-4,r:8}}),"medium"==A&&(gr={r:{o:-8,r:16},g:{o:-8,r:16},b:{o:-8,r:16}}),"rough"==A&&(gr={r:{o:-16,r:32},g:{o:-16,r:32},b:{o:-16,r:32}}),"red"==A&&(gr={r:{o:-16,r:32},g:{o:0,r:0},b:{o:0,r:0}}),"green"==A&&(gr={r:{o:0,r:0},g:{o:-16,r:32},b:{o:0,r:0}}),"blue"==A&&(gr={r:{o:0,r:0},g:{o:0,r:0},b:{o:-16,r:32}});var dC,vC,pCv,pCx,lC,lX,lW,rB,pL,pI,dsL,dsC,wW=0,wH=0,vCS=600,dCS=DCS,dCZ=vCS/dCS,cPts=[],sVl=-1,pIdx=0,lPc=0,rPc=0,dPc=0;function SD(c,a){return c.d-a.d}function SS(){var a=sVl;return sVl+=sSZ,2<=sVl&&(sVl-=3),a}function SRS(){var a=sVl;return sVl+=1/(R()*dCZ),2<=sVl&&(sVl-=3),a}function uLP(){lPc=L.r*rPc+L.d*dPc,lW||(lW=lC.width,lX.fillStyle="#2f2");var a=lPc*lW;lX.fillRect(0,0,a,PAD)}function rnCS(){for(var a=cPts.length,b=2*PAD,c=(lW-(2*a*b-b))/2,d=0;d<a;d++){var e=cPts[d],f=c+2*d*b;pCx.fillStyle="#000",pCx.fillRect(f-1,0,b+2,b+2),pCx.fillStyle="rgb("+e.r+","+e.g+","+e.b+")",pCx.fillRect(f,1,b,b)}}window.onload=function(){ii()};function ii(){sRO(),sS(),cE(),sRn()}function sS(){var a=Uint32Array.from([0,1,s=t=2,3].map(function(a){return parseInt(H.substr(8*a+2,8),16)}));R=function(){return t=a[3],a[3]=a[2],a[2]=a[1],a[1]=s=a[0],t^=t<<11,a[0]^=t^t>>>8^s>>>19,a[0]/4294967296},"tx piter"}function sRO(){d=document,b=d.body,dcE=d.createElement.bind(d),baC=b.appendChild.bind(b),wW=mx(b.clientWidth,window.innerWidth),wH=mx(b.clientHeight,window.innerHeight);var a=wW>wH,c=a?wH:wW;vCS=0<FVCS?mn(MRCS,FVCS):mn(MRCS,c),dCS=UDS?MCS:DCS,dCZ=f(vCS/dCS),dCZ>MRCS&&(dCZ=MRCS),dCS=vCS/dCZ,lPc=0,rPc=0,dPc=0,lW=0,sVl=-1,pIdx=0,cPts.length=0}function sCl(){for(var a=P.slice(),b=0;b<C;b++){var c=gCP(),d=a[b],e=parseInt(d,16);c.r=255&e>>16,c.g=255&e>>8,c.b=255&e,c.weight=pw(gv,5-b),pPt(c),cPts.push(c)}if(2===C)for(var f=cPts[0],g=cPts[1];;){var h=g.y-f.y,j=g.x-f.x,k=h/(j||1);if(-1.2<=k&&-.8>=k)pIdx=0,pPt(f),pPt(g);else break}rnCS()}function cE(){dC=dcE(c),vC=dcE(c),vC.style.position=a,vC.style.border=p,baC(vC),pCv=dcE(c),pCv.style.position=a,baC(pCv),pCx=pCv.getContext(q),lC=dcE(c),lC.style.position=a,lC.style.border=p,baC(lC),lX=lC.getContext(q),rB=dcE("button"),rB.style.position=a,rB.innerHTML="Render",rB.addEventListener("click",oRC),baC(rB),pL=dcE("label"),pL.style.position=a,pL.innerHTML="Size in Pixels (16 - 9600):",baC(pL),pI=dcE("input"),pI.style.position=a,pI.min=16,pI.max=MRCS,pI.value=vCS,pI.type="number",baC(pI),dsL=dcE("label"),dsL.style.position=a,dsL.innerHTML="Downsample (Best Result):",baC(dsL),dsC=dcE("input"),dsC.style.position=a,dsC.type="checkbox",dsC.checked=!0,baC(dsC)}function sRn(){rzVC(),rV(),uLP(),dC.width=dCZ,dC.height=dCZ,rd(dC,function(){.4>=dCS?pIm(dC,function(a){dTVC(a),sRH(a)}):(dTVC(dC),sRH(dC),dPc=1,uLP())})}var rCB;function sRH(a){window.RNCB!==void 0&&window.RNCB(vC),wRE(e,rCB,!0),rCB=function(){sRO(),rzVC(),dTVC(a)},window.addEventListener(e,rCB,!0)}function rV(){var a=f(vCS/12.5),b=f(a/12),c=vCS/60,d=vC.getContext(q);vC.style.letterSpacing=b+o,d.fillStyle="#161616",d.fillRect(0,0,vCS,vCS),d.fillStyle="#E9E9E9",d.font=a+"px sans-serif",d.textBaseline="middle",d.textAlign="center",d.fillText("vibing...",c+vCS/2,vCS/2,vCS)}function rd(a,b){var c=a.getContext(q),d=c.getImageData(0,0,a.width,a.height);dCPG(d,function(){c.putImageData(d,0,0),b()},!1)}function rzVC(){var a=f((wW-vCS)/2),b=f((wH-vCS)/2),c=a+PAD,d=b+vCS+PAD,e=c,g=d+2*PAD;vC.style.left=a+o,vC.style.top=b+o,vC.width=vCS,vC.height=vCS,pCv.style.left=c+o,pCv.style.top=b-3*PAD-2+o,pCv.width=vCS-2*PAD,pCv.height=2*PAD+2,lC.style.left=c+o,lC.style.top=d+o,lC.width=vCS-2*PAD,lC.height=PAD,pL.style.left=e+o,pL.style.top=g+o,pI.style.left=e+180+o,pI.style.top=g+o,dsL.style.left=e+o,dsL.style.top=g+3*PAD+o,dsC.style.left=e+180+o,dsC.style.top=g+3*PAD+o,rB.style.left=e+o,rB.style.top=g+6*PAD+o}function dTVC(a){var b=vC.getContext(q);fX&&(b.translate(vCS,0),b.scale(-1,1)),fY&&(b.translate(0,vCS),b.scale(1,-1)),b.drawImage(a,0,0,vCS,vCS),aG(b)}function aG(a){for(var b=a.getImageData(0,0,vCS,vCS),c=b.data,d=c.length,e=0;e<d;e+=4)c[e+0]+=gr.r.o+R()*gr.r.r,c[e+1]+=gr.g.o+R()*gr.g.r,c[e+2]+=gr.b.o+R()*gr.b.r;a.putImageData(b,0,0)}function pIm(a,b){var c=new Image;c.addEventListener("load",function(){dPc=.6,uLP(),b(rdI(c,vCS,vCS))}),c.src=a.toDataURL()}var _x=0,_y=0;function dCPG(a,b,c){var d=Date.now();for(c||(_x=0,_y=0,sCl());_x<dCZ;){for(_y=0;_y<dCZ;)sQG(a,cPts,_x,_y,dCZ,dCZ),_y++;_x++;var e=Date.now()-d;if(500<=e){rPc=_x/dCZ,uLP();break}}_x===dCZ?(rPc=1,uLP(),b()):setTimeout(function(){dCPG(a,b,!0)},0)}function gCP(){return{x:0,y:0,r:0,g:0,b:0,weight:1,d:0}}function pPt(a){var b=pC[pIdx++];pIdx>=pC.length&&(pIdx=0);var c=-.125+.25*R(),d=-.125+.25*R();a.x=(b.x+c)*dCZ,a.y=(b.y+d)*dCZ}function sQG(a,b,c,d,e,f){srtCC(b,c,d);for(var g=[],h=b.length,j=0;j<h;j+=2)j==h-1?g.push(b[j]):g.push(smsh(b[j],b[j+1]));if(1===g.length){var k=4*(d*e)+4*c,l=g[0],m=a.data;m[k+0]=l.r,m[k+1]=l.g,m[k+2]=l.b,m[k+3]=255}else sQG(a,g,c,d,e,f)}function srtCC(a,b,c){for(var d,e=0;e<a.length;e++)d=a[e],d.d=gD3(b,c,d.x,d.y);a.sort(sM)}function gD3(a,b,c,d){return pw(c-a,3)+pw(d-b,3)}function smsh(a,b){var c=gCP(),d=a.r,e=a.g,f=a.b,g=b.r,h=b.g,i=b.b,j=a.weight,k=b.weight,l=a.d*j,m=b.d*k,n=m/(l+m);return c.x=(a.x+b.x)/2,c.y=(a.y+b.y)/2,c.r=n*(g-d)+d,c.g=n*(h-e)+e,c.b=n*(i-f)+f,c.weight=(j+k)/2,c}function rdI(a,d,e){var f,h,i,j,k,l,m,n,o=0,p=a.naturalWidth,u=a.naturalHeight,v=dcE(c);v.width=p,v.height=u;var w=v.getContext(q),z=dcE(c);z.width=d,z.height=e;var B=z.getContext(q);w.drawImage(a,0,0);for(var C=w.getImageData(0,0,p,u).data,E=B.getImageData(0,0,d,e),F=p/d,I=u/e,J=C,K=E.data;o<e;){for(i=o*I,f=0;f<d;){h=f*F;var L=i+I,M=h+F;for(l=m=n=a=0,k=0|i;k<L;){var N=k+1,O=N>L?L-k:k<i?1-(i-k):1;for(j=0|h;j<M;){var Q=j+1,R=Q>M?M-j:j<h?1-(h-j):1,S=O*R/(F*I),T=4*(k*p+j);l+=J[T]/255*S,m+=J[T+1]/255*S,n+=J[T+2]/255*S,j+=1}k+=1}var T=4*(o*d+f);K[T]=255*l,K[T+1]=255*m,K[T+2]=255*n,K[T+3]=255,f+=1}o+=1,dPc=.6+.4*o/e,uLP()}return B.putImageData(E,0,0),z}function oRC(){var a=mx(16,mn(MRCS,+pI.value||vCS)),b=dsC.checked;FVCS=a,UDS=b,wRE(e,rCB,!0),sRO(),sS(),sRn()}';

    function getElementByRoll(uint256 roll) public pure returns (string memory) {
        string memory element;
        if (roll <= uint256(125)) {
            element = ELEM_NATURE;
        } else if (roll <= uint256(250)) {
            element = ELEM_LIGHT;
        } else if (roll <= uint256(375)) {
            element = ELEM_WATER;
        } else if (roll <= uint256(500)) {
            element = ELEM_EARTH;
        } else if (roll <= uint256(625)) {
            element = ELEM_WIND;
        } else if (roll <= uint256(750)) {
            element = ELEM_ARCANE;
        } else if (roll <= uint256(875)) {
            element = ELEM_SHADOW;
        } else {
            element = ELEM_FIRE;
        }
        return element;
    }

    function getPaletteByRoll(uint256 roll, string memory element) public pure returns (string memory) {
        string memory palette;
        if (compareStrings(element, ELEM_NATURE)) {
            palette = getNaturePaletteByRoll(roll);
        } else if (compareStrings(element, ELEM_LIGHT)) {
            palette = getLightPaletteByRoll(roll);
        } else if (compareStrings(element, ELEM_WATER)) {
            palette = getWaterPaletteByRoll(roll);
        } else if (compareStrings(element, ELEM_EARTH)) {
            palette = getEarthPaletteByRoll(roll);
        } else if (compareStrings(element, ELEM_WIND)) {
            palette = getWindPaletteByRoll(roll);
        } else if (compareStrings(element, ELEM_ARCANE)) {
            palette = getArcanePaletteByRoll(roll);
        } else if (compareStrings(element, ELEM_SHADOW)) {
            palette = getShadowPaletteByRoll(roll);
        } else {
            palette = getFirePaletteByRoll(roll);
        }
        return palette;
    }

    function getNaturePaletteByRoll(uint256 roll) public pure returns (string memory) {
        string memory palette;
        if (roll <= uint256(200)) {
            palette = NAT_PAL_JUNGLE;
        } else if (roll <= uint256(380)) {
            palette = NAT_PAL_SPRING;
        } else if (roll <= uint256(540)) {
            palette = NAT_PAL_CAMOUFLAGE;
        } else if (roll <= uint256(680)) {
            palette = NAT_PAL_BLOSSOM;
        } else if (roll <= uint256(800)) {
            palette = NAT_PAL_LEAF;
        } else if (roll <= uint256(880)) {
            palette = NAT_PAL_LEMONADE;
        } else if (roll <= uint256(960)) {
            palette = NAT_PAL_BIOLUMINESCENCE;
        } else {
            palette = NAT_PAL_RAINFOREST;
        }
        return palette;
    }

    function getLightPaletteByRoll(uint256 roll) public pure returns (string memory) {
        string memory palette;
        if (roll <= uint256(200)) {
            palette = LIG_PAL_PASTEL;
        } else if (roll <= uint256(380)) {
            palette = LIG_PAL_HOLY;
        } else if (roll <= uint256(540)) {
            palette = LIG_PAL_SYLVAN;
        } else if (roll <= uint256(680)) {
            palette = LIG_PAL_GLOW;
        } else if (roll <= uint256(800)) {
            palette = LIG_PAL_SUNSET;
        } else if (roll <= uint256(880)) {
            palette = LIG_PAL_INFRARED;
        } else if (roll <= uint256(960)) {
            palette = LIG_PAL_ULTRAVIOLET;
        } else {
            palette = LIG_PAL_YANG;
        }
        return palette;
    }

    function getWaterPaletteByRoll(uint256 roll) public pure returns (string memory) {
        string memory palette;
        if (roll <= uint256(200)) {
            palette = WAT_PAL_ARCHIPELAGO;
        } else if (roll <= uint256(380)) {
            palette = WAT_PAL_FROZEN;
        } else if (roll <= uint256(540)) {
            palette = WAT_PAL_VAPOR;
        } else if (roll <= uint256(680)) {
            palette = WAT_PAL_DAWN;
        } else if (roll <= uint256(790)) {
            palette = WAT_PAL_GLACIER;
        } else if (roll <= uint256(880)) {
            palette = WAT_PAL_SHANTY;
        } else if (roll <= uint256(950)) {
            palette = WAT_PAL_VICE;
        } else {
            palette = WAT_PAL_OPALESCENT;
        }
        return palette;
    }

    function getEarthPaletteByRoll(uint256 roll) public pure returns (string memory) {
        string memory palette;
        if (roll <= uint256(200)) {
            palette = EAR_PAL_ARID;
        } else if (roll <= uint256(380)) {
            palette = EAR_PAL_RIDGE;
        } else if (roll <= uint256(540)) {
            palette = EAR_PAL_COAL;
        } else if (roll <= uint256(680)) {
            palette = EAR_PAL_TOUCH;
        } else if (roll <= uint256(790)) {
            palette = EAR_PAL_BRONZE;
        } else if (roll <= uint256(880)) {
            palette = EAR_PAL_SILVER;
        } else if (roll <= uint256(950)) {
            palette = EAR_PAL_GOLD;
        } else {
            palette = EAR_PAL_PLATINUM;
        }
        return palette;
    }

    function getWindPaletteByRoll(uint256 roll) public pure returns (string memory) {
        string memory palette;
        if (roll <= uint256(200)) {
            palette = WIN_PAL_BERRY;
        } else if (roll <= uint256(380)) {
            palette = WIN_PAL_BREEZE;
        } else if (roll <= uint256(540)) {
            palette = WIN_PAL_JOLT;
        } else if (roll <= uint256(680)) {
            palette = WIN_PAL_THUNDER;
        } else if (roll <= uint256(800)) {
            palette = WIN_PAL_WINTER;
        } else if (roll <= uint256(880)) {
            palette = WIN_PAL_HEATHERMOOR;
        } else if (roll <= uint256(960)) {
            palette = WIN_PAL_ZEUS;
        } else {
            palette = WIN_PAL_MATRIX;
        }
        return palette;
    }

    function getArcanePaletteByRoll(uint256 roll) public pure returns (string memory) {
        string memory palette;
        if (roll <= uint256(200)) {
            palette = ARC_PAL_PLASTIC;
        } else if (roll <= uint256(380)) {
            palette = ARC_PAL_COSMIC;
        } else if (roll <= uint256(540)) {
            palette = ARC_PAL_BUBBLE;
        } else if (roll <= uint256(680)) {
            palette = ARC_PAL_ESPER;
        } else if (roll <= uint256(800)) {
            palette = ARC_PAL_SPIRIT;
        } else if (roll <= uint256(880)) {
            palette = ARC_PAL_COLORLESS;
        } else if (roll <= uint256(960)) {
            palette = ARC_PAL_ENTROPY;
        } else {
            palette = ARC_PAL_YINYANG;
        }
        return palette;
    }

    function getShadowPaletteByRoll(uint256 roll) public pure returns (string memory) {
        string memory palette;
        if (roll <= uint256(200)) {
            palette = SHA_PAL_MOONRISE;
        } else if (roll <= uint256(380)) {
            palette = SHA_PAL_UMBRAL;
        } else if (roll <= uint256(540)) {
            palette = SHA_PAL_DARKNESS;
        } else if (roll <= uint256(680)) {
            palette = SHA_PAL_SHARKSKIN;
        } else if (roll <= uint256(800)) {
            palette = SHA_PAL_VOID;
        } else if (roll <= uint256(880)) {
            palette = SHA_PAL_IMMORTAL;
        } else if (roll <= uint256(960)) {
            palette = SHA_PAL_UNDEAD;
        } else {
            palette = SHA_PAL_YIN;
        }
        return palette;
    }

    function getFirePaletteByRoll(uint256 roll) public pure returns (string memory) {
        string memory palette;
        if (roll <= uint256(200)) {
            palette = FIR_PAL_VOLCANO;
        } else if (roll <= uint256(380)) {
            palette = FIR_PAL_HEAT;
        } else if (roll <= uint256(540)) {
            palette = FIR_PAL_FLARE;
        } else if (roll <= uint256(680)) {
            palette = FIR_PAL_SOLAR;
        } else if (roll <= uint256(790)) {
            palette = FIR_PAL_SUMMER;
        } else if (roll <= uint256(880)) {
            palette = FIR_PAL_EMBER;
        } else if (roll <= uint256(950)) {
            palette = FIR_PAL_COMET;
        } else {
            palette = FIR_PAL_CORRUPTED;
        }
        return palette;
    }

    function getColorCount(uint256 roll, string memory style) public pure returns (uint256) {
        uint256 colorCount = 2;
        uint256[] memory options = new uint256[](5);

        if (compareStrings(style, STYLE_SMOOTH)) {
            options[0] = 2;
            options[1] = 3;
            options[2] = 4;
            options[3] = 5;
            options[4] = 6;
        } else if (compareStrings(style, STYLE_PAJAMAS) || compareStrings(style, STYLE_SILK)) {
            options[0] = 5;
            options[1] = 6;
        } else if (compareStrings(style, STYLE_RETRO)) {
            options[0] = 4;
            options[1] = 6;
        } else {
            options[0] = 3;
            options[1] = 4;
        }

        if (!compareStrings(style, STYLE_SMOOTH)) {
            if (roll <= uint256(800)) {
                colorCount = options[0];
            } else {
                colorCount = options[1];
            }
        } else {
            if (roll <= uint256(400)) {
                colorCount = options[0];
            } else if (roll <= uint256(700)) {
                colorCount = options[1];
            } else if (roll <= uint256(880)) {
                colorCount = options[2];
            } else if (roll <= uint256(960)) {
                colorCount = options[3];
            } else {
                colorCount = options[4];
            }
        }

        return colorCount;
    }

    function getStyleByRoll(uint256 roll) public pure returns (string memory) {
        string memory style;
        if (roll <= uint256(800)) {
            style = STYLE_SMOOTH;
        } else if (roll <= uint256(880)) {
            style = STYLE_PAJAMAS;
        } else if (roll <= uint256(940)) {
            style = STYLE_SILK;
        } else if (roll <= uint256(980)) {
            style = STYLE_RETRO;
        } else {
            style = STYLE_SKETCH;
        }
        return style;
    }

    function getGravityByRoll(uint256 roll) public pure returns (string memory) {
        string memory gravity;
        if (roll <= uint256(50)) {
            gravity = GRAV_LUNAR;
        } else if (roll <= uint256(150)) {
            gravity = GRAV_ATMOSPHERIC;
        } else if (roll <= uint256(340)) {
            gravity = GRAV_LOW;
        } else if (roll <= uint256(730)) {
            gravity = GRAV_NORMAL;
        } else if (roll <= uint256(920)) {
            gravity = GRAV_HIGH;
        } else if (roll <= uint256(970)) {
            gravity = GRAV_MASSIVE;
        } else if (roll <= uint256(995)) {
            gravity = GRAV_STELLAR;
        } else {
            gravity = GRAV_GALACTIC;
        }
        return gravity;
    }

    function getGravityLimitedByRoll(uint256 roll) public pure returns (string memory) {
        string memory gravity;
        if (roll <= uint256(250)) {
            gravity = GRAV_LOW;
        } else if (roll <= uint256(750)) {
            gravity = GRAV_NORMAL;
        } else {
            gravity = GRAV_HIGH;
        }
        return gravity;
    }

    function getGrainByRoll(uint256 roll) public pure returns (string memory) {
        string memory grain;
        if (roll <= uint256(1)) {
            grain = GRAIN_NULL;
        } else if (roll <= uint256(5)) {
            grain = GRAIN_FADED;
        } else if (roll <= uint256(260)) {
            grain = GRAIN_NONE;
        } else if (roll <= uint256(580)) {
            grain = GRAIN_SOFT;
        } else if (roll <= uint256(760)) {
            grain = GRAIN_MEDIUM;
        } else if (roll <= uint256(820)) {
            grain = GRAIN_ROUGH;
        } else if (roll <= uint256(880)) {
            grain = GRAIN_RED;
        } else if (roll <= uint256(940)) {
            grain = GRAIN_GREEN;
        } else {
            grain = GRAIN_BLUE;
        }
        return grain;
    }

    function getDisplayByRoll(uint256 roll) public pure returns (string memory) {
        string memory display;
        if (roll <= uint256(250)) {
            display = DISPLAY_NORMAL;
        } else if (roll <= uint256(500)) {
            display = DISPLAY_MIRRORED;
        } else if (roll <= uint256(750)) {
            display = DISPLAY_UPSIDEDOWN;
        } else {
            display = DISPLAY_MIRROREDUPSIDEDOWN;
        }
        return display;
    }

    function getColorCode(uint256 color) public pure returns (string memory) {
        bytes16 hexChars = "0123456789abcdef";
        uint256 r1 = (color >> uint256(20)) & uint256(15);
        uint256 r2 = (color >> uint256(16)) & uint256(15);
        uint256 g1 = (color >> uint256(12)) & uint256(15);
        uint256 g2 = (color >> uint256(8)) & uint256(15);
        uint256 b1 = (color >> uint256(4)) & uint256(15);
        uint256 b2 = color & uint256(15);
        bytes memory code = new bytes(6);
        code[0] = hexChars[r1];
        code[1] = hexChars[r2];
        code[2] = hexChars[g1];
        code[3] = hexChars[g2];
        code[4] = hexChars[b1];
        code[5] = hexChars[b2];
        return string(code);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function getScript() public pure returns (string memory) {
        return SCRIPT;
    }

}