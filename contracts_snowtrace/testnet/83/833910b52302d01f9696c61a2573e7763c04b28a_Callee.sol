/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-30
*/

pragma solidity ^0.4.6;

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