/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Callee {
    uint[] public values;

    function getValue(uint initial) public pure returns(uint) {
        return initial + 150;
    }
    function storeValue(uint value) public {
        values.push(value);
    }
    function getValues() public view returns(uint) {
        return values.length;
    }
}