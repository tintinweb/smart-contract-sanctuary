/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;

contract notas {
    
    // direccion del profesor
    address public profesor;
    
    // constructor
    constructor () public {
        profesor = msg.sender;
    }
    
    
    // mapping para relacionar el hash de la identidad del alumno con su nota del examen
    mapping (bytes32 => uint) Notas;
    
    //Array de los alumnos que pidan revisiones de examen
    string [] revisiones;
    
    // eventos
    event alumnoEvaluado(bytes32);
    event alumnoRevision(string);
    
    //funcion para evaluar alumnos
    function evaluar(string memory _idAlumno, uint _nota) public UnicamenteProfesor(msg.sender){
        //hash de la identificacion del alumno
        bytes32 hash_idAlumno = keccak256(abi.encodePacked(_idAlumno));
        //relaciun entre el hash de la identificacion del alumno y su Notas
        Notas[hash_idAlumno] = _nota;
        //emision eventos
        emit alumnoEvaluado(hash_idAlumno);
    }
    
    modifier UnicamenteProfesor(address _direccion){
        //requiere que la direccion introducida por parametro sea igual al owner del contrato
        require(_direccion == profesor, "no tienes permisos para ejecutar esta funccion");
        _;
    }
    
    //funcion para ver las notas de un alumno
    function verNotas(string memory _idAlumno) public view returns (uint){
        bytes32 hash_idAlumno = keccak256(abi.encodePacked(_idAlumno));
        uint notaAlumno = Notas[hash_idAlumno];
        return notaAlumno;
    }
    
    //funcion para pedir una revision del examen
    function Revision(string memory _idAlumno) public {
        //almacenamiento de la identidad del alumno en un array
        revisiones.push(_idAlumno);
        emit alumnoRevision(_idAlumno);
    }
    
    //funcion para ver alumnos que han solicitado revision de examen
    function VerRevisiones() public view UnicamenteProfesor(msg.sender) returns(string [] memory) {
        return revisiones;
    }
    
    
    
    
    
    
    
    
}