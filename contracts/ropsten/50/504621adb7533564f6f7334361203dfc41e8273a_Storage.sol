/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    uint256 minFee = 0.001 ether;
    
    struct Person {
        address caller;
        uint256 number;
    }
    
    Person[] public persons;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public payable {
        require(msg.value >= minFee);
        number = num;
        
        Person memory person;
        person.caller = msg.sender;
        person.number = num;
        
        persons.push(person);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}