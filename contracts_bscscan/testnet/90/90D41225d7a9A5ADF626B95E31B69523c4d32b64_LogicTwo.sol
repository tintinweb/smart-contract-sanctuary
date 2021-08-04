pragma solidity ^0.4.21;

import './LogicOne.sol';

contract LogicTwo is LogicOne {
    function setVal(uint _val) public returns (bool success) {
        val = 2 * _val;
        return true;
    }
}