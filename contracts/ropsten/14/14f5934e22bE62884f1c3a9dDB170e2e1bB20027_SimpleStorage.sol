/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

contract SimpleStorage {
    //variables
    address public owner;
    uint storedInt;
    string storedString;
    uint[] public arrayInt; //array de enteros. Añadir public crea un getter, de forma que no es necesario crear la funcion
    //El getter de un array debe ser llamado con un input (posicion en el array)
    
    //EVENTOS. Los eventos son atributos de una transaccion. Se usan para identificar tipos de transacciones.
    //por ejemplo, cuando se ejecute la funcion setInt, marcala con el evento setInt; y mediante un condicional reconocer
    //el tipo de evento con el fin de hacer lo que sea. una funcion se marca con un evento mediante emit y aparece en el logs
    event SetInt(uint set);
    event SetString(string set);
    event PushToArray(uint pushed);

    //MODIFICADORES. Permite modificar funciones. Hay que añadirlo en la definicion de la funcion
    modifier onlyOwner {
        require(msg.sender == owner, "No puedes porque no es tuyo el contrato");
        _;
    } //Este modificador sirve para restringir el uso de una funcion al propietario del contrato. Añadida en pushArray

    //CONSTRUCTOR. Inicialización de variables
    constructor(){
        owner = msg.sender; //address del propietario es el que inicia el constructor del contrato. 
    }

    //funciones, se indica acceso publico, view es para solo lectura (fees 0)
    //function <name>([...,<type>,<parameter de entrada>,...?]) public {}
    // las entradas de variables a funcion se indican tras el nombre de la funcion
    //las salidas deben ser indicadas mediante returns(typo de dato)
    function setInt(uint _storedInt) public {
        if(msg.sender != owner){ //si el que intenta setInt no es el propietario, revierte transaccion
        revert();
        } //revierte la transaccion
        storedInt = _storedInt;
        emit SetInt(_storedInt);
    }
    function getInt() public view returns (uint){
        return storedInt;
    }

    //para los string hay que indicar memory o storage (memoria temporal o persistente)
    function setString(string memory _storedString) public {
        //otra sintaxis para revertir transaccion es con:
        require(msg.sender == owner, "No eres el propietario"); //si no se cumple, revierte transaccion (mas usado)
        storedString = _storedString;
        emit SetString(_storedString);
    }
    function getString() public view returns (string memory){
        return storedString;
    }

    function pushArray(uint topush) public onlyOwner{
        arrayInt.push(topush); //añade int a la siguiente posicion del array
        emit PushToArray(topush);
    }
}