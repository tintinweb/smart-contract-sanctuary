/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

//SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 <0.9.0;

contract EscribirMensaje { 
string texto1;          
 function Escribir (string calldata texto2) public {
texto1 = texto2;
 }
 function Leer() public view returns (string memory)  { 
 return texto1;  
 }
}