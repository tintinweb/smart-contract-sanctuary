pragma solidity ^0.4.18;
 
contract DeveloperFactory {
    uint minAge = 10;
    uint maxAge = 30;


    struct Developer {
        string name;
        uint age;
        uint id;
    }

    Developer[] public developers;

    function _generateRandomId(string _str) private pure returns (uint) {
        uint rand = uint(keccak256(_str));
        return rand;
    }

    function _createDeveloper(string _name, uint _age, uint _id) private {
        developers.push(Developer(_name, _age, _id));
    }

    function createRandomDeveloper(string _name, uint _age) public view {
        require(_age > minAge);
        require(_age < maxAge);
        uint id = _generateRandomId(_name);
        _createDeveloper(_name, _age, id);
    }
}