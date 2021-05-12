/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

/**
 * @title Registro
 * @
 */
contract Registro {
    string public informacao;
    
    constructor(string memory _qualInformacaoRegistrar){
        informacao = _qualInformacaoRegistrar;
    }
    
    function alterarInformacao(string memory _qualInformacaoRegistrar) public{
        informacao = _qualInformacaoRegistrar;
    }
    
}