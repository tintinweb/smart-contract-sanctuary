// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

contract Carray {
    uint[] public list;
    constructor() {}
    function add(uint a) external returns(uint){
        list.push(a);
        return list.length;
    }

    function remove() external returns(uint) {
        // list.pop();
        return list.length;
    }
    function getLength() external returns(uint) {
        return list.length;
    }
}