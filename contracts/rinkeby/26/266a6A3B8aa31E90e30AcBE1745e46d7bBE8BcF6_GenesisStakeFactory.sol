pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "../interfaces/factorys/IGenesisStakeFactory.sol";
import "../interfaces/registers/IStakingRegister.sol";
import "../management/Managed.sol";
import "../management/Constants.sol";
import "../stakings/GenesisStaking.sol";

contract GenesisStakeFactory is IGenesisStakeFactory, Managed, EIP712 {
    address public registeredSigner;
    address public ownership;
    IStakingRegister public stakingRegister;
    mapping(address => uint256) public nonces;

    bytes32 private immutable _CONTAINER_TYPEHASE =
        keccak256(
            "Container(string stakingName,bool isETHStake,bool isPrivate,bool isCanTakeReward,address stakedToken,uint256 startBlock,uint256 duration,uint256 nonce)"
        );

    constructor(address _management)
        Managed(_management)
        EIP712("GenesisStakeFactory", "v1")
    {}

    function setDependency() external override onlyOwner {
        registeredSigner = management.contractRegistry(ADDRESS_SIGNER);
        stakingRegister = IStakingRegister(
            management.contractRegistry(CONTRACT_STAKING_REGISTER)
        );
        ownership = management.contractRegistry(ADDRESS_OWNER);
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function createGenesisStaking(
        string memory _stakingName,
        bool _isETHStake,
        bool _isPrivate,
        bool _isCanTakeReward,
        address _stakedToken,
        uint256 _startBlock,
        uint256 _duration,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        bool isAdmin = hasPermission(_msgSender(), ROLE_ADMIN);
        bool isRegular = hasPermission(_msgSender(), ROLE_REGULAR);
        require(
            isAdmin || isRegular,
            "GenesisFactory: You don't have permission's"
        );
        if (!isAdmin) {
            bytes32 structHash = keccak256(
                abi.encode(
                    _CONTAINER_TYPEHASE,
                    keccak256(bytes(_stakingName)),
                    _isETHStake,
                    _isPrivate,
                    _isCanTakeReward,
                    _stakedToken,
                    _startBlock,
                    _duration,
                    _useNonce(msg.sender)
                )
            );
            bytes32 hash = _hashTypedDataV4(structHash);
            address signer = ECDSA.recover(hash, v, r, s);

            require(
                signer == registeredSigner,
                "GenesisFactory: Invalid signer"
            );
        }
        uint256 defaultFeePercentage = stakingRegister
        .getDefaultFeePercentage();

        GenesisStaking staking = new GenesisStaking(
            address(management),
            _stakingName,
            _isETHStake,
            _isPrivate,
            _isCanTakeReward,
            _stakedToken,
            _startBlock,
            _duration,
            defaultFeePercentage
        );
        staking.setDependency();
        staking.transferOwnership(ownership);
        stakingRegister.add(msg.sender, address(staking), false);
    }

    function _useNonce(address owner) internal virtual returns (uint256) {
        uint256 nonce = nonces[owner];
        nonces[owner] = nonces[owner] + 1;
        return nonce;
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/stakings/IStaking.sol";
import "../interfaces/registers/IStakingRegister.sol";
import "../management/Managed.sol";
import "../management/Constants.sol";
import "../libraries/DecimalsConverter.sol";

contract GenesisStaking is IStaking, Managed {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using Address for address payable;

    address public stakingRegister;
    address[] public rewardTokenAddress;
    mapping(address => uint256) public rewardTokenAddressIndex;

    mapping(address => RewardInfo) public rewardsInfo;
    mapping(address => uint256) internal staked;
    address payable internal tresuary;
    string public name;

    bool public isPrivate;
    bool public canTakeReward;

    uint256 public immutable startBlock;
    uint256 public depositFee;

    uint256 public totalStaked;
    uint256 public lastUpdateBlock;
    address public immutable stakedToken;
    uint256 public rewardEndBlock;

    uint256 public stakedDecimals;

    modifier updateRewards(address addr) {
        _updateRewards(addr);
        _;
    }

    modifier canHarvest() {
        require(canTakeReward, "GS: It is not allowed to take the reward");
        _;
    }

    modifier canStake(bool value) {
        require(value, "GS: Not accepted for stake");
        _;
    }

    constructor(
        address _management,
        string memory _stakingName,
        bool _isETHStake,
        bool _isPrivate,
        bool _canTakeReward,
        address _stakedToken,
        uint256 _startBlock,
        uint256 _durationBlock,
        uint256 _depositFee
    ) Managed(_management) {
        require(
            _isETHStake || _stakedToken != address(0),
            "GS: not correct staked token address"
        );

        name = _stakingName;
        startBlock = _startBlock;
        rewardEndBlock = _startBlock + _durationBlock;
        lastUpdateBlock = _startBlock;
        isPrivate = _isPrivate;
        canTakeReward = _canTakeReward;
        depositFee = _depositFee;
        stakedToken = _stakedToken;

        if (_isETHStake) {
            stakedDecimals = 18;
        } else {
            stakedDecimals = IERC20Metadata(_stakedToken).decimals();
        }
    }

    function setDependency() external override onlyOwner {
        stakingRegister = management.contractRegistry(
            CONTRACT_STAKING_REGISTER
        );
        tresuary = payable(management.contractRegistry(ADDRESS_TRESUARY));
    }

    function getRewardsPerBlockInfo(address _rewardTokens)
        external
        view
        override
        returns (uint256 rewardPerBlock)
    {
        return rewardsInfo[_rewardTokens].rewardPerBlock;
    }

    function getRewardsPerBlockInfos()
        external
        view
        override
        returns (address[] memory rewardTokens, uint256[] memory rewardPerBlock)
    {
        uint256 size = rewardTokenAddress.length;
        rewardTokens = new address[](size);
        rewardPerBlock = new uint256[](size);

        for (uint256 i = 0; i < size; i++) {
            address token = rewardTokenAddress[i];
            rewardTokens[i] = token;
            rewardPerBlock[i] = rewardsInfo[token].rewardPerBlock;
        }
    }

    function getTimePoint() external view override returns (uint256, uint256) {
        return (startBlock, rewardEndBlock);
    }

    function getMustBePaid(address _addr)
        external
        view
        override
        returns (uint256)
    {
        return _getRewardMustBePaid(_addr);
    }

    function getAvailHarvest(address recipient)
        external
        view
        override
        returns (address[] memory tokens, uint256[] memory rewards)
    {
        uint256 length = rewardTokenAddress.length;
        tokens = new address[](length);
        rewards = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address token = rewardTokenAddress[i];
            RewardInfo storage info = rewardsInfo[token];
            uint256 newRewardPerTokenStore = _calculateNewRewardPerTokenStore(
                info
            );
            uint256 calculateRewards = info.rewards[recipient] +
                _calculateEarnedRewards(
                    recipient,
                    info.rewardsPerTokenPaid[recipient],
                    newRewardPerTokenStore
                );
            tokens[i] = token;
            rewards[i] = calculateRewards;
        }
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    function getPoolShare(address recipient)
        external
        view
        returns (uint256 percentage)
    {
        if (totalStaked == 0) return 0;
        return (staked[recipient] * DECIMALS18) / totalStaked;
    }

    function balanceOf(address addr) external view override returns (uint256) {
        return staked[addr];
    }

    function setDepositeFee(uint256 amount_)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
    {
        depositFee = amount_;
    }

    function setCanTakeReward(bool value_)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
    {
        canTakeReward = value_;
    }

    function stakeETH() external payable canStake(stakedToken == address(0)) {
        _stake(msg.sender, msg.value);
    }

    function stake(uint256 _amount)
        external
        override
        canStake(stakedToken != address(0))
    {
        _stake(msg.sender, _amount);
    }

    function unstake(uint256 _amount)
        external
        override
        updateRewards(msg.sender)
    {
        require(_amount > 0, "GS: Amount should be greater than 0");
        require(
            staked[msg.sender] >= _amount,
            "GS: Insufficient staked amount"
        );

        staked[msg.sender] -= _amount;
        totalStaked -= _amount;

        if (stakedToken == address(0)) {
            payable(msg.sender).sendValue(_amount);
        } else {
            IERC20(stakedToken).safeTransfer(
                msg.sender,
                DecimalsConverter.convertFrom18(_amount, stakedDecimals)
            );
        }

        emit Withdrawn(msg.sender, _amount);
    }

    function setPrivate(bool value_)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
    {
        isPrivate = value_;
    }

    function harvest() external override canHarvest updateRewards(msg.sender) {
        _harvest(msg.sender);
    }

    function harvestFor(address recipient)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
        updateRewards(recipient)
    {
        if (canTakeReward) {
            _harvest(recipient);
        }
    }

    function setRewardEndBlock(uint256 _rewardEndBlock)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
    {
        rewardEndBlock = _rewardEndBlock;
    }

    function setRewardSetting(
        address[] memory _rewardToken,
        uint256[] memory _rewardPerBlock
    )
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
        updateRewards(address(0))
    {
        for (uint256 i = 0; i < _rewardToken.length; i++) {
            address token = _rewardToken[i];
            if (rewardTokenAddressIndex[token] == 0) {
                rewardTokenAddress.push(token);
                rewardTokenAddressIndex[token] = rewardTokenAddress.length;
                IERC20(token).approve(stakingRegister, MAX_UINT256);
            }
            RewardInfo storage rewType = rewardsInfo[token];
            rewType.rewardPerBlock = _rewardPerBlock[i];
        }

        emit SetRewardSetting(_rewardToken, _rewardPerBlock);
    }

    function withdrawExtraTokens(address _token, address _recipient)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
    {
        require(_token != stakedToken, "GS: Can'ot get staked token");

        IERC20 erc20 = IERC20(_token);
        uint256 decimals = IERC20Metadata(_token).decimals();
        uint256 _amount = erc20.balanceOf(address(this));

        if (rewardTokenAddressIndex[_token] == 0) {
            erc20.safeTransfer(
                _recipient,
               _amount
            );
        } else {
            erc20.safeTransfer(
                _recipient,
                _amount - DecimalsConverter.convertFrom18(_getRewardMustBePaid(_token), decimals)
            );
        }
        emit WithdrawExtraTokens(_recipient, _token, _amount);
    }

    function _stake(address _addr, uint256 _amount)
        internal
        requireKYCWhitelist()
        requirePrivateWhitelist(isPrivate)
        updateRewards(_addr)
    {
        uint256 value = _amount;

        require(_amount > 0, "GS: Amount should be greater than 0");

        uint256 fee = 0;
        if (depositFee > 0) {
            fee = (value * depositFee) / PERCENTAGE_100;
            value = value - fee;
            if (stakedToken == address(0)) {
                tresuary.sendValue(fee);
            } else {
                IERC20(stakedToken).safeTransferFrom(_addr, tresuary, DecimalsConverter.convertFrom18(fee, stakedDecimals));
            }
        }

        if (stakedToken != address(0)) {
            IERC20(stakedToken).safeTransferFrom(_addr, address(this), DecimalsConverter.convertFrom18(value, stakedDecimals));
        }

        staked[_addr] += value;
        totalStaked += value;

        emit Staked(_addr, value, fee);
    }

    function _harvest(address recipient) internal {
        for (uint256 i = 0; i < rewardTokenAddress.length; i++) {
            address token = rewardTokenAddress[i];
            RewardInfo storage info = rewardsInfo[token];
            uint256 rewards = info.rewards[recipient];
            if (rewards > 0) {
                info.rewards[recipient] -= rewards;
                info.rewardMustBePaid -= rewards;
                IERC20(token).safeTransfer(recipient, DecimalsConverter.convertFrom18(rewards, IERC20Metadata(token).decimals()));
                emit RewardPaid(recipient, token, rewards);
            }
        }
    }

    function _updateRewards(address recipient) internal {
        for (uint256 i = 0; i < rewardTokenAddress.length; i++) {
            RewardInfo storage info = rewardsInfo[rewardTokenAddress[i]];
            uint256 newRewardPerTokenStore = _calculateNewRewardPerTokenStore(
                info
            );

            info.rewardPerTokenStore = newRewardPerTokenStore;

            if (totalStaked > 0) {
                info.rewardMustBePaid +=
                    _calculateBlocksPasted() *
                    info.rewardPerBlock;
            }

            if (recipient != address(0)) {
                info.rewards[recipient] += (
                    _calculateEarnedRewards(
                        recipient,
                        info.rewardsPerTokenPaid[recipient],
                        newRewardPerTokenStore
                    )
                );
                info.rewardsPerTokenPaid[recipient] = newRewardPerTokenStore;
            }
        }
        lastUpdateBlock = block.number;
    }

    function _calculateNewRewardPerTokenStore(RewardInfo storage info)
        internal
        view
        returns (uint256)
    {
        uint256 blockPassted = _calculateBlocksPasted();

        if (blockPassted == 0 || totalStaked == 0)
            return info.rewardPerTokenStore;

        uint256 accumulativeRewardPerToken = (blockPassted *
            info.rewardPerBlock *
            DECIMALS18) / totalStaked;
        return info.rewardPerTokenStore + accumulativeRewardPerToken;
    }

    function _calculateEarnedRewards(
        address recipient,
        uint256 rewardsPerTokenPaid,
        uint256 newRewardPerTokenStore
    ) internal view returns (uint256) {
        if (staked[recipient] == 0) return 0;
        return
            ((newRewardPerTokenStore - rewardsPerTokenPaid) *
                staked[recipient]) / DECIMALS18;
    }

    function _getRewardMustBePaid(address _addr)
        internal
        view
        returns (uint256)
    {
        RewardInfo storage info = rewardsInfo[_addr];

        if (lastUpdateBlock > rewardEndBlock) return info.rewardMustBePaid;

        uint256 lastUpdate = Math.max(startBlock, lastUpdateBlock);

        uint256 amount = (rewardEndBlock - lastUpdate) * info.rewardPerBlock;
        if (totalStaked > 0) {
            return info.rewardMustBePaid + amount;
        }

        return
            info.rewardMustBePaid +
            amount -
            (_calculateBlocksPasted() * info.rewardPerBlock);
    }

    function _calculateBlocksPasted() internal view returns (uint256) {
        uint256 blockNumber = Math.min(block.number, rewardEndBlock);

        if (blockNumber > startBlock && lastUpdateBlock < rewardEndBlock) {
            return blockNumber - Math.max(startBlock, lastUpdateBlock);
        }
        return 0;
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Constants.sol";

contract Management is Ownable {
    using SafeMath for uint256;

    // Contract Registry
    mapping(uint256 => address payable) public contractRegistry;

    // Permissions
    mapping(address => mapping(uint256 => bool)) public permissions;

    event PermissionsSet(
        address indexed subject,
        uint256[] indexed permissions,
        bool value
    );

    event UsersPermissionsSet(
        address[] indexed subject,
        uint256 indexed permissions,
        bool value
    );

    event PermissionSet(
        address indexed subject,
        uint256 indexed permission,
        bool value
    );

    event ContractRegistered(
        uint256 indexed key,
        address indexed source,
        address target
    );

    function setPermission(
        address _address,
        uint256 _permission,
        bool _value
    ) external onlyOwner {
        permissions[_address][_permission] = _value;
        emit PermissionSet(_address, _permission, _value);
    }

    function setPermissions(
        address _address,
        uint256[] calldata _permissions,
        bool _value
    ) external onlyOwner {
        for (uint256 i = 0; i < _permissions.length; i++) {
            permissions[_address][_permissions[i]] = _value;
        }
        emit PermissionsSet(_address, _permissions, _value);
    }

    function registerContract(uint256 _key, address payable _target)
        external
        onlyOwner
    {
        contractRegistry[_key] = _target;
        emit ContractRegistered(_key, address(0), _target);
    }

    function setKycWhitelist(address _address, bool _value) external {
        require(
            permissions[msg.sender][CAN_SET_KYC_WHITELISTED],
            ERROR_ACCESS_DENIED
        );

        permissions[_address][WHITELISTED_KYC] = _value;

        emit PermissionSet(_address, WHITELISTED_KYC, _value);
    }

    function setKycWhitelists(address[] calldata _address, bool _value)
        external
    {
        require(
            permissions[msg.sender][CAN_SET_KYC_WHITELISTED],
            ERROR_ACCESS_DENIED
        );

        for (uint256 i = 0; i < _address.length; i++) {
            permissions[_address[i]][WHITELISTED_KYC] = _value;
        }
        emit UsersPermissionsSet(_address, WHITELISTED_KYC, _value);
    }

    function setPrivateWhitelists(address[] calldata _address, bool _value)
        external
    {
        require(
            permissions[msg.sender][CAN_SET_PRIVATE_WHITELISTED],
            ERROR_ACCESS_DENIED
        );

        for (uint256 i = 0; i < _address.length; i++) {
            permissions[_address[i]][WHITELISTED_PRIVATE] = _value;
        }

        emit UsersPermissionsSet(_address, WHITELISTED_PRIVATE, _value);
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Constants.sol";
import "./Management.sol";

contract Managed is Ownable {
    using SafeMath for uint256;

    Management public management;

    modifier requirePermission(uint256 _permission) {
        require(
            hasPermission(msg.sender, _permission),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier requireKYCWhitelist() {
        require(
            hasPermission(msg.sender, WHITELISTED_KYC),
            ERROR_ACCESS_DENIED
        );
        _;
    }
    modifier requirePrivateWhitelist(bool _isPrivate) {
        if (_isPrivate) {
            require(
                hasPermission(msg.sender, WHITELISTED_PRIVATE),
                ERROR_ACCESS_DENIED
            );
        }
        _;
    }

    modifier canCallOnlyRegisteredContract(uint256 _key) {
        require(
            msg.sender == management.contractRegistry(_key),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier requireContractExistsInRegistry(uint256 _key) {
        require(
            management.contractRegistry(_key) != address(0),
            ERROR_NO_CONTRACT
        );
        _;
    }

    constructor(address _managementAddress) {
        management = Management(_managementAddress);
    }

    function setManagementContract(address _management) public onlyOwner {
        require(address(0) != _management, ERROR_NO_CONTRACT);

        management = Management(_management);
    }

    function hasPermission(address _subject, uint256 _permission)
        internal
        view
        returns (bool)
    {
        return management.permissions(_subject, _permission);
    }

}

pragma solidity ^0.8.0;

uint256 constant DECIMALS = 18;
uint256 constant DECIMALS18 = 1e18;

uint256 constant MAX_UINT256 = type(uint256).max;
uint256 constant PERCENTAGE_100 = 10000;
uint256 constant PERCENTAGE_1 = 100;
uint256 constant MAX_FEE_PERCENTAGE = PERCENTAGE_100 - PERCENTAGE_1;
bytes4 constant InterfaceId_ERC721 = 0x80ac58cd;

string constant ERROR_ACCESS_DENIED = "ERROR_ACCESS_DENIED";
string constant ERROR_NO_CONTRACT = "ERROR_NO_CONTRACT";
string constant ERROR_NOT_AVAILABLE = "ERROR_NOT_AVAILABLE";


address constant EMERGENCY_ADDRESS = 0x85CCc822A20768F50397BBA5Fd9DB7de68851D5B;

//permisionss
//WHITELIST
uint256 constant ROLE_ADMIN = 1;
uint256 constant ROLE_REGULAR = 5;

uint256 constant CAN_SET_KYC_WHITELISTED = 10;
uint256 constant CAN_SET_PRIVATE_WHITELISTED = 11;

uint256 constant WHITELISTED_KYC = 20;
uint256 constant WHITELISTED_PRIVATE = 21;

uint256 constant CAN_SET_REMAINING_SUPPLY = 29;

uint256 constant CAN_TRANSFER_NFT = 30;
uint256 constant CAN_MINT_NFT = 31;
uint256 constant CAN_BURN_NFT = 32;

uint256 constant CAN_ADD_STAKING = 43;
uint256 constant CAN_ADD_POOL = 45;

//REGISTER_ADDRESS
uint256 constant CONTRACT_MANAGEMENT = 0;
uint256 constant CONTRACT_KAISHI_TOKEN = 1;
uint256 constant CONTRACT_STAKE_FACTORY = 2;
uint256 constant CONTRACT_NFT_FACTORY = 3;
uint256 constant CONTRACT_LIQUIDITY_MINING_FACTORY = 4;
uint256 constant CONTRACT_STAKING_REGISTER = 5;
uint256 constant CONTRACT_POOL_REGISTER = 6;

uint256 constant ADDRESS_TRESUARY = 10;
uint256 constant ADDRESS_SIGNER = 11;
uint256 constant ADDRESS_OWNER = 12;

pragma solidity ^0.8.0;

library DecimalsConverter {
    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount / (10**(baseDecimals - destinationDecimals));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount * (10**(destinationDecimals - baseDecimals));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, 18, destinationDecimals);
    }
}

pragma solidity ^0.8.0;

interface IStaking {
    event Staked(address indexed user, uint256 amount, uint256 fee);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address token, uint256 reward);
    event WithdrawExtraTokens(
        address indexed user,
        address token,
        uint256 amount
    );

    event SetRewardSetting(address[] rewardToken, uint256[] rewardPerBlock);

    struct RewardInfo {
        uint256 rewardPerBlock;
        uint256 rewardPerTokenStore;
        uint256 rewardMustBePaid;
        mapping(address => uint256) rewardsPerTokenPaid;
        mapping(address => uint256) rewards;
    }

    function balanceOf(address _recipient) external view returns (uint256);

    function getAvailHarvest(address recipient)
        external
        view
        returns (address[] memory tokens, uint256[] memory availRewards);

    function getRewardsPerBlockInfo(address _rewardTokens)
        external
        view
        returns (uint256);

    function getRewardsPerBlockInfos()
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory rewardPerBlock
        );

    function getTimePoint()
        external
        view
        returns (uint256 startBlock, uint256 endBlock);

    function getMustBePaid(address _rewardTokens)
        external
        view
        returns (uint256);

    function setDependency() external;

    function withdrawExtraTokens(address _token, address _recipient) external;

    function stake(uint256 _amount) external;

    function unstake(uint256 _amount) external;

    function harvest() external;

    function harvestFor(address _recipient) external;

    function setDepositeFee(uint256 amount_) external;

    function setCanTakeReward(bool value_) external;

    function setPrivate(bool value_) external;

    function setRewardEndBlock(uint256 _rewardEndBlock) external;

    function setRewardSetting(
        address[] calldata _rewardTokens,
        uint256[] calldata _rewardPerBlock
    ) external;
}

pragma solidity ^0.8.0;

interface IStakingRegister {
    event SetCanTakeReward(
        address indexed sender,
        address staking,
        bool amount
    );

    event RemoveStaking(address indexed sender, address owner, address staking);
    event CreateStaking(
        address indexed sender,
        address owner,
        address staking,
        bool isLiquidityMining
    );

    event SetDefaultDepositFee(address indexed sender, uint256 amount);

    event SetDepositFee(
        address indexed sender,
        address staking,
        uint256 amount
    );

    event SetPrivate(address indexed sender, address staking, bool value);

    event WithdrawExtraTokensFromStaking(
        address indexed user,
        address staking,
        address token
    );

    event SetRewardSetting(
        address indexed sender,
        address staking,
        address[] rewardTokens,
        uint256[] rewardPerBlock,
        uint256[][] approvedNFTid
    );

    event AddDuration(address indexed sender, address staking, uint256 amount);

    function list(uint256 _offset, uint256 _limit)
        external
        view
        returns (address[] memory result);

    function listByUser(
        address _user,
        uint256 _offset,
        uint256 _limit
    ) external view returns (address[] memory result);

    function isOwner(address owner, address staking)
        external
        view
        returns (bool);

    function harvestAll(address[] calldata stakings) external;

    function withdrawExtraTokens(address _addr, address _token) external;

    function add(
        address _owner,
        address _stakingAddress,
        bool _isLiquidityMining
    ) external;

    function remove(address _owner, address _addr) external;

    function setDepositeFee(address _addr, uint256 _amount) external;

    function setCanTakeReward(address _addr, bool _value) external;

    function setPrivate(address _addr, bool _value) external;

    function setDefaultDepositFeePercentage(uint256 _amount) external;

    function getDefaultFeePercentage() external view returns (uint256);

    function addDurationLiquidityMining(
        address _stakingAddress,
        uint256 _blockAmount,
        address[] calldata _rewardTokenAddress,
        uint256[][] calldata _approvedNFTid
    ) external;

    function addDurationGenesisStaking(
        address _stakingAddress,
        uint256 _blockAmount
    ) external;

    function setRewardSettingGenesisStaking(
        address _stakingAddress,
        address[] calldata _rewardTokens,
        uint256[] calldata _rewardPerBlock
    ) external;

    function setRewardSettingLiquidityMining(
        address _stakingAddress,
        address[] calldata _rewardTokens,
        uint256[] calldata _rewardPerBlock,
        uint256[][] calldata _rewardApprovedNFTId
    ) external;
}

pragma solidity ^0.8.0;

interface IGenesisStakeFactory {
    function setDependency() external;

    function createGenesisStaking(
        string memory stakingName,
        bool isETHStake,
        bool isPrivate,
        bool isCanTakeReward,
        address stakedToken,
        uint256 startBlock,
        uint256 duration,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

