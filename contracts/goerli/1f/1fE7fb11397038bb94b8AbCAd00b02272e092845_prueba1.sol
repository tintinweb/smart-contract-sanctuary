/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.0;



// File: prueba1.sol

contract prueba1 {
    function bar(bytes3[2] memory datos) public pure returns(bytes3, bytes3){
      return(datos[0], datos[1]);
    }


    function baz(uint32 x, bool y) public pure returns (bool r) { r = x > 32 || y; }

    function sam(bytes memory, bool, uint[] memory) public pure {}
}