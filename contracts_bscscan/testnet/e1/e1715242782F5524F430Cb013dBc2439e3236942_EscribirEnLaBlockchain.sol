/**
 *Submitted for verification at BscScan.com on 2021-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.8.0;

contract EscribirEnLaBlockchain{
    string texto;
    
    // calldata significa que es una variable y proviene de una función.
    // Visibilidad... en este caso public
    function Escribir(string calldata _texto) public {
        texto = _texto;
    }
    
    // view solo es de lectura, retorno y que esta en memoria...
    function Leer() public view returns (string memory){
        return texto;
    }
}