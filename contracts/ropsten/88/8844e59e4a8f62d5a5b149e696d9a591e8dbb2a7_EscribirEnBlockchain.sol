/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.8.8;

contract EscribirEnBlockchain{
    string texto;
    
    function Escribir(string calldata _texto) public{
        texto = _texto;
    }
    
    function Obtener() public view returns(string memory) {
        return texto;
    }
}