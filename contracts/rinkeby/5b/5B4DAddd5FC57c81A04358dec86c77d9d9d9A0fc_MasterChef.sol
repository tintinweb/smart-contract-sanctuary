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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDCAU.sol";

// MasterChef is the master of DCAU(Dragon Crypto Aurum). He can make DCAU and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once DCAU is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is ERC721Holder, Ownable, ReentrancyGuard {
    event AddPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);
    event SetPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event UpdateStartBlock(uint256 newStartBlock);
    event SetDCAUPerSecond(uint256 amount);
    event SetEmissionEndTime(uint256 emissionEndTime);
    event DragonNestStaked(address indexed user, uint256 indexed tokenId);
    event DragonNestWithdrawn(address indexed user, uint256 indexed tokenId);
    event MarketDCAUDeposited(address indexed user, uint256 indexed pid, uint256 amount);

    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DCAUs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDCAUPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDCAUPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. DCAUs to distribute per block. 100 - 1point
        uint256 lastRewardTime; // Last block timestamp that DCAUs distribution occurs.
        uint256 accDCAUPerShare; // Accumulated DCAUs per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points 10000 - 100%
        uint256 lpSupply;
    }

    struct PoolDragonNestInfo {
        uint256 accDepFeePerShare; // Accumulated LP token(from deposit fee) per share, times 1e12. See below.
        uint256 pendingDepFee; // pending deposit fee for the reward for the Dragon Nest Supporters
    }

    mapping(uint256 => PoolDragonNestInfo) public poolDragonNestInfo; // poolId => poolDragonNestInfo
    mapping(uint256 => mapping(uint256 => uint256)) public dragonNestInfo; // poolId => (nestId => rewardDebt), nestId: NFT tokenId
    mapping(uint256 => address) nestSupporters; // tokenId => nest supporter;
    uint256 public nestSupportersLength;

    uint256 public constant DCAU_MAX_SUPPLY = 155000 * (10**18);

    uint256 public constant MAX_EMISSION_RATE = 1 * (10**18);

    // The Dragon Cyrpto AU TOKEN!
    address public immutable DCAU;
    uint256 public dcauPerSecond;
    address public immutable DRAGON_NEST_SUPPORTER;
    // Deposit Fee address
    address public immutable FEEADDRESS;
    address public immutable GAMEADDRESS;
    address public immutable NFT_MARKET;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The time when Dragon mining starts.
    uint256 public startTime;
    // The time when Dragon mining ends.
    uint256 public emissionEndTime = type(uint256).max;

    address public immutable DEVADDRESS;

    constructor(
        address _DCAU,
        address _DRAGON_NEST_SUPPORTER,
        address _gameAddress,
        address _feeAddress,
        uint256 _startTime,
        uint256 _dcauPerSecond,
        address _devAddress,
        address _NFT_MARKET
    ) {
        require(_DCAU != address(0), "must be valid address");
        require(_DRAGON_NEST_SUPPORTER != address(0), "must be valid address");
        require(_gameAddress != address(0), "must be valid address");
        require(_feeAddress != address(0), "must be valid address");
        require(_startTime > block.timestamp, "must start in the future");
        require(_dcauPerSecond <= MAX_EMISSION_RATE, "emission rate too high");
        require(_devAddress != address(0), "must be valid address");
        require(_NFT_MARKET != address(0), "must be valid address");

        DCAU = _DCAU;
        DRAGON_NEST_SUPPORTER = _DRAGON_NEST_SUPPORTER;
        FEEADDRESS = _feeAddress;
        startTime = _startTime;
        dcauPerSecond = _dcauPerSecond;
        DEVADDRESS = _devAddress;
        GAMEADDRESS = _gameAddress;
        NFT_MARKET = _NFT_MARKET;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) external onlyOwner nonDuplicated(_lpToken) {
        require(poolInfo.length < 20, "too many pools");

        // Make sure the provided token is ERC20
        _lpToken.balanceOf(address(this));

        require(_depositFeeBP <= 401, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolExistence[_lpToken] = true;

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTime: lastRewardTime,
                accDCAUPerShare: 0,
                depositFeeBP: _depositFeeBP,
                lpSupply: 0
            })
        );

        emit AddPool(poolInfo.length - 1, address(_lpToken), _allocPoint, _depositFeeBP);
    }

    // Update the given pool's DCAU allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) external onlyOwner {
        require(_depositFeeBP <= 401, "set: invalid deposit fee basis points");
        require(_pid < poolInfo.length, "Dragon: Non-existent pool");

        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;

        emit SetPool(_pid, address(poolInfo[_pid].lpToken), _allocPoint, _depositFeeBP);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        // As we set the multiplier to 0 here after emissionEndTime
        // deposits aren't blocked after farming ends.
        // reward every 1 seconds
        if (_from > emissionEndTime) return 0;
        if (_to > emissionEndTime) return (emissionEndTime - _from);
        else return (_to - _from);
    }

    // View function to see pending DCAUs on frontend.
    function pendingDcau(uint256 _pid, address _user) external view returns (uint256) {
        require(_pid < poolInfo.length, "Dragon: Non-existent pool");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDcauPerShare = pool.accDCAUPerShare;

        if (block.timestamp > pool.lastRewardTime && pool.lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 dcauReward = (multiplier * dcauPerSecond * pool.allocPoint) / totalAllocPoint;

            uint256 dcauTotalSupply = IERC20(DCAU).totalSupply();

            uint256 gameDevDcauReward = dcauReward / 15;

            // This shouldn't happen, but just in case we stop rewards.
            if (dcauTotalSupply >= DCAU_MAX_SUPPLY) {
                dcauReward = 0;
            } else if ((dcauTotalSupply + dcauReward + gameDevDcauReward) > DCAU_MAX_SUPPLY) {
                uint256 dcauSupplyRemaining = DCAU_MAX_SUPPLY - dcauTotalSupply;
                dcauReward = (dcauSupplyRemaining * 15) / 16;
            }

            accDcauPerShare = accDcauPerShare + ((dcauReward * 1e12) / pool.lpSupply);
        }

        return ((user.amount * accDcauPerShare) / 1e12) - user.rewardDebt;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        require(_pid < poolInfo.length, "Dragon: Non-existent pool");

        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 dcauReward = (multiplier * dcauPerSecond * pool.allocPoint) / totalAllocPoint;
        uint256 dcauTotalSupply = IERC20(DCAU).totalSupply();

        uint256 gameDevDcauReward = dcauReward / 15;

        // This shouldn't happen, but just in case we stop rewards.
        if (dcauTotalSupply >= DCAU_MAX_SUPPLY) {
            dcauReward = 0;
            gameDevDcauReward = 0;
        } else if ((dcauTotalSupply + dcauReward + gameDevDcauReward) > DCAU_MAX_SUPPLY) {
            uint256 dcauSupplyRemaining = DCAU_MAX_SUPPLY - dcauTotalSupply;
            dcauReward = (dcauSupplyRemaining * 15) / 16;
            gameDevDcauReward = dcauSupplyRemaining - dcauReward;
        }

        if (dcauReward > 0) {
            IDCAU(DCAU).mint(address(this), dcauReward);
        }

        if (gameDevDcauReward > 0) {
            uint256 devReward = (gameDevDcauReward * 1) / 3;
            uint256 gameReward = gameDevDcauReward - devReward;

            IDCAU(DCAU).mint(DEVADDRESS, devReward);
            IDCAU(DCAU).mint(GAMEADDRESS, gameReward);
        }

        dcauTotalSupply = IERC20(DCAU).totalSupply();

        // The first time we reach DCAU's max supply we solidify the end of farming.
        if (dcauTotalSupply >= DCAU_MAX_SUPPLY && emissionEndTime == type(uint256).max) emissionEndTime = block.timestamp;

        pool.accDCAUPerShare = pool.accDCAUPerShare + ((dcauReward * 1e12) / pool.lpSupply);
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens to MasterChef for DCAU allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_pid < poolInfo.length, "Dragon: Non-existent pool");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accDCAUPerShare) / 1e12) - user.rewardDebt;
            if (pending > 0) {
                safeDcauTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {
            // We are considering tokens which takes accounts fees when trasnsferring such like reflect finance
            IERC20 _lpToken = pool.lpToken;
            {
                uint256 balanceBefore = _lpToken.balanceOf(address(this));
                _lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
                _amount = _lpToken.balanceOf(address(this)) - balanceBefore;
                require(_amount > 0, "We only accept amount > 0");
            }

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = (_amount * pool.depositFeeBP) / 10000;
                // We split this fee to feeAddress and Dragon Nest supporters - 90% 10%
                _lpToken.safeTransfer(FEEADDRESS, (depositFee * 9000) / 10000);

                poolDragonNestInfo[_pid].pendingDepFee += (depositFee * 1000) / 10000;

                user.amount = user.amount + _amount - depositFee;
                pool.lpSupply = pool.lpSupply + _amount - depositFee;
            } else {
                user.amount = user.amount + _amount;
                pool.lpSupply = pool.lpSupply + _amount;
            }
        }

        user.rewardDebt = (user.amount * pool.accDCAUPerShare) / 1e12;

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_pid < poolInfo.length, "Dragon: Non-existent pool");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "Withdraw: not good");
        updatePool(_pid);
        uint256 pending = ((user.amount * pool.accDCAUPerShare) / 1e12) - user.rewardDebt;
        if (pending > 0) {
            safeDcauTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply - _amount;
        }
        user.rewardDebt = (user.amount * pool.accDCAUPerShare) / 1e12;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "Dragon: Non-existent pool");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        // In the case of an accounting error, we choose to let the user emergency withdraw anyway
        if (pool.lpSupply >= amount) pool.lpSupply = pool.lpSupply - amount;
        else pool.lpSupply = 0;

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe DCAU transfer function, just in case if rounding error causes pool to not have enough DCAUs.
    function safeDcauTransfer(address _to, uint256 _amount) internal {
        uint256 dcauBal = IERC20(DCAU).balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > dcauBal) {
            transferSuccess = IERC20(DCAU).transfer(_to, dcauBal);
        } else {
            transferSuccess = IERC20(DCAU).transfer(_to, _amount);
        }
        require(transferSuccess, "safeDcauTransfer: transfer failed");
    }

    function setStartTime(uint256 _newStartTime) external onlyOwner {
        require(poolInfo.length == 0, "no changing startTime after pools have been added");
        require(block.timestamp < startTime, "cannot change start time if sale has already commenced");
        require(block.timestamp < _newStartTime, "cannot set start time in the past");
        startTime = _newStartTime;

        emit UpdateStartBlock(startTime);
    }

    function setDcauPerSecond(uint256 _dcauPerSecond) external onlyOwner {
        require(_dcauPerSecond <= MAX_EMISSION_RATE, "emissions too high limited to 1 per second");

        massUpdatePools();

        dcauPerSecond = _dcauPerSecond;
        emit SetDCAUPerSecond(_dcauPerSecond);
    }

    function setEmissionEndTime(uint256 _emissionEndTime) external onlyOwner {
        require(_emissionEndTime > block.timestamp, "Emission can not be end in the past");
        emissionEndTime = _emissionEndTime;
        emit SetEmissionEndTime(_emissionEndTime);
    }

    function massUpdatePoolDragonNests() external nonReentrant {
        _massUpdatePoolDragonNests();
    }

    function _massUpdatePoolDragonNests() private {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePoolDragonNest(pid);
        }
    }

    // Update dragon nest.
    function updatePoolDragonNest(uint256 _pid) external nonReentrant {
        _updatePoolDragonNest(_pid);
    }

    function _updatePoolDragonNest(uint256 _pid) private {
        require(nestSupportersLength > 0, "Must have supporters");

        PoolDragonNestInfo storage poolDragonNest = poolDragonNestInfo[_pid];
        uint256 _pendingDepFee = poolDragonNest.pendingDepFee;

        if (_pendingDepFee > 0) {
            poolDragonNest.accDepFeePerShare += _pendingDepFee / nestSupportersLength;
            poolDragonNest.pendingDepFee = 0;
        }
    }

    /**
     * These functions are private function for using contract internal.
     * These functions will be used when user stakes new DragonNestSupporter
     */
    function massUpdatePoolDragonNestsWithNewToken(uint256 _tokenId) private {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePoolDragonNestWithNewToken(pid, _tokenId);
        }
    }

    function updatePoolDragonNestWithNewToken(uint256 _pid, uint256 _tokenId) private {
        PoolDragonNestInfo storage _poolDragonNestInfo = poolDragonNestInfo[_pid];
        uint256 _pendingDepFee = _poolDragonNestInfo.pendingDepFee;

        uint256 accDepFeePerShare = _poolDragonNestInfo.accDepFeePerShare;
        if (_pendingDepFee > 0 && nestSupportersLength > 0) {
            _poolDragonNestInfo.accDepFeePerShare = accDepFeePerShare + _pendingDepFee / nestSupportersLength;
            _poolDragonNestInfo.pendingDepFee = 0;
        }
        dragonNestInfo[_pid][_tokenId] = accDepFeePerShare;
    }

    function stakeDragonNest(uint256 tokenId) external nonReentrant {
        massUpdatePoolDragonNestsWithNewToken(tokenId);
        IERC721 _dragonNest = IERC721(DRAGON_NEST_SUPPORTER);
        _dragonNest.safeTransferFrom(msg.sender, address(this), tokenId);
        nestSupporters[tokenId] = msg.sender;
        nestSupportersLength++;

        emit DragonNestStaked(msg.sender, tokenId);
    }

    function withdrawDragonNest(uint256 tokenId) external nonReentrant {
        require(nestSupporters[tokenId] == msg.sender, "Dragon: Forbidden");
        nestSupporters[tokenId] = address(0);
        _massUpdatePoolDragonNests();
        // transfer in for loop? It's Okay. We should do with a few number of pools
        uint256 len = poolInfo.length;
        for (uint256 pid = 0; pid < len; pid++) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lpToken.safeTransfer(
                address(msg.sender),
                poolDragonNestInfo[pid].accDepFeePerShare - dragonNestInfo[pid][tokenId]
            );
            dragonNestInfo[pid][tokenId] = 0;
        }

        IERC721 _dragonNest = IERC721(DRAGON_NEST_SUPPORTER);
        _dragonNest.safeTransferFrom(address(this), msg.sender, tokenId);
        nestSupportersLength--;

        emit DragonNestWithdrawn(msg.sender, tokenId);
    }

    // View function to see pending DCAUs on frontend.
    function pendingDcauOfDragonNest(uint256 _pid, uint256 _tokenId) external view returns (uint256) {
        PoolDragonNestInfo storage poolDragonNest = poolDragonNestInfo[_pid];
        uint256 _pendingDepFee = poolDragonNest.pendingDepFee;

        uint256 accDepFeePerShare = 0;

        if (nestSupportersLength > 0) {
            accDepFeePerShare = poolDragonNest.accDepFeePerShare + _pendingDepFee / nestSupportersLength;
        } else {
            accDepFeePerShare = poolDragonNest.accDepFeePerShare + _pendingDepFee;
        }

        return accDepFeePerShare - dragonNestInfo[_pid][_tokenId];
    }

    function stakedAddressForDragonNest(uint256 _tokenId) external view returns (address) {
        require(_tokenId <= 25, "token does not exist");
        return nestSupporters[_tokenId];
    }

    /**
     * @dev This function is used for depositing DCAU from market
     */
    function depositMarketFee(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_pid < poolInfo.length, "pool does not exist");
        require(address(poolInfo[_pid].lpToken) == DCAU, "Should be DCAU pool");
        require(msg.sender == NFT_MARKET, "Available from only market");

        IERC20(DCAU).safeTransferFrom(address(msg.sender), address(this), _amount);
        poolDragonNestInfo[_pid].pendingDepFee += _amount;

        emit MarketDCAUDeposited(msg.sender, _pid, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IDCAU {
    function mint(address _to, uint256 _amount) external;
}