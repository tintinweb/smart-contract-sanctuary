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

    uint8 storageNumber;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function setter(uint8 num) public {
        storageNumber = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function getter() public view returns (uint8){
        return storageNumber;
    }
}