/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

//SPDX_License-Identifier: MIT
//Robin
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;

// -----------------------------------
//  CANDIDATO   |   EDAD   |      ID
// -----------------------------------
//  Toni        |    20    |    12345X
//  Alberto     |    23    |    54321T
//  Joan        |    21    |    98765P
//  Javier      |    19    |    56789W

contract votacion {
    
    // Direccion del propietario del contrato
    address owner;
    
    // Constructor 
    constructor() public {
        owner = msg.sender;
    }
    
    // Relacion entre el nombre del candidato y el hash de sus datos personales
    mapping(string => bytes32) ID_Candidato;
    
    // Relacion entre el nombre del candidato y el numero de votos
    mapping(string => uint) votos_Candidato;
    
    // Lista de todos los candidatos por nombre
    string [] candidatos;
    
    // Lista de los votantes hashes de identidad
    bytes32 [] votantes;
    
    // Culquier persona pueda usar esta funcion para presentarse a las elecciones 
    function Representar(string memory _nombrePersona, uint _edadPersona, string memory _idPersona) public {
       // Calcular el hash de los datos del candidato
       bytes32 hash_candidato = keccak256(abi.encodePacked(_nombrePersona, _edadPersona, _idPersona));
       
       // Almacenar el hash de los datos del candidato ligados a su nombre 
       ID_Candidato[_nombrePersona] = hash_candidato;
       
       //Almacenar el nombre del ccandidato
       candidatos.push(_nombrePersona);
    } 
    
    // Devuelve la lista de candidatos
    function VerCandidatos() public view returns(string [] memory) {
        return candidatos;
    }
    
    // Funcion para votar
    function Votar(string memory _candidato) public {
        // Hash de la direccion de la persona que ejecuta esta funcion
        bytes32 hash_votante = keccak256(abi.encodePacked(msg.sender));
        
        // Verificar si el votante ya ha votado
        for(uint i = 0; i < votantes.length; i++) {
            require(votantes[i] != hash_votante, "Ya has votado");
        }
        
        // Almacenamos el hash del votante dentro del array de votantes
        votantes.push(hash_votante);
        
        // Añadimos un voto al candidato
        votos_Candidato[_candidato]++;
    }
    
    // Regresa el numero de votos de un candidato
    function VerVotos(string memory _candidato) public view returns(uint) {
        return votos_Candidato[_candidato];
    }
    
    // Ver los votos de cada unos de los candidatos
    function VerResultados() public view returns(string memory) {
        // Guardamos en una variable string los candidatos con sus respectivos votos
        string memory resultados;
        
        for(uint i = 0; i < candidatos.length; i++) {
            resultados = string(abi.encodePacked(resultados, "(", candidatos[i], ", ", uint2str(VerVotos(candidatos[i])), ") --- "));
        }
        
        return resultados;
    }
    
    function Ganador() public view returns(string memory) {
        string memory ganador = candidatos[0];
        bool flag;
        
        for(uint i = 1; i < candidatos.length; i++) {
            if(votos_Candidato[ganador] < votos_Candidato[candidatos[i]]) {
                ganador = candidatos[i];
                flag = false;
            } else if(votos_Candidato[ganador] == votos_Candidato[candidatos[i]]) {
                flag = true;
            }
        }
        
        if(flag == true) {
            ganador = "Hay un empate";
        }
        return ganador;
        
    }
    
    
    //Funcion auxiliar que transforma un uint a un string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
}