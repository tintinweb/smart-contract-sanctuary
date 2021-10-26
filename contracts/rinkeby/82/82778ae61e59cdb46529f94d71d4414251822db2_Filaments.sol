/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// File: contracts/AnonymiceLibrary.sol


pragma solidity ^0.8.0;

library AnonymiceLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
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
}
// File: @openzeppelin/contracts/utils/Strings.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: contracts/Filaments.sol

// contracts/Filaments.sol

pragma solidity ^0.8.0;




contract Filaments is ERC721Enumerable, Ownable {
    /*
  _   _   _   _   _   _   _   _   _  
 / \ / \ / \ / \ / \ / \ / \ / \ / \ 
( F | I | L | A | M | E | N | T | S )
 \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ 

credit 2 my mouse dev and 0xinuarashi for making amazing on chain project
that was used as the basis for this contract
*/
    using AnonymiceLibrary for uint8;

    struct Trait {
        string traitName;
        string traitType;
    }


    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(string => bool) hashToMinted;
    mapping(uint256 => string) internal tokenIdToHash;

    //uint256s
    uint256 MAX_SUPPLY = 500;
    uint256 SEED_NONCE = 0;
    
    //minting flag
    bool public MINTING_LIVE = false;

    //uint arrays
    uint16[][10] TIERS;
    
    //whitelist
    mapping (address => bool) public whitelist;

    //p5js url
    string p5jsUrl;
    string p5jsIntegrity;
    string imageUrl;
    string animationUrl;

    constructor() ERC721("Filaments", "FLMTS") {
        //Declare all the rarity tiers

        //Palette
        TIERS[0] = [100, 100, 100, 100, 100, 600, 600, 600, 600, 600, 600, 1000, 1000, 1000, 1300, 1600];
        //Border
        TIERS[1] = [2000, 8000];
        //Number of lines
        TIERS[2] = [1000, 1000, 1000, 7000];
        //Thickness of lines
        TIERS[3] = [100, 400, 500, 9000];
        //Pixel size
        TIERS[4] = [100, 9900];
        //Noise scale
        TIERS[5] = [100, 400, 500, 9000];
        //Noise strength
        TIERS[6] = [100, 400, 500, 9000];
        //Left or right
        TIERS[7] = [5000, 5000];
        //Speed
        TIERS[8] = [1000, 9000];
        //Number of pre-iterations
        TIERS[9] = [500, 500, 1000, 1000, 7000];
        
        whitelist[0x9ea04B953640223dbb8098ee89C28E7a3B448858] = true; // testnet
        whitelist[0xeD2cE70D9905F6Ee1Cb0Fdb43A56E6eA0aC3Be20] = true; // testnet
        whitelist[0x0EEfA7e7877aEb0ce0ffcED291f492458AAE19Eb] = true; // testnet
        whitelist[0x7e11D9126289466223314970955BD365C010487C] = true; // testnet
        whitelist[0xB6426fE150A197B790D86585132daB718dC19052] = true; // testnet
        whitelist[0x210540e2Da43e81077e45001408a63F3060c15e2] = true; // testnet
    }

    /*
  __  __ _     _   _             ___             _   _             
 |  \/  (_)_ _| |_(_)_ _  __ _  | __|  _ _ _  __| |_(_)___ _ _  ___
 | |\/| | | ' \  _| | ' \/ _` | | _| || | ' \/ _|  _| / _ \ ' \(_-<
 |_|  |_|_|_||_\__|_|_||_\__, | |_| \_,_|_||_\__|\__|_\___/_||_/__/
                         |___/                                     
   */

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (uint8)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    /**
     * @dev Generates a 11 digit hash from a tokenId, address, and random number.
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     * @param _c The custom nonce to be used within the hash.
     */
    function hash(
        uint256 _t,
        address _a,
        uint256 _c
    ) internal returns (string memory) {
        require(_c < 11);

        // This will generate a 11 character string.
        // The first 2 digits are the palette.
        string memory currentHash = "";

        for (uint8 i = 0; i < 10; i++) {
            SEED_NONCE++;
            uint16 _randinput = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            SEED_NONCE
                        )
                    )
                ) % 10000
            );
            
            if (i == 0) {
                uint8 rar = rarityGen(_randinput, i);
                if (rar > 9) {
                    currentHash = string(
                        abi.encodePacked(currentHash, rar.toString())
                    );
                } else {
                    currentHash = string(
                        abi.encodePacked(currentHash, "0", rar.toString())
                    );
                }
            } else {
                currentHash = string(
                    abi.encodePacked(currentHash, rarityGen(_randinput, i).toString())
                );
            }
        }

        if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1);

        return currentHash;
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal {
        require(MINTING_LIVE == true, "Minting is not live.");
        require(isWhitelisted(msg.sender), "Must be whitelisted and can only mint 1");
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY);
        require(!AnonymiceLibrary.isContract(msg.sender));
        
        whitelist[msg.sender] = false;

        uint256 thisTokenId = _totalSupply;

        tokenIdToHash[thisTokenId] = hash(thisTokenId, msg.sender, 0);

        hashToMinted[tokenIdToHash[thisTokenId]] = true;

        _mint(msg.sender, thisTokenId);
    }

    /**
     * @dev Mints new tokens.
     */
    function mintFilament() public {
        return mintInternal();
    }

    /*
 ____     ___   ____  ___        _____  __ __  ____     __ ______  ____  ___   ____   _____
|    \   /  _] /    ||   \      |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|  D  ) /  [_ |  o  ||    \     |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|    / |    _]|     ||  D  |    |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|    \ |   [_ |  _  ||     |    |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|  .  \|     ||  |  ||     |    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
|__|\_||_____||__|__||_____|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|
                                                                                           
*/
    
    /**
     * @dev Helper function to see if whitelisted
     */
    function isWhitelisted(address _wallet) internal returns (bool) {
        if (_wallet == owner()) {
            return true; // Owner
        }
        
        return whitelist[_wallet];
    }

    /**
     * @dev Hash to HTML function
     */
    function hashToHTML(string memory _hash, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory htmlString = string(
            abi.encodePacked(
                'data:text/html,%3Chtml%3E%3Chead%3E%3Cscript%20src%3D%22',
                p5jsUrl,
                '%22%20integrity%3D%22',
                p5jsIntegrity,
                '%22%20crossorigin%3D%22anonymous%22%3E%3C%2Fscript%3E%3C%2Fhead%3E%3Cbody%3E%3Cscript%3Evar%20tokenId%3D',
                AnonymiceLibrary.toString(_tokenId),
                '%3Bvar%20hash%3D%22',
                _hash
            )
        );

        htmlString = string(
            abi.encodePacked(
                htmlString,
                '%22%3Bfunction%20sdfsd%28t%29%7Breturn%20function%28%29%7Bvar%20e%3Dt%2B%3D1831565813%3Breturn%20e%3DMath.imul%28e%5Ee%3E%3E%3E15%2C1%7Ce%29%2C%28%28%28e%5E%3De%2BMath.imul%28e%5Ee%3E%3E%3E7%2C61%7Ce%29%29%5Ee%3E%3E%3E14%29%3E%3E%3E0%29%2F4294967296%7D%7Dfunction%20wraw%28t%29%7Bvar%20e%2Cr%3D%5B%5D%3Bfor%28e%3D0%3Be%3Ct.length%3Be%2B%2B%29r%5Be%5D%3Dt%5Be%5D.w1%2B%28r%5Be-1%5D%7C%7C0%29%3Bvar%20i%3Drand%28%29%2Ar%5Br.length-1%5D%3Bfor%28e%3D0%3Be%3Cr.length%26%26%21%28r%5Be%5D%3Ei%29%3Be%2B%2B%29%3Breturn%20t%5Be%5D%7Dfunction%20wrnd%28t%29%7Breturn%20wraw%28t%29.a1%7Dfunction%20gRI%28t%29%7Breturn%20Math.floor%28rand%28%29%2At%29%7Dfunction%20traitRaw%28t%2Ce%29%7Breturn%20e%3E%3Dt.length%3Ft%5Bt.length-1%5D%3At%5Be%5D%7Dfunction%20trait%28t%2Ce%29%7Breturn%20traitRaw%28t%2Ce%29.a1%7Dvar%20colors%2Cbgc%2Cc%2CdidStart%2Cimg%2Cwd%2Chei%2Cseed%2Crand%2Ctz0%2Ctz1%2Ctz2%2Ctz3%2Ctz4%2Ctz5%2Ctz6%2Ctz7%2Ctz8%2Ctz9%2Ctz10%2Cborder%2Cnum%2ClnThk%2CpxSz%2CnsScl%2CnsStr%2ClOr%2CnnUniS%2CisSUni%2Cspeed%2Czz%2Cptks%2CrunCount%2Ccanvas%2ColdWd%2ColdHei%3Bfunction%20hashToTraits%28t%29%7Bt%26%26%28tz0%3Dt.charAt%280%29%2Ctz1%3Dt.charAt%281%29%2Ctz2%3Dt.charAt%282%29%2Ctz3%3Dt.charAt%283%29%2Ctz4%3Dt.charAt%284%29%2Ctz5%3Dt.charAt%285%29%2Ctz6%3Dt.charAt%286%29%2Ctz7%3Dt.charAt%287%29%2Ctz8%3Dt.charAt%288%29%2Ctz9%3Dt.charAt%289%29%2Ctz10%3Dt.charAt%2810%29%2Ctz1%3DNumber%28tz0.toString%28%29%2Btz1.toString%28%29%29%29%7Dfunction%20setup%28%29%7Bseed%3DtokenId%2Ctz0%3D0%2Ctz1%3D7%2Ctz2%3D7%2Ctz3%3D7%2Ctz4%3D7%2Ctz5%3D7%2Ctz6%3D7%2Ctz7%3D7%2Ctz8%3D7%2Ctz9%3D7%2Ctz10%3D7%2Ctz1%3DNumber%28tz0.toString%28%29%2Btz1.toString%28%29%29%2ChashToTraits%28hash%29%2Crand%3Dsdfsd%28seed%29%2Cborder%3D0%3D%3Dtz2%3F20%3A0%3Bnum%3Dtrait%28%5B%7Ba1%3A1e3%2Cw1%3A10%7D%2C%7Ba1%3A500%2Cw1%3A10%7D%2C%7Ba1%3A250%2Cw1%3A10%7D%2C%7Ba1%3A100%2Cw1%3A70%7D%5D%2Ctz3%29%3BlnThk%3Dtrait%28%5B%7Ba1%3A40%2Cw1%3A1%7D%2C%7Ba1%3A30%2Cw1%3A4%7D%2C%7Ba1%3A10%2Cw1%3A5%7D%2C%7Ba1%3A20%2Cw1%3A90%7D%5D%2Ctz4%29%2CpxSz%3D0%3D%3Dtz5%3F20%3A10%3BnsScl%3Dtrait%28%5B%7Ba1%3A1e4%2Cw1%3A1%7D%2C%7Ba1%3A250%2Cw1%3A4%7D%2C%7Ba1%3A50%2Cw1%3A5%7D%2C%7Ba1%3A500%2Cw1%3A90%7D%5D%2Ctz6%29%3BnsStr%3Dtrait%28%5B%7Ba1%3A10%2Cw1%3A1%7D%2C%7Ba1%3A5%2Cw1%3A4%7D%2C%7Ba1%3A2%2Cw1%3A5%7D%2C%7Ba1%3A1%2Cw1%3A90%7D%5D%2Ctz7%29%2ClOr%3D0%3D%3Dtz8%3F-1%3A1%2CnnUniS%3Dfunction%28%29%7Breturn%20lOr%2A%283%2BgRI%283%29%29%7D%2Cspeed%3D%28isSUni%3D1%3D%3Dtz9%29%3F10%2AlOr%3AnnUniS%28%29%3Bzz%3Dtrait%28%5B%7Ba1%3A0%2Cw1%3A5%7D%2C%7Ba1%3A250%2Cw1%3A5%7D%2C%7Ba1%3A300%2Cw1%3A10%7D%2C%7Ba1%3A400%2Cw1%3A10%7D%2C%7Ba1%3A500%2Cw1%3A70%7D%5D%2Ctz10%29%2Cptks%3D%5Bnum%5D%2CrunCount%3D0%2Cwd%3DMath.min%28800%2CwindowWidth%29%2Chei%3DMath.min%28960%2CwindowHeight%29%2Cwd%3DMath.ceil%28wd%2FpxSz%29%2ApxSz%2Chei%3DMath.ceil%28hei%2FpxSz%29%2ApxSz%2CdidStart%3D%211%2CnoiseSeed%28seed%29%3Bvar%20t%3DtraitRaw%28%5B%7Ba1%3A%5B%28c%3Dcolor%29%28%22%23ffa4d5%22%29%2Cc%28%22%2383ffc1%22%29%2Cc%28%22%23ffe780%22%29%2Cc%28%22%2399e2ff%22%29%5D%2CbgColor%3Ac%28%22%23ffffff%22%29%2Cw1%3A1%7D%2C%7Ba1%3A%5Bc%28%22%23ffffff%22%29%2Cc%28%22%23000000%22%29%5D%2Cw1%3A1%7D%2C%7Ba1%3A%5Bc%28%22%23305e90%22%29%2Cc%28%22%23db4e54%22%29%2Cc%28%22%234f3c2d%22%29%2Cc%28%22%23ffbb12%22%29%2Cc%28%22%23389894%22%29%2Cc%28%22%23e0d8c5%22%29%2Cc%28%22%23c7e3d4%22%29%5D%2Cw1%3A1%2CbgColor%3Ac%28%22%23ffffff%22%29%7D%2C%7Ba1%3A%5Bc%28%22%230827f5%22%29%2Cc%28%22%233751f7%22%29%2Cc%28%22%238493fa%22%29%5D%2Cw1%3A1%7D%2C%7Ba1%3A%5Bc%28%22%2300c1ff%22%29%2Cc%28%22%230023ff%22%29%2Cc%28%22%237215ff%22%29%2Cc%28%22%23ff03fc%22%29%2Cc%28%22%23ff000a%22%29%2Cc%28%22%23ff8700%22%29%2Cc%28%22%23fff700%22%29%2Cc%28%22%235fff00%22%29%2Cc%28%22%2300ff2e%22%29%5D%2Cw1%3A1%2CbgColor%3Ac%28%22%23ffffff%22%29%7D%2C%7Ba1%3A%5Bc%28%22%2300e000%22%29%2Cc%28%22%23005900%22%29%2Cc%28%22%23000000%22%29%5D%2Cw1%3A5%7D%2C%7Ba1%3A%5Bc%28%22%23586049%22%29%2Cc%28%22%23575f47%22%29%2Cc%28%22%23b3b7ae%22%29%2Cc%28%22%23666f5c%22%29%5D%2Cw1%3A5%7D%2C%7Ba1%3A%5Bc%28%22%23fff69f%22%29%2Cc%28%22%23fdd870%22%29%2Cc%28%22%23d0902f%22%29%2Cc%28%22%23a15501%22%29%2Cc%28%22%23351409%22%29%5D%2Cw1%3A5%7D%2C%7Ba1%3A%5Bc%28%22%23a0ffe3%22%29%2Cc%28%22%2365dc98%22%29%2Cc%28%22%238d8980%22%29%2Cc%28%22%23575267%22%29%2Cc%28%22%23222035%22%29%5D%2Cw1%3A5%7D%2C%7Ba1%3A%5Bc%28%22%230099ff%22%29%2Cc%28%22%235655dd%22%29%2Cc%28%22%238822ff%22%29%2Cc%28%22%23aa99ff%22%29%5D%2Cw1%3A5%7D%2C%7Ba1%3A%5Bc%28%22%237700a6%22%29%2Cc%28%22%23fe00fe%22%29%2Cc%28%22%23defe47%22%29%2Cc%28%22%2300b3fe%22%29%2Cc%28%22%230016ee%22%29%5D%2Cw1%3A5%7D%2C%7Ba1%3A%5Bc%28%22%23c4ffff%22%29%2Cc%28%22%2308deea%22%29%2Cc%28%22%231261d1%22%29%5D%2Cw1%3A10%7D%2C%7Ba1%3A%5Bc%28%22%23ff124f%22%29%2Cc%28%22%23ff00a0%22%29%2Cc%28%22%23fe75fe%22%29%2Cc%28%22%237a04eb%22%29%2Cc%28%22%23120458%22%29%5D%2Cw1%3A10%7D%2C%7Ba1%3A%5Bc%28%22%23111111%22%29%2Cc%28%22%23222222%22%29%2Cc%28%22%23333333%22%29%2Cc%28%22%23444444%22%29%2Cc%28%22%23666666%22%29%5D%2Cw1%3A10%7D%2C%7Ba1%3A%5Bc%28%22%23f887ff%22%29%2Cc%28%22%23de004e%22%29%2Cc%28%22%23860029%22%29%2Cc%28%22%23321450%22%29%2Cc%28%22%2329132e%22%29%5D%2Cw1%3A15%7D%2C%7Ba1%3A%5Bc%28%22%238386f5%22%29%2Cc%28%22%233d43b4%22%29%2Cc%28%22%23041348%22%29%2Cc%28%22%23083e12%22%29%2Cc%28%22%231afe49%22%29%5D%2Cw1%3A20%7D%5D%2Ctz1%29%3Bcolors%3Dt.a1%2Cbgc%3Dc%28%22%23000000%22%29%2Ct.bgColor%26%26%28bgc%3Dt.bgColor%29%2C%28canvas%3DcreateCanvas%28wd%2Chei%29%29.doubleClicked%28toggleFullscreen%29%2CnoStroke%28%29%3Bfor%28let%20t%3D0%3Bt%3Cnum%3Bt%2B%2B%29%7Bvar%20e%3DcreateVector%28border%2BgRI%281.2%2A%28width-2%2Aborder%29%29%2Cborder%2BgRI%28height-2%2Aborder%29%2C2%29%2Cr%3DcreateVector%28cos%280%29%2Csin%280%29%29%3Bspeed%3DisSUni%3Fspeed%3AnnUniS%28%29%2Cptks%5Bt%5D%3Dnew%20Ptk%28e%2Cr%2Cspeed%29%7DframeRate%2810%29%7Dfunction%20remake%28t%2Ce%29%7Bt%3DMath.ceil%28t%2FpxSz%29%2ApxSz%2Ce%3DMath.ceil%28e%2FpxSz%29%2ApxSz%2Cwd%3Dt%2Chei%3De%2Cwidth%3Dt%2Cheight%3De%2C%28img%3DcreateImage%28Math.floor%28wd%2FpxSz%29%2CMath.floor%28hei%2FpxSz%29%29%29.loadPixels%28%29%2CresizeCanvas%28t%2Ce%29%3Bfor%28let%20t%3D0%3Bt%3Czz%3Bt%2B%2B%29%7Bfor%28let%20t%3D0%3Bt%3Cptks.length%3Bt%2B%2B%29ptks%5Bt%5D.run%28%29%3BrunCount%2B%2B%7D%7Dfunction%20toggleFullscreen%28%29%7Blet%20t%3Ddocument.querySelector%28%22canvas%22%29%3Bdocument.fullscreenElement%3Fdocument.exitFullscreen%28%29%3A%28oldWd%3Dwd%2ColdHei%3Dhei%2Cremake%28800%2C960%29%2Ct.requestFullscreen%28%29.catch%28t%3D%3E%7Balert%28%60Error%3A%20%24%7Bt.message%7D%20%28%24%7Bt.name%7D%29%60%29%7D%29%29%7Dfunction%20keyPressed%28%29%7Breturn%2070%3D%3D%3DkeyCode%3F%28remake%281500%2C500%29%2C%211%29%3A88%3D%3D%3DkeyCode%3F%28remake%28prompt%28%22Enter%20width%20in%20pixels%22%2C%22500%22%29%2Cprompt%28%22Height%3F%22%2C%22500%22%29%29%2C%211%29%3A79%3D%3D%3DkeyCode%3F%28toggleFullscreen%28%29%2C%211%29%3Avoid%200%7Dfunction%20draw%28%29%7Bif%28%21didStart%29%7Bfor%28let%20t%3D0%3Bt%3Czz%3Bt%2B%2B%29%7Bfor%28let%20t%3D0%3Bt%3Cptks.length%3Bt%2B%2B%29ptks%5Bt%5D.run%28%29%3BrunCount%2B%2B%7DdidStart%3D%210%7Dfor%28let%20t%3D0%3Bt%3Cptks.length%3Bt%2B%2B%29ptks%5Bt%5D.run%28%29%3BrunCount%2B%2B%2C%28img%3DcreateImage%28wd%2FpxSz%2Chei%2FpxSz%29%29.loadPixels%28%29%3Bfor%28var%20t%3D0%3Bt%3Cimg.height%3Bt%2B%2B%29for%28var%20e%3D0%3Be%3Cimg.width%3Be%2B%2B%29%7Blet%20r%3Dget%28e%2ApxSz%2Ct%2ApxSz%29%2Ci%3D4%2A%28e%2Bt%2Aimg.width%29%3Bimg.pixels%5Bi%5D%3Dred%28r%29%2Cimg.pixels%5Bi%2B1%5D%3Dgreen%28r%29%2Cimg.pixels%5Bi%2B2%5D%3Dblue%28r%29%2Cimg.pixels%5Bi%2B3%5D%3Dalpha%28r%29%7Dfill%28bgc%29%2Crect%280%2C0%2Cwidth%2Cheight%29%2Cimg.updatePixels%28%29%2CnoSmooth%28%29%2Cimage%28img%2C0%2C0%2Cwidth%2Cheight%29%2Cfill%28bgc%29%2Crect%280%2C0%2Cborder%2Cheight%29%2Crect%280%2C0%2Cwidth%2Cborder%29%2Crect%28width-border%2C0%2Cborder%2Cheight%29%2Crect%280%2Cheight-border%2Cwidth%2Cborder%29%7Dclass%20Ptk%7Bconstructor%28t%2Ce%2Cr%29%7Bthis.loc%3Dt%2Cthis.dir%3De%2Cthis.speed%3Dr%2Cthis.c%3Dcolors%5BgRI%28colors.length%29%5D%2Cthis.lineSize%3DlnThk%7Drun%28%29%7Bthis.move%28%29%2Cthis.checkEdges%28%29%2Cthis.update%28%29%7Dmove%28%29%7Blet%20t%3Dnoise%28this.loc.x%2FnsScl%2Cthis.loc.y%2FnsScl%2CrunCount%2FnsScl%29%2ATWO_PI%2AnsStr%3Bthis.dir.x%3Dcos%28t%29%2Cthis.dir.y%3Dsin%28t%29%3Bvar%20e%3Dthis.dir.copy%28%29%3Be.mult%281%2Athis.speed%29%2Cthis.loc.add%28e%29%7DcheckEdges%28%29%7B%28this.loc.x%3Cborder%7C%7Cthis.loc.x%3Ewidth-border%7C%7Cthis.loc.y%3Cborder%7C%7Cthis.loc.y%3Eheight-border%29%26%26%28this.loc.x%3Dborder%2BgRI%28width-2%2Aborder%29%2Cthis.loc.y%3Dborder%2BgRI%28height-2%2Aborder%29%29%7Dupdate%28%29%7Bfill%28this.c%29%2Cellipse%28this.loc.x%2Cthis.loc.y%2Cthis.lineSize%2Cthis.lineSize%29%7D%7D%3C%2Fscript%3E%3C%2Fbody%3E%3C%2Fhtml%3E'
            )
        );

        return htmlString;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {
        string memory metadataString;
        
        uint8 paletteTraitIndex = AnonymiceLibrary.parseInt(
            AnonymiceLibrary.substring(_hash, 0, 2)
        );

        metadataString = string(
            abi.encodePacked(
                metadataString,
                '{"trait_type":"',
                traitTypes[0][paletteTraitIndex].traitType,
                '","value":"',
                traitTypes[0][paletteTraitIndex].traitName,
                '"},'
            )
        );

        for (uint8 i = 2; i < 11; i++) {
            uint8 thisTraitIndex = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, i, i + 1)
            );

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitTypes[i][thisTraitIndex].traitType,
                    '","value":"',
                    traitTypes[i][thisTraitIndex].traitName,
                    '"}'
                )
            );

            if (i != 10)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        string memory tokenHash = _tokenIdToHash(_tokenId);
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Filaments #',
                                    AnonymiceLibrary.toString(_tokenId),
                                    '", "description": "Filaments is a collection of 500 unique pieces of generative pixel art. All the metadata and art is mirrored permanently on-chain.",',
                                    '"animation_url": "',
                                    animationUrl,
                                    AnonymiceLibrary.toString(_tokenId),
                                    '","image":"',
                                    imageUrl,
                                    AnonymiceLibrary.toString(_tokenId),
                                    '","attributes":',
                                    hashToMetadata(tokenHash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */
    function _tokenIdToHash(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory tokenHash = tokenIdToHash[_tokenId];

        return tokenHash;
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    /*

  ___   __    __  ____     ___  ____       _____  __ __  ____     __ ______  ____  ___   ____   _____
 /   \ |  |__|  ||    \   /  _]|    \     |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|     ||  |  |  ||  _  | /  [_ |  D  )    |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|  O  ||  |  |  ||  |  ||    _]|    /     |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|     ||  `  '  ||  |  ||   [_ |    \     |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|     | \      / |  |  ||     ||  .  \    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
 \___/   \_/\_/  |__|__||_____||__|\_|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|
                                                                                                     


    */
    
    /**
     * @dev Clears the traits.
     */
    function clearTraits() public onlyOwner {
        for (uint256 i = 0; i < 11; i++) {
            delete traitTypes[i];
        }
    }

    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(
                    traits[i].traitName,
                    traits[i].traitType
                )
            );
        }

        return;
    }
    
    /**
     * @dev Mint for burn internal
     */
    function ownerMintForBurnInternal() internal {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY);
        require(!AnonymiceLibrary.isContract(msg.sender));

        uint256 thisTokenId = _totalSupply;

        tokenIdToHash[thisTokenId] = hash(thisTokenId, msg.sender, 0);

        hashToMinted[tokenIdToHash[thisTokenId]] = true;

        _mint(0x000000000000000000000000000000000000dEaD, thisTokenId);
    }

    /**
     * @dev Mints new tokens.
     */
    function ownerMintForBurn() public onlyOwner {
        return ownerMintForBurnInternal();
    }
    
    /**
     * @dev Mints new tokens.
     */
    function mintDev(uint8 _amount) public onlyOwner {
        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }
    
    function flipMintingSwitch() public onlyOwner {
        MINTING_LIVE = !MINTING_LIVE;
    }

    /**
     * @dev Sets the p5js url
     * @param _p5jsUrl The address of the p5js file hosted on CDN
     */

    function setJsAddress(string memory _p5jsUrl) public onlyOwner {
        p5jsUrl = _p5jsUrl;
    }

    /**
     * @dev Sets the p5js resource integrity
     * @param _p5jsIntegrity The hash of the p5js file (to protect w subresource integrity)
     */

    function setJsIntegrity(string memory _p5jsIntegrity) public onlyOwner {
        p5jsIntegrity = _p5jsIntegrity;
    }
    
    /**
     * @dev Sets the base image url
     * @param _imageUrl The base url for image field
     */

    function setImageUrl(string memory _imageUrl) public onlyOwner {
        imageUrl = _imageUrl;
    }
    
    /**
     * @dev Sets the base animation url
     * @param _animationUrl The base url for animations
     */

    function setAnimationUrl(string memory _animationUrl) public onlyOwner {
        animationUrl = _animationUrl;
    }
}