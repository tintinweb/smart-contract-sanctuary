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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ERC721Auction is Context, IERC721Receiver, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    /// @notice Event emitted only on construction. To be used by indexers
    event AuctionCreated(address indexed tokenContractAddress, uint256 indexed tokenId);
    event AuctionEnded(address indexed tokenContractAddress, uint256 indexed tokenId);

    event BidPlaced(
        address indexed tokenContractAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bidAmount
    );

    event FundWithdrawn(
        address indexed tokenContractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        uint256 withdrawAmount
    );

    event FundReturned(
        address indexed tokenContractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        uint256 returnAmount
    );

    /// @notice Parameters of an auction
    struct Auction {
        address owner;
        uint256 startPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 fee; // percent
        address fundTokenAddress;
        bool created;
    }

    /// @notice Information about the sender that placed a bid on an auction
    struct Bid {
        address bidder;
        uint256 bidAmount;
        uint256 actualBidAmount;
        uint256 bidTime;
    }

    /// @notice ERC721 Token Contract Address => Token ID -> Auction Parameters
    mapping(address => mapping(uint256 => Auction)) public auctions;
    mapping(address => mapping(uint256 => uint256)) public availableFunds;

    /// @notice ERC721 Token ID -> bidder info (if a bid has been received)
    mapping(address => mapping(uint256 => Bid[])) public bids;

    modifier onlyCreatedAuction(address _tokenContractAddress, uint256 _tokenId) {
        require(
            auctions[_tokenContractAddress][_tokenId].created == true,
            "Auction.onlyCreatedAuction: Auction does not exist"
        );
        _;
    }

    modifier onlyAuctionOwner(address _tokenContractAddress, uint256 _tokenId) {
        require(
            auctions[_tokenContractAddress][_tokenId].owner == _msgSender(),
            "Auction.onlyAuctionOwner: not auction owner"
        );
        _;
    }

    /**
     * @notice Creates a new auction for a given token
     * @dev Only the owner of a token can create an auction and must have approved the contract
     * @dev End time for the auction must be in the future.
     * @param _tokenId Token ID of the token being auctioned
     * @param _startTimestamp Unix epoch in seconds for the auction start time
     * @param _endTimestamp Unix epoch in seconds for the auction end time.
     * @param _fee percent which will be paid as a fee to the individual who provides the hightest loan amount
     */
    function createAuction(
        address _tokenContractAddress,
        uint256 _tokenId,
        uint256 _startPrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _fee,
        address _fundTokenAddress
    ) external {
        // Check owner of the token is the creator and approved
        require(
            IERC721(_tokenContractAddress).isApprovedForAll(IERC721(_tokenContractAddress).ownerOf(_tokenId), address(this)),
            "Auction.createAuction: Owner has not approved"
        );
        require(
            IERC721(_tokenContractAddress).ownerOf(_tokenId) == _msgSender(),
            "Auction.createAuction: Caller is not the owner"
        );

        _createAuction(_tokenContractAddress ,_tokenId, _startPrice,_startTimestamp, _endTimestamp, _fee, _fundTokenAddress);

        emit AuctionCreated(_tokenContractAddress, _tokenId);
    }

    /**
     * @notice Places a new bid, out bidding the existing bidder if found and criteria is reached
     * @dev Only callable when the auction is open
     * @dev Bids from smart contracts are prohibited to prevent griefing with always reverting receiver
     * @param _tokenId Token ID of the token being auctioned
     */
    function placeBid(address _tokenContractAddress, uint256 _tokenId, uint256 _bidAmount)
        external
        nonReentrant
        onlyCreatedAuction(_tokenContractAddress, _tokenId)
    {
        require(
            _msgSender().isContract() == false,
            "Auction.placeBid: No contracts permitted"
        );

        // Ensure auction is in flight
        require(
            _getNow() >= auctions[_tokenContractAddress][_tokenId].startTime 
                && _getNow() <= auctions[_tokenContractAddress][_tokenId].endTime,
            "Auction.placeBid: Bidding outside of the auction window"
        );

        _placeBid(_tokenContractAddress, _tokenId, _bidAmount);

        emit BidPlaced(_tokenContractAddress, _tokenId, _msgSender(), _bidAmount);
    }

    /**
     * @notice withdraw funds which deposit by bidders
     * @dev Only callable when the auction is open
     * @dev Only callable by auction owner
     * @param _tokenId Token ID of the token being auctioned
     * @param _withdrawAmount withdraw amount which owner want to withdraw
     */
    function withdrawFunds(address _tokenContractAddress, uint256 _tokenId, uint256 _withdrawAmount)
        external
        nonReentrant
        onlyCreatedAuction(_tokenContractAddress, _tokenId)
        onlyAuctionOwner(_tokenContractAddress, _tokenId)
    {
        require(
            availableFunds[_tokenContractAddress][_tokenId] >= _withdrawAmount,
            "Auction.withdrawFunds: not enough funds"
        );

        IERC20(auctions[_tokenContractAddress][_tokenId].fundTokenAddress)
            .transfer(auctions[_tokenContractAddress][_tokenId].owner, _withdrawAmount);

        availableFunds[_tokenContractAddress][_tokenId] -= _withdrawAmount;

        emit FundWithdrawn(_tokenContractAddress, _tokenId, _msgSender(), _withdrawAmount);
    }

    /**
     * @notice return funds which deposit by bidders
     * @dev Only callable when the auction is open
     * @dev Only callable by auction owner
     * @param _tokenId Token ID of the token being auctioned
     * @param _returnAmount return amount which owner want to return
     */
    function returnFunds(address _tokenContractAddress, uint256 _tokenId, uint256 _returnAmount)
        external
        nonReentrant
        onlyCreatedAuction(_tokenContractAddress, _tokenId)
        onlyAuctionOwner(_tokenContractAddress, _tokenId)
    {
        require(
            IERC20(auctions[_tokenContractAddress][_tokenId].fundTokenAddress)
                .balanceOf(auctions[_tokenContractAddress][_tokenId].owner) >= _returnAmount,
            "Auction.returnFunds: auction owner has not enough return amount"
        );

        IERC20(auctions[_tokenContractAddress][_tokenId].fundTokenAddress)
            .transferFrom(auctions[_tokenContractAddress][_tokenId].owner, address(this), _returnAmount);

        availableFunds[_tokenContractAddress][_tokenId] += _returnAmount;

        emit FundReturned(_tokenContractAddress, _tokenId, _msgSender(), _returnAmount);
    }

    /**
     * @notice end Auction if time is over
     * @param _tokenId Token ID of the token being auctioned
     */
    function endAuction(address _tokenContractAddress, uint256 _tokenId) 
        external 
        nonReentrant
        onlyCreatedAuction(_tokenContractAddress, _tokenId)
    {
        Auction memory auction = auctions[_tokenContractAddress][_tokenId];

        // Check the auction real
        require(
            auction.endTime > 0,
            "Auction.endAuction: Auction does not exist"
        );

        // Check the auction has ended
        require(
            _getNow() > auction.endTime,
            "Auction.endAuction: The auction has not ended"
        );

        // Ensure this contract is approved to move the token
        require(
            IERC721(_tokenContractAddress).isApprovedForAll(auction.owner, address(this)),
            "Auction.endAuction: auction not approved"
        );

        Bid[] storage bidList = bids[_tokenContractAddress][_tokenId];
        require(bidList.length > 0, "Auction.endAuction: no bid exist");

        uint256 benefit;
        benefit = bidList[bidList.length - 1].actualBidAmount.mul(auctions[_tokenContractAddress][_tokenId].fee).div(100)
            .mul(_getNow().sub(auctions[_tokenContractAddress][_tokenId].startTime))
            .div(auctions[_tokenContractAddress][_tokenId].endTime.sub(auctions[_tokenContractAddress][_tokenId].startTime));
        uint256 returnFund = bidList[bidList.length - 1].actualBidAmount + benefit;

        if(availableFunds[_tokenContractAddress][_tokenId] < returnFund) {
            IERC721(_tokenContractAddress).safeTransferFrom(address(this), bidList[bidList.length - 1].bidder, _tokenId);
            IERC20(auctions[_tokenContractAddress][_tokenId].fundTokenAddress)
                .transfer(auctions[_tokenContractAddress][_tokenId].owner, availableFunds[_tokenContractAddress][_tokenId]);
            availableFunds[_tokenContractAddress][_tokenId] = 0;
        } else {
            IERC20(auctions[_tokenContractAddress][_tokenId].fundTokenAddress)
                .transferFrom(address(this), bidList[bidList.length - 1].bidder, returnFund);
            availableFunds[_tokenContractAddress][_tokenId] -= returnFund;

            IERC721(_tokenContractAddress).safeTransferFrom(address(this), auctions[_tokenContractAddress][_tokenId].owner, _tokenId);
            IERC20(auctions[_tokenContractAddress][_tokenId].fundTokenAddress)
                .transfer(auctions[_tokenContractAddress][_tokenId].owner, availableFunds[_tokenContractAddress][_tokenId]);
            availableFunds[_tokenContractAddress][_tokenId] = 0;
        }

        // Clean up the highest bid
        delete bids[_tokenContractAddress][_tokenId];
        delete auctions[_tokenContractAddress][_tokenId];
        delete availableFunds[_tokenContractAddress][_tokenId];
        
        emit AuctionEnded(_tokenContractAddress, _tokenId);
    }

    /**
     * @notice Method for getting all info about the auction
     * @param _tokenId Token ID of the token being auctioned
     */
    function getAuction(address _tokenContractAddress, uint256 _tokenId)
        external
        view
        onlyCreatedAuction(_tokenContractAddress, _tokenId)
        returns (Auction memory)
    {
        return auctions[_tokenContractAddress][_tokenId];
    }

    /**
     * @notice Method for getting all info about the bids
     * @param _tokenId Token ID of the token being auctioned
     */
    function getBidList(address _tokenContractAddress, uint256 _tokenId) public view returns (Bid[] memory) {
        return bids[_tokenContractAddress][_tokenId];
    }

    /**
     * @notice Method for getting available funds by tokenId
     * @param _tokenId Token ID of the token being auctioned
     */
    function getAvailableFunds(address _tokenContractAddress, uint256 _tokenId) public view returns (uint) {
        return availableFunds[_tokenContractAddress][_tokenId];
    }

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _createAuction(
        address _tokenContractAddress,
        uint256 _tokenId,
        uint256 _startPrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _fee,
        address _fundTokenAddress
    ) private {
        // Check the auction alreay created
        require(
            auctions[_tokenContractAddress][_tokenId].created == false,
            "Auction.createAuction: Auction has been already created"
        );
        // Check end time not before start time and that end is in the future
        require(
            _endTimestamp > _startTimestamp,
            "Auction.createAuction: End time must be greater than start"
        );
        require(
            _endTimestamp > _getNow(),
            "Auction.createAuction: End time passed. Nobody can bid"
        );

        // Setup the auction
        auctions[_tokenContractAddress][_tokenId] = Auction({
            owner: _msgSender(),
            startPrice: _startPrice,
            startTime: _startTimestamp,
            endTime: _endTimestamp,
            fee: _fee,
            fundTokenAddress: _fundTokenAddress, 
            created: true
        });

        IERC721(_tokenContractAddress).safeTransferFrom(_msgSender(), address(this), _tokenId);
    }

    /**
     * @notice Used for placing bid with token id
     * @param _tokenId id of the token
     */
    function _placeBid(address _tokenContractAddress, uint256 _tokenId, uint256 _bidAmount) private {
        Bid[] storage bidList = bids[_tokenContractAddress][_tokenId];
        uint256 bidAmount = _bidAmount;
        uint256 benefit;
        if (bidList.length != 0) {
            benefit = bidList[bidList.length - 1].actualBidAmount.mul(auctions[_tokenContractAddress][_tokenId].fee).div(100)
                .mul(_getNow().sub(auctions[_tokenContractAddress][_tokenId].startTime))
                .div(auctions[_tokenContractAddress][_tokenId].endTime.sub(auctions[_tokenContractAddress][_tokenId].startTime));
        }
        uint256 actualBidAmount = bidAmount + benefit;

        // Ensure bid adheres to outbid increment and threshold

        if (bidList.length != 0) {
            Bid memory prevHighestBid = bidList[bidList.length - 1];
            uint256 minBidRequired = prevHighestBid.actualBidAmount;
            require(
                bidAmount > minBidRequired,
                "Auction.placeBid: Failed to outbid highest bidder"
            );
        } else {
            require(
                actualBidAmount >= auctions[_tokenContractAddress][_tokenId].startPrice,
                "Auction.placeBid: Bid amount should be higher than start price"
            );
        }

        require(
            IERC20(auctions[_tokenContractAddress][_tokenId].fundTokenAddress).balanceOf(_msgSender()) >= actualBidAmount,
            "Auction.placeBid: bidder has not enough balance"
        );

        // assign top bidder and bid time
        Bid memory newHighestBid;
        newHighestBid.bidder = _msgSender();
        newHighestBid.bidAmount = bidAmount;
        newHighestBid.actualBidAmount = actualBidAmount;
        newHighestBid.bidTime = _getNow();
        bidList.push(newHighestBid);

        IERC20(auctions[_tokenContractAddress][_tokenId].fundTokenAddress).transferFrom(_msgSender(), address(this), actualBidAmount);

        availableFunds[_tokenContractAddress][_tokenId] += actualBidAmount;

        if (bidList.length > 1) {
            IERC20(auctions[_tokenContractAddress][_tokenId].fundTokenAddress).transfer(bidList[bidList.length - 2].bidder, 
                bidList[bidList.length - 2].actualBidAmount + benefit);
            availableFunds[_tokenContractAddress][_tokenId] -= (bidList[bidList.length - 2].actualBidAmount + benefit);
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

