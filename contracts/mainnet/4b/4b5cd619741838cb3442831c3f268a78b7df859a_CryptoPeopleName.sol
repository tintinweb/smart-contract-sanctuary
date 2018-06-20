pragma solidity ^0.4.13;

contract CryptoPeopleName {
    address owner;
    mapping(address => string) private nameOfAddress;
  
    function CryptoPeopleName() public{
        owner = msg.sender;
    }
    
    function setName(string name) public {
        nameOfAddress[msg.sender] = name;
    }
    
    function getNameOfAddress(address _address) public view returns(string _name){
        return nameOfAddress[_address];
    }
    
}