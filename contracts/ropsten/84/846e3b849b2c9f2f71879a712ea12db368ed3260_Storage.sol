/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;

    struct PersonNumber {
        address person;
        uint256 number;
    }
    
    PersonNumber[] public person_numbers;
    
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
        PersonNumber memory p;
        p.person = msg.sender;
        p.number = num;
        
        person_numbers.push(p);
    }

    function number_of_persons() public view returns(uint256) {
        return person_numbers.length;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}