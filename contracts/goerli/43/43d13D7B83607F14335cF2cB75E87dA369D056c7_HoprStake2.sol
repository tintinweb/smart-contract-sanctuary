/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/token/ERC777/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

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


// File @openzeppelin/contracts/security/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/*
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


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}


// File @openzeppelin/contracts/utils/math/[email protected]

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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

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


// File contracts/IHoprBoost.sol


pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IHoprBoost is IERC721Metadata {
    /**
     * @dev Returns the boost factor and the redeem deadline associated with ``tokenId``.
     * @param tokenId uint256 token Id of the boost.
     */
    function boostOf(uint256 tokenId) external view returns (uint256, uint256);
    
    /**
     * @dev Returns the boost type associated with ``tokenId``.
     * @param tokenId uint256 token Id of the boost.
     */
    function typeOf(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Returns the boost type index associated with ``tokenId``.
     * @param tokenId uint256 token Id of the boost.
     */
    function typeIndexOf(uint256 tokenId) external view returns (uint256);
}


// File contracts/HoprStake2.sol


pragma solidity ^0.8.0;









/**
 * 
 */
contract HoprStake2 is Ownable, IERC777Recipient, IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    struct Account {
        uint256 actualLockedTokenAmount; // The amount of LOCK_TOKEN being actually locked to the contract. 
                                         // Those tokens can be withdrawn after “UNLOCK_START”
        uint256 lastSyncTimestamp; // Timestamp at which any “Account” attribute gets synced for the last time. 
        uint256 cumulatedRewards; // Rewards accredited to the account at “lastSyncTimestamp”.
        uint256 claimedRewards; // Rewards claimed by the account.
    }

    uint256 public constant PROGRAM_START = 1642424400; // Block timestamp at which incentive program starts. Default value is 1642424400 (Jan 17th 2022 14:00 CET).
    uint256 public constant PROGRAM_END = 1650974400; // Block timestamp at which incentive program ends. From this timestamp on, tokens can be unlocked. Default value is 1650974400 (Apr 26th 2022 14:00 CET).
    uint256 public constant FACTOR_DENOMINATOR = 1e12; // Denominator of the “Basic reward factor”. Default value is 1e12.
    uint256 public constant BASIC_FACTOR_NUMERATOR = 5787; // Numerator of the “Basic reward factor”, for all accounts that participate in the program. Default value is 5787, which corresponds to 5.787/1e9 per second. Its associated denominator is FACTOR_DENOMINATOR. 
    uint256 public constant BOOST_CAP = 1e24; // Cap on actual locked tokens for receiving additional boosts.

    address public LOCK_TOKEN = 0xD057604A14982FE8D88c5fC25Aac3267eA142a08; // Token that HOPR holders need to lock to the contract: xHOPR address.
    address public REWARD_TOKEN = 0xD4fdec44DB9D44B8f2b6d529620f9C0C7066A2c1; // Token that HOPR holders can claim as rewards: wxHOPR address
    IHoprBoost public NFT_CONTRACT = IHoprBoost(0x43d13D7B83607F14335cF2cB75E87dA369D056c7) ; // Address of the HoprBoost NFT smart contract.

    mapping(address=>mapping(uint256=>uint256)) public redeemedNft; // Redeemed NFT per account, structured as “account -> index -> NFT tokenId”.
    mapping(address=>uint256) public redeemedNftIndex; // The last index of redeemed NFT of an account. It defines the length of the “redeemedBoostToken mapping.
    mapping(address=>mapping(uint256=>uint256)) public redeemedFactor; // Redeemed boost factor per account, structured as “account -> index -> NFT tokenId”.
    mapping(address=>uint256) public redeemedFactorIndex; // The last index of redeemed boost factor factor of an account. It defines the length of the “redeemedFactor” mapping.

    mapping(address=>Account) public accounts; // It stores the locked token amount, earned and claimed rewards per account.
    uint256 public totalLocked;  // Total amount of tokens being locked in the incentive program.
    uint256 public availableReward; // Total amount of reward tokens currently available in the lock.

    // setup ERC1820
    IERC1820Registry private constant ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    event Sync(address indexed account, uint256 indexed increment);
    event Staked(address indexed account, uint256 indexed actualAmount);
    event Released(address indexed account, uint256 indexed actualAmount);
    event RewardFueled(uint256 indexed amount);
    event Redeemed(address indexed account, uint256 indexed boostTokenId, bool indexed factorRegistered);
    event Claimed(address indexed account, uint256 indexed rewardAmount);

    /**
     * @dev Provide NFT contract address. Transfer owner role to the new owner address. 
     * At deployment, it also registers the lock contract as an ERC777 recipient.
     * @param _nftAddress address Address of the NFT contract.
     * @param _newOwner address Address of the new owner. This new owner can reclaim any ERC20 and ERC721 token being accidentally sent to the lock contract. 
     * @param _lockToken address Address of the stake token xHOPR.
     * @param _rewardToken address Address of the reward token wxHOPR.
     */
    constructor(address _nftAddress, address _newOwner, address _lockToken, address _rewardToken) {
        // implement in favor of testing
        uint chainId;
        assembly {
            chainId := chainid()
        }
        if (chainId != 100) {
            LOCK_TOKEN = _lockToken;
            REWARD_TOKEN = _rewardToken; 
            NFT_CONTRACT = IHoprBoost(_nftAddress);
        }
        transferOwnership(_newOwner);
        ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    /**
     * @dev Given NFT name type and rank name (as in HoprBoost) returns if the hodler has redeemed such an NFT 
     * @param nftType string Type name of the HoprBoost NFT.
     * @param nftRank string Rank name of the HoprBoost NFT.
     * @param hodler address Address of an account that stakes xHOPR tokens and/or redeems its HoprBoost NFT.
     */
    function isNftTypeAndRankRedeemed1(string memory nftType, string memory nftRank, address hodler) external view returns (bool) {
        string memory nftURI = string(abi.encodePacked(nftType, "/", nftRank));

        // compare `boostType/boosRank` of redeemed NFTs with `nftURI`
        for (uint256 index = 0; index < redeemedNftIndex[hodler]; index++) {
            uint256 redeemedTokenId = redeemedNft[hodler][index];
            string memory redeemedTokenURI = NFT_CONTRACT.tokenURI(redeemedTokenId);
            if (_hasSubstring(redeemedTokenURI, nftURI)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Given NFT type index and rank name (as in HoprBoost) returns if the hodler has redeemed such an NFT 
     * @param nftTypeIndex uint256 Type index of the HoprBoost NFT.
     * @param nftRank string Rank name of the HoprBoost NFT.
     * @param hodler address Address of an account that stakes xHOPR tokens and/or redeems its HoprBoost NFT.
     */
    function isNftTypeAndRankRedeemed2(uint256 nftTypeIndex, string memory nftRank, address hodler) external view returns (bool) {
        // compare `boostType/boosRank` of redeemed NFTs with `nftURI`
        for (uint256 index = 0; index < redeemedNftIndex[hodler]; index++) {
            uint256 redeemedTokenId = redeemedNft[hodler][index];
            string memory redeemedTokenURI = NFT_CONTRACT.tokenURI(redeemedTokenId);
            if (NFT_CONTRACT.typeIndexOf(redeemedTokenId) == nftTypeIndex && _hasSubstring(redeemedTokenURI, nftRank)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Given NFT type index and the boost numerator (as in HoprBoost) returns if the hodler has redeemed such an NFT 
     * @param nftTypeIndex uint256 Type index of the HoprBoost NFT.
     * @param boostNumerator uint256 Boost numerator of the HoprBoost NFT.
     * @param hodler address Address of an account that stakes xHOPR tokens and/or redeems its HoprBoost NFT.
     */
    function isNftTypeAndRankRedeemed3(uint256 nftTypeIndex, uint256 boostNumerator, address hodler) external view returns (bool) {
        for (uint256 index = 0; index < redeemedNftIndex[hodler]; index++) {
            uint256 redeemedTokenId = redeemedNft[hodler][index];
            (uint256 redeemedBoost, ) = NFT_CONTRACT.boostOf(redeemedTokenId);
            if (NFT_CONTRACT.typeIndexOf(redeemedTokenId) == nftTypeIndex && boostNumerator == redeemedBoost) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Given NFT type name and the boost numerator (as in HoprBoost) returns if the hodler has redeemed such an NFT 
     * @param nftType string Type name of the HoprBoost NFT.
     * @param boostNumerator uint256 Boost numerator of the HoprBoost NFT.
     * @param hodler address Address of an account that stakes xHOPR tokens and/or redeems its HoprBoost NFT.
     */
    function isNftTypeAndRankRedeemed4(string memory nftType, uint256 boostNumerator, address hodler) external view returns (bool) {
        for (uint256 index = 0; index < redeemedNftIndex[hodler]; index++) {
            uint256 redeemedTokenId = redeemedNft[hodler][index];
            (uint256 redeemedBoost, ) = NFT_CONTRACT.boostOf(redeemedTokenId);
            if (keccak256((bytes(NFT_CONTRACT.typeOf(redeemedTokenId)))) == keccak256((bytes(nftType))) && boostNumerator == redeemedBoost) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev ERC677 hook. Token holders can send their tokens with `transferAndCall` to the stake contract.  
     * After PROGRAM_END, it refuses tokens; Before PROGRAM_END, it accepts tokens xHOPR token, sync 
     * Account state, and update totalLocked. 
     * @param _from address Address of tokens sender
     * @param _value uint256 token amount being transferred
     * @param _data bytes Data being sent along with token transfer
     */
    function onTokenTransfer(
        address _from, 
        uint256 _value, 
        // solhint-disable-next-line no-unused-vars
        bytes memory _data
    ) external returns (bool) {
        require(msg.sender == LOCK_TOKEN, "HoprStake: Only accept LOCK_TOKEN in staking");
        require(block.timestamp <= PROGRAM_END, "HoprStake: Program ended, cannot stake anymore.");

        _sync(_from);
        accounts[_from].actualLockedTokenAmount += _value;
        totalLocked += _value;
        emit Staked(_from, _value);

        return true;
    }

    /**
     * @dev ERC777 hook. To receive wxHOPR to fuel the reward pool with `send()` method. It updates the availableReward by tokenAmount.
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes hex information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function tokensReceived(
        // solhint-disable-next-line no-unused-vars
        address operator,
        address from,
        address to,
        uint256 amount,
        // solhint-disable-next-line no-unused-vars
        bytes calldata userData,
        // solhint-disable-next-line no-unused-vars
        bytes calldata operatorData
    ) external override {
        require(msg.sender == REWARD_TOKEN, "HoprStake: Sender must be wxHOPR token");
        require(to == address(this), "HoprStake: Must be sending tokens to HoprStake contract");
        require(from == owner(), "HoprStake: Only accept owner to provide rewards");
        availableReward += amount;
        emit RewardFueled(amount);
    }

    /**
     * @dev Whenever a boost `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * when redeeming, this function is called. Boost factor associated with the 
     * It must return its Solidity selector to confirm the token transfer upon success.
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param tokenId uint256 amount of tokens to transfer
     * @param data bytes hex information provided by the token holder (if any)
     */
    function onERC721Received(
        // solhint-disable-next-line no-unused-vars
        address operator,
        address from,
        uint256 tokenId,
        // solhint-disable-next-line no-unused-vars
        bytes calldata data
    ) external override returns (bytes4) {
        require(_msgSender() == address(NFT_CONTRACT), "HoprStake: Cannot SafeTransferFrom tokens other than HoprBoost.");
        require(block.timestamp <= PROGRAM_END, "HoprStake: Program ended, cannot redeem boosts.");
        // Account memory account = accounts[from];
        _sync(from);

        // redeem NFT
        redeemedNft[from][redeemedNftIndex[from]] = tokenId;
        redeemedNftIndex[from] += 1;

        // update boost factor
        uint256 typeId = NFT_CONTRACT.typeIndexOf(tokenId);
        (uint256 factor, ) = NFT_CONTRACT.boostOf(tokenId);

        uint256 boostIndex = redeemedFactorIndex[from];
        uint256 index = 0;
        for (index; index < boostIndex; index++) {
            // loop through redeemed factors, replace the factor of the same type, if the current factor is larger.
            uint256 redeemedId = redeemedFactor[from][index];
            (uint256 redeemedFactorValue, ) = NFT_CONTRACT.boostOf(redeemedId);

            if (NFT_CONTRACT.typeIndexOf(redeemedId) == typeId) {
                if (redeemedFactorValue < factor) {
                    redeemedFactor[from][index] = tokenId;
                }
                emit Redeemed(from, tokenId, redeemedFactorValue < factor);
                break;
            }
        }
        if (index == boostIndex) {
            // new type being redeemed.
            redeemedFactor[from][boostIndex] = tokenId;
            redeemedFactorIndex[from] += 1;
            emit Redeemed(from, tokenId, true);
        }

        return IERC721Receiver(address(this)).onERC721Received.selector;
    }

    /**
     * @dev Manually sync account's reward states
     * @notice public function of ``_sync``.
     * @param account address Account whose stake rewards will be synced.
     */
    function sync(address account) external {
        _sync(account); 
    }

    /**
     * @dev Sync rewards and claim them
     * @notice public function of ``_sync`` + ``_claim``
     * @param account address Account whose stake rewards will be synced and claimed.
     */
    function claimRewards(address account) external {
        _sync(account); 
        _claim(account);
    }

    /**
     * @dev Unlock staking for caller
     */
    function unlock() external {
        _unlockFor(msg.sender);
    }
    /**
     * @dev Unlock staking for a given account
     * @param account address Account that staked tokens.
     */
    function unlockFor(address account) external {
        _unlockFor(account);
    }

    /**
     * @dev Reclaim any ERC20 token being accidentally sent to the contract.
     * @param tokenAddress address ERC20 token address.
     */
    function reclaimErc20Tokens(address tokenAddress) external onlyOwner nonReentrant {
        uint256 difference;
        if (tokenAddress == LOCK_TOKEN) {
            difference = IERC20(LOCK_TOKEN).balanceOf(address(this)) - totalLocked;
        } else {
            difference = IERC20(tokenAddress).balanceOf(address(this));
        }
        IERC20(tokenAddress).safeTransfer(owner(), difference);
    }

    /**
     * @dev Reclaim any ERC721 token being accidentally sent to the contract.
     * @param tokenAddress address ERC721 token address.
     */
    function reclaimErc721Tokens(address tokenAddress, uint256 tokenId) external onlyOwner nonReentrant {
        require(tokenAddress != address(NFT_CONTRACT), "HoprStake: Cannot claim HoprBoost NFT");
        IHoprBoost(tokenAddress).transferFrom(address(this), owner(), tokenId);
    }

    /**
     * @dev Shortcut that returns the actual stake of an account. 
     * @param _account address Address of the staker account.
     */
    function stakedHoprTokens(address _account) public view returns (uint256) {
        return accounts[_account].actualLockedTokenAmount;
    }

    /**
     * @dev Returns the increment of cumulated rewards during the “lastSyncTimestamp” and current block.timestamp. 
     * @param _account address Address of the account whose rewards will be calculated.
     */
    function getCumulatedRewardsIncrement(address _account) public view returns (uint256) {
        return _getCumulatedRewardsIncrement(_account);
    }

    /**
     * @dev Calculates the increment of cumulated rewards during the “lastSyncTimestamp” and block.timestamp. 
     * current block timestamp and lastSyncTimestamp are confined in [PROGRAM_START, PROGRAM_END] for basic and boosted lockup,
     * @param _account address Address of the account whose rewards will be calculated.
     */
    function _getCumulatedRewardsIncrement(address _account) private view returns (uint256) {
        Account memory account = accounts[_account];
        if (block.timestamp <= PROGRAM_START || account.lastSyncTimestamp >= PROGRAM_END) {
            // skip calculation and return directly 0;
            return 0;
        }
        // Per second gain, for basic lock-up.
        uint256 gainPerSec = account.actualLockedTokenAmount * BASIC_FACTOR_NUMERATOR;
        
        // Per second gain, for additional boost, applicable to amount under BOOST_CAP
        for (uint256 index = 0; index < redeemedFactorIndex[_account]; index++) {
            uint256 tokenId = redeemedFactor[_account][index];
            (uint256 boost, ) = NFT_CONTRACT.boostOf(tokenId);
            gainPerSec += (account.actualLockedTokenAmount.min(BOOST_CAP)) * boost;
        }

        return (
                gainPerSec * (
                    block.timestamp.max(PROGRAM_START).min(PROGRAM_END) - 
                    account.lastSyncTimestamp.max(PROGRAM_START).min(PROGRAM_END)
                )
            ) / FACTOR_DENOMINATOR;
    }

    /**
     * @dev if the given `tokenURI` end with `/substring` 
     * @param tokenURI string URI of the HoprBoost NFT. E.g. "https://stake.hoprnet.org/PuzzleHunt_v2/Bronze - Week 5"
     * @param substring string of the `boostRank` or `boostType/boostRank`. E.g. "Bronze - Week 5", "PuzzleHunt_v2/Bronze - Week 5"
     */
    function _hasSubstring(string memory tokenURI, string memory substring) private pure returns (bool) {
        // convert string to bytes
        bytes memory tokenURIInBytes = bytes(tokenURI);
        bytes memory substringInBytes = bytes(substring);
        
        // lenghth of tokenURI is the sum of substringLen and restLen, where
        // - `substringLen` is the length of the part that is extracted and compared with the provided substring
        // - `restLen` is the length of the baseURI and boostType, which will be offset
        uint256 substringLen = substringInBytes.length;
        uint256 restLen = tokenURIInBytes.length - substringLen;
        // one byte before the supposed substring, to see if it's the start of `substring`
        bytes1 slashPositionContent = tokenURIInBytes[restLen - 1];

        if (slashPositionContent != 0x2f) {
            // if this position is not a `/`, substring in the tokenURI is for sure neither `boostRank` nor `boostType/boostRank`
            return false;
        }

        // offset so that value from the next calldata (`substring`) is removed, so bitwise it needs to shift
        // log2(16) * (32 - substringLen) * 2
        uint256 offset = (32 - substringLen) * 8;

        bytes32 trimed; // left-padded extracted `boostRank` from the `tokenURI`
        bytes32 substringInBytes32 = bytes32(substringInBytes);   // convert substring in to bytes32
        bytes32 shifted; // shift the substringInBytes32 from right-padded to left-padded
        
        bool result;
        assembly {
            // assuming `boostRank` or `boostType/boostRank` will never exceed 32 bytes
            // left-pad the `boostRank` extracted from the `tokenURI`, so that possible
            // extra pieces of `substring` is not included
            // 32 jumps the storage of bytes length and restLen offsets the `baseURI`
            trimed := shr(offset, mload(add(add(tokenURIInBytes, 32), restLen)))
            // tokenURIInBytes32 := mload(add(add(tokenURIInBytes, 32), restLen))
            // left-pad `substring`
            shifted := shr(offset, substringInBytes32)
            // compare results
            result := eq(trimed, shifted)
        }
        return result;
    }

    /**
     * @dev Update “lastSyncTimestamp” with the current block timestamp and update “cumulatedRewards” with _getCumulatedRewardsIncrement(account) 
     * @param _account address Address of the account whose rewards will be calculated.
     */
    function _sync(address _account) private {
        uint256 increment = _getCumulatedRewardsIncrement(_account);
        accounts[_account].cumulatedRewards += increment;
        accounts[_account].lastSyncTimestamp = block.timestamp;
        emit Sync(_account, increment);
    }

    /**
     * @dev Claim rewards for staking.
     * @param _account address Address of the staking account.
     */
    function _claim(address _account) private {
        Account memory account = accounts[_account];
        // update states
        uint256 amount = account.cumulatedRewards - account.claimedRewards;
        require(amount > 0, "HoprStake: Nothing to claim");
        accounts[_account].claimedRewards = accounts[_account].cumulatedRewards;
        require(availableReward >= amount, "HoprStake: Insufficient reward pool.");
        availableReward -= amount;
        // send rewards to the account.
        IERC20(REWARD_TOKEN).safeTransfer(_account, amount);
        emit Claimed(_account, amount);
    }

    /**
     * @dev Unlock staking for a given account
     * @param _account address Account that staked tokens.
     */
    function _unlockFor(address _account) private {
        require(block.timestamp > PROGRAM_END, "HoprStake: Program is ongoing, cannot unlock stake.");
        uint256 actualStake = accounts[_account].actualLockedTokenAmount;
        _sync(_account); 
        accounts[_account].actualLockedTokenAmount = 0;
        totalLocked -= actualStake;
        _claim(_account);
        // unlock actual staked tokens
        IERC20(LOCK_TOKEN).safeTransfer(_account, actualStake);
        // unlock redeemed NFTs
        for (uint256 index = 0; index < redeemedNftIndex[_account]; index++) {
            NFT_CONTRACT.transferFrom(address(this), _account, redeemedNft[_account][index]);
        }
        emit Released(_account, actualStake);
    }
}