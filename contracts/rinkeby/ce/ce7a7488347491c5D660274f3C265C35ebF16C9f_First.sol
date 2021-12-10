pragma solidity ^0.8.0;
    
// A simple smart contract
contract First{
    string Name = "Hi, This is Samar and now i am alive forever in blockchain";
    constructor(){} 
    function getName() public view returns(string memory) {
        return Name;
    }
    
    function setName(string memory newName) public {
        Name = newName;
    }
}