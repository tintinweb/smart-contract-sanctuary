pragma solidity ^0.4.23;

contract MyTest{
    string private name;
   
    function setName(string newName) public{
        name=newName;
    }
    
    function getName() public view returns(string){
        return name;
    }
    
}