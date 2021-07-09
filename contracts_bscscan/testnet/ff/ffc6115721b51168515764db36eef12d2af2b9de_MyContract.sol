/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity ^0.5.1;

contract MyContract
{
    
    uint256 public peopleCount = 0;
    mapping(uint => Person) public people;
    
    mapping(address => Person) public peopleAddress;
    
    address owner;
    
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    struct Person
    {
        uint _id;
        string _firstname;
        string _lastname;
    }
    
    constructor() public
    {
        owner = msg.sender;
    }
    
    function addPerson(string memory _firstname, string memory _lastname) public onlyOwner
    {
        people[peopleCount] = Person(peopleCount, _firstname, _lastname);
        incrementCount();
    }
    
    function incrementCount() internal
    {
        peopleCount++;
    }
    
}