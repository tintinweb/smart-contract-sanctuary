/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

contract EscribiEnBlockchain {
    
    string texto;
    
    function Escribir(string calldata _texto) public {
        
        texto = _texto;
        
    }
    
    function leer() public view returns(string memory) {
        
        return texto;
        
    }
    
    
}