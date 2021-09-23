/**
 *Submitted for verification at Etherscan.io on 2021-09-23
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

// File: doge.sol

contract OnChainDoge is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    uint private constant maxTokensPerTransaction = 30;
    uint256 private tokenPrice = 30000000000000000; //0.03 ETH
    uint256 private constant nftsNumber = 3333;
    uint256 private constant nftsPublicNumber = 3300;
    
    constructor() ERC721("ChainTesting", "CD") {
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
    

     function tokenURI(uint256 tokenId) pure public override(ERC721)  returns (string memory) {
        string[20] memory parts;

        //uint256 rand = random(string(abi.encodePacked('Doges',toString(tokenId))));
        
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" style="background-color:#845ec2" viewBox="-120 -110 1001 1001"><g data-name="Doge"><animateMotion dur="4s" path="m 0, 0 a 75,75 0 1,0 150,0 a 75,75 0 1,0 -150,0" repeatCount="indefinite"/>';
        parts[1] = '<path d="M570 524h16v15h-16z"fill="#e6c890"/><path d="M570 509"fill="#e2ca8e"/><path d="M570 478"fill="#e6c890"/><path d="M555 478"fill="#e6c890"/><path d="M555 447h15v15h-15z"fill="#c49141"/><path d="M539 601h16v15h-16z"fill="#e6c890"/><path d="M539 539h16v16h16z"fill="#e2ca8e"/><path d="M539 493h16v16h-16z"fill="#e6c890"/><path d="M539 478"fill="#c49141"/><path d="M524 709"fill="#ce973b"/><path d="M524 616hfill="fill="#e6c890"/><path d="M524 539hfill="fill="#e2ca8e"/><path d="M524 509h15v15h-15z"fill="#e6c890"/>';
        parts[2] = '<path d="M524 493hfill="fill="#c49141"/><path d="M509 709h15v15h-15z"fill="#ce973b"/><path d="M509 647hfill="fill="#e6c890"/><path d="M509 555"fill="#e2ca8e"/><path d="M509 524h15v15h-15z"fill="#e6c890"/><path d="M509 509"fill="#c49141"/><path d="M509 478"fill="#b6782e"/><path d="M509 447"fill="#c49141"/><path d="M493 724h16v16h-16z"fill="#ce973b"/><path d="M493 663h16v15h-16z"fill="#e6c890"/><path d="M493 524"fill="#c49141"/><path d="M493 493h16v16h16z"fill="#b6782e"/><path d="M493 447"fill="#c49141"/>';
        parts[3] = '<path d="M493 154h16v16h31h16v15h- 15h16v16h31h16v16h16z"fill="#794a1b"/><path d="M478 724hfill="fill="#ce973b"/><path d="M478 678h15v15h-15z"fill="#e6c890"/><path d="M478 539hfill="fill="#b6782e"/><path d="M478 462hfill="fill="#c49141"/><path d="M478 139"fill="#794a1b"/><path d="M478 92hfill="fill="#c49141"/><path d="M478 62"fill="#794a1b"/><path d="M462 740"fill="#e2ca8e"/><path d="M462 709h16v15h-16z"fill="#ce973b"/><path d="M462 693h16v16h-16z"fill="#e6c890"/><path d="M462 555"fill="#b6782e"/>';
        parts[4] = '<path d="M462 478"fill="#c49141"/><path d="M462 370h16v15h-16z"fill="#ce973b"/><path d="M462 354h16v16h-16z"fill="#c49141"/><path d="M462 92h16v16h16z"fill="#794a1b"/><path d="M462 62"fill="#c08d3b"/><path d="M447 693h15v16h-15z"fill="#e6c890"/><path d="M447 555h15v15h-15z"fill="#b6782e"/><path d="M447 493hfill="fill="#c49141"/><path d="M447 370h15v15h-15z"fill="#ce973b"/><path d="M447 354hfill="fill="#faebc3"/><path d="M447 262"fill="#c49141"/><path d="M447 108h15v15h-15z"fill="#794a1b"/><path d="M447 46hfill="fill="#c49141"/>';
        parts[5] = '<path d="M431 693h16v16h16z"fill="#e6c890"/><path d="M431 570h16v16h16z"fill="#b6782e"/><path d="M431 493h16v16h16z"fill="#c49141"/><path d="M431 416h16v15h-16z"fill="#e6c890"/><path d="M431 354h16v16h16z"fill="#faebc3"/><path d="M431 247h16v15h-16z"fill="#c08d3b"/><path d="M431 231h16v16h16z"fill="#c49141"/><path d="M431 108"fill="#794a1b"/><path d="M431 62"fill="#c49141"/><path d="M416 693hfill="fill="#e6c890"/><path d="M416 586h15v15h-15z"fill="#debe74"/><path d="M416 570h15v16h-15z"fill="#b6782e"/>';
        parts[6] = '<path d="M416 555"fill="#e6c890"/><path d="M416 509"fill="#c49141"/><path d="M416 462h15v16h-15z"fill="#e6c890"/><path d="M416 401h15v15h-15z"fill="#debe74"/><path d="M416 385hfill="fill="#e6c890"/><path d="M416 354hfill="fill="#faebc3"/><path d="M416 247h15v15h-15z"fill="#c08d3b"/><path d="M416 231h15v16h-15z"fill="#c49141"/><path d="M401 693hfill="fill="#e6c890"/><path d="M401 601"fill="#debe74"/><path d="M401 555h15v15h-15z"fill="#e6c890"/><path d="M401 416"fill="#debe74"/><path d="M401 385hfill="fill="#e6c890"/>';
        parts[7] = '<path d="M401 354hfill="fill="#faebc3"/><path d="M401 247h15v15h-15z"fill="#c08d3b"/><path d="M401 231hfill="fill="#c49141"/><path d="M401 108"fill="#794a1b"/><path d="M401 77"fill="#c49141"/><path d="M385 693h16v16h16z"fill="#e6c890"/><path d="M385 616h16v16h-16z"fill="#debe74"/><path d="M385 555"fill="#e6c890"/><path d="M385 447"fill="#debe74"/><path d="M385 401"fill="#e6c890"/><path d="M385 354h16v16h16z"fill="#faebc3"/><path d="M385 247h16v15h-16z"fill="#c08d3b"/><path d="M385 231h16v16h16z"fill="#c49141"/>';
        parts[8] = '<path d="M385 123h16v16h16z"fill="#794a1b"/><path d="M385 92h16v16h16z"fill="#c49141"/><path d="M370 693h15v16h-15z"fill="#e6c890"/><path d="M370 632"fill="#debe74"/><path d="M370 539hfill="fill="#e6c890"/><path d="M370 462h15v16h-15z"fill="#debe74"/><path d="M370 401"fill="#e6c890"/><path d="M370 354hfill="fill="#faebc3"/><path d="M370 247h15v15h-15z"fill="#c08d3b"/><path d="M370 231h15v16h-15z"fill="#c49141"/><path d="M354 370"fill="#faebc3"/><path d="M354 247h16v15h-16z"fill="#c08d3b"/><path d="M339 663"fill="#debe74"/>';
        parts[9] = '<path d="M339 539h15v16h-15z"fill="#e6c890"/><path d="M339 524"fill="#debe74"/><path d="M339 416"fill="#e6c890"/><path d="M339 370"fill="#faebc3"/><path d="M339 247h15v15h-15z"fill="#c08d3b"/><path d="M339 231h15v16h-15z"fill="#c49141"/><path d="M324 755hfill="fill="#e2ca8e"/><path d="M324 663"fill="#debe74"/><path d="M324 555h15v15h-15z"fill="#e6c890"/><path d="M324 539hfill="fill="#debe74"/><path d="M324 431hfill="fill="#e6c890"/><path d="M324 385hfill="fill="#faebc3"/><path d="M324 293"fill="#c49141"/>';
        parts[10] = '<path d="M324 247"fill="#c08d3b"/><path d="M324 216h15v15h-15z"fill="#c49141"/><path d="M308 755h16v16h16z"fill="#e2ca8e"/><path d="M308 678"fill="#debe74"/><path d="M308 447h16v15h-16z"fill="#e6c890"/><path d="M308 385h16v16h16z"fill="#faebc3"/><path d="M308 293"fill="#c49141"/><path d="M308 262h16v15h-16z"fill="#1d1d1b"/><path d="M308 247h16v15h-16z"/><path d="M308 231h16v16h-16z"fill="#c08d3b"/><path d="M308 216h16v15h-16z"fill="#c49141"/><path d="M293 755hfill="fill="#e2ca8e"/><path d="M293 678"fill="#debe74"/>';
        parts[11] = '<path d="M293 570hfill="fill="#ddaa5a"/><path d="M293 539h15v16h-15z"fill="#c49141"/><path d="M293 524h15v15h-15z"fill="#debe74"/><path d="M293 462hfill="fill="#e6c890"/><path d="M293 385hfill="fill="#faebc3"/><path d="M293 308hfill="fill="#c49141"/><path d="M293 277h15v16h-15z"fill="#1d1d1b"/><path d="M293 262"/><path d="M293 231h15v16h-15z"fill="#1d1d1b"/><path d="M293 216h15v15h-15z"fill="#c49141"/><path d="M293 200hfill="fill="#c08d3b"/><path d="M293 154hfill="fill="#c49141"/><path d="M277 755h16v16h-16z"fill="#e2ca8e"/>';
        parts[12] = '<path d="M277 693h16v16h16z"fill="#debe74"/><path d="M277 586"fill="#ddaa5a"/><path d="M277 539h16v16h-16z"fill="#c49141"/><path d="M277 524"fill="#debe74"/><path d="M277 478h16v15h-16z"fill="#e6c890"/><path d="M277 416"fill="#e7c98a"/>';
        parts[13] = '</svg>';
        //parts[2] = '<path d="M277 385h16v16h16z"fill="#faebc3"/><path d="M92 370h16v15H92zm0-16h16v16H92zm0-15h16v15H92zm0-15h16v15H92zm0-16h16v16H92z"/><path d="M108 354h15v16h-15zm0-15h15v15h-15zm0-15h15v15h-15zm0-16h15v16h-15z"/><path d="M77 354h15v16H77zm0-15h15v15H77zm0-15h15v15H77zm0-16h15v16H77z"/><path d="M123 216h16v15h-16zm0-16h16v16h-16z"/><path d="M277 308h16v16h16z"fill="#c49141"/><path d="M277 277h16v16h-16z"fill="#1d1d1b"/><path d="M277 262h16v15h-16z"/><path d="M277 247h16v15h-16z"fill="#fff"/><path d="M277 231h16v16h-16z"/><path d="M277 216h16v15h-16z"fill="#dead57"/><path d="M277 200h16v16h16z"fill="#e0ab5a"/><path d="M277 170h16v15h-16z"fill="#c08d3b"/><path d="M277 154h16v16h16z"fill="#c49141"/><path d="M262 755hfill="fill="#e2ca8e"/><path d="M262 709"fill="#debe74"/><path d="M262 601"fill="#ddaa5a"/><path d="M262 555h15v15h-15z"fill="#c49141"/><path d="M262 539h15v16h-15z"fill="#debe74"/><path d="M262 478h15v15h-15z"fill="#e6c890"/><path d="M262 416"fill="#e7c98a"/><path d="M262 385hfill="fill="#faebc3"/><path d="M262 308hfill="fill="#c49141"/><path d="M262 277h15v16h-15z"fill="#dbdbdb"/><path d="M262 262h15v15h-15z"fill="#fff"/><path d="M262 247h15v15h-15z"/><path d="M262 231h15v16h-15z"fill="#7a592b"/><path d="M262 216h15v15h-15z"fill="#dead57"/><path d="M262 200hfill="fill="#e0ab5a"/><path d="M262 170h15v15h-15z"fill="#c08d3b"/><path d="M262 154hfill="fill="#c49141"/><path d="M247 755hfill="fill="#e2ca8e"/><path d="M247 709"fill="#debe74"/><path d="M247 616h15v16h-15z"fill="#ddaa5a"/><path d="M247 555h15v15h-15z"fill="#c49141"/><path d="M247 539hfill="fill="#debe74"/><path d="M247 493hfill="fill="#e6c890"/><path d="M247 447"fill="#debe74"/><path d="M247 416"fill="#e7c98a"/><path d="M247 370h15v15h-15z"fill="#faebc3"/><path d="M247 308hfill="fill="#c49141"/><path d="M247 277h15v16h-15z"fill="#1d1d1b"/><path d="M247 262h15v15h-15z"/><path d="M247 247h15v15h-15z"fill="#7a592b"/><path d="M247 231h15v16h-15z"fill="#dead57"/><path d="M247 216"fill="#e0ab5a"/><path d="M247 170h15v15h-15z"fill="#c08d3b"/><path d="M247 154hfill="fill="#c49141"/><path d="M231 755h16v16h16z"fill="#e2ca8e"/><path d="M231 724h16v16h16z"fill="#debe74"/><path d="M231 632h16v15h-16z"fill="#ddaa5a"/><path d="M231 570h16v16h16z"fill="#c49141"/><path d="M231 539h16v16h16z"fill="#debe74"/><path d="M231 493h16v16h16z"fill="#e6c890"/><path d="M231 447h16v15h-16z"fill="#debe74"/><path d="M231 431h16v16h16z"fill="#e7c98a"/><path d="M231 401"fill="#e4c489"/><path d="M231 354h16v16h-16z"fill="#e0ab5a"/><path d="M231 293"fill="#c49141"/><path d="M231 262"fill="#dead57"/><path d="M231 231h16v16h16z"fill="#c49141"/><path d="M231 200h16v16h-16z"fill="#e0ab5a"/><path d="M231 185h16v15h-16z"fill="#c08d3b"/><path d="M231 170h16v15h-16z"fill="#c49141"/><path d="M231 154h16v16h-16z"fill="#b47a2c"/><path d="M231 92h16v16h16z"fill="#c49141"/><path d="M216 755hfill="fill="#e2ca8e"/><path d="M216 724hfill="fill="#debe74"/><path d="M216 647h15v16h-15z"fill="#ddaa5a"/><path d="M216 586"fill="#c49141"/><path d="M216 539hfill="fill="#debe74"/><path d="M216 493hfill="fill="#e6c890"/><path d="M216 462hfill="fill="#debe74"/><path d="M216 431hfill="fill="#e7c98a"/><path d="M216 354hfill="fill="#e0ab5a"/><path d="M216 277hfill="fill="#c49141"/><path d="M216 231h15v16h-15z"fill="#e0ab5a"/><path d="M216 216h15v15h-15z"fill="#c49141"/><path d="M216 200h15v16h-15z"fill="#c08d3b"/><path d="M216 185h15v15h-15z"fill="#c49141"/><path d="M216 170h15v15h-15z"fill="#b47a2c"/><path d="M216 154hfill="fill="#c49141"/><path d="M216 77h15v15h-15z"fill="#c08d3b"/><path d="M200 755h16v16h-16z"fill="#e2ca8e"/><path d="M200 740"fill="#debe74"/><path d="M200 663"fill="#ddaa5a"/><path d="M200 616h16v16h-16z"fill="#c49141"/><path d="M200 555h16v15h-16z"fill="#debe74"/><path d="M200 493h16v16h-16z"fill="#e6c890"/><path d="M200 478"fill="#debe74"/><path d="M200 431h16v16h-16z"fill="#584d39"/><path d="M200 416"fill="#e7c98a"/><path d="M200 370"fill="#e9d7a7"/><path d="M200 339h16v15h-16z"fill="#e0ab5a"/><path d="M200 277h16v16h16z"fill="#c49141"/><path d="M200 247"fill="#e0ab5a"/><path d="M200 216"fill="#c08d3b"/><path d="M200 170"fill="#c49141"/><path d="M200 139"fill="#e0ab5a"/><path d="M200 92h16v16h16z"fill="#c49141"/><path d="M200 46h16v16h-16z"fill="#c08d3b"/><path d="M185 755hfill="fill="#debe74"/><path d="M185 663h15v15h-15z"fill="#ddaa5a"/><path d="M185 647h15v16h-15z"fill="#dfab5a"/><path d="M185 632"fill="#c49141"/><path d="M185 555"fill="#debe74"/><path d="M185 431h15v16h-15z"fill="#584d39"/><path d="M185 416"fill="#e7c98a"/><path d="M185 385hfill="fill="#e9d7a7"/><path d="M185 354h15v16h-15zm-15 0h15v16h-15z"fill="#fcfafa"/><path d="M185 339"fill="#e6bc7a"/><path d="M185 308hfill="fill="#e0ab5a"/><path d="M185 231hfill="fill="#c08d3b"/><path d="M185 154hfill="fill="#e0ab5a"/><path d="M185 77"fill="#794a1b"/><path d="M185 31"fill="#c08d3b"/><path d="M170 755hfill="fill="#debe74"/><path d="M170 663h15v15h-15z"fill="#ddaa5a"/><path d="M170 601"fill="#c49141"/><path d="M170 555"fill="#debe74"/><path d="M170 431h15v16h-15z"fill="#584d39"/><path d="M170 416"fill="#e7c98a"/><path d="M170 385h15v16h31h15v15h-15z"fill="#fff"/><path d="M170 324h15v15h-15z"fill="#e6bc7a"/><path d="M170 308hfill="fill="#e0ab5a"/><path d="M170 231hfill="fill="#c08d3b"/><path d="M170 185"fill="#e0ab5a"/><path d="M170 62"fill="#794a1b"/><path d="M170 15hfill="fill="#c08d3b"/><path d="M154 755h16v16h16z"fill="#debe74"/><path d="M154 647h16v16h16z"fill="#ddaa5a"/><path d="M154 601"fill="#c49141"/><path d="M154 555"fill="#debe74"/><path d="M154 447h16v15h-16z"fill="#e7c98a"/><path d="M154 431h16v16h-16z"fill="#584d39"/><path d="M154 416h16v15h-16z"fill="#dedad8"/><path d="M154 401h16v15h-16z"fill="#e7c98a"/><path d="M154 385h16v16h-16z"fill="#fff"/><path d="M154 370"fill="#dedad8"/><path d="M154 339"/><path d="M154 308h16v16h-16z"fill="#e0ab5a"/><path d="M154 247h16v15h-16z"fill="#c08d3b"/><path d="M154 231h16v16h-16z"/><path d="M154 216h16v15h-16z"fill="#1d1d1b"/><path d="M154 200h16v16h-16z"/><path d="M154 185"fill="#c08d3b"/><path d="M154 154h16v16h16z"fill="#e0ab5a"/><path d="M139 755hfill="fill="#debe74"/><path d="M139 632"fill="#ddaa5a"/><path d="M139 586"fill="#c49141"/><path d="M139 555"fill="#debe74"/><path d="M139 431h15v16h-15z"fill="#584d39"/><path d="M139 416h15v15h-15z"fill="#0e090e"/><path d="M139 401h15v15h-15z"fill="#dedad8"/><path d="M139 385h15v16h-15z"fill="#89816e"/><path d="M139 370"fill="#dedad8"/><path d="M139 339"/><path d="M139 293"fill="#e0ab5a"/><path d="M139 262h15v15h-15z"fill="#c08d3b"/><path d="M139 247h15v15h-15z"fill="#74512b"/><path d="M139 231h15v16h-15z"/><path d="M139 216h15v15h-15z"fill="#fff"/><path d="M108 247h15v15h-15z"/><path d="M123 247h16v15h-16z"fill="#fff"/><path d="M139 200h15v16h-15z"/><path d="M139 185h15v15h-15z"fill="#c08d3b"/><path d="M139 170"fill="#e0ab5a"/><path d="M123 740"fill="#debe74"/><path d="M123 616h16v16h16z"fill="#ddaa5a"/><path d="M123 570h16v16h16z"fill="#c49141"/><path d="M123 539h16v16h16z"fill="#debe74"/><path d="M123 431h16v16h-16z"fill="#584d39"/><path d="M123 416h16v15h-16z"fill="#0e090e"/><path d="M123 401"fill="#89816e"/><path d="M123 370h16v15h-16z"fill="#b2afa4"/><path d="M123 354h16v16h-16z"/><path d="M123 293h16v15h-16z"fill="#e6bc7a"/><path d="M123 277h16v16h-16z"fill="#e0ab5a"/><path d="M123 262h16v15h-16z"fill="#74512b"/><path d="M123 231h16v16h-16z"fill="#dbdbdb"/><path d="M123 216"/><path d="M123 185h16v15h-16z"fill="#c08d3b"/><path d="M123 170"fill="#e0ab5a"/><path d="M108 601"fill="#ddaa5a"/><path d="M108 555"fill="#c49141"/><path d="M108 524"fill="#debe74"/><path d="M108 431h15v16h-15z"fill="#584d39"/><path d="M108 416h15v15h-15z"fill="#0e090e"/><path d="M108 401"fill="#89816e"/><path d="M108 370h15v15h-15z"fill="#b2afa4"/><path d="M108 354h15v16h-15z"/><path d="M108 293h15v15h-15z"fill="#e6bc7a"/><path d="M108 277hfill="fill="#e0ab5a"/><path d="M108 231hfill="/><path d="M108 200hfill="fill="#e0ab5a"/><path d="M92 586h16v15H92zm092z"fill="#ddaa5a"/><path d="M92 539h16v16H92zm092z"fill="#c49141"/><path d="M92 509h16v15H92zm092z"fill="#debe74"/><path d="M92 431h16v16H92z"fill="#51433b"/><path d="M92 416h16v15H92z"fill="#0e090e"/><path d="M92 401h16v15H92zm092z"fill="#89816e"/><path d="M92 370h16v15H92zm092z"/><path d="M92 293h16v15H92z"fill="#e6bc7a"/><path d="M92 277h16v16H92zm092z"fill="#e0ab5a"/><path d="M77 570h15v16H77zm077zm077z"fill="#ddaa5a"/><path d="M77 524h15v15H77z"fill="#c49141"/><path d="M77 509h15v15H77zm077zm077zm077zm077z"fill="#debe74"/><path d="M77 431h15v16H77z"fill="#dedad8"/><path d="M77 416h15v15H77zm077z"fill="#0e090e"/><path d="M77 385h15v16H77z"fill="#89816e"/><path d="M77 370h15v15H77z"fill="#dedad8"/><path d="M77 354h15v16H77zm077zm077zm077z"/><path d="M77 293h15v15H77zm077z"fill="#e9d7a7"/><path d="M77 262h15v15H77z"fill="#e0ab5a"/><path d="M77 247h15v15H77zm077zm077zm077z"fill="#e9d7a7"/><path d="M77 185h15v15H77zm077zm077z"fill="#e0ab5a"/><path d="M62 555h15v15H62zm"fill="#ddaa5a"/><path d="M62 524h15v15H62zm"fill="#c49141"/><path d="M62 493h15v16H62zm"fill="#debe74"/><path d="M62 447h15v15H62zm"fill="#e9d7a7"/><path d="M62 370h15v15H62z"fill="#dedad8"/><path d="M62 354h15v16H62zm"/><path d="M62 324h15v15H62z"fill="#dedad8"/><path d="M62 308h15v16H62zm"fill="#e9d7a7"/><path d="M62 185h15v15H62zm"fill="#e0ab5a"/><path d="M46 555h16v15H46zm"fill="#ddaa5a"/><path d="M46 509h16v15H46zm"fill="#debe74"/><path d="M46 462h16v16H46zm"fill="#e9d7a7"/><path d="M46 216h16v15H46zm"fill="#e0ab5a"/><path d="M31 462h15v16H31zm031z"fill="#e9d7a7"/><path d="M31 231h15v16H31zm031z"fill="#e0ab5a"/></g></svg>';

        string memory output = string(abi.encodePacked(parts[0],parts[1],parts[2]));
        output = string(abi.encodePacked(output, parts[3],parts[4],parts[5]));
        output = string(abi.encodePacked(output, parts[6],parts[7],parts[8]));
        output = string(abi.encodePacked(output, parts[9],parts[10],parts[11],parts[12],parts[13]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "ChainTesting", "description": "Test, completely generated OnChain", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
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