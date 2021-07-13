/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract TakeZOMBreak {

    uint256 number;
    string abc;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num, string memory a) public {
        number = num;
        abc = a;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256, string memory){
        return (number,abc) ;
    }
}