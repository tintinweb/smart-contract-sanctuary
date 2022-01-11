//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TupleTestV3 {
    address public owner;

    struct BasicTuple {
        address subAddress;
        string subString;
        uint256 subUint256;
    }

    BasicTuple basicTuple;

    struct NestTuple {
        address tupleAddress;
        string tupleString;
        uint256 tupleUint256;
        BasicTuple subTuple;
    }

    NestTuple public varNestTuple;
    

    BasicTuple[] public varTupleArray;


    struct TupleWithArray1 {
        address tupleAddress;
        string tupleString;
        uint256[3] tupleUint256;
    }

    TupleWithArray1 public varTupleWithArray1;


    struct TupleWithArray2 {
        address tupleAddress;
        string tupleString;
        uint256[] tupleUint256;
    }

    TupleWithArray2 public varTupleWithArray2;



    constructor() {
        owner = msg.sender;
    }

    function writeTuple(BasicTuple memory _basicTuple) public {
        basicTuple = _basicTuple;
    }

    function readTupleString() public view returns (string memory) {
        return basicTuple.subString;
    }

    function writeNestTuple(NestTuple memory _varNestTuple) public {
        varNestTuple = _varNestTuple;
    }

    function readNestTupleString() public view returns (string memory) {
        return varNestTuple.tupleString;
    }



    function writeTupleArray(BasicTuple[] memory _varTupleArray) public {
        for (uint256 i = 0; i < _varTupleArray.length; i++) {
            varTupleArray.push(_varTupleArray[i]);
        }
    }

    function readTupleArayString(uint256 index) public view returns (string memory) {
        return varTupleArray[index].subString;
    }



    function writeTupleWithArray1(TupleWithArray1 memory _varTupleWithArray1) public {
        varTupleWithArray1 = _varTupleWithArray1;
    }

    function readTupleWithArray1String() public view returns (string memory) {
        return varTupleWithArray1.tupleString;
    }

    function readTupleWithArray1Uint256(uint256 index) public view returns (uint256) {
        return varTupleWithArray1.tupleUint256[index];
    }



    function writeTupleWithArray2(TupleWithArray2 memory _varTupleWithArray2) public {
        varTupleWithArray2 = _varTupleWithArray2;
    }

    function readTupleWithArray2String() public view returns (string memory) {
        return varTupleWithArray2.tupleString;
    }

    function readTupleWithArray2Uint256(uint256 index) public view returns (uint256) {
        return varTupleWithArray2.tupleUint256[index];
    }
}