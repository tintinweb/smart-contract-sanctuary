pragma solidity ^0.4.24;

contract MyFirstPet {
    mapping(address => string) petname;
    
    function setPet(string _pet) public {
        petname[msg.sender] = _pet;
    }
    
    function getPet(address _petOwnerAddress) public view returns (string) {
        return petname[_petOwnerAddress];
    }
}