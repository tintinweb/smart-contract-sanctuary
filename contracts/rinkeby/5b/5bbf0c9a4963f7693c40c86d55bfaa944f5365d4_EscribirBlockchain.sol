/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract EscribirBlockchain {
    string texto;
    
    
    function escribir(string calldata _texto) public {
        texto = _texto;
    }
    
    function leer () public view returns (string memory) {
        return texto;
    }  
}