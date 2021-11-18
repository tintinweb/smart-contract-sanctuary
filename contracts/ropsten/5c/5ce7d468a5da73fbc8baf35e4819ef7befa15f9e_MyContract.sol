/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.5.1;

contract MyContract {
    uint256 peopleCount = 0;
    mapping(uint => Person) public people;
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    struct Person {
        uint _id;
        string _firstName;
        string _lastName;
    }
    
    function addPerson(string memory _firstName, string memory _lastName) public onlyOwner {
        peopleCount += 1;
        people[peopleCount] = Person(peopleCount, _firstName, _lastName);
        
    }
}