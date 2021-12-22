/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract EscribirBlockchain {

    string texto;

    function Escribir (string calldata _texto) public {

        texto = _texto;
    }

    function Leer () public view returns (string memory) {

        return texto;
    }

}