/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: MIT 

pragma solidity >=0.7.0 <0.9.0;

contract EscribirEnLaBlockChain{
   string texto;
   
   function Escribir(string calldata _texto) public{
       texto = _texto;
   }
   
   function Leer()  public view returns(string memory){
        return texto;   
       
   }
}