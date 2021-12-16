// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
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

pragma solidity ^0.8.0;

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
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
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
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
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
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IAddressRegistry.sol";
import "./interfaces/ITokenRegistry.sol";

/**
 * @title Marketplace
 *
 * @notice This contract handles normal buy/sell orders and English/Dutch auctions based on EIP-712 signature.
 *
 * @author David Lee
 */

contract Marketplace is OwnableUpgradeable, ReentrancyGuardUpgradeable, EIP712Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSAUpgradeable for bytes32;

    /**
     * @dev Fired in buyItem()
     *
     * @param seller Seller address
     * @param buyer Buyer address
     * @param nft NFT contract address
     * @param tokenId Token ID
     * @param payToken Payment token
     * @param startTime Listing start time
     * @param startPricePerItem Start price per item
     * @param quantity Quantity of itmes
     * @param endTime Listing end time
     * @param endPricePerItem End price per item
     */
    event BuyItem(
        address indexed seller,
        address indexed buyer,
        address indexed nft,
        uint256 tokenId,
        address payToken,
        uint256 startTime,
        uint256 startPricePerItem,
        uint256 quantity,
        uint256 endTime,
        uint256 endPricePerItem
    );

    /**
     * @dev Fired in cancelList()
     *
     * @param owner Owner address
     * @param nft NFT contract address
     * @param tokenId Token ID
     * @param payToken Payment token
     * @param startTime Listing start time
     * @param startPricePerItem Start price per item
     * @param quantity Quantity of itmes
     * @param endTime Listing end time
     * @param endPricePerItem End price per item
     */
    event CancelList(
        address indexed owner,
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 startTime,
        uint256 startPricePerItem,
        uint256 quantity,
        uint256 endTime,
        uint256 endPricePerItem
    );

    /**
     * @dev Fired in acceptOffer()
     *
     * @param seller Seller address
     * @param buyer Buyer address
     * @param nft NFT contract address
     * @param tokenId Token ID
     * @param payToken Payment token
     * @param startTime Offer start time
     * @param startPricePerItem Start price per item
     * @param quantity Quantity of itmes
     * @param endTime Offer end time
     * @param endPricePerItem End price per item
     */
    event AcceptOffer(
        address indexed seller,
        address indexed buyer,
        address indexed nft,
        uint256 tokenId,
        address payToken,
        uint256 startTime,
        uint256 startPricePerItem,
        uint256 quantity,
        uint256 endTime,
        uint256 endPricePerItem
    );

    /**
     * @dev Fired in cancelOffer()
     *
     * @param seller Seller address
     * @param buyer Buyer address
     * @param nft NFT contract address
     * @param tokenId Token ID
     * @param payToken Payment token
     * @param startTime Listing start time
     * @param startPricePerItem Start price per item
     * @param quantity Quantity of itmes
     * @param endTime Listing end time
     * @param endPricePerItem End price per item
     */
    event CancelOffer(
        address indexed seller,
        address indexed buyer,
        address indexed nft,
        uint256 tokenId,
        address payToken,
        uint256 startTime,
        uint256 startPricePerItem,
        uint256 quantity,
        uint256 endTime,
        uint256 endPricePerItem
    );

    /**
     * @dev Fired in acceptBid()
     *
     * @param seller Seller address
     * @param buyer Buyer address
     * @param nft NFT contract address
     * @param tokenId Token ID
     * @param payToken Payment token
     * @param auctionStartTime Auction start time
     * @param auctionStartPricePerItem Auction start price per item
     * @param quantity Quantity of itmes
     * @param auctionEndTime Auction end time
     * @param bidStartTime Bid start time
     * @param bidPricePerItem Bid price per item
     * @param bidEndTime Bid end time
     */
    event AcceptBid(
        address indexed seller,
        address indexed buyer,
        address indexed nft,
        uint256 tokenId,
        address payToken,
        uint256 auctionStartTime,
        uint256 auctionStartPricePerItem,
        uint256 quantity,
        uint256 auctionEndTime,
        uint256 bidStartTime,
        uint256 bidPricePerItem,
        uint256 bidEndTime
    );

    /**
     * @dev Fired in cancelAuction()
     *
     * @param owner Owner address
     * @param nft NFT contract address
     * @param tokenId Token ID
     * @param payToken Payment token
     * @param auctionStartTime Auction start time
     * @param auctionStartPricePerItem Auction price per item
     * @param quantity Quantity of itmes
     * @param auctionEndTime Auction end time
     */
    event CancelAuction(
        address indexed owner,
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 auctionStartTime,
        uint256 auctionStartPricePerItem,
        uint256 quantity,
        uint256 auctionEndTime
    );

    /**
     * @dev Fired in cancelBid()
     *
     * @param owner Owner address
     * @param buyer Buyer address
     * @param nft NFT contract address
     * @param tokenId Token ID
     * @param payToken Payment token
     * @param auctionStartTime Auction start time
     * @param auctionStartPricePerItem Auction start price per item
     * @param quantity Quantity of itmes
     * @param auctionEndTime Auction end time
     * @param bidStartTime Bid start time
     * @param bidPricePerItem Bid price per item
     * @param bidEndTime Bid end time
     */
    event CancelBid(
        address indexed owner,
        address indexed buyer,
        address indexed nft,
        uint256 tokenId,
        address payToken,
        uint256 auctionStartTime,
        uint256 auctionStartPricePerItem,
        uint256 quantity,
        uint256 auctionEndTime,
        uint256 bidStartTime,
        uint256 bidPricePerItem,
        uint256 bidEndTime
    );

    /**
     * @dev Fired in updatePlatformFee()
     *
     * @param platformFee Platform fee updated
     */
    event UpdatePlatformFee(uint256 platformFee);

    /**
     * @dev Fired in updatePlatformFeeRecipient()
     *
     * @param feeRecipient Platform fee recipient updated
     */
    event UpdatePlatformFeeRecipient(address feeRecipient);

    /**
     * @dev Fired in updateAddressRegistry()
     *
     * @param addressRegistry AddressRegistry contract address updated
     */
    event UpdateAddressRegistry(address addressRegistry);

    /// @dev Structure for listed items
    struct ListItem {
        address nftAddress;
        uint256 tokenId;
        address owner;
        address payToken;
        uint256 startTime;
        uint256 startPricePerItem;
        uint256 quantity;
        uint256 endTime;
        uint256 endPricePerItem;
        uint256 nonce;
    }

    /// @dev Structure for offer
    struct CreateOffer {
        address nftAddress;
        uint256 tokenId;
        address owner;
        address buyer;
        address payToken;
        uint256 startTime;
        uint256 startPricePerItem;
        uint256 quantity;
        uint256 endTime;
        uint256 endPricePerItem;
        uint256 nonce;
    }

    /// @dev Structure for English auction
    struct CreateAuction {
        address nftAddress;
        uint256 tokenId;
        address owner;
        address payToken;
        uint256 auctionStartTime;
        uint256 auctionStartPricePerItem;
        uint256 quantity;
        uint256 auctionEndTime;
        uint256 auctionNonce;
    }

    /// @dev Structure for English auction bid
    struct CreateBid {
        address nftAddress;
        uint256 tokenId;
        address owner;
        address payToken;
        uint256 auctionStartTime;
        uint256 auctionStartPricePerItem;
        uint256 quantity;
        uint256 auctionEndTime;
        address buyer;
        uint256 bidStartTime;
        uint256 bidPricePerItem;
        uint256 bidEndTime;
        uint256 bidNonce;
    }

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @dev ListItem Typehash for EIP-712 signature
    bytes32 private constant LISTITEM_TYPEHASH =
        keccak256(
            "ListItem(address nftAddress,uint256 tokenId,address owner,address payToken,uint256 startTime,"
            "uint256 startPricePerItem,uint256 quantity,uint256 endTime,uint256 endPricePerItem,uint256 nonce)"
        );

    /// @dev CreateOffer Typehash for EIP-712 signature
    bytes32 private constant CREATEOFFER_TYPEHASH =
        keccak256(
            "CreateOffer(address nftAddress,uint256 tokenId,address owner,address buyer,address payToken,"
            "uint256 startTime,uint256 startPricePerItem,uint256 quantity,uint256 endTime,"
            "uint256 endPricePerItem,uint256 nonce)"
        );

    /// @dev CreateAuction Typehash for EIP-712 signature
    bytes32 private constant CREATEAUCTION_TYPEHASH =
        keccak256(
            "CreateAuction(address nftAddress,uint256 tokenId,address owner,address payToken,uint256 auctionStartTime,"
            "uint256 auctionStartPricePerItem,uint256 quantity,uint256 auctionEndTime,uint256 auctionNonce)"
        );

    /// @dev CreateBid Typehash for EIP-712 signature
    bytes32 private constant CREATEBID_TYPEHASH =
        keccak256(
            "CreateBid(address nftAddress,uint256 tokenId,address owner,address payToken,uint256 auctionStartTime,"
            "uint256 auctionStartPricePerItem,uint256 quantity,uint256 auctionEndTime,"
            "address buyer,uint256 bidStartTime,uint256 bidPricePerItem,uint256 bidEndTime,uint256 bidNonce)"
        );

    /// @dev Platform fee
    uint256 public platformFee;

    /// @dev Platform fee recipient
    address public feeRecipient;

    /// @dev Address registry
    IAddressRegistry public addressRegistry;

    /// @dev User -> Nonce -> Bool
    mapping(address => mapping(uint256 => bool)) public isUsedNonce;

    /// @dev User -> Nonce
    mapping(address => uint256) public nonce;

    function initialize(address _feeRecipient, uint256 _platformFee) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __EIP712_init("Illuvidex Marketplace", "1");

        require(_feeRecipient != address(0), "Invalid fee recipient");

        feeRecipient = _feeRecipient;
        platformFee = _platformFee;
    }

    /**
     * @notice Buy NFT listed
     *
     * @dev Only if the signature and sell order are verified, NFT must be transferred.
     * @dev In case of Dutch auction, _startPricePerItem will be higher than _endPricerPerItem.
     *
     * @param _listItem Sell order listed
     * @param _signature EIP-712 based signature
     */
    function buyItem(ListItem memory _listItem, bytes memory _signature) external nonReentrant {
        // validate order
        _validateList(_listItem, _signature);

        // mark nonce
        require(!isUsedNonce[_listItem.owner][_listItem.nonce], "Used nonce");
        isUsedNonce[_listItem.owner][_listItem.nonce] = true;

        // execute order
        _buyItem(_listItem);

        emit BuyItem(
            _listItem.owner,
            msg.sender,
            _listItem.nftAddress,
            _listItem.tokenId,
            _listItem.payToken,
            _listItem.startTime,
            _listItem.startPricePerItem,
            _listItem.quantity,
            _listItem.endTime,
            _listItem.endPricePerItem
        );
    }

    /**
     * @notice Transfer NFT
     *
     * @dev fees will be deducted and transferred to the feeRecipient address.
     *
     * @param _listItem Sell order listed
     */
    function _buyItem(ListItem memory _listItem) private {
        // calculate payment amount
        uint256 pricePerItem = _listItem.startPricePerItem -
            ((_listItem.startPricePerItem - _listItem.endPricePerItem) / (_listItem.endTime - _listItem.startTime)) *
            (_getNow() - _listItem.startTime);
        uint256 totalPrice = _listItem.quantity * pricePerItem;
        uint256 feeAmount = totalPrice * (platformFee / 1000);
        uint256 ownerAmount = totalPrice - feeAmount;

        // trasnfer payment
        IERC20Upgradeable(_listItem.payToken).safeTransferFrom(msg.sender, feeRecipient, feeAmount);
        IERC20Upgradeable(_listItem.payToken).safeTransferFrom(msg.sender, _listItem.owner, ownerAmount);

        // transfer NFT
        IERC721Upgradeable(_listItem.nftAddress).safeTransferFrom(_listItem.owner, msg.sender, _listItem.tokenId);
    }

    /**
     * @notice Cancel listing NFT
     *
     * @dev Only signer can cancel the order
     *
     * @param _listItem Sell order listed
     * @param _signature EIP-712 based signature
     */
    function cancelList(ListItem memory _listItem, bytes memory _signature) external {
        // verify signature
        bytes32 listItemDigest = _hashTypedDataV4(_hash(_listItem));
        require(ECDSAUpgradeable.recover(listItemDigest, _signature) == msg.sender, "!Signature");

        // mark nonce
        require(!isUsedNonce[_listItem.owner][_listItem.nonce], "Cancelled nonce");
        isUsedNonce[_listItem.owner][_listItem.nonce] = true;

        emit CancelList(
            msg.sender,
            _listItem.nftAddress,
            _listItem.tokenId,
            _listItem.payToken,
            _listItem.startTime,
            _listItem.startPricePerItem,
            _listItem.quantity,
            _listItem.endTime,
            _listItem.endPricePerItem
        );
    }

    /**
     * @notice Accept buy order
     *
     * @dev Only if the signature and buy order are verifed, NFT must be transferred.
     *
     * @param _createOffer Buy order listed
     * @param _signature EIP-712 based signature
     */
    function acceptOffer(CreateOffer memory _createOffer, bytes memory _signature) external nonReentrant {
        // validate offer
        _validateOffer(_createOffer, _signature);

        // mark nonce
        require(!isUsedNonce[_createOffer.buyer][_createOffer.nonce], "Used nonce");
        isUsedNonce[_createOffer.buyer][_createOffer.nonce] = true;

        // accept offer
        _acceptOffer(_createOffer);

        emit AcceptOffer(
            msg.sender,
            _createOffer.buyer,
            _createOffer.nftAddress,
            _createOffer.tokenId,
            _createOffer.payToken,
            _createOffer.startTime,
            _createOffer.startPricePerItem,
            _createOffer.quantity,
            _createOffer.endTime,
            _createOffer.endPricePerItem
        );
    }

    /**
     * @notice Transfer NFT
     *
     * @dev fees will be deducted and transferred to the feeRecipient address.
     *
     * @param _createOffer Buy order listed
     */
    function _acceptOffer(CreateOffer memory _createOffer) private {
        // calculate payment amount
        uint256 pricePerItem = _createOffer.startPricePerItem -
            ((_createOffer.startPricePerItem - _createOffer.endPricePerItem) /
                (_createOffer.endTime - _createOffer.startTime)) *
            (_getNow() - _createOffer.startTime);
        uint256 totalPrice = _createOffer.quantity * pricePerItem;
        uint256 feeAmount = (totalPrice * platformFee) / 1000;
        uint256 ownerAmount = totalPrice - feeAmount;

        // trasnfer payment
        IERC20Upgradeable(_createOffer.payToken).safeTransferFrom(_createOffer.buyer, feeRecipient, feeAmount);
        IERC20Upgradeable(_createOffer.payToken).safeTransferFrom(_createOffer.buyer, msg.sender, ownerAmount);

        // transfer NFT
        IERC721Upgradeable(_createOffer.nftAddress).safeTransferFrom(
            msg.sender,
            _createOffer.buyer,
            _createOffer.tokenId
        );
    }

    /**
     * @notice Cancel Offer
     *
     * @dev Only signer can cancel the order
     *
     * @param _createOffer Buy order listed
     * @param _signature EIP-712 based signature
     */
    function cancelOffer(CreateOffer memory _createOffer, bytes memory _signature) external {
        // verify signature
        bytes32 createOfferDigest = _hashTypedDataV4(_hash(_createOffer));
        require(ECDSAUpgradeable.recover(createOfferDigest, _signature) == msg.sender, "!Signature");

        // mark nonce
        require(!isUsedNonce[_createOffer.buyer][_createOffer.nonce], "Cancelled nonce");
        isUsedNonce[_createOffer.buyer][_createOffer.nonce] = true;

        emit CancelOffer(
            _createOffer.owner,
            msg.sender,
            _createOffer.nftAddress,
            _createOffer.tokenId,
            _createOffer.payToken,
            _createOffer.startTime,
            _createOffer.startPricePerItem,
            _createOffer.quantity,
            _createOffer.endTime,
            _createOffer.endPricePerItem
        );
    }

    /**
     * @notice Accept English auction bid
     *
     * @dev Only if the signature and bid are verifed, NFT must be transferred.
     *
     * @param _createAuction Auction created
     * @param _createBid Auction bid created
     * @param _auctionSignature EIP-712 based signature for Auction
     * @param _bidSignature EIP-712 based signature for Auction bid
     */
    function acceptBid(
        CreateAuction memory _createAuction,
        CreateBid memory _createBid,
        bytes memory _auctionSignature,
        bytes memory _bidSignature
    ) external nonReentrant {
        // validate auction
        _validateAuction(_createAuction, _auctionSignature);

        // validate auction bid
        _validateBid(_createBid, _bidSignature);

        // mark nonce for auction
        require(!isUsedNonce[_createAuction.owner][_createAuction.auctionNonce], "Used nonce");
        isUsedNonce[_createAuction.owner][_createAuction.auctionNonce] = true;

        // mark nonce for auction bid
        require(!isUsedNonce[_createBid.buyer][_createBid.bidNonce], "Used nonce");
        isUsedNonce[_createBid.buyer][_createBid.bidNonce] = true;

        // accept auction bid, use acceptOffer() function to reduce the contract size
        _acceptOffer(
            CreateOffer({
                nftAddress: _createBid.nftAddress,
                tokenId: _createBid.tokenId,
                owner: _createBid.owner,
                buyer: _createBid.buyer,
                payToken: _createBid.payToken,
                startTime: _createBid.bidStartTime,
                startPricePerItem: _createBid.bidPricePerItem,
                quantity: _createBid.quantity,
                endTime: _createBid.bidEndTime,
                endPricePerItem: _createBid.bidPricePerItem,
                nonce: _createBid.bidPricePerItem
            })
        );

        emit AcceptBid(
            msg.sender,
            _createBid.buyer,
            _createBid.nftAddress,
            _createBid.tokenId,
            _createBid.payToken,
            _createBid.auctionStartTime,
            _createBid.auctionStartPricePerItem,
            _createBid.quantity,
            _createBid.auctionEndTime,
            _createBid.bidStartTime,
            _createBid.bidPricePerItem,
            _createBid.bidEndTime
        );
    }

    /**
     * @notice Cancel English auction
     *
     * @dev Only signer can cancel the order
     *
     * @param _createAuction Auction created
     * @param _signature EIP-712 based signature
     */
    function cancelAuction(CreateAuction memory _createAuction, bytes memory _signature) external {
        // verify signature
        bytes32 createAuctionDigest = _hashTypedDataV4(_hash(_createAuction));
        require(ECDSAUpgradeable.recover(createAuctionDigest, _signature) == msg.sender, "!Signature");

        // mark nonce
        require(!isUsedNonce[_createAuction.owner][_createAuction.auctionNonce], "Cancelled nonce");
        isUsedNonce[_createAuction.owner][_createAuction.auctionNonce] = true;

        emit CancelAuction(
            msg.sender,
            _createAuction.nftAddress,
            _createAuction.tokenId,
            _createAuction.payToken,
            _createAuction.auctionStartTime,
            _createAuction.auctionStartPricePerItem,
            _createAuction.quantity,
            _createAuction.auctionEndTime
        );
    }

    /**
     * @notice Cancel English auction Bid
     *
     * @dev Only signer can cancel the order
     *
     * @param _createBid Auction bid listed
     * @param _bidSignature EIP-712 based signature for auction bid
     */
    function cancelBid(CreateBid memory _createBid, bytes memory _bidSignature) external {
        // verify signature
        bytes32 createOfferDigest = _hashTypedDataV4(_hash(_createBid));
        require(ECDSAUpgradeable.recover(createOfferDigest, _bidSignature) == msg.sender, "!Signature");

        // mark nonce
        require(!isUsedNonce[_createBid.buyer][_createBid.bidNonce], "Cancelled nonce");
        isUsedNonce[_createBid.buyer][_createBid.bidNonce] = true;

        emit CancelBid(
            _createBid.owner,
            _createBid.buyer,
            _createBid.nftAddress,
            _createBid.tokenId,
            _createBid.payToken,
            _createBid.auctionStartTime,
            _createBid.auctionStartPricePerItem,
            _createBid.quantity,
            _createBid.auctionEndTime,
            _createBid.bidStartTime,
            _createBid.bidPricePerItem,
            _createBid.bidEndTime
        );
    }

    /**
     * @notice Update platform fee
     *
     * @dev Only owner
     *
     * @param _platformFee platform fee
     */
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;

        emit UpdatePlatformFee(_platformFee);
    }

    /**
     * @notice Update platform fee recipient address
     *
     * @dev Only owner
     *
     * @param _feeRecipient fee recipient address
     */
    function updatePlatformFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;

        emit UpdatePlatformFeeRecipient(_feeRecipient);
    }

    /**
     * @notice Update AddressRegistry contract address
     *
     * @dev Only owner
     *
     * @param _addressRegistry AddressRegistry contract address
     */
    function updateAddressRegistry(address _addressRegistry) external onlyOwner {
        addressRegistry = IAddressRegistry(_addressRegistry);

        emit UpdateAddressRegistry(_addressRegistry);
    }

    /**
     * @notice Get the current timestamp
     */
    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Validate signature and sell order
     *
     * @dev Verify signature, current NFT ownership and payment
     *
     * @param _listItem Sell order listed
     * @param _signature EIP-712 based signature
     */
    function _validateList(ListItem memory _listItem, bytes memory _signature) internal view {
        // verify signature
        bytes32 listItemDigest = _hashTypedDataV4(_hash(_listItem));
        require(ECDSAUpgradeable.recover(listItemDigest, _signature) == _listItem.owner, "!Signature");

        // check timestamp
        require(_listItem.startTime <= _getNow() && _getNow() <= _listItem.endTime, "Invalid list");

        // check ownership and payment
        _validOwner(_listItem.nftAddress, _listItem.tokenId, _listItem.owner);
        _validPayment(_listItem.payToken, _listItem.startPricePerItem, _listItem.quantity, _listItem.endPricePerItem);
    }

    /**
     * @notice Validate signature and buy order
     *
     * @dev Verify signature, current NFT ownership and payment
     * @dev _startPricePerItem must be equal to _endPricePerItem
     * @dev Only owner can accept the offer
     *
     * @param _createOffer Buy order listed
     * @param _signature EIP-712 based signature
     */
    function _validateOffer(CreateOffer memory _createOffer, bytes memory _signature) internal view {
        // verify signature
        bytes32 createOfferDigest = _hashTypedDataV4(_hash(_createOffer));
        require(ECDSAUpgradeable.recover(createOfferDigest, _signature) == _createOffer.buyer, "!Signature");

        // check timestamp
        require(_createOffer.startTime <= _getNow() && _getNow() <= _createOffer.endTime, "Invalid offer");

        // check if _startPricePerItem is equal to _endPricePerItem
        require(_createOffer.startPricePerItem == _createOffer.endPricePerItem, "Invalid price");

        // check ownership and payment
        _validOwner(_createOffer.nftAddress, _createOffer.tokenId, _createOffer.owner);
        _validPayment(
            _createOffer.payToken,
            _createOffer.startPricePerItem,
            _createOffer.quantity,
            _createOffer.endPricePerItem
        );

        // only owner can accept the offer
        require(_createOffer.owner == msg.sender, "No owner");
    }

    /**
     * @notice Validate signature and auction
     *
     * @dev Verify signature, current NFT ownership and payment
     * @dev Only owner can accept the bid
     * @dev Only after the auction is ended, bid can be accepted
     *
     * @param _createAuction Auction listed
     * @param _auctionSignature EIP-712 based signature for auction
     */
    function _validateAuction(CreateAuction memory _createAuction, bytes memory _auctionSignature) internal view {
        // verify signature
        bytes32 createAuctionDigest = _hashTypedDataV4(_hash(_createAuction));
        require(ECDSAUpgradeable.recover(createAuctionDigest, _auctionSignature) == _createAuction.owner, "!Signature");

        // check timestamp
        require(
            _createAuction.auctionStartTime <= _createAuction.auctionEndTime &&
                _createAuction.auctionEndTime <= _getNow(),
            "Invalid auction"
        );

        // check ownership and payment
        _validOwner(_createAuction.nftAddress, _createAuction.tokenId, _createAuction.owner);
        _validPayment(
            _createAuction.payToken,
            _createAuction.auctionStartPricePerItem,
            _createAuction.quantity,
            _createAuction.auctionStartPricePerItem
        );

        // only owner can accept the bid
        require(_createAuction.owner == msg.sender, "No owner");
    }

    /**
     * @notice Validate signature and auction bid
     *
     * @dev Verify signature, current NFT ownership and payment
     * @dev _bidPricePerItem must be equal to or greater than _auctionStartTime
     *
     * @param _createBid Auction bid listed
     * @param _bidSignature EIP-712 based signature for auction bid
     */
    function _validateBid(CreateBid memory _createBid, bytes memory _bidSignature) internal view {
        // verify signature
        bytes32 createBidDigest = _hashTypedDataV4(_hash(_createBid));
        require(ECDSAUpgradeable.recover(createBidDigest, _bidSignature) == _createBid.buyer, "!Signature");

        // check timestamp
        require(_createBid.bidStartTime <= _getNow() && _getNow() <= _createBid.bidEndTime, "Invalid bid");
        require(
            _createBid.auctionStartTime <= _createBid.bidStartTime &&
                _createBid.bidStartTime <= _createBid.auctionEndTime,
            "Invalid bid start time"
        );

        // check payment if _bidPricePerItem is equal to or greater than _auctionStartPricePerItem
        // since the ownership and payment was checked in _validateAuction() function,
        // only check the _bidPricePerItem to reduce the gas fees
        require(_createBid.bidPricePerItem >= _createBid.auctionStartPricePerItem, "Invalid bid price");
    }

    /**
     * @notice Validate payment token, price and quantity of buy/sell order
     *
     * @dev Only tokens registered in TokenRegistry are available for the payment.
     *
     * @param _payToken Payment token
     * @param _startPricePerItem Start price per item
     * @param _quantity Quantity of items
     * @param _endPricePerItem End price per item
     */
    function _validPayment(
        address _payToken,
        uint256 _startPricePerItem,
        uint256 _quantity,
        uint256 _endPricePerItem
    ) internal view {
        require(
            (addressRegistry.tokenRegistry() != address(0) &&
                ITokenRegistry(addressRegistry.tokenRegistry()).enabled(_payToken)),
            "Invalid pay token"
        );
        require(_quantity > 0, "Invalid quantity");
        require(_startPricePerItem >= _endPricePerItem && _endPricePerItem > 0, "Invalid price range");
    }

    /**
     * @notice Validate NFT owner
     *
     * @param _nftAddress NFT contract address
     * @param _tokenId Token ID
     * @param _owner NFT owner address
     */
    function _validOwner(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) internal view {
        if (IERC165Upgradeable(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721Upgradeable nft = IERC721Upgradeable(_nftAddress);
            require(nft.ownerOf(_tokenId) == _owner, "Not owning item");
        } else {
            revert("Invalid nft address");
        }
    }

    /**
     * @notice Hash function for sell order
     *
     * @dev For EIP-712 signature verification
     *
     * @param _listItem Sell order
     */
    function _hash(ListItem memory _listItem) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    LISTITEM_TYPEHASH,
                    _listItem.nftAddress,
                    _listItem.tokenId,
                    _listItem.owner,
                    _listItem.payToken,
                    _listItem.startTime,
                    _listItem.startPricePerItem,
                    _listItem.quantity,
                    _listItem.endTime,
                    _listItem.endPricePerItem,
                    _listItem.nonce
                )
            );
    }

    /**
     * @notice Hash function for buy order
     *
     * @dev For EIP-712 signature verification
     *
     * @param _createOffer Buy order
     */
    function _hash(CreateOffer memory _createOffer) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CREATEOFFER_TYPEHASH,
                    _createOffer.nftAddress,
                    _createOffer.tokenId,
                    _createOffer.owner,
                    _createOffer.buyer,
                    _createOffer.payToken,
                    _createOffer.startTime,
                    _createOffer.startPricePerItem,
                    _createOffer.quantity,
                    _createOffer.endTime,
                    _createOffer.endPricePerItem,
                    _createOffer.nonce
                )
            );
    }

    /**
     * @notice Hash function for English auction
     *
     * @dev For EIP-712 signature verification
     *
     * @param _createAuction English auction
     */
    function _hash(CreateAuction memory _createAuction) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CREATEAUCTION_TYPEHASH,
                    _createAuction.nftAddress,
                    _createAuction.tokenId,
                    _createAuction.owner,
                    _createAuction.payToken,
                    _createAuction.auctionStartTime,
                    _createAuction.auctionStartPricePerItem,
                    _createAuction.quantity,
                    _createAuction.auctionEndTime,
                    _createAuction.auctionNonce
                )
            );
    }

    /**
     * @notice Hash function for English auction bid
     *
     * @dev For EIP-712 signature verification
     *
     * @param _createBid English Auction bid
     */
    function _hash(CreateBid memory _createBid) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CREATEBID_TYPEHASH,
                    _createBid.nftAddress,
                    _createBid.tokenId,
                    _createBid.owner,
                    _createBid.payToken,
                    _createBid.auctionStartTime,
                    _createBid.auctionStartPricePerItem,
                    _createBid.quantity,
                    _createBid.auctionEndTime,
                    _createBid.buyer,
                    _createBid.bidStartTime,
                    _createBid.bidPricePerItem,
                    _createBid.bidEndTime,
                    _createBid.bidNonce
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * @title AddressRegistry Contract Interface
 *
 * @notice Define the interface used to get each of the contract addresses used in the Marketplace
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
pragma solidity >=0.8.4;

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
}