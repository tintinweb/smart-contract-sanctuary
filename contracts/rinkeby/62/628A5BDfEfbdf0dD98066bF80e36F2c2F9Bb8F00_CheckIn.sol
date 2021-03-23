/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title CheckIn
 * @dev Store students names
 */
contract CheckIn {

    mapping (address => string) names;

    /**
     * @dev Store name in a mapping
     * @param name value to store
     */
    function checkIn(string memory name) public {
        names[msg.sender] = name;
    }

    /**
     * @dev Return student name 
     * @return name of 'student'
     */
    function getStudent(address student) public view returns (string memory){
        return names[student];
    }
}