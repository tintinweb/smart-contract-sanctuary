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
    
    //nombre o nombres del o de los ganadores (en caso de empate)
    string electo;
    
    //cantidad de votos finales del o de los ganadores
    uint votos_electo;
    
    //verfica si ya se llamo a la funcion de calcular los resultados.
    bool resultados;
    
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
    

    
    //al instanciar el contrato se abre el periodo de elecciones
    constructor(){
        isOwner[msg.sender] = true;
        periodo_planificacion = true;
        periodo_eleccion = false;
        periodo_recuento = false;
        resultados = false;
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
        require(isOracle[msg.sender],"Necesita ser oraculo para anadir un candidato");
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
        require(isOracle[msg.sender] && periodo_eleccion, "Necesita ser oraculo para borrar un candidato");
        require(periodo_planificacion, "No se encuentra en el periodo de planificacion");
        mapping_candidatos[_nombre].esValor = false;
    }
    
    //se cierra el perioodo de planificacion para comenzar el perioodo de elecciones
    function abrir_votaciones() public{
        require(isOracle[msg.sender], "Debes ser oraculo para abrir las votaciones");
        require(!periodo_recuento, "Las votaciones finalizaron, no se puede volver a votar");
        periodo_eleccion = true;
        periodo_planificacion = false;
        periodo_recuento = false;
    }
    
    //funcion publica para otorgarle un voto a uno de los candidatos
    function votar(string memory _candidato) public{   
        require(votosPorAdress[msg.sender] == 0, "Ya ha votado");
        require(periodo_eleccion, "Las elecciones han sido finalizadas, o no han comenzado aun");
        require(mapping_candidatos[_candidato].esValor, "El candidato no existe");
        require(estaValidada[msg.sender], "Su direccion aun no ha sido validada, debe esperar la validacion antes de votar");
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
        require(isOracle[msg.sender], "Debes ser oraculo para cerrar las votaciones");
        require(periodo_eleccion, "Las elecciones ya han sido finalizadas o no han comenzado");
        periodo_eleccion = false;
        periodo_planificacion = false;
        periodo_recuento = true;
    }
    
    
    //funcion que calcula el resultado final de las votaciones
    function calcular_resultados() public{
        require(periodo_recuento, "Las votaciones siguen vigentes o no han comenzado");
        require(isOracle[msg.sender]);

        //defino un maximo para ir actualizandolo
        string memory maximo = lista_candidatos[0];
        
        //recorre todo el array de los electos, al ser limitado nos podemos permitir usar un bucle
        //la complejidad es O(n) con n la longitud del array, ya que las operaciones de consultar los valores
        //del mapping se hace en O(1) (constante)
        
        for(uint8 i=1; i<lista_candidatos.length; i++){ 
            if(mapping_candidatos[lista_candidatos[i]].votos > mapping_candidatos[maximo].votos){
                maximo = lista_candidatos[i];
                //si el actual es mayor al maximo, lo actualizo
            } 
            
            else if(mapping_candidatos[lista_candidatos[i]].votos == mapping_candidatos[maximo].votos){
                //si es igual, me fijo si el array de repetidos esta vacio
                if(votos_repetidos.length == 0){
                    votos_repetidos.push(mapping_candidatos[lista_candidatos[i]].nombre);
                    votos_repetidos.push(mapping_candidatos[maximo].nombre);
                    //si esta vacio, pongo a los nombres de los maximos parciales en el array
                    
                } else{
                    //si no esta vacio, comparo los anteriores valores con los posibles nuevos
                    if(mapping_candidatos[votos_repetidos[0]].votos == mapping_candidatos[maximo].votos){
                        votos_repetidos.push(mapping_candidatos[lista_candidatos[i]].nombre);
                        //si es igual, lo agrego.
                    } 
                    else if(mapping_candidatos[votos_repetidos[0]].votos < mapping_candidatos[maximo].votos){
                        string[] memory nuevos_repetidos;
                        votos_repetidos = nuevos_repetidos;
                        votos_repetidos.push(mapping_candidatos[maximo].nombre);
                        votos_repetidos.push(mapping_candidatos[lista_candidatos[i]].nombre);
                        //si el actual que estoy comparando es mayor al anterior de los repetidos, creo un array nuevo reemplazando el anterior y
                        //agrego el actual y el maximo (que es el anterior repetido)
                    }
                }
            }
        }
        
        //comparo el maximo con el primer el elemento de los valres repetidos, si es mayor el ganador sera ese, caso contrario habra un empate
        electo = mapping_candidatos[maximo].votos > mapping_candidatos[votos_repetidos[0]].votos ? maximo : "empate";
        
    
        //compare si el electo es empate, en ese caso la cantidad de votos de los empatados sera el primer elemtno del array de empatados, caso contrario sera la cantidad de votos del electo.
        votos_electo = keccak256(abi.encodePacked((electo))) == keccak256(abi.encodePacked(("empate"))) ? (mapping_candidatos[votos_repetidos[0]].votos) : (mapping_candidatos[electo].votos);
        
        //llamo a una funcion auxiliar para que cubra el caso de que hay un empate, y devolver el nombre de todos los ganadores
        hay_empate();
        
        //actualizo la variable a true, para que se puedan consultar los valores del ganador
        resultados = true;
    }
    
    
    function hay_empate() private{
        //en caso de empate recorro el array de los repetidos y actualizo el valor del electo 
        //con una concatenacion de los ganadores.
        //una vez mas nos podesmos llegar a permitir hacer un for, ya que va a ser acotada la cantidad de repetidos.
        //Como peor caso sera O(n), con n la cantidad de candidatos, que seria el caso en el que todos tengan 
        //la misma cantidad de votos.
        string memory espacio = " ";
        if(keccak256(abi.encodePacked((electo))) == keccak256(abi.encodePacked(("empate")))){
            electo = string(abi.encodePacked(votos_repetidos[0], espacio));
            for(uint8 i=1; i<votos_repetidos.length; i++){
                electo = string(abi.encodePacked(electo, votos_repetidos[i], espacio));
            }
        }
    }
    
    //devuelve la el valor de la variable electo, en la que se encuentra el ganador o ganadores
    function nombre_ganador() public view returns (string memory){
        require(periodo_recuento, "Las votaciones siguen vigentes o no han comenzado");
        require(resultados, "Se estan calculando los resultados todavia");
        return electo;
    }
    
    //devuelve el valor de la variable votos_electo, en el que se encuentra la cantidad de votos de electo.
    function votos_ganador() public view returns (uint){
        require(periodo_recuento, "Las votaciones siguen vigentes o no han comenzado");
        require(resultados, "Se estan calculando los resultados todavia");
        return votos_electo;
    }
    
}