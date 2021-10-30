/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Escribir{
    string texto;
    function escribir(string calldata _texto) public {
        texto = _texto;
    }
    
    function leer() public view returns (string memory) {
        return texto;
        
    }
}