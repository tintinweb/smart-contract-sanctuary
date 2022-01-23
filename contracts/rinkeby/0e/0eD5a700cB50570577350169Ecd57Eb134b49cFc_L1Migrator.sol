// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
 * @dev String operations.
 */
library Strings {
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

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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

import "./ECDSA.sol";

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
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

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
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
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
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL1LPTGateway {
    event DepositInitiated(
        address _l1Token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _sequenceNumber,
        uint256 _amount
    );

    event WithdrawalFinalized(
        address _l1Token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _exitNum,
        uint256 _amount
    );

    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external;

    // if token is not supported this should return 0x0 address
    function calculateL2TokenAddress(address l1Token)
        external
        view
        returns (address);

    // used by router
    function counterpartGateway() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBridge} from "../../arbitrum/IBridge.sol";
import {IInbox} from "../../arbitrum/IInbox.sol";
import {IOutbox} from "../../arbitrum/IOutbox.sol";

abstract contract L1ArbitrumMessenger {
    IInbox public immutable inbox;

    event TxToL2(
        address indexed from,
        address indexed to,
        uint256 indexed seqNum,
        bytes data
    );

    constructor(address _inbox) {
        inbox = IInbox(_inbox);
    }

    modifier onlyL2Counterpart(address l2Counterpart) {
        // a message coming from the counterpart gateway was executed by the bridge
        address bridge = inbox.bridge();
        require(msg.sender == bridge, "NOT_FROM_BRIDGE");

        // and the outbox reports that the L2 address of the sender is the counterpart gateway
        address l2ToL1Sender = IOutbox(IBridge(bridge).activeOutbox())
            .l2ToL1Sender();
        require(l2ToL1Sender == l2Counterpart, "ONLY_COUNTERPART_GATEWAY");
        _;
    }

    function sendTxToL2(
        address target,
        address from,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes memory data
    ) internal returns (uint256) {
        return
            sendTxToL2(
                target,
                from,
                msg.value,
                0, // we always assume that l2CallValue = 0
                maxSubmissionCost,
                maxGas,
                gasPriceBid,
                data
            );
    }

    function sendTxToL2(
        address target,
        address from,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes memory data
    ) internal returns (uint256) {
        uint256 seqNum = inbox.createRetryableTicket{value: _l1CallValue}(
            target,
            _l2CallValue,
            maxSubmissionCost,
            from,
            from,
            maxGas,
            gasPriceBid,
            data
        );
        emit TxToL2(from, target, seqNum, data);
        return seqNum;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {L1ArbitrumMessenger} from "./L1ArbitrumMessenger.sol";
import {IL1LPTGateway} from "./IL1LPTGateway.sol";
import {IMigrator} from "../../interfaces/IMigrator.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IBondingManager {
    function isRegisteredTranscoder(address _addr) external view returns (bool);

    function pendingStake(address _addr, uint256 _endRound)
        external
        view
        returns (uint256);

    function pendingFees(address _addr, uint256 _endRound)
        external
        view
        returns (uint256);

    function getDelegator(address _addr)
        external
        view
        returns (
            uint256 bondedAmount,
            uint256 fees,
            address delegateAddress,
            uint256 delegatedAmount,
            uint256 startRound,
            uint256 lastClaimRound,
            uint256 nextUnbondingLockId
        );

    function getDelegatorUnbondingLock(address _addr, uint256 _unbondingLockId)
        external
        view
        returns (uint256 amount, uint256 withdrawRound);
}

interface ITicketBroker {
    struct Sender {
        uint256 deposit;
        uint256 withdrawRound;
    }

    struct ReserveInfo {
        uint256 fundsRemaining;
        uint256 claimedInCurrentRound;
    }

    function getSenderInfo(address _addr)
        external
        view
        returns (Sender memory sender, ReserveInfo memory reserve);
}

interface IBridgeMinter {
    function withdrawETHToL1Migrator() external returns (uint256);

    function withdrawLPTToL1Migrator() external returns (uint256);
}

interface ApproveLike {
    function approve(address _addr, uint256 _amount) external;
}

interface IL2Migrator is IMigrator {
    function finalizeMigrateDelegator(MigrateDelegatorParams memory _params)
        external;

    function finalizeMigrateUnbondingLocks(
        MigrateUnbondingLocksParams memory _params
    ) external;

    function finalizeMigrateSender(MigrateSenderParams memory _params) external;
}

contract L1Migrator is
    L1ArbitrumMessenger,
    IMigrator,
    EIP712,
    AccessControl,
    Pausable
{
    address public immutable bondingManagerAddr;
    address public immutable ticketBrokerAddr;
    address public immutable bridgeMinterAddr;
    address public immutable tokenAddr;
    address public immutable l1LPTGatewayAddr;
    address public immutable l2MigratorAddr;

    event MigrateDelegatorInitiated(
        uint256 indexed seqNo,
        MigrateDelegatorParams params
    );

    event MigrateUnbondingLocksInitiated(
        uint256 indexed seqNo,
        MigrateUnbondingLocksParams params
    );

    event MigrateSenderInitiated(
        uint256 indexed seqNo,
        MigrateSenderParams params
    );

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    bytes32 private constant MIGRATE_DELEGATOR_TYPE_HASH =
        keccak256("MigrateDelegator(address l1Addr,address l2Addr)");

    bytes32 private constant MIGRATE_UNBONDING_LOCKS_TYPE_HASH =
        keccak256(
            "MigrateUnbondingLocks(address l1Addr,address l2Addr,uint256[] unbondingLockIds)"
        );

    bytes32 private constant MIGRATE_SENDER_TYPE_HASH =
        keccak256("MigrateSender(address l1Addr,address l2Addr)");

    constructor(
        address _inbox,
        address _bondingManagerAddr,
        address _ticketBrokerAddr,
        address _bridgeMinterAddr,
        address _tokenAddr,
        address _l1LPTGatewayAddr,
        address _l2MigratorAddr
    ) L1ArbitrumMessenger(_inbox) EIP712("Livepeer L1Migrator", "1") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(GOVERNOR_ROLE, DEFAULT_ADMIN_ROLE);

        bondingManagerAddr = _bondingManagerAddr;
        ticketBrokerAddr = _ticketBrokerAddr;
        bridgeMinterAddr = _bridgeMinterAddr;
        tokenAddr = _tokenAddr;
        l1LPTGatewayAddr = _l1LPTGatewayAddr;
        l2MigratorAddr = _l2MigratorAddr;

        _pause();
    }

    /**
     * @notice Executes a L2 call to L2Migrator to migrate transcoder/delegator state from the L1 BondingManager.
     * @dev The term "delegator" here can refer to both a transcoder (self-delegated delegator) and delegator.
     * @param _l1Addr Address migrating from L1
     * @param _l2Addr Address to use on L2
     * @param _sig Optional EIP-712 signature over a payload that includes _l1Addr and _l2Addr
     * @param _maxGas Gas limit for L2 execution
     * @param _gasPriceBid Gas price bid for L2 execution
     * @param _maxSubmissionCost Max ETH to pay for retryable ticket base submission fee
     */
    function migrateDelegator(
        address _l1Addr,
        address _l2Addr,
        bytes memory _sig,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable whenNotPaused {
        // Authorization
        // Either msg.sender == _l1Addr OR signer for _sig == _l1Addr
        requireValidMigration(
            _l1Addr,
            _l2Addr,
            keccak256(
                abi.encode(MIGRATE_DELEGATOR_TYPE_HASH, _l1Addr, _l2Addr)
            ),
            _sig
        );

        (
            bytes memory data,
            MigrateDelegatorParams memory params
        ) = getMigrateDelegatorParams(_l1Addr, _l2Addr);

        // We do not prevent migration replays here to minimize L1 gas costs
        // The L2Migrator is responsible for rejecting migration replays

        uint256 seqNo = sendTxToL2(
            l2MigratorAddr,
            _l2Addr, // Refunds to the L2 address
            _maxSubmissionCost,
            _maxGas,
            _gasPriceBid,
            data
        );

        emit MigrateDelegatorInitiated(seqNo, params);
    }

    /**
     * @notice Executes a L2 call to L2Migrator to migrate unbonding locks state from the L1 BondingManager.
     * @param _l1Addr Address migrating from L1
     * @param _l2Addr Address to use on L2
     * @param _unbondingLockIds IDs of unbonding locks in the L1 BondingManager to migrate
     * @param _sig Optional EIP-712 signature over a payload that includes _l1Addr, _l2Addr and _unbondingLockIds
     * @param _maxGas Gas limit for L2 execution
     * @param _gasPriceBid Gas price bid for L2 execution
     * @param _maxSubmissionCost Max ETH to pay for retryable ticket base submission fee
     */
    function migrateUnbondingLocks(
        address _l1Addr,
        address _l2Addr,
        uint256[] calldata _unbondingLockIds,
        bytes memory _sig,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable whenNotPaused {
        // Authorization
        // Either msg.sender == _l1Addr OR signer for _sig == _l1Addr
        requireValidMigration(
            _l1Addr,
            _l2Addr,
            keccak256(
                abi.encode(
                    MIGRATE_UNBONDING_LOCKS_TYPE_HASH,
                    _l1Addr,
                    _l2Addr,
                    keccak256(abi.encodePacked(_unbondingLockIds))
                )
            ),
            _sig
        );

        (
            bytes memory data,
            MigrateUnbondingLocksParams memory params
        ) = getMigrateUnbondingLocksParams(_l1Addr, _l2Addr, _unbondingLockIds);

        // We do not prevent migration replays here to minimize L1 gas costs
        // The L2Migrator is responsible for rejecting migration replays

        uint256 seqNo = sendTxToL2(
            l2MigratorAddr,
            _l2Addr, // Refund to the L2 address
            _maxSubmissionCost,
            _maxGas,
            _gasPriceBid,
            data
        );

        emit MigrateUnbondingLocksInitiated(seqNo, params);
    }

    /**
     * @notice Executes a L2 call to L2Migrator to migrate sender deposit/reserve state from the L1 TicketBroker.
     * @param _l1Addr Address migrating from L1
     * @param _l2Addr Address to use on L2
     * @param _sig Optional EIP-712 signature over a payload that includes _l1Addr and _l2Addr
     * @param _maxGas Gas limit for L2 execution
     * @param _gasPriceBid Gas price bid for L2 execution
     * @param _maxSubmissionCost Max ETH to pay for retryable ticket base submission fee
     */
    function migrateSender(
        address _l1Addr,
        address _l2Addr,
        bytes memory _sig,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable whenNotPaused {
        // Authorization
        // Either msg.sender == _l1Addr OR signer for _sig == _l1Addr
        requireValidMigration(
            _l1Addr,
            _l2Addr,
            keccak256(abi.encode(MIGRATE_SENDER_TYPE_HASH, _l1Addr, _l2Addr)),
            _sig
        );

        (
            bytes memory data,
            MigrateSenderParams memory params
        ) = getMigrateSenderParams(_l1Addr, _l2Addr);

        // We do not prevent migration replays here to minimize L1 gas costs
        // The L2Migrator is responsible for rejecting migration replays

        uint256 seqNo = sendTxToL2(
            l2MigratorAddr,
            _l2Addr, // Refund to the L2 address
            _maxSubmissionCost,
            _maxGas,
            _gasPriceBid,
            data
        );

        emit MigrateSenderInitiated(seqNo, params);
    }

    /**
     * @notice Executes a L2 call to send ETH from the L1BridgeMinter to the L2Migrator.
     * @dev Anyone can call this function.
     * @param _maxGas Gas limit for L2 execution
     * @param _gasPriceBid Gas price bid for L2 execution
     * @param _maxSubmissionCost Max ETH to pay for retryable ticket base submission fee
     */
    function migrateETH(
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable whenNotPaused {
        uint256 amount = IBridgeMinter(bridgeMinterAddr)
            .withdrawETHToL1Migrator();

        // Any ETH refunded to the L2 alias of this contract can be used for
        // other cross-chain txs sent by this contract.
        // The retryable ticket created will not be cancellable since this contract
        // currently does not support cross-chain txs to call ArbRetryableTx.cancel().
        // Regarding the comment below on this contract receiving refunds:
        // msg.sender also cannot be the address to receive refunds as beneficiary because otherwise
        // msg.sender could cancel the ticket before it is executed on L2 to receive the L2 call value.
        sendTxToL2(
            l2MigratorAddr,
            address(this), // L2 alias of this contract will receive refunds
            msg.value,
            amount,
            _maxSubmissionCost,
            _maxGas,
            _gasPriceBid,
            ""
        );
    }

    /**
     * @notice Executes a L2 call to send LPT from the L1BridgeMinter to the L2Migrator.
     * @dev Anyone can call this function.
     * @param _maxGas Gas limit for L2 execution
     * @param _gasPriceBid Gas price bid for L2 execution
     * @param _maxSubmissionCost Max ETH to pay for retryable ticket base submission fee
     */
    function migrateLPT(
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable whenNotPaused {
        uint256 amount = IBridgeMinter(bridgeMinterAddr)
            .withdrawLPTToL1Migrator();

        // Approve L1LPTGateway to pull tokens
        ApproveLike(tokenAddr).approve(l1LPTGatewayAddr, amount);
        // Trigger cross-chain transfer with L1LPTGateway which will pull and escrow tokens
        // Forward msg.value to outboundTransfer() to be used for cross-chain tx
        IL1LPTGateway(l1LPTGatewayAddr).outboundTransfer{value: msg.value}(
            tokenAddr,
            l2MigratorAddr,
            amount,
            _maxGas,
            _gasPriceBid,
            abi.encode(_maxSubmissionCost, "")
        );
    }

    /**
     * @notice Pause the contract
     * @dev Only callable by addresses with governor role
     */
    function pause() external onlyRole(GOVERNOR_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract
     * @dev Only callable by addresses with governor role
     */
    function unpause() external onlyRole(GOVERNOR_ROLE) {
        _unpause();
    }

    /**
     * @notice Return L2 calldata and MigrateDelegatorParams to use for a L2 call on L2Migrator
     * @param _l1Addr Address migrating from L1
     * @param _l2Addr Address to use on L2
     * @return data L2 calldata for finalizeMigrateDelegator() in L2Migrator
     * @return params MigrateDelegatorParams to use for finalizeMigrateDelegator() in L2Migrator
     */
    function getMigrateDelegatorParams(address _l1Addr, address _l2Addr)
        public
        view
        returns (bytes memory data, MigrateDelegatorParams memory params)
    {
        IBondingManager bondingManager = IBondingManager(bondingManagerAddr);

        // pendingStake() ignores the _endRound arg
        uint256 stake = bondingManager.pendingStake(_l1Addr, 0);
        // pendingFees() ignores the _endRound arg
        uint256 fees = bondingManager.pendingFees(_l1Addr, 0);
        (
            ,
            ,
            address delegateAddress,
            uint256 delegatedAmount,
            ,
            ,

        ) = bondingManager.getDelegator(_l1Addr);

        // Construct params and L2 calldata for finalizeMigrateDelegator() on L2Migrator
        params = MigrateDelegatorParams({
            l1Addr: _l1Addr,
            l2Addr: _l2Addr,
            stake: stake,
            delegatedStake: delegatedAmount,
            fees: fees,
            delegate: delegateAddress
        });

        data = abi.encodeWithSelector(
            IL2Migrator.finalizeMigrateDelegator.selector,
            params
        );
    }

    /**
     * @notice Return L2 calldata and MigrateSenderParams to use for a L2 call on L2Migrator
     * @param _l1Addr Address migrating from L1
     * @param _l2Addr Address to use on L2
     * @return data L2 calldata for finalizeMigrateSender() in L2Migrator
     * @return params MigrateSenderParams to use for finalizeMigrateSender() in L2Migrator
     */
    function getMigrateSenderParams(address _l1Addr, address _l2Addr)
        public
        view
        returns (bytes memory data, MigrateSenderParams memory params)
    {
        ITicketBroker ticketBroker = ITicketBroker(ticketBrokerAddr);

        (
            ITicketBroker.Sender memory sender,
            ITicketBroker.ReserveInfo memory reserveInfo
        ) = ticketBroker.getSenderInfo(_l1Addr);

        // Construct params and L2 calldata for finalizeMigrateSender() on L2Migrator
        params = MigrateSenderParams({
            l1Addr: _l1Addr,
            l2Addr: _l2Addr,
            deposit: sender.deposit,
            reserve: reserveInfo.fundsRemaining
        });

        data = abi.encodeWithSelector(
            IL2Migrator.finalizeMigrateSender.selector,
            params
        );
    }

    /**
     * @notice Return L2 calldata and MigrateUnbondingLocksParams to use for a L2 call on L2Migrator
     * @param _l1Addr Address migrating from L1
     * @param _l2Addr Address to use on L2
     * @param _unbondingLockIds IDs of unbonding locks in L1 BondingManager to migrate
     * @return data L2 calldata for finalizeMigrateUnbondingLocks() in L2Migrator
     * @return params MigrateUnbondingLocksParams to use for finalizeMigrateUnbondingLocks() in L2Migrator
     */
    function getMigrateUnbondingLocksParams(
        address _l1Addr,
        address _l2Addr,
        uint256[] memory _unbondingLockIds
    )
        public
        view
        returns (bytes memory data, MigrateUnbondingLocksParams memory params)
    {
        IBondingManager bondingManager = IBondingManager(bondingManagerAddr);

        uint256 total = 0;
        for (uint256 i = 0; i < _unbondingLockIds.length; i++) {
            (uint256 amount, ) = bondingManager.getDelegatorUnbondingLock(
                _l1Addr,
                _unbondingLockIds[i]
            );

            total += amount;
        }

        (, , address delegateAddress, , , , ) = bondingManager.getDelegator(
            _l1Addr
        );

        // Construct params and L2 calldata for finalizeMigrateUnbondingLocks() on L2Migrator
        params = MigrateUnbondingLocksParams({
            l1Addr: _l1Addr,
            l2Addr: _l2Addr,
            total: total,
            unbondingLockIds: _unbondingLockIds,
            delegate: delegateAddress
        });

        data = abi.encodeWithSelector(
            IL2Migrator.finalizeMigrateUnbondingLocks.selector,
            params
        );
    }

    function requireValidMigration(
        address _l1Addr,
        address _l2Addr,
        bytes32 _structHash,
        bytes memory _sig
    ) internal view {
        require(
            _l2Addr != address(0),
            "L1Migrator#requireValidMigration: INVALID_L2_ADDR"
        );
        require(
            msg.sender == _l1Addr ||
                recoverSigner(_structHash, _sig) == _l1Addr,
            "L1Migrator#requireValidMigration: FAIL_AUTH"
        );
    }

    function recoverSigner(bytes32 _structHash, bytes memory _sig)
        internal
        view
        returns (address)
    {
        if (_sig.length == 0) {
            return address(0);
        }

        bytes32 hash = _hashTypedDataV4(_structHash);
        return ECDSA.recover(hash, _sig);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed destAddr,
        uint256 amount,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "./IMessageProvider.sol";

interface IInbox is IMessageProvider {
    function sendL2Message(bytes calldata messageData)
        external
        returns (uint256);

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicketNoRefundAliasRewrite(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(uint256 maxSubmissionCost)
        external
        payable
        returns (uint256);

    function bridge() external view returns (address);

    function pauseCreateRetryables() external;

    function unpauseCreateRetryables() external;

    function startRewriteAddress() external;

    function stopRewriteAddress() external;
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

interface IOutbox {
    event OutboxEntryCreated(
        uint256 indexed batchNum,
        uint256 outboxEntryIndex,
        bytes32 outputRoot,
        uint256 numInBatch
    );
    event OutBoxTransactionExecuted(
        address indexed destAddr,
        address indexed l2Sender,
        uint256 indexed outboxEntryIndex,
        uint256 transactionIndex
    );

    function l2ToL1Sender() external view returns (address);

    function l2ToL1Block() external view returns (uint256);

    function l2ToL1EthBlock() external view returns (uint256);

    function l2ToL1Timestamp() external view returns (uint256);

    function l2ToL1BatchNum() external view returns (uint256);

    function l2ToL1OutputId() external view returns (bytes32);

    function processOutgoingMessages(
        bytes calldata sendsData,
        uint256[] calldata sendLengths
    ) external;

    function outboxEntryExists(uint256 batchNum) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMigrator {
    struct MigrateDelegatorParams {
        // Address that is migrating from L1
        address l1Addr;
        // Address to use on L2
        // If null, l1Addr is used on L2
        address l2Addr;
        // Stake of l1Addr on L1
        uint256 stake;
        // Delegated stake of l1Addr on L1
        uint256 delegatedStake;
        // Fees of l1Addr on L1
        uint256 fees;
        // Delegate of l1Addr on L1
        address delegate;
    }

    struct MigrateUnbondingLocksParams {
        // Address that is migrating from L1
        address l1Addr;
        // Address to use on L2
        // If null, l1Addr is used on L2
        address l2Addr;
        // Total tokens in unbonding locks
        uint256 total;
        // IDs of unbonding locks being migrated
        uint256[] unbondingLockIds;
        // Delegate of l1Addr on L1
        address delegate;
    }

    struct MigrateSenderParams {
        // Address that is migrating from L1
        address l1Addr;
        // Address to use on L2
        // If null, l1Addr is used on L2
        address l2Addr;
        // Deposit of l1Addr on L1
        uint256 deposit;
        // Reserve of l1Addr on L1
        uint256 reserve;
    }
}