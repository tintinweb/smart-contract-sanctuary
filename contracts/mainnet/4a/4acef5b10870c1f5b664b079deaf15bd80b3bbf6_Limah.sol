/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

// File: contracts/Limah.sol


pragma solidity ^0.8.0;






contract Limah is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint64;
    
    uint256 public constant maxSupply = 555;
    uint256 public constant reservedCount = 13;
    uint256 private _price = 0.1 ether;
    uint256 private _reservedClaimed = 0;
    uint256 public currentMintId = 1;

    bool private _saleStarted;
    bool private _presaleStarted;
    string public baseURI;
    mapping(address => uint256) public whitelistBalance;
    mapping(address => uint256) public whitelistMinted;
    mapping(uint256 => uint64) public metadata;

    event Minted(address account, uint256 amount, uint256 cost);
    event PresaleMinted(address account, uint256 amount, uint256 cost);

    constructor() ERC721("LIMAH", "LIMH") {
        _saleStarted = false;
        _presaleStarted = false;

        whitelistBalance[0xBcc462c488F8DA534aF98F0f2E529CDed02D9CB5] = 4;
        whitelistBalance[0x8e258E1Aa12b8f165B69f760575b90d877AfE9b6] = 3;
        whitelistBalance[0xE39CB1c2f6dC891A1685ee411B4D36827e4F860E] = 1;
        whitelistBalance[0x881475210E75b814D5b711090a064942b6f30605] = 1;
        whitelistBalance[0x74E094Be60Be8DB1e39a0b2aB395b888b478B6De] = 3;
        whitelistBalance[0x149884b699FE3E1b042f85fA3B54843EB689b2d4] = 3;
        whitelistBalance[0x62756BEdC2c98f80cE83E45BC9f8062345b65d8e] = 4;
        whitelistBalance[0x80965566ceDc9b9C8aeDa24bbc12e44eb476dEf6] = 2;
        whitelistBalance[0xE4Abc24b5A6732a8945A85B768B4a3120CB2E37C] = 1;
        whitelistBalance[0x3c64DA143Bf741A3fa833Dd46900d28EFE8893B3] = 5;
        whitelistBalance[0x1024A91b5Ba768601e2bf4f28D2458885652cFa4] = 4;
        whitelistBalance[0x4003EC66153c090ed649CE822E30CaBa11727527] = 2;
        whitelistBalance[0xBc68c859fc8Ea2de63C60F236688dEE448C8B70e] = 1;
        whitelistBalance[0x1Ce7A7F4a2af7c690A7CBEce89e919753E409aDD] = 2;
        whitelistBalance[0xfb9699DE6f7eFc7F7D64A40852a68602ac7ef403] = 1;
        whitelistBalance[0x6D21b1D31A6Aa760F396729D85460e2F887B8764] = 1;
        whitelistBalance[0xa65f5eBFfd31ed58cC3CD5c96B2989B9F58d637C] = 1;
        whitelistBalance[0x098753abA8de1e88Fb32E045Ed8eba66735E6391] = 1;
        whitelistBalance[0x8Dfa76A3E8f290e6224b93BeBA163B90449B0e38] = 7;
        whitelistBalance[0xb1877ec8638a32F68e5DcCeA1202570CbB096357] = 6;
        whitelistBalance[0xcC4CCA9F8A1739Ac629acf8761ce4F3720764a96] = 1;
        whitelistBalance[0x0e53dbb8d5d58D957480FE522258353408D1d2a6] = 2;
        whitelistBalance[0x126438c3A64DA4eF5a8dde07366270367310f855] = 1;
        whitelistBalance[0x9a7eE28B4d734378f34c617C488cD8C5805C3B84] = 1;
        whitelistBalance[0x7B59793aD075e4ce1e35181054759C080B8D965D] = 4;
        whitelistBalance[0x52C8fe1c30a22AF561B1bF1e1D6a476b37d61c68] = 1;
        whitelistBalance[0xcE7DEb8fc70838F019a33797e1D2A5De8B7Ae2cC] = 2;
        whitelistBalance[0xF0C81C3d9102DDaD3568312d11738C902aB355C2] = 1;
        whitelistBalance[0xC60F2319eEC9B91ac6428055eeD38A946014571D] = 3;
        whitelistBalance[0xBB46314634470eD16eeDBE16F301DFE074091375] = 1;
        whitelistBalance[0xb6332Be30366Ef76174eFD011c471893c86FC36b] = 1;
        whitelistBalance[0x4C33294c13C5e783dd1d28c9844950B33d4DE9a0] = 1;
        whitelistBalance[0xc39253C74D2454e8ceBF5d8C6a219505bbe8744a] = 2;
        whitelistBalance[0xdF01F73C69b1adBdb74798E531EC08DC1C136d49] = 1;
        whitelistBalance[0xB7c6d7406e2F370290111A585D1a7A76B86C8776] = 1;
        whitelistBalance[0xA14964479Ebf9cD336011ad80652b08CD83dFE3A] = 2;
        whitelistBalance[0x27D998A81b5510Ed61D94aFDAA747e9719b45d0B] = 2;
        whitelistBalance[0xC653501899b8740379A3BA78EfD242ca93f76D7A] = 3;
        whitelistBalance[0xdD88E38cD55CD5F7e3AA4ce6C28fb73bFddbF0E7] = 1;
        whitelistBalance[0x815C187c70Ef6F52c0C9EDc6bb28a619E14057d3] = 2;
        whitelistBalance[0xCC75F6166E230CBBE484d534bBB0cC546366DC7D] = 1;
        whitelistBalance[0x943bCc065c6a09d8aA26C71F72Af4cdC137D1f84] = 1;
        whitelistBalance[0x0701d19c4D9364b69Ca001061aE3eD169a40691B] = 1;
        whitelistBalance[0x599eC7E5449E41a0204A0ed17daa1059Ee2C5F28] = 1;
        whitelistBalance[0xa9c5b41605f51f3Ba6aeb62258b0DF9B9384d8A1] = 1;
        whitelistBalance[0xC585d35FB8C9D136d6443A30FD88CCbb5F4CB86D] = 4;
        whitelistBalance[0xD9Bf0EF73403C9DC9490af5c6A2F6f7516286F32] = 1;
        whitelistBalance[0x02CBDB002D578b2b83b73b9f6019FADF39fFf6b6] = 1;
        whitelistBalance[0x09bC19CD33faF805E55b708C2dB3De87979B3950] = 1;
        whitelistBalance[0x532a2707D598d7Ae6B02eF0e0BA897DaF44b1603] = 1;
        whitelistBalance[0xC683915268E712F9960Ce59736a32119165Cc962] = 2;
        whitelistBalance[0xfDC4364C13E2c892De20Ab2Acb9a80534DE493Fc] = 1;
        whitelistBalance[0x248AfBEc09C971372278C1052253E4c308d5430C] = 1;
        whitelistBalance[0xb7bB1C09b6fB19e94ac700867ff35FbEd354C1BD] = 3;
        whitelistBalance[0x461e76A4fE9f27605d4097A646837c32F1ccc31c] = 1;
        whitelistBalance[0xFa46fB8d0a991ac62bD83E1Db1Fe8aba51ef6dd2] = 1;
        whitelistBalance[0x1F0Da8D6c0F517c2a67a3F34D1BBebfbD07B6236] = 1;
        whitelistBalance[0x83c20F72736E86EA3C64994b38B5102c78120324] = 2;
        whitelistBalance[0xbDE914699063F6EA14951AF723D2F13c822bF4ad] = 1;
        whitelistBalance[0x33569c101562e1fAF5b24581057E5cEE4c8288D7] = 1;
        whitelistBalance[0x15E875bD7De4C3d1F57a9837c411a30ff5f12B38] = 2;
        whitelistBalance[0x5078110476Cd2Aa096160F2D988aE80aEaFB5Ae4] = 2;
        whitelistBalance[0x2176426a886cbA262308Ba916cC3532B3b1ce06a] = 3;
        whitelistBalance[0xea40b0f6BA2aD77fF2FedAe98Ca67EaefCBCBE4A] = 5;
        whitelistBalance[0x42f34449209059717e6C48eD0110783A7df82abF] = 8;
        whitelistBalance[0x28411D470fc1B40E52AcccF47e43D39e815FfBf0] = 2;
        whitelistBalance[0xf7520F1D4D96Da54cF0F938f3f4D33e4bd276453] = 1;
        whitelistBalance[0x01dB485f57Dc000E761b85641F78C9D212A2eEaB] = 2;
        whitelistBalance[0x00668bd79Ede077B99BbE1C4db59418bC333d4Cf] = 2;
        whitelistBalance[0x3ef13C577311Fd6736B23525bC5E3E95060716Fe] = 2;
        whitelistBalance[0x05fc3A360944Ba03aBB2bBCcE275F89c96cB1385] = 3;
        whitelistBalance[0xD19d92c23Be2c965825f31462F3d8D1f84C17BFc] = 2;
        whitelistBalance[0x5482b90E0F59Fb4a926f7FFe9DB9EADE142CF86D] = 1;
        whitelistBalance[0x7Da3236aF88181a8AB8bd3929f17EfAD5417DF3A] = 1;
        whitelistBalance[0x92B57222582EfB77295454340529c411021c7Bc5] = 2;
        whitelistBalance[0x66b19A1241FD54fE74dD8E40B7df8C419492e423] = 1;
        whitelistBalance[0x94F0FaA3c83C9Bc78b675dDeA82fcB982fa89690] = 2;
        whitelistBalance[0x95e62E8FF84ed8456fDc9739eE4A9597Bb6E4c1f] = 1;
        whitelistBalance[0xBE837e4a956cC8118A013563a9E291D8D4D4b8B4] = 1;
        whitelistBalance[0xE84b1B9593865cb14846908910bb4B9a85746770] = 1;
        whitelistBalance[0x6eF2376fA6e12Dabb3a3ED0Fb44E4ff29847Af68] = 3;
        whitelistBalance[0x460b26B95b251B477e2bc52aB731C70F42299adC] = 1;
        whitelistBalance[0x3ebFdE946baD00D005A7Abb94bcab866fE11E84F] = 1;
        whitelistBalance[0xb7fa496E5166b39a114f5DeF4ae38015b977FeC8] = 1;
        whitelistBalance[0x3943b578D00D61b622Fd99AB6F16921e54F7612b] = 1;
        whitelistBalance[0x3E4D97C22571C5Ff22f0DAaBDa2d3835E67738EB] = 1;
        whitelistBalance[0xd561ba5bdBFEA7A39bF073b7520a7273bc767131] = 1;
        whitelistBalance[0xAB00e849A18b2ae3381c8895Cf4b15494CA27561] = 1;
        whitelistBalance[0xc2bd956DcaC8268ca78F55d6b33BbA92EEac443D] = 1;
        whitelistBalance[0x89097a0A657e42627E05f33DF494dE7f10123651] = 1;
        whitelistBalance[0x6ab615CF8deCFc488186E54066Fc10589C9293A3] = 2;
        whitelistBalance[0x2DBd479974967b8a0717d8B84c2172D8b26Cdf44] = 8;
        whitelistBalance[0xaee2Ae13EBf81d38df5a9Ed7013E80EA3f72e39b] = 4;
        whitelistBalance[0x0B4338671b26d40e1177A8A0f64D75f253f15e05] = 1;
        whitelistBalance[0x6007dC12910639e692b50E3dAc02747eF6048dB2] = 1;
        whitelistBalance[0x2cb9AE536fc474159b95dF01c5a708CAcD9F84B2] = 1;
        whitelistBalance[0xbA3df119299a11EA9cFeBC2801a8Bf0102A2bE3d] = 1;
        whitelistBalance[0x34Ba3E288c3674e73ab9D3B1B75EE064628d72c6] = 1;
        whitelistBalance[0x3AEf5d2384298DB7C7F711224221F229E43cBbA7] = 1;
        whitelistBalance[0x7430EA2c3b2F2468Bba97C2B1CCa33f42Af2e57c] = 1;
        whitelistBalance[0x115406837DE7D8194421126De6Fa7dc90bDe1663] = 3;
        whitelistBalance[0x693e1AEa486c80D34124C6dC3eddDd325A41ABE9] = 1;
        whitelistBalance[0x8eE6D1daE8eCeA729bD40a6F3BEde58bF048eD9e] = 2;
        whitelistBalance[0xd0c31E46C73B386432A3DdF768587df604dD52BE] = 1;
        whitelistBalance[0x2d408F3160B15F09Df792eFCb395B828d3E55a95] = 1;
        whitelistBalance[0xcB748f312b8e0557587862225697AAe325052f7D] = 1;
        whitelistBalance[0x18655651F4DFA30dA7E47852265db731C3059E1b] = 2;
        whitelistBalance[0x1168a0Ac3f249a011a3A52C662591d6383a91d97] = 1;
        whitelistBalance[0x45698cdCC733cBA4f8B1150C2f580587adF1Df92] = 3;
        whitelistBalance[0xd3745F1ba3c0280F0Fb3456676dE2Fa714d1fcb7] = 1;
        whitelistBalance[0x9DDf691De5e1F4f7764262Be936B61f46d9f9d70] = 1;
        whitelistBalance[0x100e4F6D92965C2f2dEc3A08ACeb63A8de69c99D] = 2;
        whitelistBalance[0x3E7898c5851635D5212B07F0124a15a2d3C547EB] = 3;
        whitelistBalance[0x4e1c52008b0cd3bE1819745695E85Ffe3B9494B0] = 1;
        whitelistBalance[0x33494fB9B491B1328c90BE2c926B6A5080AbAfDA] = 4;
        whitelistBalance[0xB7D9945166e3DA89ee4c0947230753d656D116a5] = 2;
        whitelistBalance[0x403156966d0593770846e72dCBec871F93ef1224] = 6;
        whitelistBalance[0x1d4B9b250B1Bd41DAA35d94BF9204Ec1b0494eE3] = 2;
        whitelistBalance[0xEbD56361441B416a788086e47F48599593fcFE4F] = 1;
        whitelistBalance[0x93EFEC89Db80176895b2C7a4E00aF808BBc69239] = 1;
        whitelistBalance[0x2668B4B69c57624B0dc7453250f841B726a456CF] = 1;
        whitelistBalance[0x4D010eeB7ec813AE5520D4cC7Bdb975ba2bFd2a1] = 1;
        whitelistBalance[0xFF0aD4e2C7F60D2303812Cbc73c20F890b339925] = 1;
        whitelistBalance[0x38623FA88e3d8D85945C2512Abf3f001a9edB492] = 1;
        whitelistBalance[0xcD61ecC765040389b81dAc23b67B091160E9BF39] = 1;
        whitelistBalance[0x20B4E6cAbA712F520D9A3A309D8c0b0DA801a212] = 2;
        whitelistBalance[0x84274ff96A1928FEb3c1cC2260f962B377a3d53F] = 1;
        whitelistBalance[0x5080A71235d51F1E1F2F7C720810766Dc5FB15C1] = 1;
        whitelistBalance[0x4EB4a5718A685c788B650c944834ba574Db508C4] = 1;
        whitelistBalance[0x5FE7Ff8Dc6082b6b0812c5A4b23A3B7B40D26747] = 1;
        whitelistBalance[0x85C6F217D0375E5dC7b249B5bC12577B051bf417] = 1;
        whitelistBalance[0x3a4f4a3B4D965058701f0fb2611Acbc89a11996E] = 1;
        whitelistBalance[0x2A76F7Df64889A1f20F5b6Aa87eBfFA9A38AB925] = 1;
        whitelistBalance[0x9B24349Ad2e4d0a2dcE6376b75A823D9b0C9774C] = 2;
        whitelistBalance[0x4D77536a1B90C30F1fBcaeF8817160f663Da1DE0] = 3;
        whitelistBalance[0x1d06ef1CF5059370ecd6bE3A4ACa223fE5973E02] = 1;
        whitelistBalance[0xEAfAA1405A1BaC58D2C3dCefe6A07467Bcd7fEbE] = 1;
        whitelistBalance[0xc4fF126aEC164409B9c2269D34A79E53C39C8A56] = 5;
        whitelistBalance[0xd781a9158edFd5AEA767F5cfC3Db97482C722157] = 1;
        whitelistBalance[0x3ddfB199288F7a439dfFEdc03AE9Bc02FaFC63F6] = 1;
        whitelistBalance[0x6c66F4cA90c023bc04461ef19e67B06bfC3d0a53] = 1;
        whitelistBalance[0x1a60DfB071B039c6e33dcb3220891C83DA72c1be] = 1;
        whitelistBalance[0xc72f40a397453051349F73cf2E2a04Fac06E37a3] = 1;
        whitelistBalance[0x5689676A2c9C796375e01784F9B42723536Da2B2] = 1;
        whitelistBalance[0x1986F4BCc6b78d40e499E928a910DD7bde857734] = 1;
        whitelistBalance[0xcB1dAC0C1a5F87dc410a56F0F82E7E3A56bE1499] = 1;
        whitelistBalance[0x97e2B1efF9eF076635eB2983702e6b74d1D509B9] = 1;
        whitelistBalance[0xa4362e88E1444DF62fC85d15F7eC333f0664442C] = 1;
        whitelistBalance[0xB3f6Ea7b8A2ccE43D78d5637D2f0cA2c806439D0] = 1;
        whitelistBalance[0x3Eb92F230B33bD8d98cc060A76a7e7d77819a21A] = 3;
        whitelistBalance[0xBe769b04627613C8F3b30aBE20E6458c1DCB239B] = 1;
        whitelistBalance[0xd6cc8BF1a2bDF94BE558A40B2A665a46c94211B6] = 2;
        whitelistBalance[0x110772F7472B56A1aB844051260B9416FE30245b] = 2;
        whitelistBalance[0xD41c564db35DA12D9d25944b88Cc22468B0D45DC] = 1;
        whitelistBalance[0x34A4Dd196Ab83166c8C9935D5A6f60f2a02a905a] = 1;
        whitelistBalance[0x7D602b32acD5942A619f49e104b20C0553c93405] = 2;
        whitelistBalance[0x007C9c7e7ed7cD83F1A38cFd747f28E6894ab9f6] = 1;
        whitelistBalance[0xbA72224300dD0CCFeF418FEe7865017ABEB876a7] = 2;
        whitelistBalance[0x738A1f6d79e592f726efaA3B8beF81797F408119] = 1;
        whitelistBalance[0x36E058332aE39efaD2315776B9c844E30d07388B] = 1;
        whitelistBalance[0x4a7AFc64E298876FcB8F6AA7D44Ef3C91fCBC291] = 1;
        whitelistBalance[0x4D9B5696a8afeD6b65F92B1B86ccf90c7561aE56] = 2;
        whitelistBalance[0x0060263198Fe57F4e9eb4B9EE02E1c40cCf6d13E] = 1;
        whitelistBalance[0x11e6AA7D1D74Cb4A3056e8943372b94D1127D26c] = 1;
        whitelistBalance[0x2C6602c1200F08eb57CC06eaDa1C215cfd7D0b7C] = 1;
        whitelistBalance[0xe4A974E499e8767A13894635C45F7389b1FFc5Dd] = 1;
        whitelistBalance[0xdcfd6D6e63F15A391D96D1b76575Ae39Ad6965D9] = 4;
        whitelistBalance[0x08Cdbd22a584F0fa78474FD1724c664D62C65FD9] = 1;
        whitelistBalance[0xcc4b0a5b8De07B69cE5936FBbFeE6BDfb0A30F77] = 1;
        whitelistBalance[0x5968d383DeB7636FB68C91915c516499Fa2ddcD0] = 1;
        whitelistBalance[0x7eC8676CA6BDDB54455b806B9ef39c6D8ee51766] = 1;
        whitelistBalance[0x177580556eD986Cee01012C6115823208Ef584B8] = 1;
        whitelistBalance[0xB1af684799C96F5C740786bE59DC834ff8Ef5add] = 1;
        whitelistBalance[0x5fFd0B2EB25e29DBf94Ee7cB8F7b90d2b2fbbc53] = 1;
        whitelistBalance[0xE3873F3D9E13880f9c508f47cbBF9e065a67265B] = 1;
        whitelistBalance[0x322e128453EFd91a4c131761d9d535fF6E0CCd90] = 1;
        whitelistBalance[0xB21027569dDaE670aA521Ed90d6ECb5dE515e8d4] = 1;
        whitelistBalance[0xd70676Cfa67Abc65A8C39f049d62EEA30E3080CF] = 1;
        whitelistBalance[0x8889c07205749DB6d38673f9248d720b0c07955f] = 1;
        whitelistBalance[0x004768E08805AB5ece646a65C8Ba492C3AD71E4a] = 1;
        whitelistBalance[0xBb739eE04F0cC2Db984cd47EAd003F4c183CF19a] = 1;
        whitelistBalance[0xa80e8CB880b7fA0ad1EAa609eDD8f1CDDd21aF42] = 1;
        whitelistBalance[0xcA147eb37135B667B14792bc4C3Cc57389F574AA] = 1;
        whitelistBalance[0x440d55a1867958dA7C8FD88A5e163a85Fd739eFA] = 1;
        whitelistBalance[0xd544CEBA36DEF08e68c56976576AcC974DE54F7b] = 1;
        whitelistBalance[0x29f316885886bE6357FC1411478D4C291021A0AA] = 1;
        whitelistBalance[0x6634f9d0c6B7fB5764312bD0c91556F51e67E544] = 1;
        whitelistBalance[0x7a501E2a432d44013DD9575e73Ed551A88fc0184] = 1;
        whitelistBalance[0xBbcd652CF371b59CE9A063183AA44D377f4467E8] = 2;
        whitelistBalance[0x2e44F49552C0C8e93f60318520760f619c03615F] = 1;
        whitelistBalance[0x86776Ae9783C634C6AEe6cdA878C8f35a5571333] = 1;
        whitelistBalance[0xAcDBC51Dd3bbDC46C447E0A2EDaC8A713dEB1907] = 1;
        whitelistBalance[0x6D8Df15FD3dC3505a4010CaC6937De159d68081C] = 1;
        whitelistBalance[0xd3e9AF5B0C1FC2edD6A7907076cd9C79e67DE6aC] = 1;
        whitelistBalance[0x0923A3931599b5B08f91E62b1894053ca75455A9] = 1;
        whitelistBalance[0x2168B2295E912A27c0015BaD9F09F090EBcE1a99] = 1;
        whitelistBalance[0xF898F063d22a994bA6943D50A96C2dbC0Bd9218c] = 1;
        whitelistBalance[0x321f3BFA19354BD9F56CFDA97bcCf3a7C21D1621] = 1;
        whitelistBalance[0xbaCD6723bDc567E134603AA35E5c479411477d52] = 1;
        whitelistBalance[0x104F0BE994C32231934e64EeF299bC8866288a5f] = 1;
        whitelistBalance[0x167AE6231bd8E564F969482bc34A00D91B7Fe37c] = 1;
        whitelistBalance[0x646e72181602114e7eE02F963D13539cf056ce1e] = 1;
        whitelistBalance[0xF4164FC650e2C59D1580Fc1c2C9E792087865D56] = 1;
        whitelistBalance[0xCD546c340b8c0bA679eBbECA1ABB8C2E4528b6E5] = 1;
        whitelistBalance[0xcdF660aeEB6DBdDba0C096d1FAfCb41D60f9A88B] = 1;
    }

    modifier whenSaleStarted() {
        require(_saleStarted);
        _;
    }

    modifier whenPresaleStarted() {
        require(_presaleStarted);
        _;
    }

    function presaleMint(uint256 amount) external payable whenPresaleStarted {
        uint256 preSaleAllowance = whitelistBalance[msg.sender] - whitelistMinted[msg.sender];
        require(amount * _price <= msg.value, "Inconsistent amount sent!");
        require(preSaleAllowance >= amount, "Address does not own enough nfts from first collection");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, currentMintId);
            currentMintId++;
            whitelistMinted[msg.sender] = whitelistMinted[msg.sender] + 1;
        }

        emit PresaleMinted(msg.sender, amount, msg.value);
    }

    function mint(uint256 amount) external payable whenSaleStarted {
        require(amount < 3, "You cannot mint more than 2 Tokens at once!");
        require(
            currentMintId + amount <= maxSupply + 1,
            "Not enough Tokens left."
        );
        require(amount * _price <= msg.value, "Inconsistent amount sent!");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, currentMintId);
            currentMintId++;
        }
        
        emit Minted(msg.sender, amount, msg.value);
    }

    function togglePresaleStarted() external onlyOwner {
        _presaleStarted = !_presaleStarted;
    }

    function presaleStarted() public view returns (bool) {
        return _presaleStarted;
    }

    function toggleSaleStarted() external onlyOwner {
        _saleStarted = !_saleStarted;
    }

    function saleStarted() public view returns (bool) {
        return _saleStarted;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    // Make it possible to change the price: just in case
    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function getReservedLeft() public view returns (uint256) {
        return reservedCount - _reservedClaimed;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function claimReserved(uint256 _number, address _receiver) external onlyOwner {
        require(
            _number + _reservedClaimed <= reservedCount,
            "That would exceed the max reserved."
        );

        for (uint256 i = 0; i < _number; i++) {
            _safeMint(_receiver, currentMintId);
            currentMintId++;
            _reservedClaimed++;
        }

        _reservedClaimed = _reservedClaimed + _number;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function updateWhitelistAllowance(address newAddress, uint256 amount) public onlyOwner {
        whitelistBalance[newAddress] = amount;
    }
    
    function getWhitelistAllowance(address userAddress) public  view  returns (uint256)  {
        return whitelistBalance[userAddress];
    } 
    
    function getPresaleAllowance(address userAddress) public view returns (uint256) {
        return whitelistBalance[userAddress] - whitelistMinted[userAddress];
    }
    
    function getTokensRemaining () public view returns (uint256) {
        return maxSupply - currentMintId + 1;
    }
}