/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

/**

GET READY FOR OKAMI INU

LAUNCHING SHORTLY 

Website: https://OkamiInu.info/
Telegram: https://t.me/OkamiInuETH

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract OkamiHelper {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}