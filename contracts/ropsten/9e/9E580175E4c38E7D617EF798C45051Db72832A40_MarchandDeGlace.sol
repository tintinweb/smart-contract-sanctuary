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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
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
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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
pragma solidity 0.8.7;

import {Proxied} from "../vendor/hardhat-deploy/Proxied.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    _withdrawETH,
    _withdrawUnlockedGEL,
    _withdrawAllGEL
} from "./functions/ProxyAdminFunctions.sol";
import {
    _isPoolOneOpen,
    _requirePoolOneIsOpen,
    _hasWhaleNeverBought,
    _requireWhaleNeverBought,
    _isBoughtWithinWhaleCaps,
    _requireBoughtWithinWhaleCaps,
    _isPoolOneCapExceeded,
    _requirePoolOneCapNotExceeded,
    _isPoolTwoOpen,
    _requirePoolTwoIsOpen,
    _hasDolphinNeverBought,
    _requireDolphinNeverBought,
    _isBoughtLteDolphinMax,
    _requireBoughtLteDolphinMax,
    _getRemainingGel,
    _isSaleClosing,
    _isBoughtEqRemaining,
    _requireBoughtEqRemaining,
    _isBoughtGteDolphinMin,
    _requireBoughtGteDolphinMin,
    _isBoughtLteRemaining,
    _requireBoughtLteRemaining,
    _requireNotAddressZero,
    _requireNotLocked,
    _requireHasGELToUnlock
} from "./functions/CheckerFunctions.sol";
import {
    _isWhale,
    _requireWhale,
    _isDolphin,
    _requireDolphin
} from "./functions/SignatureFunctions.sol";
import {_wmul} from "../vendor/DSMath.sol";

// BE CAREFUL: DOT NOT CHANGE THE ORDER OF INHERITED CONTRACT
// solhint-disable-next-line max-states-count
contract MarchandDeGlace is
    Initializable,
    Proxied,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    // solhint-disable-next-line max-line-length
    ////////////////////////////////////////// CONSTANTS AND IMMUTABLES ///////////////////////////////////

    ///@dev GEL_TOTAL_SUPPLY 420,690,000.00
    /// TOTAL_GEL_CAP = GEL_TOTAL_SUPPLY * 4%
    uint256 public constant TOTAL_GEL_CAP = 16827600000000000000000000;

    ///@dev POOL_ONE_GEL_CAP = TOTAL_GEL_CAP * (3/5);
    uint256 public constant POOL_ONE_GEL_CAP = 10096560000000000000000000;

    ///@dev GELUSD = 0.2971309 $ and WHALE_MIN_USD = 5000 $
    /// WHALE_POOL_USD_PRICE = POOL_ONE_GEL_CAP * GELUSD
    /// we know that WHALE_MIN_USD / WHALE_POOL_USD_PRICE = WHALE_MIN_GEL / POOL_ONE_GEL_CAP
    /// so WHALE_MIN_GEL = ( WHALE_MIN_USD / WHALE_POOL_USD_PRICE ) * POOL_ONE_GEL_CAP
    uint256 public constant WHALE_MIN_GEL = 16827600226028326236012;

    ///@dev WHALE_MAX_USD = 20000 $, with same reasoning
    /// we know that WHALE_MAX_USD / WHALE_POOL_USD_PRICE = WHALE_MAX_GEL / POOL_ONE_GEL_CAP
    /// so WHALE_MAX_GEL = ( WHALE_MAX_USD / WHALE_POOL_USD_PRICE ) * POOL_ONE_GEL_CAP
    uint256 public constant WHALE_MAX_GEL = 67310400904113304944050;

    ///@dev DOLPHIN_MIN_USD = 1000 $ and DOLPHIN_POOL_GEL = 6731040
    /// DOLPHIN_POOL_USD_PRICE = DOLPHIN_POOL_GEL * GELUSD
    /// we know that DOLPHIN_MIN_USD / DOLPHIN_POOL_USD_PRICE = DOLPHIN_MIN_GEL / DOLPHIN_POOL_GEL
    /// so DOLPHIN_MIN_GEL = ( DOLPHIN_MIN_USD / DOLPHIN_POOL_USD_PRICE ) * DOLPHIN_POOL_GEL
    uint256 public constant DOLPHIN_MIN_GEL = 3365520045205665247202;

    ///@dev DOLPHIN_MAX_USD = 4000 $, with same reasoning
    /// we know that DOLPHIN_MAX_USD / DOLPHIN_POOL_USD_PRICE = DOLPHIN_MAX_GEL / DOLPHIN_POOL_GEL
    /// so DOLPHIN_MAX_GEL = ( DOLPHIN_MAX_USD / DOLPHIN_POOL_USD_PRICE ) * DOLPHIN_POOL_GEL
    uint256 public constant DOLPHIN_MAX_GEL = 13462080180822660988810;

    // Token that Marchand De Glace Sell.
    IERC20 public immutable GEL; // solhint-disable-line var-name-mixedcase

    // Address signing user signature.
    address public immutable SIGNER; // solhint-disable-line var-name-mixedcase

    // solhint-disable-next-line max-line-length
    /////////////////////////////////////////// STORAGE DATA //////////////////////////////////////////////////

    // !!!!!!!!!!!!!!!!!!!!!!!! DO NOT CHANGE ORDER !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    // Only settable by the Admin
    uint256 public gelPerEth;
    uint256 public poolOneStartTime;
    uint256 public poolTwoStartTime;
    uint256 public poolOneEndTime;
    uint256 public poolTwoEndTime;
    uint256 public lockUpEndTime;

    mapping(address => uint256) public gelLockedByWhale;
    mapping(address => uint256) public gelBoughtByDolphin;
    uint256 public totalGelLocked;

    // !!!!!!!! ADD NEW PROPERTIES HERE !!!!!!!

    event LogBuyWhale(
        address indexed whale,
        uint256 ethPaid,
        uint256 gelBought,
        uint256 gelLocked,
        uint256 gelUnlocked
    );
    event LogBuyDolphin(
        address indexed dolphin,
        uint256 ethPaid,
        uint256 gelBought
    );
    event LogWithdrawLockedGEL(
        address indexed whale,
        address indexed to,
        uint256 gelWithdrawn
    );

    // solhint-disable-next-line func-param-name-mixedcase, var-name-mixedcase
    constructor(IERC20 _GEL, address _SIGNER) {
        GEL = _GEL;
        SIGNER = _SIGNER;
    }

    function initialize(
        uint256 _gelPerEth,
        uint256 _poolOneStartTime,
        uint256 _poolTwoStartTime,
        uint256 _poolOneEndTime,
        uint256 _poolTwoEndTime,
        uint256 _lockUpEndTime
    ) external initializer {
        require(_gelPerEth > 0, "Ether to Gel price cannot be settable to 0");
        require(
            _poolOneStartTime <= _poolOneEndTime,
            "Pool One phase cannot end before the start"
        );
        require(
            _poolOneEndTime <= _poolTwoStartTime,
            "Pool One phase should be closed for starting pool two"
        );
        require(
            _poolTwoStartTime <= _poolTwoEndTime,
            "Pool Two phase cannot end before the start"
        );
        require(
            _poolOneEndTime + 182 days <= _lockUpEndTime,
            "Lockup should end at least 6 months after pool one phase 1 ending"
        );
        __ReentrancyGuard_init();
        __Pausable_init();
        gelPerEth = _gelPerEth;
        poolOneStartTime = _poolOneStartTime;
        poolTwoStartTime = _poolTwoStartTime;
        poolOneEndTime = _poolOneEndTime;
        poolTwoEndTime = _poolTwoEndTime;
        lockUpEndTime = _lockUpEndTime;
    }

    // We are using onlyProxyAdmin, because admin = owner,
    // Proxied get admin from storage position
    // 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
    // and EIP173Proxy store owner at same position.
    // https://github.com/wighawag/hardhat-deploy/blob/master/solc_0.7/proxy/EIP173Proxy.sol
    function setGelPerEth(uint256 _gelPerEth) external onlyProxyAdmin {
        gelPerEth = _gelPerEth;
    }

    function setPhaseOneStartTime(uint256 _poolOneStartTime)
        external
        onlyProxyAdmin
    {
        poolOneStartTime = _poolOneStartTime;
    }

    function setPhaseTwoStartTime(uint256 _poolTwoStartTime)
        external
        onlyProxyAdmin
    {
        poolTwoStartTime = _poolTwoStartTime;
    }

    function setPhaseOneEndTime(uint256 _poolOneEndTime)
        external
        onlyProxyAdmin
    {
        poolOneEndTime = _poolOneEndTime;
    }

    function setPhaseTwoEndTime(uint256 _poolTwoEndTime)
        external
        onlyProxyAdmin
    {
        poolTwoEndTime = _poolTwoEndTime;
    }

    function setLockUpEndTime(uint256 _lockUpEndTime) external onlyProxyAdmin {
        lockUpEndTime = _lockUpEndTime;
    }

    function pause() external onlyProxyAdmin {
        _pause();
    }

    function unpause() external onlyProxyAdmin {
        _unpause();
    }

    function withdrawETH() external onlyProxyAdmin {
        _withdrawETH(_proxyAdmin(), address(this).balance);
    }

    function withdrawUnlockedGEL() external onlyProxyAdmin {
        _withdrawUnlockedGEL(
            GEL,
            _proxyAdmin(),
            GEL.balanceOf(address(this)),
            totalGelLocked
        );
    }

    function withdrawAllGEL() external onlyProxyAdmin whenPaused {
        _withdrawAllGEL(GEL, _proxyAdmin(), GEL.balanceOf(address(this)));
    }

    // !!!!!!!!!!!!!!!!!!!!! FUNCTIONS CALLABLE BY WHALES AND DOLPHINS !!!!!!!!!!!!!!!!!!!!!!!!!

    function buyWhale(bytes calldata _signature)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        _requirePoolOneIsOpen(poolOneStartTime, poolOneEndTime);
        _requireWhale(_signature, SIGNER);
        _requireWhaleNeverBought(gelLockedByWhale[msg.sender]);

        // Amount of gel bought
        // TODO check precision issue here.
        uint256 gelBought = _wmul(msg.value, gelPerEth);

        _requireBoughtWithinWhaleCaps(gelBought, WHALE_MIN_GEL, WHALE_MAX_GEL);
        _requirePoolOneCapNotExceeded(
            TOTAL_GEL_CAP,
            GEL.balanceOf(address(this)),
            totalGelLocked,
            gelBought,
            POOL_ONE_GEL_CAP
        );

        uint256 gelLocked = _wmul(gelBought, 7 * 1e17); // 70% locked.
        totalGelLocked = totalGelLocked + gelLocked;
        gelLockedByWhale[msg.sender] = gelLocked;

        GEL.safeTransfer(msg.sender, gelBought - gelLocked);

        emit LogBuyWhale(
            msg.sender,
            msg.value,
            gelBought,
            gelLocked,
            gelBought - gelLocked
        );
    }

    // solhint-disable-next-line function-max-lines
    function buyDolphin(bytes calldata _signature)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        _requirePoolTwoIsOpen(poolTwoStartTime, poolTwoEndTime);
        _requireDolphin(_signature, SIGNER);
        _requireWhaleNeverBought(gelLockedByWhale[msg.sender]);
        _requireDolphinNeverBought(gelBoughtByDolphin[msg.sender]);

        // Amount of gel bought
        // TODO check precision issue here.
        uint256 gelBought = _wmul(msg.value, gelPerEth);

        _requireBoughtLteDolphinMax(gelBought, DOLPHIN_MAX_GEL);
        uint256 remainingGel = _getRemainingGel(
            GEL.balanceOf(address(this)),
            totalGelLocked
        );

        if (_isSaleClosing(remainingGel, DOLPHIN_MIN_GEL))
            _requireBoughtEqRemaining(gelBought, remainingGel);
        else {
            _requireBoughtGteDolphinMin(gelBought, DOLPHIN_MIN_GEL);
            _requireBoughtLteRemaining(gelBought, remainingGel);
        }

        gelBoughtByDolphin[msg.sender] = gelBought;

        GEL.safeTransfer(msg.sender, gelBought);

        emit LogBuyDolphin(msg.sender, msg.value, gelBought);
    }

    function withdrawLockedGEL(address _to)
        external
        whenNotPaused
        nonReentrant
    {
        _requireNotAddressZero(_to);
        _requireNotLocked(lockUpEndTime);
        _requireHasGELToUnlock(gelLockedByWhale[msg.sender]);

        uint256 gelWithdrawn = gelLockedByWhale[msg.sender];
        delete gelLockedByWhale[msg.sender];

        totalGelLocked = totalGelLocked - gelWithdrawn;

        GEL.safeTransfer(_to, gelWithdrawn);

        emit LogWithdrawLockedGEL(msg.sender, _to, gelWithdrawn);
    }

    // ======== HELPERS =======

    function canBuyWhale(
        address _whale,
        bytes calldata _signature,
        uint256 _ethToSell
    ) external view returns (bool) {
        uint256 gelToBuy = getGELToBuy(_ethToSell);
        return
            !paused() &&
            isPoolOneOpen() &&
            isWhale(_whale, _signature) &&
            hasWhaleNeverBought(_whale) &&
            isBoughtWithinWhaleCaps(gelToBuy) &&
            !isPoolOneCapExceeded(gelToBuy);
    }

    function canBuyDolphin(
        address _dolphin,
        bytes calldata _signature,
        uint256 _ethToSell
    ) external view returns (bool) {
        uint256 gelToBuy = getGELToBuy(_ethToSell);
        return
            !paused() &&
            isPoolTwoOpen() &&
            isDolphin(_dolphin, _signature) &&
            hasWhaleNeverBought(_dolphin) &&
            hasDolphinNeverBought(_dolphin) &&
            isBoughtLteDolphinMax(gelToBuy) &&
            (
                isSaleClosing()
                    ? isBoughtEqRemaining(gelToBuy)
                    : isBoughtGteDolphinMin(gelToBuy) &&
                        isBoughtLteRemaining(gelToBuy)
            );
    }

    function getGELToBuy(uint256 _ethToSell) public view returns (uint256) {
        return _wmul(_ethToSell, gelPerEth);
    }

    function isPoolOneOpen() public view returns (bool) {
        return _isPoolOneOpen(poolOneStartTime, poolOneEndTime);
    }

    function isWhale(address _whale, bytes calldata _signature)
        public
        view
        returns (bool)
    {
        return _isWhale(_whale, _signature, SIGNER);
    }

    function hasWhaleNeverBought(address _whale) public view returns (bool) {
        return _hasWhaleNeverBought(gelLockedByWhale[_whale]);
    }

    function isPoolOneCapExceeded(uint256 _gelToBuy)
        public
        view
        returns (bool)
    {
        return
            _isPoolOneCapExceeded(
                TOTAL_GEL_CAP,
                GEL.balanceOf((address(this))),
                totalGelLocked,
                _gelToBuy,
                POOL_ONE_GEL_CAP
            );
    }

    function getRemainingGelPoolOne() public view returns (uint256) {
        return
            block.timestamp < poolOneEndTime // solhint-disable-line not-rely-on-time
                ? POOL_ONE_GEL_CAP -
                    (TOTAL_GEL_CAP -
                        GEL.balanceOf(address(this)) +
                        totalGelLocked)
                : 0;
    }

    function isPoolTwoOpen() public view returns (bool) {
        return _isPoolTwoOpen(poolTwoStartTime, poolTwoEndTime);
    }

    function isDolphin(address _dolphin, bytes calldata _signature)
        public
        view
        returns (bool)
    {
        return _isDolphin(_dolphin, _signature, SIGNER);
    }

    function hasDolphinNeverBought(address _dolphin)
        public
        view
        returns (bool)
    {
        return _hasDolphinNeverBought(gelBoughtByDolphin[_dolphin]);
    }

    function isSaleClosing() public view returns (bool) {
        return _isSaleClosing(getRemainingGel(), DOLPHIN_MIN_GEL);
    }

    function isBoughtEqRemaining(uint256 _gelToBuy) public view returns (bool) {
        return _isBoughtEqRemaining(_gelToBuy, getRemainingGel());
    }

    function isBoughtLteRemaining(uint256 _gelBought)
        public
        view
        returns (bool)
    {
        return _isBoughtLteRemaining(_gelBought, getRemainingGel());
    }

    function getRemainingGel() public view returns (uint256) {
        return _getRemainingGel(GEL.balanceOf(address(this)), totalGelLocked);
    }

    function isBoughtWithinWhaleCaps(uint256 _gelBought)
        public
        pure
        returns (bool)
    {
        return
            _isBoughtWithinWhaleCaps(_gelBought, WHALE_MIN_GEL, WHALE_MAX_GEL);
    }

    function isBoughtLteDolphinMax(uint256 _gelBought)
        public
        pure
        returns (bool)
    {
        return _isBoughtLteDolphinMax(_gelBought, DOLPHIN_MAX_GEL);
    }

    function isBoughtGteDolphinMin(uint256 _gelToBuy)
        public
        pure
        returns (bool)
    {
        return _isBoughtGteDolphinMin(_gelToBuy, DOLPHIN_MIN_GEL);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// solhint-disable

// PoolOne/Whale checkers

function _isPoolOneOpen(uint256 _poolOneStartTime, uint256 _poolOneEndTime)
    view
    returns (bool)
{
    return
        _poolOneStartTime <= block.timestamp &&
        _poolOneEndTime > block.timestamp;
}

function _requirePoolOneIsOpen(
    uint256 _poolOneStartTime,
    uint256 _poolOneEndTime
) view {
    require(
        _isPoolOneOpen(_poolOneStartTime, _poolOneEndTime),
        "Pool One is not open"
    );
}

function _hasWhaleNeverBought(uint256 _gelLockedByWhaleAmt)
    pure
    returns (bool)
{
    return _gelLockedByWhaleAmt == 0;
}

function _requireWhaleNeverBought(uint256 _gelLockedByWhaleAmt) pure {
    require(
        _hasWhaleNeverBought(_gelLockedByWhaleAmt),
        "Whale had already bought GEL"
    );
}

function _isBoughtWithinWhaleCaps(
    uint256 _gelBought,
    uint256 _whaleMinGel,
    uint256 _whaleMaxGel
) pure returns (bool) {
    return _gelBought >= _whaleMinGel && _gelBought <= _whaleMaxGel;
}

function _requireBoughtWithinWhaleCaps(
    uint256 _gelBought,
    uint256 _whaleMinGel,
    uint256 _whaleMaxGel
) pure {
    require(
        _isBoughtWithinWhaleCaps(_gelBought, _whaleMinGel, _whaleMaxGel),
        "User buying amount is outside of Whale CAPs"
    );
}

function _isPoolOneCapExceeded(
    uint256 _totalGelCap,
    uint256 _marchandDeGlaceGelBalance,
    uint256 _totalGelLocked,
    uint256 _gelBought,
    uint256 _poolOneGelCap
) pure returns (bool) {
    return
        _totalGelCap -
            _marchandDeGlaceGelBalance +
            _totalGelLocked +
            _gelBought >
        _poolOneGelCap;
}

function _requirePoolOneCapNotExceeded(
    uint256 _totalGelCap,
    uint256 _marchandDeGlaceGelBalance,
    uint256 _totalGelLocked,
    uint256 _gelBought,
    uint256 _poolOneGelCap
) pure {
    require(
        !_isPoolOneCapExceeded(
            _totalGelCap,
            _marchandDeGlaceGelBalance,
            _totalGelLocked,
            _gelBought,
            _poolOneGelCap
        ),
        "Whale pool hasn't enough GEL Token."
    );
}

// PoolTwo/Dolphin checkers

function _isPoolTwoOpen(uint256 _poolTwoStartTime, uint256 _poolTwoEndTime)
    view
    returns (bool)
{
    return
        _poolTwoStartTime <= block.timestamp &&
        _poolTwoEndTime > block.timestamp;
}

function _requirePoolTwoIsOpen(
    uint256 _poolTwoStartTime,
    uint256 _poolTwoEndTime
) view {
    require(
        _isPoolTwoOpen(_poolTwoStartTime, _poolTwoEndTime),
        "Pool Two is not open"
    );
}

function _hasDolphinNeverBought(uint256 _gelBoughtByDolphin)
    pure
    returns (bool)
{
    return _gelBoughtByDolphin == 0;
}

function _requireDolphinNeverBought(uint256 _gelBoughtByDolphin) pure {
    require(
        _hasDolphinNeverBought(_gelBoughtByDolphin),
        "Dolphin had already bought GEL"
    );
}

function _isBoughtLteDolphinMax(uint256 _gelBought, uint256 _dolphinMaxGel)
    pure
    returns (bool)
{
    return _gelBought <= _dolphinMaxGel;
}

function _requireBoughtLteDolphinMax(uint256 _gelBought, uint256 _dolphinMaxGel)
    pure
{
    require(
        _isBoughtLteDolphinMax(_gelBought, _dolphinMaxGel),
        "User buying more than Dolphin max cap"
    );
}

function _getRemainingGel(
    uint256 _marchandDeGlaceGelBalance,
    uint256 _totalGelLocked
) pure returns (uint256) {
    return _marchandDeGlaceGelBalance - _totalGelLocked;
}

function _isSaleClosing(
    uint256 _marchandDeGlaceRemainingGel,
    uint256 _dolphinMinGel
) pure returns (bool) {
    return _marchandDeGlaceRemainingGel < _dolphinMinGel;
}

function _isBoughtEqRemaining(
    uint256 _gelBought,
    uint256 _marchandDeGlaceRemainingGel
) pure returns (bool) {
    return _gelBought == _marchandDeGlaceRemainingGel;
}

function _requireBoughtEqRemaining(
    uint256 _gelBought,
    uint256 _marchandDeGlaceRemainingGel
) pure {
    require(
        _isBoughtEqRemaining(_gelBought, _marchandDeGlaceRemainingGel),
        "Last buyer should buy the exact remaining."
    );
}

function _isBoughtGteDolphinMin(uint256 _gelBought, uint256 _dolphinMinGel)
    pure
    returns (bool)
{
    return _gelBought >= _dolphinMinGel;
}

function _requireBoughtGteDolphinMin(uint256 _gelBought, uint256 _dolphinMinGel)
    pure
{
    require(
        _isBoughtGteDolphinMin(_gelBought, _dolphinMinGel),
        "User buying less than Dolphin min cap"
    );
}

function _isBoughtLteRemaining(
    uint256 _gelBought,
    uint256 _marchandDeGlaceRemainingGel
) pure returns (bool) {
    return _gelBought <= _marchandDeGlaceRemainingGel;
}

function _requireBoughtLteRemaining(
    uint256 _gelBought,
    uint256 _marchandDeGlaceRemainingGel
) pure {
    require(
        _isBoughtLteRemaining(_gelBought, _marchandDeGlaceRemainingGel),
        "buyDolphin: GEL buy cap exceeded."
    );
}

// Whale unlock

function _requireNotAddressZero(address _to) pure {
    require(_to != address(0), "_to == AddressZero");
}

function _requireNotLocked(uint256 _lockUpEndTime) view {
    require(_lockUpEndTime < block.timestamp, "Still in lock time.");
}

function _requireHasGELToUnlock(uint256 _gelLockedByWhaleAmt) pure {
    require(_gelLockedByWhaleAmt > 0, "Whale has no GEL to unlock.");
}

// Whale unlock

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// solhint-disable-next-line private-vars-leading-underscore, func-visibility
function _withdrawETH(address _receiver, uint256 _amount) {
    Address.sendValue(payable(_receiver), _amount);
}

// solhint-disable-next-line private-vars-leading-underscore, func-visibility
function _withdrawUnlockedGEL(
    IERC20 _GEL, // solhint-disable-line func-param-name-mixedcase , var-name-mixedcase
    address _receiver,
    uint256 _gelBalance,
    uint256 _totalGelLocked
) {
    SafeERC20.safeTransfer(_GEL, _receiver, _gelBalance - _totalGelLocked);
}

// solhint-disable-next-line private-vars-leading-underscore, func-visibility
function _withdrawAllGEL(
    IERC20 _GEL, // solhint-disable-line func-param-name-mixedcase , var-name-mixedcase
    address _receiver,
    uint256 _gelBalance
) {
    SafeERC20.safeTransfer(_GEL, _receiver, _gelBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// solhint-disable

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

function _isWhale(
    address _whale,
    bytes calldata _signature,
    address _signer
) pure returns (bool) {
    return _recover(_getWitness(true, _whale), _signature) == _signer;
}

function _requireWhale(bytes calldata _signature, address _signer) view {
    require(
        _isWhale(msg.sender, _signature, _signer),
        "Not whitelisted or wrong whale/dolphin type"
    );
}

function _isDolphin(
    address _dolphin,
    bytes calldata _signature,
    address _signer
) pure returns (bool) {
    return _recover(_getWitness(false, _dolphin), _signature) == _signer;
}

function _requireDolphin(bytes calldata _signature, address _signer) view {
    require(
        _isDolphin(msg.sender, _signature, _signer),
        "Not whitelisted or wrong whale/dolphin type"
    );
}

function _recover(bytes32 _hash, bytes calldata _signature)
    pure
    returns (address)
{
    return ECDSA.recover(_hash, _signature);
}

function _getWitness(bool _whale, address _user) pure returns (bytes32) {
    return
        ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(_whale, _user))
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// solhint-disable
function _add(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
}

function _sub(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
}

function _mul(uint256 x, uint256 y) pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
}

function _min(uint256 x, uint256 y) pure returns (uint256 z) {
    return x <= y ? x : y;
}

function _max(uint256 x, uint256 y) pure returns (uint256 z) {
    return x >= y ? x : y;
}

function _imin(int256 x, int256 y) pure returns (int256 z) {
    return x <= y ? x : y;
}

function _imax(int256 x, int256 y) pure returns (int256 z) {
    return x >= y ? x : y;
}

uint256 constant WAD = 10**18;
uint256 constant RAY = 10**27;
uint256 constant QUA = 10**4;

//rounds to zero if x*y < WAD / 2
function _wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, y), WAD / 2) / WAD;
}

//rounds to zero if x*y < WAD / 2
function _rmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, y), RAY / 2) / RAY;
}

//rounds to zero if x*y < WAD / 2
function _wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, WAD), y / 2) / y;
}

//rounds to zero if x*y < RAY / 2
function _rdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, RAY), y / 2) / y;
}

// This famous algorithm is called "exponentiation by squaring"
// and calculates x^n with x as fixed-point and n as regular unsigned.
//
// It's O(log n), instead of O(n) for naive repeated multiplication.
//
// These facts are why it works:
//
//  If n is even, then x^n = (x^2)^(n/2).
//  If n is odd,  then x^n = x * x^(n-1),
//   and applying the equation for even x gives
//    x^n = x * (x^2)^((n-1) / 2).
//
//  Also, EVM division is flooring and
//    floor[(n-1) / 2] = floor[n / 2].
//
function _rpow(uint256 x, uint256 n) pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
        x = _rmul(x, x);

        if (n % 2 != 0) {
            z = _rmul(z, x);
        }
    }
}

//rounds to zero if x*y < QUA / 2
function _qmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, y), QUA / 2) / QUA;
}

//rounds to zero if x*y < QUA / 2
function _qdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, QUA), y / 2) / y;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }
}

