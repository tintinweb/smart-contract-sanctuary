// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Signature Verification
contract SignatureVerifier {
    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    // Recover signer address using ecrecover
    function recoverSigner(bytes32 _messageHash, bytes memory _signature)
        external
        pure
        returns (address)
    {
        // Split user signature
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        // Sign user message hash
        bytes32 _ethSignedMessageHash = getEthSignedMessageHash(_messageHash);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // Split user signature
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

