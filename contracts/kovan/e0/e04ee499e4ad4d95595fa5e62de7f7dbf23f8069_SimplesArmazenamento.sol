/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

contract SimplesArmazenamento {
    uint numero;

    function armazena(uint numRecebido) public {
        numero = numRecebido;
    }

    function consulta() public view returns(uint){
        return numero;
    }

}