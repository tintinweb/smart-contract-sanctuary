/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    
    event ValueChange(uint256 _prev, uint256 _new);

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        uint256 prev = number;
        number = num;
        emit ValueChange(prev, number);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}