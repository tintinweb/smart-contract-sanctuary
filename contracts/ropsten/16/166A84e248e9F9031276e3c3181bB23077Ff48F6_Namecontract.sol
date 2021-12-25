//SPDX- License- Identityfier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Namecontract{
    string Name;
    function getName() view public returns(string memory){
        return Name;
    }
     function setName(string memory newName) public{
         Name=newName;
     }
}