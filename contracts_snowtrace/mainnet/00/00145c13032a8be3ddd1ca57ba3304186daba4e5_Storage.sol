/**
 *Submitted for verification at snowtrace.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;

    event EmitNumber(uint256 num);

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    function add(uint256 num) public {
        number += num;
    }

    function retrieve(uint256 num) public view returns (uint256){
        return number + num;
    }

    function retrieveEmit(uint256 num) public returns (uint256) {
        emit EmitNumber(number + num);
        return number + num;
    }
}