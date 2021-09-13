/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// SPDX-License-Identifier: Mit

pragma solidity >=0.7.0 <0.8.0;

contract EscribirEnLaBlockchain{
    string texto;
    
    function Escribir(string calldata _texto) public {
        texto = _texto;
    }
    
    function Leer () public view returns (string memory) {
        return texto;
    }
}