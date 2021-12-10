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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title ProposedOwnable
 * @notice Contract module which provides a basic access control mechanism, 
 * where there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed via a two step process:
 * 1. Call `proposeOwner`
 * 2. Wait out the delay period
 * 3. Call `acceptOwner`
 *
 * @dev This module is used through inheritance. It will make available the 
 * modifier `onlyOwner`, which can be applied to your functions to restrict 
 * their use to the owner.
 * 
 * @dev The majority of this code was taken from the openzeppelin Ownable 
 * contract
 *
 */
abstract contract ProposedOwnable {
  address private _owner;

  address private _proposed;
  uint256 private _proposedOwnershipTimestamp;

  bool private _routerOwnershipRenounced;
  uint256 private _routerOwnershipTimestamp;

  bool private _assetOwnershipRenounced;
  uint256 private _assetOwnershipTimestamp;

  uint256 private constant _delay = 7 days;

  event RouterOwnershipRenunciationProposed(uint256 timestamp);

  event RouterOwnershipRenounced(bool renounced);

  event AssetOwnershipRenunciationProposed(uint256 timestamp);

  event AssetOwnershipRenounced(bool renounced);

  event OwnershipProposed(address indexed proposedOwner);

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
    * @notice Initializes the contract setting the deployer as the initial 
    * owner.
    */
  constructor() {
    _setOwner(msg.sender);
  }

  /**
    * @notice Returns the address of the current owner.
    */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
    * @notice Returns the address of the proposed owner.
    */
  function proposed() public view virtual returns (address) {
    return _proposed;
  }

  /**
    * @notice Returns the address of the proposed owner.
    */
  function proposedTimestamp() public view virtual returns (uint256) {
    return _proposedOwnershipTimestamp;
  }

  /**
    * @notice Returns the timestamp when router ownership was last proposed to be renounced
    */
  function routerOwnershipTimestamp() public view virtual returns (uint256) {
    return _routerOwnershipTimestamp;
  }

  /**
    * @notice Returns the timestamp when asset ownership was last proposed to be renounced
    */
  function assetOwnershipTimestamp() public view virtual returns (uint256) {
    return _assetOwnershipTimestamp;
  }

  /**
    * @notice Returns the delay period before a new owner can be accepted.
    */
  function delay() public view virtual returns (uint256) {
    return _delay;
  }

  /**
    * @notice Throws if called by any account other than the owner.
    */
  modifier onlyOwner() {
      require(_owner == msg.sender, "#OO:029");
      _;
  }

  /**
    * @notice Throws if called by any account other than the proposed owner.
    */
  modifier onlyProposed() {
      require(_proposed == msg.sender, "#OP:035");
      _;
  }

  /** 
    * @notice Indicates if the ownership of the router whitelist has
    * been renounced
    */
  function isRouterOwnershipRenounced() public view returns (bool) {
    return _owner == address(0) || _routerOwnershipRenounced;
  }

  /** 
    * @notice Indicates if the ownership of the router whitelist has
    * been renounced
    */
  function proposeRouterOwnershipRenunciation() public virtual onlyOwner {
    // Use contract as source of truth
    // Will fail if all ownership is renounced by modifier
    require(!_routerOwnershipRenounced, "#PROR:038");

    // Begin delay, emit event
    _setRouterOwnershipTimestamp();
  }

  /** 
    * @notice Indicates if the ownership of the asset whitelist has
    * been renounced
    */
  function renounceRouterOwnership() public virtual onlyOwner {
    // Contract as sournce of truth
    // Will fail if all ownership is renounced by modifier
    require(!_routerOwnershipRenounced, "#RRO:038");

    // Ensure there has been a proposal cycle started
    require(_routerOwnershipTimestamp > 0, "#RRO:037");

    // Delay has elapsed
    require((block.timestamp - _routerOwnershipTimestamp) > _delay, "#RRO:030");

    // Set renounced, emit event, reset timestamp to 0
    _setRouterOwnership(true);
  }

  /** 
    * @notice Indicates if the ownership of the asset whitelist has
    * been renounced
    */
  function isAssetOwnershipRenounced() public view returns (bool) {
    return _owner == address(0) || _assetOwnershipRenounced;
  }

  /** 
    * @notice Indicates if the ownership of the asset whitelist has
    * been renounced
    */
  function proposeAssetOwnershipRenunciation() public virtual onlyOwner {
    // Contract as sournce of truth
    // Will fail if all ownership is renounced by modifier
    require(!_assetOwnershipRenounced, "#PAOR:038");

    // Start cycle, emit event
    _setAssetOwnershipTimestamp();
  }

  /** 
    * @notice Indicates if the ownership of the asset whitelist has
    * been renounced
    */
  function renounceAssetOwnership() public virtual onlyOwner {
    // Contract as sournce of truth
    // Will fail if all ownership is renounced by modifier
    require(!_assetOwnershipRenounced, "#RAO:038");

    // Ensure there has been a proposal cycle started
    require(_assetOwnershipTimestamp > 0, "#RAO:037");

    // Ensure delay has elapsed
    require((block.timestamp - _assetOwnershipTimestamp) > _delay, "#RAO:030");

    // Set ownership, reset timestamp, emit event
    _setAssetOwnership(true);
  }

  /** 
    * @notice Indicates if the ownership has been renounced() by
    * checking if current owner is address(0)
    */
  function renounced() public view returns (bool) {
    return _owner == address(0);
  }

  /**
    * @notice Sets the timestamp for an owner to be proposed, and sets the
    * newly proposed owner as step 1 in a 2-step process
   */
  function proposeNewOwner(address newlyProposed) public virtual onlyOwner {
    // Contract as source of truth
    require(_proposed != newlyProposed || newlyProposed == address(0), "#PNO:036");

    // Sanity check: reasonable proposal
    require(_owner != newlyProposed, "#PNO:038");

    _setProposed(newlyProposed);
  }

  /**
    * @notice Renounces ownership of the contract after a delay
    */
  function renounceOwnership() public virtual onlyOwner {
    // Ensure there has been a proposal cycle started
    require(_proposedOwnershipTimestamp > 0, "#RO:037");

    // Ensure delay has elapsed
    require((block.timestamp - _proposedOwnershipTimestamp) > _delay, "#RO:030");

    // Require proposed is set to 0
    require(_proposed == address(0), "#RO:036");

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  /**
    * @notice Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
  function acceptProposedOwner() public virtual onlyProposed {
    // Contract as source of truth
    require(_owner != _proposed, "#APO:038");

    // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
    // the only time this would happen is if the _proposed was never
    // set (will fail from modifier) or if the owner == _proposed (checked
    // above)

    // Ensure delay has elapsed
    require((block.timestamp - _proposedOwnershipTimestamp) > _delay, "#APO:030");

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  ////// INTERNAL //////

  function _setRouterOwnershipTimestamp() private {
    _routerOwnershipTimestamp = block.timestamp;
    emit RouterOwnershipRenunciationProposed(_routerOwnershipTimestamp);
  }

  function _setRouterOwnership(bool value) private {
    _routerOwnershipRenounced = value;
    _routerOwnershipTimestamp = 0;
    emit RouterOwnershipRenounced(value);
  }

  function _setAssetOwnershipTimestamp() private {
    _assetOwnershipTimestamp = block.timestamp;
    emit AssetOwnershipRenunciationProposed(_assetOwnershipTimestamp);
  }

  function _setAssetOwnership(bool value) private {
    _assetOwnershipRenounced = value;
    _assetOwnershipTimestamp = 0;
    emit AssetOwnershipRenounced(value);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    _proposedOwnershipTimestamp = 0;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _setProposed(address newlyProposed) private {
    _proposedOwnershipTimestamp = block.timestamp;
    _proposed = newlyProposed;
    emit OwnershipProposed(_proposed);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./interfaces/IFulfillInterpreter.sol";
import "./interfaces/ITransactionManager.sol";
import "./interpreters/FulfillInterpreter.sol";
import "./ProposedOwnable.sol";
import "./lib/LibAsset.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


/**
  *
  * @title TransactionManager
  * @author Connext <[email protected]>
  * @notice This contract holds the logic to facilitate crosschain transactions.
  *         Transactions go through three phases in the happy case:
  *
  *         1. Route Auction (offchain): User broadcasts to our network 
  *         signalling their desired route. Routers respond with sealed bids 
  *         containing commitments to fulfilling the transaction within a 
  *         certain time and price range.
  *
  *         2. Prepare: Once the auction is completed, the transaction can be 
  *         prepared. The user submits a transaction to `TransactionManager` 
  *         contract on sender-side chain containing router's signed bid. This 
  *         transaction locks up the users funds on the sending chain. Upon 
  *         detecting an event containing their signed bid from the chain, 
  *         router submits the same transaction to `TransactionManager` on the 
  *         receiver-side chain, and locks up a corresponding amount of 
  *         liquidity. The amount locked on the receiving chain is `sending 
  *         amount - auction fee` so the router is incentivized to complete the 
  *         transaction.
  *
  *         3. Fulfill: Upon detecting the `TransactionPrepared` event on the 
  *         receiver-side chain, the user signs a message and sends it to a 
  *         relayer, who will earn a fee for submission. The relayer (which may 
  *         be the router) then submits the message to the `TransactionManager` 
  *         to complete their transaction on receiver-side chain and claim the 
  *         funds locked by the router. A relayer is used here to allow users 
  *         to submit transactions with arbitrary calldata on the receiving 
  *         chain without needing gas to do so. The router then submits the 
  *         same signed message and completes transaction on sender-side, 
  *         unlocking the original `amount`.
  *
  *         If a transaction is not fulfilled within a fixed timeout, it 
  *         reverts and can be reclaimed by the party that called `prepare` on 
  *         each chain (initiator). Additionally, transactions can be cancelled 
  *         unilaterally by the person owed funds on that chain (router for 
  *         sending chain, user for receiving chain) prior to expiry.
  */
contract TransactionManager is ReentrancyGuard, ProposedOwnable, ITransactionManager {
  /**
   * @dev Mapping of router to balance specific to asset
   */
  mapping(address => mapping(address => uint256)) public routerBalances;

  /**
    * @dev Mapping of allowed router addresses. Must be added to both
    *      sending and receiving chains when forwarding a transfer.
    */
  mapping(address => bool) public approvedRouters;

  /**
    * @dev Mapping of allowed assetIds on same chain as contract
    */
  mapping(address => bool) public approvedAssets;

  /**
    * @dev Mapping of hash of `InvariantTransactionData` to the hash
    *      of the `VariantTransactionData`
    */
  mapping(bytes32 => bytes32) public variantTransactionData;

  /**
  * @dev The stored chain id of the contract, may be passed in to avoid any 
  *      evm issues
  */
  uint256 private immutable chainId;

  /**
    * @dev Minimum timeout (will be the lowest on the receiving chain)
    */
  uint256 public constant MIN_TIMEOUT = 1 days; // 24 hours

  /**
    * @dev Maximum timeout (will be the highest on the sending chain)
    */
  uint256 public constant MAX_TIMEOUT = 30 days; // 720 hours

  /**
    * @dev The external contract that will execute crosschain
    *      calldata
    */
  IFulfillInterpreter public immutable interpreter;

  constructor(uint256 _chainId) {
    chainId = _chainId;
    interpreter = new FulfillInterpreter(address(this));
  }

  /** 
   * @notice Gets the chainId for this contract. If not specified during init
   *         will use the block.chainId
   */
  function getChainId() public view override returns (uint256 _chainId) {
    // Hold in memory to reduce sload calls
    uint256 chain = chainId;
    if (chain == 0) {
      // If not provided, pull from block
      chain = block.chainid;
    }
    return chain;
  }

  /**
   * @notice Allows us to get the chainId that this contract has stored
   */
  function getStoredChainId() external view override returns (uint256) {
    return chainId;
  }

  /**
    * @notice Used to add routers that can transact crosschain
    * @param router Router address to add
    */
  function addRouter(address router) external override onlyOwner {
    // Sanity check: not empty
    require(router != address(0), "#AR:001");

    // Sanity check: needs approval
    require(approvedRouters[router] == false, "#AR:032");

    // Update mapping
    approvedRouters[router] = true;

    // Emit event
    emit RouterAdded(router, msg.sender);
  }

  /**
    * @notice Used to remove routers that can transact crosschain
    * @param router Router address to remove
    */
  function removeRouter(address router) external override onlyOwner {
    // Sanity check: not empty
    require(router != address(0), "#RR:001");

    // Sanity check: needs removal
    require(approvedRouters[router] == true, "#RR:033");

    // Update mapping
    approvedRouters[router] = false;

    // Emit event
    emit RouterRemoved(router, msg.sender);
  }

  /**
    * @notice Used to add assets on same chain as contract that can
    *         be transferred.
    * @param assetId AssetId to add
    */
  function addAssetId(address assetId) external override onlyOwner {
    // Sanity check: needs approval
    require(approvedAssets[assetId] == false, "#AA:032");

    // Update mapping
    approvedAssets[assetId] = true;

    // Emit event
    emit AssetAdded(assetId, msg.sender);
  }

  /**
    * @notice Used to remove assets on same chain as contract that can
    *         be transferred.
    * @param assetId AssetId to remove
    */
  function removeAssetId(address assetId) external override onlyOwner {
    // Sanity check: already approval
    require(approvedAssets[assetId] == true, "#RA:033");

    // Update mapping
    approvedAssets[assetId] = false;

    // Emit event
    emit AssetRemoved(assetId, msg.sender);
  }

  /**
    * @notice This is used by anyone to increase a router's available
    *         liquidity for a given asset.
    * @param amount The amount of liquidity to add for the router
    * @param assetId The address (or `address(0)` if native asset) of the
    *                asset you're adding liquidity for
    * @param router The router you are adding liquidity on behalf of
    */
  function addLiquidityFor(uint256 amount, address assetId, address router) external payable override nonReentrant {
    _addLiquidityForRouter(amount, assetId, router);
  }

  /**
    * @notice This is used by any router to increase their available
    *         liquidity for a given asset.
    * @param amount The amount of liquidity to add for the router
    * @param assetId The address (or `address(0)` if native asset) of the
    *                asset you're adding liquidity for
    */
  function addLiquidity(uint256 amount, address assetId) external payable override nonReentrant {
    _addLiquidityForRouter(amount, assetId, msg.sender);
  }

  /**
    * @notice This is used by any router to decrease their available
    *         liquidity for a given asset.
    * @param amount The amount of liquidity to remove for the router
    * @param assetId The address (or `address(0)` if native asset) of the
    *                asset you're removing liquidity for
    * @param recipient The address that will receive the liquidity being removed
    */
  function removeLiquidity(
    uint256 amount,
    address assetId,
    address payable recipient
  ) external override nonReentrant {
    // Sanity check: recipient is sensible
    require(recipient != address(0), "#RL:007");

    // Sanity check: nonzero amounts
    require(amount > 0, "#RL:002");

    uint256 routerBalance = routerBalances[msg.sender][assetId];
    // Sanity check: amount can be deducted for the router
    require(routerBalance >= amount, "#RL:008");

    // Update router balances
    unchecked {
      routerBalances[msg.sender][assetId] = routerBalance - amount;
    }

    // Transfer from contract to specified recipient
    LibAsset.transferAsset(assetId, recipient, amount);

    // Emit event
    emit LiquidityRemoved(msg.sender, assetId, amount, recipient);
  }

  /**
    * @notice This function creates a crosschain transaction. When called on
    *         the sending chain, the user is expected to lock up funds. When
    *         called on the receiving chain, the router deducts the transfer
    *         amount from the available liquidity. The majority of the
    *         information about a given transfer does not change between chains,
    *         with three notable exceptions: `amount`, `expiry`, and 
    *         `preparedBlock`. The `amount` and `expiry` are decremented
    *         between sending and receiving chains to provide an incentive for 
    *         the router to complete the transaction and time for the router to
    *         fulfill the transaction on the sending chain after the unlocking
    *         signature is revealed, respectively.
    * @param args TODO
    */
  function prepare(
    PrepareArgs calldata args
  ) external payable override nonReentrant returns (TransactionData memory) {
    // Sanity check: user is sensible
    require(args.invariantData.user != address(0), "#P:009");

    // Sanity check: router is sensible
    require(args.invariantData.router != address(0), "#P:001");

    // Router is approved *on both chains*
    require(isRouterOwnershipRenounced() || approvedRouters[args.invariantData.router], "#P:003");

    // Sanity check: sendingChainFallback is sensible
    require(args.invariantData.sendingChainFallback != address(0), "#P:010");

    // Sanity check: valid fallback
    require(args.invariantData.receivingAddress != address(0), "#P:026");

    // Make sure the chains are different
    require(args.invariantData.sendingChainId != args.invariantData.receivingChainId, "#P:011");

    // Make sure the chains are relevant
    uint256 _chainId = getChainId();
    require(args.invariantData.sendingChainId == _chainId || args.invariantData.receivingChainId == _chainId, "#P:012");

    { // Expiry scope
      // Make sure the expiry is greater than min
      uint256 buffer = args.expiry - block.timestamp;
      require(buffer >= MIN_TIMEOUT, "#P:013");

      // Make sure the expiry is lower than max
      require(buffer <= MAX_TIMEOUT, "#P:014");
    }

    // Make sure the hash is not a duplicate
    bytes32 digest = keccak256(abi.encode(args.invariantData));
    require(variantTransactionData[digest] == bytes32(0), "#P:015");

    // NOTE: the `encodedBid` and `bidSignature` are simply passed through
    //       to the contract emitted event to ensure the availability of
    //       this information. Their validity is asserted offchain, and
    //       is out of scope of this contract. They are used as inputs so
    //       in the event of a router or user crash, they may recover the
    //       correct bid information without requiring an offchain store.

    // Amount actually used (if fee-on-transfer will be different than
    // supplied)
    uint256 amount = args.amount;

    // First determine if this is sender side or receiver side
    if (args.invariantData.sendingChainId == _chainId) {
      // Check the sender is correct
      require(msg.sender == args.invariantData.initiator, "#P:039");

      // Sanity check: amount is sensible
      // Only check on sending chain to enforce router fees. Transactions could
      // be 0-valued on receiving chain if it is just a value-less call to some
      // `IFulfillHelper`
      require(args.amount > 0, "#P:002");

      // Assets are approved
      // NOTE: Cannot check this on receiving chain because of differing
      // chain contexts
      require(isAssetOwnershipRenounced() || approvedAssets[args.invariantData.sendingAssetId], "#P:004");

      // This is sender side prepare. The user is beginning the process of 
      // submitting an onchain tx after accepting some bid. They should
      // lock their funds in the contract for the router to claim after
      // they have revealed their signature on the receiving chain via
      // submitting a corresponding `fulfill` tx

      // Validate correct amounts on msg and transfer from user to
      // contract
      amount = transferAssetToContract(
        args.invariantData.sendingAssetId,
        args.amount
      );

      // Store the transaction variants. This happens after transferring to
      // account for fee on transfer tokens
      variantTransactionData[digest] = hashVariantTransactionData(
        amount,
        args.expiry,
        block.number
      );
    } else {
      // This is receiver side prepare. The router has proposed a bid on the
      // transfer which the user has accepted. They can now lock up their
      // own liquidity on th receiving chain, which the user can unlock by
      // calling `fulfill`. When creating the `amount` and `expiry` on the
      // receiving chain, the router should have decremented both. The
      // expiry should be decremented to ensure the router has time to
      // complete the sender-side transaction after the user completes the
      // receiver-side transactoin. The amount should be decremented to act as
      // a fee to incentivize the router to complete the transaction properly.

      // Check that the callTo is a contract
      // NOTE: This cannot happen on the sending chain (different chain 
      // contexts), so a user could mistakenly create a transfer that must be
      // cancelled if this is incorrect
      require(args.invariantData.callTo == address(0) || Address.isContract(args.invariantData.callTo), "#P:031");

      // Check that the asset is approved
      // NOTE: This cannot happen on both chains because of differing chain 
      // contexts. May be possible for user to create transaction that is not
      // prepare-able on the receiver chain.
      require(isAssetOwnershipRenounced() || approvedAssets[args.invariantData.receivingAssetId], "#P:004");

      // Check that the caller is the router
      require(msg.sender == args.invariantData.router, "#P:016");

      // Check that the router isnt accidentally locking funds in the contract
      require(msg.value == 0, "#P:017");

      // Check that router has liquidity
      uint256 balance = routerBalances[args.invariantData.router][args.invariantData.receivingAssetId];
      require(balance >= amount, "#P:018");

      // Store the transaction variants
      variantTransactionData[digest] = hashVariantTransactionData(
        amount,
        args.expiry,
        block.number
      );

      // Decrement the router liquidity
      // using unchecked because underflow protected against with require
      unchecked {
        routerBalances[args.invariantData.router][args.invariantData.receivingAssetId] = balance - amount;
      }
    }

    // Emit event
    TransactionData memory txData = TransactionData({
      receivingChainTxManagerAddress: args.invariantData.receivingChainTxManagerAddress,
      user: args.invariantData.user,
      router: args.invariantData.router,
      initiator: args.invariantData.initiator,
      sendingAssetId: args.invariantData.sendingAssetId,
      receivingAssetId: args.invariantData.receivingAssetId,
      sendingChainFallback: args.invariantData.sendingChainFallback,
      callTo: args.invariantData.callTo,
      receivingAddress: args.invariantData.receivingAddress,
      callDataHash: args.invariantData.callDataHash,
      transactionId: args.invariantData.transactionId,
      sendingChainId: args.invariantData.sendingChainId,
      receivingChainId: args.invariantData.receivingChainId,
      amount: amount,
      expiry: args.expiry,
      preparedBlockNumber: block.number
    });

    emit TransactionPrepared(
      txData.user,
      txData.router,
      txData.transactionId,
      txData,
      msg.sender,
      args
    );

    return txData;
  }



    /**
    * @notice This function completes a crosschain transaction. When called on
    *         the receiving chain, the user reveals their signature on the
    *         transactionId and is sent the amount corresponding to the number
    *         of shares the router locked when calling `prepare`. The router 
    *         then uses this signature to unlock the corresponding funds on the 
    *         receiving chain, which are then added back to their available 
    *         liquidity. The user includes a relayer fee since it is not 
    *         assumed they will have gas on the receiving chain. This function 
    *         *must* be called before the transaction expiry has elapsed.
    * @param args TODO
    */
  function fulfill(
    FulfillArgs calldata args
  ) external override nonReentrant returns (TransactionData memory) {
    // Get the hash of the invariant tx data. This hash is the same
    // between sending and receiving chains. The variant data is stored
    // in the contract when `prepare` is called within the mapping.

    { // scope: validation and effects
      bytes32 digest = hashInvariantTransactionData(args.txData);

      // Make sure that the variant data matches what was stored
      require(variantTransactionData[digest] == hashVariantTransactionData(
        args.txData.amount,
        args.txData.expiry,
        args.txData.preparedBlockNumber
      ), "#F:019");

      // Make sure the expiry has not elapsed
      require(args.txData.expiry >= block.timestamp, "#F:020");

      // Make sure the transaction wasn't already completed
      require(args.txData.preparedBlockNumber > 0, "#F:021");

      // Check provided callData matches stored hash
      require(keccak256(args.callData) == args.txData.callDataHash, "#F:024");

      // To prevent `fulfill` / `cancel` from being called multiple times, the
      // preparedBlockNumber is set to 0 before being hashed. The value of the
      // mapping is explicitly *not* zeroed out so users who come online without
      // a store can tell the difference between a transaction that has not been
      // prepared, and a transaction that was already completed on the receiver
      // chain.
      variantTransactionData[digest] = hashVariantTransactionData(
        args.txData.amount,
        args.txData.expiry,
        0
      );
    }

    // Declare these variables for the event emission. Are only assigned
    // IFF there is an external call on the receiving chain
    bool success;
    bool isContract;
    bytes memory returnData;

    uint256 _chainId = getChainId();

    if (args.txData.sendingChainId == _chainId) {
      // The router is completing the transaction, they should get the
      // amount that the user deposited credited to their liquidity
      // reserves.

      // Make sure that the user is not accidentally fulfilling the transaction
      // on the sending chain
      require(msg.sender == args.txData.router, "#F:016");

      // Validate the user has signed
      require(
        recoverFulfillSignature(
          args.txData.transactionId,
          args.relayerFee,
          args.txData.receivingChainId,
          args.txData.receivingChainTxManagerAddress,
          args.signature
        ) == args.txData.user, "#F:022"
      );

      // Complete tx to router for original sending amount
      routerBalances[args.txData.router][args.txData.sendingAssetId] += args.txData.amount;

    } else {
      // Validate the user has signed, using domain of contract
      require(
        recoverFulfillSignature(
          args.txData.transactionId,
          args.relayerFee,
          _chainId,
          address(this),
          args.signature
        ) == args.txData.user, "#F:022"
      );

      // Sanity check: fee <= amount. Allow `=` in case of only 
      // wanting to execute 0-value crosschain tx, so only providing 
      // the fee amount
      require(args.relayerFee <= args.txData.amount, "#F:023");

      (success, isContract, returnData) = _receivingChainFulfill(
        args.txData,
        args.relayerFee,
        args.callData
      );
    }

    // Emit event
    emit TransactionFulfilled(
      args.txData.user,
      args.txData.router,
      args.txData.transactionId,
      args,
      success,
      isContract,
      returnData,
      msg.sender
    );

    return args.txData;
  }

  /**
    * @notice Any crosschain transaction can be cancelled after it has been
    *         created to prevent indefinite lock up of funds. After the
    *         transaction has expired, anyone can cancel it. Before the
    *         expiry, only the recipient of the funds on the given chain is
    *         able to cancel. On the sending chain, this means only the router
    *         is able to cancel before the expiry, while only the user can
    *         prematurely cancel on the receiving chain.
    * @param args TODO
    */
  function cancel(CancelArgs calldata args)
    external
    override
    nonReentrant
    returns (TransactionData memory)
  {
    // Make sure params match against stored data
    // Also checks that there is an active transfer here
    // Also checks that sender or receiver chainID is this chainId (bc we checked it previously)

    // Get the hash of the invariant tx data. This hash is the same
    // between sending and receiving chains. The variant data is stored
    // in the contract when `prepare` is called within the mapping.
    bytes32 digest = hashInvariantTransactionData(args.txData);

    // Verify the variant data is correct
    require(variantTransactionData[digest] == hashVariantTransactionData(args.txData.amount, args.txData.expiry, args.txData.preparedBlockNumber), "#C:019");

    // Make sure the transaction wasn't already completed
    require(args.txData.preparedBlockNumber > 0, "#C:021");

    // To prevent `fulfill` / `cancel` from being called multiple times, the
    // preparedBlockNumber is set to 0 before being hashed. The value of the
    // mapping is explicitly *not* zeroed out so users who come online without
    // a store can tell the difference between a transaction that has not been
    // prepared, and a transaction that was already completed on the receiver
    // chain.
    variantTransactionData[digest] = hashVariantTransactionData(args.txData.amount, args.txData.expiry, 0);

    // Get chainId for gas
    uint256 _chainId = getChainId();

    // Return the appropriate locked funds
    if (args.txData.sendingChainId == _chainId) {
      // Sender side, funds must be returned to the user
      if (args.txData.expiry >= block.timestamp) {
        // Timeout has not expired and tx may only be cancelled by router
        // NOTE: no need to validate the signature here, since you are requiring
        // the router must be the sender when the cancellation is during the
        // fulfill-able window
        require(msg.sender == args.txData.router, "#C:025");
      }

      // Return users locked funds
      // NOTE: no need to check if amount > 0 because cant be prepared on
      // sending chain with 0 value
      LibAsset.transferAsset(
        args.txData.sendingAssetId,
        payable(args.txData.sendingChainFallback),
        args.txData.amount
      );

    } else {
      // Receiver side, router liquidity is returned
      if (args.txData.expiry >= block.timestamp) {
        // Timeout has not expired and tx may only be cancelled by user
        // Validate signature
        require(msg.sender == args.txData.user || recoverCancelSignature(args.txData.transactionId, _chainId, address(this), args.signature) == args.txData.user, "#C:022");

        // NOTE: there is no incentive here for relayers to submit this on
        // behalf of the user (i.e. fee not respected) because the user has not
        // locked funds on this contract. However, if the user reveals their
        // cancel signature to the router, they are incentivized to submit it
        // to unlock their own funds
      }

      // Return liquidity to router
      routerBalances[args.txData.router][args.txData.receivingAssetId] += args.txData.amount;
    }

    // Emit event
    emit TransactionCancelled(
      args.txData.user,
      args.txData.router,
      args.txData.transactionId,
      args,
      msg.sender
    );

    // Return
    return args.txData;
  }

  //////////////////////////
  /// Private functions ///
  //////////////////////////

  /**
    * @notice Contains the logic to verify + increment a given routers liquidity
    * @param amount The amount of liquidity to add for the router
    * @param assetId The address (or `address(0)` if native asset) of the
    *                asset you're adding liquidity for
    * @param router The router you are adding liquidity on behalf of
    */
  function _addLiquidityForRouter(
    uint256 amount,
    address assetId,
    address router
  ) internal {
    // Sanity check: router is sensible
    require(router != address(0), "#AL:001");

    // Sanity check: nonzero amounts
    require(amount > 0, "#AL:002");

    // Router is approved
    require(isRouterOwnershipRenounced() || approvedRouters[router], "#AL:003");

    // Asset is approved
    require(isAssetOwnershipRenounced() || approvedAssets[assetId], "#AL:004");

    // Transfer funds to contract
    amount = transferAssetToContract(assetId, amount);

    // Update the router balances. Happens after pulling funds to account for
    // the fee on transfer tokens
    routerBalances[router][assetId] += amount;

    // Emit event
    emit LiquidityAdded(router, assetId, amount, msg.sender);
  }

  /**
   * @notice Handles transferring funds from msg.sender to the
   *         transaction manager contract. Used in prepare, addLiquidity
   * @param assetId The address to transfer
   * @param specifiedAmount The specified amount to transfer. May not be the 
   *                        actual amount transferred (i.e. fee on transfer 
   *                        tokens)
   */
  function transferAssetToContract(address assetId, uint256 specifiedAmount) internal returns (uint256) {
    uint256 trueAmount = specifiedAmount;

    // Validate correct amounts are transferred
    if (LibAsset.isNativeAsset(assetId)) {
      require(msg.value == specifiedAmount, "#TA:005");
    } else {
      uint256 starting = LibAsset.getOwnBalance(assetId);
      require(msg.value == 0, "#TA:006");
      LibAsset.transferFromERC20(assetId, msg.sender, address(this), specifiedAmount);
      // Calculate the *actual* amount that was sent here
      trueAmount = LibAsset.getOwnBalance(assetId) - starting;
    }

    return trueAmount;
  }

  /// @notice Recovers the signer from the signature provided by the user
  /// @param transactionId Transaction identifier of tx being recovered
  /// @param signature The signature you are recovering the signer from
  function recoverCancelSignature(
    bytes32 transactionId,
    uint256 receivingChainId,
    address receivingChainTxManagerAddress,
    bytes calldata signature
  ) internal pure returns (address) {
    // Create the signed payload
    SignedCancelData memory payload = SignedCancelData({
      transactionId: transactionId,
      functionIdentifier: "cancel",
      receivingChainId: receivingChainId,
      receivingChainTxManagerAddress: receivingChainTxManagerAddress
    });

    // Recover
    return recoverSignature(abi.encode(payload), signature);
  }

  /**
    * @notice Recovers the signer from the signature provided by the user
    * @param transactionId Transaction identifier of tx being recovered
    * @param relayerFee The fee paid to the relayer for submitting the
    *                   tx on behalf of the user.
    * @param signature The signature you are recovering the signer from
    */
  function recoverFulfillSignature(
    bytes32 transactionId,
    uint256 relayerFee,
    uint256 receivingChainId,
    address receivingChainTxManagerAddress,
    bytes calldata signature
  ) internal pure returns (address) {
    // Create the signed payload
    SignedFulfillData memory payload = SignedFulfillData({
      transactionId: transactionId,
      relayerFee: relayerFee,
      functionIdentifier: "fulfill",
      receivingChainId: receivingChainId,
      receivingChainTxManagerAddress: receivingChainTxManagerAddress
    });

    // Recover
    return recoverSignature(abi.encode(payload), signature);
  }

  /**
    * @notice Holds the logic to recover the signer from an encoded payload.
    *         Will hash and convert to an eth signed message.
    * @param encodedPayload The payload that was signed
    * @param signature The signature you are recovering the signer from
    */
  function recoverSignature(bytes memory encodedPayload, bytes calldata  signature) internal pure returns (address) {
    // Recover
    return ECDSA.recover(
      ECDSA.toEthSignedMessageHash(keccak256(encodedPayload)),
      signature
    );
  }

  /**
    * @notice Returns the hash of only the invariant portions of a given
    *         crosschain transaction
    * @param txData TransactionData to hash
    */
  function hashInvariantTransactionData(TransactionData calldata txData) internal pure returns (bytes32) {
    InvariantTransactionData memory invariant = InvariantTransactionData({
      receivingChainTxManagerAddress: txData.receivingChainTxManagerAddress,
      user: txData.user,
      router: txData.router,
      initiator: txData.initiator,
      sendingAssetId: txData.sendingAssetId,
      receivingAssetId: txData.receivingAssetId,
      sendingChainFallback: txData.sendingChainFallback,
      callTo: txData.callTo,
      receivingAddress: txData.receivingAddress,
      sendingChainId: txData.sendingChainId,
      receivingChainId: txData.receivingChainId,
      callDataHash: txData.callDataHash,
      transactionId: txData.transactionId
    });
    return keccak256(abi.encode(invariant));
  }

  /**
    * @notice Returns the hash of only the variant portions of a given
    *         crosschain transaction
    * @param amount amount to hash
    * @param expiry expiry to hash
    * @param preparedBlockNumber preparedBlockNumber to hash
    * @return Hash of the variant data
    *
    */
  function hashVariantTransactionData(uint256 amount, uint256 expiry, uint256 preparedBlockNumber) internal pure returns (bytes32) {
    VariantTransactionData memory variant = VariantTransactionData({
      amount: amount,
      expiry: expiry,
      preparedBlockNumber: preparedBlockNumber
    });
    return keccak256(abi.encode(variant));
  }

  /**
   * @notice Handles the receiving-chain fulfillment. This function should
   *         pay the relayer and either send funds to the specified address
   *         or execute the calldata. Will return a tuple of boolean,bytes
   *         indicating the success and return data of the external call.
   * @dev Separated from fulfill function to avoid stack too deep errors
   *
   * @param txData The TransactionData that needs to be fulfilled
   * @param relayerFee The fee to be paid to the relayer for submission
   * @param callData The data to be executed on the receiving chain
   *
   * @return Tuple representing (success, returnData) of the external call
   */
  function _receivingChainFulfill(
    TransactionData calldata txData,
    uint256 relayerFee,
    bytes calldata callData
  ) internal returns (bool, bool, bytes memory) {
    // The user is completing the transaction, they should get the
    // amount that the router deposited less fees for relayer.

    // Get the amount to send
    uint256 toSend;
    unchecked {
      toSend = txData.amount - relayerFee;
    }

    // Send the relayer the fee
    if (relayerFee > 0) {
      LibAsset.transferAsset(txData.receivingAssetId, payable(msg.sender), relayerFee);
    }

    // Handle receiver chain external calls if needed
    if (txData.callTo == address(0)) {
      // No external calls, send directly to receiving address
      if (toSend > 0) {
        LibAsset.transferAsset(txData.receivingAssetId, payable(txData.receivingAddress), toSend);
      }
      return (false, false, new bytes(0));
    } else {
      // Handle external calls with a fallback to the receiving
      // address in case the call fails so the funds dont remain
      // locked.

      bool isNativeAsset = LibAsset.isNativeAsset(txData.receivingAssetId);

      // First, transfer the funds to the helper if needed
      if (!isNativeAsset && toSend > 0) {
        LibAsset.transferERC20(txData.receivingAssetId, address(interpreter), toSend);
      }

      // Next, call `execute` on the helper. Helpers should internally
      // track funds to make sure no one user is able to take all funds
      // for tx, and handle the case of reversions
      return interpreter.execute{ value: isNativeAsset ? toSend : 0}(
        txData.transactionId,
        payable(txData.callTo),
        txData.receivingAssetId,
        payable(txData.receivingAddress),
        toSend,
        callData
      );
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IFulfillInterpreter {

  event Executed(
    bytes32 indexed transactionId,
    address payable callTo,
    address assetId,
    address payable fallbackAddress,
    uint256 amount,
    bytes callData,
    bytes returnData,
    bool success,
    bool isContract
  );

  function getTransactionManager() external returns (address);

  function execute(
    bytes32 transactionId,
    address payable callTo,
    address assetId,
    address payable fallbackAddress,
    uint256 amount,
    bytes calldata callData
  ) external payable returns (bool success, bool isContract, bytes memory returnData);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface ITransactionManager {
  // Structs

  // Holds all data that is constant between sending and
  // receiving chains. The hash of this is what gets signed
  // to ensure the signature can be used on both chains.
  struct InvariantTransactionData {
    address receivingChainTxManagerAddress;
    address user;
    address router;
    address initiator; // msg.sender of sending side
    address sendingAssetId;
    address receivingAssetId;
    address sendingChainFallback; // funds sent here on cancel
    address receivingAddress;
    address callTo;
    uint256 sendingChainId;
    uint256 receivingChainId;
    bytes32 callDataHash; // hashed to prevent free option
    bytes32 transactionId;
  }

  // Holds all data that varies between sending and receiving
  // chains. The hash of this is stored onchain to ensure the
  // information passed in is valid.
  struct VariantTransactionData {
    uint256 amount;
    uint256 expiry;
    uint256 preparedBlockNumber;
  }

  // All Transaction data, constant and variable
  struct TransactionData {
    address receivingChainTxManagerAddress;
    address user;
    address router;
    address initiator; // msg.sender of sending side
    address sendingAssetId;
    address receivingAssetId;
    address sendingChainFallback;
    address receivingAddress;
    address callTo;
    bytes32 callDataHash;
    bytes32 transactionId;
    uint256 sendingChainId;
    uint256 receivingChainId;
    uint256 amount;
    uint256 expiry;
    uint256 preparedBlockNumber; // Needed for removal of active blocks on fulfill/cancel
  }

  // The structure of the signed data for fulfill
  struct SignedFulfillData {
    bytes32 transactionId;
    uint256 relayerFee;
    string functionIdentifier; // "fulfill" or "cancel"
    uint256 receivingChainId; // For domain separation
    address receivingChainTxManagerAddress; // For domain separation
  }

  // The structure of the signed data for cancellation
  struct SignedCancelData {
    bytes32 transactionId;
    string functionIdentifier;
    uint256 receivingChainId;
    address receivingChainTxManagerAddress; // For domain separation
  }

  /**
    * Arguments for calling prepare()
    * @param invariantData The data for a crosschain transaction that will
    *                      not change between sending and receiving chains.
    *                      The hash of this data is used as the key to store 
    *                      the inforamtion that does change between chains 
    *                      (amount,expiry,preparedBlock) for verification
    * @param amount The amount of the transaction on this chain
    * @param expiry The block.timestamp when the transaction will no longer be
    *               fulfillable and is freely cancellable on this chain
    * @param encryptedCallData The calldata to be executed when the tx is
    *                          fulfilled. Used in the function to allow the user
    *                          to reconstruct the tx from events. Hash is stored
    *                          onchain to prevent shenanigans.
    * @param encodedBid The encoded bid that was accepted by the user for this
    *                   crosschain transfer. It is supplied as a param to the
    *                   function but is only used in event emission
    * @param bidSignature The signature of the bidder on the encoded bid for
    *                     this transaction. Only used within the function for
    *                     event emission. The validity of the bid and
    *                     bidSignature are enforced offchain
    * @param encodedMeta The meta for the function
    */
  struct PrepareArgs {
    InvariantTransactionData invariantData;
    uint256 amount;
    uint256 expiry;
    bytes encryptedCallData;
    bytes encodedBid;
    bytes bidSignature;
    bytes encodedMeta;
  }

  /**
    * @param txData All of the data (invariant and variant) for a crosschain
    *               transaction. The variant data provided is checked against
    *               what was stored when the `prepare` function was called.
    * @param relayerFee The fee that should go to the relayer when they are
    *                   calling the function on the receiving chain for the user
    * @param signature The users signature on the transaction id + fee that
    *                  can be used by the router to unlock the transaction on 
    *                  the sending chain
    * @param callData The calldata to be sent to and executed by the 
    *                 `FulfillHelper`
    * @param encodedMeta The meta for the function
    */
  struct FulfillArgs {
    TransactionData txData;
    uint256 relayerFee;
    bytes signature;
    bytes callData;
    bytes encodedMeta;
  }

  /**
    * Arguments for calling cancel()
    * @param txData All of the data (invariant and variant) for a crosschain
    *               transaction. The variant data provided is checked against
    *               what was stored when the `prepare` function was called.
    * @param signature The user's signature that allows a transaction to be
    *                  cancelled by a relayer
    * @param encodedMeta The meta for the function
    */
  struct CancelArgs {
    TransactionData txData;
    bytes signature;
    bytes encodedMeta;
  }

  // Adding/removing asset events
  event RouterAdded(address indexed addedRouter, address indexed caller);

  event RouterRemoved(address indexed removedRouter, address indexed caller);

  // Adding/removing router events
  event AssetAdded(address indexed addedAssetId, address indexed caller);

  event AssetRemoved(address indexed removedAssetId, address indexed caller);

  // Liquidity events
  event LiquidityAdded(address indexed router, address indexed assetId, uint256 amount, address caller);

  event LiquidityRemoved(address indexed router, address indexed assetId, uint256 amount, address recipient);

  // Transaction events
  event TransactionPrepared(
    address indexed user,
    address indexed router,
    bytes32 indexed transactionId,
    TransactionData txData,
    address caller,
    PrepareArgs args
  );

  event TransactionFulfilled(
    address indexed user,
    address indexed router,
    bytes32 indexed transactionId,
    FulfillArgs args,
    bool success,
    bool isContract,
    bytes returnData,
    address caller
  );

  event TransactionCancelled(
    address indexed user,
    address indexed router,
    bytes32 indexed transactionId,
    CancelArgs args,
    address caller
  );

  // Getters
  function getChainId() external view returns (uint256);

  function getStoredChainId() external view returns (uint256);

  // Owner only methods
  function addRouter(address router) external;

  function removeRouter(address router) external;

  function addAssetId(address assetId) external;

  function removeAssetId(address assetId) external;

  // Router only methods
  function addLiquidityFor(uint256 amount, address assetId, address router) external payable;

  function addLiquidity(uint256 amount, address assetId) external payable;

  function removeLiquidity(
    uint256 amount,
    address assetId,
    address payable recipient
  ) external;

  // Methods for crosschain transfers
  // called in the following order (in happy case)
  // 1. prepare by user on sending chain
  // 2. prepare by router on receiving chain
  // 3. fulfill by user on receiving chain
  // 4. fulfill by router on sending chain
  function prepare(
    PrepareArgs calldata args
  ) external payable returns (TransactionData memory);

  function fulfill(
    FulfillArgs calldata args
  ) external returns (TransactionData memory);

  function cancel(CancelArgs calldata args) external returns (TransactionData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "../interfaces/IFulfillInterpreter.sol";
import "../lib/LibAsset.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
  * @title FulfillInterpreter
  * @author Connext <[email protected]>
  * @notice This library contains an `execute` function that is callabale by
  *         an associated TransactionManager contract. This is used to execute
  *         arbitrary calldata on a receiving chain.
  */
contract FulfillInterpreter is ReentrancyGuard, IFulfillInterpreter {
  address private immutable _transactionManager;

  constructor(address transactionManager) {
    _transactionManager = transactionManager;
  }

  /**
  * @notice Errors if the sender is not the transaction manager
  */
  modifier onlyTransactionManager {
    require(msg.sender == _transactionManager, "#OTM:027");
    _;
  }

  /** 
    * @notice Returns the transaction manager address (only address that can 
    *         call the `execute` function)
    * @return The address of the associated transaction manager
    */
  function getTransactionManager() override external view returns (address) {
    return _transactionManager;
  }

  /** 
    * @notice Executes some arbitrary call data on a given address. The
    *         call data executes can be payable, and will have `amount` sent
    *         along with the function (or approved to the contract). If the
    *         call fails, rather than reverting, funds are sent directly to 
    *         some provided fallbaack address
    * @param transactionId Unique identifier of transaction id that necessitated
    *        calldata execution
    * @param callTo The address to execute the calldata on
    * @param assetId The assetId of the funds to approve to the contract or
    *                send along with the call
    * @param fallbackAddress The address to send funds to if the `call` fails
    * @param amount The amount to approve or send with the call
    * @param callData The data to execute
    */
  function execute(
    bytes32 transactionId,
    address payable callTo,
    address assetId,
    address payable fallbackAddress,
    uint256 amount,
    bytes calldata callData
  ) override external payable onlyTransactionManager returns (bool, bool, bytes memory) {
    // If it is not ether, approve the callTo
    // We approve here rather than transfer since many external contracts
    // simply require an approval, and it is unclear if they can handle 
    // funds transferred directly to them (i.e. Uniswap)
    bool isNative = LibAsset.isNativeAsset(assetId);
    if (!isNative) {
      LibAsset.increaseERC20Allowance(assetId, callTo, amount);
    }

    // Check if the callTo is a contract
    bool success;
    bytes memory returnData;
    bool isContract = Address.isContract(callTo);
    if (isContract) {
      // Try to execute the callData
      // the low level call will return `false` if its execution reverts
      (success, returnData) = callTo.call{value: isNative ? amount : 0}(callData);
    }

    // Handle failure cases
    if (!success) {
      // If it fails, transfer to fallback
      LibAsset.transferAsset(assetId, fallbackAddress, amount);
      // Decrease allowance
      if (!isNative) {
        LibAsset.decreaseERC20Allowance(assetId, callTo, amount);
      }
    }

    // Emit event
    emit Executed(
      transactionId,
      callTo,
      assetId,
      fallbackAddress,
      amount,
      callData,
      returnData,
      success,
      isContract
    );
    return (success, isContract, returnData);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
* @title LibAsset
* @author Connext <[email protected]>
* @notice This library contains helpers for dealing with onchain transfers
*         of assets, including accounting for the native asset `assetId`
*         conventions and any noncompliant ERC20 transfers
*/
library LibAsset {
  /** 
  * @dev All native assets use the empty address for their asset id
  *      by convention
  */
  address constant NATIVE_ASSETID = address(0);

  /** 
  * @notice Determines whether the given assetId is the native asset
  * @param assetId The asset identifier to evaluate
  * @return Boolean indicating if the asset is the native asset
  */
  function isNativeAsset(address assetId) internal pure returns (bool) {
    return assetId == NATIVE_ASSETID;
  }

  /** 
  * @notice Gets the balance of the inheriting contract for the given asset
  * @param assetId The asset identifier to get the balance of
  * @return Balance held by contracts using this library
  */
  function getOwnBalance(address assetId) internal view returns (uint256) {
    return
      isNativeAsset(assetId)
        ? address(this).balance
        : IERC20(assetId).balanceOf(address(this));
  }

  /** 
  * @notice Transfers ether from the inheriting contract to a given
  *         recipient
  * @param recipient Address to send ether to
  * @param amount Amount to send to given recipient
  */
  function transferNativeAsset(address payable recipient, uint256 amount)
      internal
  {
    Address.sendValue(recipient, amount);
  }

  /** 
  * @notice Transfers tokens from the inheriting contract to a given
  *         recipient
  * @param assetId Token address to transfer
  * @param recipient Address to send ether to
  * @param amount Amount to send to given recipient
  */
  function transferERC20(
      address assetId,
      address recipient,
      uint256 amount
  ) internal {
    SafeERC20.safeTransfer(IERC20(assetId), recipient, amount);
  }

  /** 
  * @notice Transfers tokens from a sender to a given recipient
  * @param assetId Token address to transfer
  * @param from Address of sender/owner
  * @param to Address of recipient/spender
  * @param amount Amount to transfer from owner to spender
  */
  function transferFromERC20(
    address assetId,
    address from,
    address to,
    uint256 amount
  ) internal {
    SafeERC20.safeTransferFrom(IERC20(assetId), from, to, amount);
  }

  /** 
  * @notice Increases the allowance of a token to a spender
  * @param assetId Token address of asset to increase allowance of
  * @param spender Account whos allowance is increased
  * @param amount Amount to increase allowance by
  */
  function increaseERC20Allowance(
    address assetId,
    address spender,
    uint256 amount
  ) internal {
    require(!isNativeAsset(assetId), "#IA:034");
    SafeERC20.safeIncreaseAllowance(IERC20(assetId), spender, amount);
  }

  /**
  * @notice Decreases the allowance of a token to a spender
  * @param assetId Token address of asset to decrease allowance of
  * @param spender Account whos allowance is decreased
  * @param amount Amount to decrease allowance by
  */
  function decreaseERC20Allowance(
    address assetId,
    address spender,
    uint256 amount
  ) internal {
    require(!isNativeAsset(assetId), "#DA:034");
    SafeERC20.safeDecreaseAllowance(IERC20(assetId), spender, amount);
  }

  /**
  * @notice Wrapper function to transfer a given asset (native or erc20) to
  *         some recipient. Should handle all non-compliant return value
  *         tokens as well by using the SafeERC20 contract by open zeppelin.
  * @param assetId Asset id for transfer (address(0) for native asset, 
  *                token address for erc20s)
  * @param recipient Address to send asset to
  * @param amount Amount to send to given recipient
  */
  function transferAsset(
      address assetId,
      address payable recipient,
      uint256 amount
  ) internal {
    isNativeAsset(assetId)
      ? transferNativeAsset(recipient, amount)
      : transferERC20(assetId, recipient, amount);
  }
}