/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0; //en que verion compila

contract EscribirEnLaBlockchain{
    string texto;
    
    function Escribir(string calldata _txt)public{
        texto = _txt;
    }
    
    function Leer()public view returns(string memory){
        return texto;
    }
}