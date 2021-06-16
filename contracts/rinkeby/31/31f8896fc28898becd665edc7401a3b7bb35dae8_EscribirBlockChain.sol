/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

//SPDX-License-Indentifier: UNLICENSED

pragma solidity =0.8.5;

contract EscribirBlockChain{
    string texto;

    function Escribir(string calldata _texto) public {
        texto=_texto;
    }

    function leer() public view returns(string memory) {
        return texto;
    }
}