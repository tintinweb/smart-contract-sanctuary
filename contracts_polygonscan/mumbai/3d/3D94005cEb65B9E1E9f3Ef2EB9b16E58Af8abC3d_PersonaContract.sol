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

    mapping (uint => Persona) private personas;
    
    constructor() {
        
        owner = msg.sender;
    }

    function addPersona(uint _id , string memory _name , uint _age) public{

        //personas[msg.sender]=Persona({name: _name , age: _age , legajos: Legajo[]});
        personas[_id]=Persona({name: _name , age: _age });
    }

    function getPersonaName(uint _id) public view returns(string memory){

        return personas[_id].name;
    }
    function getPersonaAge(uint _id) public view returns(uint){

        return personas[_id].age;
    }
}