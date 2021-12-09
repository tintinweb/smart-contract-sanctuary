/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    uint256 a;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num,uint256 aa) public {
        number = num;
        a = aa;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256,uint256){
        return (number,a);
    }
}