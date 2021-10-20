/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 totalCars;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function setCars(uint256 num) public {
        totalCars = num;
    }
    
    function removeCars(uint256 num) public {
        totalCars = totalCars - num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function getCars() public view returns (uint256){
        return totalCars;
    }
}