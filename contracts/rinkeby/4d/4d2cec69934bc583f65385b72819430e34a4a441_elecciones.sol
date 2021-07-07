/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

//para poder votar, un oraculo debe hacer la validacion de la direccion.

contract elecciones{
    //determina si nos encontramos en el periodo de elecciones
    bool periodo_eleccion;
    bool periodo_planificacion;
    bool periodo_recuento;
    
    //determina si la direccion es un Oraculo
    mapping(address=>bool)isOracle;
    
    //determina si cierta direccion es o no owner
    mapping(address=>bool) isOwner;
    
    //struct de los candidatos
    struct Candidatos{
        string nombre;
        uint votos;
        bool esValor; //para verificar que el candidato existe
    }
    
    //mapping que verifica si la direccion con la que se quiere votar ya esta validada
    mapping(address=>bool) estaValidada;
    
    //asocia el nombre del candidato con su struct
    mapping(string=>Candidatos) mapping_candidatos;
    
    //array con los candidatos
    string[] public lista_candidatos;
    string[] votos_repetidos;
    
    //asocia la direccion del votante con la cantidad de votos que tiene esta, para que no se pueda votar dos veces
    mapping(address => uint) votosPorAdress;
    
    //mapping que asocia la direccion del votante con el candidato votado
    mapping(address => string) votos;
    
    
    //al instanciar el contrato se abre el periodo de elecciones
    constructor(){
        isOwner[msg.sender] = true;
        periodo_planificacion = true;
        periodo_eleccion = false;
        periodo_recuento = false;
    }
    
    //por si se requiere añadir otro Owner
    function anadir_owner(address _direccion) public{
        require(isOwner[msg.sender], "Necesita ser owner para anadir otro owner");
        isOwner[_direccion] = true;
    }
    
    //se anade un oraculo, el que verificara si un usuario podra votar o no
    function anadir_oraculo(address _direccion) public{
        require(isOwner[msg.sender], "Necesita ser owner para anadir un oraculo");
        isOracle[_direccion] = true;
    }
    
    //valida una direccion para que pueda votar
    function verificar_address(address _direccion) public{
        require(isOracle[msg.sender], "Necesita ser oraculo para validar una direccion");
        estaValidada[_direccion] = true;
    }
    
    //omite la posibilidad de que una direccion pueda votar
    function omitir_address(address _direccion) public{
        require(isOracle[msg.sender], "Necesita ser oraculo para omitir una direccion");
        estaValidada[_direccion] = false;
    }
    
    //añade un candidato al mapping, para que podamos votarlo.
    function anadir_candidato(string memory _nombre) public{
        require(isOwner[msg.sender],"Necesita ser owner para anadir un candidato");
        require(periodo_planificacion, "No se encuentra en el periodo de planificacion");
        
        Candidatos memory candidato_nuevo = Candidatos({
            nombre : _nombre,
            votos : 0,
            esValor : true
        });
        mapping_candidatos[_nombre] = candidato_nuevo;
        lista_candidatos.push(_nombre);
    }
    
    //para evitar caer en loops hasta encontrar el candidato en el string, directamente modificamos el atributo esValor a false
    function borrar_candidato(string memory _nombre) public{
        require(isOwner[msg.sender] && periodo_eleccion, "Necesita ser owner para borrar un candidato");
        require(periodo_planificacion, "No se encuentra en el periodo de planificacion");
        mapping_candidatos[_nombre].esValor = false;
    }
    
    //se cierra el perioodo de planificacion para comenzar el perioodo de elecciones
    function abrir_votaciones() public{
        require(isOwner[msg.sender], "Debes ser owner para abrir las votaciones");
        periodo_eleccion = true;
        periodo_planificacion = false;
        periodo_recuento = false;
    }
    
    //funcion publica para otorgarle un voto a uno de los candidatos
    function votar(string memory _candidato) public{   
        //require(votosPorAdress[msg.sender] == 0, "Ya ha votado");
        require(periodo_eleccion, "Las elecciones han sido finalizadas, o no han comenzado aun");
        require(mapping_candidatos[_candidato].esValor, "El candidato no existe");
        require(estaValidada[msg.sender], "Su direccion aun no ha sido validada, debe esperar la validacion antes de votar");
        votos[msg.sender] = _candidato;
        votosPorAdress[msg.sender]++;
        mapping_candidatos[_candidato].votos++;
    }
    
    //devuelve la cantidad de votos que tiene cada candidato hasta el momento
    function votos_parciales(string memory _candidato) public view returns (uint){
        require(periodo_eleccion || periodo_recuento, "Las elecciones no han comenzado aun");
        require(mapping_candidatos[_candidato].esValor, "El candidato no existe");
        return(mapping_candidatos[_candidato].votos);
    }
    
    //devuelve el total de votos que se hicieron
    function votos_totales()public view returns (uint){
        require(periodo_eleccion || periodo_recuento, "Las elecciones no han comenzado aun");
        uint resultado = 0;
        //al ser un numero limitado de candidatos, nos podemos permitir hacer una iteracion
        for(uint8 i=0; i<lista_candidatos.length; i++){
            resultado+=mapping_candidatos[lista_candidatos[i]].votos;
        }
        return resultado;
    }
    
    //cierra el periodo de votacion, y habilita el periodo de recuento
    function cerrar_votaciones() public{
        require(isOwner[msg.sender], "Debes ser owner para cerrar las votaciones");
        require(periodo_eleccion, "Las elecciones ya han sido finalizadas o no han comenzado");
        periodo_eleccion = false;
        periodo_planificacion = false;
        periodo_recuento = true;
    }
    
    
    //funcion provada que sera usada por otra, en la que retorna dos valores, el nombre del ganador y la cantidad de votos que obtuvo
    function ganador_votacion() public returns(string memory nombre, uint cantidad){
        require(periodo_recuento, "Las votaciones siguen vigentes o no han comenzado");

        string memory maximo = lista_candidatos[0];
        
        for(uint8 i=1; i<lista_candidatos.length; i++){
            if(mapping_candidatos[lista_candidatos[i]].votos > mapping_candidatos[maximo].votos){
                maximo = lista_candidatos[i];
            } 
            else if(mapping_candidatos[lista_candidatos[i]].votos == mapping_candidatos[maximo].votos){
                if(votos_repetidos.length == 0){
                    votos_repetidos.push(mapping_candidatos[lista_candidatos[i]].nombre);
                    votos_repetidos.push(mapping_candidatos[maximo].nombre);
                } else{
                    if(mapping_candidatos[votos_repetidos[0]].votos < mapping_candidatos[maximo].votos){
                        votos_repetidos[0] = mapping_candidatos[lista_candidatos[i]].nombre;
                        votos_repetidos[1] = mapping_candidatos[maximo].nombre;
                    }
                }
            }
        }
        
        string memory ganador = mapping_candidatos[maximo].votos > mapping_candidatos[votos_repetidos[0]].votos ? maximo : "empate";
        
        return keccak256(abi.encodePacked((ganador))) == keccak256(abi.encodePacked(("empate"))) ? ("empate", mapping_candidatos[votos_repetidos[0]].votos) : (ganador, mapping_candidatos[ganador].votos);
    }
    
    //llama a una funcion privada y devuelve el nombre del candidato ganador
    function nombre_ganador() public returns(string memory){
        require(periodo_recuento, "Las votaciones siguen vigentes o no han comenzado");
        string memory nombre;
        (nombre,) = ganador_votacion();//con la , ignoramos la cantidad que obtuvo ya que lo utilizaremos en otra funcion
        
        if(keccak256(abi.encodePacked((nombre))) == keccak256(abi.encodePacked(("empate")))){
            return hay_empate();
        }
        return nombre;
    }
    
    function hay_empate() private view returns(string memory){
        string memory candidato1 = votos_repetidos[0];
        string memory espacio = " ";
        string memory candidato2 = votos_repetidos[1];
        return string (abi.encodePacked(candidato1, espacio, candidato2));
    }
    
    //llama a una funcion privada y devuelve la cantidad de votos que obtivo el ganador
    function votos_ganador() public returns(uint){
        require(periodo_recuento, "Las votaciones siguen vigentes o no han comenzado");
        uint cantidad_votos_ganador;
        (,cantidad_votos_ganador) = ganador_votacion();
        return cantidad_votos_ganador;
    }
    
    
    
}