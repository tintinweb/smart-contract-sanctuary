/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract EscribirBC {
    
    string textoBC;
    
    function guardarBC(string calldata _texto) public
    {
        textoBC= _texto;
    }
    
    function leerBC() public view returns(string memory)
    {
        return textoBC;
    }
    
}