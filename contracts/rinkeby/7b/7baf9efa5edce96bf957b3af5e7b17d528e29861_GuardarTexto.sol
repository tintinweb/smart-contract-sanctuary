/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract GuardarTexto {

    string texto;

    function guardar(string calldata _texto) public {
        texto= _texto;
    }

    function recibir() public view returns (string memory){
        return texto;
    }
}