/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ECDSA {
    function recover(bytes32 hash, bytes memory signature)
        external
        pure
        returns (address signer, bytes32 r, bytes32 s, uint8 v)
    {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0), r, s, v);
        }

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0), r, s, v);
        } else {
            // solium-disable-next-line arg-overflow
            return (ecrecover(hash, v, r, s), r, s, v);
        }
    }
}