/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity ^ 0.5.1;

contract MyContract {
    uint256 public peopleCount = 0;
    mapping(uint => Person) public people;
    uint256 startTime;
    modifier onlyWhileOpen() {
        require(block.timestamp >= startTime);
        _;
    }

    function incrementCount() internal {
        peopleCount += 1;}


 struct Person {
        uint _id;
        string _firstName;
        string _lastName;  }

    constructor() public {
        startTime = 1619545934;}

    function addPerson(
        string memory _firstName,
        string memory _lastName )
        public
        onlyWhileOpen
    {  people[peopleCount] = Person(peopleCount, _firstName, _lastName); }
}