/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

//Licencia
// SPDX-License-Identifier: MIT

//Version de Compilador de Ethereum a utilizar
pragma solidity >= 0.7.0 <0.8.0;

//Nombre del contrato
contract EscribirEnLaBlockchainRhemsy{
    string texto;

    function Escribir(string calldata _texto) public{
        texto = _texto;
    }

    function Leer() public view returns(string memory){
        return texto;
    }
}