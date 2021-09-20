/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number = 0;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function inc(uint256 num) public {
        number = number + num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
    
    function addition(uint a, uint b) public pure returns(uint) {
        return (a + b);
    }

    function multiplication(uint a, uint b) public pure returns(uint) {
        return (a * b);
    }
    
    function division(uint a, uint b) public pure returns(uint) {
        return (a / b);
    }
}