/**
 *Submitted for verification at arbiscan.io on 2021-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutismRegistrar {
    event RecordUpdated(address indexed account, bytes value);
    event RecordUpdatedFor(address indexed account, bytes value, bytes proof, address relayer);

    function update(bytes calldata value) public {
        emit RecordUpdated(msg.sender, value);
    }

    function updateFor(address account, bytes calldata value, bytes calldata proof) public {
        bytes32 msgHash = keccak256(abi.encodePacked(account, value));
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(proof);

        bool verified = recoverSigner(msgHash, proof) == account;

        require(verified);

        emit RecordUpdatedFor(account, value, proof, msg.sender);
    }

    function recoverSigner(bytes32 msgHash, bytes memory proof) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(proof);
        return ecrecover(msgHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    ) {
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