/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.4;

contract EscribirEnLaBlockchain {
    string texto;
    
    
    function Escribir(string calldata _texto) public {
        texto = _texto;
    }
    
    function Leer() public view returns (string memory) {
        return texto;
    }
}