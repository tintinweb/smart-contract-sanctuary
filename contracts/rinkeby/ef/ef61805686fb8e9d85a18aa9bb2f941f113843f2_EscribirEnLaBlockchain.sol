/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// SPDX-License-Identifier: MIT

// Version del compilador
pragma solidity >=0.7.0 <0.8.0;

// Contrato
contract EscribirEnLaBlockchain{
	string texto;
	
	function Escribir(string calldata _texto) public{
		texto = _texto;	
	}
	
	function Leer() public view returns(string memory){
		return texto;
	}
}