/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

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

// File: contracts/1_Storage.sol

pragma solidity ^0.8.0;






/*
    - add randomization for land tiers on mind (probably just add a random percent chance based on tier? shouldn't be to hard)
*/

interface InterfaceRainbows {
    function transferTokens(address _from, address _to) external;
    function burn(address user, uint256 amount) external;
}

interface InterfaceOriginals {
    function ownerOf(uint256 tokenId) external view returns (address);
    function getNoundlesFromWallet(address _noundles) external view returns (uint256[] memory);
}

/*
    :)
*/
contract EvilNoundles is ERC721, ERC721Enumerable, Ownable {

    // Interfaces to interact with the other contracts
    InterfaceRainbows public Rainbows;
    InterfaceOriginals public Originals;

    uint256 public seed = 0;

    /*
     * Constants
     * MAX_EVIL_NOUNDLES        = Maximum Supply for Evil Noundles that could be minted
     * MAX_COMPANION_NOUNDLES   = Maximum Supply for public mint with eth or rainbows (with 100% chance at companion).
     * MAX_FREE_COMPANION_MINTS = Maximum Supply for every Noundle holder to mint one companion
     * MAX_FREE_LAND_MINTS      = Maximum Supply for every Genesis Noundle Holder to mint some land (you deserve it kings)
     * MAX_RESERVED_EVIL        = Evil Reserved noundles for the team for giveaways, advisors, etc.
     * MAX_RESERVED_LAND        = Land Reserved noundles for the team for giveaways, advisors, etc.
     * MAX_RESERVED_COMP        = Companions Reserved noundles for the team for giveaways, advisors, etc.
     */
    uint256 public constant MAX_EVIL_NOUNDLES        = 40000;
    uint256 public constant MAX_COMPANION_NOUNDLES   = 8888;
    uint256 public constant MAX_FREE_COMPANION_MINTS = 8888;
    uint256 public constant MAX_FREE_LAND_MINTS      = 8888;
    uint256 public constant MAX_RESERVED_EVIL        = 250;
    uint256 public constant MAX_RESERVED_LAND        = 250;
    uint256 public constant MAX_RESERVED_COMP        = 250;

    // Track all the mintable tokens.
    uint256[] public companionList;
    uint256[] public evilList;
    uint256[] public lowLandList;
    uint256[] public midLandList;
    uint256[] public highLandList;

    // Each number is based on a %
    uint256 public percentEvil      = 10;
    uint256 public percentSteal     = 10;
    uint256 public percentJail      = 10;
    uint256 public percentLowLand   = 75;
    uint256 public percentMidLand   = 20;
    uint256 public percentHighLand  = 5;

    // Total minted of each kind.
    uint256 public mintCountCompanions = 0;
    uint256 public mintCountEvil       = 0;
    uint256 public mintCountLandLow    = 0;
    uint256 public mintCountLandMid    = 0;
    uint256 public mintCountLandHigh   = 0;

    // Public minting costs - these will most likely change when contract is deployed, so don't look to deep into them
    uint256 public publicMintCompanionPriceEth     = 0.1 ether;
    uint256 public publicMintCompanionPriceRainbow = 20 ether;
    uint256 public evilMintPriceRainbow            = 20 ether;
    uint256 public landMintPriceRainbow            = 50 ether;

    // Track the free mints for companions and evil noundle mints
    uint256 public freeCompanionMint = 0;
    uint256 public evilNoundleMint   = 0;

    // Tracks the reserved mints to make sure we don't go over it
    uint256 public reservedEvil = 0;
    uint256 public reservedLand = 0;
    uint256 public reservedComp = 0;

    // Track the whitelisted evil noundles
    mapping(address => bool) evilNoundleAllowed;
    mapping(address => bool) evilNoundleMinted;

    // Track the whitelisted land owners
    mapping(address => bool) landAllowed;
    mapping(address => bool) landMinted;

    // Tracks the tokens that were already used to mint companions - prevents people from transfering their token to new wallets and claiming again :)
    mapping(uint256 => bool) alreadyMintedNoundles;

    // Tracks the tokens that were already used to mint land
    mapping(uint256 => bool) alreadyMintedLandNoundles;

    // Minting Settings
    bool    public saleEnabled = false;
    uint256 public saleOneTime = 0;
    uint256 public saleTwoTime = 0; // lands + more :)

    // $RAINBOW Minting costs
    bool    public rainbowMintingEnabled = false;
    uint256 public rBaseMintPriceTier1   = 40.0 ether;
    uint256 public rBaseMintPriceTier2   = 80.0 ether;
    uint256 public rBaseMintPriceTier3   = 120.0 ether;
    uint256 public tier2Start            = 10000;
    uint256 public tier3Start            = 17500;

    // Jail Settings
    uint256 public jailLength    = 10800;
    uint256 public getOutOfJail  = 2.0 ether;
    mapping (uint256 => uint256) public jailHouse;

    // Counters.
    uint256 public counterStolenAttempted = 0;
    uint256 public counterStolen          = 0;
    uint256 public counterBail            = 0;
    uint256 public counterJailed          = 0;

    // Most Wanted
    mapping (address => uint256) public mostWantedValues;
    address [] public mostWantedMembers;

    // Tracks the amount of tokens for Noundle Theory
    mapping (address => uint256) public companionBalance;
    mapping (address => uint256) public evilBalance;

    // different tiers give different protection bonuses when being robbed
    mapping (address => uint256) public lowLandBalance;
    mapping (address => uint256) public midLandBalance;
    mapping (address => uint256) public highLandBalance;

    /*
     * The types of Noundles in the Noundle Theory Game
     * 0 - companions
     * 1 - evil noundles
     * 2 - low tier land (phase 2)
     * 3 - mid tier land (phase 3)
     * 4 - high tier land (phase 4)
     **/
    mapping (uint256 => uint8) public noundleType;
    mapping (uint256 => uint256) public noundleOffsetCount;

    // Rest of the contract settings
    string  private baseURI;
    address public founder1;
    address public founder2;

    // Modifiers
    modifier isSaleEnabled() {
        require(saleEnabled, "Cannot be sold yet.");
        _;
    }

    modifier isPhaseOneStarted() {
        require(block.timestamp >= saleOneTime && saleOneTime > 0, "Phase One hasn't started");
        _;
    }

    modifier isPhaseTwoStarted() {
        require(block.timestamp >= saleTwoTime && saleTwoTime > 0, "Phase Two hasn't started");
        _;
    }

    modifier isRainbowMintingEnabled() {
        require(rainbowMintingEnabled, "Cannot mint with $RAINBOWS yet.");
        _;
    }

    constructor(string memory _uri) ERC721("EVILNOUNDLES", "EVILNOUNDLES") {
        baseURI = _uri;
    }

    // Adds a user to the claimable evil noundle mint
    function addEvilNoundlers(address[] memory _noundles) public onlyOwner {
        for (uint256 __noundles;__noundles < _noundles.length;__noundles++) {
            evilNoundleAllowed[_noundles[__noundles]] = true;
        }
    }

    // Check if a address is on the free mint.
    function checkEvilNoundlers(address _noundles) public view returns (bool) {
        return evilNoundleAllowed[_noundles];
    }

    // generic minting function :)
    function _handleMinting(address _to, uint256 _index, uint8 _type) private {

        // Attempt to mint.
        _safeMint(_to, _index);

        // Set it's type in place.
        noundleType[_index] = _type;

        if (_type == 0) {
            companionBalance[msg.sender]++;
            companionList.push(_index);
            noundleOffsetCount[_index] = mintCountCompanions;
            mintCountCompanions++;
        } else if (_type == 1) {
            evilBalance[msg.sender]++;
            evilList.push(_index);
            noundleOffsetCount[_index] = mintCountEvil;
            mintCountEvil++;
        } else if (_type == 2) {
            lowLandBalance[msg.sender]++;
            lowLandList.push(_index);
            noundleOffsetCount[_index] = mintCountLandLow;
            mintCountLandLow++;
        } else if (_type == 3) {
            midLandBalance[msg.sender]++;
            midLandList.push(_index);
            noundleOffsetCount[_index] = mintCountLandMid;
            mintCountLandMid++;
        } else {
            highLandBalance[msg.sender]++;
            highLandList.push(_index);
            noundleOffsetCount[_index] = mintCountLandHigh;
            mintCountLandHigh++;
        }
    }

    // Reserves some of the supply of the noundles for giveaways & the community
    function reserveNoundles(uint256 _amount, uint8 _type) public onlyOwner {
        // enforce reserve limits based on type claimed
        if (_type == 0) {
            require(reservedComp + _amount <= MAX_RESERVED_COMP, "Cannot reserve more companions!");
        } else if (_type == 1) {
            require(reservedEvil + _amount <= MAX_RESERVED_EVIL, "Cannot reserve more evil noundles!");
        } else {
            require(reservedLand + _amount <= MAX_RESERVED_LAND, "Cannot reserve more land!");
        }

        uint256 _ts = totalSupply();

        // Mint the reserves.
        for (uint256 i; i < _amount; i++) {
            _handleMinting(msg.sender, _ts + i, _type);

            if (_type == 0) {
                reservedComp++;
            } else if (_type == 1) {
                reservedEvil++;
            } else {
                reservedLand++;
            }
        }
    }

    // Mint your evil noundle.
    function claimEvilNoundle() public payable isPhaseOneStarted {
        uint256 __noundles = totalSupply();

        // Verify request.
        require(freeCompanionMint + 1 <= MAX_FREE_COMPANION_MINTS,   "We ran out of evil noundles :(");
        require(evilNoundleAllowed[msg.sender],         "You are not on whitelist");
        require(evilNoundleMinted[msg.sender] == false, "You already minted your free noundle.");

        // Make sure that the wallet is holding at least 1 noundle.
        require(Originals.getNoundlesFromWallet(msg.sender).length > 0, "You must hold at least one Noundle to mint");

        // Burn the rainbows.
        Rainbows.burn(msg.sender, evilMintPriceRainbow);

        // Mark it as they already got theirs.
        evilNoundleMinted[msg.sender] = true;

        // Add to our free mint count.
        freeCompanionMint += 1;

        // Mint it.
        _handleMinting(msg.sender, __noundles, 1);
    }

    // Mint your free companion.
    function mintHolderNoundles(uint256 _noundles) public payable isPhaseOneStarted {
        uint256 __noundles = totalSupply();

        require(_noundles > 0 && _noundles <= 10, "Your amount needs to be greater then 0 and can't exceed 10");
        require(_noundles + __noundles <= MAX_FREE_COMPANION_MINTS, "We ran out of noundles! Try minting with less!");

        // The noundles that the sender is holding.
        uint256[] memory holdingNoundles = Originals.getNoundlesFromWallet(msg.sender);

        uint256 offset = 0;

        // Mint as many as they are holding.
        for (uint256 index; (index < holdingNoundles.length) && index < _noundles; index += 1){

            // Check if it has been minted before.
            if(alreadyMintedNoundles[holdingNoundles[index]]){
                continue;
            }

            // Mark it as minted.
            alreadyMintedNoundles[holdingNoundles[index]] = true;

            // Mint it.
            _handleMinting(msg.sender,  __noundles + offset, 0);

            // Go to the next offset.
            offset += 1;
        }
    }

    // Mint your companion (with Eth).
    function mintNoundles(uint256 _noundles) public payable isPhaseOneStarted {
        uint256 __noundles = totalSupply();

        // Make sure to Do you even read these
        require(_noundles > 0 && _noundles <= 5,               "Your amount needs to be greater then 0 and can't exceed 5");
        require(_noundles * publicMintCompanionPriceEth <= msg.value,   "Ser we need more money for your noundles");
        require(_noundles + __noundles <= MAX_COMPANION_NOUNDLES, "We ran out of noundles! Try minting with less!");

        for (uint256 ___noundles; ___noundles < _noundles; ___noundles++) {
            _handleMinting(msg.sender,  __noundles + ___noundles, 0);
        }
    }

    // Mint your companion (with $RAINBOWS).
    function mintNoundlesWithRainbows(uint256 _noundles) public payable isPhaseOneStarted {
        uint256 __noundles = totalSupply();

        // Make sure to Do you even read these
        require(_noundles > 0 && _noundles <= 5,              "Your amount needs to be greater then 0 and can't exceed 5");
        require(_noundles + __noundles <= MAX_COMPANION_NOUNDLES, "We ran out of noundles! Try minting with less!");

        // Burn the rainbows.
        Rainbows.burn(msg.sender, publicMintCompanionPriceRainbow * _noundles);

        // Mint it.
        for (uint256 ___noundles; ___noundles < _noundles; ___noundles++) {
            _handleMinting(msg.sender, __noundles + ___noundles, 0);
        }
    }

    /*
        Rainbow Minting.
    */
    function _handleRainbowMinting(address _to, uint256 index) private {

        // make a copy of who is getting it.
        address to = _to;

        // Determine what kind of mint it should be.
        uint8 _type = 0;

        // If we determine it's evil.
        if(percentChance(index, 100, percentEvil)){
            _type = 0;
        }

        // Determine if it was stolen, give it to the evil noundle owner.
        if(percentChance(index, 100, percentSteal)){
            uint256 evilTokenId = getRandomEvilNoundle(index, 0);

            // If it's 0 then we don't have a evil noundle to give it to.
            if(evilTokenId != 0){

                counterStolenAttempted += 1;

                // Check if it failed to steal and needs to go to jail.
                if(percentChance(index, 100, percentJail)){
                    jailHouse[evilTokenId] = block.timestamp;

                    counterJailed += 1;
                }else{
                    // The evil noundle stole the nft.
                    to = ownerOf(evilTokenId);
                    counterStolen += 1;

                    // Add to the most wanted.
                    if(mostWantedValues[to] == 0){
                        mostWantedMembers.push(to);
                    }

                    mostWantedValues[to] += 1;
                }
            }
        }

        // Burn the rainbows.
        Rainbows.burn(msg.sender, costToMintWithRainbows());

        // Mint it.
        _handleMinting(to, index, _type);
    }

    // Handle consuming rainbow to mint a new NFT with random chance.
    function mintWithRainbows(uint256 _noundles) public payable isRainbowMintingEnabled {
        uint256 __noundles = totalSupply();

        require(_noundles > 0 && _noundles <= 10,              "Your amount needs to be greater then 0 and can't exceed 10");
        require(_noundles + (mintCountCompanions + mintCountEvil) <= MAX_EVIL_NOUNDLES, "We ran out of noundles! Try minting with less!");

        for (uint256 ___noundles; ___noundles < _noundles; ___noundles++) {
            _handleRainbowMinting(msg.sender,  __noundles + ___noundles);
        }
    }

    // Mint your free lkand.
    function mintHolderLandNoundles(uint256 _noundles) public payable isPhaseTwoStarted {
        uint256 __noundles = totalSupply();

        require(_noundles > 0 && _noundles <= 10, "Your amount needs to be greater then 0 and can't exceed 10");
        require(_noundles + __noundles <= MAX_FREE_LAND_MINTS, "We ran out of land! Try minting with less!");

        // The noundles that the sender is holding.
        uint256[] memory holdingNoundles = Originals.getNoundlesFromWallet(msg.sender);

        uint256 offset = 0;

        // Mint as many as they are holding.
        for (uint256 index; (index < holdingNoundles.length) && index < _noundles; index += 1){

            // Check if it has been minted before.
            if(alreadyMintedLandNoundles[holdingNoundles[index]]){
                continue;
            }

            uint8 _type = 2;

            // Pick a random type of land.
            if(percentChance(__noundles + offset, (percentLowLand + percentMidLand + percentHighLand), percentHighLand)){
                _type = 4;
            }else if(percentChance(__noundles + offset, (percentLowLand + percentMidLand + percentHighLand), percentMidLand)){
                _type = 3;
            }

            // Burn the rainbows.
            Rainbows.burn(msg.sender, landMintPriceRainbow);

            // Mark it as minted.
            alreadyMintedLandNoundles[holdingNoundles[index]] = true;

            // Mint it.
            _handleMinting(msg.sender,  __noundles + offset, _type);

            // Go to the next offset.
            offset += 1;
        }
    }


    /*
        Jail Related
    */
    // Get a evil out of jail.
    function getOutOfJailByTokenId(uint256 _tokenId) public payable isRainbowMintingEnabled {

        // Check that it is a evil noundle.
        require(noundleType[_tokenId] == 1, "Only evil noundles can go to jail.");

        // Burn the rainbows to get out of jail.
        Rainbows.burn(msg.sender, getOutOfJail);

        // Reset the jail time.
        jailHouse[_tokenId] = 1;

        // Stat track.
        counterBail += 1;
    }


    /*
        Helpers
    */
    function setPayoutAddresses(address[] memory _noundles) public onlyOwner {
        founder1 = _noundles[0];
        founder2 = _noundles[1];
    }

    function withdrawFunds(uint256 _noundles) public payable onlyOwner {
        uint256 percentle = _noundles / 100;

        require(payable(founder1).send(percentle * 50));
        require(payable(founder2).send(percentle * 50));
    }

    function random(uint256 _seed, uint256 _index) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _seed, _index)));
    }

    // Pick a evil noundle randomly from our list.
    function getRandomEvilNoundle(uint256 index, uint256 depth) internal view returns(uint256) {
        uint256 selectedIndex = random(seed, index + depth) % evilList.length;

        // If it's not in jail.
        if(jailHouse[evilList[selectedIndex]] + jailLength < block.timestamp){
            return evilList[selectedIndex];
        }

        // If we can't find one in 100 attempts, select none.
        if(depth > 99){
            return 0;
        }

        // If it's in jail, it can't steal so try again.
        return getRandomEvilNoundle(index, depth + 1);
    }

    // Pick a evil noundle randomly from our list.
    function percentChance(uint256 index, uint256 total, uint256 chance) internal returns(bool) {
        seed += 1;

        if(seed > 300000000){ seed = 10; }

        if((random(seed, index) % total) < chance){
            return true;
        }else{
            return false;
        }
    }

    // Determine how much to mint a one with rainbows.
    function costToMintWithRainbows() public view returns(uint256) {

        uint256 total = mintCountCompanions + mintCountEvil;

        if(total >= tier2Start){
            return rBaseMintPriceTier2;
        }
        if(total >= tier3Start){
            return rBaseMintPriceTier3;
        }

        return rBaseMintPriceTier1;
    }

    // Gets the noundle theory tokens and returns a array with all the tokens owned
    function getNoundlesFromWallet(address _noundles) external view returns (uint256[] memory) {
        uint256 __noundles = balanceOf(_noundles);

        uint256[] memory ___noundles = new uint256[](__noundles);
        for (uint256 i;i < __noundles;i++) {
            ___noundles[i] = tokenOfOwnerByIndex(_noundles, i);
        }

        return ___noundles;
    }

    // Returns the addresses that own any evil noundle - seems rare :eyes:
    function getEvilNoundleOwners() external view returns (address[] memory) {
        address[] memory result;

        for(uint256 index; index < evilList.length; index += 1){
            if(jailHouse[evilList[index]] + jailLength <= block.timestamp){
                result[index] = ownerOf(evilList[index]);
            }
        }

        return result;
    }

    // Returns all the home owners :) - 0 = low, 1 = mid, 2 = high in terms of land types
    function getHomeOwners(uint256 _type) external view returns(address[] memory) {
        address[] memory result;

        if (_type == 0) {
            for (uint256 index; index < lowLandList.length; index += 1) {
                result[index] = ownerOf(lowLandList[index]);
            }
        } else if (_type == 1) {
            for (uint256 index; index < midLandList.length; index += 1) {
                result[index] = ownerOf(midLandList[index]);
            }
        } else {
            for (uint256 index; index < highLandList.length; index += 1) {
                result[index] = ownerOf(highLandList[index]);
            }
        }

        return result;
    }

    // Returns all pet owners - make sure you pet your pets.
    function getPetOwners() external view returns(address[] memory) {
        address[] memory result;

        for (uint256 index; index < companionList.length; index += 1) {
            result[index] = ownerOf(companionList[index]);
        }

        return result;
    }

    // Helper to convert int to string (thanks stack overflow).
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // Most wanted.
    function getMostWanted() external view returns(address[] memory) {return mostWantedMembers;}
    function getMostWantedValue(address _arg) external view returns(uint256) {return mostWantedValues[_arg];}
    function resetMostWanted() public onlyOwner {

        // Reset the value for each.
        for(uint256 i = 0; i < mostWantedMembers.length; i += 1){
            mostWantedValues[mostWantedMembers[i]] = 0;
        }

        // Clear most wanted.
        delete mostWantedMembers;
    }

    // Contract Getters
    function _baseURI() internal view override returns (string memory) { return baseURI; }
    function getTypeByTokenId(uint256 _tokenId) external view returns (uint8) { return noundleType[_tokenId]; }
    function getFreeMintUsedByTokenId(uint256 _tokenId) external view returns (bool){ return alreadyMintedNoundles[_tokenId]; }
    function getFreeLandMintUsedByTokenId(uint256 _tokenId) external view returns (bool){ return alreadyMintedLandNoundles[_tokenId]; }
    function getJailStatus(uint256 _tokenId) external view returns (uint256){ return jailHouse[_tokenId]; }
    function getJailStatusBool(uint256 _tokenId) public view returns (bool){ return (jailHouse[_tokenId] + jailLength > block.timestamp); }

    // Contract Setters (pretty standard :))
    function setBaseURI(string memory arg) public onlyOwner { baseURI = arg; }
    function setSaleEnabled() public onlyOwner { saleEnabled = true; }
    function setSeed(uint256 _seed) public onlyOwner { seed = _seed; }
    function setPhaseOneSaleTime(uint256 _arg) public onlyOwner { saleOneTime = _arg; }
    function setPhaseTwoSaleTime(uint256 _arg) public onlyOwner { saleTwoTime = _arg; }
    function setMintPriceEth(uint256 _arg) public onlyOwner { publicMintCompanionPriceEth = _arg; }
    function setMintPriceRain(uint256 _arg) public onlyOwner { publicMintCompanionPriceRainbow = _arg; }
    function setEvilMintCostRainbows(uint256 _arg) external onlyOwner { evilMintPriceRainbow = _arg; }
    function setLandMintCostRainbows(uint256 _arg) external onlyOwner { landMintPriceRainbow = _arg; }

    // Noundle Theory Setters (incase we need to balance some things out)
    function setLowLandPercent(uint256 _amount) public onlyOwner { percentLowLand = _amount; }
    function setMidLandPercent(uint256 _amount) public onlyOwner { percentMidLand = _amount; }
    function setHighLandPercent(uint256 _amount) public onlyOwner { percentHighLand = _amount; }
    function setEvilPercent(uint256 _amount) public onlyOwner { percentEvil = _amount; }
    function setJailPercent(uint256 _amount) public onlyOwner { percentJail = _amount; }
    function setStealPercent(uint256 _amount) public onlyOwner { percentSteal = _amount; }
    function setJailTime(uint256 _amount) external onlyOwner { jailLength = _amount; }
    function setGetOutOfJailCost(uint256 _amount) external onlyOwner { getOutOfJail = _amount; }

    // Contract Setters for the Genesis Contract
    function setGenesisAddress(address _genesis) external onlyOwner { Originals = InterfaceOriginals(_genesis); }

    // Contract Setters for the Rainbows Contract
    function setRainbowMintStatus(bool _arg) public onlyOwner { rainbowMintingEnabled = _arg; }
    function setBaseMintPriceTier1(uint256 _arg) public onlyOwner { rBaseMintPriceTier1 = _arg; }
    function setBaseMintPriceTier2(uint256 _arg) public onlyOwner { rBaseMintPriceTier2 = _arg; }
    function setBaseMintPriceTier3(uint256 _arg) public onlyOwner { rBaseMintPriceTier3 = _arg; }
    function setTier2Start(uint256 _arg) public onlyOwner { tier2Start = _arg; }
    function setTier3Start(uint256 _arg) public onlyOwner { tier3Start = _arg; }
    function setRainbowAddress(address _rainbow) external onlyOwner { Rainbows = InterfaceRainbows(_rainbow); }

    // opensea / ERC721 functions
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();

        return string(abi.encodePacked(base, uint2str(noundleType[tokenId]), "/", uint2str(noundleOffsetCount[tokenId])));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override isSaleEnabled {
        Rainbows.transferTokens(from, to);

        if (noundleType[tokenId] == 0) {
            companionBalance[from]++;
            companionBalance[to]--;
        } else if (noundleType[tokenId] == 2) {
            evilBalance[from]++;
            evilBalance[to]--;
        } else if (noundleType[tokenId] == 3) {
            lowLandBalance[from]++;
            lowLandBalance[to]--;
        } else if (noundleType[tokenId] == 4) {
            midLandBalance[from]++;
            midLandBalance[to]--;
        } else {
            highLandBalance[from]++;
            highLandBalance[to]--;
        }

        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override isSaleEnabled {
        Rainbows.transferTokens(from, to);

        if (noundleType[tokenId] == 0) {
            companionBalance[from]++;
            companionBalance[to]--;
        } else if (noundleType[tokenId] == 2) {
            evilBalance[from]++;
            evilBalance[to]--;
        } else if (noundleType[tokenId] == 3) {
            lowLandBalance[from]++;
            lowLandBalance[to]--;
        } else if (noundleType[tokenId] == 4) {
            midLandBalance[from]++;
            midLandBalance[to]--;
        } else {
            highLandBalance[from]++;
            highLandBalance[to]--;
        }

        ERC721.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override isSaleEnabled {
        Rainbows.transferTokens(from, to);

        if (noundleType[tokenId] == 0) {
            companionBalance[from]++;
            companionBalance[to]--;
        } else if (noundleType[tokenId] == 2) {
            evilBalance[from]++;
            evilBalance[to]--;
        } else if (noundleType[tokenId] == 3) {
            lowLandBalance[from]++;
            lowLandBalance[to]--;
        } else if (noundleType[tokenId] == 4) {
            midLandBalance[from]++;
            midLandBalance[to]--;
        } else {
            highLandBalance[from]++;
            highLandBalance[to]--;
        }

        ERC721.safeTransferFrom(from, to, tokenId, data);
    }
}