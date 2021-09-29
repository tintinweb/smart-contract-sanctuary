/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
 
 /**
  * @title Storage
  * @dev Store & retreive value in a variable
  */
contract Storage{

    uint256 private number;
    /**
     * dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
            number= num;
    }
    /**
     * @dev Return value
     * @return value of 'number'
     */
     function retreive() public view returns (uint256){
        return number;
    }
}