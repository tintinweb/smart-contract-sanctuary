//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ArgumentTestV2 {
    address public owner;

    address public varAddress;
    string public varString;
    bool public varBool;
    uint256 public varUint256;
    int256 public varInt256;
    bytes32 public varBytes32;
    bytes public varBytes;

    address[] public varArrayAddress;
    string[] public varArrayString;
    bool[] public varArrayBool;
    uint[] public varArrayUint;
    int[] public varArrayInt;
    bytes[] public varArrayBytes;

    struct StrTuple {
        address tupleAddress;
        string tupleString;
        uint256 tupleUint256;
    }

    StrTuple public varTuple;



    constructor() {
        owner = msg.sender;
    }

    function writeAddress(address _varAddress) public {
        varAddress = _varAddress;
    }

    function writeString(string memory _varString) public {
        varString = _varString;
    }

    function writeBool(bool _varBool) public {
        varBool = _varBool;
    }

    function writeUint256(uint256 _varUint256) public {
        varUint256 = _varUint256;
    }

    function writeInt256(int256 _varInt256) public {
        varInt256 = _varInt256;
    }

    function writeBytes32(bytes32 _varBytes32) public {
        varBytes32 = _varBytes32;
    }

    function writeBytes(bytes memory _varBytes) public {
        varBytes = _varBytes;
    }



    function writeArrayAddress(address[] memory _varArrayAddress) public {
        varArrayAddress = _varArrayAddress;
    }

    function writeArrayString(string[] memory _varArrayString) public {
        varArrayString = _varArrayString;
    }

    function writeArrayBool(bool[] memory _varArrayBool) public {
        varArrayBool = _varArrayBool;
    }

    function writeArrayUint(uint[] memory _varArrayUint) public {
        varArrayUint = _varArrayUint;
    }

    function writeArrayInt(int[] memory _varArrayInt) public {
        varArrayInt = _varArrayInt;
    }

    function writeArrayBytes(bytes[] memory _varArrayBytes) public {
        varArrayBytes = _varArrayBytes;
    }

    function writeTuple(StrTuple memory _varTuple) public {
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