/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 <0.8.0;

contract EscribirEnBlockchain {
    string texto;
    
    function Escribir(string calldata _text) public {
        texto = _text;
    }
    
    function Leer() public view returns(string memory) {
        return texto;
    }
}