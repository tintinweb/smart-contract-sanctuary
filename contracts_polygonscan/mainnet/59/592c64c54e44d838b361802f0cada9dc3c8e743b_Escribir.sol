/**
 *Submitted for verification at polygonscan.com on 2021-11-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Escribir{

  string texto;


  function Escribe(string calldata _texto) public{

      texto = _texto;
  }

  function Leer() public view returns(string memory){

      return texto;

  }

}