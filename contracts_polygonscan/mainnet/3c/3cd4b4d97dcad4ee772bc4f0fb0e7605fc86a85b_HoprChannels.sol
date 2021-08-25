/**
 *Submitted for verification at polygonscan.com on 2021-08-25
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
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
    return functionCall(target, data, 'Address: low-level call failed');
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
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    require(isContract(target), 'Address: call to non-contract');

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
    return functionStaticCall(target, data, 'Address: low-level static call failed');
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
    require(isContract(target), 'Address: static call to non-contract');

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
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
    require(isContract(target), 'Address: delegate call to non-contract');

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

// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
  /**
   * @dev Receives and executes a batch of function calls on this contract.
   */
  function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      results[i] = Address.functionDelegateCall(address(this), data[i]);
    }
    return results;
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

// File @openzeppelin/contracts/utils/introspection/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface for an ERC1820 implementer, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820#interface-implementation-erc1820implementerinterface[EIP].
 * Used by contracts that will be registered as implementers in the
 * {IERC1820Registry}.
 */
interface IERC1820Implementer {
  /**
   * @dev Returns a special value (`ERC1820_ACCEPT_MAGIC`) if this contract
   * implements `interfaceHash` for `account`.
   *
   * See {IERC1820Registry-setInterfaceImplementer}.
   */
  function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external view returns (bytes32);
}

// File @openzeppelin/contracts/utils/introspection/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC1820Implementer} interface.
 *
 * Contracts may inherit from this and call {_registerInterfaceForAddress} to
 * declare their willingness to be implementers.
 * {IERC1820Registry-setInterfaceImplementer} should then be called for the
 * registration to be complete.
 */
contract ERC1820Implementer is IERC1820Implementer {
  bytes32 private constant _ERC1820_ACCEPT_MAGIC = keccak256('ERC1820_ACCEPT_MAGIC');

  mapping(bytes32 => mapping(address => bool)) private _supportedInterfaces;

  /**
   * @dev See {IERC1820Implementer-canImplementInterfaceForAddress}.
   */
  function canImplementInterfaceForAddress(bytes32 interfaceHash, address account)
    public
    view
    virtual
    override
    returns (bytes32)
  {
    return _supportedInterfaces[interfaceHash][account] ? _ERC1820_ACCEPT_MAGIC : bytes32(0x00);
  }

  /**
   * @dev Declares the contract as willing to be an implementer of
   * `interfaceHash` for `account`.
   *
   * See {IERC1820Registry-setInterfaceImplementer} and
   * {IERC1820Registry-interfaceHash}.
   */
  function _registerInterfaceForAddress(bytes32 interfaceHash, address account) internal virtual {
    _supportedInterfaces[interfaceHash][account] = true;
  }
}

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
      'SafeERC20: approve from non-zero to non-zero allowance'
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
      require(oldAllowance >= value, 'SafeERC20: decreased allowance below zero');
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

    bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// File @openzeppelin/contracts/utils/cryptography/[email protected]

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
      revert('ECDSA: invalid signature length');
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
    require(signer != address(0), 'ECDSA: invalid signature');

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
    return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
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
    return keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
  }
}

// File contracts/HoprChannels.sol

pragma solidity ^0.8;
pragma abicoder v2;

contract HoprChannels is IERC777Recipient, ERC1820Implementer, Multicall {
  using SafeERC20 for IERC20;

  // required by ERC1820 spec
  IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  // required by ERC777 spec
  bytes32 public constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256('ERC777TokensRecipient');
  // used by {tokensReceived} to distinguish which function to call after tokens are sent
  uint256 public immutable FUND_CHANNEL_MULTI_SIZE = abi.encode(address(0), address(0), uint256(0), uint256(0)).length;

  /**
   * @dev Possible channel states.
   *
   *         finalizeChannelClosure()    +----------------------+
   *              (After delay)          |                      | initiateChannelClosure()
   *                    +----------------+   Pending To Close   |<-----------------+
   *                    |                |                      |                  |
   *                    |                +----------------------+                  |
   *                    |                              ^                           |
   *                    |                              |                           |
   *                    |                              |  initiateChannelClosure() |
   *                    |                              |  (If not committed)       |
   *                    v                              |                           |
   *             +------------+                        +-+                    +----+-----+
   *             |            |                          |                    |          |
   *             |   Closed   +--------------------------+--------------------+   Open   |
   *             |            |    tokensReceived()      |                    |          |
   *             +------+-----+ (If already committed) +-+                    +----------+
   *                    |                              |                           ^
   *                    |                              |                           |
   *                    |                              |                           |
   *   tokensReceived() |                              |                           | bumpChannel()
   *                    |              +---------------+------------+              |
   *                    |              |                            |              |
   *                    +--------------+   Waiting For Commitment   +--------------+
   *                                   |                            |
   *                                   +----------------------------+
   */
  enum ChannelStatus {
    CLOSED,
    WAITING_FOR_COMMITMENT,
    OPEN,
    PENDING_TO_CLOSE
  }

  /**
   * @dev A channel struct, used to represent a channel's state
   */
  struct Channel {
    uint256 balance;
    bytes32 commitment;
    uint256 ticketEpoch;
    uint256 ticketIndex;
    ChannelStatus status;
    uint256 channelEpoch;
    // the time when the channel can be closed - NB: overloads at year >2105
    uint32 closureTime;
  }

  /**
   * @dev Stored channels keyed by their channel ids
   */
  mapping(bytes32 => Channel) public channels;

  /**
   * @dev HoprToken, the token that will be used to settle payments
   */
  IERC20 public immutable token;

  /**
   * @dev Seconds it takes until we can finalize channel closure once,
   * channel closure has been initialized.
   */
  uint32 public immutable secsClosure;

  event Announcement(address indexed account, bytes multiaddr);

  event ChannelUpdate(address indexed source, address indexed destination, Channel newState);

  event ChannelClosureInitiated(address indexed source, address indexed destination, uint32 closureInitiationTime);

  event ChannelClosureFinalized(
    address indexed source,
    address indexed destination,
    uint32 closureFinalizationTime,
    uint256 channelBalance
  );

  event ChannelBumped(
    address indexed source,
    address indexed destination,
    bytes32 newCommitment,
    uint256 ticketEpoch,
    uint256 channelBalance
  );

  event TicketRedeemed(
    address indexed source,
    address indexed destination,
    bytes32 nextCommitment,
    uint256 ticketEpoch,
    uint256 ticketIndex,
    bytes32 proofOfRelaySecret,
    uint256 amount,
    uint256 winProb,
    bytes signature
  );

  event TokensReceived(
    address indexed from,
    address indexed account1,
    address indexed account2,
    uint256 amount1,
    uint256 amount2
  );

  /**
   * @param _token HoprToken address
   * @param _secsClosure seconds until a channel can be closed
   */
  constructor(address _token, uint32 _secsClosure) {
    require(_token != address(0), 'token must not be empty');

    token = IERC20(_token);
    secsClosure = _secsClosure;
    _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
  }

  /**
   * Assert that source and destination are good addresses, and distinct.
   */
  modifier validateSourceAndDest(address source, address destination) {
    require(source != destination, 'source and destination must not be the same');
    require(source != address(0), 'source must not be empty');
    require(destination != address(0), 'destination must not be empty');
    _;
  }

  /**
   * @dev Announces msg.sender's multiaddress.
   * Confirmation should be done off-chain.
   * @param multiaddr the multiaddress
   */
  function announce(bytes calldata multiaddr) external {
    emit Announcement(msg.sender, multiaddr);
  }

  /**
   * @dev Funds channels, in both directions, between 2 parties.
   * then emits {ChannelUpdate} event, for each channel.
   * @param account1 the address of account1
   * @param account2 the address of account2
   * @param amount1 amount to fund account1
   * @param amount2 amount to fund account2
   */
  function fundChannelMulti(
    address account1,
    address account2,
    uint256 amount1,
    uint256 amount2
  ) external {
    require(amount1 + amount2 > 0, 'amount must be greater than 0');
    if (amount1 > 0) {
      _fundChannel(account1, account2, amount1);
    }
    if (amount2 > 0) {
      _fundChannel(account2, account1, amount2);
    }

    token.transferFrom(msg.sender, address(this), amount1 + amount2);
  }

  /**
   * @dev redeem a ticket.
   * If the sender has a channel to the source, the amount will be transferred
   * to that channel, otherwise it will be sent to their address directly.
   * @param source the source of the ticket
   * @param nextCommitment the commitment that hashes to the redeemers previous commitment
   * @param proofOfRelaySecret the proof of relay secret
   * @param winProb the winning probability of the ticket
   * @param amount the amount in the ticket
   * @param signature signature
   */
  function redeemTicket(
    address source,
    bytes32 nextCommitment,
    uint256 ticketEpoch,
    uint256 ticketIndex,
    bytes32 proofOfRelaySecret,
    uint256 amount,
    uint256 winProb,
    bytes memory signature
  ) external validateSourceAndDest(source, msg.sender) {
    require(nextCommitment != bytes32(0), 'nextCommitment must not be empty');
    require(amount != uint256(0), 'amount must not be empty');
    (, Channel storage spendingChannel) = _getChannel(source, msg.sender);
    require(
      spendingChannel.status == ChannelStatus.OPEN || spendingChannel.status == ChannelStatus.PENDING_TO_CLOSE,
      'spending channel must be open or pending to close'
    );
    require(
      spendingChannel.commitment == keccak256(abi.encodePacked(nextCommitment)),
      'commitment must be hash of next commitment'
    );
    require(spendingChannel.ticketEpoch == ticketEpoch, 'ticket epoch must match');
    require(spendingChannel.ticketIndex < ticketIndex, 'redemptions must be in order');

    bytes32 ticketHash = ECDSA.toEthSignedMessageHash(
      keccak256(
        _getEncodedTicket(
          msg.sender,
          spendingChannel.ticketEpoch,
          proofOfRelaySecret,
          spendingChannel.channelEpoch,
          amount,
          ticketIndex,
          winProb
        )
      )
    );

    require(ECDSA.recover(ticketHash, signature) == source, 'signer must match the counterparty');
    require(_getTicketLuck(ticketHash, nextCommitment, proofOfRelaySecret) <= winProb, 'ticket must be a win');

    spendingChannel.ticketIndex = ticketIndex;
    spendingChannel.commitment = nextCommitment;
    spendingChannel.balance = spendingChannel.balance - amount;
    (, Channel storage earningChannel) = _getChannel(msg.sender, source);

    emit ChannelUpdate(source, msg.sender, spendingChannel);
    emit TicketRedeemed(
      source,
      msg.sender,
      nextCommitment,
      ticketEpoch,
      ticketIndex,
      proofOfRelaySecret,
      amount,
      winProb,
      signature
    );

    if (earningChannel.status == ChannelStatus.OPEN) {
      earningChannel.balance = earningChannel.balance + amount;
      emit ChannelUpdate(msg.sender, source, earningChannel);
    } else {
      token.transfer(msg.sender, amount);
    }
  }

  /**
   * @dev Initialize channel closure.
   * When a channel owner (the 'source' of the channel) wants to 'cash out',
   * they must notify the counterparty (the 'destination') that they will do
   * so, and provide enough time for them to redeem any outstanding tickets
   * before-hand. This notice period is called the 'cool-off' period.
   * The channel 'destination' should be monitoring blockchain events, thus
   * they should be aware that the closure has been triggered, as this
   * method triggers a {ChannelUpdate} and an {ChannelClosureInitiated} event.
   * After the cool-off period expires, the 'source' can call
   * 'finalizeChannelClosure' which withdraws the stake.
   * @param destination the address of the destination
   */
  function initiateChannelClosure(address destination) external validateSourceAndDest(msg.sender, destination) {
    (, Channel storage channel) = _getChannel(msg.sender, destination);
    require(
      channel.status == ChannelStatus.OPEN || channel.status == ChannelStatus.WAITING_FOR_COMMITMENT,
      'channel must be open or waiting for commitment'
    );
    channel.closureTime = _currentBlockTimestamp() + secsClosure;
    channel.status = ChannelStatus.PENDING_TO_CLOSE;
    emit ChannelUpdate(msg.sender, destination, channel);
    emit ChannelClosureInitiated(msg.sender, destination, _currentBlockTimestamp());
  }

  /**
   * @dev Finalize the channel closure, if cool-off period
   * is over it will close the channel and transfer funds
   * to the sender. Then emits {ChannelUpdate} and the
   * {ChannelClosureFinalized} event.
   * @param destination the address of the counterparty
   */
  function finalizeChannelClosure(address destination) external validateSourceAndDest(msg.sender, destination) {
    (, Channel storage channel) = _getChannel(msg.sender, destination);
    require(channel.status == ChannelStatus.PENDING_TO_CLOSE, 'channel must be pending to close');
    require(channel.closureTime < _currentBlockTimestamp(), 'closureTime must be before now');
    uint256 amountToTransfer = channel.balance;
    emit ChannelClosureFinalized(msg.sender, destination, channel.closureTime, channel.balance);
    delete channel.balance;
    delete channel.closureTime;
    channel.status = ChannelStatus.CLOSED;
    emit ChannelUpdate(msg.sender, destination, channel);

    if (amountToTransfer > 0) {
      token.transfer(msg.sender, amountToTransfer);
    }
  }

  /**
   * @dev Request a channelIteration bump, so we can make a new set of
   * commitments
   * Implies that msg.sender is the destination of the channel.
   * @param source the address of the channel source
   * @param newCommitment, a secret derived from this new commitment
   */
  function bumpChannel(address source, bytes32 newCommitment) external validateSourceAndDest(source, msg.sender) {
    (, Channel storage channel) = _getChannel(source, msg.sender);

    require(newCommitment != bytes32(0), 'Cannot set empty commitment');
    channel.commitment = newCommitment;
    channel.ticketEpoch = channel.ticketEpoch + 1;
    if (channel.status == ChannelStatus.WAITING_FOR_COMMITMENT) {
      channel.status = ChannelStatus.OPEN;
    }
    emit ChannelUpdate(source, msg.sender, channel);
    emit ChannelBumped(source, msg.sender, newCommitment, channel.ticketEpoch, channel.balance);
  }

  /**
   * A hook triggered when HOPR tokens are sent to this contract.
   *
   * @param operator address operator requesting the transfer
   * @param from address token holder address
   * @param to address recipient address
   * @param amount uint256 amount of tokens to transfer
   * @param userData bytes extra information provided by the token holder (if any)
   * @param operatorData bytes extra information provided by the operator (if any)
   */
  function tokensReceived(
    address operator,
    address from,
    // solhint-disable-next-line no-unused-vars
    address to,
    uint256 amount,
    bytes calldata userData,
    // solhint-disable-next-line no-unused-vars
    bytes calldata operatorData
  ) external override {
    require(msg.sender == address(token), 'caller must be HoprToken');
    require(to == address(this), 'must be sending tokens to HoprChannels');

    // must be one of our supported functions
    if (userData.length == FUND_CHANNEL_MULTI_SIZE) {
      address account1;
      address account2;
      uint256 amount1;
      uint256 amount2;

      (account1, account2, amount1, amount2) = abi.decode(userData, (address, address, uint256, uint256));
      require(amount == amount1 + amount2, 'amount sent must be equal to amount specified');

      if (amount1 > 0) {
        _fundChannel(account1, account2, amount1);
      }
      if (amount2 > 0) {
        _fundChannel(account2, account1, amount2);
      }
      emit TokensReceived(from, account1, account2, amount1, amount2);
    }
  }

  // internal code

  /**
   * @dev Funds a channel, then emits
   * {ChannelUpdate} event.
   * @param source the address of the channel source
   * @param dest the address of the channel destination
   * @param amount amount to fund account1
   */
  function _fundChannel(
    address source,
    address dest,
    uint256 amount
  ) internal validateSourceAndDest(source, dest) {
    require(amount > 0, 'amount must be greater than 0');

    (, Channel storage channel) = _getChannel(source, dest);
    require(channel.status != ChannelStatus.PENDING_TO_CLOSE, 'Cannot fund a closing channel');
    if (channel.status == ChannelStatus.CLOSED) {
      // We are reopening the channel
      channel.channelEpoch = channel.channelEpoch + 1;
      channel.ticketEpoch = 0; // As we've incremented the channel epoch, we can restart the ticket counter
      channel.ticketIndex = 0;

      if (channel.commitment != bytes32(0)) {
        channel.status = ChannelStatus.OPEN;
      } else {
        channel.status = ChannelStatus.WAITING_FOR_COMMITMENT;
      }
    }

    channel.balance = channel.balance + amount;
    emit ChannelUpdate(source, dest, channel);
  }

  /**
   * @param source source
   * @param destination destination
   * @return a tuple of channelId, channel
   */
  function _getChannel(address source, address destination) internal view returns (bytes32, Channel storage) {
    bytes32 channelId = _getChannelId(source, destination);
    Channel storage channel = channels[channelId];
    return (channelId, channel);
  }

  /**
   * @param source the address of source
   * @param destination the address of destination
   * @return the channel id
   */
  function _getChannelId(address source, address destination) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(source, destination));
  }

  /**
   * @return the current timestamp
   */
  function _currentBlockTimestamp() internal view returns (uint32) {
    // solhint-disable-next-line
    return uint32(block.timestamp);
  }

  /**
   * Uses the response to recompute the challenge. This is done
   * by multiplying the base point of the curve with the given response.
   * Due to the lack of embedded ECMUL functionality in the current
   * version of the EVM, this is done by misusing the `ecrecover`
   * functionality. `ecrecover` performs the point multiplication and
   * converts the output to an Ethereum address (sliced hash of the product
   * of base point and scalar).
   * See https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384
   * @param response response that is used to recompute the challenge
   */
  function _computeChallenge(bytes32 response) internal pure returns (address) {
    // Field order of the base field
    uint256 FIELD_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    require(0 < uint256(response), 'Invalid response. Value must be within the field');
    require(uint256(response) < FIELD_ORDER, 'Invalid response. Value must be within the field');

    // x-coordinate of the base point
    uint256 gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    // y-coordinate of base-point is even, so v is 27
    uint8 gv = 27;

    address signer = ecrecover(0, gv, bytes32(gx), bytes32(mulmod(uint256(response), gx, FIELD_ORDER)));

    return signer;
  }

  /**
   * @dev Encode ticket data
   * @return bytes
   */
  function _getEncodedTicket(
    address recipient,
    uint256 recipientCounter,
    bytes32 proofOfRelaySecret,
    uint256 channelIteration,
    uint256 amount,
    uint256 ticketIndex,
    uint256 winProb
  ) internal pure returns (bytes memory) {
    address challenge = _computeChallenge(proofOfRelaySecret);

    return abi.encodePacked(recipient, challenge, recipientCounter, amount, winProb, ticketIndex, channelIteration);
  }

  /**
   * @dev Get the ticket's "luck" by
   * hashing provided values.
   * @return luck
   */
  function _getTicketLuck(
    bytes32 ticketHash,
    bytes32 nextCommitment,
    bytes32 proofOfRelaySecret
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(ticketHash, nextCommitment, proofOfRelaySecret)));
  }
}