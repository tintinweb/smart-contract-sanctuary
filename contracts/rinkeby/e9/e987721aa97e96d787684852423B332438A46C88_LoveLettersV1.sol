/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: Base64

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/Counters

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

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/IERC721Receiver

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

// Part: OpenZeppelin/[email protected]/Strings

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

// Part: OpenZeppelin/[email protected]/ERC165

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

// Part: OpenZeppelin/[email protected]/IERC721

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

// Part: OpenZeppelin/[email protected]/Ownable

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

// Part: OpenZeppelin/[email protected]/IERC721Enumerable

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

// Part: OpenZeppelin/[email protected]/IERC721Metadata

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

// Part: OpenZeppelin/[email protected]/ERC721

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

// Part: OpenZeppelin/[email protected]/ERC721Enumerable

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

// File: LoveLettersV1.sol

contract LoveLettersV1 is Context, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    //Relevant mappings
    Counters.Counter private _tokenIdTracker;
    uint256 private _price;

    uint256 public maxSupply;
    bool public saleStarted = false;

    mapping(uint256 => string) private tokenIdToLetter;

    address public constant staffVaultAddress =
        0xd55883D964ad3299Aa099Fae555989FBCe0De6bD;

    event SaleState(bool);
    event LetterWritten(
        uint256 proposalid,
        address author,
        address to,
        string content
    );

    //Constructor
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 price_
    ) ERC721(name_, symbol_) {
        maxSupply = maxSupply_;
        _price = price_;

        _tokenIdTracker.increment(); //Start at index 1
    }

    function mint(address to) internal {
        _safeMint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function writeLetter(string memory letter, address to) public payable {
        require(
            saleStarted,
            "You can not write letters until the project starts!"
        );
        require(to != msg.sender, "Letters are for other people!");
        require(msg.value >= viewPrice(), "sent insufficient Ether");
        require(totalSupply() + 1 <= maxSupply, "We are out of stamps!");
        tokenIdToLetter[_tokenIdTracker.current()] = letter;
        mint(to);

        emit LetterWritten(_tokenIdTracker.current(), msg.sender, to, letter);
    }

    function staffWrite(string memory letter, address to) public onlyOwner {
        tokenIdToLetter[_tokenIdTracker.current()] = letter;
        mint(to);

        emit LetterWritten(_tokenIdTracker.current(), msg.sender, to, letter);
    }

    function readLetter(uint256 tokenId) public view returns (string memory) {
        return tokenIdToLetter[tokenId];
    }

    //tokenURI function
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[2] memory parts;
        parts[
            0
        ] = '<svg width="265" height="338" fill="none" xmlns="http://www.w3.org/2000/svg"><g clip-path="url(#a)"><path d="M271 0H-6v338h277V0Z" fill="#000"/><path d="M199.422.422c-1.028.502-1.74 1.585-2.452 3.671-.606 1.796-1.371 3.063-2.083 3.486-.29.184-1.767.396-3.322.501l-2.795.185-.791-.766c-.976-.924-1.609-2.112-2.189-4.145-.237-.845-.606-1.585-.817-1.664-.185-.08-1.055 0-1.872.158-1.767.37-3.006 1.4-3.006 2.509 0 2.113-2.479 4.093-5.063 4.093-1.688 0-2.874-.396-6.803-2.245-1.951-.924-3.797-1.716-4.087-1.795-.396-.106-.791.185-1.582 1.215-1.345 1.716-2.901 2.535-4.878 2.535-2.374.026-4.457-1.268-5.432-3.301-.475-1.03-1.767-1.69-3.191-1.69-1.424.026-1.977.422-3.296 2.376-1.45 2.192-2.426 2.747-4.693 2.747-1.345 0-1.978-.132-2.901-.634-1.45-.819-2.9-2.667-2.9-3.723 0-1.189-1.029-2.087-2.4-2.087-.606 0-1.529.132-2.083.29-.896.265-1.028.423-1.397 1.797-.501 1.822-1.213 2.772-2.611 3.485-3.217 1.637-7.172.423-8.279-2.614-.264-.687-.581-1.4-.712-1.584-.317-.397-1.952-.423-3.534 0-1.081.264-1.318.475-2.215 1.9-1.344 2.166-2.109 2.589-4.799 2.615-2.584.053-3.533-.37-4.931-2.27-.738-1.03-1.186-1.348-2.241-1.638-1.186-.37-1.503-.343-2.716 0-.817.238-1.53.66-1.766 1.003-.633.977-2.98 2.615-4.14 2.852-1.424.343-3.665-.132-4.667-.95-.396-.344-1.055-1.347-1.45-2.245-.818-1.822-1.214-1.954-2.4-.819-.422.423-1.503 1.004-2.373 1.32-.87.318-2.136.872-2.822 1.242-2.531 1.347-4.983 1.743-6.829 1.135-1.24-.422-2.61-1.478-2.61-2.033 0-.924-1.082-2.192-2.294-2.746-2.136-.95-4.298-.185-4.298 1.531 0 .845-1.477 2.456-2.77 3.037-1.95.898-4.64.502-6.17-.898-.342-.317-.896-1.03-1.265-1.584-.87-1.4-2.03-2.033-3.665-2.033-1.609 0-2.11.343-3.349 2.244-.448.713-1.24 1.585-1.74 1.901-.818.555-1.134.608-2.9.476-4.009-.317-4.694-.687-5.3-2.984-.58-2.218-.844-2.43-2.717-2.43-2.294 0-3.216.529-4.667 2.72-.738 1.136-1.53 2.007-2.11 2.324-1.054.555-3.269.66-4.877.211-1.213-.343-3.296-2.27-3.296-3.063 0-.74-1.055-1.135-3.033-1.135-2.083 0-2.505.158-2.505.924 0 1.188-4.667 4.885-6.143 4.885-.238 0-.818-.238-1.293-.528-.474-.29-.975-.528-1.133-.528-.132 0-.58.634-.976 1.4-.554 1.082-.712 1.874-.844 3.881-.079 1.743-.026 2.72.185 3.169.184.37 1.24 1.188 2.426 1.875 1.37.765 2.267 1.478 2.61 2.06.66 1.135.923 4.515.422 5.465-.185.344-1.45 1.48-2.795 2.509-2.347 1.796-2.452 1.928-2.637 3.09-.237 1.505.317 3.274 1.081 3.485.29.08 1.213.581 2.057 1.136 2.03 1.294 2.663 2.64 2.69 5.466 0 2.43-.422 3.116-2.875 4.78-1.845 1.24-2.267 2.033-2.267 4.277 0 .977.132 1.294.685 1.743.396.317.87.554 1.108.554.738 0 2.11 1.057 2.558 2.007.738 1.558 1.028 3.776.659 5.097-.396 1.505-2.373 3.512-3.955 4.014-1.082.343-1.24.501-1.767 1.848-.317.819-.66 1.98-.765 2.561l-.184 1.11H1.74c2.083 0 3.613.765 4.457 2.218 1.239 2.112.606 4.911-1.714 7.816-1.82 2.27-2.294 3.116-2.61 4.542-.344 1.558-.027 2.482.948 2.878 2.242.871 3.033 1.373 3.507 2.139.765 1.294.923 2.825.396 4.594-.501 1.796-.58 1.875-2.558 4.067-1.608 1.743-1.977 2.72-1.714 4.41.185 1.135.897 1.928 2.057 2.297 1.213.396 1.898 1.479 2.11 3.275.316 2.746-.897 4.542-3.086 4.542-2.69 0-3.085.924-2.056 4.726.896 3.301 1.08 3.644 2.083 3.988 1.08.343 2.083 1.399 2.742 2.904 1.424 3.143-.132 6.84-3.19 7.685-2.796.739-3.033 1.293-1.767 3.881.685 1.373 1.186 1.928 2.452 2.852 2.189 1.558 2.4 1.796 2.742 2.984.976 3.195-.263 6.39-3.111 8.08a3.95 3.95 0 0 0-1.899 3.327c.027 1.294.528 1.902 2.163 2.747 3.823 1.954 4.245 5.703.975 8.608-.923.792-1.318 1.426-1.74 2.667-1.134 3.327-.527 5.281 1.977 6.391 1.082.475 1.767 1.98 1.873 4.119.105 1.531.026 1.875-.712 3.089-.607 1.057-1.108 1.558-2.11 2.06-2.03 1.03-2.373 1.532-2.373 3.459 0 1.928.58 2.826 2.531 3.961 2.189 1.294 3.191 3.116 2.927 5.414-.079.686-.342 1.637-.58 2.112-.606 1.136-2.373 3.01-3.533 3.723-1.213.74-1.345.925-1.345 2.166 0 1.056.448 1.61 3.349 4.119 1.846 1.584 2.426 5.017 1.266 7.499-.475.951-1.319 1.479-2.505 1.479-1.082 0-1.53.581-1.714 2.298-.08.845-.185 2.033-.264 2.64-.132 1.188.079 1.479 1.24 1.769 1.792.423 3.348 2.667 3.559 5.176.21 2.271-.211 3.195-2.03 4.515-1.873 1.4-2.215 1.928-2.743 4.463-.395 1.954-.237 2.826.475 2.562.66-.238 2.769 1.161 3.77 2.508.502.713.607 1.162.607 2.746 0 1.057-.132 2.245-.264 2.615-.158.396-1.08 1.505-2.083 2.455-1.82 1.796-3.006 3.697-3.322 5.361-.185.977.105 1.267 1.608 1.69 1.055.29 2.716 1.69 3.217 2.693.66 1.294.923 3.512.607 4.78-.396 1.452-1.899 2.852-3.613 3.353-1.239.37-1.53.555-1.845 1.347-.712 1.664.158 3.591 1.95 4.384 1.82.792 2.901 1.954 3.376 3.591.87 2.984-.633 6.258-3.138 6.813-2.452.528-3.217 1.927-2.4 4.489.396 1.267.633 1.558 2.057 2.508 2.004 1.347 3.006 2.271 3.48 3.195.502.951.476 3.645-.052 4.938-.422 1.057-1.186 1.532-3.85 2.377-1.265.422-1.423.66-1.608 2.535-.237 2.271.132 2.905 2.452 4.331 2.584 1.584 3.164 2.614 3.138 5.651-.026 2.508-.21 2.904-2.4 4.515-1.793 1.347-2.742 2.509-3.111 3.829-.343 1.241-.026 1.637 1.793 2.35 1.582.607 3.48 2.271 3.48 3.063 0 .185.66 1.215 1.45 2.298.792 1.082 1.53 2.244 1.61 2.614.263.977.817 1.505 2.109 2.007 1.661.633 2.347.237 4.271-2.351 2.242-3.036 2.532-3.274 4.404-3.432 2.637-.212 3.27.422 4.113 4.145.29 1.215.501 1.585 1.029 1.823.949.369 4.166.237 5.062-.238.396-.211 1.398-1.268 2.163-2.324 2.294-3.089 2.69-3.327 5.3-3.327 2.004 0 2.267.053 3.032.686 1.134.977 2.347 3.169 2.531 4.674.211 1.506.87 1.902 2.532 1.638 1.503-.265 2.478-1.242 3.639-3.697.922-1.928 1.186-2.245 2.188-2.747 1.292-.633 1.978-.686 3.929-.264 2.373.528 3.797 1.875 4.271 4.067.238 1.03.633 1.531 1.609 2.033 1.24.634 2.373.792 3.533.476 1.134-.291 1.187-.397 1.424-2.562.158-1.347 1.477-3.327 2.479-3.723.395-.159 1.582-.343 2.584-.423 1.45-.105 2.083-.026 2.9.344 1.53.686 1.899 1.161 2.532 3.221l.553 1.822h1.055c2.373 0 3.323-.475 4.984-2.482 1.793-2.192 2.848-2.957 4.377-3.195 1.872-.291 2.69.053 4.693 1.98 2.057 2.007 3.376 2.799 5.221 3.143 1.398.237 1.53.158 2.004-1.321.686-2.112 3.191-3.67 5.88-3.67 2.347 0 4.694 1.479 4.694 2.957 0 1.057.659 2.483 1.266 2.826.685.37 2.109.37 3.137 0 .712-.238 2.163-1.769 4.483-4.674.897-1.136 4.456-1.241 5.643-.158.263.237.896 1.161 1.45 2.086.949 1.637 1.028 1.716 2.426 2.006.791.159 1.978.212 2.637.106 1.265-.185 1.687-.528 3.533-2.984 1.582-2.112 3.27-2.614 5.801-1.769.923.343 1.371.687 2.03 1.69 1.82 2.852 4.167 4.146 6.223 3.433 1.029-.37 1.213-.608 2.136-2.694.554-1.267 2.241-2.271 4.114-2.482 2.9-.29 5.379 1.136 5.669 3.275.079.633.29 1.241.448 1.346.158.132 1.16.502 2.215.819 1.028.317 1.898.686 1.898.845 0 .158.264.238.607.185.501-.079.606-.291.765-1.505.316-2.773 2.926-5.044 5.721-5.044 1.873 0 2.453.449 3.006 2.192.871 2.72 2.795 4.145 5.59 4.145 1.82 0 2.215-.211 2.4-1.293.527-2.984 4.298-5.704 7.172-5.176 1.213.211 3.032 2.06 3.744 3.723.317.713.844 1.373 1.371 1.69 1.846 1.136 3.613 1.901 4.008 1.769.238-.105.449-.66.554-1.425.317-2.535 1.793-4.542 3.771-5.097 1.292-.343 3.902-.343 4.614.026 1.081.555 2.347 1.955 3.006 3.354.712 1.532 1.609 2.086 3.771 2.35 1.318.159 1.318.159 2.531-2.772.554-1.374 2.057-2.773 3.402-3.222 2.109-.687 5.273.343 6.012 1.954.211.449.448 1.584.553 2.509.185 1.927.897 3.274 2.004 3.855 1.477.766 1.714.607 3.217-2.324 1.556-2.984 3.771-5.571 5.089-5.888 1.002-.238 4.483.237 5.063.713.237.211.738 1.082 1.134 1.954.949 2.112 1.898 3.168 3.296 3.697 1.371.528 2.294.369 2.689-.449 1.978-4.252 2.189-4.595 3.27-5.308 1.609-1.03 3.665-1.003 5.643.053 1.872 1.003 2.505.871 2.505-.555 0-1.478-.844-2.904-2.321-3.961-1.16-.845-1.318-1.109-1.872-2.931-.553-1.927-.58-2.086-.184-3.433.527-1.795 1.45-2.667 3.876-3.591l1.951-.739.079-1.4c.106-1.954-.237-2.588-2.452-4.462-2.189-1.822-2.927-2.879-3.191-4.41-.184-1.215.238-2.984.897-3.803.29-.343 1.477-.95 2.848-1.426 2.795-1.003 2.9-1.267 1.74-3.881-.686-1.479-1.028-1.902-2.663-3.116-1.24-.925-2.083-1.796-2.452-2.483-.607-1.241-.791-3.248-.422-4.647.342-1.241 1.793-2.561 3.19-2.957 2.742-.74 2.637-.634 2.452-2.588-.079-.951-.158-2.271-.158-2.905 0-1.135-.079-1.268-2.505-3.618l-2.505-2.429v-1.981c0-1.927.027-2.006.923-2.799 1.081-.95 2.611-1.426 4.694-1.426 1.635 0 1.872-.316 1.107-1.346-.211-.291-.395-.951-.395-1.479 0-1.32-1.055-2.773-2.294-3.195-3.059-1.004-4.562-2.852-4.562-5.651 0-2.984 1.582-4.727 4.483-4.991 1.713-.158 2.214-.528 2.003-1.558-.263-1.241-1.529-3.882-1.872-3.882-.501 0-3.006-2.799-3.48-3.881-.238-.581-.475-2.086-.554-3.539-.132-2.957-.105-2.984 2.769-3.961 1.845-.607 2.083-.871 2.346-2.799.317-2.456-.712-4.04-3.559-5.492-1.002-.502-1.371-.872-1.714-1.717-.87-2.165-.369-3.855 1.793-6.311 1.424-1.611 2.136-3.538 1.872-5.202-.132-.898-.475-1.531-1.503-2.693-2.69-3.09-3.27-5.017-2.215-7.394.58-1.267 1.714-1.928 4.166-2.429 2.505-.502 2.584-.634 2.373-4.437-.131-2.455-.29-3.3-.58-3.485-.211-.132-1.107-.264-2.004-.264-1.397 0-1.687-.079-2.294-.74-2.03-2.139-2.109-5.73-.105-7.895.29-.317 1.107-.792 1.819-1.03 1.45-.475 1.793-.951 1.793-2.456 0-1.769-.87-3.353-2.294-4.198-2.083-1.189-2.637-1.902-2.848-3.512-.237-1.822.211-3.565 1.134-4.569.739-.765 3.191-2.007 3.982-2.007.791 0 1.16-1.584.791-3.485-.396-1.981-1.213-3.01-2.742-3.407-2.875-.792-4.14-4.251-2.637-7.288.844-1.663 1.45-2.086 3.375-2.323.817-.106 1.661-.317 1.898-.502.66-.475.791-2.271.29-3.776-.369-1.083-.817-1.637-2.663-3.248-1.239-1.083-2.426-2.218-2.637-2.562-.263-.396-.395-1.294-.395-2.799 0-1.822.079-2.297.475-2.64.263-.264.553-.37.659-.291.343.344 2.083-.211 2.927-.977 1.424-1.241 1.74-3.802.712-5.73-.185-.37-1.134-.977-2.294-1.505-2.374-1.083-2.716-1.664-2.769-4.806-.079-3.037.976-5.096 2.61-5.096.976 0 2.374-.898 2.716-1.77.475-1.241.027-2.693-1.265-4.066-.633-.687-1.556-1.426-2.004-1.664-1.029-.475-1.846-1.875-2.268-3.908-.606-2.799.395-4.621 3.059-5.572 2.056-.74 3.243-2.27 3.243-4.172 0-1.003-.897-1.875-3.138-3.142-2.162-1.188-2.795-2.271-2.769-4.912 0-1.637.106-2.06.792-3.169.711-1.161.922-1.32 2.373-1.69 2.215-.58 2.979-1.214 2.979-2.376 0-.502-.211-1.505-.448-2.245-.475-1.346-.633-1.505-3.006-2.482-1.608-.66-2.004-1.347-2.373-4.093-.237-2.007-.237-2.43.184-3.485.264-.66.818-1.611 1.24-2.113.712-.792.923-.898 2.162-.898 2.162 0 2.268-.185 2.057-3.406-.185-2.403-.264-2.773-.818-3.222-.342-.264-.896-.501-1.265-.501-2.426 0-4.193-3.222-3.507-6.47.395-1.848.949-2.43 3.032-3.195 2.9-1.056 3.164-1.505 2.347-3.882-.422-1.215-.844-1.716-3.797-4.357l-1.187-1.083-.079-2.878c-.079-2.693-.053-2.904.527-3.565.317-.37 1.424-1.162 2.453-1.716 2.294-1.294 2.953-2.35 2.452-3.908-.343-1.03-.659-1.294-3.692-3.142-1.239-.766-2.083-2.483-2.267-4.49-.106-1.478-.027-1.874.685-3.432l.844-1.743-.87-.343c-.448-.212-1.371-.45-2.03-.555-1.398-.211-1.714-.475-3.587-2.825-1.582-1.955-2.715-2.536-4.429-2.219-1.081.212-2.268 1.558-2.268 2.588 0 .898-1.266 2.007-2.769 2.482-1.608.476-2.346.476-4.034-.026-1.767-.528-3.138-1.716-3.481-3.063-.342-1.268-.949-1.558-3.217-1.532-2.135.027-2.795.317-3.005 1.215-.475 2.007-1.556 2.931-3.982 3.512-2.769.634-5.458-.555-6.46-2.878-.976-2.298-1.661-2.562-4.246-1.611-1.054.396-1.872 1.003-3.19 2.377-1.529 1.557-1.925 1.848-2.953 2.006-1.477.212-3.112-.026-4.114-.633-1.424-.845-3.058-4.093-2.768-5.546.079-.396-.027-1.03-.238-1.426-.448-.871-1.555-.977-2.927-.317Z" fill="#fff"/><path fill="#FEFEFF" d="M15 15h236v298H15z"/><path d="M82.25 133.477c7.792-4.808 23.709-14.785 25.045-16.227L129 133.477 114.975 147 82.25 133.477Z" fill="#E4A649"/><path d="m188.5 135.844-29.75-18.594-8.5 29.75 38.25-11.156Z" fill="#B5F42E"/><path d="m82.25 172.5 76.5-55.25L146 172.5H82.25Z" fill="#E6F15F"/><path d="M82.25 168.25v-34l34 12.143-34 21.857Z" fill="#BB3030"/><path d="m132.5 211-50.25-38.5h38.093L132.5 211Z" fill="#801ECD"/><path d="M188.5 172.5h-63.75l11.389 38.25L188.5 172.5Z" fill="#3116DA"/><path d="m146 172.5 7.391-26.171L188.5 134.25v38.25H146Z" fill="#42DA51"/><path d="m158.108 113-24.858 17.811L108.395 113 78 132.727v38.66L133.25 215l55.25-43.613v-38.66L158.108 113Zm-48.505 33.993-25.817 17.601v-26.182l25.817 8.581Zm23.647-8.969 20.223-14.492-11.4 43.615-51.896.188 43.03-29.34.043.029Zm26.806-16.763 18.898 12.265-24.293 8.376 5.395-20.641Zm-40.19 51.867 8.266 30.373-38.339-30.262 30.073-.111Zm5.998-.024 51.238-.183-42.218 33.326-9.02-33.143Zm56.847-6.107-34.643.129 4.804-18.379 29.839-10.29v28.54Zm-54.578-32.642-12.408 8.465-28.106-9.344 20.614-13.378 19.9 14.257Z" fill="#000"/><path fill="#3116DA" d="M15 15h31v31H15zM220 15h31v31h-31zM15 289h31v31H15zM220 289h31v31h-31z"/></g><defs><clipPath id="a"><path fill="#fff" d="M0 0h265v338H0z"/></clipPath></defs></svg>';
        parts[1] = "";
        string memory output = string(abi.encodePacked(parts[0], parts[1]));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Bag #',
                        toString(tokenId),
                        '", "description": "Love Letters descrption", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function viewPrice() public view returns (uint256) {
        return _price;
    }

    function startSale() public virtual onlyOwner {
        require(!saleStarted, "sale already started");
        emit SaleState(true);
        saleStarted = true;
    }

    function stopSale() public virtual onlyOwner {
        require(saleStarted, "not currently started");
        emit SaleState(false);
        saleStarted = false;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        payable(staffVaultAddress).transfer(balance);
    }

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
}