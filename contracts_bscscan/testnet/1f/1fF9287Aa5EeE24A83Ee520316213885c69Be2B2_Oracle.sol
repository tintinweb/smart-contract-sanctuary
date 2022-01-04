// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

contract Oracle {
    uint256[10] public arr;

    event OracleUpdate(address indexed sender, uint256 idx, uint256 value);

    function get(uint256 i) public view returns (uint256) {
        return arr[i];
    }

    function getArr() public view returns (uint256[10] memory) {
        return arr;
    }

    function set(uint256 i, uint256 value) public {
        arr[i] = value;
        emit OracleUpdate(msg.sender, i, value);
    }

    function set(uint256[10] memory values) public {
        arr = values;
    }

    function getLength() public view returns (uint256) {
        return arr.length;
    }

    function remove(uint256 index) public {
        delete arr[index];
    }
}