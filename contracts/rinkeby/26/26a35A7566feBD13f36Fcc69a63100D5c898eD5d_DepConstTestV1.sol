//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DepConstTestV1 {
    bool public varBool;
    uint256 public varUint256;
    int256 public varInt256;
    bytes32 public varBytes32;
    bytes public varBytes;

    constructor(bool _varBool, uint256 _varUint256, int256 _varInt256, bytes32 _varBytes32, bytes memory _varBytes) {
        varBool = _varBool;
        varUint256 = _varUint256;
        varInt256 = _varInt256;
        varBytes32 = _varBytes32;
        varBytes = _varBytes;
    }
}