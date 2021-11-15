// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.4;

interface FireInterface {
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract MultiDelegator {
    FireInterface public fire;

    constructor(FireInterface _fire) {
        fire = _fire;
    }

    function delegateBySig(
        address delegatee,
        uint256[] memory nonce,
        uint256[] memory expiry,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public {
        for (uint256 i = 0; i < nonce.length; i++) {
            fire.delegateBySig(delegatee, nonce[i], expiry[i], v[i], r[i], s[i]);
        }
    }
}

