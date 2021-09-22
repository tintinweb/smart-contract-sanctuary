/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: Address

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

// Part: Base64

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

// Part: Context

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

// Part: Counters

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

// Part: IERC165

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

// Part: IERC721Receiver

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

// Part: SafeMath

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

// Part: Strings

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

// Part: ERC165

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

// Part: IERC721

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

// Part: Ownable

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

// Part: IERC721Enumerable

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

// Part: IERC721Metadata

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

// Part: ERC721

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

// Part: ERC721Enumerable

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

// File: seasides.sol

contract OnChainSeaside is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    uint private constant maxTokensPerTransaction = 30;
    uint256 private tokenPrice = 30000000000000000; //0.03 ETH
    uint256 private constant nftsNumber = 3333;
    uint256 private constant nftsPublicNumber = 3300;
    
    constructor() ERC721("OnChain Seaside", "ONSEA") {
        _tokenIdCounter.increment();
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
    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function toHashCode(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "000000";
        }
        uint256 i;

        bytes memory buffer = "000000";
        for(i=6;i>0;i--) {
            if (value % 16 < 10)
                buffer[i-1] = bytes1(uint8(48 + uint256(value % 16)));
            else
                buffer[i-1] = bytes1(uint8(55 + uint256(value % 16)));

            value /= 16;
        }
        return string(buffer);
    }
    
    function getGrass(uint256 value, uint256 is_mirror) public pure returns (string memory) {
        uint256 i;
        uint256 prt;
        int256 sym;
        uint256 pos;
        uint256 seed;
        uint256 ps;
        uint256 psx;

        uint256 finale=1;

        bytes memory buffer = new bytes(250);

        uint256[6] memory gtypes;

        gtypes[0] = 563891157643448204000202434637890680663763947839870365052682593692495482209;
        gtypes[1] = 1002862760941180669446230775124823108274825368678245159754096610961814;
        gtypes[2] = 563871000271014004664722370698789260236686074535032282236861359775136052288;
        gtypes[3] = 1003329826285104973259814183739832352502149867278345049274004408492605;
        gtypes[4] = 564017709498396033660054424834310877655732749413952956046917965314005819035;
        gtypes[5] = 1002137238139483205643623885946750710585681910777426838629649942020236;


        finale = 0;
        seed = gtypes[value*2-2];

    
        for(psx=ps=pos=i=0;i<70;i++) {
            prt = seed / (750 ** ps++);
            sym = int256(prt % 750);
            if (sym == 749) {
                if (finale == 1)
                    break;
                    
                finale = 1;
                seed = gtypes[value*2-1];
                ps=0;
                continue;
            }
            
            if (psx%2==0) {
                
                if (is_mirror==1)
                    sym = 400 - sym;
                else
                    sym += 550;
                  
                if (i>0)
                    buffer[pos++] = ' ';
            } else {
                if (i>0)
                    buffer[pos++] = ',';
                sym += 500;
    
            }
            
            if (sym<0) {
                sym=-sym;
                buffer[pos++] = bytes1(uint8(45));
    
            }
                
            if (sym<10)
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));
            else if (sym<100) {
                buffer[pos++] = bytes1(uint8(48 + uint256(sym / 10)));
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));
            } else if (sym<1000) {
                buffer[pos++] = bytes1(uint8(48 + uint256(sym / 100)));
                buffer[pos++] = bytes1(uint8(48 + uint256((sym / 10)%10)));
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));  
            } else {
                buffer[pos++] = bytes1(uint8(48 + uint256(sym / 1000)));
                buffer[pos++] = bytes1(uint8(48 + uint256((sym / 100)%10)));
                buffer[pos++] = bytes1(uint8(48 + uint256((sym / 10)%10)));
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));  
            }
            psx++;
    
        }
        
        bytes memory buffer2 = new bytes(pos);
        for(i=0;i<pos;i++)
            buffer2[i] = buffer[i];

        return string(buffer2);
    }
    
    function getShip(uint256 value, uint dir, uint is_mirror) internal pure returns (string memory) {
        uint256 i;
        uint256 prt;
        uint256 sym;
        uint256 pos;
        uint256 seed;
        uint256 ps;

        uint256 finale=1;

        bytes memory buffer = new bytes(300);

        uint256[10] memory stypes;

        stypes[0] = 4039953958419306012627391607069051694356360220713754655043968660016;
        stypes[1] = 63106266081136485859406661386793985037851232673778661;
        stypes[2] = 161568093605294050650559196328221936718722000674656809180508552713619040;
        stypes[3] = 63096482884095845761084638724950672236119832596577537;
        stypes[4] = 6461049781969783938359086369026346968766711308334899858451023002616666897676;
        stypes[5] = 63120086296825990194702960480301658791387552688699008;
        stypes[6] = 161512793322334258241850556133413063336821761930288295517787616106338882;
        stypes[7] = 986070141659197590531764122903072004020;
        stypes[8] = 161390119281273703232398765386984498139365471992159755174679367096177400;
        stypes[9] = 100972004999646208506838990436000093602246360157725215130052251;
        if (value < 7) {
            seed = stypes[value-1];
        } else {
            finale = 0;
            seed = stypes[value==7?6:8];
        }

        uint256 shift_y = is_mirror==1 ? 560 : 460;
        for(ps=pos=i=0;i<70;i++) {
            prt = seed / (200 ** ps++);
            sym = prt % 200;
            if (sym == 150) {
                if (finale == 1)
                    break;
                    
                finale = 1;
                seed = stypes[value==7?7:9];
                ps=0;
                continue;
            }
            
    
            
            
            if (ps%2==0) {
                if (is_mirror==1)
                    sym = 1000 - (sym + 320);
                else
                    sym = sym + shift_y;
                    
                if (i>0)
                    buffer[pos++] = ',';
            } else {
    
                if (dir == 1)
                    sym += 100;
                else
                    sym = 1000 - (sym + 100);
                    
                if (i>0)
                    buffer[pos++] = ' ';
            }
                
            if (sym<10)
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));
            else if (sym<100) {
                buffer[pos++] = bytes1(uint8(48 + uint256(sym / 10)));
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));
            } else {
                buffer[pos++] = bytes1(uint8(48 + uint256(sym / 100)));
                buffer[pos++] = bytes1(uint8(48 + uint256((sym / 10)%10)));
                buffer[pos++] = bytes1(uint8(48 + uint256(sym % 10)));  
            }
    
        }

        bytes memory buffer2 = new bytes(pos);
        for(i=0;i<pos;i++)
            buffer2[i] = buffer[i];

        return string(buffer2);
        }

    
    function getPalm(uint256 num) internal pure returns (string memory) {
        string[4] memory palm;
        palm[0]='M-137,104C-32,27,573,28,762,263 C582,95,180,57,23,87c105-7,598,17,757,244 c-60-74-241-182-524-212c241,55,435,181,475,265 C587,207,260,141,220,133c18,4,375,100,461,262 C504,164,19,125-4,123c141,15,524,86,641,281 C493,229,162,170,122,163c141,51,245,127,273,197 C340,270,68,139-39,146c139,51,242,127,269,196 C117,195-84,150-84,150L-758,97L-137,104z';
        palm[1]='M-144,304c9-106,334-319,580-175 C236,41-2,150-67,232c52-44,331-195,555-47 c-77-45-241-78-410-5c162-35,344,8,417,70 C307,140,92,197,65,204c12-2,263-42,407,72 c-236-144-520-8-534-1C24,239,273,167,455,301 C270,193,57,257,31,265c107-3,209,27,267,80 C214,284-11,263-65,308c106-3,207,28,264,80 C48,296-87,326-87,326L-533,433L-144,304z';
        palm[2]='M173,299c80-78,288-143,525-156c123-6,235,2,323,22 c11,1,21,2,32,4c-87-30-205-48-339-49c-210-0-400,43-495,107 c84-74,293-128,528-127c217,0,395,47,466,114l435,66 c0,0-500-18-509-26c-175,21-328,81-402,151c56-69,193-132,358-163 c-15-2-30-4-47-5c-22,1-46,2-70,5C796,262,636,324,560,396 c56-70,195-133,362-164c-44,0-91,3-139,8 c-213,23-400,87-490,161c76-82,282-158,521-184 c92-10,179-11,255-5c-0-0-0-0-0-0c-89-14-204-14-330,1 C524,241,338,309,250,384c75-83,280-163,519-193 c21-2,42-4,63-6c-45,1-92,5-141,11c-213,27-400,95-488,170 c75-83,280-163,519-193c26-3,53-6,78-8c-42-1-87-1-133,0 C454,175,265,230,173,299z';
        palm[3]='M1086,14C982-63,415-11,256,269C412,64,785-11,934,9 c-99,0-559,70-690,339c50-88,212-225,474-283 c-221,82-393,240-424,339C415,191,716,89,753,77 c-16,6-344,144-412,334C490,136,941,50,963,47 C832,76,478,189,384,418c120-210,426-305,463-316 c-128,69-220,164-241,245c44-106,289-276,391-277 c-126,69-217,163-237,243c94-175,279-243,279-243l438-99L1086,14z';
        return palm[num-1];
    }
    
    function getGround(uint256 num) internal pure returns (string memory) {
        string[7] memory ground;
        ground[0] = '-30,898,-1357,1016,1298,1016';
        ground[1] = '-11,927,431,952,663,921,845,945,1043,934,1043,1011,-8,1011';
        ground[2] = '-11,927,156,912,222,941,284,931,1043,934,1043,1011,-8,1011';
        ground[3] = '-11,927,425,969,875,952,1046,880,1043,934,1043,1011,-8,1011';
        ground[4] = '-12,962,136,940,239,960,648,966,951,931,1041,938,1043,1011,-8,1011';
        ground[5] = '894,933,722,948,666,900,666,900,664,890,646,890,645,900,482,900,481,890,462,890,461,900,461,900,364,967,247,961,102,946,-9,912,-12,1007,1039,1007,1043,930';
        ground[6] = '800,951,1014,927,1039,1007,-12,1007,-10,940,81,941,175,962,647,927';
        return ground[num-1];
    }
    
    function getSun(uint256 num) internal pure returns (string memory) {
        uint256 suns;

        suns = 712316151692331099684323100692331075717224135713226117576244139582262105;
        if (num > 0)
            suns = suns / (1000 ** (num*3));
        string memory output = string(abi.encodePacked('cx="',toString((suns/1000000)%1000),'" cy="',toString((suns/1000)%1000),  '" r="',toString(suns%1000),'"'));
        
        return output;
    }


    function getMoon(uint256 num) internal pure returns (string memory) {
        uint256 moons;

        moons = 712316151692331099684323100692331075717224135713226117576244139582262105;
        if (num > 0)
            moons = moons / (1000 ** (num*3));
        
        string memory output = string(abi.encodePacked('cx="',toString((moons/1000000)%1000+100),'" cy="',toString((moons/1000)%1000),  '" r="',toString(moons%1000-50),'"'));
        
        return output;
    }
    
     function tokenURI(uint256 tokenId) pure public override(ERC721)  returns (string memory) {
        uint256[16] memory xtypes;
        string[5] memory colors;
        string[25] memory parts;
        string[8] memory mount1;
        string[8] memory mount2;
        uint256[9] memory params;
        uint256 pos;
        uint256 moonpos;

        uint256 rand = random(string(abi.encodePacked('Seasides',toString(tokenId))));

        params[0] = 1 + ((rand/10) % 8);// ship
        params[1] = 1 + (rand/100) % 2; // dir
        //params[2] = 1 + ((rand/10000) % 37); // pallette
        params[2] = 35;
        params[3] = 1 + ((rand/1000000) % 8); // mounts
        params[4] = 1 + ((rand/100000000) % 6); // grass
        params[5] = 1 + ((rand/1000000000) % 4); // palm
        params[6] = 1 + ((rand/10000000000) % 7); // ground
        params[7] = 1 + ((rand/100000000000) % 4); // sun
        params[8] = 1 + ((rand/10000) % 37); // pallette
        
        mount1[0] = '78,444 -494,478 651,478';
        mount1[1] = '999,392 865,417 806,420 743,451 529,478 1468,478';
        mount1[2] = '463,449 403,457 351,431 177,478 681,478';
        mount1[3] = '1004,457 848,464 760,450 608,455 419,433 320,454 135,409 -8,424 -8,478 1004,478';
        mount1[4] = '226,422 177,414 83,344 -8,367 -12,478 328,478';
        mount1[5] = '999,392 865,417 806,420 743,451 529,478 1468,478';
        mount1[6] = '564,443 463,457 375,478 793,478 721,467 612,414';
        mount1[7] = '1013,420 853,410 732,441 637,431 608,446 390,466 240,457 186,430 94,447 -16,420 -87,478 1016,478';
        
        mount2[0] = '162,392 -307,478 632,478';
        mount2[1] = '';
        mount2[2] = '';
        mount2[3] = '';
        mount2[4] = '991,410 826,454 611,478 1262,478';
        mount2[5] = '';
        mount2[6] = '156,438 47,478 321,478 214,461';
        mount2[7] = '';
        
        xtypes[0] = 5165462586977505248984271025794477445148782908573069521325498340212639;
        xtypes[1] = 490024044101034400102396419179934085738779419751960710510484619019681904;
        xtypes[2] = 4043991994607814950473362577238312297018937036519365143342896853810329;
        xtypes[3] = 1379064599573736476104814799994272434465744258265921437097553789059202;
        xtypes[4] = 6056088629583070600596400423476580059718415009582353316298341503465113;
        xtypes[5] = 138040297937156288773826099078203347749133755730926697092887565253488215;
        xtypes[6] = 1763486549546207954426324916291393168705773800679768336312337964145309337;
        xtypes[7] = 948653233183009513098268805292360185252612190882203913941189109236825;
        xtypes[8] = 1765596160030049122294337924707755907300568572202546387173451426705702110;
        xtypes[9] = 571213962168160818623884462797953331024439701527741670201332697661529;
        xtypes[10] = 1759945423641250114310949500884067660757318022344968985317724270290468863;
        xtypes[11] = 634962523324887909409742165431514640856016078396772822011217464449368064;
        xtypes[12] = 1318233657466206738337996551415773989873200879281323137549919882303230302;
        xtypes[13] = 20786449684869734852663949139680728584860474635680334261919687729872949;
        xtypes[14] = 321076936879265745525548114627410433723373509773187045336;
    
        pos = (params[2]-1) * 4;
        colors[0] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
    
        pos = (params[2]-1) * 4 + 1;
        colors[1] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
        pos = (params[2]-1) * 4 + 2;
        colors[2] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
        pos = (params[2]-1) * 4 + 3;
        colors[3] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
        moonpos = (params[8]-1) * 4;
        colors[4] = toHashCode(xtypes[moonpos/10] / (16777216 ** (moonpos%10)) % 16777216);

        parts[0] = '<svg width="1000px" height="1000px" viewBox="0 0 1000 1000" version="1.1" xmlns="http://www.w3.org/2000/svg"> <linearGradient id="SkyGradient" gradientUnits="userSpaceOnUse" x1="500.001" y1="999.8105" x2="500.0009" y2="4.882813e-004"> <stop offset="0.5604" style="stop-color:#'; // 2
        parts[1] = '"/> <stop offset="1" style="stop-color:#'; // 3
        parts[2] = '"/> </linearGradient> <rect x="0.001" fill="url(#SkyGradient)" width="1000" height="999.811"/> <polygon opacity="0.15" fill="#'; // 3
        parts[3] = string(abi.encodePacked('" points="',mount2[params[3]-1],'"/> <polygon opacity="0.1" fill="#')); // 3
        parts[4] = string(abi.encodePacked('" points="',mount1[params[3]-1],'"/> <rect x="0" y="478" opacity="0.2" fill="#')); // 3
        parts[5] = '" width="1000" height="734.531"/> <rect x="0" y="563.156" opacity="0.3" fill="#'; // 3
        parts[6] = '" width="1000" height="649.315"/> <g> <path xmlns="http://www.w3.org/2000/svg" opacity="0.55" fill="#'; // 3
        parts[7] = '" d="M8087,687c-158,0-320-3.15-469-3 c-293,0-616,10-701,10c-261,0-600-17-809-17 c-118,0-246,11-376,11c-158,0-320-10-469-10 c-293,0-379,10-574,10c-195,0-331-11-540-11 c-118,0-246,11-376,11c-158,0-320-10-469-10 c-293,0-616,17-701,17c-261,0-600-12-809-12 c-118,0-246,12-376,12c-103,0-263-9-469-9 c-92,0-181,2-260,2c-171,0-304,0-362,0c-261,0-330-0-330-0 v525l9053-6V688C9039,688,8217,687,8087,687z"/> <animateMotion path="M 0 0 L -8050 20 Z" dur="7s" repeatCount="indefinite" /> </g> <g> <path xmlns="http://www.w3.org/2000/svg" fill="#'; // 3
        parts[8] = '" d="M8097,846c-158,0-319-7-470-7c-285,0-443,20-651,20 c-172,0-353-5-449-9c-101-4-247-20-413-20c-116,0-243,26-373,26 c-158,0-320-31-471-31c-285,0-352,36-560,36c-172,0-390-31-556-31 c-116,0-243,26-373,26c-158,0-320-31-471-31c-285,0-442,35-650,35 c-172,0-353-5-449-9c-101-4-247-20-413-20c-116,0-245,25-375,25 c-158,0-322-13-474-13c-107,0-197,2-277,3c-133,1-243,0-372,0 c-172,0-308-0-308-0v364h9053V846C9038,846,8227,846,8097,846z"/> <animateMotion path="M 0 0 L -8050 40 Z" dur="7s" repeatCount="indefinite" /> </g> <g> <polygon fill="#'; // 3
        parts[9] =  string(abi.encodePacked('" points="',getShip(params[0],params[1],0), '"/> <polygon opacity="0.2" fill="#')); // 3
        parts[10] = string(abi.encodePacked('" points="',getShip(params[0],params[1],1),'"/> <animateMotion path="m 0 0 h ',(params[1]==1 ? '':'-'),'5000" dur="12s" repeatCount="indefinite" /> </g>'));
        parts[17] = string(abi.encodePacked('<radialGradient id="SunGradient" ',getSun(params[7]*2-2),' gradientUnits="userSpaceOnUse"> <stop offset="0.7604" style="stop-color:#')); // 1
        parts[11] = '"/> <stop offset="0.9812" style="stop-color:#'; // 2
        parts[12] = '"/> </radialGradient>';
        parts[17] = '';
        parts[11] = '';
        parts[12] = '';

        //parts[18] = '<circle opacity="0.1" fill="#'; // 2
        //parts[13] = string(abi.encodePacked('" ',getMoon(params[7]*2-1),'/>'));
        //<circle fill="url(#SunGradient)" ',getSun(params[7]*2-2),'/>'));
        parts[22] = '<circle opacity="0.8" fill="#'; // 2
        parts[23] = string(abi.encodePacked('" ',getMoon(params[7]*2-1),'/>')); 
        //<circle fill="url(#SunGradient)" ',getSun(params[7]*2-2),'/>'));
        
        //parts[21] = '<g><polygon fill="#'; // 4
        //parts[14] = string(abi.encodePacked('" points="',getGrass(params[4]/3+1, params[4]%2),'"/> <animateMotion path="M 0 0 H 10 Z" dur="4s" repeatCount="indefinite" /> </g>'));
        
        //parts[20] = string(abi.encodePacked('<g> <path fill="#',colors[3],'" d="',getPalm(params[5]),'"/> <animateMotion path="M 0 0 H 15 Z" dur="5s" repeatCount="indefinite"/> </g> <polygon fill="#')); // 4
        //parts[15] = '" points="';
        //parts[16] = '"/>';
        
        //parts[18] = '';
        //parts[13] = '';
        parts[14] = '';
        parts[15] = '';
        parts[16] = '';
        parts[20] = '';
        parts[21] = '';

        parts[19] = '</svg> ';

        string memory output = string(abi.encodePacked(parts[0],colors[1],parts[1],colors[2]));
         output = string(abi.encodePacked(output,parts[2],colors[2],parts[3] ));
         output = string(abi.encodePacked(output,colors[2],parts[4],colors[2] ));
         output = string(abi.encodePacked(output,parts[5],colors[2],parts[6] ));
         output = string(abi.encodePacked(output,colors[2],parts[7],colors[2] ));
         output = string(abi.encodePacked(output,parts[8],colors[2],parts[9] ));
         output = string(abi.encodePacked(output,colors[2],parts[10],parts[17],colors[0] ));
         output = string(abi.encodePacked(output,parts[11],colors[1],parts[12] ));
         output = string(abi.encodePacked(output,parts[18],colors[1],parts[13],parts[22],colors[4],parts[23]));
         //output = string(abi.encodePacked(output,parts[21],colors[3],parts[14],parts[20],colors[3],parts[15]));
         output = string(abi.encodePacked(output,parts[20],colors[3],parts[15]));
         output = string(abi.encodePacked(output,getGround(params[6]), parts[16], parts[19]));

        string[11] memory aparts;
        aparts[0] = '[{ "trait_type": "Ship", "value": "';
        aparts[1] = toString(params[0]);
        aparts[2] = '" }, { "trait_type": "Palette", "value": "';
        aparts[3] = toString(params[2]);
        aparts[4] = '" }, { "trait_type": "Hills", "value": "';
        aparts[5] = toString(params[3]);
        aparts[6] = '" }, { "trait_type": "Sun", "value": "';
        aparts[7] = toString(params[7]);
        aparts[8] = '" }, { "trait_type": "Coast", "value": "';
        aparts[9] = toString(params[6]);
        aparts[10] = '" }]';
        
        string memory strparams = string(abi.encodePacked(aparts[0], aparts[1], aparts[2], aparts[3], aparts[4], aparts[5]));
        strparams = string(abi.encodePacked(strparams, aparts[6], aparts[7], aparts[8], aparts[9], aparts[10]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "OnChain Seaside", "description": "Beautiful views, completely generated OnChain", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        
        //"attributes":', strparams, ', 
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    function claim() public  {
        require(_tokenIdCounter.current() <= 333, "Tokens number to mint exceeds number of public tokens");
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();

    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function buySunsets(uint tokensNumber) public payable {
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber <= maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Tokens number to mint exceeds number of public tokens");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Ether value sent is too low");

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    
}