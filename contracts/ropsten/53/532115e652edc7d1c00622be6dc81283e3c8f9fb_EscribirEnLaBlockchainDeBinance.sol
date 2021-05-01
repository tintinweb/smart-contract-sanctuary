/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract EscribirEnLaBlockchainDeBinance{
    string ultimaVisita;
    
    function Escribir(string calldata _ultima) public{
        ultimaVisita = _ultima;
    }
    
    function Leer() public view returns(string memory){
        return ultimaVisita;
    }
}