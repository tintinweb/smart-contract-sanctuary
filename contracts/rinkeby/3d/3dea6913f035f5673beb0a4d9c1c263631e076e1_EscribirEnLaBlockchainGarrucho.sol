/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT License

pragma solidity >=0.8.0 <0.9.0;

contract EscribirEnLaBlockchainGarrucho{
    string texto;
    
    function Escribir(string calldata _texto) public{
        texto = _texto;
    } 
    
    function Leer() public view returns(string memory){
        return texto;
    }
}