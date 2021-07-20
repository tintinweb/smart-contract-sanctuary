/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract msgSign {
    function getSigner(bytes32 hash, uint8 v, bytes32 r, bytes32 s) external pure returns(address) {
        return ecrecover(hash, v, r, s);
    }
    
    function getMessageHash(string calldata a) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(a));
    }
}