/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract CryptosparkXSingle {
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function verifytest(
        address from,
        string calldata to,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external pure {
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(from, to, amount, nonce))
        );

        require(recoverSigner(message, signature) == from, "wrong signature");
        require(recoverSigner(message, signature) != from, "wrong signature2");
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}