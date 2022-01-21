// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
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
interface IERC165Upgradeable {
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IAddressRegistry.sol";
import "./interfaces/ITokenRegistry.sol";
import "./interfaces/IAuction.sol";

/**
 * @title Auction
 *
 * @notice This contract handles English/Dutch auctions based on EIP-712 signature.
 *
 * @author David Lee
 */

contract Auction is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, EIP712Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSAUpgradeable for bytes32;

    /**
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /**
     * @dev EIP-712 SellOrder typeHash,
     *      see https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct
     */
    bytes32 private constant CREATE_AUCTION_TYPEHASH =
        keccak256(
            "CreateAuction(address tokenAddress,uint256 tokenId,uint256 quantity,address priceTokenAddress,"
            "uint256 auctionInitialLotPrice,uint256 auctionInitialUnitPrice,"
            "uint256 auctionStartsAt,uint256 auctionExpiresAt,uint256 auctionNonce)"
        );

    /**
     * @dev EIP-712 SellOrder typeHash,
     *      see https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct
     */
    bytes32 private constant CREATE_BID_TYPEHASH =
        keccak256(
            "CreateBid(bytes32 auctionHash,address buyer,"
            "uint256 bidInitialLotPrice,uint256 bidInitialUnitPrice,"
            "uint256 bidStartsAt,uint256 bidExpiresAt,uint256 bidNonce)"
        );

    /**
     * @dev Maximum difference between End and Start Time
     *
     * @dev Global configurable setting helping to avoid potential mistakes when creating EIP712 signed messages
     */
    uint256 public maxOrderDuration;

    /**
     * @dev Minimum Lot price
     *
     * @dev Global configurable setting helping to avoid potential mistakes when creating EIP712 signed messages
     */
    uint256 public minLotPrice;

    /**
     *  @dev Maximum Lot price
     *
     * @dev Global configurable setting helping to avoid potential mistakes when creating EIP712 signed messages
     */
    uint256 public maxLotPrice;

    /**
     *  @dev Minimum Unit Price
     *
     * @dev Global configurable setting helping to avoid potential mistakes when creating EIP712 signed messages
     */
    uint256 public minUnitPrice;

    /**
     *  @dev Maximum Unit Price
     *
     * @dev Global configurable setting helping to avoid potential mistakes when creating EIP712 signed messages
     */
    uint256 public maxUnitPrice;

    /**
     * @dev The platform fee is charged in favor of the fee recipient when order is executed
     *
     * @dev The fee is held in the payment token currency
     *
     * @dev Defined in per mille (parts per thousand), for example,
     *      value 135 means 13.5%
     */
    uint16 public platformFee;

    /**
     * @dev The platform fee is charged in favor of the fee recipient when order is executed,
     *      see `platformFee`
     */
    address public feeRecipient;

    /**
     * @dev Link to the IAddressRegistry contract
     */
    address public addressRegistry;

    /**
     * @dev A record of used nonces for signing/validating signatures
     *
     * @dev Maps seller/buyer address => nonce => true/false (used unused)
     */
    mapping(address => mapping(uint256 => bool)) public usedNonces;

    /**
     * @dev Fired in acceptBid()
     *
     * @param _by Seller address
     * @param _from Buyer address
     * @param _tokenAddress NFT contract address
     * @param _auction Auction data
     * @param _bid Bid data
     */
    event BidAccepted(
        address indexed _by,
        address indexed _from,
        address indexed _tokenAddress,
        IAuction.CreateAuction _auction,
        IAuction.CreateBid _bid
    );

    /**
     * @dev Fired in cancelOrder()
     *
     * @param _by seller/buyer address who executed the cancellation
     * @param _nonce the nonce marked as used (cancelled)
     */
    event OrderCancelled(address indexed _by, uint256 indexed _nonce);

    /**
     * @dev Fired in updateMaxOrderDuration()
     *
     * @param _by address which executed an update
     * @param _oldMaxOrderDuration old max order duration value
     * @param _newMaxOrderDuration new max order duration value
     */
    event MaxOrderDurationUpdated(address indexed _by, uint256 _oldMaxOrderDuration, uint256 _newMaxOrderDuration);

    /**
     * @dev Fired in updateLotPriceRange()
     *
     * @param _by address which executed an update
     * @param _oldMinLotPrice old min lot price value
     * @param _oldMaxLotPrice old max lot price value
     * @param _newMinLotPrice new min lot price value
     * @param _newMaxLotPrice new max lot price value
     */
    event LotPriceRangeUpdated(
        address indexed _by,
        uint256 _oldMinLotPrice,
        uint256 _oldMaxLotPrice,
        uint256 _newMinLotPrice,
        uint256 _newMaxLotPrice
    );

    /**
     * @dev Fired in updateUnitPriceRange()
     *
     * @param _by address which executed an update
     * @param _oldMinUnitPrice Old min unit price value
     * @param _oldMaxUnitPrice Old max unit price value
     * @param _newMinUnitPrice New min unit price value
     * @param _newMaxUnitPrice New max unit price value
     */
    event UnitPriceRangeUpdated(
        address indexed _by,
        uint256 _oldMinUnitPrice,
        uint256 _oldMaxUnitPrice,
        uint256 _newMinUnitPrice,
        uint256 _newMaxUnitPrice
    );

    /**
     * @dev Fired in updatePlatformFee()
     *
     * @param _by address which executed an update
     * @param _oldFeeRecipient old fee recipient address
     * @param _oldPlatformFee old platform fee
     * @param _newFeeRecipient new fee recipient address
     * @param _newPlatformFee new platform fee
     */
    event PlatformFeeUpdated(
        address indexed _by,
        address indexed _oldFeeRecipient,
        uint16 _oldPlatformFee,
        address indexed _newFeeRecipient,
        uint16 _newPlatformFee
    );

    /**
     * @dev Fired in updateAddressRegistry()
     *
     * @param _by address which executed an update
     * @param _oldAddressRegistry old AddressRegistry contract address
     * @param _newAddressRegistry new AddressRegistry contract address
     */
    event AddressRegistryUpdated(
        address indexed _by,
        address indexed _oldAddressRegistry,
        address indexed _newAddressRegistry
    );

    /**
     * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
     *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
     */
    function initialize(
        address _addressRegistry,
        address _feeRecipient,
        uint16 _platformFee
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __EIP712_init("Illuvidex Auction", "1");

        require(_addressRegistry != address(0), "address registry not set");
        require(_feeRecipient != address(0) || _platformFee == 0, "fee recipient not set");
        require(_platformFee <= 1000, "platform fee must not exceed 1000");

        uint256 maxValue = type(uint256).max;

        // initialize AddressRegistery
        addressRegistry = _addressRegistry;

        // initialize max order duration
        maxOrderDuration = maxValue;

        // initialize min/max lot price
        minLotPrice = 1_000; // 0.001 for USDT/USDC
        maxLotPrice = maxValue;

        // initialize min/max unit price
        minUnitPrice = 1_000; // 0.001 for USDT/USDC
        maxUnitPrice = maxValue;

        // initialize fee and recipient
        feeRecipient = _feeRecipient;
        platformFee = _platformFee;
    }

    /**
     * @notice Accept English auction bid
     *
     * @dev whenNotPaused
     * @dev Only if the signature and bid are verified, NFT must be transferred.
     *
     * @param _createAuction Auction created
     * @param _createBid Auction bid created
     * @param _auctionSignature EIP-712 based signature for Auction
     * @param _bidSignature EIP-712 based signature for Auction bid
     */
    function acceptBid(
        IAuction.CreateAuction memory _createAuction,
        IAuction.CreateBid memory _createBid,
        bytes memory _auctionSignature,
        bytes memory _bidSignature
    ) external nonReentrant whenNotPaused {
        // validate auction
        _validateAuction(_createAuction, _auctionSignature);

        // validate auction bid
        _validateBid(
            _createAuction.auctionStartsAt,
            _createAuction.auctionExpiresAt,
            _createAuction.auctionInitialLotPrice,
            _createBid,
            _bidSignature
        );

        // check if the bid is matched with the auction
        bytes32 auctionHash = keccak256(
            abi.encodePacked(
                _createAuction.tokenAddress,
                _createAuction.tokenId,
                _createAuction.quantity,
                _createAuction.priceTokenAddress,
                _createAuction.auctionInitialLotPrice,
                _createAuction.auctionInitialUnitPrice,
                _createAuction.auctionStartsAt,
                _createAuction.auctionExpiresAt,
                _createAuction.auctionNonce
            )
        );

        require(auctionHash == _createBid.auctionHash, "Auction mismatched with Bid");

        // mark nonce for auction
        require(!usedNonces[msg.sender][_createAuction.auctionNonce], "nonce already used");
        usedNonces[msg.sender][_createAuction.auctionNonce] = true;

        // mark nonce for auction bid
        require(!usedNonces[_createBid.buyer][_createBid.bidNonce], "nonce already used");
        usedNonces[_createBid.buyer][_createBid.bidNonce] = true;

        // accept auction bid
        _acceptBuyOrder(
            IAuction.BuyOrder({
                buyer: _createBid.buyer,
                tokenAddress: _createAuction.tokenAddress,
                tokenId: _createAuction.tokenId,
                quantity: _createAuction.quantity,
                priceTokenAddress: _createAuction.priceTokenAddress,
                initialLotPrice: _createBid.bidInitialLotPrice,
                initialUnitPrice: _createBid.bidInitialUnitPrice,
                finalLotPrice: _createBid.bidInitialLotPrice,
                finalUnitPrice: _createBid.bidInitialUnitPrice,
                startsAt: _createBid.bidStartsAt,
                expiresAt: _createBid.bidExpiresAt,
                nonce: _createBid.bidInitialLotPrice
            })
        );

        emit BidAccepted(msg.sender, _createBid.buyer, _createAuction.tokenAddress, _createAuction, _createBid);
    }

    /**
     * @notice Transfer NFT
     *
     * @dev Fees are deducted and transferred to the feeRecipient address.
     *
     * @param _buyOrder Buy order listed
     */
    function _acceptBuyOrder(IAuction.BuyOrder memory _buyOrder) private {
        // calculate payment amount
        // _buyOrder.initialLotPrice is always equal to _buyOrder.finalLotPrice
        uint256 lotPrice = _buyOrder.initialLotPrice;
        uint256 feeAmount = (lotPrice * platformFee) / 1000;
        uint256 ownerAmount = lotPrice - feeAmount;

        // transfer the payment fee
        IERC20Upgradeable(_buyOrder.priceTokenAddress).safeTransferFrom(_buyOrder.buyer, feeRecipient, feeAmount);

        // transfer the payment
        IERC20Upgradeable(_buyOrder.priceTokenAddress).safeTransferFrom(_buyOrder.buyer, msg.sender, ownerAmount);

        // transfer the NFT
        IERC721Upgradeable(_buyOrder.tokenAddress).safeTransferFrom(msg.sender, _buyOrder.buyer, _buyOrder.tokenId);
    }

    /**
     * @notice Cancel orders
     *
     * @param _nonce Nonce of the order to cancel
     */
    function cancelOrder(uint256 _nonce) external {
        require(!usedNonces[msg.sender][_nonce], "nonce already used");
        usedNonces[msg.sender][_nonce] = true;

        emit OrderCancelled(msg.sender, _nonce);
    }

    /**
     * @dev Restricted access function to update maximum order duration
     *
     * @param _maxOrderDuration Maximum difference between End and Start Time
     */
    function updateMaxOrderDuration(uint256 _maxOrderDuration) external onlyOwner {
        require(_maxOrderDuration > 0, "maxOrderDuration not set");

        emit MaxOrderDurationUpdated(msg.sender, maxOrderDuration, _maxOrderDuration);

        maxOrderDuration = _maxOrderDuration;
    }

    /**
     * @dev Restricted access function to update lot price range
     *
     * @param _minLotPrice minimum lot price
     * @param _maxLotPrice maximum lot price
     */
    function updateLotPriceRange(uint256 _minLotPrice, uint256 _maxLotPrice) external onlyOwner {
        require(_minLotPrice > 0, "minLotPrice not set");
        require(_maxLotPrice >= _minLotPrice, "maxLotPrice must not be less than minLotPrice");

        emit LotPriceRangeUpdated(msg.sender, minLotPrice, maxLotPrice, _minLotPrice, _maxLotPrice);

        minLotPrice = _minLotPrice;
        maxLotPrice = _maxLotPrice;
    }

    /**
     * @dev Restricted access function to update unit price range
     *
     * @param _minUnitPrice minimum unit price
     * @param _maxUnitPrice maximum unit price
     */
    function updateUnitPriceRange(uint256 _minUnitPrice, uint256 _maxUnitPrice) external onlyOwner {
        require(_minUnitPrice > 0, "minUnitPrice not set");
        require(_maxUnitPrice >= _minUnitPrice, "maxUnitPrice must not be less than minUnitPrice");

        emit UnitPriceRangeUpdated(msg.sender, minUnitPrice, maxUnitPrice, _minUnitPrice, _maxUnitPrice);

        minUnitPrice = _minUnitPrice;
        maxUnitPrice = _maxUnitPrice;
    }

    /**
     * @dev Restricted access function to update the platform fee
     *
     * @dev Allows zero recipient only if the fee is also zero
     *
     * @param _feeRecipient fee recipient
     * @param _platformFee platform fee
     */
    function updatePlatformFee(address _feeRecipient, uint16 _platformFee) external onlyOwner {
        require(_feeRecipient != address(0) || _platformFee == 0, "fee recipient not set");
        require(_platformFee <= 1000, "platform fee must not exceed 1000");

        emit PlatformFeeUpdated(msg.sender, feeRecipient, platformFee, _feeRecipient, _platformFee);

        feeRecipient = _feeRecipient;
        platformFee = _platformFee;
    }

    /**
     * @dev Restricted access function to update AddressRegistry contract address
     *
     * @param _addressRegistry AddressRegistry contract address
     */
    function updateAddressRegistry(address _addressRegistry) external onlyOwner {
        require(_addressRegistry != address(0), "address registry not set");

        // emit an event first to log both old and new values
        emit AddressRegistryUpdated(msg.sender, addressRegistry, _addressRegistry);

        // update the value
        addressRegistry = _addressRegistry;
    }

    /**
     * @dev Restricted access function to pause order execution
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Restricted access function to resume order execution
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Verifies payment token (if it's registered), price and quantity of the order
     *
     * @dev Only tokens registered in TokenRegistry are available for the payment.
     *
     * @param _quantity Quantity of items
     * @param _priceTokenAddress Payment token address
     * @param _initialLotPrice Initial lot price
     * @param _initialUnitPrice Initial unit price
     */
    function _verifyPayment(
        uint256 _quantity,
        address _priceTokenAddress,
        uint256 _initialLotPrice,
        uint256 _initialUnitPrice
    ) private view {
        // check payment token
        require(
            ITokenRegistry(IAddressRegistry(addressRegistry).tokenRegistry()).enabled(_priceTokenAddress),
            "invalid payment token"
        );

        // check quantity
        require(_quantity > 0, "zero quantity");

        // check lot price range
        require(maxLotPrice >= _initialLotPrice, "lot price is out of range");
        require(_initialLotPrice >= minLotPrice, "lot price is out of range");

        // check unit price range
        require(maxUnitPrice >= _initialUnitPrice, "unit price is out of range");
        require(_initialUnitPrice >= minUnitPrice, "unit price is out of range");
    }

    /**
     * @dev Checks if order start/end dates are in valid range
     *
     * @param _startsAt order start date
     * @param _expiresAt order end date
     */
    function _verifyOrderDuration(uint256 _startsAt, uint256 _expiresAt) private view {
        require(_expiresAt - _startsAt <= maxOrderDuration, "order duration too big");
    }

    /**
     * @dev Verifies NFT is whitelisted and if it is owned by the address specified,
     *      throws if verification fails
     *
     * @param _tokenAddress NFT contract address
     * @param _tokenId Token ID
     * @param _owner NFT owner address to verify against
     */
    function _verifyNFTAndOwner(
        address _tokenAddress,
        uint256 _tokenId,
        address _owner
    ) private view {
        require(IERC165Upgradeable(_tokenAddress).supportsInterface(INTERFACE_ID_ERC721), "unexpected NFT type");

        require(
            ITokenRegistry(IAddressRegistry(addressRegistry).tokenRegistry()).registeredNFT(_tokenAddress),
            "unexpected NFT address"
        );

        require(IERC721Upgradeable(_tokenAddress).ownerOf(_tokenId) == _owner, "unexpected owner");
    }

    /**
     * @notice Get the current timestamp
     */
    function _getNow() private view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Verifies signature and auction
     *
     * @dev Throws on any error
     *
     * @dev Only owner can accept the bid
     * @dev Only after the auction is ended, bid can be accepted
     *
     * @param _createAuction Auction listed
     * @param _auctionSignature EIP-712 based signature for auction
     */
    function _validateAuction(IAuction.CreateAuction memory _createAuction, bytes memory _auctionSignature)
        private
        view
    {
        // verify signature
        bytes32 createAuctionDigest = _hashTypedDataV4(_hash(_createAuction));
        require(ECDSAUpgradeable.recover(createAuctionDigest, _auctionSignature) == msg.sender, "invalid signature");

        // check timestamp
        require(
            _createAuction.auctionStartsAt <= _createAuction.auctionExpiresAt &&
                _createAuction.auctionExpiresAt <= _getNow(),
            "inactive auction"
        );

        // check nft, ownership, payment and order duration
        _verifyNFTAndOwner(_createAuction.tokenAddress, _createAuction.tokenId, msg.sender);
        _verifyPayment(
            _createAuction.quantity,
            _createAuction.priceTokenAddress,
            _createAuction.auctionInitialLotPrice,
            _createAuction.auctionInitialUnitPrice
        );
        _verifyOrderDuration(_createAuction.auctionStartsAt, _createAuction.auctionExpiresAt);
    }

    /**
     * @notice Validate signature and auction bid
     *
     * @dev Verify signature, current NFT ownership and payment
     * @dev _bidInitialLotPrice must be equal to or greater than _auctionStartsAt
     *
     * @param _auctionStartsAt Auction start time
     * @param _auctionExpiresAt Auction end time
     * @param _auctionInitialLotPrice Auction initial lot price
     * @param _createBid Auction bid listed
     * @param _bidSignature EIP-712 based signature for auction bid
     */
    function _validateBid(
        uint256 _auctionStartsAt,
        uint256 _auctionExpiresAt,
        uint256 _auctionInitialLotPrice,
        IAuction.CreateBid memory _createBid,
        bytes memory _bidSignature
    ) private view {
        // verify signature
        bytes32 createBidDigest = _hashTypedDataV4(_hash(_createBid));
        require(ECDSAUpgradeable.recover(createBidDigest, _bidSignature) == _createBid.buyer, "invalid signature");

        // check timestamp
        require(_createBid.bidStartsAt <= _getNow() && _getNow() <= _createBid.bidExpiresAt, "inactive bid");
        require(
            _auctionStartsAt <= _createBid.bidStartsAt && _createBid.bidStartsAt <= _auctionExpiresAt,
            "inactive bid start time"
        );

        // check payment if _bidInitialLotPrice is equal to or greater than _auctionInitialLotPrice
        // since the ownership and payment was checked in _validateAuction() function,
        // only check the _bidInitialLotPrice to reduce the gas fees
        require(_createBid.bidInitialLotPrice >= _auctionInitialLotPrice, "inactive bid price");

        // check bid lot price
        // since _createBid.bidInitialLotPrice >= _auctionInitialLotPrice && _auctionInitialLotPrice >= minLotPrice,
        // ignore checking if _createBid.bidInitialLotPrice >= minLotPrice
        require(maxLotPrice >= _createBid.bidInitialLotPrice, "lot price is out of range");

        // check bid unit price
        // since _initialUnitPrice >= minUnitPrice, ignore checking if _createBid.bidInitialLotPrice >= minLotPrice
        require(maxUnitPrice >= _createBid.bidInitialUnitPrice, "unit price is out of range");
        require(_createBid.bidInitialUnitPrice >= minUnitPrice, "unit price is out of range");

        // check order duration
        _verifyOrderDuration(_createBid.bidStartsAt, _createBid.bidExpiresAt);
    }

    /**
     * @notice Hash function for English Auction
     *
     * @dev For EIP-712 signature verification
     *
     * @param _createAuction English Auction
     */
    function _hash(IAuction.CreateAuction memory _createAuction) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CREATE_AUCTION_TYPEHASH,
                    _createAuction.tokenAddress,
                    _createAuction.tokenId,
                    _createAuction.quantity,
                    _createAuction.priceTokenAddress,
                    _createAuction.auctionInitialLotPrice,
                    _createAuction.auctionInitialUnitPrice,
                    _createAuction.auctionStartsAt,
                    _createAuction.auctionExpiresAt,
                    _createAuction.auctionNonce
                )
            );
    }

    /**
     * @notice Hash function for English Auction bid
     *
     * @dev For EIP-712 signature verification
     *
     * @param _createBid English Auction bid
     */
    function _hash(IAuction.CreateBid memory _createBid) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CREATE_BID_TYPEHASH,
                    _createBid.auctionHash,
                    _createBid.buyer,
                    _createBid.bidInitialLotPrice,
                    _createBid.bidInitialUnitPrice,
                    _createBid.bidStartsAt,
                    _createBid.bidExpiresAt,
                    _createBid.bidNonce
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title AddressRegistry Contract Interface
 *
 * @notice Define the interface used to get the contract addresses in the Illuvidex
 *
 * @author David Lee
 */

interface IAddressRegistry {
    /**
     * @notice Provide the Marketplace contract address
     *
     * @dev Can be zero in case of the Marketplace contract is not registered
     *
     * @return address Marketplace contract address
     */
    function marketplace() external view returns (address);

    /**
     * @notice Provide the Auction contract address
     *
     * @dev Can be zero in case of the Auction contract is not registered
     *
     * @return address Auction contract address
     */
    function auction() external view returns (address);

    /**
     * @notice Provide the TokenRegistry contract address
     *
     * @dev All the payment tokens are stored in the tokenRegistry contract
     *
     * @dev Can be zero in case of the TokenRegistry contract is not registered
     *
     * @return TokenRegistry contract address
     */
    function tokenRegistry() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMarketplace.sol";

/**
 * @title Auction Contract Interface
 *
 * @notice Define the interface for the structures and the functions in the Auction
 *
 * @author David Lee
 */

interface IAuction {
    /// @dev Structure for English auction
    struct CreateAuction {
        address tokenAddress;
        uint256 tokenId;
        uint256 quantity;
        address priceTokenAddress;
        uint256 auctionInitialLotPrice;
        uint256 auctionInitialUnitPrice;
        uint256 auctionStartsAt;
        uint256 auctionExpiresAt;
        uint256 auctionNonce;
    }

    /// @dev Structure for English auction bid
    struct CreateBid {
        bytes32 auctionHash;
        address buyer;
        uint256 bidInitialLotPrice;
        uint256 bidInitialUnitPrice;
        uint256 bidStartsAt;
        uint256 bidExpiresAt;
        uint256 bidNonce;
    }

    /// @dev Structure for buy order
    struct BuyOrder {
        address buyer;
        address tokenAddress;
        uint256 tokenId;
        uint256 quantity;
        address priceTokenAddress;
        uint256 initialLotPrice;
        uint256 finalLotPrice;
        uint256 initialUnitPrice;
        uint256 finalUnitPrice;
        uint256 startsAt;
        uint256 expiresAt;
        uint256 nonce;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Marketplace Contract Interface
 *
 * @notice Define the interface for the structures and the functions in the Marketplace
 *
 * @author David Lee
 */

interface IMarketplace {
    /// @dev Structure for sell order
    struct SellOrder {
        address owner;
        address tokenAddress;
        uint256 tokenId;
        uint256 quantity;
        address priceTokenAddress;
        uint256 initialLotPrice;
        uint256 finalLotPrice;
        uint256 initialUnitPrice;
        uint256 finalUnitPrice;
        uint256 startsAt;
        uint256 expiresAt;
        uint256 nonce;
    }

    /// @dev Structure for buy order
    struct BuyOrder {
        address buyer;
        address tokenAddress;
        uint256 tokenId;
        uint256 quantity;
        address priceTokenAddress;
        uint256 initialLotPrice;
        uint256 finalLotPrice;
        uint256 initialUnitPrice;
        uint256 finalUnitPrice;
        uint256 startsAt;
        uint256 expiresAt;
        uint256 nonce;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title TokenRegistry Contract Interface
 *
 * @notice Define the interface used to get the token information
 *
 * @author David Lee
 */

interface ITokenRegistry {
    /**
     * @notice Check if the token can be used for the payment
     *
     * @param _token token address to check
     *
     * @return true if the token can be used for the payment
     */
    function enabled(address _token) external view returns (bool);

    /**
     * @notice Check if NFT is registered in the marketplace
     *
     * @dev Only registered NFT can be handled in the marketplace
     *
     * @param _tokenAddress NFT address to check
     *
     * @return bool true: registered, false: unregistered
     */
    function registeredNFT(address _tokenAddress) external view returns (bool);
}