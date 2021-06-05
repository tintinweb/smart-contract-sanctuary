/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract ContratoPablo{
    string texto;
    
    function escribir(string calldata textoAEscribir) public{
        texto = textoAEscribir;
    }
    
    function leer() public view returns(string memory){
        return texto;
    }
}