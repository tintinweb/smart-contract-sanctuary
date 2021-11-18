/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.5.1;
contract MyContract {
    uint256 public peopleCount = 0;
    mapping(uint => Person) public people;
    address owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _; }
    struct Person {
        uint _id;
        string _firstName;
        string _lastName;
        bool marry;
        uint age;  }
    constructor() public {
        owner = msg.sender; }
    function addPerson(
        string memory _firstName,
        string memory _lastName,
        bool marry,
        uint age)
        public
        onlyOwner
        {
            incrementCount();
            people[peopleCount] = Person(peopleCount, _firstName, _lastName, marry, age);
        }
    function incrementCount() internal {
        peopleCount += 1; }
    }