/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;

      /**
     * Initial deposit
     */
    function initialDeposit(uint256 num) public {
        number = num;
    }

    /**
     * deposit
     */
    function deposit(uint256 num) public {
        number = number + num;
    }
    
    /**
     * withdrawal
     */
    function withdrawal(uint256 num) public {
        if (number >= num)
        {
        number = number - num;
        }
        else
        {

        }
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}