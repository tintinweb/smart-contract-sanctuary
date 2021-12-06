/**
 *Submitted for verification at Etherscan.io on 2021-12-06
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

// File: contracts/interfaces/IAxons.sol



/// @title Interface for Axons

pragma solidity ^0.8.6;


interface IAxons is IERC721Enumerable {
    event AxonCreated(uint256 indexed tokenId);
    
    event AxonBurned(uint256 indexed tokenId);

    event MinterUpdated(address minter);

    event MinterLocked();

    function mint(uint256 axonId) external returns (uint256);
    
    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setMinter(address minter) external;

    function lockMinter() external;
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

// File: contracts/Axons.sol

// contracts/Axons.sol

pragma solidity ^0.8.0;





contract Axons is IAxons, ERC721Enumerable, Ownable {
    /*
  _   _   _   _   _
 / \ / \ / \ / \ / \
( A | X | O | N | S |
 \_/ \_/ \_/ \_/ \_/

credit to mouse dev and 0xinuarashi for making amazing on chain project with Anonymice
that was used as the basis for Filaments and this contract
*/
    using AnonymiceLibrary for uint8;

    // An address who has permissions to mint Axons
    address public minter;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash = '';

    //Mappings
    mapping(uint256 => bool) internal axonNumberToMinted;
    mapping(uint256 => uint256) internal tokenIdToNumber;

    //p5js url
    string p5jsUrl = 'https%3A%2F%2Fcdnjs.cloudflare.com%2Fajax%2Flibs%2Fp5.js%2F1.4.0%2Fp5.js';
    string p5jsIntegrity = 'sha256-maU2GxaUCz5WChkAGR40nt9sbWRPEfF8qo%2FprxhoKPQ%3D';
    string imageUrl = 'https://axons.art/api/axons/image/';
    string animationUrl = 'ipfs://QmepMLoRLNUX2ratx24a12oQFuRhLsgMhM6ni3HfMzK3Fu?x=';

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'Minter is locked');
        _;
    }

    constructor() ERC721("Axons", "AXONS") {
    }

    /*
  __  __ _     _   _             ___             _   _             
 |  \/  (_)_ _| |_(_)_ _  __ _  | __|  _ _ _  __| |_(_)___ _ _  ___
 | |\/| | | ' \  _| | ' \/ _` | | _| || | ' \/ _|  _| / _ \ ' \(_-<
 |_|  |_|_|_||_\__|_|_||_\__, | |_| \_,_|_||_\__|\__|_\___/_||_/__/
                         |___/                                     
   */

   /**
     * @dev Generates a random axon number
     * @param _a The address to be used within the hash.
     */
    function randomAxonNumber(
        address _a,
        uint256 _c
    ) internal returns (uint256) {
        uint256 _rand = uint256(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        _a,
                        _c
                    )
                )
            ) % 900719925474000
        );

        if (axonNumberToMinted[_rand]) return randomAxonNumber(_a, _c + 1);

        return _rand;
    }
    
    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }

    /**
     * @dev Mints new tokens.
     */
    function mint(uint256 axonId) public override onlyMinter returns (uint256) {
        if (totalSupply() <= 1830 && totalSupply() % 30 == 0 && totalSupply() > 0) {
            _mintTo(owner(), randomAxonNumber(msg.sender, 1000)); // Mint every 30th Axon to creator
        }

        return _mintTo(msg.sender, axonId);
    }

    function _mintTo(address to, uint256 axonId) internal returns (uint256) {
        uint256 thisTokenId = totalSupply();

        tokenIdToNumber[thisTokenId] = axonId;

        axonNumberToMinted[tokenIdToNumber[thisTokenId]] = true;

        _mint(to, thisTokenId);
        
        return thisTokenId;
    }
    
    /**
     * @notice Burn an axon.
     */
    function burn(uint256 axonId) public override onlyMinter {
        _burn(axonId);
        emit AxonBurned(axonId);
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
    * @notice The IPFS URI of contract-level metadata.
    */
    function contractURI() public view returns (string memory) {
       return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @dev Number to HTML function
     */
    function dataURI(uint256 _tokenId)
        public override
        view
        returns (string memory)
    {
        require(_exists(_tokenId));
        uint256 axonNumber = tokenIdToNumber[_tokenId];

        string memory htmlString = string(
            abi.encodePacked(
                'data:text/html,%3Chtml%3E%3Chead%3E%3Cscript%20src%3D%22',
                p5jsUrl,
                '%22%20integrity%3D%22',
                p5jsIntegrity,
                '%22%20crossorigin%3D%22anonymous%22%3E%3C%2Fscript%3E%3Cstyle%3Ehtml%7Bheight%3A100%25%3Boverflow%3Ahidden%7Dbody%7Bmin-height%3A100%25%3Bmargin%3A0%3Bpadding%3A0%3Boverflow%3Ahidden%3Bbackground-color%3A%23111%7Dcanvas%7Bpadding%3A0%3Bmargin%3Aauto%3Bdisplay%3Ablock%3Bposition%3Aabsolute%3Btop%3A0%3Bbottom%3A0%3Bleft%3A0%3Bright%3A0%3Bimage-rendering%3Apixelated%7D%3C%2Fstyle%3E%3Cmeta%20charset%3D%22utf-8%22%3E%3C%2Fhead%3E%3Cbody%3E%3Cscript%3Evar%20gs%3DparseInt%28',
                AnonymiceLibrary.toString(axonNumber),
                '%29%3Bclass%20Mx%7Bconstructor%28t%2Cr%29%7Bthis.rZ%3Dt%2Cthis.cols%3Dr%2Cthis.data%3DArray%28this.rZ%29.fill%28%29.map%28%28%28%29%3D%3EArray%28this.cols%29.fill%280%29%29%29%7Dcopy%28%29%7Blet%20t%3Dnew%20Mx%28this.rZ%2Cthis.cols%29%3Bfor%28let%20r%3D0%3Br%3Cthis.rZ%3Br%2B%2B%29for%28let%20s%3D0%3Bs%3Cthis.cols%3Bs%2B%2B%29t.data%5Br%5D%5Bs%5D%3Dthis.data%5Br%5D%5Bs%5D%3Breturn%20t%7Dstatic%20fromArray%28t%29%7Breturn%20new%20Mx%28t.length%2C1%29.map%28%28%28r%2Cs%29%3D%3Et%5Bs%5D%29%29%7Dstatic%20subtract%28t%2Cr%29%7Bif%28t.rZ%3D%3D%3Dr.rZ%26%26t.cols%3D%3D%3Dr.cols%29return%20new%20Mx%28t.rZ%2Ct.cols%29.map%28%28%28s%2Ca%2Ci%29%3D%3Et.data%5Ba%5D%5Bi%5D-r.data%5Ba%5D%5Bi%5D%29%29%7DtoArray%28%29%7Blet%20t%3D%5B%5D%3Bfor%28let%20r%3D0%3Br%3Cthis.rZ%3Br%2B%2B%29for%28let%20s%3D0%3Bs%3Cthis.cols%3Bs%2B%2B%29t.push%28this.data%5Br%5D%5Bs%5D%29%3Breturn%20t%7Drdz%28%29%7Breturn%20this.map%28%28t%3D%3E2%2Arng%28%29-1%29%29%7Dadd%28t%29%7Bif%28t%20instanceof%20Mx%29%7Bif%28this.rZ%21%3D%3Dt.rZ%7C%7Cthis.cols%21%3D%3Dt.cols%29return%3Breturn%20this.map%28%28%28r%2Cs%2Ca%29%3D%3Er%2Bt.data%5Bs%5D%5Ba%5D%29%29%7Dreturn%20this.map%28%28r%3D%3Er%2Bt%29%29%7Dstatic%20trp%28t%29%7Breturn%20new%20Mx%28t.cols%2Ct.rZ%29.map%28%28%28r%2Cs%2Ca%29%3D%3Et.data%5Ba%5D%5Bs%5D%29%29%7Dstatic%20mtp%28t%2Cr%29%7Bif%28t.cols%3D%3D%3Dr.rZ%29return%20new%20Mx%28t.rZ%2Cr.cols%29.map%28%28%28s%2Ca%2Ci%29%3D%3E%7Blet%20o%3D0%3Bfor%28let%20s%3D0%3Bs%3Ct.cols%3Bs%2B%2B%29o%2B%3Dt.data%5Ba%5D%5Bs%5D%2Ar.data%5Bs%5D%5Bi%5D%3Breturn%20o%7D%29%29%7Dmtp%28t%29%7Bif%28t%20instanceof%20Mx%29%7Bif%28this.rZ%21%3D%3Dt.rZ%7C%7Cthis.cols%21%3D%3Dt.cols%29return%3Breturn%20this.map%28%28%28r%2Cs%2Ca%29%3D%3Er%2At.data%5Bs%5D%5Ba%5D%29%29%7Dreturn%20this.map%28%28r%3D%3Er%2At%29%29%7Dmap%28t%29%7Bfor%28let%20r%3D0%3Br%3Cthis.rZ%3Br%2B%2B%29for%28let%20s%3D0%3Bs%3Cthis.cols%3Bs%2B%2B%29%7Blet%20a%3Dthis.data%5Br%5D%5Bs%5D%3Bthis.data%5Br%5D%5Bs%5D%3Dt%28a%2Cr%2Cs%29%7Dreturn%20this%7Dstatic%20map%28t%2Cr%29%7Breturn%20new%20Mx%28t.rZ%2Ct.cols%29.map%28%28%28s%2Ca%2Ci%29%3D%3Er%28t.data%5Ba%5D%5Bi%5D%2Ca%2Ci%29%29%29%7Dserialize%28%29%7Breturn%20JSON.stringify%28this%29%7Dstatic%20dsr%28t%29%7B%22string%22%3D%3Dtypeof%20t%26%26%28t%3DJSON.parse%28t%29%29%3Blet%20r%3Dnew%20Mx%28t.rZ%2Ct.cols%29%3Breturn%20r.data%3Dt.data%2Cr%7D%7D%22undefined%22%21%3Dtypeof%20module%26%26%28module.exports%3DMx%29%3C%2Fscript%3E%3Cscript%3Eclass%20AAF%7Bconstructor%28i%2Ct%29%7Bthis.func%3Di%2Cthis.dfunc%3Dt%7D%7Dlet%20sigmoid%3Dnew%20AAF%28%28i%3D%3E1%2F%281%2BMath.exp%28-i%29%29%29%2C%28i%3D%3Ei%2A%281-i%29%29%29%3Bclass%20NNN%7Bconstructor%28i%2Ct%2Cs%29%7B%28this.seed%3Dgs%2Crng%3Dsrand%28this.seed%29%2Cthis.i_n%3Di%2Cthis.h_n%3Dt%2Cthis.o_n%3Ds%2Cthis.w_hi%3Dnew%20Mx%28this.h_n%2Cthis.i_n%29%2Cthis.w_ho%3Dnew%20Mx%28this.o_n%2Cthis.h_n%29%2Cthis.w_hi.rdz%28%29%2Cthis.w_ho.rdz%28%29%2Cthis.bias_h%3Dnew%20Mx%28this.h_n%2C1%29%2Cthis.bias_o%3Dnew%20Mx%28this.o_n%2C1%29%2Cthis.bias_h.rdz%28%29%2Cthis.bias_o.rdz%28%29%29%2Cthis.setLearningRate%28%29%2Cthis.setAAF%28%29%7Dpredict%28i%29%7Blet%20t%3DMx.fromArray%28i%29%2Cs%3DMx.mtp%28this.w_hi%2Ct%29%3Bs.add%28this.bias_h%29%2Cs.map%28this.a_f.func%29%3Blet%20e%3DMx.mtp%28this.w_ho%2Cs%29%3Breturn%20e.add%28this.bias_o%29%2Ce.map%28this.a_f.func%29%2Ce.toArray%28%29%7DsetLearningRate%28i%3D.1%29%7Bthis.l_r%3Di%7DsetAAF%28i%3Dsigmoid%29%7Bthis.a_f%3Di%7Dserialize%28%29%7Breturn%20JSON.stringify%28this%29%7Dstatic%20dsr%28i%29%7B%22string%22%3D%3Dtypeof%20i%26%26%28i%3DJSON.parse%28i%29%29%3Blet%20t%3Dnew%20NNN%28i.i_n%2Ci.h_n%2Ci.o_n%29%3Breturn%20t.w_hi%3DMx.dsr%28i.w_hi%29%2Ct.w_ho%3DMx.dsr%28i.w_ho%29%2Ct.bias_h%3DMx.dsr%28i.bias_h%29%2Ct.bias_o%3DMx.dsr%28i.bias_o%29%2Ct.l_r%3Di.l_r%2Ct%7Dcopy%28%29%7Breturn%20new%20NNN%28this%29%7DmtT%28i%29%7Bfunction%20t%28t%29%7Breturn%20rng%28%29%3Ci%3Ft%2BrandomGaussian%280%2C.1%29%3At%7Dthis.w_hi.map%28t%29%2Cthis.w_ho.map%28t%29%2Cthis.bias_h.map%28t%29%2Cthis.bias_o.map%28t%29%7D%7D%3C%2Fscript%3E%3Cscript%3Eclass%20Art%7Bconstructor%28t%29%7Bthis.score%3D0%2Cthis.fitness%3D0%2Cthis.frame%3D0%2Cthis.rate%3D1%2Cthis.brain%3Dt%3Ft.copy%28%29%3Anew%20NNN%281%2C8%2C38%29%7DcvC%28t%2Cr%2Ce%29%7Breturn%5BMath.round%28255%2At%5B0%5D%2B.35%2Ar%2Athis.ouT%5B35%5D%29%2CMath.round%28255%2At%5B1%5D%2B.35%2Ar%2Athis.ouT%5B36%5D%29%2CMath.round%28255%2At%5B2%5D%29%2B.35%2Ar%2Athis.ouT%5B37%5D%5D%7DgCN%28t%2Cr%2Ce%29%7Bt%25%3D35%2Ct%3DMath.round%28%28Math.sin%28t%29%2B1%29%2F2%2A55%29-1%2Cthis.brain.seed%253%3D%3D0%3Ft%3D-1%2AMath.abs%28t%29%3Athis.brain.seed%253%3D%3D1%26%26%28t%3DMath.abs%28t%29%29%3Breturn%20this.ouT%5B6%2B3%2At%5D%3F%5Bthis.ouT%5B6%2B3%2At%5D%2Cthis.ouT%5B6%2B4%2At%5D%2Cthis.ouT%5B6%2B5%2At%5D%5D%3A%5B-1%2C-1%2C-1%5D%7Dshow%28t%2Cr%2Ce%29%7BpF%7C%7C%28pF%3Dcolor%280%29%2Cfill%28pF%29%29%3Bvar%20i%2Cn%3D0%2BMath.round%285%2Athis.ouT%5B0%5D%29%2Ca%3DMath.max%28this.ouT%5B1%5D%2B3e-7%2At%2C.01%29%2At%2F12%2Cs%3DMath.max%28this.ouT%5B2%5D%2B3e-7%2Ar%2C.01%29%2Ar%2F12%2Co%3D12e3%2Athis.ouT%5B4%5D%2B%281-8e3%2Athis.ouT%5B3%5D%29%2Cu%3DMath.round%28a%2Ao%2Bs%2A%281-o%29%2An%29%2Ch%3Dthis.gCN%28u%29%3B-1%3D%3Dh%5B0%5D%3Fthis.cf%3DpF%3A%28i%3Dthis.cvC%28h%2Ct%2Cr%29%2CdrawingContext.fillStyle%3D%22rgb%28%22%2Bi%5B0%5D%2B%22%2C%22%2Bi%5B1%5D%2B%22%2C%22%2Bi%5B2%5D%2B%22%29%22%2Cthis.cf%3Di%2C%22rgba%280%2C%200%2C%200%2C%200.00%29%22%3D%3D%3DdrawingContext.fillStyle%3F%28drawingContext.fillStyle%3D%60rgb%28%24%7BpF%5B0%5D%7D%2C%20%24%7BpF%5B1%5D%7D%2C%20%24%7BpF%5B2%5D%7D%29%60%2Cthis.cf%3DpF%29%3ApF%3Di%29%3Blet%20l%3D4%2A%28r%2Ae%2Awidth%2Bt%2Ae%29%2Cc%3D%5Bpixels%5Bl%5D%2Cpixels%5Bl%2B1%5D%2Cpixels%5Bl%2B2%5D%2Cpixels%5Bl%2B3%5D%5D%3Bc%5B0%5D%3D%3Dthis.cf%5B0%5D%26%26c%5B1%5D%3D%3Dthis.cf%5B1%5D%26%26c%5B2%5D%3D%3Dthis.cf%5B2%5D%7C%7CdrawingContext.fillRect%28t%2Ae%2Cr%2Ae%2Ce%2Ce%29%7DmtT%28%29%7Bthis.brain.mtT%28.9%29%7Dthink%28%29%7Bthis.frame%2B%3Dthis.rate%2C5e-6%2Athis.frame%3E15%26%26%28this.frame%3D-5%2CcrA.brain.mtT%28.9%29%29%3Blet%20t%3D%5B%5D%3Bt%5B0%5D%3D5e-6%2Athis.frame-5%3Blet%20r%3Dthis.brain.predict%28t%29%3Bthis.ouT%3Dr%7Dupdate%28%29%7Bthis.score%2B%2B%7D%7Dvar%20pF%3Bfunction%20pickOne%28%29%7Blet%20t%3D0%2Cr%3Drandom%281%29%3Bfor%28%3Br%3E0%3B%29r-%3DsvA%5Bt%5D.fitness%2Ct%2B%2B%3Bt--%3Blet%20e%3DsvA%5Bt%5D%2Ci%3Dnew%20Art%28e.brain%29%3Breturn%20i.mtT%28%29%2Ci%7Dfunction%20ccF%28%29%7Blet%20t%3D0%3Bfor%28let%20r%20of%20svA%29t%2B%3Dr.score%3Bfor%28let%20r%20of%20svA%29r.fitness%3Dr.score%2Ft%7Dfunction%20srand%28t%29%7Breturn%20function%28%29%7Bvar%20r%3Dt%2B%3D1831565813%3Breturn%20r%3DMath.imul%28r%5Er%3E%3E%3E15%2C1%7Cr%29%2C%28%28%28r%5E%3Dr%2BMath.imul%28r%5Er%3E%3E%3E7%2C61%7Cr%29%29%5Er%3E%3E%3E14%29%3E%3E%3E0%29%2F4294967296%7D%7Dconst%20TOTAL%3D10%3Blet%20crA%2ClastFill%2Crng%2Carts%3D%5B%5D%2CsvA%3D%5B%5D%2Ccnt%3D0%2CartIndex%3D0%3Bvar%20pS%3D5%2Ccol%3D%22black%22%3Bfunction%20windowResized%28%29%7BpS%3DMath.max%28Math.round%28Math.min%281e3%2CwindowWidth%29%2F200%29%2C3%29%2CresizeCanvas%28Math.min%281e3%2CMath.max%28windowWidth%2C500%29%29%2CMath.min%281e3%2CMath.max%28windowHeight%2C500%29%29%29%7Dfunction%20setup%28%29%7BpixelDensity%281%29%2CcolorMode%28RGB%29%2CcreateCanvas%28Math.min%281e3%2CMath.max%28windowWidth%2C500%29%29%2CMath.min%281e3%2CMath.max%28windowHeight%2C500%29%29%29%2CpS%3DMath.max%28Math.round%28Math.min%281e3%2CwindowWidth%29%2F200%29%2C3%29%3Bfor%28var%20t%3D0%3Bt%3CTOTAL%3Bt%2B%2B%29arts.push%28new%20Art%29%3BframeRate%2810%29%2CnextArt%28%29%7Dfunction%20nextArt%28%29%7BcrA%3Darts.shift%28%29%2CcrA.update%28%29%2Cconsole.log%28btoa%28crA.brain.seed%29%29%2Credraw%28%29%7Dfunction%20draw%28%29%7BnoStroke%28%29%2CloadPixels%28%29%2CcrA.think%28%29%3Bfor%28var%20t%3D0%3Bt%3Cheight%2FpS%3Bt%2B%2B%29for%28var%20r%3D0%3Br%3Cwidth%2FpS%3Br%2B%2B%29crA.show%28r%2Ct%2CpS%29%7Dfunction%20keyPressed%28%29%7B%22z%22%3D%3D%3Dkey%26%26crA.brain.mtT%28.1%29%2C%22d%22%3D%3D%3Dkey%26%26crA.rate%2B%2B%2C%22a%22%3D%3D%3Dkey%26%26crA.rate--%7D%3C%2Fscript%3E%3C%2Fbody%3E%3C%2Fhtml%3E'
            )
        );

        return htmlString;
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
        
        string memory description = '", "description": "Axons is an infinite collection of generative pixel art, looking into the mind of a neural network (thus, no distinct traits can be distilled). A new Axon is chosen and auctioned on-chain daily based on decentralized community voting. Art is mirrored permanently on-chain. Auctions are conducted using a free, untradeable token obtained by participating in the voting process.';
        
        uint256 axonNumber = tokenIdToNumber[_tokenId];
        string memory encodedAxonNumber = AnonymiceLibrary.encode(bytes(string(abi.encodePacked(AnonymiceLibrary.toString(axonNumber)))));
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Axons #',
                                    AnonymiceLibrary.toString(_tokenId),
                                    description,
                                    '","image":"',
                                    imageUrl,
                                    encodedAxonNumber,
                                    '","animation_url":"',
                                    animationUrl,
                                    encodedAxonNumber,
                                    '"}'
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
    function _tokenIdToAxonNumber(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        uint256 axonNumber = tokenIdToNumber[_tokenId];

        return axonNumber;
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

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;
        
        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;
        
        emit MinterLocked();
    }

    /**
    * @notice Set the _contractURIHash.
    * @dev Only callable by the owner.
    */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
       _contractURIHash = newContractURIHash;
    }
}