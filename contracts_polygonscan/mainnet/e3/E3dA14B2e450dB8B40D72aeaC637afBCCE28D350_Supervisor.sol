pragma solidity ^0.8.0;

import "ECDSA.sol";

/// @title Supervisor is the guardian of YPool. It requires multiple validators to valid
/// the requests from users and workers and sign on them if valid.
contract Supervisor {
    using ECDSA for bytes32;

    /* ========== STATE VARIABLES ========== */

    bytes32 public constant CLAIM_IDENTIFIER = 'SWAPPER_CLAIM';
    bytes32 public constant SET_THRESHOLD_IDENTIFIER = 'SET_THRESHOLD';
    bytes32 public constant SET_VALIDATOR_IDENTIFIER = 'SET_VALIDATOR';
    bytes32 public constant LOCK_CLOSE_SWAP_AND_REFUND_IDENTIFIER = 'LOCK_CLOSE_SWAP_AND_REFUND';
    bytes32 public constant BATCH_CLAIM_IDENTIFIER = 'BATCH_CLAIM';
    bytes32 public constant VALIDATE_SWAP_IDENTIFIER = 'VALIDATE_SWAP_IDENTIFIER';

    // the chain ID contract located at
    uint32 public chainId;
    // check if the address is one of the validators
    mapping (address => bool) public validators;
    // number of validators
    uint256 private validatorsNum;
    // threshold to pass the signature validation
    uint256 public threshold;
    // current nonce for write functions
    uint256 public nonce;

    /// @dev Constuctor with chainId / validators / threshold
    /// @param _chainId The chain ID located with
    /// @param _validators Initial validator addresses
    /// @param _threshold Initial threshold to pass the request validation
    constructor(uint32 _chainId, address [] memory _validators, uint256 _threshold) {
        chainId = _chainId;

        for (uint256 i; i < _validators.length; i++) {
            validators[_validators[i]] = true;
        }
        validatorsNum = _validators.length;
        require(_threshold <= validatorsNum, "ERR_INVALID_THRESHOLD");
        threshold = _threshold;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Check if there are enough signed signatures to the signature hash
    /// @param sigIdHash The signature hash to be signed
    /// @param signatures Signed signatures by different validators
    function checkSignatures(bytes32 sigIdHash, bytes[] memory signatures) public view {
        require(signatures.length >= threshold, "ERR_NOT_ENOUGH_SIGNATURES");
        address prevAddress = address(0);
        for (uint i; i < threshold; i++) {
            address recovered = sigIdHash.recover(signatures[i]);
            require(validators[recovered], "ERR_NOT_VALIDATOR");
            require(recovered > prevAddress, "ERR_WRONG_SIGNER_ORDER");
            prevAddress = recovered;
        }
    }

    /* ========== WRITE FUNCTIONS ========== */

    /// @notice Change `threshold` by providing a correct nonce and enough signatures from validators
    /// @param _threshold New `threshold`
    /// @param _nonce The nonce to be processed
    /// @param signatures Signed signatures by validators
    function setThreshold(uint256 _threshold, uint256 _nonce, bytes[] memory signatures) external {
        require(signatures.length >= threshold, "ERR_NOT_ENOUGH_SIGNATURES");
        require(_nonce == nonce, "ERR_INVALID_NONCE");
        require(_threshold > 0, "ERR_INVALID_THRESHOLD");
        require(_threshold <= validatorsNum, "ERR_INVALID_THRESHOLD");

        bytes32 sigId = keccak256(abi.encodePacked(SET_THRESHOLD_IDENTIFIER, address(this), chainId, _threshold, _nonce));
        bytes32 sigIdHash = sigId.toEthSignedMessageHash();
        checkSignatures(sigIdHash, signatures);

        threshold = _threshold;
        nonce++;
    }

    /// @notice Set / remove the validator address to be part of signatures committee
    /// @param _validator The address to add or remove
    /// @param flag `true` to add, `false` to remove
    /// @param _nonce The nonce to be processed
    /// @param signatures Signed signatures by validators
    function setValidator(address _validator, bool flag, uint256 _nonce, bytes[] memory signatures) external {
        require(_validator != address(0), "ERR_INVALID_VALIDATOR");
        require(signatures.length >= threshold, "ERR_NOT_ENOUGH_SIGNATURES");
        require(_nonce == nonce, "ERR_INVALID_NONCE");
        require(flag != validators[_validator], "ERR_OPERATION_TO_VALIDATOR");

        bytes32 sigId = keccak256(abi.encodePacked(SET_VALIDATOR_IDENTIFIER, address(this), chainId, _validator, flag, _nonce));
        bytes32 sigIdHash = sigId.toEthSignedMessageHash();
        checkSignatures(sigIdHash, signatures);

        if (validators[_validator]) {
            validatorsNum--;
            validators[_validator] = false;
            if (validatorsNum < threshold) threshold--;
        } else {
            validatorsNum++;
            validators[_validator] = true;
        }
        nonce++;
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