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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
  /**
   * @dev Should return whether the signature provided is valid for the provided data
   * @param hash      Hash of the data to be signed
   * @param signature Signature byte array associated with _data
   */
  function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/*
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal initializer {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal initializer {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly { sender := shr(96, calldataload(sub(calldatasize(), 20))) }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length-20];
        } else {
            return super._msgData();
        }
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
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

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        if (AddressUpgradeable.isContract(signer)) {
            try IERC1271Upgradeable(signer).isValidSignature(hash, signature) returns (bytes4 magicValue) {
                return magicValue == IERC1271Upgradeable(signer).isValidSignature.selector;
            } catch {
                return false;
            }
        } else {
            return ECDSAUpgradeable.recover(hash, signature) == signer;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IEthSign.sol";
import "./EthSignUtils.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

// import "hardhat/console.sol";

/**
 * @title EthSign 3.0
 * @dev EthSign 3.0 Smart Contract with ERC2771 compliance.
 * Please read this before modifying storage: https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
 */
contract EthSign is
    IEthSign,
    EthSignUtils,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC2771ContextUpgradeable
{
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return super._msgData();
    }

    /**
     * @dev Initializer for upgradeable contracts (replaces constructors)
     */
    function initialize(address forwarder) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC2771Context_init(forwarder);
    }

    function pause() external onlyOwner {
        _pause();
        emit LogContractPaused();
    }

    function unpause() external onlyOwner {
        _unpause();
        emit LogContractUnpaused();
    }

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    struct ECSignature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct Document {
        uint256 birth;
        uint256 expiration;
        uint256 numOfSigners;
        StorageInfo docStorageInfo;
        EnumerableSetUpgradeable.AddressSet signersSet;
        // Note:
        // SaltedDocument = hash(doc.provider + doc.stroage_id0 + doc.storage_id1)
        // SaltedMetaDocument = hash(doc.provider + doc.storage_id0 + doc.storage_id1 +
        //                      meta.provider + meta.storage_id0 + meta.storage_id1)
        // SaltedAddress = hash(doc.provider + doc.storage_id0 + doc.storage_id1 +
        //                 meta.provider + meta.storage_id0 + meta.storage_id1 +
        //                 address)
        // SaltedAddressWithIndex: hash everything in SaltedAddress + count
        mapping(bytes32 => StorageInfo) metadataStorageInfoForSaltedDocument;
        mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) numOfSignedSignersSetForSaltedMetaDocument;
        mapping(bytes32 => uint256) numOfSignatureFieldsForSaltedAddress;
        mapping(bytes32 => uint256) numOfSignedSignatureFieldsForSaltedAddress;
        mapping(bytes32 => ECSignature) signatureFieldForSaltedAddressWithIndex;
        mapping(bytes32 => StorageInfo) commentsForSaltedAddress;
        address initiator;
        bytes32 name;
    }

    mapping(bytes32 => Document) documents; // documentKey => Document object
    mapping(address => EnumerableSetUpgradeable.Bytes32Set) createdByMe; // address => documentKey
    mapping(address => EnumerableSetUpgradeable.Bytes32Set) sharedWithMe; // address => documentKey
    mapping(address => EnumerableSetUpgradeable.Bytes32Set) archived; // address => documentKey
    // Reserved storage for future use
    mapping(address => EnumerableSetUpgradeable.Bytes32Set) bytesBucket0;
    mapping(address => EnumerableSetUpgradeable.Bytes32Set) bytesBucket1;
    mapping(address => EnumerableSetUpgradeable.Bytes32Set) bytesBucket2;
    mapping(address => EnumerableSetUpgradeable.AddressSet) addressBucket0;
    mapping(address => EnumerableSetUpgradeable.AddressSet) addressBucket1;
    mapping(address => EnumerableSetUpgradeable.AddressSet) addressBucket2;

    // Modifiers
    modifier addressNonZero(address recipient) {
        require(recipient != address(0), "ZERO_SENDER");
        _;
    }

    modifier documentDoesExist(bytes32 documentKey) {
        require(documents[documentKey].birth != 0, "DOC_NOT_EXIST");
        _;
    }

    modifier documentDoesNotExist(bytes32 documentKey) {
        require(documents[documentKey].birth == 0, "DOC_EXIST");
        _;
    }

    modifier documentHasExpired(bytes32 documentKey) {
        require(
            documents[documentKey].expiration < block.number,
            "DOC_NOT_EXPIRED"
        );
        _;
    }

    modifier documentHasNotExpired(bytes32 documentKey) {
        if (documents[documentKey].expiration != 0) {
            require(
                documents[documentKey].expiration >= block.number,
                "DOC_EXPIRED"
            );
        }
        _;
    }

    modifier onlyDocumentInitiator(bytes32 documentKey) {
        Document storage doc = documents[documentKey];
        require(doc.initiator == _msgSender(), "UNAUTH");
        _;
    }

    modifier onlyAuthorizedSigner(bytes32 documentKey) {
        Document storage doc = documents[documentKey];
        require(doc.signersSet.contains(_msgSender()), "UNAUTH");
        _;
    }

    modifier signersNotFinalizedForDocument(bytes32 documentKey) {
        Document storage doc = documents[documentKey];
        require(
            doc.numOfSigners > doc.signersSet.length(),
            "SIGNERS_FINALIZED"
        );
        _;
    }

    // Utility functions
    function hashDocumentKey(string calldata uuid)
        public
        pure
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(uuid));
    }

    function hashSaltedDocumentMappingKey(bytes32 documentKey)
        public
        view
        override
        returns (bytes32)
    {
        StorageInfo storage doc_si = documents[documentKey].docStorageInfo;
        return
            keccak256(
                abi.encodePacked(
                    documentKey,
                    doc_si.provider,
                    doc_si.storage_id0,
                    doc_si.storage_id1
                )
            );
    }

    function hashSaltedMetaDocumentMappingKey(bytes32 documentKey)
        public
        view
        override
        returns (bytes32)
    {
        Document storage doc = documents[documentKey];
        StorageInfo storage doc_si = doc.docStorageInfo;
        StorageInfo storage meta_si = doc.metadataStorageInfoForSaltedDocument[
            hashSaltedDocumentMappingKey(documentKey)
        ];
        return
            keccak256(
                abi.encodePacked(
                    documentKey,
                    doc_si.provider,
                    doc_si.storage_id0,
                    doc_si.storage_id1,
                    meta_si.provider,
                    meta_si.storage_id0,
                    meta_si.storage_id1
                )
            );
    }

    function hashSaltedAddressMappingKey(bytes32 documentKey, address signer)
        public
        view
        override
        addressNonZero(signer)
        returns (bytes32)
    {
        Document storage doc = documents[documentKey];
        StorageInfo storage doc_si = doc.docStorageInfo;
        StorageInfo storage meta_si = doc.metadataStorageInfoForSaltedDocument[
            hashSaltedDocumentMappingKey(documentKey)
        ];
        return
            keccak256(
                abi.encodePacked(
                    documentKey,
                    doc_si.provider,
                    doc_si.storage_id0,
                    doc_si.storage_id1,
                    meta_si.provider,
                    meta_si.storage_id0,
                    meta_si.storage_id1,
                    signer
                )
            );
    }

    function hashSaltedAddressWithIndexMappingKey(
        bytes32 documentKey,
        address signer,
        uint256 index
    ) public view override addressNonZero(signer) returns (bytes32) {
        Document storage doc = documents[documentKey];
        StorageInfo storage doc_si = doc.docStorageInfo;
        StorageInfo storage meta_si = doc.metadataStorageInfoForSaltedDocument[
            hashSaltedDocumentMappingKey(documentKey)
        ];
        return
            keccak256(
                abi.encodePacked(
                    documentKey,
                    doc_si.provider,
                    doc_si.storage_id0,
                    doc_si.storage_id1,
                    meta_si.provider,
                    meta_si.storage_id0,
                    meta_si.storage_id1,
                    signer,
                    index
                )
            );
    }

    function verifyECSignatureSigner(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) public view override returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return
            SignatureCheckerUpgradeable.isValidSignatureNow(
                signer,
                prefixedHash,
                signature
            );
    }

    function splitECSignature(bytes memory signature)
        public
        pure
        override
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }

    // Getters (view functions)
    function getNumOfDocumentsCreatedByMe()
        external
        view
        override
        returns (uint256 count)
    {
        return createdByMe[_msgSender()].length();
    }

    function getNumOfDocumentsSharedWithMe()
        external
        view
        override
        returns (uint256 count)
    {
        return sharedWithMe[_msgSender()].length();
    }

    function getNumOfDocumentsArchived()
        external
        view
        override
        returns (uint256 count)
    {
        return archived[_msgSender()].length();
    }

    function getDocumentCreatedByMeAtIndex(uint256 index)
        external
        view
        override
        returns (bytes32 documentKey)
    {
        return createdByMe[_msgSender()].at(index);
    }

    function getDocumentSharedWithMeAtIndex(uint256 index)
        external
        view
        override
        returns (bytes32 documentKey)
    {
        return sharedWithMe[_msgSender()].at(index);
    }

    function getDocumentArchivedAtIndex(uint256 index)
        external
        view
        override
        returns (bytes32 documentKey)
    {
        return archived[_msgSender()].at(index);
    }

    function getDocumentBasicInfo(bytes32 documentKey)
        external
        view
        override
        documentDoesExist(documentKey)
        returns (
            address initiator,
            bytes32 name,
            uint256 birth,
            uint256 expiration,
            uint256 numOfSigners
        )
    {
        Document storage doc = documents[documentKey];
        initiator = doc.initiator;
        name = doc.name;
        birth = doc.birth;
        expiration = doc.expiration;
        numOfSigners = doc.signersSet.length();
    }

    function getDocumentDocStorageInfo(bytes32 documentKey)
        external
        view
        override
        documentDoesExist(documentKey)
        returns (
            bytes32 docStorageProvider,
            bytes32 docStorage_id0,
            bytes32 docStorage_id1
        )
    {
        StorageInfo storage doc_si = documents[documentKey].docStorageInfo;
        docStorageProvider = doc_si.provider;
        docStorage_id0 = doc_si.storage_id0;
        docStorage_id1 = doc_si.storage_id1;
    }

    function getDocumentMetaStorageInfo(bytes32 documentKey)
        external
        view
        override
        documentDoesExist(documentKey)
        returns (
            bytes32 metaStorageProvider,
            bytes32 metaStorage_id0,
            bytes32 metaStorage_id1
        )
    {
        bytes32 saltedDocumentMappingKey = hashSaltedDocumentMappingKey(
            documentKey
        );
        StorageInfo storage meta_si = documents[documentKey]
        .metadataStorageInfoForSaltedDocument[saltedDocumentMappingKey];
        metaStorageProvider = meta_si.provider;
        metaStorage_id0 = meta_si.storage_id0;
        metaStorage_id1 = meta_si.storage_id1;
    }

    function getNumberOfSignersForDocument(bytes32 documentKey)
        external
        view
        override
        documentDoesExist(documentKey)
        returns (uint256 count)
    {
        return documents[documentKey].signersSet.length();
    }

    function getDocumentSignerAtIndex(bytes32 documentKey, uint256 index)
        external
        view
        override
        documentDoesExist(documentKey)
        returns (address signer)
    {
        signer = documents[documentKey].signersSet.at(index);
    }

    function getNumberOfDocumentECSignaturesForSigner(
        address signer,
        bytes32 documentKey
    )
        external
        view
        override
        documentDoesExist(documentKey)
        returns (uint256 count)
    {
        bytes32 saltedAddressMappingKey = hashSaltedAddressMappingKey(
            documentKey,
            signer
        );
        return
            documents[documentKey].numOfSignatureFieldsForSaltedAddress[
                saltedAddressMappingKey
            ];
    }

    function getDocumentECSignatureForSignerAtIndex(
        address signer,
        bytes32 documentKey,
        uint256 index
    )
        external
        view
        override
        documentDoesExist(documentKey)
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        Document storage doc = documents[documentKey];
        bytes32 saltedAddressMappingKey = hashSaltedAddressMappingKey(
            documentKey,
            signer
        );
        require(
            index <
                doc.numOfSignatureFieldsForSaltedAddress[
                    saltedAddressMappingKey
                ],
            "OUT_OF_BOUNDS"
        );


            bytes32 saltedAddressWithIndexMappingKey
         = hashSaltedAddressWithIndexMappingKey(documentKey, signer, index);
        ECSignature storage ecs = doc.signatureFieldForSaltedAddressWithIndex[
            saltedAddressWithIndexMappingKey
        ];
        return (ecs.r, ecs.s, ecs.v);
    }

    function getDocumentCommentsForSigner(address signer, bytes32 documentKey)
        external
        view
        override
        documentDoesExist(documentKey)
        returns (
            bytes32 provider,
            bytes32 storage_id0,
            bytes32 storage_id1
        )
    {
        Document storage doc = documents[documentKey];
        bytes32 saltedAddressMappingKey = hashSaltedAddressMappingKey(
            documentKey,
            signer
        );
        StorageInfo storage si = doc.commentsForSaltedAddress[
            saltedAddressMappingKey
        ];
        return (si.provider, si.storage_id0, si.storage_id1);
    }

    function getDocumentStatus(bytes32 documentKey)
        external
        view
        override
        documentDoesExist(documentKey)
        returns (uint256 totalSigners, uint256 signedSigners)
    {
        Document storage doc = documents[documentKey];
        bytes32 saltedMetaDocumentMappingKey = hashSaltedMetaDocumentMappingKey(
            documentKey
        );
        totalSigners = doc.signersSet.length();
        signedSigners = doc
        .numOfSignedSignersSetForSaltedMetaDocument[
            saltedMetaDocumentMappingKey
        ]
        .length();
    }

    function aggregateGetIsSignedForAllSignatureFields(bytes32 documentKey)
        external
        view
        override
        documentDoesExist(documentKey)
        returns (_HelperSignerSignatureFieldStatus[] memory fieldSignedInfo)
    {
        Document storage doc = documents[documentKey];
        EnumerableSetUpgradeable.AddressSet storage signersSet = doc.signersSet;
        uint256 numOfSigners = signersSet.length();
        fieldSignedInfo = new _HelperSignerSignatureFieldStatus[](numOfSigners);
        for (uint256 i = 0; i < numOfSigners; ++i) {
            address signer = signersSet.at(i);
            bytes32 saltedAddressMappingKey = hashSaltedAddressMappingKey(
                documentKey,
                signer
            );
            uint256 numOfSignatureFieldsForSigner = doc
            .numOfSignatureFieldsForSaltedAddress[saltedAddressMappingKey];
            bool[] memory nestedElement = new bool[](
                numOfSignatureFieldsForSigner
            );
            for (uint256 j = 0; j < numOfSignatureFieldsForSigner; ++j) {

                    bytes32 saltedAddressWithIndexMappingKey
                 = hashSaltedAddressWithIndexMappingKey(documentKey, signer, j);
                ECSignature storage ecs = doc
                .signatureFieldForSaltedAddressWithIndex[
                    saltedAddressWithIndexMappingKey
                ];
                bool fieldSigned = !(ecs.r == 0x0 &&
                    ecs.s == 0x0 &&
                    ecs.v == 0);
                nestedElement[j] = fieldSigned;
            }
            fieldSignedInfo[i].signer = signer;
            fieldSignedInfo[i].fieldSigned = nestedElement;
        }
    }

    function aggregateGetAllCommentsOfAllSigners(bytes32 documentKey)
        external
        view
        override
        documentDoesExist(documentKey)
        returns (_HelperCommentInfo[] memory hci)
    {
        Document storage doc = documents[documentKey];
        EnumerableSetUpgradeable.AddressSet storage signersSet = doc.signersSet;
        uint256 numOfSigners = signersSet.length();
        hci = new _HelperCommentInfo[](numOfSigners);
        for (uint256 i = 0; i < numOfSigners; ++i) {
            address signer = signersSet.at(i);
            bytes32 saltedAddressMappingKey = hashSaltedAddressMappingKey(
                documentKey,
                signer
            );
            hci[i].signer = signer;
            hci[i].commentStorageInfo = doc.commentsForSaltedAddress[
                saltedAddressMappingKey
            ];
        }
    }

    // Setters
    function newBasicDocument(
        bytes32 documentKey,
        bytes32 name,
        uint256 expiration,
        uint256 numOfSigners
    ) public whenNotPaused documentDoesNotExist(documentKey) {
        Document storage doc = documents[documentKey];
        doc.name = name;
        doc.birth = block.number;
        doc.expiration = expiration;
        doc.initiator = _msgSender();
        doc.numOfSigners = numOfSigners;
        createdByMe[_msgSender()].add(documentKey);
        emit LogNewDocument(
            doc.initiator,
            documentKey,
            doc.name,
            doc.numOfSigners,
            expiration
        );
    }

    function addSignerForDocument(bytes32 documentKey, address signer)
        public
        whenNotPaused
        documentDoesExist(documentKey)
        documentHasNotExpired(documentKey)
        onlyDocumentInitiator(documentKey)
        signersNotFinalizedForDocument(documentKey)
    {
        Document storage doc = documents[documentKey];
        doc.signersSet.add(signer);
        if (doc.initiator != signer) {
            sharedWithMe[signer].add(documentKey);
        }
        emit LogAddedNewSignerForDocument(signer, documentKey);
    }

    function setDocStorageForDocument(
        bytes32 documentKey,
        bytes32 provider,
        bytes32 storage_id0,
        bytes32 storage_id1
    )
        public
        whenNotPaused
        documentDoesExist(documentKey)
        documentHasNotExpired(documentKey)
        onlyDocumentInitiator(documentKey)
    {
        Document storage doc = documents[documentKey];
        StorageInfo storage doc_si = doc.docStorageInfo;
        doc_si.provider = provider;
        doc_si.storage_id0 = storage_id0;
        doc_si.storage_id1 = storage_id1;
        emit LogChangedDocumentStorage(
            documentKey,
            provider,
            storage_id0,
            storage_id1
        );
    }

    function setMetaStorageForDocument(
        bytes32 documentKey,
        bytes32 saltedDocumentMappingKey, // hashSaltedDocumentMappingKey(documentKey)
        bytes32 provider,
        bytes32 storage_id0,
        bytes32 storage_id1
    )
        public
        whenNotPaused
        documentDoesExist(documentKey)
        documentHasNotExpired(documentKey)
        onlyDocumentInitiator(documentKey)
    {
        Document storage doc = documents[documentKey];
        StorageInfo storage meta_si = doc.metadataStorageInfoForSaltedDocument[
            saltedDocumentMappingKey
        ];
        meta_si.provider = provider;
        meta_si.storage_id0 = storage_id0;
        meta_si.storage_id1 = storage_id1;
        emit LogChangedMetadataStorage(
            documentKey,
            provider,
            storage_id0,
            storage_id1
        );
    }

    // No need to check if signer exists in set since mapping key hash contains signer address
    // If signer does not exist, nothing adverse will happen
    function setNumberOfSignatureFieldsForSignerForDocument(
        bytes32 documentKey,
        bytes32 saltedAddressMappingKey, // hashSaltedAddressMappingKey(documentKey, signer)
        address signer,
        uint256 number
    )
        public
        whenNotPaused
        documentDoesExist(documentKey)
        documentHasNotExpired(documentKey)
        onlyDocumentInitiator(documentKey)
    {
        Document storage doc = documents[documentKey];
        require(
            doc.numOfSignatureFieldsForSaltedAddress[saltedAddressMappingKey] ==
                0,
            "NUM_SIG_EXISTS"
        );
        doc.numOfSignatureFieldsForSaltedAddress[
            saltedAddressMappingKey
        ] = number;
        emit LogSetNumberOfSignatureFields(documentKey, signer, number);
    }

    // No need to check if signer exists in set since mapping key hash contains signer address
    // If signer does not exist, the upper bound will be 0 and call will revert
    // Returns true if the signer is not replacing an existing signature
    function setSignatureFieldAtIndexAsSignerForDocument(
        bytes32 documentKey,
        uint256 index,
        bytes32 saltedAddressMappingKey, // hashSaltedAddressMappingKey(documentKey, _msgSender())
        bytes32 saltedMetaDocumentMappingKey, // hashSaltedMetaDocumentMappingKey(documentKey)
        bytes32 r,
        bytes32 s,
        uint8 v
    )
        public
        whenNotPaused
        documentDoesExist(documentKey)
        documentHasNotExpired(documentKey)
        onlyAuthorizedSigner(documentKey)
        returns (bool isNewSignature)
    {
        return
            _setSignatureFieldAtIndexAsSignerForDocument(
                documentKey,
                index,
                _msgSender(),
                saltedAddressMappingKey,
                saltedMetaDocumentMappingKey,
                r,
                s,
                v
            );
    }

    function _setSignatureFieldAtIndexAsSignerForDocument(
        bytes32 documentKey,
        uint256 index,
        address signer,
        bytes32 saltedAddressMappingKey, // hashSaltedAddressMappingKey(documentKey, _msgSender())
        bytes32 saltedMetaDocumentMappingKey, // hashSaltedMetaDocumentMappingKey(documentKey)
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal returns (bool isNewSignature) {
        Document storage doc = documents[documentKey];
        require(
            doc.numOfSigners == doc.signersSet.length(),
            "SIGNERS_NOT_FINALIZED"
        );
        require(
            index <
                doc.numOfSignatureFieldsForSaltedAddress[
                    saltedAddressMappingKey
                ],
            "OUT_OF_BOUNDS"
        );


            bytes32 saltedAddressWithIndexMappingKey
         = hashSaltedAddressWithIndexMappingKey(documentKey, signer, index);
        ECSignature storage ecs = doc.signatureFieldForSaltedAddressWithIndex[
            saltedAddressWithIndexMappingKey
        ];
        isNewSignature = ecs.r == 0;
        ecs.r = r;
        ecs.s = s;
        ecs.v = v;
        emit LogSignedDocumentSignatureField(documentKey, signer, index);
        if (isNewSignature) {
            ++doc.numOfSignedSignatureFieldsForSaltedAddress[
                saltedAddressMappingKey
            ];
            if (
                doc.numOfSignedSignatureFieldsForSaltedAddress[
                    saltedAddressMappingKey
                ] ==
                doc.numOfSignatureFieldsForSaltedAddress[
                    saltedAddressMappingKey
                ]
            ) {
                doc
                    .numOfSignedSignersSetForSaltedMetaDocument[
                    saltedMetaDocumentMappingKey
                ]
                    .add(signer);
                emit LogSignedDocument(documentKey, signer);
            }
        }
    }

    function setDocumentCommentsForSigner(
        bytes32 documentKey,
        bytes32 saltedAddressMappingKey, // hashSaltedAddressMappingKey(documentKey, _msgSender())
        bytes32 provider,
        bytes32 storage_id0,
        bytes32 storage_id1
    )
        external
        override
        whenNotPaused
        documentDoesExist(documentKey)
        documentHasNotExpired(documentKey)
    {
        _setDocumentCommentsForSigner(
            documentKey,
            saltedAddressMappingKey,
            provider,
            storage_id0,
            storage_id1
        );
    }

    function _setDocumentCommentsForSigner(
        bytes32 documentKey,
        bytes32 saltedAddressMappingKey, // hashSaltedAddressMappingKey(documentKey, _msgSender())
        bytes32 provider,
        bytes32 storage_id0,
        bytes32 storage_id1
    ) internal {
        Document storage doc = documents[documentKey];
        require(
            doc.signersSet.contains(_msgSender()) ||
                doc.initiator == _msgSender(),
            "COMMENT_UNAUTH"
        );
        StorageInfo storage si = doc.commentsForSaltedAddress[
            saltedAddressMappingKey
        ];
        if (si.provider == 0) {
            emit LogLeftNewCommentOnDocument(
                _msgSender(),
                documentKey,
                provider,
                storage_id0,
                storage_id1
            );
        } else {
            emit LogEditedCommentOnDocument(
                _msgSender(),
                documentKey,
                provider,
                storage_id0,
                storage_id1
            );
        }
        si.provider = provider;
        si.storage_id0 = storage_id0;
        si.storage_id1 = storage_id1;
    }

    function _archiveDocument(bytes32 documentKey)
        internal
        whenNotPaused
        documentDoesExist(documentKey)
    {
        EnumerableSetUpgradeable.Bytes32Set storage set = sharedWithMe[
            _msgSender()
        ];
        if (set.contains(documentKey)) {
            set.remove(documentKey);
        }
        set = createdByMe[_msgSender()];
        if (set.contains(documentKey)) {
            set.remove(documentKey);
        }
        set = archived[_msgSender()];
        set.add(documentKey);
        emit LogArchivedDocument(_msgSender(), documentKey);
    }

    function archiveDocuments(bytes32[] calldata documentKeys)
        external
        override
    {
        for (uint256 i = 0; i < documentKeys.length; ++i) {
            _archiveDocument(documentKeys[i]);
        }
    }

    // Functions for call aggregation
    function aggregateNewBasicDocumentAndSetStorage(
        bytes32 documentKey,
        bytes32 name,
        uint256 expiration,
        uint256 numOfSigners,
        bytes32[3] calldata providers, // doc provider, meta provider, comment provider
        bytes32[6] calldata storage_ids
    ) external override {
        newBasicDocument(documentKey, name, expiration, numOfSigners);
        setDocStorageForDocument(
            documentKey,
            providers[0],
            storage_ids[0],
            storage_ids[1]
        );
        bytes32 saltedDocumentMappingKey = hashSaltedDocumentMappingKey(
            documentKey
        );
        setMetaStorageForDocument(
            documentKey,
            saltedDocumentMappingKey,
            providers[1],
            storage_ids[2],
            storage_ids[3]
        );
        bytes32 saltedAddressMappingKey = hashSaltedAddressMappingKey(
            documentKey,
            _msgSender()
        );
        _setDocumentCommentsForSigner(
            documentKey,
            saltedAddressMappingKey,
            providers[2],
            storage_ids[4],
            storage_ids[5]
        );
    }

    function aggregateAddSignersAndNumOfSigFieldsForDocument(
        bytes32 documentKey,
        bytes32[] calldata saltedAddressMappingKeys,
        address[] calldata signers,
        uint256[] calldata numOfSigFields
    ) external override {
        require(
            saltedAddressMappingKeys.length == signers.length,
            "BAD_ARRAYS"
        );
        require(signers.length == numOfSigFields.length, "BAD_ARRAYS");
        for (uint256 i = 0; i < signers.length; ++i) {
            addSignerForDocument(documentKey, signers[i]);
            setNumberOfSignatureFieldsForSignerForDocument(
                documentKey,
                saltedAddressMappingKeys[i],
                signers[i],
                numOfSigFields[i]
            );
        }
    }

    function aggregateSetSigFieldAsSignerForDocument(
        bytes32 documentKey,
        uint256[] calldata indices,
        bytes32 saltedAddressMappingKey,
        bytes32 saltedMetaDocumentMappingKey,
        bytes32[] calldata r,
        bytes32[] calldata s,
        uint8[] calldata v
    ) external override {
        require(
            (r.length == s.length) &&
                (r.length == v.length) &&
                (indices.length == r.length),
            "BAD_ARRAYS"
        );
        for (uint256 i = 0; i < r.length; ++i) {
            setSignatureFieldAtIndexAsSignerForDocument( // Calls the public method since modifiers will throw "stack too deep" compilation error
                documentKey,
                indices[i],
                saltedAddressMappingKey,
                saltedMetaDocumentMappingKey,
                r[i],
                s[i],
                v[i]
            );
        }
    }

    function aggregateSetDocumentCommentsForSigner(
        bytes32 documentKey,
        bytes32[] calldata saltedAddressMappingKeys,
        bytes32[] calldata providers,
        bytes32[] calldata storage_id0s,
        bytes32[] calldata storage_id1s
    )
        external
        whenNotPaused
        documentDoesExist(documentKey)
        documentHasNotExpired(documentKey)
    {
        for (uint256 i = 0; i < saltedAddressMappingKeys.length; ++i) {
            _setDocumentCommentsForSigner(
                documentKey,
                saltedAddressMappingKeys[i],
                providers[i],
                storage_id0s[i],
                storage_id1s[i]
            );
        }
    }

    // Functions for relays
    function setSigFieldAsRelayForDocument(
        address signer,
        bytes32 documentKey,
        uint256 index,
        bytes calldata signature
    )
        external
        override
        whenNotPaused
        documentDoesExist(documentKey)
        documentHasNotExpired(documentKey)
    {

            bytes32 saltedAddressWithIndexMappingKey
         = hashSaltedAddressWithIndexMappingKey(documentKey, signer, index);
        require(
            verifyECSignatureSigner(
                signer,
                saltedAddressWithIndexMappingKey,
                signature
            ),
            "BAD_SIGN"
        );
        bytes32 saltedAddressMappingKey = hashSaltedAddressMappingKey(
            documentKey,
            signer
        );
        bytes32 saltedMetaDocumentMappingKey = hashSaltedMetaDocumentMappingKey(
            documentKey
        );
        (bytes32 r, bytes32 s, uint8 v) = splitECSignature(signature);
        _setSignatureFieldAtIndexAsSignerForDocument(
            documentKey,
            index,
            signer,
            saltedAddressMappingKey,
            saltedMetaDocumentMappingKey,
            r,
            s,
            v
        );
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title EthSign 3.0 Utility Interface
 * @dev Interface of various utility functions used in EthSign 3.0.
 */
abstract contract EthSignUtils {
    /**
     * @dev Hashes the input string using `keccak256(abi.encodePacked())`.
     * @param uuid The input string, usually UUID v4. But really, this is no restriction.
     */
    function hashDocumentKey(string calldata uuid)
        public
        pure
        virtual
        returns (bytes32);

    /**
     * @dev Generates a mapping key by packing document key and document storage information.
     * @param documentKey A valid documentKey, although there is no check.
     */
    function hashSaltedDocumentMappingKey(bytes32 documentKey)
        public
        view
        virtual
        returns (bytes32);

    /**
     * @dev Generates a mapping key by packing document key, document storage information, and document metadata storage information.
     * @param documentKey A valid documentKey, although there is no check.
     */
    function hashSaltedMetaDocumentMappingKey(bytes32 documentKey)
        public
        view
        virtual
        returns (bytes32);

    /**
     * @dev Generates a mapping key by packing document key, document storage information, document metadata storage information, and the signer's address.
     * @param documentKey A valid documentKey, although there is no check.
     * @param signer The signer's address.
     */
    function hashSaltedAddressMappingKey(bytes32 documentKey, address signer)
        public
        view
        virtual
        returns (bytes32);

    /**
     * @dev Generates a mapping key by packing document key, document storage information, document metadata storage information, the signer's address, and the signature field index.
     * @param documentKey A valid documentKey, although there is no check.
     * @param signer The signer's address.
     * @param index The signature field index.
     */
    function hashSaltedAddressWithIndexMappingKey(
        bytes32 documentKey,
        address signer,
        uint256 index
    ) public view virtual returns (bytes32);

    /**
     * @dev Verifies if a given ECDSA signature is authentic.
     * @param signer The signer's address.
     * @param hash The signed data, usually a hash.
     * @param signature The raw ECDSA signature.
     */
    function verifyECSignatureSigner(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) public view virtual returns (bool);

    /**
     * @dev Splits a given ECDSA signature into r, s, v.
     * @param signature The raw ECDSA signature.
     * @return r The r value of the ECDSA signature.
     * @return s The s value of the ECDSA signature.
     * @return v The v value of the ECDSA signature.
     */
    function splitECSignature(bytes memory signature)
        public
        pure
        virtual
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        );
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title EthSign 3.0 Interface
 * @dev EthSign 3.0 Smart Contract Interface
 * Please note that the word "document" in synonymous with "contract" in EthSign.
 * We avoided using the word "contract" to prevent confusion (it does NOT stand for the EthSign smart contract!).
 */
interface IEthSign {
    /**
     * @dev Struct used to record the storage info of various off-chain assets.
     */
    struct StorageInfo {
        bytes32 provider; // IP - IPFS, AR - Arweave; Comments are also xfdfs so they must use destorage too and be loaded dynamically
        bytes32 storage_id0; // hash that fits in 32 bytes
        bytes32 storage_id1; // extended support (e.g. Arweave with 43 bytes of storage ID)
    }

    /**
     * @dev Helper struct that streamlines return values.
     */
    struct _HelperSignerSignatureFieldStatus {
        address signer;
        bool[] fieldSigned;
    }

    /**
     * @dev Helper struct that streamlines return values.
     */
    struct _HelperCommentInfo {
        address signer;
        StorageInfo commentStorageInfo;
    }

    /**
     * @dev Total number of documents created by sender.
     */
    function getNumOfDocumentsCreatedByMe()
        external
        view
        returns (uint256 count);

    /**
     * @dev Total number of documents shared with sender.
     */
    function getNumOfDocumentsSharedWithMe()
        external
        view
        returns (uint256 count);

    /**
     * @dev Total number of documents archived by sender.
     */
    function getNumOfDocumentsArchived() external view returns (uint256 count);

    /**
     * @dev Gets the documentKey of the specified index within the createdByMe mapping.
     * @param index The index to query the documentKey of.
     * @return documentKey A bytes32 representing the documentKey.
     */
    function getDocumentCreatedByMeAtIndex(uint256 index)
        external
        view
        returns (bytes32 documentKey);

    /**
     * @dev Gets the documentKey of the specified index within the sharedWithMe mapping.
     * @param index The index to query the documentKey of.
     * @return documentKey A bytes32 representing the documentKey.
     */
    function getDocumentSharedWithMeAtIndex(uint256 index)
        external
        view
        returns (bytes32 documentKey);

    /**
     * @dev Gets the documentKey of the specified index within the archived mapping.
     * @param index The index to query the documentKey of.
     * @return documentKey A bytes32 representing the documentKey.
     */
    function getDocumentArchivedAtIndex(uint256 index)
        external
        view
        returns (bytes32 documentKey);

    /**
     * @dev Retrieves basic information of a document.
     * @param documentKey The documentKey of the document of interest.
     * @return initiator The initiator of this document.
     * @return name The name of the document.
     * @return birth The block number when the document is created.
     * @return expiration The expiration block of the document.
     * @return numOfSigners The total number of signers for this document.
     */
    function getDocumentBasicInfo(bytes32 documentKey)
        external
        view
        returns (
            address initiator,
            bytes32 name,
            uint256 birth,
            uint256 expiration,
            uint256 numOfSigners
        );

    /**
     * @dev Retrieves storage information of a document.
     * @param documentKey The documentKey of the document of interest.
     * @return docStorageProvider The storage provider. For example, IP = IPFS, AR = Arweave.
     * @return docStorage_id0 The first part of the CID.
     * @return docStorage_id1 The second part of the CID (if applicable).
     */
    function getDocumentDocStorageInfo(bytes32 documentKey)
        external
        view
        returns (
            bytes32 docStorageProvider,
            bytes32 docStorage_id0,
            bytes32 docStorage_id1
        );

    /**
     * @dev Retrieves metadata annontation storage information of a document.
     * @param documentKey The documentKey of the document of interest.
     * @return metaStorageProvider The storage provider. For example, IP = IPFS, AR = Arweave.
     * @return metaStorage_id0 The first part of the CID.
     * @return metaStorage_id1 The second part of the CID (if applicable).
     */
    function getDocumentMetaStorageInfo(bytes32 documentKey)
        external
        view
        returns (
            bytes32 metaStorageProvider,
            bytes32 metaStorage_id0,
            bytes32 metaStorage_id1
        );

    /**
     * @dev Gets the total number of signers added to a document.
     * @param documentKey The documentKey of the document of interest.
     * @return count The number of signers in total for the specified document.
     */
    function getNumberOfSignersForDocument(bytes32 documentKey)
        external
        view
        returns (uint256 count);

    /**
     * @dev Gets the address of the signer at the provided index in a document.
     * @param documentKey The documentKey of the document of interest.
     * @param index The index of the signer in the specified document.
     * @return signer The address of the signer at the provided index.
     */
    function getDocumentSignerAtIndex(bytes32 documentKey, uint256 index)
        external
        view
        returns (address signer);

    /**
     * @dev Gets the current total number of ECDSA signatures for a signer in a document.
     * @param signer The address of the signer.
     * @param documentKey The documentKey of the document of interest.
     * @return count The total number of ECDSA signatures for the specified signer in the specified current version of the document.
     */
    function getNumberOfDocumentECSignaturesForSigner(
        address signer,
        bytes32 documentKey
    ) external view returns (uint256 count);

    /**
     * @dev Gets the split ECDSA signature of a signer at an index in a document.
     * @param signer The address of the signer.
     * @param documentKey The documentKey of the document of interest.
     * @param index The index of the signature.
     * @return r The r value of the ECDSA signature.
     * @return s The s value of the ECDSA signature.
     * @return v The v value of the ECDSA signature.
     */
    function getDocumentECSignatureForSignerAtIndex(
        address signer,
        bytes32 documentKey,
        uint256 index
    )
        external
        view
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        );

    /**
     * @dev Gets the comment XFDF metadata file of a signer at an index in a document.
     * @param signer The address of the signer.
     * @param documentKey The documentKey of the document of interest.
     * @return provider The storage provider. For example, IP = IPFS, AR = Arweave.
     * @return storage_id0 The first part of the CID.
     * @return storage_id1 The second part of the CID (if applicable).
     */
    function getDocumentCommentsForSigner(address signer, bytes32 documentKey)
        external
        view
        returns (
            bytes32 provider,
            bytes32 storage_id0,
            bytes32 storage_id1
        );

    /**
     * @dev Gets the status of a document.
     * @param documentKey The documentKey of the document of interest.
     * @return totalSigners The total number of signers.
     * @return signedSigners The number of signers who have signed all signature fields.
     */
    function getDocumentStatus(bytes32 documentKey)
        external
        view
        returns (uint256 totalSigners, uint256 signedSigners);

    /**
     * @dev Gets the status of each signature field of each signer in a document.
     * @param documentKey The documentKey of the document of interest.
     * @return fieldSignedInfo .
     */
    function aggregateGetIsSignedForAllSignatureFields(bytes32 documentKey)
        external
        view
        returns (_HelperSignerSignatureFieldStatus[] memory fieldSignedInfo);

    /**
     * @dev Gets the comment file of each signer in a document.
     * @param documentKey The documentKey of the document of interest.
     * @return hci .
     */
    function aggregateGetAllCommentsOfAllSigners(bytes32 documentKey)
        external
        view
        returns (_HelperCommentInfo[] memory hci);

    /**
     * @dev Creates a new document.
     * @param documentKey The documentKey of the new document. Will revert if documentKey exists.
     * @param name The name of the new document.
     * @param expiration The intended expiration block of the new document.
     * @param numOfSigners The intended total number of signers. Please note signers are added in a separate step.
     * @param providers The document, metadata, and comment storage providers in an ordered array.
     * @param storage_ids The document storage and metadata storage CIDs in an ordered array: `[doc_storage_id0, doc_storage_id1, meta_storage_id0, meta_storage_id1, comment_storage_id0, comment_storage_id1]`.
     */
    function aggregateNewBasicDocumentAndSetStorage(
        bytes32 documentKey,
        bytes32 name,
        uint256 expiration,
        uint256 numOfSigners,
        bytes32[3] calldata providers,
        bytes32[6] calldata storage_ids
    ) external;

    /**
     * @dev Populates signers and number of signature fields for each for a new document.
     * @param documentKey The documentKey of the specified document. Will revert if documentKey does not exist.
     * @param saltedAddressMappingKeys An ordered array, includes the salted document+metadata+signer mapping key of each signer in the document. Use `function hashSaltedAddressMappingKey(bytes32 documentKey, address signer)` to generate.
     * @param signers An ordered array, includes the addresses of all signers.
     * @param numOfSigFields An ordered array, includes the number of signature fields intended for each signer.
     */
    function aggregateAddSignersAndNumOfSigFieldsForDocument(
        bytes32 documentKey,
        bytes32[] calldata saltedAddressMappingKeys,
        address[] calldata signers,
        uint256[] calldata numOfSigFields
    ) external;

    /**
     * @dev Populates all assigned signature fields in a document as a signer with their ECDSA signatures.
     * @param documentKey The documentKey of the specified document. Will revert if documentKey does not exist.
     * @param indices An ordered array, includes the index of the signature fields of each signer in the document.
     * @param saltedAddressMappingKey The salted document+metadata+signer mapping key of each signer in the document. Use `function hashSaltedAddressMappingKey(bytes32 documentKey, address signer)` to generate.
     * @param saltedMetaDocumentMappingKey The salted document+metadata mapping key of the document. Use `function hashSaltedMetaDocumentMappingKey(bytes32 documentKey)` to generate.
     * @param r The ordered r values of each ECDSA signature.
     * @param s The ordered s values of each ECDSA signature.
     * @param v The ordered v values of each ECDSA signature.
     */
    function aggregateSetSigFieldAsSignerForDocument(
        bytes32 documentKey,
        uint256[] calldata indices,
        bytes32 saltedAddressMappingKey,
        bytes32 saltedMetaDocumentMappingKey,
        bytes32[] calldata r,
        bytes32[] calldata s,
        uint8[] calldata v
    ) external;

    /**
     * @dev Sets the comment XFDF metadata file for a specified and current document as a signer.
     * @param documentKey The documentKey of the specified document. Will revert if documentKey does not exist.
     * @param saltedAddressMappingKey The salted document+metadata+signer mapping key of each signer in the document. Use `function hashSaltedAddressMappingKey(bytes32 documentKey, address signer)` to generate.
     * @param provider The storage provider. For example, IP = IPFS, AR = Arweave.
     * @param storage_id0 The first part of the CID.
     * @param storage_id1 The second part of the CID (if applicable).
     */
    function setDocumentCommentsForSigner(
        bytes32 documentKey,
        bytes32 saltedAddressMappingKey,
        bytes32 provider,
        bytes32 storage_id0,
        bytes32 storage_id1
    ) external;

    /**
     * @dev Archives the specified documents as a signer (does not affect other signers).
     * @param documentKeys The documentKeys of the specified documents. Will revert if any documentKey does not exist.
     */
    function archiveDocuments(bytes32[] calldata documentKeys) external;

    /**
     * @dev Sets the ECDSA signature for a signer as a third party.
     * @param signer The address of the signer.
     * @param documentKey The documentKey of the specified document. Will revert if documentKey does not exist.
     * @param index The index of this particular signature.
     * @param signature The raw ECDSA signature, which will be validated on-chain. Will revert if validation fails.
     */
    function setSigFieldAsRelayForDocument(
        address signer,
        bytes32 documentKey,
        uint256 index,
        bytes calldata signature
    ) external;

    event LogContractPaused();

    event LogContractUnpaused();

    event LogNewDocument(
        address indexed initiator,
        bytes32 indexed documentKey,
        bytes32 indexed documentName,
        uint256 numOfSigners,
        uint256 expiration
    );

    event LogAddedNewSignerForDocument(
        address indexed signer,
        bytes32 indexed documentKey
    );

    event LogChangedDocumentStorage(
        bytes32 indexed documentKey,
        bytes32 provider,
        bytes32 storage_id0,
        bytes32 storage_id1
    );

    event LogChangedMetadataStorage(
        bytes32 indexed documentKey,
        bytes32 provider,
        bytes32 storage_id0,
        bytes32 storage_id1
    );

    event LogSetNumberOfSignatureFields(
        bytes32 indexed documentKey,
        address indexed signer,
        uint256 number
    );

    event LogSignedDocumentSignatureField(
        bytes32 indexed documentKey,
        address indexed signer,
        uint256 index
    );

    event LogSignedDocument(
        bytes32 indexed documentKey,
        address indexed signer
    );

    event LogLeftNewCommentOnDocument(
        address indexed author,
        bytes32 indexed documentKey,
        bytes32 provider,
        bytes32 storage_id0,
        bytes32 storage_id1
    );

    event LogEditedCommentOnDocument(
        address indexed author,
        bytes32 indexed documentKey,
        bytes32 provider,
        bytes32 storage_id0,
        bytes32 storage_id1
    );

    event LogArchivedDocument(
        address indexed party,
        bytes32 indexed documentKey
    );
}

