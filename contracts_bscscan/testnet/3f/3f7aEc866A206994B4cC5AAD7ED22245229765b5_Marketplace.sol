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

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./MarketplaceStorage.sol";

contract Marketplace is Ownable, Pausable, MarketplaceStorage, IERC721Receiver {
  using SafeMath for uint256;
  using Address for address;

  /**
    * @dev Initialize this contract. Acts as a constructor
    * @param _acceptedToken - Address of the ERC20 accepted for this marketplace
    * @param _ownerCutPerMillion - owner cut per million, the fee for listing an asset
    */
  constructor (
    address _acceptedToken,
    uint256 _ownerCutPerMillion
  ) {
    // Fee init
    setOwnerCutPerMillion(_ownerCutPerMillion);

    require(_acceptedToken.isContract(), "The accepted token address must be a deployed contract");
    acceptedToken = IERC20(_acceptedToken);
  }

  /**
    * @dev Sets the publication fee that's charged to users to publish items
    * @param _publicationFee - Fee amount in wei this contract charges to publish an item
    */
  function setPublicationFeeInEther(uint256 _publicationFee) external onlyOwner {
    publicationFeeInEtherWei = _publicationFee;
    emit ChangedPublicationFeeInEther(publicationFeeInEtherWei);
  }

  /**
    * @dev Sets the publication fee that's charged to users to publish items
    * @param _publicationFee - Fee amount in wei this contract charges to publish an item
    */
  function setPublicationFeeInToken(uint256 _publicationFee) external onlyOwner {
    publicationFeeInTokenWei = _publicationFee;
    emit ChangedPublicationFeeInToken(publicationFeeInTokenWei);
  }

  /**
    * @dev Sets the share cut for the owner of the contract that's
    *  charged to the seller on a successful sale
    * @param _ownerCutPerMillion - Share amount, from 0 to 999,999
    */
  function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) public onlyOwner {
    require(_ownerCutPerMillion < 1000000, "The owner cut should be between 0 and 999,999");

    ownerCutPerMillion = _ownerCutPerMillion;
    emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
  }

  /// @dev Returns auction info for an NFT on auction.
  /// @param _nftAddress - Address of the NFT.
  /// @param _assetId - ID of NFT on auction.
  function getOrder(
    address _nftAddress,
    uint256 _assetId
  )
    external
    view
    returns (
      bytes32 id,
      address seller,
      bool isPriceInEther,
      uint256 startingPrice,
      uint256 endingPrice,
      uint64 duration,
      uint256 startedAt
    )
  {
    Order memory _order = orderByAssetId[_nftAddress][_assetId];

    require(_isOnOrder(_order), "Asset not published");

    return (
      _order.id,
      _order.seller,
      _order.isPriceInEther,
      _order.startingPrice,
      _order.endingPrice,
      _order.duration,
      _order.startedAt
    );
  }

  function getCurrentPrice(
    address _nftAddress,
    uint256 _assetId
  )
    external view
    returns(uint256)
  {
    Order memory _order = orderByAssetId[_nftAddress][_assetId];
    
    require(_isOnOrder(_order), "Asset not published");
    return _getCurrentPrice(_order);
  }

  function _getCurrentPrice(
    Order memory _order
  )
    internal
    view
    returns (uint256)
  {
    if(_order.startingPrice == _order.endingPrice)
    {
      return _order.startingPrice;
    } 
    else {
      uint256 _secondsPassed = 0;

      // A bit of insurance against negative values (or wraparound).
      // Probably not necessary (since Ethereum guarantees that the
      // now variable doesn't ever go backwards).
      if (block.timestamp > _order.startedAt) {
        _secondsPassed = block.timestamp - _order.startedAt;
      }

      return _computeCurrentPrice(
        _order.startingPrice,
        _order.endingPrice,
        _order.duration,
        _secondsPassed
      );
    }       
  }

  /// @dev Computes the current price of an auction. Factored out
  function _computeCurrentPrice(
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    uint256 _secondsPassed
  )
    internal
    pure
    returns (uint256)
  {
    // NOTE: We don't use SafeMath (or similar) in this function because
    //  all of our external functions carefully cap the maximum values for
    //  time (at 64-bits) and currency (at 128-bits). _duration is
    //  also known to be non-zero (see the require() statement in
    //  _addAuction())
    if (_secondsPassed >= _duration) {
      // We've reached the end of the dynamic pricing portion
      // of the auction, just return the end price.
      return _endingPrice;
    } else {
      // Starting price can be higher than ending price (and often is!), so
      // this delta can be negative.
      int256 _totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

      // This multiplication can't overflow, _secondsPassed will easily fit within
      // 64-bits, and _totalPriceChange will easily fit within 128-bits, their product
      // will always fit within 256-bits.
      int256 _currentPriceChange = _totalPriceChange * int256(_secondsPassed) / int256(_duration);

      // _currentPriceChange can be negative, but if so, will have a magnitude
      // less that _startingPrice. Thus, this result will always end up positive.
      int256 _currentPrice = int256(_startingPrice) + _currentPriceChange;

      return uint256(_currentPrice);
    }
  }

  /// @dev Returns true if the NFT is on auction.
  /// @param _order - Order to check.
  function _isOnOrder(Order memory _order) internal pure returns (bool) {
    return (_order.id != 0 && _order.startedAt > 0);
  }

  /// @dev Creates a new order
  /// @param _nftAddress - address of a deployed contract implementing
  ///  the Nonfungible Interface.
  /// @param _assetId - ID of token to auction, sender must be owner.
  /// @param _startingPrice - Price of item (in wei) at beginning of auction.
  /// @param _endingPrice - Price of item (in wei) at end of auction.
  /// @param _duration - Length of time to move between starting
  ///  price and ending price (in seconds).
  function createOrderInToken(
    address _nftAddress,
    uint256 _assetId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint64 _duration
  )
    public whenNotPaused
  {    
    // Check NFT Address
    // _requireERC721(_nftAddress); // _requireERC1155(nftAddress);

    address _seller = _msgSender();

    IERC721 _nftContract = IERC721(_nftAddress);

    require(_nftContract.ownerOf(_assetId) == _seller, "Only the owner can create orders");

    // NOTE: transfer to this contract
    _nftContract.safeTransferFrom(_seller, address(this), _assetId);

    require(_startingPrice > 0, "Starting price should be bigger than 0");
    require(_endingPrice > 0, "Ending price should be bigger than 0");
    // Require that all auctions have a duration of
    // at least one minute. (Keeps our math from getting hairy!)
    require(_duration >= 1 minutes, 'Publication should be more than 1 minute in the future');

    bytes32 _orderId = keccak256(
      abi.encodePacked(
        block.timestamp,
        _seller,
        _nftAddress,
        _assetId,        
        _startingPrice,
        _endingPrice,
        _duration
      )
    );

    Order memory _order = Order({
      id: _orderId,
      seller: _seller,
      nftAddress: _nftAddress,
      isPriceInEther: false,
      startingPrice: _startingPrice,
      endingPrice: _endingPrice,
      duration: _duration,
      startedAt: block.timestamp
    });

    orderByAssetId[_nftAddress][_assetId] = _order;

    // Check if there's a publication fee and
    // transfer the amount to marketplace owner
    if (publicationFeeInTokenWei > 0) {
      require(
        acceptedToken.transferFrom(_seller, owner(), publicationFeeInTokenWei),
        "Transfering the publication fee to the Marketplace owner failed"
      );
    }

    emit OrderCreated(
      _orderId,
      _seller,
      _nftAddress,
      _assetId,
      _order.isPriceInEther,
      _startingPrice,
      _endingPrice,
      _duration,
      _order.startedAt
    );
  }

  function createOrderInEther(
    address _nftAddress,
    uint256 _assetId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint64 _duration
  )
    public payable whenNotPaused
  {    
    // Check NFT Address
    _requireERC721(_nftAddress); // _requireERC1155(nftAddress);

    address _seller = _msgSender();

    IERC721 _nftContract = IERC721(_nftAddress);

    require(_nftContract.ownerOf(_assetId) == _seller, "Only the owner can create orders");

    // NOTE: transfer to this contract
    _nftContract.safeTransferFrom(_seller, address(this), _assetId);

    require(_startingPrice > 0, "Starting price should be bigger than 0");
    require(_endingPrice > 0, "Ending price should be bigger than 0");
    // Require that all auctions have a duration of
    // at least one minute. (Keeps our math from getting hairy!)
    require(_duration >= 1 minutes);

    // Check if there's a publication fee and
    // transfer the amount to marketplace owner
    if (publicationFeeInEtherWei > 0) {
      require(msg.value == publicationFeeInEtherWei, "Should be equals publication fee");
    }

    bytes32 _orderId = keccak256(
      abi.encodePacked(
        block.timestamp,
        _seller,
        _nftAddress,
        _assetId,        
        _startingPrice,
        _endingPrice,
        _duration
      )
    );

    Order memory _order = Order({
      id: _orderId,
      seller: _seller,
      nftAddress: _nftAddress,
      isPriceInEther: true,
      startingPrice: _startingPrice,
      endingPrice: _endingPrice,
      duration: _duration,
      startedAt: block.timestamp
    });

    orderByAssetId[_nftAddress][_assetId] = _order;    

    emit OrderCreated(
      _orderId,
      _seller,
      _nftAddress,
      _assetId,
      _order.isPriceInEther,
      _startingPrice,
      _endingPrice,
      _duration,
      _order.startedAt
    );
  }

  function cancelOrder(address _nftAddress, uint256 _assetId) public whenNotPaused {
    address _sender = _msgSender();

    Order memory _order = orderByAssetId[_nftAddress][_assetId];

    require(_isOnOrder(_order), "Asset not published");
    require(_order.seller == _sender || _sender == owner(), "Unauthorized user");

    bytes32 orderId = _order.id;

    // NOTE: Transfer the order to the seller
    delete orderByAssetId[_nftAddress][_assetId];
    IERC721 _nftContract = IERC721(_nftAddress);
    _nftContract.safeTransferFrom(address(this), _order.seller, _assetId);

    emit OrderCancelled(orderId);
  }

  function cancelOrderWhenPaused(
    address _nftAddress,
    uint256 _assetId
  )
    external
    whenPaused
    onlyOwner
  {
    Order memory _order = orderByAssetId[_nftAddress][_assetId];
    require(_isOnOrder(_order), "Asset not published");

    bytes32 orderId = _order.id;

    delete orderByAssetId[_nftAddress][_assetId];
    IERC721 _nftContract = IERC721(_nftAddress);
    _nftContract.safeTransferFrom(address(this), _order.seller, _assetId);

    emit OrderCancelled(orderId);
  }

 /**
    * @dev Executes the sale for a published NFT and checks for the asset fingerprint
    */
  function executeOrderInToken(
    address _nftAddress,
    uint256 _assetId,
    uint256 _bidAmount
  )
    public whenNotPaused
  {
    Order memory _order = orderByAssetId[_nftAddress][_assetId];    
    require(_isOnOrder(_order), "Asset not published");
    require(!_order.isPriceInEther, "Order price in Ether");

    _executeOrder(
      _nftAddress,
      _assetId,
      _order,
      _bidAmount
    );

  }

  /**
    * @dev Executes the sale for a published NFT
    */
  function executeOrderInEther(
    address _nftAddress,
    uint256 _assetId
  )
    public payable whenNotPaused
  {
    Order memory _order = orderByAssetId[_nftAddress][_assetId];    
    require(_isOnOrder(_order), "Asset not published");
    require(_order.isPriceInEther, "Order price in token");

    _executeOrder(
      _nftAddress,
      _assetId,
      _order,
      msg.value
    );
  }

  /**
    * @dev Creates a new order
    * @param nftAddress - Non fungible registry address
    * @param assetId - ID of the published NFT
    * @param priceInWei - Price in Wei for the supported coin
    * @param expiresAt - Duration of the order (in hours)
    */

  /**
    * @dev Executes the sale for a published NFT
    */
  function _executeOrder(
    address _nftAddress,
    uint256 _assetId,
    Order memory _order,
    uint256 _bidAmount
  )
    internal returns (Order memory)
  {
    address _buyer = _msgSender();
    // ERC721, ERC1155
    IERC721 nftContract = IERC721(_nftAddress);

    // Grab a reference to the seller before the auction struct
    // gets deleted.
    address _seller = _order.seller;

    require(_seller != address(0), "Invalid address");
    require(_seller != _buyer, "Unauthorized user");

    // NOTE:     
    uint256 _price = _getCurrentPrice(_order);

    // // Check that the incoming bid is higher than the current price
    require(_bidAmount >= _price);
    // require(order.price == _price, "The price is not correct");
    // require(block.timestamp < order.expiresAt, "The order expired");

    // The bid is good! Remove the auction before sending the fees
    // to the sender so we can't have a reentrancy attack.
    bytes32 orderId = _order.id;
    bool isPriceInEther = _order.isPriceInEther;
    delete orderByAssetId[_nftAddress][_assetId];

    if(isPriceInEther) {
      _transferEther(_buyer, _seller, _bidAmount, _price);
    }
    else {
      _transferToken(_buyer, _seller, _bidAmount);
    }    

    // Transfer asset owner
    // NOTE: ERC721 or ERC1155
    nftContract.safeTransferFrom(
      address(this),
      _buyer,
      _assetId
    );

    emit OrderSuccessful(
      orderId,
      _buyer,
      _price
    );

    return _order;
  }

  function _transferToken(
    address buyer,
    address seller,
    uint256 _bidAmount
  ) internal {
    uint256 _ownerCut = _bidAmount.mul(ownerCutPerMillion).div(1000000);
    uint256 _sellerProceeds = _bidAmount - _ownerCut;

    require(
      acceptedToken.transferFrom(buyer, owner(), _ownerCut),
      "Transfering the cut to the Marketplace owner failed"
    );

    require(
      acceptedToken.transferFrom(buyer, seller, _bidAmount.sub(_sellerProceeds)),
      "Transfering the sale amount to the seller failed"
    );
  }

  function _transferEther(
    address buyer,
    address seller,
    uint256 _bidAmount,
    uint256 _price 
  ) internal {
    if (_price > 0) {
      uint256 _ownerCut = _price.mul(ownerCutPerMillion).div(1000000);
      uint256 _sellerProceeds = _price - _ownerCut;

      // NOTE ?
      payable(seller).transfer(_sellerProceeds);
    }

    if (_bidAmount > _price) {
      uint256 _bidExcess = _bidAmount - _price;

      payable(buyer).transfer(_bidExcess);
    }
  }

  function _requireERC721(address nftAddress) internal view {
    require(nftAddress.isContract(), "The NFT Address should be a contract");

    IERC721 nftRegistry = IERC721(nftAddress);
    require(
      nftRegistry.supportsInterface(ERC721_Interface),
      "The NFT contract has an invalid ERC721 implementation"
    );
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MarketplaceStorage {
  bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);
  
  struct Order {
    // Order ID
    bytes32 id;
    // Owner of the NFT
    address seller;
    // NFT registry address: ERC721, ERC1155
    address nftAddress;
    // price in ether or token
    bool isPriceInEther;
    // Price (in wei) at beginning of order/auction
    uint256 startingPrice;
    // Price (in wei) at end of order/auction
    uint256 endingPrice;
    // Time when order started
    // NOTE: 0 if this auction has been concluded
    uint256 startedAt;
    // Duration (in seconds) of auction
    uint64 duration;    
  }

  IERC20 public acceptedToken;

  // Cut owner takes on each order, measured in basis points
  // Values 0-1,000,000 map to 0%-100%
  uint256 public ownerCutPerMillion;

  uint256 public publicationFeeInEtherWei;
  uint256 public publicationFeeInTokenWei;

  // From ERC721/ERC1155 registry assetId to Order (to avoid asset collision)
  mapping (address => mapping(uint256 => Order)) public orderByAssetId;

  // EVENTS
  event OrderCreated(
    bytes32 id,
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed assetId,
    bool isPriceInEther,
    uint256 startingPrice,
    uint256 endingPrice,
    uint64 duration,
    uint256 startedAt
  );

  event OrderSuccessful(
    bytes32 id,
    address indexed buyer,
    uint256 finalPrice
  );

  event OrderCancelled(
    bytes32 id
  );

  event ChangedPublicationFeeInEther(uint256 publicationFee);
  event ChangedPublicationFeeInToken(uint256 publicationFee);
  event ChangedOwnerCutPerMillion(uint256 ownerCutPerMillion);
}

