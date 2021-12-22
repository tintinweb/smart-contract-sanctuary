/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT : tipo de licencia de código abierto

//Tipo de compilador ETH
pragma solidity >=0.7.0 <0.8.0;

contract EscribirEnLaBlockchain{
    string texto;

    function Escribir(string calldata _texto) public{
        texto = _texto;
    }

    function Leer()public view returns(string memory){ //view solo para recuperar datos
        return texto;
    }
}