/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT

// File: Base64.sol



/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
pragma solidity ^0.8.2;

library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
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
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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

// File: booncuk.sol



/*
    
    booncuk
    
*/

pragma solidity ^0.8.2;







contract booncuk is
    ERC721,
    ReentrancyGuard,
    Ownable
{
    using SafeMath for uint256;
    using Strings for uint256;
    using Strings for uint160;
    using Strings for uint8;
    using Base64 for bytes;
    uint256 public booncuk_count;
    string public _description;
    string public _external_url;
    uint MAX_SUPPLY = 128;
    // testnet
    // IERC721 internal BONCUK_CONTRACT = IERC721(0x3EB595bD0C169e61BB18307aeF3717863b9C523c);
    // mainnet
    IERC721 internal BONCUK_CONTRACT = IERC721(0xfa12Fae65134A8F2041a68b88A253D23E7914804);


    mapping(uint256 => uint256) private _dnaBank;
    mapping(uint => bool) private _redeems;

    function redeemBoncuk(uint _b) private {
        _redeems[_b] = true;
    }
    function setDescription(string memory _d) public onlyOwner {
        require(msg.sender == tx.origin);
        _description = _d;
    }
    function setExternalUrl(string memory _u) public onlyOwner {
        require(msg.sender == tx.origin);
        _external_url = _u;
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, _dnaBank[booncuk_count-1])));
    }

    function _mint(address _to) private {
        booncuk_count = booncuk_count.add(1);
        _dnaBank[booncuk_count] = random();
        _safeMint(_to, booncuk_count);
    }

    function mint(uint boncuk_id) public nonReentrant {
        require(msg.sender == tx.origin);
        require(_redeems[boncuk_id] == false, 'this boncuk seems to have minted a booncuk before');
        require(BONCUK_CONTRACT.ownerOf(boncuk_id) == msg.sender, "this boncuk seems not to be yours");
        require(booncuk_count.add(2) <= MAX_SUPPLY, string(abi.encodePacked("only ", MAX_SUPPLY.toString(), " of them will ever exist")));
        redeemBoncuk(boncuk_id);
        _mint(msg.sender);
        // angels' share
        if (booncuk_count % 8 == 7) {
            _mint(address(owner()));
        }
    }
    
    // dna structs
    
    struct s_c {
        string _r;
        string _g;
        string _b;
    }
    
    struct s_e {
        uint r_y;
        uint r_x;
        uint c_y;
        uint c_x;
    }
    
    struct s_r {
        uint r_0;
        uint r_1;
        string r_s;
    }
    
    struct s_boncuk {
        uint e_1_r_x;
        s_c e_1_c;
        s_e e_2;
        s_e e_3;
        s_c e_3_c;
        string e_3_c_a;
        s_e e_4;
        s_r r_;
    }
    
    // TODO: struct _boo mirroring the DNA_Decoded and a new DNA_Decoded with 2 _boo and one e_0_c
    struct DNA_Decoded {
        uint s_;
        string e_0_g;
        uint e_0_r;
        uint e_0_r_x;
        s_boncuk b_1;
        s_boncuk b_2;
    }
    
    // dna helpers
    
    function _g_c(uint _i, uint _p) private pure returns (string memory) {
        return ((_i / (255 ** _p)) % 255).toString();
    }
    
    function g_c(uint _i, uint _o) private pure returns (s_c memory) {
        return s_c(_g_c(_i, (0 + _o)), _g_c(_i, (1 + _o)), _g_c(_i, (2 + _o)));
    }
    
    function g_r_x(uint _i, uint _r, uint _s) private pure returns (uint) {
        return _r - (_r / 20) + ((_i / 64) % (_r / (10 * _s)));
    }
    
    function g_n_r(uint _i, uint _p_r, uint _f) private pure returns (uint) {
        return (_p_r / 2) + ((_i / 128) % (_p_r / _f));
    }
    
    function g_n_c(uint _i, uint _p_r, uint _n_r, uint _p_c, uint _s) private pure returns (uint) {
        uint _d = ((_p_r - _n_r) * 35) / 100;
        return _p_c - _d + ((_i / (255 * _s)) % (_d * 2));
    }

    function g_s_e(uint _i, uint _p_r, uint _p_c_y, uint _p_c_x) private pure returns (s_e memory) {
        uint _n_r = g_n_r(_i, _p_r, 3);
        return s_e(
            _n_r,
            g_r_x(_i, _n_r, 1),
            g_n_c(_i, _p_r, _n_r, _p_c_y, 1),
            g_n_c(_i, _p_r, _n_r, _p_c_x, 2));
    }
    
    function g_s_r(uint _i) private pure returns (s_r memory) {
        uint _r = 360 * ((_i / 1025) % 2);
        return s_r(_r, (360 - _r), (8 + ((_i / 2048) % 25)).toString());
    }
    
    function g_c_a(uint _i, uint _p, uint _d) private pure returns (string memory) {
        return (_d + (_i / 10 ** _p) % 5).toString();
    }
    
    function g_s(uint _i) private pure returns (uint) {
        return 20 + (_i / 1024) % 11;
    }
    
    function g_boo(uint _i) private pure returns (s_boncuk memory) {
        uint e_1_r_x = g_r_x(_i, 512, 2);
        s_c memory e_1_c = g_c(_i, 3);
        s_e memory e_2 = g_s_e(_i, 512, 512, 512);
        s_e memory e_3 = g_s_e(_i, e_2.r_y, e_2.c_y, e_2.c_x);
        s_c memory e_3_c = g_c(_i, 5);
        string memory e_3_c_a = g_c_a(_i, 6, 1);
        s_e memory e_4 = g_s_e(_i, e_3.r_y, e_3.c_y, e_3.c_x);
        s_r memory r_ = g_s_r(_i);
        s_boncuk memory _b = s_boncuk(e_1_r_x, e_1_c, e_2, e_3, e_3_c, e_3_c_a, e_4, r_);
        return _b;
    }    
    // dna decoder
    function decode_dna(uint _i) private view returns (DNA_Decoded memory) {
        uint s_ = g_s(_i);
        uint _i_1 = _dnaBank[_i];
        uint _i_2 = _i_1.div(2);
        s_boncuk memory b_1 = g_boo(_i_1);
        s_boncuk memory b_2 = g_boo(_i_2);
        s_c memory e_0_c = g_c(_i_1, 4);
        uint e_0_r = g_n_r(_i_1, 500, 2);
        uint e_0_r_x = g_r_x(_i_1, e_0_r, 1);
        DNA_Decoded memory d = DNA_Decoded(s_, e_0_c._g, e_0_r, e_0_r_x, b_1, b_2);
        return d;
    }
    
    // render helpers
    
    function s_t(address _o) private pure returns (string memory) {
        string memory _s;
        string memory _t;
        string memory _a = uint160(_o).toHexString();
        {
            _s = '<svg width="1024" height="1024" xmlns="http://www.w3.org/2000/svg"><g>';
            _t = string(abi.encodePacked('<title>', _a, '</title>'));
        }
        return string(abi.encodePacked(_s, _t));
    }
    
    // TODO: e_0
    
    function e_0(DNA_Decoded memory _d) private pure returns (string memory) {
        string memory _a;
        string memory _d_0;
        string memory _r_g_0;
        string memory _s_o_0;
        string memory _s_o_1;
        string memory _s_o_2;
        string memory _r_g_1;
        string memory _d_1;
        string memory _e_0;
        {
            _a = string(
                abi.encodePacked(
                    '<g><animateTransform attributeName="transform" begin="0s" dur="', _d.s_.toString(), 's" type="translate" values="0,0; 12,0; 0,0; -12,0; 0,0" repeatCount="indefinite"/>'));
        }
        {
            _d_0 = '<defs>';
            _r_g_0 = '<radialGradient id="e_0_g">';
        }
        {
            _s_o_0 = '<stop offset="0%" stop-color="#FFF"/>';
            _s_o_1 = string(abi.encodePacked('<stop offset="99%" stop-color="rgb(', _d.e_0_g, ',', _d.e_0_g, ',', _d.e_0_g, ')"/>'));
            _s_o_2 = '<stop offset="100%" stop-color="#7d7d7d"/>';
        }
        {
            _r_g_1 = '</radialGradient>';
            _d_1 = '</defs>';
        }
        {
            _e_0 = string(abi.encodePacked('<ellipse ry="', _d.e_0_r.toString(), '" rx="', _d.e_0_r_x.toString(), '" cy="512" cx="512" fill="url(#e_0_g)"/></g>'));
        }

        return string(abi.encodePacked(_a, _d_0, _r_g_0, _s_o_0, _s_o_1, _s_o_2, _r_g_1, _d_1, _e_0));
    }

    function e_1_2_3_4(s_boncuk memory _b, uint b_i) private pure returns (string memory) {
        string memory _g;
        string memory _a;
        string memory _e_1;
        string memory _e_2;
        string memory _e_3;
        string memory _e_3_f;
        string memory _e_4;
        {
            _g = string(abi.encodePacked('<g transform="scale(0.5), translate(', ((b_i - 1) * 1024).toString(), ',512)">'));
        }
        {
            _a = string(
                abi.encodePacked(
                    '<animateTransform additive="sum" attributeName="transform" begin="0s" dur="', _b.r_.r_s, 's" type="translate" values="0,0; 0,', (b_i == 1 ? '': '-'), '50; 0,0; 0,', (b_i == 2 ? '': '-'), '50; 0,0" repeatCount="indefinite"/><g>'));
        }
        {
            _e_1 = string(abi.encodePacked('<ellipse ry="512" rx="', _b.e_1_r_x.toString(), '" cy="512" cx="512" fill="url(#e_1_g', b_i.toString(), ')"/>'));
        }
        {
            _e_2 = string(
                abi.encodePacked(
                    '<ellipse ry="',_b.e_2.r_y.toString(),
                    '" rx="', _b.e_2.r_x.toString(),
                    '" cy="', _b.e_2.c_y.toString(),
                    '" cx="', _b.e_2.c_x.toString(),
                    '" fill="#FFF"/>'));
        }
        {
            _e_3_f = string(abi.encodePacked('rgba(', _b.e_3_c._r, ',', _b.e_3_c._g, ',', _b.e_3_c._b, ',0.', _b.e_3_c_a,')'));
        }
        {
            _e_3 = string(
                abi.encodePacked(
                    '<ellipse ry="', _b.e_3.r_y.toString(),
                    '" rx="', _b.e_3.r_x.toString(),
                    '" cy="', _b.e_3.c_y.toString(),
                    '" cx="', _b.e_3.c_x.toString(),
                    '" fill="', _e_3_f, '"/>'));
        }
        {
            _e_4 = string(
                abi.encodePacked(
                    '<ellipse ry="', _b.e_4.r_y.toString(),
                    '" rx="', _b.e_4.r_x.toString(),
                    '" cy="', _b.e_4.c_y.toString(),
                    '" cx="', _b.e_4.c_x.toString(),
                    '" fill="rgba(22, 24, 150, 0.8)"/>'));
        }
        return string(abi.encodePacked(_g, _a, _e_1, _e_2, _e_3, _e_4));
    }

    function a_d_r_g(s_boncuk memory _b, uint b_i) private pure returns (string memory) {
        string memory _a;
        string memory _de;
        string memory _r_g;
        {
            _a = string(
                abi.encodePacked(
                    '<animateTransform attributeName="transform" begin="0s" dur="', _b.r_.r_s, 's" type="rotate" from="',
                    _b.r_.r_0.toString(), ' 512 512" to="', _b.r_.r_1.toString(), ' 512 512" repeatCount="indefinite"/>'));
            _de = '<defs>';
           _r_g = string(abi.encodePacked('<radialGradient id="e_1_g', b_i.toString(), '">'));
        }
        return string(abi.encodePacked(_a, _de, _r_g));
    }

    // TODO: takes s_boo instead of DNA_Decoded
    function s_o(s_boncuk memory _b) private pure returns (string memory) {
        string memory _s_o_0;
        string memory _s_o_1;
        string memory _s_o_2;
        string memory _r_g;
        string memory _d;
        string memory _g;
        {
            _s_o_0 = '<stop offset="30%" stop-color="#000"/>';
            _s_o_1 = string(abi.encodePacked('<stop offset="99%" stop-color="rgb(', _b.e_1_c._r, ',', _b.e_1_c._g, ',', _b.e_1_c._b, ')"/>'));
            _s_o_2 = '<stop offset="100%" stop-color="rgba(125,125,125,1)"/>';
        }
        {
            _r_g = '</radialGradient>';
            _d = '</defs>';
            _g = '</g></g>';
        }

        return string(abi.encodePacked(_s_o_0, _s_o_1, _s_o_2, _r_g, _d, _g));
    }

    function g_s() private pure returns (string memory) {
        string memory _s;
        {
            _s = '</g></svg>';
        }
        return string(abi.encodePacked(_s));
    }
    
    function r_bo(s_boncuk memory _b, uint _b_i) private pure returns (string memory) {
        return string(abi.encodePacked(
            e_1_2_3_4(_b, _b_i),
            a_d_r_g(_b, _b_i),
            s_o(_b)
        ));
    }

    // render function

    function render(uint _i) private view returns (string memory) {
        DNA_Decoded memory _d = decode_dna(_i);
        return string(abi.encodePacked(
            s_t(ownerOf(_i)),
            e_0(_d),
            r_bo(_d.b_1, 1),
            r_bo(_d.b_2, 2),
            g_s()
        ));
    }

    // encoded render function

    function render_encoded(uint _i) private view returns (string memory) {
        return string(bytes(abi.encodePacked(render(_i))).encode());
    }
    
    // metadata attributes helpers
    
    function o_w(s_boncuk memory _b) private pure returns (string memory) {
        return ((1000 * (512 - _b.e_1_r_x)) / 512).toString();
    }

    function i_w(s_e memory _s_e) private pure returns (string memory) {
        uint _r_x = _s_e.r_x;
        uint _r_y = _s_e.r_y;
        if (_r_x > _r_y) {
            return ((
                1000 * (_r_x - _r_y)
            ) / _r_x).toString();
        }
        return ((
            1000 * (_r_y - _r_x)
        ) / _r_y).toString();
    }

    function w_a(s_boncuk memory _b, string memory _i) private pure returns (string memory) {
        string memory _s_w;
        string memory _e_w;
        string memory _i_w;
        string memory _p_w;
        {
            _s_w = string(abi.encodePacked('{"trait_type": "', _i, 'eye socket warp", "value": "', o_w(_b)));
        }
        {
            _e_w = string(abi.encodePacked(' promil"}, {"trait_type": "', _i, 'eye warp", "value": "', i_w(_b.e_2)));
        }
        {
            _i_w = string(abi.encodePacked(' promil"}, {"trait_type": "', _i, 'eye iris warp", "value": "', i_w(_b.e_3)));
        }
        {
            _p_w = string(abi.encodePacked(' promil"}, {"trait_type": "', _i, 'eye pupil warp", "value": "', i_w(_b.e_4)));
        }
        return string(
            abi.encodePacked(
                _s_w,
                _e_w,
                _i_w,
                _p_w,
                ' promil"}, '
            )
        );
    }

    function s_a(s_boncuk memory _b, string memory _i) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"trait_type": "', _i, 'eye size", "value": "',
                _b.e_2.r_x.toString(),
                'px"}, {"trait_type": "', _i, 'eye iris size", "value": "',
                _b.e_3.r_x.toString(),
                'px"},  {"trait_type": "', _i, 'eye pupil size", "value": "',
                _b.e_4.r_x.toString(),
                'px"},'
            )
        );
    }

    function c_a(s_boncuk memory _b, string memory _i) private pure returns (string memory) {
        string memory l_c;
        string memory i_c;
        string memory b_c;
        {
            l_c = string(abi.encodePacked('{"trait_type": "', _i, 'eye lid color", "value": "rgb(', _b.e_1_c._r, ', ', _b.e_1_c._g, ', ', _b.e_1_c._b, ')"},'));
        }
        {
            i_c = string(abi.encodePacked('{"trait_type": "', _i, 'eye pupil color", "value": "rgb(', _b.e_3_c._r, ', ', _b.e_3_c._g, ', ', _b.e_3_c._b, ')"},'));
        }
        return string(
            abi.encodePacked(
                l_c,
                i_c,
                b_c
            )
        );
    }

    function r_a(s_boncuk memory _b, string memory _i) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"trait_type": "', _i, 'eye full rotation time", "value": "',
                _b.r_.r_s,
                's"}, {"trait_type": "', _i, 'eye rotation direction", "value": "',
                _b.r_.r_0 == 0 ? 'clockwise' : 'counter-clockwise',
                '"}'
            )
        );
    }
    
    function f_a(DNA_Decoded memory _d) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"trait_type": "face size", "value": "',
                _d.e_0_r.toString(),
                'px"}, {"trait_type": "face color", "value": "rgb(',
                _d.e_0_g, ',', _d.e_0_g, ',', _d.e_0_g,
                ')"},  {"trait_type": "face swing time", "value": "',
                _d.s_.toString(),
                's"},'
            )
        );
    }

    // metadata attribute generation
    
    function getBoncukAttributes(s_boncuk memory _b, string memory _i) private pure returns (string memory) {
        return string(abi.encodePacked(w_a(_b, _i), s_a(_b, _i), c_a(_b, _i), r_a(_b, _i)));
    }

    function getAttributes(uint _i)
        private
        view
        returns (string memory)
    {
        DNA_Decoded memory _d = decode_dna(_i);
        s_boncuk memory b_1 = _d.b_1;
        s_boncuk memory b_2 = _d.b_2;
        return string(abi.encodePacked('[', f_a(_d), getBoncukAttributes(b_1, 'left '), ",", getBoncukAttributes(b_2, 'right '), ']'));
    }
    
    // tokenURI for ERC721

    function tokenURI(uint256 _i)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        super.tokenURI(_i);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    bytes(
                        abi.encodePacked(
                            '{"attributes": ', getAttributes(_i),
                            ', "name": "booncuk #', _i.toString(),
                            '", "description": "', _description,
                            '", "external_url": "', _external_url,
                            '", "image": "data:image/svg+xml;base64,',
                            render_encoded(_i),
                            '"}'
                        )
                    ).encode(),
                    "#"
                )
            );
    }
    
    // contractURI for OpenSea
  
    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    bytes(
                        abi.encodePacked(
                            '{"name": "booncuk", "description": "', _description,
                            '", "external_link": "', _external_url,
                            '"}'
                        )
                    ).encode()
                )
            );
    }
    
    // Derived 721 contract must override function “supportsInterface”

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
     
    // constructor populating description, externalUrl, and the genesis NFT for the contractURI

    constructor()
        ERC721("booncuk", "booncuk")
        onlyOwner
    {
        setDescription(string(abi.encodePacked(MAX_SUPPLY.toString(), " on-mint generated, on-chain stored and displayed evil eye pairs")));
        setExternalUrl("https://booncuk.wtf");
        mint(1);
    }
}