/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.5.1;

contract MyContract {
    uint public peopleCount=0;
    mapping(uint => Person) public people;
    uint256 startTime;
    modifier onlyWhileOpen() {
        require(block.timestamp >= startTime);
        _;
    }
    
    function incrementCount() internal {
        peopleCount +=1;   }
    struct Person {
        uint _id;
        string _firstName;
        string _lastName;
        bool marry;
        uint age;
    }
        
    constructor() public {
        startTime=1544668513;
    }
    function addPesron(
        string memory _firstName,
        string memory _lastName,
        bool marry,
        uint age)
        public
        onlyWhileOpen
        {people[peopleCount]=Person(peopleCount, _firstName, _lastName, marry, age);}
}