pragma solidity ^0.4.22;
 
contract DeveloperFactory {
    // Let&#39;s create a Developer!
 
    event NewDeveloper(uint devId, string name, uint age);
 
    uint maxAge = 100;
    uint minAge = 5;
 
    struct Developer {
        string name;
        uint id;
        uint age;
    }
 
    Developer[] public developers;
 
    function _createDeveloper( string _name, uint _id, uint _age) private {
        uint id = developers.push(Developer(_name, _id, _age)) - 1;
        NewDeveloper(id, _name, _age);
    }
 
    function _generateRandomId( string _str ) private pure returns (uint) {
        uint rand = uint(keccak256(_str));
        return rand;
    }
 
    function createRandomDeveloper( string _name, uint _age ) public view {
        require(_age > minAge);
        require(_age < maxAge);
        uint randId = _generateRandomId(_name);
        _createDeveloper(_name, randId, _age);
    }
}