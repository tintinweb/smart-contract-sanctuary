pragma solidity ^0.4.0;

contract myfirstcontract {
    string name;
    uint age;
    
    function getName() returns (string) {
        return name;
    }
    
    function getAge() returns (uint) {
        return age;
    }
    
    function setName (string _name) {
        name = _name;
    }
    
    function setAge (uint _age) {
        age = _age;
    }
    
}