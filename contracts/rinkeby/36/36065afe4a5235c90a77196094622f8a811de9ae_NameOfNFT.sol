/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// File: contracts/utils/Strings.sol



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
// File: contracts/utils/Address.sol



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
// File: contracts/token/ERC721/IERC721Receiver.sol



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
// File: contracts/utils/introspection/IERC165.sol



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
// File: contracts/utils/introspection/ERC165.sol



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
// File: contracts/token/ERC721/IERC721.sol



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
// File: contracts/token/ERC721/extensions/IERC721Enumerable.sol



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
// File: contracts/token/ERC721/extensions/IERC721Metadata.sol



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
// File: contracts/security/ReentrancyGuard.sol



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
// File: contracts/utils/Context.sol



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
// File: ERC721L.sol



pragma solidity ^0.8.0;









/**
 * @dev modified version of Azuki's ERC721A (https://www.azuki.com/erc721a) by Lagune DAO
 *
 * Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Heavily optimized for the lowest gas possible while providing a full feature set.
 *
 * Lagune Improvements: 
 * improves gas efficiency by removing unnecessary structs used for auction functionality (not needed for this version)
 * introduces a multiTransfer function that allows the transfer of multiple tokens from the sender to a target address in a single transaction (requires manual call or front-end customization) 
 * optimized _safeMint functionality, calling the ERC721Receiver implementer check only a single time rather than for each token.
 * removed unused _numberMinted and startTimestamp functionality for some extra gas saving since we aren't using it.
 * added contract supply limit check to _beforeTokenTransfers such that the inheriting contract does not need to perform this check (code simplification)
 * modified the ordering of multiple requires() in the contract for gas savings on failed transactions (generally external contract calls to here).
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped.
 *
 * Does not support burning tokens to address(0).
 * 
 */
contract ERC721L is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using Address for address;
    using Strings for uint256;

    uint256 private supplyCounter = 0;

    uint256 internal immutable collectionSize;
    uint256 internal immutable maxMintQuantity;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => address) private _ownerships;

    // Mapping owner address to address data
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev
     * `maxMintQuantity` refers to how much a minter can mint at a time.
     * `collectionSize_` refers to how many tokens are in the collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxMintQuantity_,
        uint256 collectionSize_
    ) {
        require(
            collectionSize_ > 0,
            "ERC721L: collection must have a nonzero supply"
        );
        require(
            maxMintQuantity_ > 0,
            "ERC721L: max batch size must be nonzero"
        );
        _name = name_;
        _symbol = symbol_;
        maxMintQuantity = maxMintQuantity_;
        collectionSize = collectionSize_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return supplyCounter;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < totalSupply(), "ERC721L: global index out of bounds");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < balanceOf(owner), "ERC721L: owner index out of bounds");
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < totalSupply(); i++) {
            address ownership = _ownerships[i];
            if (ownership != address(0)) {
                currOwnershipAddr = ownership;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("ERC721L: unable to get token of owner by index");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721L: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownershipOf(uint256 tokenId) internal view returns (address) {
        require(_exists(tokenId), "ERC721L: owner query for nonexistent token");

        uint256 lowestTokenToCheck;
        if (tokenId >= maxMintQuantity) {
            lowestTokenToCheck = tokenId - maxMintQuantity + 1;
        }

        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
            address ownership = _ownerships[curr];
            if (ownership != address(0)) {
                return ownership;
            }
        }

        revert("ERC721L: unable to determine the owner of token");
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId);
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

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
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
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721L.ownerOf(tokenId);
        require(to != owner, "ERC721L: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721L: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721L: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        require(operator != _msgSender(), "ERC721L: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
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
    ) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721L: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < supplyCounter;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - there must be `quantity` tokens remaining unminted in the total collection.
     * - `to` cannot be the zero address.
     * - `quantity` cannot be larger than the max batch size.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        require(to != address(0), "ERC721L: mint to the zero address");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        uint256 mintIndex = supplyCounter;
        require(!_exists(mintIndex), "ERC721L: token already minted");
        require(
            quantity <= maxMintQuantity,
            "ERC721L: quantity to mint too high"
        );

        _beforeTokenTransfers(mintIndex, quantity);

        _balances[to] = _balances[to] + quantity;
        _ownerships[mintIndex] = to;

        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, mintIndex);
            mintIndex++;
        }

        require( // Moved ERC721Receiver implementer check out of the for loop above. We should only need to validate that a reciever contract implements this once, since the to address never changes.
            _checkOnERC721Received(address(0), to, mintIndex, _data),
            "ERC721L: transfer to non ERC721Receiver implementer"
        );

        supplyCounter = mintIndex;
        _afterTokenTransfers(address(0), to, mintIndex, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        address prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership, _msgSender()));

        require(
            isApprovedOrOwner,
            "ERC721L: transfer caller is not owner nor approved"
        );

        require(
            prevOwnership == from,
            "ERC721L: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721L: transfer to the zero address");

        _beforeTokenTransfers(tokenId, 0);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership);

        _balances[from] -= 1;
        _balances[to] += 1;
        _ownerships[tokenId] = to;

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId] == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = prevOwnership;
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev multi transfer function to allow the transfer of any number of tokens in a single transaction for extra gas savings.
     *
     * - Requires custom front-end support unless called directly.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - every token id in `tokenIds[]` must be owned by `from`.
     *
     * Emits {Transfer} events for each token transferred.
     */
    function multiTransfer(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public {
        require(to != address(0), "ERC721L: transfer to the zero address");
        
        _balances[from] -= tokenIds.length;
        _balances[to] += tokenIds.length;

        for (uint8 i = 0; i < tokenIds.length; i++) {
            require(
                _exists(tokenIds[i]),
                "ERC721L: approved query for nonexistent token"
            );

            address prevOwnerOf = ownershipOf(tokenIds[i]);

            require(
                _tokenApprovals[tokenIds[i]] == _msgSender() ||
                    ownershipOf(tokenIds[i]) == _msgSender() ||
                    isApprovedForAll(prevOwnerOf, _msgSender()),
                "ERC721L: transfer caller is not owner nor approved"
            );

            require(
                prevOwnerOf == from,
                "ERC721L: transfer from incorrect owner"
            );

            _beforeTokenTransfers(tokenIds[i], 0);

            // Clear approvals from the previous owner
            _approve(address(0), tokenIds[i], prevOwnerOf);

            _ownerships[tokenIds[i]] = to;

            if (_ownerships[tokenIds[i] + 1] == address(0)) {
                if (_exists(tokenIds[i] + 1)) {
                    _ownerships[tokenIds[i] + 1] = prevOwnerOf;
                }
            }

            emit Transfer(from, to, tokenIds[i]);
            _afterTokenTransfers(from, to, tokenIds[i], 1);
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    uint256 public nextOwnerToExplicitlySet = 0;

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     */
    function _setOwnersExplicit(uint256 quantity) internal {
        uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
        require(quantity > 0, "quantity must be nonzero");
        uint256 endIndex = oldNextOwnerToSet + quantity - 1;
        if (endIndex > collectionSize - 1) {
            endIndex = collectionSize + 1;
        }
        // We know if the last one in the group exists, all in the group exist, due to serial ordering.
        require(_exists(endIndex), "not enough minted yet for this cleanup");
        for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
            if (_ownerships[i] == address(0)) {
                _ownerships[i] = ownershipOf(i);
            }
        }
        nextOwnerToExplicitlySet = endIndex + 1;
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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721L: transfer to non ERC721Receiver implementer"
                    );
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * updated in ERC721L to function as the control to stop any transfer of a token ID higher than the collection limit.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(uint256 startTokenId, uint256 quantity)
        internal
        virtual
    {
        require(
            startTokenId + quantity < collectionSize,
            "ERC721L: transfer called outside of token limit."
        );
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// File: contracts/access/Ownable.sol



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
// File: Lagune_ERC721L.sol



pragma solidity ^0.8.0;





// OpenSea Proxy implementation to support gasless approvals.
contract OwnableDelegateProxy {

}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

pragma solidity ^0.8.0;

/// @title NAME OF NFT
/// @author Araveras.eth
contract NameOfNFT is Ownable, ERC721L, ReentrancyGuard {
    using Address for address;

    string private baseURI; //token URI. Initialized with a placeholder containing the full URL. can be updated with setURI()
    address private vault; //Address used to send the remainder of the contract balance using withdraw(). Set with _initVaultAddress in the constructor arguments.
    address public immutable openSeaProxy; // Stores the proxy registry address for openSea to allow for gasless listing approval.
    mapping(address => bool) approverProxies; // Mapping to store allowed external approve() proxies, making the contract extensible and able to approve() token transfers gaslessly when made by proxies.
    mapping(address => uint256) public presaleWhitelist; // Stores the whitelist addresses. Set with setWhiteList()

    /** Mapping for all uint storage
     *   packedConfig[0] = Reserve a number of tokens from public minting functions by setting this with _initReserve in the constructor arguments. Optional.
     *   packedConfig[1] = set this to 1 to disable the OpenSea approver proxy. Can be used in any case where the Opensea proxy is deemed insecure or unwanted
     *   packedConfig[2] = The minting price for the token. Set with _initPrice in the constructor arguments.
     *   packedConfig[3] = Number of free mints allowed. Set with _initFreeMints in the constructor arguments. Optional.
     *   packedConfig[4] = Set to 1 with setMint() to enable the use of AirDrop() and whitelistMint(). Set to 2 to disable whitelistMint() and enable Mint()
     *   packedConfig[5] = Flag this to 1 with setURI() to start returning the real baseURI + tokenId instead of placeholderURI
     */
    mapping(uint256 => uint256) public packedConfig;

    /**
     * @dev Emitted when a minting transaction is submitted with a payment amount greater than the minting price. Ensures that the refund shows up on trackers.
     */
    event Refund(address indexed recipient, uint256 indexed refundAmount);

    constructor(
        string memory _name, //Name of the Contract (as you want it to show on OpenSea)
        string memory _symbol, //Symbol for the NFT. This will be shown on etherscan and in some responses to function calls.
        uint256 maxMintQuantity_, // Max number that can be minted in one transaction
        uint256 collectionSize, // Total size of the collection
        string memory _initBaseURI,
        address _initVaultAddress,
        address _openSeaProxyAddress,
        uint256 _initPrice,
        uint256 _initReserve,
        uint256 _initFreeMints
    ) ERC721L(_name, _symbol, maxMintQuantity_, collectionSize + 1) {
        baseURI = _initBaseURI;
        vault = _initVaultAddress;
        openSeaProxy = _openSeaProxyAddress;
        packedConfig[0] = _initReserve == 0 ? 0 : _initReserve - 1; // Places _initReserve minus 1 into the reserve counter. This is done as a gas saving measure so that all calculations of maxSupply - reserve (collectionSize.sub(packedConfig[0])) can be done with a single < comparitor, rather than <=
        packedConfig[2] = _initPrice;
        packedConfig[3] = _initFreeMints; // Places the number of reserve tokens into the free minting value. Add a uint256 value to the constructor arguments and replace _initReserve to set a different value.
    }

    // Anti-contract function modifier. Prevents contracts from calling the function.
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "contracts are not allowed");
        _;
    }

    /**
     * @dev onlyOwner function to set the vault address
     * @param _VaultAddress address  to recieve remaining funds from withdraw()
     */
    function setVault(address _VaultAddress) external onlyOwner {
        vault = _VaultAddress;
    }

    /**
     * @dev onlyOwner function to set the tokenURI toggle packedConfig[5] true and false.
     * NOTE: This function is used to both flag the reveal state and to set the baseURI. set toggleReveal to false to only set baseURI submit the existing baseURI as _URI to use it as a toggle switch for packedConfig[5]
     * @param _URI string URI ending in a /. This address must serve the metadata json with no extension, such as https://domain.com/token/1
     */
    function setURI(string memory _URI) external onlyOwner {
        require( //check if new _URI is the same as the current. Don't update if it is.
            bytes(baseURI).length != bytes(_URI).length ||
                keccak256(abi.encode(baseURI)) != keccak256(abi.encode(_URI)),
            "submitted baseURI is the same as the current baseURI"
        );
        baseURI = _URI;
    }

    /**
     * @dev function to change the config of the contract. used for all non-immutable configuration.
     *
     * @param newConfig uint256 array containing the new config that should be written into packedConfig[].
     * NOTE: setting any value in newConfig to 0 will prevent this function from updating that config entry. you must use the below indexes in the array and all must have a value:
     *
     *   [
     *   0, //Reserve a number of tokens from public minting functions by setting this with _initReserve in the constructor arguments. Optional.
     *   1, //Set this to 1 to disable the OpenSea approver proxy. Can be used in any case where the Opensea proxy is deemed insecure or unwanted
     *   2, //The minting price for the token. Set with _initPrice in the constructor arguments. Submitting 0 to this value will not change the price. For free minting set index 3 to the max supply.
     *   3, //Number of free mints allowed. Set with _initFreeMints in the constructor arguments. Optional. Set this to the total size of the collection to make minting free.
     *   4, //Set to 1 to enable the use of AirDrop() and whitelistMint(). Set to 2 to disable whitelistMint() and enable Mint()
     *   5 //Set this to 1 to start returning baseURI + tokenId instead of just baseURI (metadata reveal switch)
     *   ]
     */
    function setConfig(uint256[] memory newConfig)
        external
        onlyOwner
    {
        for (uint8 i = 0; i < newConfig.length; i++) {
            if (newConfig[i] > 0) {
                packedConfig[i] = newConfig[i];
            }
        }
    }

    /**
     * @dev add an approve() proxy address or remove a current proxy address from the list
     *
     * @param _proxyAddress address of the proxy contract to toggle.
     */
    function setProxyState(address _proxyAddress) external onlyOwner {
        approverProxies[_proxyAddress] = !approverProxies[_proxyAddress];
    }

    /**
     * @dev Set the presaleWhitelist mappings. This function replaces the existing mappings with the given input.
     * @param whitelist address[] array containing all whitelist addresses. (entered as ["0x0000","0x0000","0x0000"])
     * @param quantity number of tokens to grant each person on the whitelist
     */
    function setWhiteList(address[] memory whitelist, uint256[] memory quantity)
        external
        onlyOwner
    {
        require(
            whitelist.length == quantity.length,
            "presaleAddresses do not match quantity length"
        );
        for (uint256 i = 0; i < whitelist.length; i++) {
            presaleWhitelist[whitelist[i]] = quantity[i];
        }
    }

    /**
     * @dev function to air drop tokens to a given list of addresses.
     * Takes in an array of addresses, as well as an array containing the number of tokens that each address should recieve.
     * A check is done to see if packedConfig[0] (reserve count) is greater than 0, and subtracts the total number of tokens airdropped from this number.
     * This ensures that public minting will be able to mint until the max count as airdropped tokens are removed from the reserve count, but airdropping is still allowed until the token maximum supply (ie, there is no airdropping limit).
     *
     * @param recipients  address[] array containing all airDrop recipient addresses.
     * @param quantity number of tokens to airdrop to each recipient
     */
    function AirDrop(address[] memory recipients, uint256[] memory quantity)
        external
        onlyOwner
    {
        require(packedConfig[4] > 0, "minting must be active.");

        uint256 totalAirDrops = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalAirDrops += quantity[i];
            _safeMint(recipients[i], quantity[i]);
        }
        if (packedConfig[0] >= totalAirDrops) {
            /* subtracts from the reserve the amount airdropped. However, does not require a reserve remaining to allow the team to airdrop further if needed from the public minting pool
            (assuming it is not sold out). */
            packedConfig[0] -= totalAirDrops;
        } else {
            packedConfig[0] = 0;
        }
    }

    /**
     * @dev Whitelist minting function
     * Verifies that msg.sender is mapped in presaleWhitelist
     * Will always fail if packedConfig[4] has not been set to 1
     * Prevents minting up to collectionSize (Max Count), minus the remaining packedConfig[0] (Reserved Count) value
     * Each token minted reduces the addresses remaining whitelist balance, until 0.
     *
     * @param _NumberOfMints number of NFTs to mint.
     */
    function whitelistMint(uint256 _NumberOfMints)
        external
        payable
        callerIsUser
    {
        require(packedConfig[4] == 1, "Presale must be active");
        require(
            totalSupply() + _NumberOfMints <
                collectionSize - packedConfig[0] - 1,
            "There are no more tokens"
        );
        require(
            _NumberOfMints <= presaleWhitelist[msg.sender],
            "Not enough tokens reserved for this address"
        );

        presaleWhitelist[msg.sender] =
            presaleWhitelist[msg.sender] -
            _NumberOfMints; // update presaleWhitelist prior to minting to mitigate reentrancy further

        _safeMint(msg.sender, _NumberOfMints);
        payMint(packedConfig[2] * _NumberOfMints);
    }

    /**
     * @dev Public minting function
     * Only allows for 5 mints per transaction, but multiple mints are supported.
     * Will always fail if packedConfig[4] has not been toggled to true
     * Prevents minting up to the collectionSize (Max Count) of the contract, minus the remaining packedConfig[0] (Reserved Count) value
     * The function allows for the first mints done to be free + gas. The totalSupply() of the contract is used: once this is over the value of packedConfig[3], free minting will be disabled and a value equal to (packedConfig[2] * _numberOfMints) must be provided.
     *
     * @param _NumberOfMints number of NFTs to mint.
     */
    function Mint(uint256 _NumberOfMints) external payable callerIsUser {
        require(packedConfig[4] == 2, "Public sale must be active");
        require(
            totalSupply() + _NumberOfMints <
                collectionSize - packedConfig[0] - 1,
            "There are no more tokens"
        );
        _safeMint(msg.sender, _NumberOfMints);
        payMint(packedConfig[2] * _NumberOfMints);
    }

    /**
     * @dev refunds eth sent over the total price for transactions sent with the incorrect amount. 
     * bypasses payment check and allows minting with any transaction value (generally 0 unless you want to be nice) if totalSupply() is less than packedConfig[3] (free mints)
     */
    function payMint(uint256 price) private {
        require(
            msg.value >= price || totalSupply() <= packedConfig[3],
            "Eth sent value incorrect. Free mints are limited"
        );
        if (msg.value > price) {
            emit Refund(_msgSender(), msg.value - price);
            payable(msg.sender).transfer(msg.value - price); //refund any eth sent over the minting price. (could cause extra gas usage! check your math before submitting transactions!)
            // yes - we really put this in here. we aren't rug artists. if you miss a decimal it's ok.
        }
    }

    /**
     * @dev Public TokenURI function
     * Serves the raw value of baseURI for all minted tokens if revealed has not been toggled to true, after which it will append the token id to the end of the URI
     * Will not return data for any tokenId that has not been minted.
     *
     * @param _TokenId the token number to return the current metadata URI for.
     */
    function tokenURI(uint256 _TokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_TokenId), "Token ID does not exist.");
        if (packedConfig[5] != 1) {
            return baseURI;
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(_TokenId)))
                : "";
    }

    /**
     * @dev Opensea compatible isApprovedForAll function
     * Checks if one of the OpenSea proxies is the operator in the request, and if yes returns true to allow their proxies without a separate approval transaction.
     * This entirely removes the need for any gassed transactions when performing listing on opensea for the first time with this collection.
     * the immutable OpenSea proxy address can be removed from the approvers by setting packedConfig[1] to 1 with setConfig()
     *
     * @param _owner the owner of the token to check for approval
     * @param operator the address that is being checked for approval
     */
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(openSeaProxy);
        if (approverProxies[operator]) {
            return true;
        }
        if (
            (address(proxyRegistry.proxies(_owner)) == operator) &&
            packedConfig[1] != 1
        ) {
            return true;
        }
        return super.isApprovedForAll(_owner, operator);
    }

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     */
    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    /**
     * @dev uses ERC721A replacement ownership query directly
     */
    function getOwnerOf(uint256 tokenId) external view returns (address) {
        return ownershipOf(tokenId);
    }

    /**
     * @dev function to withdraw the balance held in the contract.
     * This function will give each address in team $ETH equal to the packedConfig[1] percent of the balance
     * The remainder of the balance will go to the address in vault
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance empty");
        (bool success, ) = vault.call{value: balance}("");
        require(success, "Transfer failed.");
    }
}