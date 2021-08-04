pragma solidity ^0.4.21;

import './Storage.sol';

contract LogicOne is Storage {

    function setVal(uint _val) public returns (bool success) {
        val = 2 * _val;
        return true;
    }

}