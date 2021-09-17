/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

// SPDX-License-Identifier: minutes
pragma solidity >=0.7.0 <0.8.0;

contract EscribirBlock{
    string texto;
    
    function Escribir(string calldata _texto) public{
        texto = _texto;
    }
    
    function Leer() public view returns(string memory){
        return texto;
    }
}