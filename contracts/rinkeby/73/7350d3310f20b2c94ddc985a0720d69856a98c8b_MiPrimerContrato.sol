/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-Licensse-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract MiPrimerContrato
{
    string textoenlablockchain;
    
    function guardar(string calldata texto) public
    {
        textoenlablockchain= texto;
    }
    
    
    function leer() public view returns (string memory)
    {
     return textoenlablockchain;   
    }
    
    
}