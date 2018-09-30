pragma solidity ^0.4.4;
contract SimpleStorage{

string name;

function set(string newName) public{
name = newName;
}
function getName() public view returns(string){
return name;
}
}