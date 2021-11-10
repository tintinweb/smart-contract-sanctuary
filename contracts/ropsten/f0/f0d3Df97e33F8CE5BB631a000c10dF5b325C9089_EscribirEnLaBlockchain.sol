/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: MIT 

pragma solidity >=0.8.0 <0.9.0;

contract EscribirEnLaBlockchain{
    string texto; //vivira en la blockchain
    
    function Escribir(string calldata _texto) public{
        texto = _texto;  
    } //calldata: variable que proviene de la funcion
    
    function Leer() public view returns(string memory){
        return texto;
    } //view: solo para recuperar información
}