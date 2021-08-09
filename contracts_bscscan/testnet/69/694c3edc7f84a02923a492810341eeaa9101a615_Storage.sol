/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number1;
    uint256 number2;


    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store1(uint256 num) public {
        number1 = num;
    }
    
    function store2(uint256 num) public {
        number2 = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve1() public view returns (uint256){
        return number1;
    }
    
    function retrieve2() public view returns (uint256){
        return number2;
    }
}