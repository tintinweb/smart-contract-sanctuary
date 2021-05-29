/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract EscribirEnLaBlockchain{
    
    string texto; 
    
    //calldata significa que es una variable que proviene de una funcion
    
    function Escribir(string calldata _texto) public{
        
        texto = _texto; 
        
        
    }
    
    //Una variable view significa que no vaa modificar nada, sino que es solamente para ver. 
    
    function Leer() public view returns(string memory){
        
        return texto; 
    }
    
    
    
}