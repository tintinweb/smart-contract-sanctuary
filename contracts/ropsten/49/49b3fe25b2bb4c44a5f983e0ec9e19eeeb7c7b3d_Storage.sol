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
    
    uint256 public current_fee = 0.0001 ether;
    uint256 max_fee = 0.01 ether;
    
    struct PersonNumber {
        address person;
        uint256 number;
    }

    PersonNumber[] public person_numbers;
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num, uint256 new_fee) public payable {
        require(msg.value >= current_fee);
        require(new_fee <= max_fee);
        
        current_fee = new_fee;
        number = num;
        
        PersonNumber memory p;
        p.person = msg.sender;
        p.number = num;
        
        person_numbers.push(p);
    }
    
    function number_of_persons() public view returns(uint256) {
        return person_numbers.length;
    }
    
    function withdraw() external {
        require(msg.sender == owner);
        
        uint256 current_balance = address(this).balance;
        payable(owner).transfer(current_balance);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}