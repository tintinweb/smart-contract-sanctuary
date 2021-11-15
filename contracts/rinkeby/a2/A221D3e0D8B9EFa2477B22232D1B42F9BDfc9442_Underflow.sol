// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Underflow vulnerable
 * @dev expose underflow
 */
contract Underflow {

    uint8 number;

    /**
     * @dev Store value in variable
     * @param _num value to store
     */
    function store(uint8 _num) public {
        number = _num;
    }
    
    /**
     * @dev subtract value
     * @param _num value to subtract from stored number, vulnerable to underflow
     */
    function subByNum(uint8 _num) public {
        number = number - _num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint8){
        return number;
    }
}

