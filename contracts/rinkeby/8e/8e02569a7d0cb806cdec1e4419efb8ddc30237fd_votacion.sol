/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

//SPDX-License-Identifier: MIT
pragma solidity >= 0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;

    //-------------------
    // CANDIDATO | EDAD | ID 
    // Boric     |  33  | 123qwe
    // Sichel    |  43  | 456asd
    // Parisi    |  46  |  789zxc
    // Meo       |  45  | 987rty
    // Kast      |  54  | 654ewq
    // Provoste  |  45  | 431ert
    // Artés     |  67  | 435adg

contract votacion{
    
    /*
    // Declaraciones
    */
    
    //Direccion del dueño del contrato
    address owner;
    
    //constructor
    constructor () public{
        owner = msg.sender;
    }
    
    //Relación entre candidato y el hash de sus datos personales
    mapping (string => bytes32) id_cantidato;
    
    //Relacion entre nombre y numero de votos
    mapping (string=>uint) votos_candidatos;
    
    //Lista para almacenar nombres de votos_candidatos
    string [] candidatos;
    
    //lista de hashes de identidad de votantes
    bytes32 [] votantes;
    
    //funciones de votacion
    
    //cualquier persona puede usar la funcion para presentarse a las elecciones
    function Representar(string memory _nombrePersona, uint _edad, string memory _idPersona) public{
        
        //calcular el hash de los datos del candidatos
        bytes32 hash_candidato = keccak256(abi.encodePacked(_nombrePersona, _edad, _idPersona));
        
        
        //almacenar el hash de los datos del candidato ligados al nombres
        id_cantidato[_nombrePersona] = hash_candidato;
        
        //almacenamos el nombre del candidato 
        candidatos.push(_nombrePersona);

    }
    
    //listar los candidatos
    function VerCandidatos() public view returns(string[] memory){
        
        return candidatos;
        
    }
    
    function Votar(string memory _candidato) public{
        
        //obtenemos el hash del votante
        bytes32 hash_votante = keccak256(abi.encodePacked(msg.sender));
    
    
        //revisamos si votó o no 
        for(uint i=0; i<votantes.length ;i++ )
        {
            //cortamos la funcion por que ya votó
            require(votantes[i] != hash_votante, "Ya has votado previamente");
        }
        
        //guardamos el hash del votante en el array
        votantes.push(hash_votante);
        
        //guardamos un voto al candidato seleccionado
        votos_candidatos[_candidato]++;
        
    }
    
    //devuelve los votos de un candidato
    function VerVotos(string memory _candidato) public view returns(uint){
        
        return votos_candidatos[_candidato];
        
    }
    
    
    //funcion uint a string
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
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    
    //ver los votos de los candidatos
    function VerResultados() public view returns(string memory){
    
        //guardamos los candidatos y los votos
        string memory resultados = "";
        
        //recorremos los candidatos
        for(uint i=0; i<candidatos.length ;i++ )
        {
            //metemos todo el string con el nombre del candidato y votos en un hash y lo pasamos a string
            resultados = string(abi.encodePacked(resultados, "(", candidatos[i], ", ", uint2str(VerVotos(candidatos[i])), ") ----"));
        }
        return resultados;     
    }
    
    function Ganador() public view returns(string memory){
        
        string memory ganador=candidatos[0];
        bool flag;
        for(uint i=1; i<candidatos.length ;i++ )
        {
            if(votos_candidatos[ganador] < votos_candidatos[candidatos[i]]){
                ganador = candidatos[i];
                flag = false;
            }else{
                if(votos_candidatos[ganador] == votos_candidatos[candidatos[i]]){
                    flag = true;
                }
            }
        }
        
        if(flag){
            ganador = "Empate!";
        }
        
        return ganador;
    }
    
}