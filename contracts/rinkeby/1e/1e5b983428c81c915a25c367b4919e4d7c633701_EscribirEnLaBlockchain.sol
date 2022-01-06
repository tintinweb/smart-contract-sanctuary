/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract EscribirEnLaBlockchain{
    string texto;

    function Escribir(string calldata _texto) public {
        texto = _texto;

    }

    function Leer() public view returns(string memory){
        return texto;
    }

}