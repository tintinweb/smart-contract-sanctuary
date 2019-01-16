pragma solidity 0.4.24;

contract YouthInfo {
    struct Person {
        uint age;
        string name;
        string fatherName;
        string location;
        uint id;
    }
    
    mapping(uint => Person) public personsMap;
    mapping(string => string) private personValidity;
    
    uint public personCount;
    uint private ageRange;
    
    constructor() public {
        personCount = 0;
        ageRange = 18;
    }
    
    modifier checkAge(uint _age) {
        require(_age >= ageRange, &#39;Age must be greater than 18&#39;);
        _;
    }

    modifier isUnique(string _name, string _fatherName) {
        string storage fatherName = personValidity[_name];
        require(keccak256(abi.encodePacked(fatherName)) != keccak256(abi.encodePacked(_fatherName)), &#39;Person already exists&#39;);
        _;
    }
    
    function addPerson(uint _age, string _name, string _fatherName, 
        string _location) public payable checkAge(_age) isUnique(_name, _fatherName) {
        personsMap[personCount] = Person(_age, _name, _fatherName, _location, personCount);
        personValidity[_name] = _fatherName;
        personCount++;
    }
    
    function getPersonInfo(uint id) public view returns(uint, string, string, string, uint) {
        return (personsMap[id].age, personsMap[id].name, 
            personsMap[id].fatherName, personsMap[id].location, personsMap[id].id);
    }
    
    function updatePersonLocation(uint id, string _location) public {
        personsMap[id].location = _location;
    }
    
}