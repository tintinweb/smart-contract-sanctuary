/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 <0.8.0;

contract Escribir{

    string texto;

    function setTexto(string calldata _textoP) public {
        texto = _textoP;
    }

    function getTexto() public view returns (string memory){
        return texto;
    }
    

}