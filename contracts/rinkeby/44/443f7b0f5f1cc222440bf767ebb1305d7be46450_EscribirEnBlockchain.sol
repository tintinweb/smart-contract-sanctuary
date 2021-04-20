/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

contract EscribirEnBlockchain {
    
    string texto;
    
    function escribir(string calldata _texto) public {
        
        texto = _texto;
        
    }
    
    function leer() public view returns(string memory) {
        
        return texto;
        
    }
    
}