//SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;


// -----------------------------------
//  CANDIDATO   |   EDAD   |      ID
// -----------------------------------
//  Toni        |    20    |    12345X
//  Alberto     |    23    |    54321T
//  Joan        |    21    |    98765P
//  Javier      |    19    |    56789W


contract votacion{
    
    //Direccion del propietario del contrato
    address owner;
    
    //constructor
    constructor () public{
        owner = msg.sender;
    }
    
    //Relacion entre el nombre del candidato y el hash de sus datos personales
    mapping (string=>bytes32) ID_Candidato;
    
    //Relacion entre el nombre del candidato y el numero de votos
    mapping (string=>uint) votos_candidato;
    
    //Lista para almacenar los nombres de los candidatos
    string [] candidatos;
    
    //Lista de los hashes de la identidad de los votantes
    bytes32 [] votantes;
    
    
    //Cualquier persona puede usar esta funcion para presentarse a las elecciones
    function Representar(string memory _nombrePersona, uint _edadPersona, string memory _idPersona) public{
        
        //Hash de los datos del candidato
        bytes32 hash_Candidato = keccak256(abi.encodePacked(_nombrePersona, _edadPersona, _idPersona));
        
        //Almacenamos el hash de los datos del candidato ligados a su nombre
        ID_Candidato[_nombrePersona] = hash_Candidato;
        
        //Almacenamos el nombre del candidato
        candidatos.push(_nombrePersona);
        
    }
    
    //Permite visualizar las personas que se han presentado como candidatos a las votaciones
    function VerCandidatos() public view returns(string[] memory){
        //Devuelve la lista de los candidatos presentados
        return candidatos;
    }
    
    //Los votantes van a poder votar
    function Votar(string memory _candidato) public{
        
        //Hash de la direccion de la persona que ejecuta esta funcion
        bytes32 hash_Votante = keccak256(abi.encodePacked(msg.sender));
        //Verificamos si el votante ya ha votado
        for(uint i=0; i<votantes.length; i++){
            require(votantes[i]!=hash_Votante, "Ya has votado previamente");
        }
        //Almacenamos el hash del votante dentro del array de votantes
        votantes.push(hash_Votante);
        //Añadimos un voto al candidato seleccionado
        votos_candidato[_candidato]++;
    }
    
    //Dado el nombre de un candidato nos devuelve el numero de votos que tiene
    function VerVotos(string memory _candidato) public view returns(uint){
        //Devolviendo el numero de votos del candidato _candidato
        return votos_candidato[_candidato];
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
    
    
    //Ver los votos de cada uno de los candidatos
    function VerResultados() public view returns(string memory){
        //Guardamos en una variable string los candidatos con sus respectivos votos
        string memory resultados="";
        
        //Recorremos el array de candidatos para actualizar el string resultados
        for(uint i=0; i<candidatos.length; i++){
            //Actualizamos el string resultados y añadimos el candidato que ocupa la posicion "i" del array candidatos
            //y su numero de votos
            resultados = string(abi.encodePacked(resultados, "(", candidatos[i], ", ", uint2str(VerVotos(candidatos[i])), ") -----"));
        }
        
        //Devolvemos los resultados
        return resultados;
    }
    
    //Proporcionar el nombre del candidato ganador
    function Ganador() public view returns(string memory){
        
        //La variable ganador va a contener el nombre del candidato ganador
        string memory ganador = candidatos[0];
        //La variable flag nos sirve para la situacion de empate
        bool flag;
        
        //Recorremos el array de candidatos para determinar el candidato con un numero mayor de votos
        for(uint i=1; i<candidatos.length; i++){
            
            //Comparamos si nuestro ganador ha sido superado por otro candidato
            if(votos_candidato[ganador] < votos_candidato[candidatos[i]]){
                ganador = candidatos[i];
                flag=false;
            }else{
                //Miramos si hay empate entre los candidatos
                if(votos_candidato[ganador] == votos_candidato[candidatos[i]]){
                    flag=true;
                }
            }
        }
        
        //comprobamos si ha habido un empate entre los candidatos
        if(flag==true){
            //Informamos del empate
            ganador="¡Hay un empate entre los candidatos!";
        }
        
        //Devolvemos el ganador
        return ganador;
        
    }
}