pragma solidity ^0.4.0;

contract Bussines_Card {
    
    string public name;
    uint256 public age;
    string public photoHash;
    address public wallet;
    
    function  Bussines_Card(string _name,
    uint256 _age,
    string _photoHash,
    address _wallet) 
    {
        name = _name;
        age = _age;
        photoHash =_photoHash;
        wallet = _wallet;
    }
    
    function  changeAge(uint256 _age) {
        age = _age;
    }

}