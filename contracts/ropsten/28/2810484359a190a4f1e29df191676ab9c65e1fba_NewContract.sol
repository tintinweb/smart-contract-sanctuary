/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.5.1;

contract NewContract{
    mapping(uint256 => Person) public people;
    uint256 CountOfPeople = 0;
    struct Person{
        uint ID;
        string FirstName;
        string LastName;
        uint256 Age;
        bool Married;
    }
    address owner;
    constructor() public{
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    function AddPerson(string memory FName, string memory LName, uint256 age, bool married) public onlyOwner{
        people[CountOfPeople] = Person(CountOfPeople, FName, LName, age, married); 
        CountOfPeople += 1;
    }
}