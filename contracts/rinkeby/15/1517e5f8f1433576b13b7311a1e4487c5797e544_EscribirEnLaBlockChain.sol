/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.8.0;


contract EscribirEnLaBlockChain {
    string Texto;
    
    function Escribir(string calldata _Texto) public  {Texto = _Texto;}
    
    function Leer () public view returns(string memory){return Texto;}
    
}