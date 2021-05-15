/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier: MIT 
pragma solidity >=0.7.0 <0.8.0;


contract EscribirBLockchain {
  string texto;

  function escribir(string calldata _texto) public
  {
    texto= _texto;

  }

  function leer() public view returns(string memory)
  {
    return texto;
  }
  
}