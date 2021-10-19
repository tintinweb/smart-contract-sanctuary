/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;


contract NotasDeUniversidad {
    
    //Direccion del profesor
    
    address public profesor;
    
    constructor () public {
        
        profesor=msg.sender;
    }
    
    //para relacionar un hash de la identidad del alumno con una nota
   mapping (bytes32 => uint) notas;
   
   
   //array de lista de alumnos que pidan revision de examenes
   
   string [] revisiones;
   
   event AlumnoEvaluado(bytes32, uint);
   event Revision (string);
   
   
   //funcion para Evaluar alumnos
   
   
   modifier UnicamenteProfesor (address _direccion){
       
       require(msg.sender==profesor,"no tienes permisos para ejecutar esta funcion");
       
       _;
   }
   
   
   function Evaluar(string memory _id, uint _nota) public UnicamenteProfesor(msg.sender){
       
       //hash de la identificacion del Alumno
       
       bytes32 Hash_id = keccak256(abi.encodePacked(_id));
       
       //relacionar el hash deel Alumno con su nota
       
       notas[Hash_id] = _nota;
       
       emit AlumnoEvaluado(Hash_id, _nota);
   }
   
   //funcion para ver las notas
   
   
   function VerNotas (string memory _id) public view returns (uint) {
       
       //hash de la identificacion del Alumno
       
       bytes32 Hash_id = keccak256(abi.encodePacked(_id));
       
       //nota asociada al hash del Alumno
       
       uint NotaAlumno = notas[Hash_id];
       
       return NotaAlumno;
       
       
       
   }
   
   
   function RevisionExamen (string memory _id) public{
       
       //almacenamiento de la id del alumno en un array
       
       revisiones.push(_id);
       emit Revision(_id);
       
       
       
   } 
   
   function VerRevision() public UnicamenteProfesor(msg.sender) returns (string[] memory){
       
       return revisiones;
   }
   
   
   
   
}