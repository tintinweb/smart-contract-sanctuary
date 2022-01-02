// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 < 0.7.0;
//importar el archivo ERC20
import "./ERC20.sol";
// Contract es el cuerpo de tu contrato.
contract axl{

    // Sacar la direccion del despliegue (Creador del token)
    address owner;

    /* Constructor es una funcion que se usa para especificar propiedades. 
    Se invoca una sola vez.*/

    constructor() public{
        //msg.sender devuelve el remitente de la llamada.
        owner = msg.sender;

    }
    function Now() public view returns(uint){
        return now;
    }
}