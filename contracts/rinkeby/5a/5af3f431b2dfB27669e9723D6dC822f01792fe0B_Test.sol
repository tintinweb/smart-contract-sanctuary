// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    constructor() {}

    function recoverSignerFromSignature(
        bytes32 msgh,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (address) {
        address signer = ecrecover(msgh, v, r, s);

        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }
}