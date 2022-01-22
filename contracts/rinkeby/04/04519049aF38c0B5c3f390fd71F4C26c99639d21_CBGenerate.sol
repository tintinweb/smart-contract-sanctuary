/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/interfaces/ICBGenerate.sol




pragma solidity ^0.8.0;


interface ICBGenerate {
    event PartsLocked();

    function arePartsLocked() external returns (bool);

    function backgrounds(uint256 index) external view returns (string memory);

    function faces(uint256 index) external view returns (string memory);

    function eyes(uint256 index) external view returns (string memory);

    function mouths(uint256 index) external view returns (string memory);

    function nose(uint256 index) external view returns (string memory);

    function noserings(uint256 index) external view returns (string memory);
    
    function beautymarks(uint256 index) external view returns (string memory);

    function hair(uint256 index) external view returns (string memory);

    function eyewear(uint256 index) external view returns (string memory);

    function earrings(uint256 index) external view returns (string memory);

    function necklaces(uint256 index) external view returns (string memory);

    function headwears(uint256 index) external view returns (string memory);

    function accessories(uint256 index) external view returns (string memory);

    function backgroundCount() external view returns (uint256);

    function faceCount() external view returns (uint256);

    function eyeCount() external view returns (uint256);

    function mouthCount() external view returns (uint256);

    function noseCount() external view returns (uint256);

    function noseringCount() external view returns (uint256);

    function beautymarkCount() external view returns (uint256);

    function hairCount() external view returns (uint256);

    function eyewearCount() external view returns (uint256);

    function earringCount() external view returns (uint256);

    function necklaceCount() external view returns (uint256);

    function headwearCount() external view returns (uint256);

    function accessoriesCount() external view returns (uint256);

    function addBackground(string calldata background) external;

    function addFace(string calldata faces) external;

    function addEye(string calldata eyes) external;

    function addMouth(string calldata mouths) external;

    function addNose(string calldata nose) external;

    function addNosering(string calldata noserings) external;

    function addBeautymark(string calldata beautymarks) external;

    function addHair(string calldata hair) external;

    function addEyewear(string calldata eyewear) external;

    function addEarring(string calldata earrings) external;

    function addNecklace(string calldata necklaces) external;

    function addHeadwear(bytes calldata headwears) external;

    function addAccessory(string calldata accessories) external;

    function lockParts() external;



}
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

// File: contracts/CBGenerate.sol





pragma solidity ^0.8.6;





contract CBGenerate is Ownable, ERC721Enumerable {
    using Strings for uint256;

    bool public arePartsLocked;

string[] public backgrounds = ['<path stroke="#03b2bd" d="M0 0h32M0 1h32M0 2h32M0 3h32M0 4h32M0 5h32M0 6h32M0 7h32M0 8h32M0 9h32M0 10h32M0 11h32M0 12h32M0 13h32M0 14h32M0 15h32M0 16h32M0 17h32M0 18h32M0 19h32M0 20h32M0 21h32M0 22h32M0 23h32M0 24h32M0 25h32M0 26h32M0 27h32M0 28h32M0 29h32M0 30h32M0 31h32" />','<path stroke="#464646" d="M0 0h32M0 1h32M0 2h32M0 3h32M0 4h32M0 5h32M0 6h32M0 7h32M0 8h32M0 9h32M0 10h32M0 11h32M0 12h32M0 13h32M0 14h32M0 15h32M0 16h32M0 17h32M0 18h32M0 19h32M0 20h32M0 21h32M0 22h32M0 23h32M0 24h32M0 25h32M0 26h32M0 27h32M0 28h32M0 29h32M0 30h32M0 31h32" />','<path stroke="#03b2bd" d="M0 0h32M0 1h31M0 2h30M0 3h29M0 4h28M0 5h27M0 6h26M0 7h25M0 8h24M0 9h23M0 10h22M0 11h21M0 12h20M0 13h19M0 14h18M0 15h17M0 16h16M0 17h15M0 18h14M0 19h13M0 20h12M0 21h11M0 22h10M0 23h9M0 24h8M0 25h7M0 26h6M0 27h5M0 28h4M0 29h3M0 30h2M0 31h1" /><path stroke="#ddf107" d="M31 1h1M30 2h2M29 3h3M28 4h4M27 5h5M26 6h6M25 7h7M24 8h8M23 9h9M22 10h10M21 11h11M20 12h12M19 13h13M18 14h14M17 15h15M16 16h16M15 17h17M14 18h18M13 19h19M12 20h20M11 21h21M10 22h22M9 23h23M8 24h24M7 25h25M6 26h26M5 27h27M4 28h28M3 29h29M2 30h30M1 31h31" />'];
  string[] public faces = ['<path stroke="#000000" d="M7 0h2M22 0h1M6 1h1M23 1h1M5 2h1M24 2h1M5 3h1M25 3h1M4 4h1M25 4h1M4 5h1M26 5h1M3 6h1M26 6h1M3 7h1M26 7h1M3 8h1M26 8h1M3 9h1M26 9h1M3 10h1M26 10h1M2 11h2M26 11h1M2 12h1M25 12h1M2 13h1M25 13h1M2 14h1M25 14h1M2 15h2M26 15h1M2 16h1M26 16h1M2 17h1M4 17h1M26 17h1M3 18h1M5 18h1M26 18h1M3 19h1M5 19h1M26 19h1M4 20h3M26 20h1M6 21h1M26 21h1M6 22h2M26 22h1M7 23h1M25 23h1M8 24h1M25 24h1M8 25h1M24 25h1M8 26h1M24 26h1M8 27h1M23 27h1M8 28h1M23 28h1M8 29h1M22 29h1M8 30h1M16 30h6M8 31h1M17 31h1" /><path stroke="#ffd1a6" d="M9 0h8M7 1h11M6 2h13M6 3h13M5 4h14M5 5h15M4 6h16M4 7h16M4 8h16M4 9h16M4 10h16M4 11h16M3 12h18M3 13h18M3 14h18M4 15h17M5 16h16M3 17h1M5 17h16M4 18h1M6 18h16M4 19h1M6 19h16M7 20h15M7 21h15M8 22h14M8 23h14M9 24h13M10 25h12M11 26h10M9 27h1M12 27h9M9 28h2M14 28h6M9 29h3M16 29h4M9 30h5M9 31h7" /><path stroke="#cca785" d="M17 0h5M18 1h5M19 2h5M19 3h6M19 4h6M20 5h6M20 6h6M20 7h6M20 8h6M20 9h6M20 10h6M20 11h6M21 12h4M21 13h4M21 14h4M21 15h5M3 16h2M21 16h5M21 17h5M22 18h4M22 19h4M22 20h4M22 21h4M22 22h4M22 23h3M22 24h3M22 25h2M9 26h1M21 26h3M10 27h1M21 27h2M11 28h1M20 28h3M12 29h2M20 29h2M14 30h2M16 31h1" /><path stroke="#0d0b08" d="M9 25h1M10 26h1M11 27h1M12 28h2M14 29h2" />','<path stroke="#000000" d="M7 0h2M22 0h1M6 1h1M23 1h1M5 2h1M24 2h1M5 3h1M25 3h1M4 4h1M25 4h1M4 5h1M26 5h1M3 6h1M26 6h1M3 7h1M26 7h1M3 8h1M26 8h1M3 9h1M26 9h1M3 10h1M26 10h1M2 11h2M26 11h1M2 12h1M25 12h1M2 13h1M25 13h1M2 14h1M25 14h1M2 15h2M26 15h1M2 16h1M26 16h1M2 17h1M4 17h1M26 17h1M3 18h1M5 18h1M26 18h1M3 19h1M5 19h1M26 19h1M4 20h3M26 20h1M6 21h1M26 21h1M6 22h2M26 22h1M7 23h1M25 23h1M8 24h1M25 24h1M8 25h1M24 25h1M8 26h1M24 26h1M8 27h1M23 27h1M8 28h1M23 28h1M8 29h1M22 29h1M8 30h1M16 30h6M8 31h1M17 31h1" /><path stroke="#f5b5b8" d="M9 0h8M7 1h11M6 2h13M6 3h13M5 4h14M5 5h15M4 6h16M4 7h16M4 8h16M4 9h16M4 10h16M4 11h16M3 12h18M3 13h18M3 14h18M4 15h17M5 16h16M3 17h1M5 17h16M4 18h1M6 18h16M4 19h1M6 19h16M7 20h15M7 21h15M8 22h14M8 23h14M9 24h13M10 25h12M11 26h10M9 27h1M12 27h9M9 28h2M14 28h6M9 29h3M16 29h4M9 30h5M9 31h7" /><path stroke="#c49193" d="M17 0h5M18 1h5M19 2h5M19 3h6M19 4h6M20 5h6M20 6h6M20 7h6M20 8h6M20 9h6M20 10h6M20 11h6M21 12h4M21 13h4M21 14h4M21 15h5M3 16h2M21 16h5M21 17h5M22 18h4M22 19h4M22 20h4M22 21h4M22 22h4M22 23h3M22 24h3M22 25h2M9 26h1M21 26h3M10 27h1M21 27h2M11 28h1M20 28h3M12 29h2M20 29h2M14 30h2M16 31h1" /><path stroke="#0c0909" d="M9 25h1M10 26h1M11 27h1M12 28h2M14 29h2" />','<path stroke="#000000" d="M7 0h2M22 0h1M6 1h1M23 1h1M5 2h1M24 2h1M5 3h1M25 3h1M4 4h1M25 4h1M4 5h1M26 5h1M3 6h1M26 6h1M3 7h1M26 7h1M3 8h1M26 8h1M3 9h1M26 9h1M3 10h1M26 10h1M2 11h2M26 11h1M2 12h1M25 12h1M2 13h1M25 13h1M2 14h1M25 14h1M2 15h2M26 15h1M2 16h1M26 16h1M2 17h1M4 17h1M26 17h1M3 18h1M5 18h1M26 18h1M3 19h1M5 19h1M26 19h1M4 20h3M26 20h1M6 21h1M26 21h1M6 22h2M26 22h1M7 23h1M25 23h1M8 24h1M25 24h1M8 25h1M24 25h1M8 26h1M24 26h1M8 27h1M23 27h1M8 28h1M23 28h1M8 29h1M22 29h1M8 30h1M16 30h6M8 31h1M17 31h1" /><path stroke="#6a4c2e" d="M9 0h8M7 1h11M6 2h13M6 3h13M5 4h14M5 5h15M4 6h16M4 7h16M4 8h16M4 9h16M4 10h16M4 11h16M3 12h18M3 13h18M3 14h18M4 15h17M5 16h16M3 17h1M5 17h16M4 18h1M6 18h16M4 19h1M6 19h16M7 20h15M7 21h15M8 22h14M8 23h14M9 24h13M10 25h12M11 26h10M9 27h1M12 27h9M9 28h2M14 28h6M9 29h3M16 29h4M9 30h5M9 31h7" /><path stroke="#553d25" d="M17 0h5M18 1h5M19 2h5M19 3h6M19 4h6M20 5h6M20 6h6M20 7h6M20 8h6M20 9h6M20 10h6M20 11h6M21 12h4M21 13h4M21 14h4M21 15h5M3 16h2M21 16h5M21 17h5M22 18h4M22 19h4M22 20h4M22 21h4M22 22h4M22 23h3M22 24h3M22 25h2M9 26h1M21 26h3M10 27h1M21 27h2M11 28h1M20 28h3M12 29h2M20 29h2M14 30h2M16 31h1" /><path stroke="#050402" d="M9 25h1M10 26h1M11 27h1M12 28h2M14 29h2" />'];
  string[] public eyes = ['<path stroke="#0c0909" d="M12 8h3M24 8h2M11 9h1M15 9h2M22 9h2M26 9h1M17 10h2M21 10h1" /><path stroke="#0a0707" d="M13 12h4M22 12h4M11 13h5M21 13h3M26 13h1M15 14h2M23 14h2" /><path stroke="#03b2bd" d="M16 13h1M24 13h1M14 14h1M22 14h1M14 15h3M22 15h3" /><path stroke="#100000" d="M17 13h1M25 13h1" /><path stroke="#414141" d="M12 14h1" /><path stroke="#ffffff" d="M13 14h1M17 14h1M25 14h1" /><path stroke="#cccccc" d="M13 15h1M17 15h1M25 15h1" />','<path stroke="#000000" d="M12 8h4M11 9h1M15 9h2M24 9h2M10 10h1M23 10h1M22 11h1M13 12h3M24 12h2M10 13h7M23 13h3M11 14h2M15 14h3M22 14h2M25 14h1M12 15h1M15 15h2M21 15h2M25 15h1" /><path stroke="rgba(10,25,30,0.2)" d="M23 8h3M22 9h2M22 10h1M24 10h2M12 11h4M23 11h3M12 12h1M16 12h1M23 12h1M17 13h1M22 13h1M14 16h2M24 16h2" /><path stroke="#ffffff" d="M13 14h1M24 14h1M21 16h1" /><path stroke="#ff5249" d="M14 14h1M23 15h1" /><path stroke="rgba(255,255,255,0.2)" d="M13 15h1M24 15h1" /><path stroke="#d2433c" d="M14 15h1" /><path stroke="rgba(8,25,28,0.3607843137254902)" d="M23 16h1" />','<path stroke="rgba(0,0,0,0.9490196078431372)" d="M11 9h3M25 9h1M14 10h2M24 10h2M16 11h2M23 11h1M12 12h3M22 12h1M24 12h2M10 13h6M22 13h4M11 14h2M15 14h2M21 14h2M25 14h1M16 15h1M21 15h2M25 15h1" /><path stroke="#000000" d="M18 10h2M22 10h1M11 12h1M17 15h1M25 16h1" /><path stroke="#d2c43c" d="M13 14h1M23 14h1" /><path stroke="#ffffff" d="M14 14h1M23 15h1" /><path stroke="rgba(204,204,204,0.5882352941176471)" d="M24 14h1M15 15h1" /><path stroke="#ddf107" d="M12 15h1M24 15h1" /><path stroke="rgba(255,255,255,0.5882352941176471)" d="M14 15h1" />'];
    string[] public mouths = ['<g transform="translate(0.000000,32.000000) scale(0.100000,-0.100000)" fill="#000000" stroke="none"><path d="M185 80 c-4 -6 6 -10 22 -10 22 0 25 2 13 10 -19 12 -27 12 -35 0z"/></g>','<g transform="translate(0.000000,32.000000) scale(0.100000,-0.100000)" fill="#000000" stroke="none"><path d="M202 78 c4 -12 22 -12 26 0 1 5 -4 9 -13 9 -9 0 -14 -4 -13 -9z"/></g>','<g transform="translate(0.000000,32.000000) scale(0.100000,-0.100000)" fill="#000000" stroke="none"><path d="M186 81 c-3 -4 6 -6 19 -3 14 2 25 6 25 8 0 8 -39 4 -44 -5z"/></g>'];

    string[] public nose;

    string[] public noserings;

    string[] public beautymarks;

    string[] public hair;

    string[] public eyewear;

    string[] public earrings;

    string[] public necklaces;

    string[] public headwears;

    string[] public accessories;

 

    modifier whenPartsNotLocked() {
        require(!arePartsLocked, 'Parts are locked');
        _;
    }

  constructor() ERC721("Strawberry", "StrawberryGen") {}

    function backgroundCount() external view returns (uint256) {
        return backgrounds.length;
    }

    function faceCount() external view returns (uint256) {
        return faces.length;
    }

    function eyeCount() external view returns (uint256) {
        return eyes.length;
    }

    function mouthCount() external view returns (uint256) {
        return mouths.length;
    }
    function noseCount() external view returns (uint256) {
        return nose.length;
    }

    function noseringCount() external view returns (uint256) {
        return noserings.length;
    }

    function beautymarkCount() external view returns (uint256) {
        return beautymarks.length;
    }

    function hairCount() external view returns (uint256) {
        return hair.length;
    }

    function eyewearCount() external view returns (uint256) {
        return eyewear.length;
    }

    function earringCount() external view returns (uint256) {
        return earrings.length;
    }

    function necklaceCount() external view returns (uint256) {
        return necklaces.length;
    }

    function headwearCount() external view returns (uint256) {
        return headwears.length;
    }

    function accessoriesCount() external view returns (uint256) {
        return accessories.length;
    }

    function addBackground(string calldata _background) external onlyOwner whenPartsNotLocked {
        _addBackground(_background);
    }

    function addFace(string calldata _face) external onlyOwner whenPartsNotLocked {
        _addFace(_face);
    }

    function addEye(string calldata _eye) external onlyOwner whenPartsNotLocked {
        _addEye(_eye);
    }

    function addMouth(string calldata _mouth) external onlyOwner whenPartsNotLocked {
        _addMouth(_mouth);
    }
    function addNose(string calldata _nose) external onlyOwner whenPartsNotLocked {
        _addNose(_nose);
    }

    function addNosering(string calldata _nosering) external onlyOwner whenPartsNotLocked {
        _addNosering(_nosering);
    }

    function addBeautymark(string calldata _beautymark) external onlyOwner whenPartsNotLocked {
        _addBeautymark(_beautymark);
    }

    function addHair(string calldata _hair) external  onlyOwner whenPartsNotLocked {
        _addHair(_hair);
    }

    function addEyewear(string calldata _eyewear) external onlyOwner whenPartsNotLocked {
        _addEyewear(_eyewear);
    }

    function addEarring(string calldata _earring) external onlyOwner whenPartsNotLocked {
        _addEarring(_earring);
    }

    function addNecklace(string calldata _necklace) external onlyOwner whenPartsNotLocked {
        _addNecklace(_necklace);
    }

    function addHeadwear(string calldata _headwear) external onlyOwner whenPartsNotLocked {
        _addHeadwear(_headwear);
    }

    function addAccessory(string calldata _accessory) external onlyOwner whenPartsNotLocked {
        _addAccessory(_accessory);
    }

    function lockParts() external onlyOwner whenPartsNotLocked {
        arePartsLocked = true;
    }

    function _addBackground(string calldata _background) internal {
        backgrounds.push(_background);
    }

    function _addFace(string calldata _face) internal {
        faces.push(_face);
    }

    function _addEye(string calldata _eye) internal {
        eyes.push(_eye);
    }

    function _addMouth(string calldata _mouth) internal {
        mouths.push(_mouth);
    }
    function _addNose(string calldata _nose) internal {
        nose.push(_nose);
    }

    function _addNosering(string calldata _nosering) internal {
        noserings.push(_nosering);
    }

    function _addBeautymark(string calldata _beautymark) internal {
        beautymarks.push(_beautymark);
    }

    function _addHair(string calldata _hair) internal {
        hair.push(_hair);
    }

    function _addEyewear(string calldata _eyewear) internal {
        eyewear.push(_eyewear);
    }

    function _addEarring(string calldata _earring) internal {
        earrings.push(_earring);
    }

    function _addNecklace(string calldata _necklace) internal {
        necklaces.push(_necklace);
    }

    function _addHeadwear(string calldata _headwear) internal {
        headwears.push(_headwear);
    }

    function _addAccessory(string calldata _accessory) internal {
        accessories.push(_accessory);
    }

}