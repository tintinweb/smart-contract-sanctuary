// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {CanvasManager} from "./CanvasManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ClaimProxy2
contract ClaimProxy2 {
    // ============ Variables ============

    // Mapping from nftId to contributor claim amount list
    mapping(uint256 => mapping(address => uint256)) public _data;

    CanvasManager public immutable _manager;
    IERC20 public immutable _token;

    // ========== Constructor function ==========

    constructor(CanvasManager canvas, IERC20 token) {
        _manager = canvas;
        _token = token;
    }

    // ========== External functions ==========

    function getAmount(uint256 nftId, address contributor) external view returns (uint256) {
        return _data[nftId][contributor];
    }

    function claimeArtAuctionFee(uint256 nftId, address contributor) external {
        if (contributor == address(0)) {
            contributor = msg.sender;
        }

        uint256 oldBalance = _token.balanceOf(contributor);
        _manager.claimeArtAuctionFee(nftId, contributor);
        uint256 newBalance = _token.balanceOf(contributor);
        require(newBalance > oldBalance, "ClaimProxy: no claim");
        _data[nftId][contributor] += newBalance - oldBalance;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
// Reproduced from https://github.com/ourzora/auction-house/blob/main/contracts/interfaces/IAuctionHouse.sol under terms of GPL-3.0
// Modified slightly

pragma solidity ^0.8.0;

/**
 * @title Interface for Auction Houses
 */
interface IZoraAuctionHouse {
    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract
        address tokenContract;
        // Whether or not the auction curator has approved the auction to start
        bool approved;
        // The current highest bid amount
        uint256 amount;
        // The length of time to run the auction for, after the first bid was made
        uint256 duration;
        // The time of the first bid
        uint256 firstBidTime;
        // The minimum price of the first bid
        uint256 reservePrice;
        // The sale percentage to send to the curator
        uint8 curatorFeePercentage;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
        // The address of the current highest bid
        address payable bidder;
        // The address of the auction's curator.
        // The curator can reject or approve an auction
        address payable curator;
        // The address of the ERC-20 currency to run the auction with.
        // If set to 0x0, the auction will be run in ETH
        address auctionCurrency;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address tokenOwner,
        address curator,
        uint8 curatorFeePercentage,
        address auctionCurrency
    );

    event AuctionApprovalUpdated(uint256 indexed auctionId, uint256 indexed tokenId, address indexed tokenContract, bool approved);

    event AuctionReservePriceUpdated(uint256 indexed auctionId, uint256 indexed tokenId, address indexed tokenContract, uint256 reservePrice);

    event AuctionBid(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address sender,
        uint256 value,
        bool firstBid,
        bool extended
    );

    event AuctionDurationExtended(uint256 indexed auctionId, uint256 indexed tokenId, address indexed tokenContract, uint256 duration);

    event AuctionEnded(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,
        address curator,
        address winner,
        uint256 amount,
        uint256 curatorFee,
        address auctionCurrency
    );

    event AuctionCanceled(uint256 indexed auctionId, uint256 indexed tokenId, address indexed tokenContract, address tokenOwner);

    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address payable curator,
        uint8 curatorFeePercentages,
        address auctionCurrency
    ) external returns (uint256);

    function setAuctionApproval(uint256 auctionId, bool approved) external;

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice) external;

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICanvas {
    // ============ Events ============

    event NewArt(address indexed who, uint256 indexed nftId, uint256 startTime, uint256 endTime);

    event SetEndTime(address indexed who, uint256 indexed nftId, uint256 endTime);

    event EndArt(address indexed who, uint256 indexed nftId);

    event DrawPixel(address indexed who, uint256 indexed nftId, uint256 indexed momentId, uint256 index, uint24 color, uint256 bidPrice);

    // ============ Functions ============

    function getMoment(uint256 uMomentId)
        external
        view
        returns (
            uint24[1024] memory colors,
            uint256 momentIndex,
            uint256 artId
        );

    function getMomentColors(uint256 uMomentId) external view returns (uint24[1024] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArtAuction {
    // ============ Enums ============

    enum MarketType {
        Unknown,
        Zora
    }

    // ============ Events ============

    event NewArtAuctionContract(
        address indexed me,
        uint256 allNftShares,
        uint256 thisNftShares,
        uint256 indexed nftId,
        address indexed market,
        address auctionCurrency,
        MarketType marketType
    );

    event OnERC721Receive(address indexed me, address operator, address from, uint256 indexed tokenId);

    event CreateArtAuction(
        address indexed me,
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        uint256 duration,
        uint256 reservePrice,
        address auctionCurrency
    );

    event SetArtAuctionApproval(address indexed me, uint256 indexed tokenId, uint256 indexed auctionId, bool approved);

    event SetArtAuctionReservePrice(address indexed me, uint256 indexed auctionId, uint256 indexed tokenId, uint256 reservePrice);

    event CancelArtAuction(address indexed me, uint256 indexed auctionId, uint256 indexed tokenId);

    event EndArtAuction(address indexed me, uint256 indexed auctionId, uint256 indexed tokenId);

    event ClaimeArtAuctionFee(
        address indexed me,
        address indexed who,
        address indexed contributor,
        uint256 thisNftShare,
        uint256 allNftShare,
        uint256 totalPayment,
        uint256 pendingPayment
    );

    event ClaimeCuratorFee(address indexed me, address indexed who, address indexed to, uint256 totalPayment, uint256 pendingPayment);

    // ============ Functions ============

    function marketType() external pure returns (MarketType);

    function getArtAuctionId() external view returns (uint256);

    function getAuctionCurrency() external view returns (address);

    function setAuctionCurrency(address newCurrency) external;

    function createArtAuction(uint256 duration, uint256 reservePrice) external returns (uint256);

    function getArtAuctionInfo()
        external
        view
        returns (
            uint256 auctionId,
            uint256 reservePrice,
            uint256 beginTime,
            uint256 duration,
            address owner,
            address auctionCurrency,
            uint8 state,
            bool approved
        );

    function getProfitInfo()
        external
        view
        returns (
            uint256 totalSharesOfThisNft,
            uint256 totalSharesOfAllNft,
            uint256 amount
        );

    function getArtAuctionApproval() external view returns (bool);

    function setArtAuctionApproval(bool approved) external;

    function getArtAuctionReservePrice() external view returns (uint256);

    function setArtAuctionReservePrice(uint256 reservePrice) external;

    function cancelArtAuction() external;

    function endArtAuction() external;

    function claimeArtAuctionFee(
        address contributor,
        uint256 thisNftShare,
        uint256 allNftShare
    ) external;

    function claimeCuratorFee(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));
    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({nonce: nonces[userAddress], from: userAddress, functionSignature: functionSignature});

        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return keccak256(abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from, keccak256(metaTx.functionSignature)));
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return signer == ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"));
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(ERC712_VERSION)), address(this), bytes32(getChainId()))
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IZoraAuctionHouse} from "./interfaces/IZoraAuctionHouse.sol";
import {IArtAuction} from "./interfaces/IArtAuction.sol";

/// @title ZoraAuction contract
/// @author Daniel Liu
/// @dev owner is CanvasManager
contract ZoraAuction is IArtAuction, IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;

    // ============ Enums ============

    // ============ Constants ============

    uint256 internal constant MAX_ID = type(uint256).max;

    // ============ Structs ============

    // ============ Variables ============

    address internal immutable _nftContract; // nft contract address
    uint256 internal immutable _nftId; // nft id
    uint256 internal immutable _totalSharesOfThisNft; // moment count of this NFT
    uint256 internal immutable _totalSharesOfAllNft; // total moment count of all NFTs before this NFT

    uint256 internal _beginTime = 0; // the start time of auction
    uint256 internal _totalPaid = 0; // total paid fee, includes _curatorPaid
    uint256 internal _curatorPaid = 0; // curator paid fee
    mapping(address => uint256) internal _alreadyPaids; // already paids

    uint256 internal _auctionId = MAX_ID;
    uint256 internal _reservePrice = 0;
    uint256 internal _duration = 0;
    address internal _market;
    address internal _auctionCurrency;
    bool internal _approved = false;

    // ============ Events ============

    // ============ Constructor function ============

    constructor(
        uint256 allNftShares,
        uint256 thisNftShares,
        uint256 nftId,
        address nftContract,
        address market,
        address auctionCurrency
    ) {
        require(allNftShares >= thisNftShares, "ZA1");
        require(thisNftShares > 0, "ZA2");
        require(nftId != 0, "ZA3");
        require(nftContract != address(0), "ZA4");
        require(market != address(0), "ZA5");
        require(auctionCurrency != address(0), "ZA6");

        _totalSharesOfAllNft = allNftShares;
        _totalSharesOfThisNft = thisNftShares;
        _nftId = nftId;
        _nftContract = nftContract;
        _market = market;
        _auctionCurrency = auctionCurrency;

        emit NewArtAuctionContract(address(this), allNftShares, thisNftShares, nftId, market, auctionCurrency, MarketType.Zora);
    }

    // ============ Receive function ============

    // ============ Fallback function ============

    // ============ Modifier functions ============

    /// @notice Require the auction is not started
    modifier auctionNotStarted() {
        address tokenOwner = IERC721(_nftContract).ownerOf(_nftId);
        require(tokenOwner == address(this), "ANS");
        _;
    }

    /// @notice Require the auction is exist
    modifier auctionInProcess() {
        address tokenOwner = IERC721(_nftContract).ownerOf(_nftId);
        require(tokenOwner == _market, "AIP");
        _;
    }

    // ============ External functions ============

    function marketType() external pure returns (MarketType) {
        return MarketType.Zora;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata /* data */
    ) external returns (bytes4) {
        emit OnERC721Receive(address(this), operator, from, tokenId);
        return this.onERC721Received.selector;
    }

    /// @return _auctionId
    function getArtAuctionId() external view returns (uint256) {
        return _auctionId;
    }

    /// @return the currency address
    function getAuctionCurrency() external view returns (address) {
        return _auctionCurrency;
    }

    /// @dev change auction currency before acution, only callable by owner CanvasManager.
    /// @param auctionCurrency new auction currency address
    function setAuctionCurrency(address auctionCurrency) external onlyOwner auctionNotStarted {
        require(auctionCurrency != address(0), "SAC");
        _auctionCurrency = auctionCurrency;
    }

    /// @notice Create an auction at zora AuctionHouse and store auction id, emits CreateArtAuction event.
    /// @dev only callable by owner CanvasManager.
    /// @param duration The length of time to run the auction for, after the first bid was made
    /// @param reservePrice The minimum price of the first bid
    /// @return auctionId
    function createArtAuction(uint256 duration, uint256 reservePrice) external onlyOwner auctionNotStarted returns (uint256) {
        require(duration > 0 && reservePrice > 0, "CRT");

        IERC721(_nftContract).approve(_market, _nftId);
        _auctionId = IZoraAuctionHouse(_market).createAuction(
            _nftId, // tokenId
            _nftContract, // tokenContract
            duration, // duration
            reservePrice, // reservePrice
            payable(address(this)), // curator
            0, // curatorFeePercentages
            _auctionCurrency // auctionCurrency
        );

        _approved = true;
        _duration = duration;
        _reservePrice = reservePrice;
        _beginTime = block.timestamp;

        emit CreateArtAuction(address(this), _auctionId, _nftId, duration, reservePrice, _auctionCurrency);

        return _auctionId;
    }

    /// @return totalSharesOfThisNft The total shares of this NFT
    /// @return totalSharesOfAllNft The total shares of all NFT when this NFT is created
    /// @return amount The received tokens of this contract
    function getProfitInfo()
        external
        view
        returns (
            uint256 totalSharesOfThisNft,
            uint256 totalSharesOfAllNft,
            uint256 amount
        )
    {
        totalSharesOfThisNft = _totalSharesOfThisNft;
        totalSharesOfAllNft = _totalSharesOfAllNft;
        amount = IERC20(_auctionCurrency).balanceOf(address(this)) + _totalPaid; // total tokens received
    }

    /// @return auctionId auction ID
    /// @return reservePrice The minimum price of the first bid
    /// @return beginTime The begin time of auction
    /// @return duration The duration of auction
    /// @return owner The owner of auction
    /// @return auctionCurrency The currency of auction
    /// @return state 0: nft in this contract; 1: nft is market; 2: other
    /// @return approved Whether or not the auction curator has approved the auction to start
    function getArtAuctionInfo()
        external
        view
        returns (
            uint256 auctionId,
            uint256 reservePrice,
            uint256 beginTime,
            uint256 duration,
            address owner,
            address auctionCurrency,
            uint8 state,
            bool approved
        )
    {
        auctionId = _auctionId;
        reservePrice = _reservePrice;
        beginTime = _beginTime;
        duration = _duration;
        owner = IERC721(_nftContract).ownerOf(_nftId);
        auctionCurrency = _auctionCurrency;

        if (owner == address(this)) {
            state = 0;
        } else if (owner == _market) {
            state = 1;
        } else {
            state = 2;
        }

        approved = _approved;
    }

    /// @return _approved
    function getArtAuctionApproval() external view returns (bool) {
        return _approved;
    }

    function setArtAuctionApproval(bool approved) external onlyOwner auctionInProcess {
        require(_auctionId != MAX_ID, "SAA");
        IZoraAuctionHouse(_market).setAuctionApproval(_auctionId, approved);
        _approved = approved;
        emit SetArtAuctionApproval(address(this), _nftId, _auctionId, approved);
    }

    /// @return _reservePrice
    function getArtAuctionReservePrice() external view returns (uint256) {
        return _reservePrice;
    }

    /// @notice set auction reserve price, emits SetArtAuctionApproval event.
    /// @dev Only callable by owner CanvasManager.
    function setArtAuctionReservePrice(uint256 reservePrice) external onlyOwner auctionInProcess {
        require(_auctionId != MAX_ID && reservePrice > 0, "SARP");
        IZoraAuctionHouse(_market).setAuctionReservePrice(_auctionId, reservePrice);
        _reservePrice = reservePrice;
        emit SetArtAuctionReservePrice(address(this), _auctionId, _nftId, reservePrice);
    }

    /**
     * @notice Cancel auction, emits CancelArtAuction or EndArtAuction event.
     * @dev IAuctionHouse will transfers the NFT back to this contract, only callable by owner CanvasManager.
     */
    function cancelArtAuction() external onlyOwner {
        require(_auctionId != MAX_ID, "CAN");

        address tokenOwner = IERC721(_nftContract).ownerOf(_nftId);
        if (tokenOwner == _market) {
            IZoraAuctionHouse(_market).cancelAuction(_auctionId);
            tokenOwner = IERC721(_nftContract).ownerOf(_nftId);
        }

        if (tokenOwner == address(this)) {
            // action is canceled
            _auctionId = MAX_ID;
            _beginTime = 0;
            _approved = false;
            _reservePrice = 0;
            emit CancelArtAuction(address(this), _auctionId, _nftId);
        } else if (tokenOwner == _market) {
            // fail to cancel
            return;
        } else {
            // action is end
            emit EndArtAuction(address(this), _auctionId, _nftId);
        }
    }

    /**
     * @notice Anyone can call this function to end auction, emits CancelArtAuction or EndArtAuction event.
     * @dev If the auction is fail or canceled then the NFT is transferred back to this contract,
     * only callable by owner CanvasManager.
     */
    function endArtAuction() external onlyOwner {
        address tokenOwner = IERC721(_nftContract).ownerOf(_nftId);
        if (tokenOwner == _market) {
            IZoraAuctionHouse(_market).endAuction(_auctionId);
            tokenOwner = IERC721(_nftContract).ownerOf(_nftId);
        }

        if (tokenOwner == address(this)) {
            // action is canceled
            _beginTime = 0;
            _auctionId = MAX_ID;
            _approved = false;
            _reservePrice = 0;
            emit CancelArtAuction(address(this), _auctionId, _nftId);
        } else if (tokenOwner == _market) {
            // fail to end
            return;
        } else {
            // action is end
            emit EndArtAuction(address(this), _auctionId, _nftId);
        }
    }

    /**
     * @notice Claim contributor fee after end, and emit ClaimeArtFee event.
     * @dev only callable by owner CanvasManager, and can be called for multi times.
     * @param contributor the address of receiver
     * @param contributorShareOfThisNft the contribution in this NFT
     * @param contributorShareOfAllNft the contribution in all NFT(include this NFT)
     */
    function claimeArtAuctionFee(
        address contributor,
        uint256 contributorShareOfThisNft,
        uint256 contributorShareOfAllNft
    ) external onlyOwner {
        require(contributorShareOfThisNft <= contributorShareOfAllNft, "CF1");
        require(contributorShareOfThisNft <= _totalSharesOfThisNft, "CF2");
        require(contributorShareOfAllNft <= _totalSharesOfAllNft, "CF3");
        address tokenOwner = IERC721(_nftContract).ownerOf(_nftId);
        require(tokenOwner != address(this) && tokenOwner != _market, "CF4");

        uint256 totalReceived = IERC20(_auctionCurrency).balanceOf(address(this)) + _totalPaid; // total tokens received
        uint256 curatorFee = (totalReceived * 24) / 1024; // tokens for curator
        uint256 thisArtFee = (totalReceived * 900) / 1024; // tokens for this NFT users
        uint256 allArtsFee = totalReceived - curatorFee - thisArtFee; // thkens for all NFT users
        uint256 paymentSum = (thisArtFee * contributorShareOfThisNft * _totalSharesOfAllNft + allArtsFee * contributorShareOfAllNft * _totalSharesOfThisNft) /
            (_totalSharesOfThisNft * _totalSharesOfAllNft);
        uint256 alreadyPaid = _alreadyPaids[contributor];
        require(paymentSum > alreadyPaid, "CF5");

        _alreadyPaids[contributor] = paymentSum;
        uint256 pendingPay = paymentSum - alreadyPaid;
        IERC20(_auctionCurrency).safeTransfer(contributor, pendingPay);
        _totalPaid += pendingPay;

        emit ClaimeArtAuctionFee(address(this), _msgSender(), contributor, contributorShareOfThisNft, contributorShareOfAllNft, paymentSum, pendingPay);
    }

    /**
     * @notice Claim curator fee to any account after end, and emit ClaimeCuratorFee event.
     * @dev only callable by owner CanvasManager, and can be called for multi times.
     * @param to the receiver account
     */
    function claimeCuratorFee(address to, uint256 amount) external onlyOwner {
        address tokenOwner = IERC721(_nftContract).ownerOf(_nftId);
        require(tokenOwner != address(this) && tokenOwner != _market, "CC1");

        uint256 totalReceived = IERC20(_auctionCurrency).balanceOf(address(this)) + _totalPaid;
        uint256 curatorFee = (totalReceived * 24) / 1024;
        require(curatorFee > _curatorPaid, "CC2");
        uint256 pendingPay = curatorFee - _curatorPaid;

        if (amount == 0) {
            amount = pendingPay;
        } else {
            require(amount <= pendingPay, "CC3");
        }

        _totalPaid += amount;
        _curatorPaid += amount;
        IERC20(_auctionCurrency).safeTransfer(to, amount);

        emit ClaimeCuratorFee(address(this), _msgSender(), to, _curatorPaid, pendingPay);
    }

    // ============ Public functions ============

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IArtAuction).interfaceId || interfaceId == type(IERC721Receiver).interfaceId;
    }

    // ============ Internal functions ============

    // ============ Private functions ============
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721Tradable} from "./ERC721Tradable.sol";

contract PixNft is ERC721Tradable {
    constructor(address _proxyRegistryAddress) ERC721Tradable("1kPixelArt", "1kPix", _proxyRegistryAddress) {}

    function baseTokenURI() public pure override returns (string memory) {
        return "https://www.1kpixel.io/pix-nft/metadata/";
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mint(address _to, uint256 tokenId) public onlyPix {
        _mint(_to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ERC721Tradable} from "./ERC721Tradable.sol";

contract PixMoment is ERC721Tradable {
    constructor(address _proxyRegistryAddress) ERC721Tradable("1kPixelSnapshot", "1kSS", _proxyRegistryAddress) {}

    function baseTokenURI() public pure override returns (string memory) {
        return "https://www.1kpixel.io/moment-nft/metadata/";
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintMoment(address _to) public onlyPix returns (uint256 newTokenId) {
        newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable, ERC721Burnable, AccessControl {
    using SafeMath for uint256;

    address proxyRegistryAddress;
    uint256 internal _currentTokenId = 0;

    // access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PIX_ROLE = keccak256("PIX_ROLE");

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "admin");
        _;
    }

    modifier onlyPix() {
        require(hasRole(PIX_ROLE, _msgSender()), "pixel");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public onlyAdmin {
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }

    function setProxyRegistry(address proxyAddress) public onlyOwner {
        proxyRegistryAddress = proxyAddress;
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() internal view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() internal {
        _currentTokenId++;
    }

    function baseTokenURI() public pure virtual returns (string memory);

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.

        if (operator == proxyRegistryAddress) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    // get all the tokens of the address
    function ownerTokens(address owner) public view returns (uint256[] memory result) {
        require(owner != address(0), "owner");

        result = new uint256[](balanceOf(owner));
        for (uint256 i = 0; i < balanceOf(owner); ++i) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }
    }

    // add interface for bunrable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    event setRoyaltyInfoEvent(address _to, uint256 rate);

    address mRoyaltyAddr;
    uint256 mRoyaltyRate; // 0.00 precise

    function setRoyaltyInfo(address _to, uint256 rate) public onlyAdmin {
        mRoyaltyAddr = _to;
        mRoyaltyRate = rate;
        emit setRoyaltyInfoEvent(_to, rate);
    }

    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(
        uint256, /* tokenId */
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        royaltyAmount = (salePrice * mRoyaltyRate) / 10000;
        receiver = mRoyaltyAddr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ICanvas} from "./interfaces/ICanvas.sol";
import {IArtAuction} from "./interfaces/IArtAuction.sol";
import {PixNft} from "./PixNft.sol";
import {PixMoment} from "./PixMoment.sol";
import {ZoraAuction} from "./ZoraAuction.sol";

contract CanvasManager is AccessControl, Ownable, Pausable, ICanvas, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    // ============ Constants ============

    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 internal constant MaxArt = 1024; // max count of art
    uint256 internal constant PixCount = 1024; // count of pixels

    // ============ Structs ============

    struct Art {
        uint256 startTime;
        uint256 endTime;
        uint256 consumToken; // total consumed tokens
        uint32 momentIndex; // index no of last moment in this art: momentIndex + 1 = size of moments array
        uint8 state; // 1=open, 2=end
        uint256[PixCount] price; // current consumed tokens of each pixel
        uint256[] moments; // id array of mements in this art
        uint24[PixCount] colors; // color array of last mement in this art
    }

    struct Moment {
        uint256 artId; // id of art
        uint256 momentIndex; // index no of this moment in art
        uint24[PixCount] colors; // color array of this moment
    }

    // ============ Variables ============

    address internal _zoraMarket; // address of zora auction house
    address internal _defaultAuctionCurrency; // default auction currency, must be ERC20
    uint256 internal _defaultAuctionDuration; // default auction duration
    uint256 internal _defaultAuctionPrice; // default auction price

    mapping(uint256 => Art) public mArts;
    mapping(uint256 => Moment) public mMoments;
    mapping(uint256 => IArtAuction) public _artAuctions;
    uint256[] public _endArtIds;

    PixNft internal mPixNft; // pixel nft contract
    PixMoment internal mPixMoment; // moment nft contract

    uint256 internal mNftId = 0; // current count of arts
    IERC20[] internal mTokens; // token array
    uint256[] internal _basePrices; // the first price of draw pixel

    // ============ Events ============

    // ============ Constructor function ============

    constructor(
        address nft,
        address moment,
        address zoraMarket
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        mPixNft = PixNft(nft);
        mPixMoment = PixMoment(moment);
        _zoraMarket = zoraMarket;
    }

    // ============ Receive function ============

    // ============ Fallback function ============

    // ============ Modifier functions ============

    // ============ External functions ============

    function pause() external {
        onlyAdmin();
        _pause();
    }

    function unpause() external {
        onlyAdmin();
        _unpause();
    }

    function getZoraMarketAddress() external view returns (address) {
        return _zoraMarket;
    }

    function setZoraMarketAddress(address zoraMarket) external {
        _zoraMarket = zoraMarket;
    }

    function getMoment(uint256 uMomentId)
        external
        view
        override
        returns (
            uint24[1024] memory colors,
            uint256 momentIndex,
            uint256 artId
        )
    {
        Moment storage moment = mMoments[uMomentId];
        colors = moment.colors;
        momentIndex = moment.momentIndex;
        artId = moment.artId;
    }

    function getMomentColors(uint256 uMomentId) external view override returns (uint24[1024] memory) {
        Moment storage moment = mMoments[uMomentId];
        return moment.colors;
    }

    /// @return default duration, currency, price of auction
    function getDefaultAuctionInfo()
        external
        view
        returns (
            uint256,
            address,
            uint256
        )
    {
        return (_defaultAuctionDuration, _defaultAuctionCurrency, _defaultAuctionPrice);
    }

    /// @notice set default duration, currency, price used when create auction
    function setDefaultAuctionInfo(
        uint256 duration,
        address currency,
        uint256 price
    ) external {
        onlyAdmin();
        _defaultAuctionDuration = duration;
        _defaultAuctionCurrency = currency;
        _defaultAuctionPrice = price;
    }

    /// @return address of auction contract which tokenId is nftId
    function getArtAuctionAddress(uint256 nftId) external view returns (address) {
        return address(_getArtAuction(nftId));
    }

    function withdrawAdminFee(
        uint256 tokenIndex,
        address to,
        uint256 amount
    ) external nonReentrant {
        onlyAdmin();
        require(tokenIndex < mTokens.length, "TI");
        IERC20 token = mTokens[tokenIndex];
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "BA");

        if (to == address(0)) {
            to = _msgSender();
        }

        if (amount == 0) {
            amount = balance;
        } else {
            require(amount <= balance, "AM");
        }

        token.safeTransfer(to, amount);
    }

    function withdrawCuratorFee(
        uint256 nftId,
        address to,
        uint256 amount
    ) external nonReentrant {
        onlyAdmin();
        checkNftId(nftId);

        if (to == address(0)) {
            to = _msgSender();
        }

        IArtAuction artAuction = _getArtAuction(nftId);
        return artAuction.claimeCuratorFee(to, amount);
    }

    function setAuctionCurrency(uint256 nftId, address auctionCurrency) external {
        onlyAdmin();
        checkNftId(nftId);
        IArtAuction artAuction = _getArtAuction(nftId);
        artAuction.setAuctionCurrency(auctionCurrency);
    }

    function createArtAuctionAndApproval(
        uint256 nftId,
        uint256 duration,
        uint256 reservePrice
    ) external returns (uint256) {
        onlyAdmin();
        checkNftId(nftId);
        IArtAuction artAuction = _getArtAuction(nftId);
        return artAuction.createArtAuction(duration, reservePrice);
    }

    /// @return auctionId auction ID
    /// @return reservePrice The minimum price of the first bid
    /// @return beginTime The begin time of auction
    /// @return duration The duration of auction
    /// @return owner The owner of auction
    /// @return auctionCurrency The currency of auction
    /// @return state 0: nft in this contract; 1: nft is market; 2: other
    /// @return approved Whether or not the auction curator has approved the auction to start
    function getArtAuctionInfo(uint256 nftId)
        external
        view
        returns (
            uint256 auctionId,
            uint256 reservePrice,
            uint256 beginTime,
            uint256 duration,
            address owner,
            address auctionCurrency,
            uint8 state,
            bool approved
        )
    {
        checkNftId(nftId);
        IArtAuction artAuction = _getArtAuction(nftId);
        return artAuction.getArtAuctionInfo();
    }

    /// @notice this function calculates contribution for a single contributor
    /// @param nftId token id of pixel nft
    /// @param contributor any contributor
    /// @return contributorShareOfThisNft The shares of contributor in this PixNft
    /// @return contributorShareOfAllNft The total shares of contributor from first PixNft to this PixNft(include this PixNft)
    /// @return totalSharesOfThisNft The total shares of this PixNft
    /// @return totalSharesOfAllNft The total shares from first PixNft to this PixNft(include this PixNft)
    /// @return amount The all received tokens of art auction contract
    function getNftPorfitInfo(uint256 nftId, address contributor)
        external
        view
        returns (
            uint256 contributorShareOfThisNft,
            uint256 contributorShareOfAllNft,
            uint256 totalSharesOfThisNft,
            uint256 totalSharesOfAllNft,
            uint256 amount
        )
    {
        checkNftId(nftId);
        IArtAuction artAuction = _getArtAuction(nftId);
        (contributorShareOfThisNft, contributorShareOfAllNft) = _calcShares(nftId, contributor);
        (totalSharesOfThisNft, totalSharesOfAllNft, amount) = artAuction.getProfitInfo();
    }

    function setArtAuctionApproval(uint256 nftId, bool approved) external {
        onlyAdmin();
        checkNftId(nftId);
        IArtAuction artAuction = _getArtAuction(nftId);
        artAuction.setArtAuctionApproval(approved);
    }

    function setArtAuctionReservePrice(uint256 nftId, uint256 reservePrice) external {
        onlyAdmin();
        checkNftId(nftId);
        IArtAuction artAuction = _getArtAuction(nftId);
        artAuction.setArtAuctionReservePrice(reservePrice);
    }

    function cancelArtAuction(uint256 nftId) external {
        onlyAdmin();
        checkNftId(nftId);
        IArtAuction artAuction = _getArtAuction(nftId);
        artAuction.cancelArtAuction();
    }

    function endArtAuction(uint256 nftId) external {
        onlyAdmin();
        checkNftId(nftId);
        IArtAuction artAuction = _getArtAuction(nftId);
        artAuction.endArtAuction();
    }

    /**
     * @notice Claim ERC20 tokens to a single contributor after the auction has ended,
     * @dev Anyone can call this function to claim for any contributor, and can be called for multi times
     * @param nftId id of PixNFT
     * @param contributor the address of receiver
     */
    function claimeArtAuctionFee(uint256 nftId, address contributor) external nonReentrant {
        checkNftId(nftId);

        if (contributor == address(0)) {
            contributor = _msgSender();
        }

        (uint256 contributorShareOfThisNft, uint256 contributorShareOfAllNft) = _calcShares(nftId, contributor);
        IArtAuction artAuction = _getArtAuction(nftId);
        artAuction.claimeArtAuctionFee(contributor, contributorShareOfThisNft, contributorShareOfAllNft);
    }

    function getConsumeToken(uint256 index) external view returns (address token, uint256 basePrice) {
        require(index < mTokens.length, "GCT");
        token = address(mTokens[index]);
        basePrice = _basePrices[index];
    }

    function setOrAddConsumeToken(
        uint256 index,
        IERC20 token,
        uint256 basePrice
    ) external {
        onlyAdmin();
        require(basePrice > 0, "SCT");

        if (index < mTokens.length) {
            mTokens[index] = token;
            _basePrices[index] = basePrice;
        } else {
            mTokens.push(token);
            _basePrices.push(basePrice);
        }
    }

    function startNewArt(uint256 endTime) external returns (uint256 nftId) {
        onlyAdmin();
        require(mNftId < MaxArt && block.timestamp < endTime, "SNA");

        mNftId++;
        nftId = mNftId;
        Art storage art = mArts[nftId];
        art.state = 1; // open
        art.startTime = block.timestamp;
        art.endTime = endTime;

        emit NewArt(_msgSender(), nftId, art.startTime, art.endTime);
    }

    function setEndTime(uint256 nftId, uint256 endTime) external {
        onlyAdmin();
        checkNftId(nftId);
        Art storage art = mArts[nftId];
        require(art.state == 1 && art.startTime < endTime, "SET");
        art.endTime = endTime;

        emit SetEndTime(_msgSender(), nftId, art.endTime);

        if (endTime <= block.timestamp) {
            _endArt(nftId);
        }
    }

    // every one can call end, if reach the end time
    function endArt(uint256 nftId) external {
        checkNftId(nftId);
        Art storage art = mArts[nftId];
        require(art.state == 1 && block.timestamp >= art.endTime, "EA");
        _endArt(nftId);
    }

    function getArt(uint256 nftId)
        external
        view
        returns (
            uint256 consumToken,
            uint32 momentIndex,
            uint24[PixCount] memory colors,
            uint256[PixCount] memory price,
            uint8 state,
            uint256[] memory moments,
            uint256 startTime,
            uint256 endTime
        )
    {
        Art storage art = mArts[nftId];
        consumToken = art.consumToken;
        momentIndex = art.momentIndex;
        colors = art.colors;
        price = art.price;
        moments = art.moments;
        state = art.state;
        startTime = art.startTime;
        endTime = art.endTime;
    }

    function getOpenArts() external view returns (uint256[] memory nftIds) {
        uint256 index = mNftId - _endArtIds.length;
        nftIds = new uint256[](index);

        index = 0;
        for (uint256 i = 1; i <= mNftId; ++i) {
            if (mArts[i].state == 1) {
                nftIds[index] = i;
                index++;
            }
        }
    }

    function getEndArts() external view returns (uint256[] memory) {
        return _endArtIds;
    }

    function getAllArts() external view returns (uint256[] memory nftIds) {
        uint256 index = 0;
        for (uint256 i = 1; i <= mNftId; ++i) {
            if (mArts[i].state > 0) {
                index++;
            }
        }
        nftIds = new uint256[](index);

        index = 0;
        for (uint256 i = 1; i <= mNftId; ++i) {
            if (mArts[i].state > 0) {
                nftIds[index] = i;
                index++;
            }
        }
    }

    function getDrawPrice(
        uint256 nftId,
        uint256 pixelIndex,
        uint256 tokenIndex
    ) external view returns (uint256) {
        checkNftId(nftId);
        require(pixelIndex < PixCount && tokenIndex < _basePrices.length, "GPP");
        Art storage art = mArts[nftId];
        return _getNewPrice(_basePrices[tokenIndex], art.price[pixelIndex]);
    }

    function drawPixel(
        uint256 tokenIndex,
        uint256 nftId,
        uint256 index,
        uint24 color,
        uint256 bidPrice
    ) external {
        checkNftId(nftId);
        require(index < PixCount && tokenIndex < mTokens.length, "DP1");

        Art storage art = mArts[nftId];
        require(art.state == 1 && block.timestamp <= art.endTime, "DP2");

        IERC20 token = mTokens[tokenIndex];
        uint256 price = _getNewPrice(_basePrices[tokenIndex], art.price[index]);
        require(token.balanceOf(_msgSender()) >= price && bidPrice >= price, "DP3");

        token.transferFrom(_msgSender(), address(this), price);
        art.consumToken += price;
        art.price[index] = price;
        art.colors[index] = color;

        // for moment
        uint256 uMomentId = mPixMoment.mintMoment(_msgSender());
        art.momentIndex = uint32(art.moments.length);
        art.moments.push(uMomentId);

        Moment storage moment = mMoments[uMomentId];
        moment.colors = art.colors;
        moment.momentIndex = art.momentIndex;
        moment.artId = nftId;

        emit DrawPixel(_msgSender(), nftId, uMomentId, index, color, bidPrice);
    }

    // ============ Public functions ============

    // ============ Internal functions ============

    /// @notice this function calculates contribution for a single contributor
    /// @param nftId token id of pixel nft
    /// @param contributor any contributor
    /// @return contributorShareOfThisNft shares of contributor in this PixNft
    /// @return contributorShareOfAllNft all shares of contributor from first PixNft to this PixNft(include this PixNft)
    function _calcShares(uint256 nftId, address contributor) internal view returns (uint256 contributorShareOfThisNft, uint256 contributorShareOfAllNft) {
        Art storage art = mArts[nftId];

        uint256 count = art.moments.length;
        for (uint256 i = 0; i < count; ++i) {
            uint256 tokenIdOfMoment = art.moments[i];
            if (contributor == mPixMoment.ownerOf(tokenIdOfMoment)) {
                ++contributorShareOfThisNft;
            }
        }

        uint256 maxMomentId = art.moments[art.momentIndex];
        count = mPixMoment.balanceOf(contributor);
        for (uint256 i = 0; i < count; ++i) {
            if (mPixMoment.tokenOfOwnerByIndex(contributor, i) <= maxMomentId) {
                ++contributorShareOfAllNft;
            }
        }
    }

    function _endArt(uint256 nftId) internal {
        Art storage art = mArts[nftId];
        art.state = 2; // end

        if (art.moments.length > 0) {
            _endArtIds.push(nftId);
            IArtAuction artAuction = new ZoraAuction(
                art.moments[art.momentIndex], // allNftShares
                art.moments.length, // thisNftShares
                nftId, // nftTokenId
                address(mPixNft), // nftContract
                _zoraMarket, // market
                _defaultAuctionCurrency // auctionCurrency
            );
            _artAuctions[nftId] = artAuction;
            mPixNft.mint(address(artAuction), nftId);
            artAuction.createArtAuction(_defaultAuctionDuration, _defaultAuctionPrice);
        }

        emit EndArt(_msgSender(), nftId);
    }

    function _getNewPrice(uint256 basePrice, uint256 oldPrice) internal pure returns (uint256) {
        return (oldPrice == 0) ? basePrice : (oldPrice + oldPrice);
    }

    function _getArtAuction(uint256 nftId) internal view returns (IArtAuction) {
        require(address(_artAuctions[nftId]) != address(0), "AA");
        return _artAuctions[nftId];
    }

    function onlyAdmin() internal view {
        require(hasRole(ADMIN_ROLE, _msgSender()), "OA");
    }

    function checkNftId(uint256 nftId) internal view {
        require(nftId <= mNftId && nftId > 0, "ND");
    }

    // ============ Private functions ============
}