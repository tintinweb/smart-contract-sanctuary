// @author Unstoppable Domains, Inc.
// @date August 23th, 2021

pragma solidity ^0.8.0;

import './IForwarder.sol';
import './BaseForwarder.sol';

contract MintingManagerForwarder is BaseForwarder {
    address private _mintingManager;
    mapping(uint256 => uint256) private _nonces;

    constructor(address mintingManager) {
        _mintingManager = mintingManager;
    }

    function nonceOf(uint256 tokenId) external view override returns (uint256) {
        return _nonces[tokenId];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view override returns (bool) {
        return _verify(req, _mintingManager, signature);
    }

    function execute(ForwardRequest calldata req, bytes calldata signature) external override returns (bytes memory) {
        uint256 gas = gasleft();
        require(verify(req, signature), 'MintingManagerForwarder: SIGNATURE_INVALID');
        return _execute(req.from, _mintingManager, req.tokenId, gas, req.data, signature);
    }

    function _invalidateNonce(uint256 tokenId) internal override {
        _nonces[tokenId] = _nonces[tokenId] + 1;
    }
}

// @author Unstoppable Domains, Inc.
// @date August 11th, 2021

pragma solidity ^0.8.0;

interface IForwarder {
    struct ForwardRequest {
        address from;
        uint256 nonce;
        uint256 tokenId;
        bytes data;
    }

    function nonceOf(uint256 tokenId) external view returns (uint256);

    function verify(ForwardRequest calldata req, bytes calldata signature) external view returns (bool);

    function execute(ForwardRequest calldata req, bytes calldata signature) external returns (bytes memory);
}

// @author Unstoppable Domains, Inc.
// @date August 12th, 2021

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';

import './IForwarder.sol';

abstract contract BaseForwarder is IForwarder {
    using ECDSAUpgradeable for bytes32;

    function _verify(
        ForwardRequest memory req,
        address target,
        bytes memory signature
    ) internal view virtual returns (bool) {
        uint256 nonce = this.nonceOf(req.tokenId);
        address signer = _recover(keccak256(req.data), target, nonce, signature);
        return nonce == req.nonce && signer == req.from;
    }

    function _recover(
        bytes32 digest,
        address target,
        uint256 nonce,
        bytes memory signature
    ) internal pure virtual returns (address signer) {
        return keccak256(abi.encodePacked(digest, target, nonce)).toEthSignedMessageHash().recover(signature);
    }

    function _execute(
        address from,
        address to,
        uint256 tokenId,
        uint256 gas,
        bytes memory data,
        bytes memory signature
    ) internal virtual returns (bytes memory) {
        _invalidateNonce(tokenId);

        (bool success, bytes memory returndata) = to.call{gas: gas}(_buildData(from, tokenId, data, signature));
        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        assert(gasleft() > gas / 63);

        return _verifyCallResult(success, returndata, 'BaseForwarder: CALL_FAILED');
    }

    function _invalidateNonce(
        uint256 /* tokenId */
    ) internal virtual {}

    function _buildData(
        address from,
        uint256 tokenId,
        bytes memory data,
        bytes memory /* signature */
    ) internal view virtual returns (bytes memory) {
        return abi.encodePacked(data, from, tokenId);
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

                //solhint-disable-next-line no-inline-assembly
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}