/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


//Define the contract

contract Employee {
    
    struct Parcial {
        string hash1;  
        string file1;
        string hash2;
        string file2;
        string hash3;
        string file3;
        string hash4;
        string file4;
    }
    
    address private  profesor;
    
    mapping(address => Parcial) public Respuestas;

constructor()
{
    profesor = msg.sender;
}

//Define the setters and getters for the employee

function contestar (string memory _pregunta1, string memory _file1, string memory _pregunta2,string memory _file2, string memory _pregunta3, string memory _file3, string memory _pregunta4, string memory _file4 ) public payable {
    require(msg.value >= 299000000000000000);
    Parcial storage contesta = Respuestas[msg.sender];
    contesta.hash1 = _pregunta1;
    contesta.hash2 = _pregunta2;
    contesta.hash3 = _pregunta3;
    contesta.hash4 = _pregunta4;
    contesta.file1 = _file1;
    contesta.file1 = _file2;
    contesta.file1 = _file3;
    contesta.file1 = _file4;
    profesor.call{value: msg.value}("");
}

function getprofesor()public view returns(address){
    return profesor;
}

function getrespuestas()public view returns( Parcial memory)
{
    return Respuestas[msg.sender];
}
   
//function setEmployee( string memory _name, uint256 _age) public {
  //     name = _name;
    //   age = _age;
//}
   

//function getEmployee() view public returns (string memory ,uint256) {
  //     return (name,age);
 //}
   
}