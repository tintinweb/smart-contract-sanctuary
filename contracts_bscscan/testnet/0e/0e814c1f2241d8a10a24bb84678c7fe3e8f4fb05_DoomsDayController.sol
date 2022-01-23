/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: DoomsDayNFT.sol



pragma solidity ^0.8.0;




contract DoomsDayNFT is ERC721URIStorage, Ownable {

	uint256 public counter;

    uint256 private randNum = 0;

    mapping(uint256 => uint256) public NFTTypes;

    mapping(uint256 => uint256) public NFTsToHeros;

	constructor() ERC721("DoomsDayNFT", "DDN"){
		counter = 0;
	}

    address private controllerAddress;

    function setController(address controllerAddr) public onlyOwner {
        controllerAddress = controllerAddr;
    }

    modifier onlyController {
         require(controllerAddress == msg.sender);
         _;
    }

    function createNFT(address user, uint256 NFTType, uint256 heroId) public onlyController returns (uint256){
        counter ++;

        uint256 tokenId = _rand();

        NFTTypes[tokenId] = NFTType;
		
        _safeMint(user, tokenId);

        NFTsToHeros[tokenId] = heroId;
		
        return tokenId;
	} 

	function burn(uint256 tokenId) public virtual {
		require(_isApprovedOrOwner(msg.sender, tokenId),"ERC721: you are not the owner nor approved!");	
		super._burn(tokenId);
	}

    // function burn(address user, uint256 tokenId) public virtual {
	// 	require(_isApprovedOrOwner(user, tokenId),"ERC721: you are not the owner nor approved!");	
	// 	super._burn(tokenId);
	// }

    function approveToController(address ownerAddr, uint256 tokenId) public onlyController {
        address owner = ERC721.ownerOf(tokenId);

        require(ownerAddr == owner, "ERC721: this user does not own this tokenId");

        _approve(controllerAddress, tokenId);
    }

    function _rand() internal virtual returns(uint256) {
        
        uint256 number1 =  uint256(keccak256(abi.encodePacked(block.timestamp, randNum++, msg.sender))) % (4 * 10 ** 15) + 196874639854288;

        uint256 number2 =  uint256(keccak256(abi.encodePacked(block.timestamp, randNum++, msg.sender))) % (2 * 10 ** 15) + 197658768746346;
        
        return number1 + number2 + counter * 10 ** 16;
    }

}
// File: DOOToken.sol



pragma solidity ^0.8.0;



contract DOOToken is ERC20, Ownable {

    constructor() ERC20("DOOToken", "DOO") {

        _mint(address(this),11000000 * 10 ** 18);

        _mint(msg.sender,10000000 * 10 ** 18);
        
    }

    address private controllerAddress;

    function setController(address controllerAddr) public onlyOwner {
        controllerAddress = controllerAddr;
    }

    modifier onlyController {
         require(controllerAddress == msg.sender);
         _;
    }

    function approveToController(address owner, uint256 amount) public onlyController {

        // require(msg.sender == controllerAddress, "Caller must be controller");

        _approve(owner, controllerAddress, amount);
    }

    function ownerWithdrew(uint256 amount) public onlyOwner{
        
        amount = amount * 10 **18;
        
        uint256 dexBalance = balanceOf(address(this));
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Not enough tokens in the reserve");
        
        _transfer(address(this), msg.sender, amount);
    }
    
    function ownerDeposit( uint256 amount ) public onlyOwner {
        
        amount = amount * 10 **18;

        uint256 dexBalance = balanceOf(msg.sender);
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Dont hava enough EMSC");
        
        // transferFrom(msg.sender, address(this), amount);

        _transfer(msg.sender, address(this), amount);
    }
  
}
// File: DOMToken.sol



pragma solidity ^0.8.0;



contract DOMToken is ERC20, Ownable {

    constructor() ERC20("DOMToken", "DOM") {

        _mint(address(this),60000000 * 10 ** 18);

        _mint(msg.sender,40000000 * 10 ** 18);
        
    }

    address private controllerAddress;

    function setController(address controllerAddr) public onlyOwner {
        controllerAddress = controllerAddr;
    }

    modifier onlyController {
         require(controllerAddress == msg.sender);
         _;
    }

    function approveToController(address owner, uint256 amount) public onlyController {

        // require(msg.sender == controllerAddress, "Caller must be controller");

        _approve(owner, controllerAddress, amount);
    }


    function additionalIssuance(uint256 amount) public onlyOwner{       
        _mint(msg.sender,amount * 10 ** 18);
    }

    function ownerWithdrew(uint256 amount) public onlyOwner{
        
        amount = amount * 10 **18;
        
        uint256 dexBalance = balanceOf(address(this));
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Not enough tokens in the reserve");
        
        _transfer(address(this), msg.sender, amount);
    }
    
    function ownerDeposit( uint256 amount ) public onlyOwner {
        
        amount = amount * 10 **18;

        uint256 dexBalance = balanceOf(msg.sender);
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Dont hava enough EMSC");
        
        // transferFrom(msg.sender, address(this), amount);

        _transfer(msg.sender, address(this), amount);
    }
  
}
// File: DoomsDayController.sol



pragma solidity ^0.8.0;






contract DoomsDayController is Ownable {

    using SafeMath for uint256;

    event GetHero(address indexed user, uint256 totalHeros, uint256 types, uint256 rarity);

    event UpHero(address indexed user, uint256 heroId, uint256 level, bool success);

    event HeroCardTransfer(address indexed sender, address indexed recipient, uint256 heroId);

    event SellHeroCard(address indexed seller, uint256 heroId, uint256 tokenType, uint256 price);

    event BuyHeroCards(address indexed seller, address indexed buyer, uint256 heroId);

    event ExecuteTask(address indexed user, uint256 heroId, uint256 taskTypes, uint256 startBlock);

    event TaskRewardWithdrew(address indexed user, uint256 heroId, uint256 reward, uint256 startBlock);

    event FightMonster(uint256 heroId, uint256 monsterNum, uint256 successTimes, uint256 DOOProfit, uint256 DOMProfit);

    event Fight(uint256 monsterType, uint256 adjust, uint256 heroLife, uint256 monsterlife, uint256[] blood);
    
    event PaymentReceived(address from, uint256 amount);

    DOOToken private DOO;

    DOMToken private DOM;

    DoomsDayNFT private DDN;

    uint256 private randNum = 0;
    
    struct User{
        
        uint256 heroNumber;

        uint256 openCardTimes;

        uint256 recommendUserNumber;

        uint256 recommendCards;

        uint256 pledgeCards;

        uint256 dayDividends;

        uint256 totalDividends;

        uint256 surplusDividends;

        uint256 battleTimes;

        uint256 DOOProfitOfBattle;

        uint256 DOMProfitOfBattle;

        address upper;
    }
    
    struct Hero{

        //力量
        uint256 power;

        //速度
        uint256 speed;

        //体力
        uint256 physicalPower;

        //智慧
        uint256 wisdom;

        //信念
        uint256 belief;

        //科学
        uint256 science;
        
        uint256 id;

        uint256 tokenId;

        uint256 types;

        uint256 rarity;

        uint256 level;
            
        //已用对战次数
        uint256 usedTimes;

        uint256 lastUsedTime;

        address onwerAddr;
    }

    struct HeroPublicAttribute{

        //暴击率
        uint256 crit;

        //闪避率
        uint256 miss;

        //等级对应可用对战次数
        uint256 totalTimes;

        //升级花费DOO数量
        uint256 DOMCost;

        //升级花费DOM数量
        uint256 DOOCost;

        //升级失败概率
        uint256 failRate;

        //收益倍率
        uint256 profitMagnification;
    }

    function setCrit(uint256 levels, uint256 num) public onlyOwner {heroPublicAttributes[levels].crit = num;}
    function setMiss(uint256 levels, uint256 num) public onlyOwner {heroPublicAttributes[levels].miss = num;}
    function setTotalTimes(uint256 levels, uint256 num) public onlyOwner {heroPublicAttributes[levels].totalTimes = num;}
    function setDOMCost(uint256 levels, uint256 num) public onlyOwner {heroPublicAttributes[levels].DOMCost = num;}
    function setDOOCost(uint256 levels, uint256 num) public onlyOwner {heroPublicAttributes[levels].DOOCost = num;}
    function setFailRate(uint256 levels, uint256 num) public onlyOwner {heroPublicAttributes[levels].failRate = num;}
    function setProfitMagnification(uint256 levels, uint256 num) public onlyOwner {heroPublicAttributes[levels].profitMagnification = num;}

    struct HeroAttr{

        uint256 mainLow;
		
		uint256 mainUp;

        uint256 secondaryLow;
		
		uint256 secondaryUp;
    }

    struct Area {

        uint256 ticket; 
        
        uint256[4] probability;

        uint256[5] corpse;
    }

    struct FightReward {

        uint256 dooMin;

        uint256 dooMax;

        uint256 domMin;

        uint256 domMax;
    }

    struct BattleHistory {

        uint256 heroId;

        uint256 areaId;

        uint256 monsterNumber;

        uint256 DOOProfit;

        uint256 DOMProfit;

        bool result;
    }

    struct Sell {

        uint256 heroId;

        uint256 price;

        uint256 tokenType;

        bool sold;
    }

    struct Task {

        uint256 heroId;

        uint256 taskTypes;

        uint256 startBlock;
    }

    uint256 public totalHeros;

    uint256 public totalPledgeCards;

    uint256 public totalPledgeUsers;

    uint256 public totalPledgeDOO = 20000;

    uint256 public onceDividendsDOO = 350;

    uint256 public accumulativeDividendsDOO = 0;

    uint256 public tradeFee = 5;

    uint256 private DOOOfOpenCard = 1;

    uint256 public miningRatio = 10000;
    
    uint256 public basePrice = 30;

    uint256 public totalSell;

    mapping(address => User) public users;

    mapping(uint256 => Hero) public heros;

    mapping(uint256 => address) public pledgeUsers;
 
    mapping(uint256 => HeroAttr) public herroAttrs;
    
    mapping(uint256 => HeroPublicAttribute) public heroPublicAttributes;

    mapping(uint256 => Area) public areas;

    mapping(uint256 => mapping(uint256 => FightReward)) public fightRewards;

    mapping(address => mapping(uint256 => uint256)) public userHeros;

    mapping(address => mapping(uint256 => address)) public recommendUsers;

    mapping(uint256 => Task) public tasks;//heroIdToTasks

    mapping(uint256 => Sell) public sells;//heroIdToSells

    mapping(address => mapping(uint256 => BattleHistory)) public battleHistorys;

    mapping(uint256 => uint256) public sellsToHeroIds;//SellsToheroId

    // mapping(uint256 => uint256) public herosToNFTs;//SellsToheroId

    //1代表开卡, 2代表商城购买, 3代表预售NFT获取
    mapping(uint256 => uint256) public heroSource;

    uint256[3] public rarityRate;

    address pairAddr;

    address WBNBAddr;

    constructor() {

        DOO = DOOToken(0x7A1B732e7280B1e41a0e286cd9EB7fF378f2563B);

        DOM = DOMToken(0x7df7EAa95d04C75f805B3a479Ba4bd411BE124f9);

        DDN = DoomsDayNFT(0x0e0122EC3eA055df36Bf9B17DBd0E8d1Bd9Ad3f4);

        herroAttrs[5] = HeroAttr(35, 85, 35, 60);
        herroAttrs[6] = HeroAttr(86, 90, 61, 80);
        herroAttrs[7] = HeroAttr(91, 95, 81, 85);
        herroAttrs[8] = HeroAttr(96, 100, 86, 100);

        heroPublicAttributes[1] = HeroPublicAttribute(10,10,3,20000,0,0,1);
        heroPublicAttributes[2] = HeroPublicAttribute(11,11,3,50000,0,0,2);
        heroPublicAttributes[3] = HeroPublicAttribute(12,12,3,150000,0,0,4);
        heroPublicAttributes[4] = HeroPublicAttribute(13,13,3,450000,5,0,8);
        heroPublicAttributes[5] = HeroPublicAttribute(14,14,5,1000000,50,25,16);
        heroPublicAttributes[6] = HeroPublicAttribute(15,15,6,2000000,1000,25,25);
        heroPublicAttributes[7] = HeroPublicAttribute(16,16,7,5000000,500,25,50);
        heroPublicAttributes[8] = HeroPublicAttribute(17,17,8,10000000,1000,30,75);
        heroPublicAttributes[9] = HeroPublicAttribute(18,18,9,20000000,1000,30,100);
        heroPublicAttributes[10] = HeroPublicAttribute(19,19,10,50000000,2000,50,200);
        heroPublicAttributes[11] = HeroPublicAttribute(20,20,11,100000000,5000,50,300);
        heroPublicAttributes[12] = HeroPublicAttribute(21,21,12,0,0,0,500);

        areas[1].probability = [40, 70, 90, 100];
        areas[1].corpse = [25, 50, 70, 85, 100];
        areas[1].ticket = 2890;

        areas[2].probability = [35, 65, 85, 100];
        areas[2].corpse =  [20, 40, 65, 85, 100];
        areas[2].ticket = 6570;

        areas[3].probability =  [30, 70, 85, 100];
        areas[3].corpse =  [10, 30, 55, 80, 100];
        areas[3].ticket = 12980;

        fightRewards[1][1] = FightReward(0, 0, 396, 865);
        fightRewards[1][2] = FightReward(0, 0, 695, 1365);
        fightRewards[1][3] = FightReward(150, 550, 783, 1850);
        fightRewards[1][4] = FightReward(550, 850, 1310, 2650);
        fightRewards[1][5] = FightReward(850, 2850, 1790, 3900);

        fightRewards[2][1] = FightReward(0, 0, 996, 1755);
        fightRewards[2][2] = FightReward(0, 0, 1350, 2565);
        fightRewards[2][3] = FightReward(250, 850, 1861, 4265);
        fightRewards[2][4] = FightReward(850, 1850, 2234, 5955);
        fightRewards[2][5] = FightReward(1150, 3950, 3370, 7550);

        fightRewards[3][1] = FightReward(0, 0, 1447, 2890);
        fightRewards[3][2] = FightReward(0, 0, 1867, 4950);
        fightRewards[3][3] = FightReward(385, 1150, 2654, 6855);
        fightRewards[3][4] = FightReward(1150, 2350, 3913, 9630);
        fightRewards[3][5] = FightReward(1750, 5750, 5112, 12059);

        rarityRate = [83,93,98];        
    }

    function setTicket(uint256 levels, uint256 num) public onlyOwner {areas[levels].ticket = num;}
    function setProbability(uint256 levels, uint256 num1,uint256 num2,uint256 num3,uint256 num4) public onlyOwner {areas[levels].probability = [num1, num2, num3, num4];}
    function setCorpse(uint256 levels, uint256 num1,uint256 num2,uint256 num3,uint256 num4) public onlyOwner {areas[levels].corpse = [num1, num2, num3, num4];}
    function setFightRewards(uint256 levels,uint256 monsterId, uint256 num1,uint256 num2,uint256 num3,uint256 num4) public onlyOwner {fightRewards[levels][monsterId] = FightReward(num1, num2, num3, num4);}
    function setRarityRate(uint256 num1,uint256 num2,uint256 num3) public onlyOwner {rarityRate = [num1,num2,num3];}

    uint256[5] adjustLow = [80,80,80,80,80];

    uint256[5] adjustUp = [120,120,120,120,120];

    function setAdjustLow(uint256 index,uint256 num) public onlyOwner {adjustLow[index - 1] = num;}
    function setAdjustUp(uint256 index,uint256 num) public onlyOwner {adjustUp[index - 1] = num;}

    uint256[] bloods;

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
    
    function ownerWithdrew(uint256 token, uint256 amount) public onlyOwner{

        amount = amount * 10 **18;

        if(token == 1){
            uint256 dexBalance = DOO.balanceOf(address(this));
        
            require(amount > 0, "You need to send some ether");
            
            require(amount <= dexBalance, "Not enough tokens in the reserve");
            
            DOO.transfer(msg.sender, amount);
        }

        if(token == 2){
            uint256 dexBalance = DOM.balanceOf(address(this));
        
            require(amount > 0, "You need to send some ether");
            
            require(amount <= dexBalance, "Not enough tokens in the reserve");
            
            DOM.transfer(msg.sender, amount);
        }             
    }
    
    function ownerDeposit(uint256 token, uint256 amount ) public onlyOwner {
        
        amount = amount * 10 **18;

        if(token == 1){

            uint256 dexBalance = DOO.balanceOf(msg.sender);
        
            require(amount > 0, "You need to send some ether");
            
            require(amount <= dexBalance, "Dont hava enough EMSC");

            DOO.approveToController(msg.sender, amount);
            
            DOO.transferFrom(msg.sender, address(this), amount);
        }

        if(token == 2){
            
            uint256 dexBalance = DOM.balanceOf(address(this));
        
            require(amount > 0, "You need to send some ether");
            
            require(amount <= dexBalance, "Not enough tokens in the reserve");

            DOM.approveToController(msg.sender, amount);
            
            DOM.transferFrom(msg.sender, address(this), amount);
        }
    }

    function bindRecommender(address upperAddr) public {

        require(upperAddr != address(0) && upperAddr != msg.sender, "Please enter the correct address");

        address upper = users[msg.sender].upper;

        require(upper == address(0), "This user has bound a upper");
        
        users[msg.sender].upper = upperAddr;

        users[upperAddr].recommendUserNumber ++;

        recommendUsers[upperAddr][users[upperAddr].recommendUserNumber] = msg.sender;
    }

    //获取英雄卡
    function getHeroCard() public{

        DOO.approveToController(msg.sender, DOOOfOpenCard * 10 ** 18);
    
        DOO.transferFrom(msg.sender, address(this), DOOOfOpenCard * 10 ** 18);

        totalHeros ++;

        uint256 types = _getRandomNum(1, 4);

        uint256 rarity = _getRarity();

        uint256 tokenId = DDN.createNFT(msg.sender, types, totalHeros);

        users[msg.sender].heroNumber ++;

        if (users[msg.sender].upper != address(0)) {

            users[msg.sender].openCardTimes ++;

            if (users[msg.sender].openCardTimes == 10) {
                users[users[msg.sender].upper].recommendCards ++;
            }          
        }

        (uint256 num1,uint256 num2,uint256 num3,uint256 num4,uint256 num5,uint256 num6) = _getHeroAttr(types, rarity); 

        heros[totalHeros] = Hero(num1, num2, num3, num4, num5, num6, totalHeros, tokenId, types, rarity, 1, 0, 0, msg.sender);

        userHeros[msg.sender][users[msg.sender].heroNumber] = totalHeros;

        heroSource[totalHeros] = 1;

        emit GetHero(msg.sender, totalHeros, types, rarity);
    }

    function heroBattleAttributes(uint256 heroId) public view returns(uint256[5] memory battleAttribute) {

        if (heros[heroId].types == 1 || heros[heroId].types == 2) {
            battleAttribute[0] = heros[heroId].power * (10  + 2 * (heros[heroId].level - 1)) / 10;
        }

        if (heros[heroId].types == 3 || heros[heroId].types == 4) {
           battleAttribute[0] = heros[heroId].wisdom * (10  + 2 * (heros[heroId].level - 1)) / 10;
        }

        //生命值
        battleAttribute[1] = heros[heroId].physicalPower * 5 * (10  + 2 * (heros[heroId].level - 1)) / 10 ;

        //物理防御
        battleAttribute[2] = heros[heroId].belief * (10  + 2 * (heros[heroId].level - 1)) / 10;

        //法术防御
        battleAttribute[3] =  heros[heroId].science * (10  + 2 * (heros[heroId].level - 1)) / 10;

        //命中
        battleAttribute[4]= (100 * heros[heroId].speed).div(heros[heroId].speed + heros[heroId].speed.div(2));

        return battleAttribute;
    }

    //卡片升级
    function upHeroCard(uint8 heroId) public {

        require(heros[heroId].onwerAddr == msg.sender,"This user is not the owner");

        require(tasks[heroId].heroId == 0 && tasks[heroId].startBlock == 0,"This hero is not available");

        require(sells[heroId].price == 0 || (sells[heroId].price > 0 && sells[heroId].sold),"This card is already onsale");

        uint256 DOOCost = heroPublicAttributes[heros[heroId].level].DOOCost * 10 ** 18;

        uint256 DOMCost = heroPublicAttributes[heros[heroId].level].DOMCost * 10 ** 18;

        if(DOOCost > 0){

            DOO.approveToController(msg.sender, DOOCost);
        
            DOO.transferFrom(msg.sender, address(this), DOOCost);
        }

        DOM.approveToController(msg.sender, DOMCost);
    
        DOM.transferFrom(msg.sender, address(this), DOMCost);

        uint256 index = _findIndex(msg.sender, heroId);

        require(index != 10000000000 , "Index is not find");
		
        if (_getRandom(100) < heroPublicAttributes[heros[heroId].level].failRate) {

            delete heros[heroId];

            delete userHeros[msg.sender][index];

            DDN.approveToController(msg.sender, heros[heroId].tokenId);

            DDN.burn(heros[heroId].tokenId);

            emit UpHero(msg.sender, heroId, heros[heroId].level, false);
        }else {	

            heros[heroId].level  ++;

            emit UpHero(msg.sender, heroId, heros[heroId].level, true);
        }
    }

    //设置基价
    function setBasePrice(uint256 price) public onlyOwner {

        require(price > 0,"Input is zero");

        basePrice = price;
    }

    //计算产出率, 更新产币率, 每天更新
    function updateMiningRatio() public onlyOwner {

        uint256 WBNBNum = ERC20(WBNBAddr).balanceOf(pairAddr);

        uint256 DOONum = DOM.balanceOf(pairAddr);

        //精度问题???
        uint256 price = 10000 * WBNBNum.div(DOONum);

        uint256 ratio = 10000;

        if(price < basePrice){
            ratio = (100 * price.div(basePrice) ** 2);               
        }

        miningRatio = ratio;
    }

    //设置swap及币地址
    function setPairAddress(address pairAddress, address WBNBAddress) public onlyOwner {

        pairAddr = pairAddress;

        WBNBAddr = WBNBAddress;
    }

    function setDOOOfOpenCard(uint256 DOOCost) public onlyOwner {
        DOOOfOpenCard = DOOCost;
    }

    //执行任务 1234堡垒任务  10 是搜集物资
    function executeTask(uint256 heroId, uint256 activeType) public {

        require(heros[heroId].onwerAddr == msg.sender,"This user is not the owner");

        require(tasks[heroId].startBlock == 0 && heros[heroId].level > 1 ,"This hero is not available");

        require(sells[heroId].price == 0 || (sells[heroId].price > 0 && sells[heroId].sold),"This hero is already onsale");

        if(activeType < 10) {
            require(heros[heroId].rarity > 5,"This hero's rarity is non-compliant");
        } 

        tasks[heroId].heroId = heroId;

        tasks[heroId].taskTypes = activeType;

        tasks[heroId].startBlock = block.number;

        emit ExecuteTask(msg.sender, heroId, activeType, block.number);
    }

    
  
    //领取奖励
    function taskRewardWithdrew(uint256 heroId) public {

        require(heros[heroId].onwerAddr == msg.sender,"This user is not the owner");

        require(sells[heroId].price == 0 || (sells[heroId].price > 0 && sells[heroId].sold),"This card is already onsale");

        require(tasks[heroId].startBlock > 0,"This hero is not available");

        uint256 reward = getTaskReward(heroId);

        DOM.transfer(msg.sender, reward * 10 ** 18);

        tasks[heroId].startBlock = block.number;

        emit TaskRewardWithdrew(msg.sender, heroId, reward, block.number);
    }

    function getTaskReward(uint256 heroId) public view returns (uint256 reward) {

        uint256 overtimeRatio = 10;

        uint256 number = block.number - tasks[heroId].startBlock;

        if (number > 1728000) {
            overtimeRatio = 1;
        }
        if (number > 864000) {
            overtimeRatio = 4;
        }
        if (number > 432000) {
            overtimeRatio = 8;
        }

        uint256 mainAttr;

        if (heros[heroId].types == 1) {
            mainAttr = heros[heroId].power;
        }
        if (heros[heroId].types == 2) {
            mainAttr = heros[heroId].speed;
        }       
        if (heros[heroId].types == 3) {
            mainAttr = heros[heroId].wisdom;
        }
        if (heros[heroId].types == 4) {
            mainAttr = heros[heroId].belief;
        }

        if (tasks[heroId].taskTypes < 10) {
            reward = miningRatio * overtimeRatio * (10 + (mainAttr - 85) * 5) * number * heroPublicAttributes[heros[heroId].level].profitMagnification / 100000000 ;
            return reward;
        }

        if (tasks[heroId].taskTypes == 10) {
            reward = miningRatio * overtimeRatio * number * heroPublicAttributes[heros[heroId].level].profitMagnification / 10000000 ;
            return reward;
        }

        return 0;
    }

    //结束任务
    function stopTask(uint256 heroId) public {

        taskRewardWithdrew(heroId);
        
        // require(heros[heroId].onwerAddr == msg.sender,"This user is not the owner");

        // require(sells[heroId].price == 0 || (sells[heroId].price > 0 && sells[heroId].sold),"This card is already onsale");

        // require(tasks[heroId].startBlock > 0,"This hero did not perform a mission");

        delete tasks[heroId];
    }

    //质押推荐卡
    function pledgeCards(uint256 cardsNum) public {

        require(users[msg.sender].recommendCards - users[msg.sender].pledgeCards >= cardsNum,"This user dont hava enough cards");

        totalPledgeUsers ++;

        pledgeUsers[totalPledgeUsers]  = msg.sender;

        totalPledgeCards += cardsNum;

        users[msg.sender].pledgeCards += cardsNum;
    }

    //质押分红结算
    function pledgeDividends() public onlyOwner{

        for (uint256 i = 1 ; i <= totalPledgeUsers ; i++) {

            address user = pledgeUsers[totalPledgeUsers];

            uint256 dividends = 10 ** 18 * onceDividendsDOO.mul(users[user].pledgeCards).div(totalPledgeCards);

            users[user].dayDividends = dividends;

            users[user].totalDividends += dividends;

            users[user].surplusDividends += dividends;

            accumulativeDividendsDOO += onceDividendsDOO;
        }
    }

    //提取质押分红
    function userDrawDividends() public {

        uint256 dividends = users[msg.sender].surplusDividends;

        require(dividends > 0,"This user dont hava enough cards");

        DOO.transfer(msg.sender, dividends);

        users[msg.sender].surplusDividends = 0;
    }

    //英雄卡片转让
    function heroCardTransfer(uint256 heroId, address recipient) public {

        require(heros[heroId].onwerAddr == msg.sender,"This user is not the owner");

        require(tasks[heroId].heroId == 0 && tasks[heroId].startBlock == 0,"This hero is not available");

        require(sells[heroId].price == 0 || (sells[heroId].price > 0 && sells[heroId].sold),"This card is already onsale");

        uint256 index = _findIndex(msg.sender, heroId);

        require(index != 10000000000 , "Index is not find");

        delete userHeros[msg.sender][index];

        heros[heroId].onwerAddr = recipient;

        users[recipient].heroNumber += 1;

        userHeros[recipient][users[recipient].heroNumber] = heroId;

        DDN.approveToController(msg.sender, heros[heroId].tokenId);

        DDN.transferFrom(msg.sender, recipient, heros[heroId].tokenId);

        heroSource[heroId] = 3;

        emit HeroCardTransfer(msg.sender, recipient, heroId);
    }

    //商城售卖卡牌
    function sellHeroCard(uint256 heroId, uint256 tokenType, uint256 price) public {

        require(heros[heroId].onwerAddr == msg.sender,"This user is not the owner");

        require(tasks[heroId].heroId == 0 && tasks[heroId].startBlock == 0,"This hero is not available");

        require(sells[heroId].price == 0 || (sells[heroId].price > 0 && sells[heroId].sold),"This card is not onsale");

        require((tokenType == 1 || tokenType == 2) && price > 0,"The price is zero");

        uint256 index = _findSellIndex(heroId);

        if(index == 10000000000){
            totalSell ++;

            sellsToHeroIds[totalSell] = heroId;

            sells[heroId].heroId = heroId;         
        }       

        // sells[heroId].heroId = heroId;

        sells[heroId].tokenType = tokenType;

        sells[heroId].price = price;

        sells[heroId].sold = false;

        emit SellHeroCard(msg.sender, heroId, tokenType, price);
    }

    //取消售卖卡牌
    function cancelSellHeroCard(uint256 heroId) public {

        require(heros[heroId].onwerAddr == msg.sender,"This user is not the owner");

        require(tasks[heroId].heroId == 0 && tasks[heroId].startBlock == 0,"This hero is not available");

        require(sells[heroId].price > 0 && !sells[heroId].sold,"This card dont not onsale");

        sells[heroId].price = 0;

        sells[heroId].tokenType = 0;
    }

    //商城购买卡牌
    function buyHeroCard(uint256 heroId) public {

        require(tasks[heroId].heroId == 0 && tasks[heroId].startBlock == 0,"This hero is not available");

        uint256 price = sells[heroId].price * 10 ** 18;

        require(price > 0 && !sells[heroId].sold,"This card dont not onsale");

        address ownerAddress = heros[heroId].onwerAddr;

        require(ownerAddress != msg.sender,"This buyer is owner");

        uint256 index = _findIndex(ownerAddress, sells[heroId].heroId);

        require(index != 10000000000 , "Index is not find");

        delete userHeros[ownerAddress][index];

        uint256 tradeFees = price.mul(tradeFee).div(100);

        price = price.sub(tradeFees);

        if(sells[heroId].tokenType == 1){
            DOO.approveToController(msg.sender, price * 2);

            DOO.transferFrom(msg.sender,address(this),tradeFees);//????手续费钱包地址

            DOO.transferFrom(msg.sender,ownerAddress,price);
        }

        if(sells[heroId].tokenType == 2){
            DOM.approveToController(msg.sender, price * 2);

            DOM.transferFrom(msg.sender,address(this),tradeFees);//????手续费钱包地址

            DOM.transferFrom(msg.sender,ownerAddress,price);
        }

        heros[heroId].onwerAddr = msg.sender;

        users[msg.sender].heroNumber += 1;

        userHeros[msg.sender][users[msg.sender].heroNumber] = heroId;

        sells[heroId].sold = true;

        DDN.approveToController(ownerAddress, heros[heroId].tokenId);

        DDN.transferFrom(ownerAddress, msg.sender, heros[heroId].tokenId);

        heroSource[heroId] = 2;

        emit BuyHeroCards(ownerAddress, msg.sender, heroId);
    }

    //打怪
    function fightMonster(uint256 areaId, uint256 heroId) public {

        require(heros[heroId].onwerAddr == msg.sender,"This user is not the owner");

        require(tasks[heroId].heroId == 0 && tasks[heroId].startBlock == 0,"This hero is not available");

        require(sells[heroId].price == 0 || (sells[heroId].price > 0 && sells[heroId].sold),"This card is onsale");

        require(heros[heroId].level >= areaId,"This hero have no permission to enter");

        if(getUsedTimes(heroId) == 0){
            heros[heroId].usedTimes = 0;
        }

        require(heros[heroId].usedTimes < heroPublicAttributes[heros[heroId].level].totalTimes,"The times of battles has been used up");

        uint256 ticket = areas[areaId].ticket * 10 **18;

        DOM.approveToController(msg.sender, ticket);

        DOM.transferFrom(msg.sender,address(this),ticket);

        uint256 monsterNum = _getMonsterNum(areaId);

        uint256 DOOProfit;

        uint256 DOMProfit;

        uint256 i;

        bool result;

        for (i = 0; i < monsterNum; i++) {

            uint256 monsterType = _getMonsterType(areaId);

            result = _fight(heroId, monsterType);

            if(!result) {
                break;
            }

            if(fightRewards[areaId][monsterType].dooMax > 0){
                DOOProfit += _getRandomNum(fightRewards[areaId][monsterType].dooMin, fightRewards[areaId][monsterType].dooMax);
            }

            DOMProfit += _getRandomNum(fightRewards[areaId][monsterType].domMin, fightRewards[areaId][monsterType].domMax);
        }

        heros[heroId].usedTimes ++;

        heros[heroId].lastUsedTime = block.timestamp;

        users[msg.sender].battleTimes ++;

        battleHistorys[msg.sender][users[msg.sender].battleTimes].heroId = heroId;

        battleHistorys[msg.sender][users[msg.sender].battleTimes].areaId = areaId;

        battleHistorys[msg.sender][users[msg.sender].battleTimes].monsterNumber = monsterNum;

        if(DOOProfit > 0){
            // DOO.transfer(msg.sender, DOOProfit * 10 ** 15);

            battleHistorys[msg.sender][users[msg.sender].battleTimes].DOOProfit = DOOProfit;

            users[msg.sender].DOOProfitOfBattle += DOOProfit;
        }

        if(DOMProfit > 0){
            // DOM.transfer(msg.sender, DOMProfit * 10 ** 18);

            battleHistorys[msg.sender][users[msg.sender].battleTimes].DOMProfit = DOMProfit;

            users[msg.sender].DOMProfitOfBattle += DOMProfit;
        }

        if(result){
            battleHistorys[msg.sender][users[msg.sender].battleTimes].result = result;        
        }

        emit FightMonster(heroId, monsterNum, i, DOOProfit, DOMProfit);
    }

    function withdrewBattleProfit() public {

        if(users[msg.sender].DOOProfitOfBattle > 0){
            DOO.transfer(msg.sender, users[msg.sender].DOOProfitOfBattle * 10 **15);

            users[msg.sender].DOOProfitOfBattle = 0;
        }

        if(users[msg.sender].DOMProfitOfBattle > 0){
            DOM.transfer(msg.sender, users[msg.sender].DOMProfitOfBattle * 10 **18);

            users[msg.sender].DOMProfitOfBattle = 0;
        }     
    }

    function _fight(uint256 heroId, uint256 monsterType) internal virtual returns (bool) {

        uint256 adjust = _getRandomNum(adjustLow[monsterType - 1],adjustUp[monsterType - 1]);

        uint256[5] memory attrs = heroBattleAttributes(heroId);

        uint256 heroLife = attrs[1];
   
        uint256 monsterLife = heroLife * adjust / 100;

        uint256 heroAggressivity = attrs[0];

        uint256 types = heros[heroId].types;

        uint256 defense;

        if (types == 1 || types == 2) {
            defense = attrs[2];
        }

        if (types == 3 || types == 4) {
            defense = attrs[3];
        }

        uint256 heroMiss = heroPublicAttributes[heros[heroId].level].miss;

        uint256 heroCrit = heroPublicAttributes[heros[heroId].level].crit; 

        // uint256 count = 0; 

        // uint256[50] memory bloods;

        delete bloods;

        while(heroLife > 0 && monsterLife > 0) { 

            // count ++;

            if (10 < _getRandom(100)) {

                if (heroCrit > _getRandom(100)) {

                    uint256 blood = (heroAggressivity * 150 * _getRandomNum(5,15) / 10).div(100 + defense * adjust / 100);

                    bloods.push(blood);
                    // bloods[count - 1] = blood;

                    if(monsterLife > blood){
                        monsterLife = monsterLife - blood;
                    }else{
                        monsterLife = 0;
                    }                  
                }else{

                    uint256 blood = (heroAggressivity * 100 * _getRandomNum(5,15) / 10).div(100 + defense * adjust / 100);

                    bloods.push(blood);
                    // bloods[count - 1] = blood;

                    if(monsterLife > blood){
                        monsterLife = monsterLife - blood;
                    }else{
                        monsterLife = 0;
                    }                    
                }               
            }else{
                bloods.push(0);
                // bloods[count - 1] = 0;
            }

            if(monsterLife == 0){
                break;
            }

            // count ++;   

            if (heroMiss < _getRandom(100)) {           

                if (10 > _getRandom(100)) {
                    uint256 blood = (heroAggressivity * adjust * 150 * _getRandomNum(5,15) / 1000).div(100 + defense);

                    bloods.push(blood);
                    // bloods[count - 1] = blood;

                    if(heroLife > blood){
                        heroLife = heroLife - blood;
                    }else{
                        heroLife = 0;
                    }                    
                }else{
                    uint256 blood = (heroAggressivity * adjust * 100 * _getRandomNum(5,15) / 1000).div(100 + defense);

                    bloods.push(blood);
                    // bloods[count - 1] = blood;

                    if(heroLife > blood){
                        heroLife = heroLife - blood;
                    }else{
                        heroLife = 0;
                    }                    
                }               
            }else{
                bloods.push(0);
                // bloods[count - 1] = 0;
            }

            if(heroLife == 0){
                break;
            }
        }
        emit Fight(monsterType, adjust, heroLife, monsterLife, bloods);

        return heroLife > 0;
    }

    //获取每次遇见几个怪
    function _getMonsterNum(uint256 areaId) internal virtual returns (uint256) {
        uint256 num = _getRandom(100);

        uint256 monsterNum = 0;

        for (uint256 i = 0 ; i < areas[areaId].probability.length; i++) {

            if (num < areas[areaId].probability[i]) {

                monsterNum = i + 2;

                break;
            }
        }
        return monsterNum;
    }

    //获取每次遇见怪物类型
    function _getMonsterType(uint256 areaId) internal virtual returns (uint256) {
        uint256 num = _getRandom(100);

        uint256 monsterType = 0;

        for(uint256 j = 0; j < areas[areaId].corpse.length ; j++) {

            if (num < areas[areaId].corpse[j]) {

                monsterType = j + 1;

                break;
            }
        }
        return monsterType;
    }
   
    //获取英雄卡质量
    function _getRarity() internal virtual returns (uint256) {
    
        uint256 number = _getRandom(100);

        if(number >= rarityRate[2]){
            return 8;
        }

        if(number >= rarityRate[1]){
            return 7;
        }

        if(number >= rarityRate[0]){
            return 6;
        }
        
        return 5;
    }

    //获取英雄卡属性
    function _getHeroAttr(uint256 types, uint256 rarity) internal virtual returns (uint256 num1,uint256 num2,uint256 num3,uint256 num4,uint256 num5,uint256 num6) {

        num1 = _getRandomNum(herroAttrs[rarity].mainLow, herroAttrs[rarity].mainUp);

        num2 = _getRandomNum(herroAttrs[rarity].secondaryLow, herroAttrs[rarity].secondaryUp);

        //获取其他属性
        num3 = _getRandomNum(35, 100);

        num4 = _getRandomNum(35, 100);

        num5 = _getRandomNum(35, 100);

        num6 = _getRandomNum(35, 100);
        
        if (types == 1) {
            // hero = Hero(num1, num3, num2, num4, num5, num6, totalHeros, types, rarity, 1, 0, 0, msg.sender, false);
            return (num1, num3, num2, num4, num5, num6);
        }

        if (types == 2) {
            return (num2, num1, num3, num4, num5, num6);          
        }
       
        if (types == 3) {
            return (num3, num4, num5, num1, num6, num2);     
        }
       
        if (types == 4) {
            return (num3, num2, num4, num5, num1, num6);
        }
    }

    //获取随机数
    function _getRandomNum(uint256 low, uint256 up) internal virtual returns (uint256) {

        require(up > low, "Check the number input");

        uint256 range = up - low + 1;

        uint256 num = _getRandom(range);

        return num + low;
    }
    
    //获取随机数
    function _getRandom(uint256 num) internal virtual returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, (randNum ++) * block.number, msg.sender))) % num;
    }

    function _findIndex(address user, uint256 heroId) internal view returns (uint256) {

        for (uint256 i = 1 ; i <= users[user].heroNumber ; i++) {
            if(userHeros[user][i] == heroId) return i;
        }

        return 10000000000;
    }

    function _findSellIndex(uint256 heroId) internal view returns (uint256) {

        for (uint256 i = 1 ; i <= totalSell ; i++) {
            if(sellsToHeroIds[i] == heroId) return i;
        }

        return 10000000000;
    }
    
    //获取英雄对战次数
    function getUsedTimes(uint256 heroId) public view returns (uint256) {

        if((block.timestamp + 20 hours) / 24 hours - (heros[heroId].lastUsedTime + 20 hours) / 24 hours >= 1){
            return 0;
        }else{
            return heros[heroId].usedTimes;
        }  
    }

    // function getUserHeros(address user) public view returns (uint256[] memory heroIds, Hero[] memory myHeros) {
    // function getUserHeros(address user) public view returns (uint256[] memory heroIds) {

    //     for (uint256 i = 1 ; i <= users[user].heroNumber ; i++) {
    //         uint256 heroId = userHeros[user][i];

    //         if(heroId != 0 && tasks[heroId].startBlock == 0 && sells[heroId].price == 0 || (sells[heroId].price > 0 && sells[heroId].sold)){
    //             heroIds[i - 1] = heroId;

    //             // myHeros[i - 1] = heros[heroId];
    //         }
    //     }
    // }

    // function getOnsellHeros() public view returns (Sell[] memory Onsells, uint256[] memory heroIds, Hero[] memory onsellHeros) {

    //     for (uint256 i = 1 ; i <= totalSell ; i++) {

    //         if(!sells[i].sold && sells[i].price > 0){
    //             Onsells[i - 1] = sells[i];
    //             heroIds[i - 1] = sells[i].heroId;
    //             onsellHeros[i - 1] = heros[sells[i].heroId];
    //         }
    //     }
    // }

    // function getSoldHeros() public view returns (Sell[] memory Onsells, uint256[] memory heroIds, Hero[] memory onsellHeros) {

    //     for (uint256 i = 1 ; i <= totalSell ; i++) {

    //         if(!sells[i].sold && sells[i].price > 0){
    //             Onsells[i - 1] = sells[i];
    //             heroIds[i - 1] = sells[i].heroId;
    //             onsellHeros[i - 1] = heros[sells[i].heroId];
    //         }
    //     }
    // }

}