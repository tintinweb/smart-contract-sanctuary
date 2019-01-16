pragma solidity ^0.5.0;

contract MyFirstContract {
    
    string private _name;
    uint private _age;
    
    function setName(string memory name) public {
        _name = name;
    }
    
    function getName() public view returns (string memory) {
        return _name;
    }
    
    function setAge(uint age) public {
        _age = age;
    }
    
    function getAge() public view returns (uint) {
        return _age;
    }
    
}