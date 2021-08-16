/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

contract Ecr {
    function ecr (bytes32 msgh, uint8 v, bytes32 r, bytes32 s) public pure returns (address sender) {
        return ecrecover(msgh, v, r, s);
    }
}