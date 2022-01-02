/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// File: @openzeppelin/[email protected]/utils/Counters.sol


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

// File: @openzeppelin/[email protected]/utils/Strings.sol


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

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


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

// File: @openzeppelin/[email protected]/utils/Address.sol


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

// File: @openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


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

// File: @openzeppelin/[email protected]/utils/introspection/ERC165.sol


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

// File: @openzeppelin/[email protected]/token/ERC721/IERC721.sol


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

// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Enumerable.sol


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

// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Metadata.sol


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

// File: @openzeppelin/[email protected]/token/ERC721/ERC721.sol


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

// File: @openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol


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

// File: contract-3ca8ecdeb2.sol


pragma solidity ^0.8.2;





// PETARP contract
// to get the prg for a token:
// call getTokenPRG( uint256 tokenId, bool unmodified )
// the prg will be returned as bytes
contract PETARP is ERC721, ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  string constant tokenName   = "PETARP";
  string constant tokenSymbol = "ARP";

  uint256 public mintPrice = .00256e18;
  string private _tokenBaseURI = "https://nopsta.com/petarp/meta/";

  // the number of seconds in a day
  uint constant DAY_SECONDS = 24 * 60 * 60;

  // can only mint up to 256 tokens
  uint constant MAX_NUMBER_TOKENS = 256;

  // each token has 8 parameters
  uint constant PARAM_COUNT = 8;

  // each token has 4 unlocks: color effect, detune effect, root note change, journey mode
  uint constant UNLOCKS_COUNT = 4;

  // a token owner can set 8 custom bytes
  uint constant CUSTOM_BYTE_COUNT = 8;

  // the default filter value (filter cutoff high)
  uint8 constant FILTER_DEFAULT_VALUE = 22 * 8;

  // the length of the prg in bytes
  uint constant PRG_DATA_LENGTH = 2048;

  // the position in the prg of the user settings
  uint constant SETTINGS_POSITION = 1826;

  // the position in the prg where the token parameters go
  uint constant PARAM_START_POSITION = 1837;

  // the base prg data, this is modified to produce the prg for each token
  bytes constant basePRGData = hex"01080b0800009e3230363100000078a96f8dfaffa90b8dfbffa9008d0edd8d05dd8d04dda9818d0ddda9018d0edda9358501a000a2fda9ff9dff039dfc049df9059dea06ad1f0f9dffd79dfcd89df9d99deada9401cad0de8cff0fa9128d18d08e0010a9048d1910bd00101869289d0110bd191069009d1a10e8e018d0eaa91f851aad12d0cd12d0f0fb30f6c920b002e626a20bbd200f952ecad0f88557ad2f0f291faa29f085febd8d0e8521ad2f0f4a4a4a4a4aaa4a262d8a2902852b8a29048522ad300f48290faa18bdd80e69ea8523a90e69008524684a4a4a4aaabd670e852ebd770e852fe001d0028619b1238d20d08d21d0af310f2903a8b9850e851b8a4a4a482907aabd850e851c684a4a4a2907aabd850e851dc645c64cc653a00a844284498450c643c651af2d0f851529b0851ead2e0f851629018520af2c0f85142910d00284518a2902d00284438a2901851fa9928546a9a28554a9e2854dad330f482907c901d0028551aabd170f8552684a4a4aae2d0f1009a6fef004a62e10024a4a852caf320f2907a8b90e0f85448a4a4a4a482907aabd110f854b0552c911d0028544684a4a4a29030522aabd820e8518a91f8558855520b70ce602ad12d0c9eed0f9a218b5409d00d4ca10f820830ba526f00ac63a1006a905853ad0dea24fb45df03ad6ad1036a52f95adbd32108503bd8210850488945dd01338e9d48504a9ff9103bd82108504ad1f0fb00cc8984aa8b123b0044a4a4a4aa0009103ca10bfc602f0034c540ba52e8502a51a290fc90830051849ff6911186901854aaaa50c2520f0028651a556a631e00410097d770b900ba9ffd007fd770bb002a9008556c6171008a5188517a5308556c61a101aa534f010a429c8c529d002a0008429b9e70e85fda91f851a8550a5350a6510291e8510f002e6321865218525a52ec906f00538e519852ea202d60a1014b51b950ad65a1006f614b537955ab514950d9511b50df0030a90024525950d290718652d7d520da88a051e0517d002a007b9390d850718b9200d652cac360ff00265fda88622bd610eaab9550d9540b9a90d9541a62220550e291fc9143002290f850620550e290fc90c300229078505a52b8508a50829010a8509a5064820fd0d38a927e506850620fd0d38a917e505850520fd0d68850620fd0da622ca30034cad0aad350ff00a18a547a6337d7e0b854718a550651fb00285504cbf0940ecf6fae8f4f8e700180c04180c040018120c06a528f005c6284caa0b8d02dcaf00dc2904f0788a2901f0358a2902f0478a2910f04c8a2908f07ba9ff8d02dca9008d03dca97f8d00dcaf01dcc53ff015853f2908d005a9024cc20c8a2901d005a9014cc20ca9fd8d00dcaf01dcc53bf01b853b2901d005a9044cc20c8a2908d00bc6311004a90685314cc90ca9fb8d00dcaf01dcc53cf037853c2901d01238a530e9089027853038a556e908901eb0178a2908d01a18a5306908c9f8f00e853018a5566908b00585568d16d44cc90ca9f78d00dcaf01dcc53df021853d2901d007ad340ff002e6328a2908d00fad350ff00ac6331004a9048533105da9ef8d00dcad01dcc53ef036853e2901d019ad360ff014a900852918a5346901c903d002a90085344cc90ca53e2908d011ad370ff00ca5354901853585328510101ba527f004c627f00160a227a9ff9dc007ca10f860455785578d17d0a9508527a9088528a202bd640e2557f004a9e9d002a9ee9dc007ca10eda431b9700b8dc307a9ec9dc507e8e01fd0f6a5304a4a4aaaa9ed9dc507a9eaa633f003bdcf0e8de507a5341869ea8de607a5354a69ea8de7076018130c100c101300241c181a181f1f23241c1817131f1a17240004020102010405060700080009090a0607000304090803060008102d4e7196bee8144374a9e11c5a9ce22d7ccf2885e852c137b439c55af79e4f0ad1a3826e68718ab3ee3c9e15a24604dcd0e21467dd793c29448d08b8a1c528cdbaf17853871a107142894f9b74e2f0a60e3320ff0202020202020303030303040404040505050606060707080809090a0a0b0c0d0d0e0f10111213141517181a1b1d1f20222427292b2e3134373a3e4145494e52575c62686e757c838b939ca5afb9c4d0ddeaf8ff18a605bd001065068503bd191069008504a000a5070a0a6508aabdac0e910318a50469d48504a00218b1236532a0009103a24fb55df003cad0f9a904955da52f95ada5039d3210a5049d821018a508690165092903850860b511f0030a9002452595116000070e0102040681080806e50608050706060706080603030705042e050303040703030303070b0f13171b1f20436f190367050f07090a0b5a25852103595bd15f62139a9fa7a9aba1afc3e7e8e7e8e9e9e9e9fbfcfefdebebebebececececededededeeeeeeeeeff0f2f1f3f4f6f5f7f8faf9eaeaeaea001e1b030c000f121518090306210300050700bcf101fcb00bcfa20a82940064e303557706eeee0488a70ea3a3064e3d028a7101e46511411141211141415141512111154121410f0027b00300000000000f0707010203040506070800000000c0e070381c0e070303070e1c3870e0c0003c7e7e7e7e3c00003c7e66667e3c001818181818181818000000ffff000000181818ffff181818c3e77e3c3c7ee7c3ffffc0c0c0c0c0c0ffff030303030303c0c0c0c0c0c0ffff030303030303ffff0000001f1f181818000000f8f81818181818181f1f000000181818f8f8000000000000070f1c1818000000e0f038181818181c0f07000000181838f0e0000000000103070f1f3f7f0080c0e0f0f8fcfeff7f3f1f0f070301fffefcf8f0e0c08000000000000000";

  // this event is emitted when a custom byte is set
  event ByteSet( uint indexed tokenId, uint byteIndex, uint16 bytePosition, uint8 byteValue );

  // TokenData has the values specific to each token
  struct TokenData {
    // 8 x 1 byte parameters stored in a uint64
    uint64 params;

    // 4 unlocks, 1 if unlocked, 0 otherwise
    uint8[UNLOCKS_COUNT] unlocked;

    // 8 custom bytes, set by the token owner
    // bytes in the prg data will be replaced with these bytes
    // customBytePosition is 0 if unset
    uint16[CUSTOM_BYTE_COUNT] customBytePosition;
    uint8[CUSTOM_BYTE_COUNT]  customByteValue;

    // user data is used to store settings
    uint24 userData;

    // the last time the token was transferred
    uint256 lastTransfer;
  }

  // mapping of tokenIds to the token's data
  mapping(uint256 => TokenData) tokenData;

  // the number of tokens minted. if less than 256 then this will also be the value of the next tokenId
  Counters.Counter private _tokenIdCounter;

  // keep track of which positions have been used per byte index
  // a position can't be used if someone else has used it first (per byte index)
  mapping( uint16 => uint8 )[CUSTOM_BYTE_COUNT] public positionUsed;

  constructor() ERC721( tokenName, tokenSymbol ) {
  }


  // ------------------------- public/external functions with no access restrictions ------------------------- //

  function mintToken()
    public
    payable
    returns ( uint256 _tokenId )
  {
    require( _tokenIdCounter.current() < MAX_NUMBER_TOKENS, "All tokens created" );
    require( msg.value >= mintPrice, "The value sent must be at least the mint price" );

    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();

    _safeMint( msg.sender, tokenId );

    tokenData[tokenId].params = uint64( bytes8( keccak256( abi.encodePacked( block.timestamp, msg.sender, tokenId.toString() ) ) ) );

    tokenData[tokenId].lastTransfer = block.timestamp;

    // increase price for tokens 128 - 255
    if( tokenId == 127 ) {
      mintPrice = .00512e18;
    }

    return tokenId;
  }

  // convert a 5 bit number (0-31) stored in user data
  // to the 8 bit number (0-240) used as the prg's initial filter value
  function filterValue( uint8 v )
    internal
    pure
    returns ( uint8 )
  {
    if( v == 0 ) {
      // zero means use the filter default value
      return FILTER_DEFAULT_VALUE;
    } else {
      return (v - 1) * 8;
    }
  }

  // return the prg for a token as bytes
  // if unmodified is true, don't set any owner custom bytes or settings
  function getTokenPRG( uint256 tokenId, bool unmodified )
    public
    view
    returns ( bytes memory )
  {
    require( tokenId < _tokenIdCounter.current(), "Invalid token id" );

    bytes memory tokenPRG = basePRGData;

    // get the token's parameters and insert them into the prg data
    uint8 p0;
    uint8 p1;
    uint8 p2;
    uint8 p3;
    uint8 p4;
    uint8 p5;
    uint8 p6;
    uint8 p7;

    (p0, p1, p2, p3, p4, p5, p6, p7) = getTokenParams( tokenId );

    tokenPRG[PARAM_START_POSITION]     = bytes1( p0 );
    tokenPRG[PARAM_START_POSITION + 1] = bytes1( p1 );
    tokenPRG[PARAM_START_POSITION + 2] = bytes1( p2 );
    tokenPRG[PARAM_START_POSITION + 3] = bytes1( p3 );
    tokenPRG[PARAM_START_POSITION + 4] = bytes1( p4 );
    tokenPRG[PARAM_START_POSITION + 5] = bytes1( p5 );
    tokenPRG[PARAM_START_POSITION + 6] = bytes1( p6 );
    tokenPRG[PARAM_START_POSITION + 7] = bytes1( p7 );

    // modify the prg to set the state of the unlocks
    for( uint i = 0; i < UNLOCKS_COUNT; i++) {
      tokenPRG[PARAM_START_POSITION + 8 + i] = bytes1( tokenData[tokenId].unlocked[i] );
    }

    // if unmodified is false, set any custom bytes and settings set by the current or a previous owner
    if( !unmodified ) {

      // read the user settings from the 24 bit user data number

      // filter routing (inverted) add the resonance value (32)  (3 bits)
      tokenPRG[SETTINGS_POSITION] = bytes1( uint8( ( ( tokenData[tokenId].userData & 7 ) ^ 7 ) + 32 ) );

      // filter value (0-31). if 0, set to the default value, otherwise subtract 1 and multiply by 8 (5 bits)
      tokenPRG[SETTINGS_POSITION + 1] = bytes1( filterValue ( uint8( ( tokenData[tokenId].userData >> 3 ) & 31 ) ) );

      // filter mode (0-6). if 0, set to the default value (3) (3 bits)
      tokenPRG[SETTINGS_POSITION + 2] = bytes1( uint8( ( ( ( tokenData[tokenId].userData >> 8 ) & 7 ) + 3 ) % 7 ) );

      // color offset effect value (0-15) (4 bits)
      if( tokenData[tokenId].unlocked[0] != 0 ) {
        tokenPRG[SETTINGS_POSITION + 3] = bytes1( uint8( ( tokenData[tokenId].userData >> 11 ) & 15) );
      }

      // detune effect (0-4) (3 bits)
      if( tokenData[tokenId].unlocked[1] != 0 ) {
        tokenPRG[SETTINGS_POSITION + 4] = bytes1( uint8( ( ( tokenData[tokenId].userData >> 15 ) & 7 ) % 5 ) );
      }

      // root note change effect (0-2) (2 bits)
      if( tokenData[tokenId].unlocked[2] != 0 ) {
        tokenPRG[SETTINGS_POSITION + 5] = bytes1( uint8( ( ( tokenData[tokenId].userData >> 18 ) & 3 ) % 3 ) );
      }

      // journey mode off/on (0-1) (1 bit)
      if( tokenData[tokenId].unlocked[3] != 0 ) {
        tokenPRG[SETTINGS_POSITION + 6] = bytes1( uint8( ( tokenData[tokenId].userData >> 20 ) & 1 ) );
      }

      // include user defined custom bytes if bit 21 is zero
      if( ( tokenData[tokenId].userData >> 21 ) & 1 == 0 ) {

        uint16 customBytePosition = 0;
        for( uint i = 0; i < CUSTOM_BYTE_COUNT; i++ ) {
          customBytePosition = tokenData[tokenId].customBytePosition[i];

          if( customBytePosition != 0 && customBytePosition < PRG_DATA_LENGTH ) {
            tokenPRG[customBytePosition] = bytes1( tokenData[tokenId].customByteValue[i] );
          }
        }
      }
    }

    // insert the token id into the prg
    tokenPRG[SETTINGS_POSITION + 7] = bytes1( uint8( tokenId ) );

    return tokenPRG;
  }

  // get the uint64 the prg params are made from
  function getTokenSeed( uint256 tokenId )
    external
    view
    returns ( uint64 p )
  {
    p = tokenData[tokenId].params;
  }

  // return the 8 parameters for the token as uint8s
  function getTokenParams( uint256 tokenId )
    public
    view
    returns ( uint8 p0, uint8 p1, uint8 p2, uint8 p3, uint8 p4, uint8 p5, uint8 p6, uint8 p7 )
  {
    require( tokenId < _tokenIdCounter.current(), "Invalid token id" );

    uint params = tokenData[tokenId].params;

    p0 =  uint8( params & 255 );
    p1 =  uint8( (params >> 8) & 255 );
    p2 =  uint8( (params >> 16) & 255 );
    p3 =  uint8( (params >> 24) & 255 );
    p4 =  uint8( (params >> 32) & 255 );
    p5 =  uint8( (params >> 40) & 255 );
    p6 =  uint8( (params >> 48) & 255 );
    p7 =  uint8( (params >> 56) & 255 );

  }

  // return the state of the 4 unlocks for the token, 1 = unlocked
  function getTokenUnlocks( uint256 tokenId )
    external
    view
    returns ( uint8 u0, uint8 u1, uint8 u2, uint8 u3 )
  {
    require( tokenId < _tokenIdCounter.current(), "Invalid token id" );

    u0 = tokenData[tokenId].unlocked[0];
    u1 = tokenData[tokenId].unlocked[1];
    u2 = tokenData[tokenId].unlocked[2];
    u3 = tokenData[tokenId].unlocked[3];
  }

  // return an owner set custom byte for the token
  // byteIndex is 0 - 7 (8 custom bytes per token)
  // if a byte is not set, its position will be 0
  function getTokenCustomByte( uint256 tokenId, uint256 byteIndex )
    external
    view
    returns ( uint16 position, uint8 value )
  {
    require( tokenId < _tokenIdCounter.current(), "Invalid token id" );
    require( byteIndex < CUSTOM_BYTE_COUNT, "Invalid byte index" );

    position = tokenData[tokenId].customBytePosition[byteIndex];
    value    = tokenData[tokenId].customByteValue[byteIndex];
  }

  // return all the custom bytes for a token in an array
  function getTokenCustomBytes( uint256 tokenId )
    external
    view
    returns ( uint16[CUSTOM_BYTE_COUNT] memory position, uint8[CUSTOM_BYTE_COUNT] memory value )
  {
    require( tokenId < _tokenIdCounter.current(), "Invalid token id" );

    position = tokenData[tokenId].customBytePosition;
    value    = tokenData[tokenId].customByteValue;
  }


  // return the user data containing the settings for a token
  function getTokenUserData( uint256 tokenId )
    external
    view
    returns ( uint24 userData )
  {
    require( tokenId < _tokenIdCounter.current(), "Invalid token id" );

    userData = tokenData[tokenId].userData;
  }

  // return the time in seconds since a token was last transferred
  function getSecondsSinceLastTransfer( uint tokenId )
    external
    view
    returns(uint)
  {
    require( tokenId < _tokenIdCounter.current(), "Invalid token id" );

    return block.timestamp - tokenData[tokenId].lastTransfer;
  }

  function supportsInterface( bytes4 interfaceId )
    public
    view
    override( ERC721, ERC721Enumerable )
    returns ( bool )
  {
      return super.supportsInterface( interfaceId );
  }

  // ------------------------- internal unrestricted functions ------------------------- //

  function _baseURI()
    internal
    view
    override
    returns ( string memory )
  {
    return _tokenBaseURI;
  }

  function _beforeTokenTransfer( address from, address to, uint256 tokenId )
    internal
    override( ERC721, ERC721Enumerable )
  {
    super._beforeTokenTransfer( from, to, tokenId );

    // set the time the token was last transferred to the current timestamp
    if( tokenId < _tokenIdCounter.current() ) {
      tokenData[tokenId].lastTransfer = block.timestamp;
    }
  }

  // ------------------------- token owner functions ------------------------- //

  // check if the sender address can set a byte for the token
  // the token owner can set up to 8 bytes for a token (byteIndex can be 0-7)
  // each byteIndex can be set if the token has been held for byteIndex x 64 days
  function checkCanSetByte( address sender, uint tokenId, uint byteIndex, uint16 bytePosition )
    public
    view
  {
    require( tokenId < _tokenIdCounter.current(), "Invalid token id" );
    require( ERC721.ownerOf(tokenId) == sender, "Only owner can set bytes" );

    require( byteIndex < CUSTOM_BYTE_COUNT, "Invalid byte index" );
    require( bytePosition < basePRGData.length, "Invalid position" );
    require( bytePosition < PARAM_START_POSITION || bytePosition >= PARAM_START_POSITION + 12, "Can't set param bytes" );
    require( bytePosition < SETTINGS_POSITION || bytePosition >= SETTINGS_POSITION + 8, "Can't set settings bytes" );

    uint timeRequirement = ( byteIndex + 1 ) * 64 * DAY_SECONDS;
    string memory message = string( abi.encodePacked( "Since last transfer needs to be greater than ", timeRequirement.toString() ) );

    if ( bytePosition != 0 ) {
      require( ( block.timestamp - tokenData[tokenId].lastTransfer) >= timeRequirement, message );
    }

    require( bytePosition == 0 || bytePosition == tokenData[tokenId].customBytePosition[byteIndex] || positionUsed[byteIndex][bytePosition] == 0, "Position already used" );

  }


  // set a byte
  function setByte( uint tokenId, uint byteIndex, uint16 bytePosition, uint8 byteValue )
    public
  {
    checkCanSetByte( msg.sender, tokenId, byteIndex, bytePosition );

    // if the new position is different to the previous position for the byte index
    // mark the previous position as unused and the new position as used
    if( tokenData[tokenId].customBytePosition[byteIndex] != bytePosition ) {
      positionUsed[byteIndex][tokenData[tokenId].customBytePosition[byteIndex]] = 0;
      positionUsed[byteIndex][bytePosition] = 1;
    }

    // save the values
    tokenData[tokenId].customBytePosition[byteIndex]  = bytePosition;
    tokenData[tokenId].customByteValue[byteIndex]     = byteValue;

    // emit the event
    emit ByteSet( tokenId, byteIndex, bytePosition, byteValue );

  }

  // set all the bytes with one call
  function setBytes( uint tokenId, uint16[CUSTOM_BYTE_COUNT] memory bytePositions, uint8[CUSTOM_BYTE_COUNT] memory byteValues )
    public
  {
    // fail if one of the bytes can't be set
    for( uint i = 0; i < CUSTOM_BYTE_COUNT; i++ ) {
      checkCanSetByte( msg.sender, tokenId, i, bytePositions[i] );
    }

    for( uint i = 0; i < CUSTOM_BYTE_COUNT; i++ ) {
      setByte( tokenId, i, bytePositions[i], byteValues[i] );
    }
  }

  // can unlock a feature if:
  // tokenId is valid
  // unlock index is valid
  // sender is the owner of the token
  // unlock ownership/time requirements are met
  function checkCanUnlock( address sender, uint tokenId, uint unlockIndex )
    public
    view
  {
    require( tokenId < _tokenIdCounter.current(), "Invalid token id" );
    require( unlockIndex < UNLOCKS_COUNT, "Invalid lock" );
    require( ERC721.ownerOf( tokenId ) == sender, "Only owner can unlock" );

    // time constraint: 32, 64, 128, 256 days
    uint timeRequirement = ( 2 ** unlockIndex ) * 32 * DAY_SECONDS;
    string memory message = string( abi.encodePacked( "Since Last Transfer needs to be ", timeRequirement.toString() ) );

    require( ( block.timestamp - tokenData[tokenId].lastTransfer ) >= timeRequirement, message );

    if( unlockIndex == 0 ) {
      // to unlock 0, need to own at least 2
      require( ERC721.balanceOf( sender ) > 1, "Need to own 2 or more" );
    }

    // to unlock 3, need to satisfy time constraint and own at least 4
    if( unlockIndex == 3 ) {
      require( ERC721.balanceOf( sender ) > 3, "Need to own 4 or more" );
    }
  }

  // set a feature as unlocked
  function unlock( uint256 tokenId, uint256 unlockIndex )
    external
  {
    checkCanUnlock( msg.sender, tokenId, unlockIndex );

    // set as unlocked
    tokenData[tokenId].unlocked[unlockIndex] = 1;
  }

  function checkCanSetUserData( address sender, uint tokenId )
    public
    view
  {
    require( tokenId < _tokenIdCounter.current(), "Invalid token id" );
    require( ERC721.ownerOf( tokenId ) == sender, "Only owner can set user data" );
  }

  // user settings for the token
  function setTokenUserData ( uint tokenId, uint24 userData )
    external
  {
    checkCanSetUserData( msg.sender, tokenId );

    tokenData[tokenId].userData = userData;
  }

  // set byte and user data
  function setByteAndUserData( uint tokenId, uint byteIndex, uint16 bytePosition, uint8 byteValue, uint24 userData )
    external
  {
    setByte( tokenId, byteIndex, bytePosition, byteValue );

    checkCanSetUserData( msg.sender, tokenId );
    tokenData[tokenId].userData = userData;
  }

  // ------------------------- contract owner only functions ------------------------- //

  function setMintPrice( uint256 price )
    external
    Ownable.onlyOwner
  {
    mintPrice = price;
  }

  function withdraw( uint amount )
    external
    Ownable.onlyOwner
  {
    require( amount <= address( this ).balance, "Insufficient funds" );

    payable( msg.sender ).transfer( amount );
  }

  function setBaseURI( string memory baseURI )
    external
    Ownable.onlyOwner {
    _tokenBaseURI = baseURI;
  }
}