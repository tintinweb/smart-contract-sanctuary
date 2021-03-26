/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: MIT 

pragma solidity >=0.7.0 <0.8.0;

contract EscribirEnLaBlockchain{
     string Diosnoexite;
     
     function Escribir(string calldata _texto) public{
         Diosnoexite = _texto; 
     }
     
     function Leer() public view returns(string memory){
         return Diosnoexite; 
     }
}