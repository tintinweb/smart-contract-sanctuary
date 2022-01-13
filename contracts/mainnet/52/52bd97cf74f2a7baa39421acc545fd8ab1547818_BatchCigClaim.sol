// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IClaim.sol";

contract BatchCigClaim {

    IClaim claimContract = IClaim(0x5A35A6686db167B05E2Eb74e1ede9fb5D9Cdb3E0);

    function batchClaim(uint256[] calldata _punkIndexes) external {
        for (uint i = 0; i < _punkIndexes.length; i++) {
            claimContract.claim(_punkIndexes[i]);
        }
    }
}