/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-24
*/

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

// File: contracts/interfaces/ITheNeighbours.sol


pragma solidity ^0.8.0;


// Interface for neighbour contract.
interface ITheNeighbours is IERC20Metadata {
    function specialTransfer(address from, address to, uint amount) external;
}
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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

// File: contracts/interfaces/ITheFurniture.sol


pragma solidity ^0.8.0;



interface ITheFurniture is IERC721Enumerable, IERC721Metadata {
    // Strcture to store Furniture category
    struct furnitureCategory {
        string name; // Name of Furniture category, ie. Bronze, Silver, Gold, Platinum
        uint256[] dailyRewards; // daily rewards in NEIBR of all time.
        uint256[] timestamps; // APY updation timestamps.
    }

    function furnitureCategories(uint256 index)
        external
        view
        returns (furnitureCategory memory);

    // Struct to store furniture details except tokenURI.
    struct furniture {
        uint256 furnitureCategoryIndex; // Index of frunitureCategory.
        string tokenURI; // String to store token metadata
        uint256 propertyId; // tokenId of propery from property contract, 0 means not allocated
    }

    // get furniture details
    function getFurniture(uint256 tokenId)
        external
        view
        returns (furniture memory);

    function getFurnitureCategory(uint256 tokenId)
        external
        view
        returns (furnitureCategory memory);

    // Method to allocate the furniture to property
    function allocateToProperty(uint256 tokenId, uint256 _propertyId) external;

    // Method to deallocate the furniture from property
    function deallocateFromProperty(uint256 tokenId) external;


    // Special method to allow property to be transferred from owner to another user.
    function transferFromByProperty(
        address from,
        address to,
        uint256 tokenId
    ) external;
 
    // Special method to allow property to be transferred from owner to another user.
    function transferFromByPropertyBatch(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external;
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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;



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

// File: contracts/TheProperty.sol


pragma solidity ^0.8.0;








// TODO: Integrate Pausable contract as well.
contract TheProperty is ERC721, ERC721Burnable, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    // Public variables to store address of furniture and property contract
    address public neighbour;
    address public furniture;
    uint256 public precisionValue;

    // To store baseURI of property Metada.
    string baseURIPrefix;
    string baseURISuffix;

    // timestamp for which rent due is allowed.
    uint256 rentDueAllowed;

    // timestamp for a rent completion(month in secs)
    uint256 monthtime;

    // Struct to store any precesion values along with their previous values.
    struct precesionValues {
        uint256[] values;
        uint256[] timestamps;
    }

    // ********************************PropertyType section********************
    struct propertyType {
        string name; // name of property type
        uint256 price; // Price of the proerty in NEIBR
        precesionValues dailyRewards; // Daily rewards updated over time.
        uint256 maxDailyReward; // Max daily reward that an property can reach
        uint256 monthlyRent; // Monthly rent that user have to pay(proerty tax)
    }

    // Array to store all property types
    propertyType[] public propertyTypes;

    // Method to check if property type exists
    /**
     * @dev Method to check if property type exists.
     * @notice This method let's you check if property tyep exists.
     * @param _propertyTypeIndex Index of Property type to check existance.
     * @return Bool, True if property type exists else false.
     */
    function doesPropertyTypeExists(uint256 _propertyTypeIndex)
        public
        view
        returns (bool)
    {
        return _propertyTypeIndex < propertyTypes.length;
    }

    // Modfier to check if property exists or not
    modifier propertyTypeExists(uint256 _propertyTypeIndex) {
        require(
            _propertyTypeIndex < propertyTypes.length,
            "The Property: The Property type doesn't exists."
        );
        _;
    }

    /**
     * @dev This function will return length of property to loop and get all property types.
     * @notice This method returns you number of property types.
     * @return length of proerty types.
     */
    function getPropertyTypesLength() public view returns (uint256) {
        return propertyTypes.length;
    }

    /**
     * @dev Method will return if name already present.
     * @notice This method let's you check if it's already in property type.
     * @param _name Name of Property type to check existance.
     * @return Bool, True if name exists else false.
     */
    function doesPropertyTypeNameExists(string memory _name)
        public
        view
        returns (bool)
    {
        for (uint256 index = 0; index < propertyTypes.length; index++) {
            if (
                keccak256(abi.encodePacked(propertyTypes[index].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Internal method to create new Property type.
     * @param _name Name of new category.
     * @param _dailyReward Daily reward in NEIBR.
     * @param _maxDailyReward Maximum daily reward in NEIBR that a propery can have.
     * @param _monthlyRent Property tax user have to pay per month in dollers(wei).
     */
    function _createPropertyType(
        string memory _name,
        uint256 _price,
        uint256 _dailyReward,
        uint256 _maxDailyReward,
        uint256 _monthlyRent
    ) internal {
        // Check if name is avaialable.
        require(
            !doesPropertyTypeNameExists(_name),
            "The Furnitures: Name already in use."
        );

        // Create furnitureCategory memory struct.
        propertyType memory _propertyType;
        _propertyType.name = _name;
        _propertyType.price = _price;
        _propertyType.maxDailyReward = _maxDailyReward;
        _propertyType.monthlyRent = _monthlyRent;
        // _propertyType.minSellReward = _minSellReward;
        // _propertyType.propertyURI = _propertyURI;

        // Create new furniture category.
        propertyTypes.push(_propertyType);

        // Update daily reward
        propertyTypes[propertyTypes.length - 1].dailyRewards.values.push(
            _dailyReward
        );
        propertyTypes[propertyTypes.length - 1].dailyRewards.timestamps.push(
            block.timestamp
        );
    }

    /**
     * @dev Public method to create new propery type, allowed only to contract Owner.
     * @notice Let's you create new property type if you're contract Admin.
     * @param _name Name of new category.
     * @param _dailyReward Daily reward in NEIBR.
     * @param _maxDailyReward Maximum daily reward in NEIBR that a propery can have.
     * @param _monthlyRent Property tax user have to pay per month in dollers(wei).
     */
    function createPropertyType(
        string memory _name,
        uint256 _price,
        uint256 _dailyReward,
        uint256 _maxDailyReward,
        uint256 _monthlyRent
    ) external onlyOwner {
        _createPropertyType(
            _name,
            _price,
            _dailyReward,
            _maxDailyReward,
            _monthlyRent
        );
    }

    /**
     * @dev Method to udate price of Property, Allowed or owner only.
     * @notice This method let's you change the price of property if you're owner of contract.
     * @param _price New Price of the Proerty type in wei
     * @param _propertyTypeIndex Index of property type
     */
    function updateProperyTypePrice(uint256 _price, uint256 _propertyTypeIndex)
        public
        onlyOwner
        propertyTypeExists(_propertyTypeIndex)
    {
        propertyTypes[_propertyTypeIndex].price = _price;
    }

    /**
     * @dev Method to udate daily reward of Property, Allowed or owner only.
     * @notice This method let's you change the daily reward of property if you're owner of contract.
     * @param _dailyReward Daily reward in NEIBR.
     * @param _propertyTypeIndex Index of property type
     */
    function updateProperyTypeDailyReward(
        uint256 _dailyReward,
        uint256 _propertyTypeIndex
    ) public onlyOwner propertyTypeExists(_propertyTypeIndex) {
        propertyTypes[_propertyTypeIndex].dailyRewards.values.push(
            _dailyReward
        );
        propertyTypes[_propertyTypeIndex].dailyRewards.timestamps.push(
            block.timestamp
        );
    }

    /**
     * @dev Method to udate maxDailyReward of Property, Allowed or owner only.
     * @notice This method let's you change the maxDailyReward of property if you're owner of contract.
     * @param _maxDailyReward Maximum daily reward in NEIBR that a propery can have.
     * @param _propertyTypeIndex Index of property type
     */
    function updateProperyTypeMaxDailyReward(
        uint256 _maxDailyReward,
        uint256 _propertyTypeIndex
    ) public onlyOwner propertyTypeExists(_propertyTypeIndex) {
        propertyTypes[_propertyTypeIndex].maxDailyReward = _maxDailyReward;
    }

    /**
     * @dev Method to udate monthlyRent of Property, Allowed or owner only.
     * @notice This method let's you change the monthlyRent of property if you're owner of contract.
     * @param _monthlyRent Property tax user have to pay per month in dollers(wei)
     * @param _propertyTypeIndex Index of property type
     */
    function updateProperyTypeMothlyRent(
        uint256 _monthlyRent,
        uint256 _propertyTypeIndex
    ) public onlyOwner propertyTypeExists(_propertyTypeIndex) {
        propertyTypes[_propertyTypeIndex].monthlyRent = _monthlyRent;
    }

    // ********************************PropertyType section end****************

    // ********************************Property section************************

    struct property {
        string name; //Name of property
        uint256 propertyTypeIndex; // Property type index.
        uint256 createdOn; // Timestamp when Propery was created.
        precesionValues furnitureIndices; // Furniture indices and allocation times.
        uint256 lastRentDeposited; // Time then the last rent was deposted.
        uint256 lastRewardCalculated; // Timestamp when the reward was calculated.
        uint256 unclaimedDetachedReward; // Unclaimed reward that have no record in contract.
    }

    uint256 public presaleStart; // Starting timestamp for presale.
    uint256 public presaleEnd; // Ending timestamp for presale.
    address public presaleContract; // Contract address for presale.

    uint256 public rewardCalculationTime;

    // Method to start reward calculation time. Can be executed only once.
    function startRewardCalculation() public onlyOwner {
        require(
            rewardCalculationTime == 0,
            "The Property: Reward calculation already started"
        );
        rewardCalculationTime = block.timestamp;
    }

    // Method to start presale.
    function setPresale(
        uint256 _presaleStart,
        uint256 _presaleEnd,
        address _presaleContract
    ) public onlyOwner {
        require(
            _presaleStart >= block.timestamp,
            "The Property: The presale start time must be future time."
        );
        require(
            _presaleStart < _presaleEnd,
            "The Property: The presale end time must be future time from starting time."
        );
        require(
            _presaleContract != address(0),
            "The Property: The presale contract must be valid address."
        );
        presaleStart = _presaleStart;
        presaleEnd = _presaleEnd;
        presaleContract = _presaleContract;
    }

    // Function to check if contract is in presale state.
    function validPresale() private view returns (bool) {
        return (block.timestamp >= presaleStart &&
            block.timestamp <= presaleEnd &&
            msg.sender == presaleContract);
    }

    // Function to end presale right away.
    function termintatePresale() public onlyOwner {
        presaleStart = 0;
        presaleEnd = 0;
        presaleContract = address(0);
    }

    // Array to store properties
    property[] properties;

    // Modifier to check if property exists
    modifier propertyExists(uint256 tokenId) {
        require(
            _exists(tokenId),
            "The Property: operator query for nonexistent token"
        );
        _;
    }

    // Method to create new property:
    function _mintProperty(uint256 _propertyTypeIndex, string memory _name)
        internal
        propertyTypeExists(_propertyTypeIndex)
    {
        // Create memory object.
        property memory _property;
        _property.propertyTypeIndex = _propertyTypeIndex;
        _property.name = _name;
        _property.createdOn = block.timestamp;
        _property.lastRentDeposited = block.timestamp;
        _property.lastRewardCalculated = block.timestamp;

        // Add property to properties
        properties.push(_property);

        // Mint property
        _mint(msg.sender, properties.length - 1);
    }

    /**
     * @dev Public method to mint the property.
     * @notice This method allows you to create new property by paying the presale price
     * @param _propertyTypeIndex Property type index
     * @param _name Name of the property
     */
    function presaleMint(uint256 _propertyTypeIndex, string memory _name)
        external
    {
        require(validPresale(), "The Property: Presale only!!");
        _mintProperty(_propertyTypeIndex, _name);
    }

    // Method to create new property:
    function mint(uint256 _propertyTypeIndex, string memory _name) public {
        require(
            presaleStart >= block.timestamp,
            "The Property: Can't mint before presale."
        );
        require(
            presaleEnd <= block.timestamp,
            "The Property: Can't mint in presale."
        );
        require(
            presaleContract == msg.sender,
            "The Property: Can't be minted by presale."
        );
        ITheNeighbours _neighbour = ITheNeighbours(neighbour);
        require(
            _neighbour.balanceOf(msg.sender) >=
                propertyTypes[_propertyTypeIndex].price,
            "The  Property: You don't have sufficient balance to buy property."
        );
        _neighbour.specialTransfer(
            msg.sender,
            address(this),
            propertyTypes[_propertyTypeIndex].price
        );
        _mintProperty(_propertyTypeIndex, _name);
    }

    // Method to get property
    function getProperty(uint256 tokenId)
        public
        view
        propertyExists(tokenId)
        returns (property memory)
    {
        return properties[tokenId];
    }

    // Internal method to get baseURI
    function baseURI() external view returns (string memory) {
        return
            bytes(baseURIPrefix).length > 0
                ? string(abi.encodePacked(baseURIPrefix, "{id}", baseURISuffix))
                : "";
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURIPrefix).length > 0
                ? string(
                    abi.encodePacked(
                        baseURIPrefix,
                        tokenId.toString(),
                        baseURISuffix
                    )
                )
                : "";
    }

    // /**
    //  * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    //  */
    // function tokenURI(uint256 tokenId)
    //     public
    //     view
    //     virtual
    //     override
    //     propertyExists(tokenId)
    //     returns (string memory)
    // {
    //     string memory _tokenURI = propertyTypes[
    //         properties[tokenId].propertyTypeIndex
    //     ].propertyURI;
    //     string memory base = _baseURI();

    //     // If there is no base URI, return the token URI.
    //     if (bytes(base).length == 0) {
    //         return _tokenURI;
    //     }
    //     // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    //     if (bytes(_tokenURI).length > 0) {
    //         return string(abi.encodePacked(base, _tokenURI));
    //     }

    //     return super.tokenURI(tokenId);
    // }

    // Method to set baseURI.
    function setURIPrefix(string memory _URIPrefix) public onlyOwner {
        baseURIPrefix = _URIPrefix;
    }

    // Method to set baseURI.
    function setURISuffix(string memory _URISuffix) public onlyOwner {
        baseURISuffix = _URISuffix;
    }

    // ********************************Property section end *******************

    // ********************************Property rent section ******************

    modifier proertyOwnerOnly(uint256 tokenId) {
        require(
            msg.sender == ownerOf(tokenId),
            "The Property: Property owner only."
        );
        _;
    }

    // TODO: get value in avax from exchange.
    function getRentInAVAX(uint256 _propertyTypeIndex)
        public
        view
        propertyTypeExists(_propertyTypeIndex)
        returns (uint256)
    {
        return propertyTypes[_propertyTypeIndex].monthlyRent;
    }

    // Method to check if the rent is cleared.
    function isRentCleared(uint256 tokenId) public view returns (bool) {
        require(
            super._exists(tokenId),
            "The Property: operator query for nonexistent token"
        );
        if (
            properties[tokenId].lastRentDeposited + monthtime >= block.timestamp
        ) {
            return true;
        }
        return false;
    }

    // Method to check if proerty is locked due to insufficient rent payment.
    function isPropertyLocked(uint256 tokenId) public view returns (bool) {
        require(
            super._exists(tokenId),
            "The Property: operator query for nonexistent token"
        );
        if (
            properties[tokenId].lastRentDeposited + monthtime + rentDueAllowed <
            block.timestamp
        ) {
            return true;
        }
        return false;
    }

    // Method to accept rent
    function acceptRent(uint256 tokenId)
        public
        payable
        proertyOwnerOnly(tokenId)
        propertyExists(tokenId)
    {
        require(
            msg.value >= getRentInAVAX(tokenId),
            "The Property: Insufficient rent supplied. "
        );

        // update the rent by 1 month.
        properties[tokenId].lastRentDeposited += monthtime;
    }

    // Method to get upcoming due date for rent payment.
    function getUpcomingRentDue(uint256 tokenId)
        public
        view
        propertyExists(tokenId)
        returns (uint256)
    {
        return properties[tokenId].lastRentDeposited + monthtime;
    }

    // Method to get upcoming due date for rent payment.
    function getLastDate(uint256 tokenId)
        public
        view
        propertyExists(tokenId)
        returns (uint256)
    {
        return
            properties[tokenId].lastRentDeposited + monthtime + rentDueAllowed;
    }

    // Override _exists method of ERC721 to stop every execution if the the proerty is locked.
    function _exists(uint256 tokenId) internal view override returns (bool) {
        // require(
        //     !isPropertyLocked(tokenId),
        //     "The Property: This property is locked due to insufficient tax payment"
        // );
        // return super._exists(tokenId);
        // Check for the property lock if token exists:
        if (super._exists(tokenId)) {
            return
                properties[tokenId].lastRentDeposited +
                    monthtime +
                    rentDueAllowed <
                block.timestamp;
        }
        return false;
    }

    // ********************************Property rent section end **************

    // ********************************Property Furniture section start *******

    // Method to check if furniture is allocated in property
    function isFurnitureAllocated(uint256 tokenId, uint256 _furnitureId)
        public
        view
        returns (bool)
    {
        for (
            uint256 index = 0;
            index < properties[tokenId].furnitureIndices.values.length;
            index++
        ) {
            if (
                properties[tokenId].furnitureIndices.values[index] ==
                _furnitureId
            ) {
                return true;
            }
        }
        return false;
    }

    // Method to allocate furniture in property
    function allocateFurniture(uint256 tokenId, uint256 _furnitureId)
        public
        proertyOwnerOnly(tokenId)
        propertyExists(tokenId)
    {
        ITheFurniture _furniture = ITheFurniture(furniture);
        _furniture.allocateToProperty(_furnitureId, tokenId);
        properties[tokenId].furnitureIndices.values.push(_furnitureId);
        properties[tokenId].furnitureIndices.timestamps.push(block.timestamp);

        // TODO: check if Total daily reward have been reached to minSellReward and update daily reward reached
    }

    // Method to deallocate furniture
    function _deallocateFurniture(uint256 tokenId, uint256 _furnitureId)
        internal
    {
        require(
            isFurnitureAllocated(tokenId, _furnitureId),
            "The Property: The Furniture is not allocated to property."
        );
        // Loop through all furnitures.
        for (
            uint256 index = 0;
            index < properties[tokenId].furnitureIndices.values.length;
            index++
        ) {
            // Chack for furniture allocation.
            if (
                properties[tokenId].furnitureIndices.values[index] ==
                _furnitureId
            ) {
                // Remove furniture
                properties[tokenId].furnitureIndices.values[index] = properties[
                    tokenId
                ].furnitureIndices.values[
                        properties[tokenId].furnitureIndices.values.length - 1
                    ];
                properties[tokenId].furnitureIndices.values.pop();

                // Remove timestamp
                properties[tokenId].furnitureIndices.timestamps[
                    index
                ] = properties[tokenId].furnitureIndices.timestamps[
                    properties[tokenId].furnitureIndices.timestamps.length - 1
                ];
                properties[tokenId].furnitureIndices.timestamps.pop();

                // Stop execution.
                break;
            }
        }
    }

    // Method to deallocate the property
    function deallocateFurniture(uint256 tokenId, uint256 _furnitureId)
        public
        proertyOwnerOnly(tokenId)
        propertyExists(tokenId)
    {
        // Delloacte the property from furniture contract
        ITheFurniture _furniture = ITheFurniture(furniture);
        _furniture.deallocateFromProperty(_furnitureId);

        // Calculate and update the unclaimed reward.
        _updateReward(tokenId);

        // Deallocate the furniture from property
        _deallocateFurniture(tokenId, _furnitureId);

        // TODO: Calculate current reward and update in the property.
    }

    // ********************************Property furniture section end *********

    // ********************************Property reward section end ************

    // TODO: Method to udpate last calculated reward for the property.
    function _updateReward(uint256 tokenId) internal {}

    // /**
    //  * @dev This function is used to calculate current reward
    //  * @return reward calculated till current block
    //  */
    // function _calculateRewardInTimeframe(
    //     uint256 amount,
    //     uint256 _APY,
    //     uint256 duration
    // ) internal view returns (uint256 reward) {
    //     if (amount > 0) {
    //         // Without safemath formula for explanation
    //         // reward = (
    //         //     (stakeDetail.stake * stakeDetails.APY * (block.timestamp - stakeDetail.lastRewardCalculated)) /
    //         //     (APYTime * 100 * 1000)
    //         // );

    //         reward = amount.mul(_APY).mul(duration).div(
    //             APYTime.mul(100).mul(precisionValue)
    //         );
    //     } else {
    //         reward = 0;
    //     }
    // }

    // Internal method to calculate the reward.
    // function _calculateReward(uint256 tokenId) internal view returns (uint256) {
    //     property memory _property = properties[tokenId];
    //     uint256 rewardSum = 0;
    //     uint256 startingTime = _property.createdOn <=
    //         _property.lastRewardCalculated
    //         ? _property.lastRewardCalculated
    //         : _property.createdOn;
    //     uint256 endingTime = block.timestamp;
    //     uint256 nextEndingTime = block.timestamp;

    //     propertyType memory _propertyType = propertyTypes[
    //         _property.propertyTypeIndex
    //     ];

    //     // Loop through all APYs for propertyType
    //     for (uint256 i = 0; i < _propertyType.APYs.values.length; i++) {
    //         // Skip the execution if already used this APY.
    //         if (i + 1 < _propertyType.APYs.values.length) {
    //             if (startingTime >= _propertyType.APYs.timestamps[i + 1]) {
    //                 continue;
    //             } else if (endingTime >= _propertyType.APYs.timestamps[i + 1]) {
    //                 nextEndingTime = endingTime;
    //                 endingTime = _propertyType.APYs.timestamps[i + 1];
    //             }
    //         }
    //         uint256 _APY = _propertyType.APYs.values[i];
    //         uint256 _baseAPY = _propertyType.APYs.values[i];

    //         // Loop through every furniture
    //         for (
    //             uint256 j = 0;
    //             j < _property.furnitureIndices.values.length;
    //             j++
    //         ) {
    //             ITheFurniture.furnitureCategory
    //                 memory _furnitureCategory = ITheFurniture(furniture)
    //                     .getFurnitureCategory(tokenId);

    //             // Boost current APY percentage.
    //             // Loop through All APY of category
    //             for (uint256 k = 0; k < _furnitureCategory.APYs.length; k++) {
    //                 // Skip the execution if already used this APY.
    //                 if (k + 1 < _furnitureCategory.APYs.length) {
    //                     if (
    //                         startingTime >= _furnitureCategory.timestamps[k + 1]
    //                     ) {
    //                         continue;
    //                     } else if (
    //                         endingTime >= _propertyType.APYs.timestamps[i + 1]
    //                     ) {
    //                         nextEndingTime = endingTime;
    //                         endingTime = _propertyType.APYs.timestamps[i + 1];
    //                     }
    //                 }
    //                 _APY += ((_baseAPY * _furnitureCategory.APYs[i]) /
    //                     (100 * precisionValue));
    //                 break;
    //             }
    //         }

    //         // calculate reward for current timeframe and update the timeframe.
    //         rewardSum += _calculateRewardInTimeframe(
    //             _propertyType.price,
    //             _APY,
    //             endingTime - startingTime
    //         );

    //         // Mark execution complete if it have been done till block.timestamp
    //         if (endingTime == block.timestamp) break;

    //         // Update timings to calculate next cycle
    //         startingTime = endingTime;
    //         endingTime = nextEndingTime;
    //         nextEndingTime = block.timestamp;
    //     }

    //     return rewardSum;
    // }

    function _calculateReward(uint256 tokenId) private returns (uint256) {}

    // ********************************Property furniture section end *********

    constructor(string memory _URIPrefix, string memory _URISuffix) ERC721("The Property", "PRT") {
        // Set baseURI
        baseURIPrefix = _URIPrefix;
        baseURISuffix = _URISuffix;

        // Insert blank property at init to match the tokenId from ERC721
        property memory _property; // MUST NOT BE DELETED
        properties.push(_property); // MUST NOT BE DELETED

        // Create all 4 default categories.
        string[3] memory _properyTypeNames = ["Condo", "House", "Mansion"];

        // Prices in $NEIBR
        uint256[3] memory _prices = [
            uint256(4 * (10**18)), // Condo   4 $NEIBR
            7 * (10**18), // House   7 $NEIBR
            10 * (10**18) // Mansion 10 $NEIBR
        ];

        // Daily rewards in $NEIBR
        uint256[3] memory _dailyRewards = [
            uint256(6 * (10**16)), // Condo 0.06 $NEIBR
            8 * (10**16), // House  0.08 $NEIBR
            10 * (10**16) // Mansion 0.1 $NEIBR
        ];

        // Max daily rewards in $NEIBR
        uint256[3] memory _maxDailyRewards = [
            uint256(8 * (10**16)), // Condo Max (with home decor) 0.08 $NEIBR
            10 * (10**16), // House Max (with home decor) 0.1 $NEIBR
            13 * (10**16) // Mansion Max (with home decor) 0.13 $NEIBR
        ];

        // Monthly rent in doller. It have 6 decimal presion only.
        uint256[3] memory _monthlyRents = [
            uint256(10 * (10**6)), // Condo    10$ a month paid in $AVAX
            13 * (10**6), // House    13$ a month paid in $AVAX
            17 * (10 * 6) // Mansion  17$ a month paid in $AVAX
        ];

        for (uint256 i = 0; i < _properyTypeNames.length; i++) {
            _createPropertyType(
                _properyTypeNames[i],
                _prices[i],
                _dailyRewards[i],
                _maxDailyRewards[i],
                _monthlyRents[i]
            );
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}