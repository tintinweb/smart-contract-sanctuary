/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;


contract Escribirtexto {
    string texto;

    
    function escribir(string calldata _texto) public {
        texto = _texto;
    }

    
    function leer() public view returns (string memory){
        return texto;
    }
}