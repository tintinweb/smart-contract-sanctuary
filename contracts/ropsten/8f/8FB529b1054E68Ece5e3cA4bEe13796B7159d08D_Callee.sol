/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity ^0.4.12;

contract Callee {
    uint[] public values;

    function getValue(uint initial) returns(uint) {
        return initial + 150;
    }
    function storeValue(uint value) {
        values.push(value);
    }
    function getValues() returns(uint) {
        return values.length;
    }
}