// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


/**
* @notice Library to recover address and verify signatures
* @dev Simple wrapper for `ecrecover`
*/
library SignatureVerifier {

    enum HashAlgorithm {KECCAK256, SHA256, RIPEMD160}

    // Header for Version E as defined by EIP191. First byte ('E') is also the version
    bytes25 constant EIP191_VERSION_E_HEADER = "Ethereum Signed Message:\n";

    /**
    * @notice Recover signer address from hash and signature
    * @param _hash 32 bytes message hash
    * @param _signature Signature of hash - 32 bytes r + 32 bytes s + 1 byte v (could be 0, 1, 27, 28)
    */
    function recover(bytes32 _hash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        require(_signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28);
        return ecrecover(_hash, v, r, s);
    }

    /**
    * @notice Transform public key to address
    * @param _publicKey secp256k1 public key
    */
    function toAddress(bytes memory _publicKey) internal pure returns (address) {
        return address(uint160(uint256(keccak256(_publicKey))));
    }

    /**
    * @notice Hash using one of pre built hashing algorithm
    * @param _message Signed message
    * @param _algorithm Hashing algorithm
    */
    function hash(bytes memory _message, HashAlgorithm _algorithm)
        internal
        pure
        returns (bytes32 result)
    {
        if (_algorithm == HashAlgorithm.KECCAK256) {
            result = keccak256(_message);
        } else if (_algorithm == HashAlgorithm.SHA256) {
            result = sha256(_message);
        } else {
            result = ripemd160(_message);
        }
    }

    /**
    * @notice Verify ECDSA signature
    * @dev Uses one of pre built hashing algorithm
    * @param _message Signed message
    * @param _signature Signature of message hash
    * @param _publicKey secp256k1 public key in uncompressed format without prefix byte (64 bytes)
    * @param _algorithm Hashing algorithm
    */
    function verify(
        bytes memory _message,
        bytes memory _signature,
        bytes memory _publicKey,
        HashAlgorithm _algorithm
    )
        internal
        pure
        returns (bool)
    {
        require(_publicKey.length == 64);
        return toAddress(_publicKey) == recover(hash(_message, _algorithm), _signature);
    }

    /**
    * @notice Hash message according to EIP191 signature specification
    * @dev It always assumes Keccak256 is used as hashing algorithm
    * @dev Only supports version 0 and version E (0x45)
    * @param _message Message to sign
    * @param _version EIP191 version to use
    */
    function hashEIP191(
        bytes memory _message,
        byte _version
    )
        internal
        view
        returns (bytes32 result)
    {
        if(_version == byte(0x00)){  // Version 0: Data with intended validator
            address validator = address(this);
            return keccak256(abi.encodePacked(byte(0x19), byte(0x00), validator, _message));
        } else if (_version == byte(0x45)){  // Version E: personal_sign messages
            uint256 length = _message.length;
            require(length > 0, "Empty message not allowed for version E");

            // Compute text-encoded length of message
            uint256 digits = 0;
            while (length != 0) {
                digits++;
                length /= 10;
            }
            bytes memory lengthAsText = new bytes(digits);
            length = _message.length;
            uint256 index = digits - 1;
            while (length != 0) {
                lengthAsText[index--] = byte(uint8(48 + length % 10));
                length /= 10;
            }

            return keccak256(abi.encodePacked(byte(0x19), EIP191_VERSION_E_HEADER, lengthAsText, _message));
        } else {
            revert("Unsupported EIP191 version");
        }
    }

    /**
    * @notice Verify EIP191 signature
    * @dev It always assumes Keccak256 is used as hashing algorithm
    * @dev Only supports version 0 and version E (0x45)
    * @param _message Signed message
    * @param _signature Signature of message hash
    * @param _publicKey secp256k1 public key in uncompressed format without prefix byte (64 bytes)
    * @param _version EIP191 version to use
    */
    function verifyEIP191(
        bytes memory _message,
        bytes memory _signature,
        bytes memory _publicKey,
        byte _version
    )
        internal
        view
        returns (bool)
    {
        require(_publicKey.length == 64);
        return toAddress(_publicKey) == recover(hashEIP191(_message, _version), _signature);
    }

}
