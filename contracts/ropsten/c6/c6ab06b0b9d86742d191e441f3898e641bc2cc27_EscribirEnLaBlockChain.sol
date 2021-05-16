/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract EscribirEnLaBlockChain{
    string texto;
    
    //caldata pide una variable como entrada
    function Escribir(string calldata _texto) public{
        texto = _texto;
    }
    
    //view es solo una funcion de lectura
    function Leer() public view returns(string memory){
        return texto;
    }
}