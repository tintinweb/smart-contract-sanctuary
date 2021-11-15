pragma solidity ^0.8.0;

contract Register {
    address public admin;

    struct Person {
        string name;
        string surname;
        uint256 age;
    }

    // Variables have private and public options. Private variables can still be reached through pointers (get sth at ...)
    Person[] public people;
    mapping(address => uint256) public personIndex;

    // Functions can be public (most expensive, everyone, including this contract can call public functions),
    // external(everyone, except this contract can call this function) and
    // internal (just this contract can call)

    // function can have state mutability: view, pure or "" (empty string)

    // Functions can store to: storage (on chain data), memory (available during run-time), calldata (input data)
    function getPeople() external view returns (Person[] memory) {
        return people;
    }

    constructor() {
        admin = msg.sender;
    }

    function newPerson(
        string calldata name,
        string calldata surname,
        uint256 age
    ) external {
        people.push(Person(name, surname, age));
        personIndex[msg.sender] = people.length - 1;
    }

    function updateAge(uint256 newAge) external {
        uint256 myIndex = personIndex[msg.sender];
        people[myIndex].age = newAge;
    }

    function updateAge(address personAddress, uint256 newAge)
        external
        onlyAdmin
    {
        uint256 myIndex = personIndex[personAddress];
        people[myIndex].age = newAge;
    }

    function deletePerson() external {
        deletePerson(msg.sender);
    }

    function deletePersonAdmin(address personAddress) external onlyAdmin {
        deletePerson(personAddress);
    }

    function deletePerson(address personAddress) internal {
        uint256 myIndex = personIndex[personAddress];
        delete people[myIndex];
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "NOT AUTHORIZED");
        _; // Same as calling code from inside functions with onlyAdmin modifiers;
    }
}

