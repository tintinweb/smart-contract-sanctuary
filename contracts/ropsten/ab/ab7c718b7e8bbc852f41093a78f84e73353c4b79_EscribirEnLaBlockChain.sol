/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.8.0;

contract EscribirEnLaBlockChain{
    
    string Texto;
    
    function Escribir(string calldata _texto)  public{
        Texto = _texto;
    }
    
    function    Leer() public view returns(string memory){
        return Texto;
    }
    
    
}