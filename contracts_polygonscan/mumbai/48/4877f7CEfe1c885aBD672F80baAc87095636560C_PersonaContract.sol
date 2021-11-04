//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract PersonaContract {
    address private owner;

    struct Legajo {

        uint id;
        string description;
        uint date;

    }

    struct Persona{
        string name;
        uint age;
        //Legajo[] legajos;
        }

    mapping (address => Persona) private personas;
    
    constructor() {
        
        owner = msg.sender;
    }

    function addPersona(string memory _name , uint _age) public{

        //personas[msg.sender]=Persona({name: _name , age: _age , legajos: Legajo[]});
        personas[msg.sender]=Persona({name: _name , age: _age });
    }

    function getPersonaName() public view returns(string memory){

        return personas[msg.sender].name;
    }
    function getPersonaAge() public view returns(uint){

        return personas[msg.sender].age;
    }
}