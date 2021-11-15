// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Register {
    address public admin;

    struct Person {
        string name;
        string surname;
        uint age;
    }

    Person[] public people;
    mapping(address => uint) public personIndex;

    function getPeople() external view returns (Person[] memory) {
        return people;
    }

    Person public someone;

    constructor() {
        admin = msg.sender;
    }
    

    function newPerson(string calldata name, string calldata surname, uint age) external {
        Person memory someoneNew = Person(name,surname,age);
        people.push(someoneNew);

        personIndex[msg.sender] = people.length - 1;
    }



    function updateAge(uint newAge) external {
        updateAge(msg.sender,newAge);
    }

    function updateAgeAdmin(address personAddress, uint newAge) external onlyAdmin {
        updateAge(personAddress,newAge);
    }

    function updateAge(address personAddress, uint newAge) internal {
        uint myIndex = personIndex[personAddress];
        people[myIndex].age = newAge;
    }


    function deletePerson () external {
        deletePerson(msg.sender);
    }

    function deletePersonAdmin(address personAddress) external onlyAdmin {
        deletePerson(personAddress);
    }

    function deletePerson(address personAddress) internal {
        uint myIndex = personIndex[personAddress];
        delete people[myIndex];
    }



    modifier onlyAdmin() {
        require(msg.sender == admin, "NOT_AUTHORIZED");        
        _;
    }
}

