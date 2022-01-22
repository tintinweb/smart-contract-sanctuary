/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// @dev Realizado por @cryptoL1or basado en curso de Solidity en Udemy:
// @dev Smart Contracts y Blockchain con Solidity de la A a la Z
// @dev https://www.udemy.com/course/solidity-a-z/learn/lecture/27575708#questions/16536182

// https://rinkeby.etherscan.io/tx/0xfcb92432e8ecab247a6c88252f870855632ff3b385eadd13e728e13d34284f41
// contract address: 0x2AF7cb01524da048aae9211b276ADB79FbE68F6F

// --------------------------------------------------------------------------
// ESQUEMA DE PROYECTO

// Se debe crear un sistema de evaluacion de notas donde los profesores deberán
// cargar las notas de los alumnos.
// Cada alumno tendrá: Nombre, ID, Nota.

//  NOMBRE   /    ID    /   NOTA
//  Lior       12345        8  
//  Julian     99999        9
//  Melissa    11111        10
//  Juan       77777        3      

// --------------------------------------------------------------------------

contract notasUniversitarias{
    // --------------------------------------------------------------------------
    // BLOQUE 1: Creacion y asignacion de variables y modificadores de funciones.

    // Direccion del profesor quien cargará las notas.
    address public direccionProfesor = msg.sender;

    // Modifier de funciones de ejecucion solo para el profesor.
    modifier soloProfesor() {
        require(msg.sender == direccionProfesor, "No tenes permisos de profesor.");
        _;
    }

    // Modifier de funciones de ejecucion solo para el alumno.
    modifier soloAlumno() {
        require(msg.sender != direccionProfesor, "Funcion solo ejecutable por alumnos.");
        _;
    }

    
    // Creación de dato complejo de alumnos.
    struct alumno{
        string nombreAlumno;
        string idAlumno;
        uint notaAlumno;
        uint revisionesSolicitadas;
    }

    // Mapping para relacionar hash de alumnos con sus notas
    mapping (bytes32 => alumno) notas;

    // Listado de alumnos que piden revision de sus notas. 
    string [] revisiones;

    // Eventos de Contrato
    event alumno_evaluado(bytes32);
    event revision_solicitada(string);

    // --------------------------------------------------------------------------
    // BLOQUE 2: Creacion de funciones de contrato.

    // Asociacion de identidades de alumno con sus notas y evaluarlos.  
    function evaluarAlumno(string memory _nombreAlumno, string memory _idAlumno, uint _notaAlumno) public soloProfesor() returns(string memory)  {
        bytes32 hashAlumno = keccak256(abi.encodePacked(_nombreAlumno,_idAlumno));
        notas[hashAlumno] = alumno(_nombreAlumno, _idAlumno, _notaAlumno, 0);
        
        emit alumno_evaluado(hashAlumno);
        return "La nota ha sido cargada correctamente";    
        
    }

    // Consultar nota.
    function consultarNota(string memory _nombreAlumno, string memory _idAlumno) public view returns(uint){
        bytes32 hashAlumno = keccak256(abi.encodePacked(_nombreAlumno,_idAlumno));
        require(notas[hashAlumno].notaAlumno != 0, "No se encontro la nota del alumno introducido");
        return notas[hashAlumno].notaAlumno;   
    }

    // Solicitar una revision de nota. Maximo 2 revisiones posibles.
    uint maxRevs;

    function cantidadRevisiones(uint _cantidadAdmitida) public soloProfesor(){
        maxRevs = _cantidadAdmitida;
    }

    function solicitarRevision(string memory _nombreAlumno, string memory _idAlumno) public soloAlumno() returns(string memory, uint){
        bytes32 hashAlumno = keccak256(abi.encodePacked(_nombreAlumno,_idAlumno));
        uint revisionesRestantes;

        require(maxRevs > 0, "El profesor debe especificar una cantidad maxima admitida de revisiones");
        require((notas[hashAlumno].notaAlumno != 0), "No se encontraron notas para el alumno ingresado");
        require(notas[hashAlumno].revisionesSolicitadas < maxRevs, "Ya se solicitaron las revisiones permitidas");

        emit revision_solicitada(notas[hashAlumno].nombreAlumno);

        notas[hashAlumno].revisionesSolicitadas++;
        revisionesRestantes = maxRevs - notas[hashAlumno].revisionesSolicitadas;

        // Se documentan los alumnos que pidieron revision
        revisiones.push(notas[hashAlumno].nombreAlumno);

        return ("Se ha solicitado correctamente la revision, restan las siguientes revisiones:", revisionesRestantes);

    }

    // Consulta del profesor de los alumnos que solicitaron revision
    function consultarRevisiones() public view soloProfesor() returns(string [] memory){
      return revisiones;    
    }



}