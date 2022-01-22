/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

// @dev Realizado por @cryptoL1or basado en curso de Solidity en Udemy:
// @dev Smart Contracts y Blockchain con Solidity de la A a la Z
// @dev https://www.udemy.com/course/solidity-a-z/

// https://rinkeby.etherscan.io/address/0xc1a7d8dd34272a0757f6ab0c429f6ffd3006d871
// contract address: 0xc1a7D8DD34272A0757f6ab0c429f6Ffd3006D871

// --------------------------------------------------------------------------
// ESQUEMA DE PROYECTO

// Sistema de votacion online que permita asignar candidatos, votar y cotejar los resultados.

//  CANDIDATO      /   EDAD   /   DNI
//  Cmaul              20       12345X  
//  Karner             23       54321T
//  Chyoli             21       98765P
//  Rua                19       56789W     

// --------------------------------------------------------------------------


contract votacionOnline{


    // --------------------------------------------------------------------------
    // BLOQUE 1: Creacion y asignacion de variables y modificadores de funciones.

    //Direccion del Owner del contrato.
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Modifier de funciones de ejecucion solo para el gobierno.
    modifier soloGobierno() {
        require(msg.sender == owner, "No formas parte del gobierno.");
        _;
    }

    // Relacion entre nombre de candiato y su hash.
    mapping (string => bytes32) hash_candidato;

    // Relacion entre nombre y numero de votos de cada uno.
    mapping (string => uint) votos_candidato;

    //  Lista de candidatos que se presentaron.
    string [] candidatos_presentados;

    // Identificar votantes. Lista de votantes privada/encriptada.
    bytes32 [] hash_votantes;

    
    // --------------------------------------------------------------------------
    // BLOQUE 2: Implementacion de funciones.

    // --- Dar de ALTA candidatos.
    function altaCandidato(string memory _nombre, uint _edad, string memory _dni) public soloGobierno() {
        bytes32 hashCandidatoAux = keccak256(abi.encodePacked(_nombre, _edad, _dni));
        hash_candidato[_nombre] = hashCandidatoAux;
        
        candidatos_presentados.push(_nombre);
    }
    
    // --- VER candidatos que se presentaron.
    function candidatosPresentados() public view returns(string [] memory){
        return candidatos_presentados;    
    }

    // --- VOTAR a un candidato (solo se permite un voto por ciudadano).
    function votarCandidato(uint _edadVotante, string memory _dniVotante, string memory _nombreCandidato) public returns(string memory, string memory){
    require(_edadVotante >= 18, "Usted no es mayor de edad.");
    bytes32 hashVotantesAux = keccak256(abi.encodePacked(_dniVotante));
    uint contadorAux;

    // Chequear que exista el candidato presentado.
    for (uint i = 0; i < candidatos_presentados.length; i++) {
        if( keccak256(abi.encodePacked(_nombreCandidato)) != keccak256(abi.encodePacked(candidatos_presentados[i]))){
            contadorAux++;
        }
    }
    require(contadorAux == candidatos_presentados.length -1, "El candidato votado no se presento.");       
    
    // Chequear que no haya votado anteriormente.
    for (uint i = 0; i < hash_votantes.length; i++) {
     require( (hashVotantesAux) != (hash_votantes[i]), "No puede votar mas de una vez.");
    }
    votos_candidato[_nombreCandidato]++;
    hash_votantes.push(hashVotantesAux);
    return ("Ha votado correctamente al candidato.", _nombreCandidato);
            
    }

    // --- VER votos de un candidato.
    function verVotos(string memory _nombreCandidato) public view returns(string memory, uint){
    uint contadorAux;

    // Chequear que exista el candidato presentado.
    for (uint i = 0; i < candidatos_presentados.length; i++) {
        if( keccak256(abi.encodePacked(_nombreCandidato)) != keccak256(abi.encodePacked(candidatos_presentados[i]))){
            contadorAux++;
        }
    }
    require(contadorAux == candidatos_presentados.length -1, "El candidato votado no se presento.");    
    return ("El candidato ingresado recibio los siguientes votos: ", votos_candidato[_nombreCandidato]);
    }

    uint []  lista_votos;

    // --- VER restulados de votacion.
    function verResultados() public returns(string [] memory , uint [] memory){
        delete lista_votos;
        for(uint i = 0; i < candidatos_presentados.length; i++){
            lista_votos.push(votos_candidato[candidatos_presentados[i]]);
        }  
        return (candidatos_presentados, lista_votos);
    } 

    // --- GANADOR de la votacion.
    function Ganador() public view returns(string memory, string memory, uint){
    string memory auxiliarGanador = candidatos_presentados[0];
    uint auxiliarGanadorVotos = votos_candidato[candidatos_presentados[0]];
   
        for (uint i = 1; i < candidatos_presentados.length; i++){
         
            require (bytes(candidatos_presentados[i]).length > 0, "No existen mas candidatos.");
            if (auxiliarGanadorVotos < votos_candidato[candidatos_presentados[i]]){
                auxiliarGanador = candidatos_presentados[i];
                auxiliarGanadorVotos = votos_candidato[candidatos_presentados[i]];
            }
        }
        return (auxiliarGanador, "gano con los siguientes votos: ", auxiliarGanadorVotos);
    }


}