/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.5.1;

contract StatusContract {
    
    uint256 public peopleCount = 0;
    mapping(uint => Person) public people;
    
    address owner;
    uint256 startTime;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyWhileOpen() {
        require(block.timestamp <= startTime + 300000);
        _;
    }
    
    constructor() public {
        startTime = block.timestamp;
        owner = msg.sender;
    }
    
    struct Person {
        uint _id;
        uint age;
        string _firstName;
        string _lastName;
        bool isMarried;
    }
    
    function addPerson(
        string memory _firstName, 
        string memory _lastName, 
        uint age, 
        bool isMarried
    ) public onlyOwner onlyWhileOpen {
        incrementCount();
        people[peopleCount] = Person(peopleCount, age, _firstName, _lastName, isMarried);
    }
    
    function incrementCount() internal {
        peopleCount += 1;
    }
    
}