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

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.8;


/**
 * @dev Required interface of an Auction compliant contract.
 */
interface ILevel0Auction {
    // admin functions
    function setDaoTreasury(address daoTreasuryAddress) external;
    function setAuctionCurve(address auctionCurveAddress) external;
    function setPurchaseToken(address purchaseTokenAddress) external;
    function setMaxAuctionsPerEpoch(uint256 limit) external;
    function setAlbum(address playlistPoolAddress) external;
    function escapeHatchERC20(address tokenAddress) external;
    // end-user functions
    function level0sPerAuction(uint256 auctionId) external view returns (uint256);
    function currentPrice(uint256 auctionId) external view returns (uint256);
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.8;


interface IERC721MintableBurnable {
    function setBaseURI(string memory baseURI_) external;
    function mint(address to) external returns (uint256 newTokenId);
    function batchMint(address[] calldata to) external;
    function batchBurnFrom(uint256[] calldata tokenIds) external;
    function transferOwnership(address newOwner) external;
    function getNextTokenId() external view returns (uint256);
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.8;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../heartbeat/Pacemaker.sol";
import "../level-token/IERC721MintableBurnable.sol";
import "./IEscapeHatchERC20.sol";
import "./LevelWrapper.sol";


/** @title Album
    @author Lendroid Foundation
        LICENSE : https://github.com/lendroidproject/protocol.2.0/blob/master/LICENSE.md
    @notice Inherits the LevelWrapper contract, performs additional functions
        on the stake and unstake functions, and includes logic to calculate and
        withdraw levelRewards.
        This contract is inherited by all MultiNFT Album contracts.
    @dev Audit certificate : None
*/

// solhint-disable-next-line
abstract contract Album is IEscapeHatchERC20, LevelWrapper, Pacemaker {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    string public albumName;
    IERC20 public rewardToken;

    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public cachedRewardPerStake;
    // accountLevelXHash => userRewardPerStakePaid for the NFT address
    mapping(bytes32 => uint256) public userRewardPerStakePaid;
    // accountLevelXHash => last epoch staked for the NFT address
    mapping(bytes32 => uint256) public lastEpochStaked;
    // accountLevelXHash => levelRewards per commitment
    mapping(bytes32 => uint256) public levelRewards;
    // _accountSongTokenHash => levelRewards for the NFT address
    mapping(bytes32 => uint256) public songRewards;

    uint256 public startEpoch;

    event Staked(address indexed user, address indexed tokenAddress, uint256 tokenIdCount);
    event Unstaked(address indexed user, address indexed tokenAddress, uint256 tokenIdCount);
    event Committed(address indexed user, address indexed token1Address, address indexed token2Address);
    event LevelRewardClaimed(address indexed user, address indexed levelXAddress, uint256 reward);
    event SongRewardClaimed(address indexed user, address indexed songAddress, uint256 reward);

    /**
        @notice Registers the album name, Reward Token address, and Level0 Token address.
        @param name : Name of the Album
        @param rewardTokenAddress : address of the Reward Token
        @param level0Address : address of Level0 Token
    */
    // solhint-disable-next-line func-visibility
    constructor(uint256 startEpochNumber, string memory name, address rewardTokenAddress,
        address level0Address, address level0AuctionAddress, uint256 maxLevel)
    LevelWrapper(level0Address, level0AuctionAddress, maxLevel) {//solhint-disable-line func-visibility
        require(startEpochNumber > 0, "{Playlist} : startEpoch cannot be > 100");
        require(rewardTokenAddress.isContract(), "{Playlist} : invalid rewardTokenAddress");
        startEpoch = startEpochNumber;
        rewardToken = IERC20(rewardTokenAddress);
        // It's OK for the album name to be empty.
        albumName = name;
    }

    /**
        @notice modifier to check if the startEpoch has been reached
        @dev Pacemaker.currentEpoch() returns values > 0 only from
            HEART_BEAT_START_TIME+1. Therefore, staking is possible only from startEpoch
    */
    modifier checkStart() {
        // solhint-disable-next-line not-rely-on-time
        require(currentEpoch() >= startEpoch, "{checkStart} : startEpoch has not been reached");
        _;
    }

    /**
        @notice modifier to update system and user info whenever a user makes a
            function call to stake or unstake.
        @dev Updates rewardPerStake and time when system is updated
            Recalculates user levelRewards
    */
    modifier updateLevelRewards(address account, address levelXAddress) {
        _updateLevelXRewards(account, levelXAddress);
        _;
    }

    /**
        @notice modifier to update system and user info whenever a user makes a function call to songClaim.
        @dev Updates rewardPerStake and time when system is updated. Recalculates user songRewards
    */
    modifier updateSongRewards(address account, address songAddress) {
        uint256 rewards = 0;
        address levelXAddress = address(0);
        for (uint256 i=0; i < songLevels[ISong(songAddress)].length; i++) {
            levelXAddress = address(songLevels[ISong(songAddress)][i]);
            _updateLevelXRewards(account, levelXAddress);
            rewards = rewards.add(levelRewards[accountLevelXHash(account, levelXAddress)]);
        }
        songRewards[_accountSongTokenHash(account, songAddress)] = rewards;
        _;
    }

    /**
    * @notice Safety function to handle accidental / excess token transfer to the contract
    */
    function escapeHatchERC20(address tokenAddress) external override onlyOwner {
        require(tokenAddress != address(0), "{escapeHatchERC20} : invalid tokenAddress");
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    function transferERC721Ownership(address tokenAddress, address newOwner) external onlyOwner whenPaused {
        require(tokenAddress.isContract(), "{transferERC721Ownership} : invalid tokenAddress");
        require(newOwner != address(0), "{transferERC721Ownership} : invalid newOwner");
        // transfer ownership of ERC721 token to newOwner
        IERC721MintableBurnable(tokenAddress).transferOwnership(newOwner);
    }

    function secureStakeLevel0s(address staker, uint256[] calldata tokenIds) external {
        require(msg.sender == address(level0Auction), "{secureStakeLevel0s} : invalid sender");
        lastEpochStaked[accountLevelXHash(staker, address(level0))] = currentEpoch();
        _updateLevelXRewards(staker, address(level0));
        _secureStakeLevel0s(staker, tokenIds);

        emit Staked(msg.sender, address(level0), tokenIds.length);
    }

    /**
        @notice Transfers earnings from previous epochs per level to the caller
    */
    function level0Claim() external checkStart {
        _updateLevelXRewards(msg.sender, address(level0));
        bytes32 accountLpTokenHash = accountLevelXHash(msg.sender, address(level0));
        require(levelRewards[accountLpTokenHash] > 0, "{level0Claim} : no levelRewards to claim");
        uint256 rewardsEarned = levelRewards[accountLpTokenHash];
        levelRewards[accountLpTokenHash] = 0;

        rewardToken.safeTransfer(msg.sender, rewardsEarned);

        emit LevelRewardClaimed(msg.sender, address(level0), rewardsEarned);
    }

    /**
        @notice Displays reward tokens per LevelX Token staked. Useful to display APY on the frontend
    */
    function rewardPerStake(address levelXAddress) public view returns (uint256) {
        if (totalSupply(levelXAddress) == 0) {
            return cachedRewardPerStake[levelXAddress];
        }
        if (levelXAddress == address(level0)) {
            // solhint-disable-next-line not-rely-on-time
            return cachedRewardPerStake[levelXAddress].add(block.timestamp.sub(
                lastUpdateTime[levelXAddress]).mul(
                    rewardRate(currentEpoch())).mul(1e18).div(totalSupply(levelXAddress))
                );
        } else {
            // solhint-disable-next-line not-rely-on-time
            return cachedRewardPerStake[levelXAddress].add(block.timestamp.sub(
                lastUpdateTime[levelXAddress]).mul(
                    rewardRate2(currentEpoch())).mul(1e18).div(totalSupply(levelXAddress))
                );
        }
    }

    /**
        @notice Displays earnings per level of an address so far. Useful to display
            claimable levelRewards per level on the frontend
        @param account : the given user address
        @return earnings of given address
    */
    function earnedPerLevel(address account, address levelXAddress) public view returns (uint256) {
        return balanceOf(account, levelXAddress).mul(rewardPerStake(levelXAddress).sub(
            userRewardPerStakePaid[accountLevelXHash(account, levelXAddress)])).div(1e18).add(
                levelRewards[accountLevelXHash(account, levelXAddress)]);
    }

    /**
        @notice Displays earnings per level of an address so far. Useful to display
            claimable rewards per song on the frontend
        @param account : the given user address
        @return rewards : earnings of given address per song
    */
    function earnedPerSong(address account, address songAddress) public view returns (uint256 rewards) {
        for (uint256 i=0; i < songLevels[ISong(songAddress)].length; i++) {
            rewards = rewards.add(earnedPerLevel(account, address(songLevels[ISong(songAddress)][i])));
        }
    }

    /**
        @notice Displays reward tokens per second for a given epoch for the base NFTs. This
        function is implemented in contracts that inherit this contract.
    */
    function rewardRate(uint256 epoch) public pure virtual returns (uint256);

    /**
        @notice Displays reward tokens per second for a given epoch for higher order NFTs. This
        function is implemented in contracts that inherit this contract.
    */
    function rewardRate2(uint256 epoch) public pure virtual returns (uint256);

    /**
        @notice Displays required amounts of LevelX Tokens and levelUpTokenAmount to commit to the next level. This
            function is implemented in contracts that inherit this contract.
    */
    function levelUpRequirements(uint256 levelXNumber) public pure virtual returns (uint256 xCount, uint256 tokenCount);

    /**
        @notice Stake / Deposit LevelX Token into the Album.
        @dev Increases count of total LevelX Tokens staked in the current epoch.
             Increases count of LevelX Tokens staked for the caller in the current epoch.
             Register that caller last staked a LevelX Token in the current epoch.
             Perform actions from LevelWrapper.stake().
        @param levelXAddress : LevelX Token to stake
        @param levelXIds : array of LevelX Token IDs to stake
    */
    function stake(address songAddress, address levelXAddress, uint256[] calldata levelXIds) public
        checkStart whenNotPaused updateLevelRewards(msg.sender, levelXAddress) override {
        lastEpochStaked[accountLevelXHash(msg.sender, levelXAddress)] = currentEpoch();
        super.stake(songAddress, levelXAddress, levelXIds);

        emit Staked(msg.sender, levelXAddress, levelXIds.length);
    }

    /**
        @notice Unstake / Withdraw staked LevelX Tokens from the Pool
        @inheritdoc LevelWrapper
    */
    function unstake(address songAddress, address levelXAddress, uint256[] calldata levelXIds) public
        checkStart updateLevelRewards(msg.sender, levelXAddress) override {
        require(lastEpochStaked[accountLevelXHash(msg.sender, levelXAddress)] < currentEpoch(),
        "{unstake} : cannot unstake in staked epoch");
        super.unstake(songAddress, levelXAddress, levelXIds);

        emit Unstaked(msg.sender, levelXAddress, levelXIds.length);
    }

    /**
        @notice Transfers earnings from previous epochs per song to the caller
    */
    function songClaim(address songAddress) public checkStart updateSongRewards(msg.sender, songAddress) {
        bytes32 accountSongHash = _accountSongTokenHash(msg.sender, songAddress);
        require(songRewards[accountSongHash] > 0, "{songClaim} : no songRewards to claim");
        uint256 rewardsEarned = songRewards[accountSongHash];
        songRewards[accountSongHash] = 0;

        for (uint256 i=0; i < songLevels[ISong(songAddress)].length; i++) {
            levelRewards[accountLevelXHash(msg.sender, address(songLevels[ISong(songAddress)][i]))] = 0;
        }

        rewardToken.safeTransfer(msg.sender, rewardsEarned);

        emit SongRewardClaimed(msg.sender, songAddress, rewardsEarned);
    }

    /**
        @notice Combine one or more LevelX Tokens of one type into another
        @dev : Decreases count of total LevelX1 Tokens staked.
               Decreases count of LevelX1 Tokens staked for the msg.sender.
               Increases count of total LevelX2 Tokens staked.
               Increases count of LevelX2 Tokens staked for the msg.sender.
               LevelX1 Tokena are burned, LevelX2 Token is minted to the Pool.
        @param songAddress : address of NFT song
        @param levelX1Number : level from which to level up
        @param levelX1Ids : array of staked LevelX1 Token IDs
    */
    function levelUp(address songAddress, uint256 levelX1Number, uint256[] calldata levelX1Ids)
    public virtual whenNotPaused {
        // validate inputs
        require(levelX1Number < maxLevelLimit.sub(1), "{levelUp} : invalid levelX1Number");
        (uint256 xCount, uint256 erc20TokenAmount) = levelUpRequirements(levelX1Number);
        require(levelX1Ids.length >= xCount, "{levelUp} : insufficient number of LevelX1 Tokens");
        uint256 mintableX2Count = levelX1Ids.length.div(xCount);
        uint256[] memory burnableLevelX1Ids = new uint256[](xCount.mul(mintableX2Count));
        // get LevelX1 Token address
        address levelX1Address = levelX1Number == 0 ? address(level0) :
            address(songLevels[ISong(songAddress)][levelX1Number.sub(1)]);
        for (uint256 i=0; i < levelX1Ids.length; i++) {
            require(IERC721(levelX1Address).ownerOf(levelX1Ids[i]) == address(this),
                "{combine} : staked tokenId not found");
        }
        // get LevelX2 Token address
        address levelX2Address = address(songLevels[ISong(songAddress)][levelX1Number]);
        // update LevelX1 and LevelX2 rewards
        _updateLevelXRewards(msg.sender, levelX1Address);
        _updateLevelXRewards(msg.sender, levelX2Address);
        for (uint256 i=0; i < mintableX2Count; i++) {
            // mint higher level token
            uint256 newTokenId = IERC721MintableBurnable(levelX2Address).mint(address(this));
            // stake higher level token on behalf of sender
            _stake(msg.sender, levelX2Address, newTokenId);
        }

        emit Staked(msg.sender, levelX2Address, mintableX2Count);

        for (uint256 i=0; i < burnableLevelX1Ids.length; i++) {
            // unstake lower level tokens
            _unstake(msg.sender, levelX1Address, levelX1Ids[i]);
            burnableLevelX1Ids[i] = levelX1Ids[i];
        }

        emit Unstaked(msg.sender, levelX1Address, burnableLevelX1Ids.length);

        // batchBurn unstaked level token1s
        IERC721MintableBurnable(levelX1Address).batchBurnFrom(burnableLevelX1Ids);
        // transfer erc20TokenAmount to contract
        rewardToken.safeTransferFrom(msg.sender, address(this), erc20TokenAmount);

        emit Committed(msg.sender, levelX1Address, levelX2Address);
    }

    function _updateLevelXRewards(address account, address levelXAddress) internal {
        cachedRewardPerStake[levelXAddress] = rewardPerStake(levelXAddress);
        lastUpdateTime[levelXAddress] = block.timestamp;// solhint-disable-line not-rely-on-time
        levelRewards[accountLevelXHash(account, levelXAddress)] = earnedPerLevel(account, levelXAddress);
        userRewardPerStakePaid[accountLevelXHash(account, levelXAddress)] =
            cachedRewardPerStake[levelXAddress];
    }

}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.8;


interface IEscapeHatchERC20 {
    function escapeHatchERC20(address tokenAddress) external;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.8;


interface IEscapeHatchERC721 {
    function escapeHatchERC721(address tokenAddress, uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../song-token/ISong.sol";
import "../level-0-token-auction/ILevel0Auction.sol";

import "./IEscapeHatchERC721.sol";


/** @title LevelWrapper
    @author Lendroid Foundation
            LICENSE : https://github.com/lendroidproject/protocol.2.0/blob/master/LICENSE.md
    @notice Tracks the state of the LP NFTs staked / unstaked both in total
        and on a per account basis.
    @dev Audit certificate : None
*/


// solhint-disable-next-line
abstract contract LevelWrapper is ERC721Holder, IEscapeHatchERC721, Ownable, Pausable {
    using SafeMath for uint256;
    using Address for address;

    struct AccountLevel {
        uint256 balance;
        uint256[] stakedIds;
    }

    // Level0 tokens across the entire playlist
    IERC721 public level0;
    // Level0 token auction contract
    ILevel0Auction public level0Auction;
    // Song Tokens
    ISong[] public songs;
    // Higher Level tokens per song
    mapping (ISong => IERC721[]) public songLevels;
    // Maximum attainable level per song
    uint256 public maxLevelLimit;
    // NFT address => count of tokenIds
    mapping(address => uint256) private _totalSupply;
    // _accountlevelXHash => AccountLevel struct
    mapping(bytes32 => AccountLevel) public accountLevelXs;
    // accountLevelXHash => array of token Ids for the NFT address
    mapping(bytes32 => uint256) private _stakedLevelXIdMapper;
    // _levelXIdHash => staker address
    mapping(bytes32 => address) private _stakedBy;

    // return value for safeTransferFrom function calls of older ERC721 versions
    bytes4 public constant ERC721_RECEIVED_OLD = 0xf0b9e5ba;

    /**
        @notice Registers the Level0 Token address
        @param level0TokenAddress : address of Level0 Token
    */
    // solhint-disable-next-line func-visibility
    constructor(address level0TokenAddress, address level0TokenAuctionAddress, uint256 maxLevelAttainable) {
        require(level0TokenAddress.isContract(), "{LevelWrapper} : invalid level0TokenAddress");
        require(level0TokenAuctionAddress.isContract(), "{LevelWrapper} : invalid level0TokenAuctionAddress");
        require(maxLevelAttainable > 0, "{LevelWrapper} : max level can not be zero");
        level0 = IERC721(level0TokenAddress);
        level0Auction = ILevel0Auction(level0TokenAuctionAddress);
        maxLevelLimit = maxLevelAttainable;
    }

    /**
        @notice Registers the LP Token addresses
        @param tokenAddresses : [songAddress, Higher Level addresses (Au, Pt, Pd, Jx)]
    */
    // solhint-disable-next-line func-visibility
    function addSong(address[] memory tokenAddresses) external onlyOwner {
        // validate inputs
        require(tokenAddresses.length == maxLevelLimit,
            "{addSong} : tokenAddresses array length should equal maxLevelLimit");
        require(tokenAddresses[0].isContract(), "{addSong} : invalid levelXAddress");
        for (uint256 i=1; i < tokenAddresses.length; i++) {
            require(tokenAddresses[i].isContract(), "{addSong} : invalid levelXAddress");
        }
        // add song
        ISong song = ISong(tokenAddresses[0]);
        songs.push(song);
        // populate level tokens for song
        for (uint256 i=1; i < tokenAddresses.length; i++) {
            songLevels[song].push(IERC721(tokenAddresses[i]));
        }
    }

    // admin functions in case something goes wrong
    function escapeHatchERC721(address tokenAddress, uint256[] calldata tokenIds) external override onlyOwner {
        require(tokenAddress.isContract(), "{escapeHatchERC721} : invalid tokenAddress");
        for (uint256 i=0; i < tokenIds.length; i++) {
            IERC721(tokenAddress).safeTransferFrom(address(this), owner(), tokenIds[i]);
        }
    }

    function togglePause(bool pause) external onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function nextSongId() external view returns (uint256) {
        return songs.length;
    }

    /**
        @notice Displays the total LP Token staked
        @param levelXAddress : LP Tokens
        @return uint256 : value of the _totalSupply which stores total LP NFTs staked
    */
    function totalSupply(address levelXAddress) public view returns (uint256) {
        return _totalSupply[levelXAddress];
    }

    /**
        @notice Displays LP Token staked per account
        @param account : address of a user account
        @param levelXAddress : LP Token
        @return uint256 : total LP Token staked by given account address
    */
    function balanceOf(address account, address levelXAddress) public view returns (uint256) {
        return accountLevelXs[accountLevelXHash(account, levelXAddress)].balance;
    }

    /**
        @notice Displays LP Token staked per account
        @param account : address of a user account
        @param levelXAddress : LP Token
        @return uint256[] : LP Token IDs staked by given account address
    */
    function stakedIdsOf(address account, address levelXAddress) public view returns (uint256[] memory) {
        return accountLevelXs[accountLevelXHash(account, levelXAddress)].stakedIds;
    }

    /**
        @notice Stake / Deposit LP Token into the Pool
        @dev : Increases count of total LP Token staked.
               Increases count of LP Token staked for the msg.sender.
               LP Token is transferred from msg.sender to the Pool.
        @param levelXAddress : LP Token to stake
        @param levelXIds : array of LP Token IDs to stake
    */
    function stake(address songAddress, address levelXAddress, uint256[] calldata levelXIds) public
    virtual {
        (uint256 isValid, uint256 tokenAddressIndex) = isValidLevelX(songAddress, levelXAddress);
        require(isValid | tokenAddressIndex > 0, "{stake} : invalid levelXAddress");
        for (uint256 i=0; i < levelXIds.length; i++) {
            require(IERC721(levelXAddress).ownerOf(levelXIds[i]) == msg.sender,
            "{stake} : sender is not levelX owner");
        }
        for (uint256 j=0; j < levelXIds.length; j++) {
            _stake(msg.sender, levelXAddress, levelXIds[j]);
            IERC721(levelXAddress).safeTransferFrom(msg.sender, address(this), levelXIds[j]);
        }
    }

    /**
        @notice Unstake / Withdraw staked LP Token from the Pool
        @dev : Decreases count of total LP Token staked
               Decreases count of LP Token staked for the msg.sender
               LP Token is transferred from the Pool to the msg.sender
               @param levelXAddress : LP Token to withdraw / unstake
               @param levelXIds : array of LP Token IDs to withdraw / unstake
    */
    function unstake(address songAddress, address levelXAddress, uint256[] calldata levelXIds) public
    virtual {
        (uint256 isValid, uint256 tokenAddressIndex) = isValidLevelX(songAddress, levelXAddress);
        require(isValid | tokenAddressIndex > 0, "{unstake} : invalid levelXAddress");
        for (uint256 i=0; i < levelXIds.length; i++) {
            _unstake(msg.sender, levelXAddress, levelXIds[i]);
            IERC721(levelXAddress).safeTransferFrom(address(this), msg.sender, levelXIds[i]);
        }
    }

    function onERC721Received(address, uint256, bytes memory) public pure returns (bytes4) {
        return ERC721_RECEIVED_OLD;
    }

    /**
        @notice computes the hash of the given account and Level NFT. This hash is used as a key to store values
        @param account : address of a user account
        @param levelXAddress : LP Token
        @return bytes32 : keccak256 hash of given account and levelXAddress
    */
    function accountLevelXHash(address account, address levelXAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, levelXAddress));
    }

    function _stake(address staker, address levelXAddress, uint256 levelXId) internal {
        // update stakedBy mapper
        _stakedBy[_levelXIdHash(levelXAddress, levelXId)] = staker;
        // update totalSupply
        _totalSupply[levelXAddress] = _totalSupply[levelXAddress].add(1);
        // retrieve from storage
        AccountLevel storage accountLevelX = accountLevelXs[accountLevelXHash(staker,
            levelXAddress)];
        // update tokenId mapper
        _stakedLevelXIdMapper[_accountLevelXIdHash(staker, levelXAddress, levelXId)] =
            accountLevelX.stakedIds.length;
        // update balance
        accountLevelX.balance = accountLevelX.balance.add(1);
        // update stakedIds
        accountLevelX.stakedIds.push(levelXId);
    }

    function _unstake(address staker, address levelXAddress, uint256 levelXId) internal {
        require(_stakedBy[_levelXIdHash(levelXAddress, levelXId)] == staker,
            "{unstake} : invalid staker");
        // update stakedBy mapper
        _stakedBy[_levelXIdHash(levelXAddress, levelXId)] = address(0);
        // update totalSupply
        _totalSupply[levelXAddress] = _totalSupply[levelXAddress].sub(1);
        // retrieve from storage
        AccountLevel storage accountLevelX = accountLevelXs[accountLevelXHash(staker,
            levelXAddress)];
        // update balance
        accountLevelX.balance = accountLevelX.balance.sub(1);
        // update stakedIds
        delete accountLevelX.stakedIds[_stakedLevelXIdMapper[_accountLevelXIdHash(staker,
            levelXAddress, levelXId)]];
    }

    function _secureStakeLevel0s(address staker, uint256[] calldata tokenIds) internal {
        // retrieve from storage
        AccountLevel storage accountLevelX = accountLevelXs[accountLevelXHash(staker,
            address(level0))];
        // update totalSupply
        _totalSupply[address(level0)] = _totalSupply[address(level0)].add(tokenIds.length);
        // update balance
        accountLevelX.balance = accountLevelX.balance.add(tokenIds.length);
        for (uint256 i=0; i < tokenIds.length; i++) {
            // update stakedBy mapper
            _stakedBy[_levelXIdHash(address(level0), tokenIds[i])] = staker;
            // update tokenId mapper
            _stakedLevelXIdMapper[_accountLevelXIdHash(staker, address(level0), tokenIds[i])] =
                accountLevelX.stakedIds.length;
            // update stakedIds
            accountLevelX.stakedIds.push(tokenIds[i]);
        }
    }

    /**
        @notice Check if a given LP Token is supported
        @param songAddress : Song Token address
        @param levelXAddress : LP Token address
    */
    function isValidLevelX(address songAddress, address levelXAddress) internal view
    returns (uint256, uint256) {
        if (levelXAddress == address(level0)) {
            return (1, 0);
        }
        for (uint256 i=0; i < songLevels[ISong(songAddress)].length; i++) {
            if (address(songLevels[ISong(songAddress)][i]) == levelXAddress) {
                return (1, i);
            }
        }
        return (0, 0);
    }

    /**
        @notice computes the hash of the given account and Song NFT. This hash is used as a key to store values
        @param account : address of a user account
        @param songAddress : Song NFT
        @return bytes32 : keccak256 hash of given account and songAddress
    */
    function _accountSongTokenHash(address account, address songAddress) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, songAddress));
    }

    /**
        @notice computes the hash of the given NFT contract and Token Id. This hash is used as a key to store values
        @param levelXAddress : NFT address
        @param levelXId : NFT Id
        @return bytes32 : keccak256 hash of given NFT address and NFT Id
    */
    function _levelXIdHash(address levelXAddress, uint256 levelXId) internal pure
    returns (bytes32) {
        return keccak256(abi.encodePacked(levelXAddress, levelXId));
    }

    /**
        @notice computes the hash of the given account, NFT contract, and Token Id.
            This hash is used as a key to store values
        @param account : address of a user account
        @param levelXAddress : NFT address
        @param levelXId : NFT Id
        @return bytes32 : keccak256 hash of given NFT address and NFT Id
    */
    function _accountLevelXIdHash(address account, address levelXAddress, uint256 levelXId)
    internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, levelXAddress, levelXId));
    }

}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.8;

import "../playlist/Album.sol";


/** @title JAXBlast2
    @author Lendroid Foundation
        LICENSE : https://github.com/lendroidproject/protocol.2.0/blob/master/LICENSE.md
    @notice Inherits the Album contract, and contains reward distribution
        logic for the JAX token.
*/
contract JAXBlast2 is Album {

    using SafeMath for uint256;

    /**
        @notice Registers the Pool name as “JAXBLAST2 - TAWANDA”,
                Silver, Gold, Platinum, Palladium, Jaxium Lives as the LP Tokens, and
                JAX as the Reward Token.
        @param rewardTokenAddress : JAX Token address
        @param level0TokenAddress : Ag Token addresses
    */
    constructor (address rewardTokenAddress, address level0TokenAddress, address level0TokenAuctionAddress)
    Album(1059, "Arturo Rhythm & Soul",// solhint-disable-line func-visibility
        rewardTokenAddress, level0TokenAddress, level0TokenAuctionAddress, 5) {}// solhint-disable-line no-empty-blocks

    /**
        @notice Displays total JAX rewards (for first order Level Tokens) distributed per second in a given epoch.
        @dev Series 1 :
                Epochs : 1059-1100
                Total JAX distributed : 50,000
                Distribution duration : 14 days
            Series 2 :
                Epochs : 1101-1142
                Total JAX distributed : 25,000
                Distribution duration : 14 days
            Series 3 :
                Epochs : 1143-1184
                Total JAX distributed : 15,000
                Distribution duration : 14 days
            Series 4 :
                Epochs : 1185-1226
                Total JAX distributed : 10,000
                Distribution duration : 14 days
            Total distribution duration : 2 months, aka, 8 weeks, aka 56 days
        @param epoch : 8-hour window number
        @return JAX Tokens distributed per second during the given epoch
    */
    function rewardRate(uint256 epoch) public pure override returns (uint256) {
        /* require(epoch >= 647, "epoch cannot be below 647"); */
        uint256 seriesRewards = 0;
        if (epoch >= 1059) {
            if (epoch <= 1100) {
                seriesRewards = 50000;// 50,000
            } else if (epoch >= 1101 && epoch <= 1142) {
                seriesRewards = 25000;// 25,000
            } else if (epoch >= 1143 && epoch <= 1184) {
                seriesRewards = 15000;// 15,000
            } else if (epoch >= 1185 && epoch <= 1226) {
                seriesRewards = 10000;// 10,000
            }
            if (seriesRewards > 0) {
                seriesRewards = seriesRewards.mul(1e18).div(14 days);
            }
        }

        return seriesRewards;
    }

    /**
        @notice Displays total JAX rewards (for higher order Level Tokens) distributed per second in a given epoch.
        @dev Series 1 :
                Epochs : 1059-1310
                Total JAX distributed : 50,000
                Total distribution duration : 3 months, aka, 12 weeks, aka 84 days
        @param epoch : 8-hour window number
        @return JAX Tokens distributed per second during the given epoch
    */
    function rewardRate2(uint256 epoch) public pure override returns (uint256) {
        require(epoch >= 1059, "epoch cannot be below 1059");
        if (epoch > 1310) {
            return 0;
        } else {
            uint256 seriesRewards = 50000;// 50,000
            return seriesRewards.mul(1e18).div(84 days);
        }
    }

    /**
        @notice Displays required amounts of LevelX1 Tokens and rewardAmount to levelUp from LevelX1 to LevelX2.
        @dev L0 to L1 :  1 Ag +    10 JAX -> 1 Au
             L1 to L2 : 10 Au +   100 JAX -> 1 Pt
             L2 to L3 : 10 Pt +  1000 JAX -> 1 Pd
             L3 to L4 : 10 Pd + 10000 JAX -> 1 Jx
             Total possible Ag -> 12000
             Total possible Au ->  1200
             Total possible Pt ->   120
             Total possible Pd ->    12
             Total possible Jx ->     1
        @param levelXNumber : Accepted levels are 0,1,2, and 3. Level 4 is the highest.
        @return xCount : L0 to L1 requires 1 Ag
                         L1 to L2 requires 10 Au
                         L2 to L3 requires 10 Pt
                         L3 to L4 requires 10 Pd
        @return tokenCount : L0 to L1 requires    10 JAX
                             L1 to L2 requires   100 JAX
                             L2 to L3 requires  1000 JAX
                             L3 to L4 requires 10000 JAX
    */
    function levelUpRequirements(uint256 levelXNumber) public pure override returns
        (uint256 xCount, uint256 tokenCount) {
        require(levelXNumber < 4, "invalid level");
        tokenCount = 10 ** (levelXNumber.add(1));
        if (levelXNumber == 0) {
            xCount = 1;
        } else {
            xCount = 10;
        }
        tokenCount = tokenCount.mul(1e18);
    }

}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.8;


interface ISong {
    function setBaseURI(string memory baseURI_) external;
    function mint(address to) external returns (uint256 newTokenId);
    function burn(uint256[] calldata tokenIds) external;
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/** @title Pacemaker
    @author Lendroid Foundation
        LICENSE : https://github.com/lendroidproject/protocol.2.0/blob/master/LICENSE.md
    @notice Smart contract based on which various events in the Protocol take place
    @dev Audit certificate : https://certificate.quantstamp.com/view/lendroid-whalestreet
*/

// solhint-disable-next-line
abstract contract Pacemaker {

    using SafeMath for uint256;
    uint256 constant public HEART_BEAT_START_TIME = 1607212800;// 2020-12-06 00:00:00 UTC (UTC +00:00)
    uint256 constant public EPOCH_PERIOD = 8 hours;

    /**
        @notice Displays the epoch which contains the given timestamp
        @return uint256 : Epoch value
    */
    function epochFromTimestamp(uint256 timestamp) public pure virtual returns (uint256) {
        if (timestamp > HEART_BEAT_START_TIME) {
            return timestamp.sub(HEART_BEAT_START_TIME).div(EPOCH_PERIOD).add(1);
        }
        return 0;
    }

    /**
        @notice Displays timestamp when a given epoch began
        @return uint256 : Epoch start time
    */
    function epochStartTimeFromTimestamp(uint256 timestamp) public pure virtual returns (uint256) {
        if (timestamp <= HEART_BEAT_START_TIME) {
            return HEART_BEAT_START_TIME;
        } else {
            return HEART_BEAT_START_TIME.add((epochFromTimestamp(timestamp).sub(1)).mul(EPOCH_PERIOD));
        }
    }

    /**
        @notice Displays timestamp when a given epoch will end
        @return uint256 : Epoch end time
    */
    function epochEndTimeFromTimestamp(uint256 timestamp) public pure virtual returns (uint256) {
        if (timestamp < HEART_BEAT_START_TIME) {
            return HEART_BEAT_START_TIME;
        } else if (timestamp == HEART_BEAT_START_TIME) {
            return HEART_BEAT_START_TIME.add(EPOCH_PERIOD);
        } else {
            return epochStartTimeFromTimestamp(timestamp).add(EPOCH_PERIOD);
        }
    }

    /**
        @notice Calculates current epoch value from the block timestamp
        @dev Calculates the nth 8-hour window frame since the heartbeat's start time
        @return uint256 : Current epoch value
    */
    function currentEpoch() public view virtual returns (uint256) {
        return epochFromTimestamp(block.timestamp);// solhint-disable-line not-rely-on-time
    }

}