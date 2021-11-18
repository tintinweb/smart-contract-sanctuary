//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DepTestTupleV1 {
    struct StrTuple {
        address tupleAddress;
        string tupleString;
        uint256 tupleUint256;
    }

    StrTuple public varTuple;

    constructor(StrTuple memory _varTuple) {
        varTuple = _varTuple;
    }

    function readTupleAddress() public view returns (address) {
        return varTuple.tupleAddress;
    }

    function readTupleString() public view returns (string memory) {
        return varTuple.tupleString;
    }

    function readTupleUint256() public view returns (uint256) {
        return varTuple.tupleUint256;
    }
}