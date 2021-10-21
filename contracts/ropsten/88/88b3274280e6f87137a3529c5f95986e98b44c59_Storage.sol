/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint8 num1;
    uint8 num2;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function storeNumber(uint8 num, uint8 n) public {
        num1 = num;
        num2 = n;
    }
    

    // function storeNum2(uint8 num) public {
    //     num2 = num;
    // }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieveNumber() public view returns (uint8){
        return num1;
    }
    
    function retrieveNum2() public view returns (uint8){
        return num2;
    }
}