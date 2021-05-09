/**
 *Submitted for verification at Etherscan.io on 2021-05-09
*/

// SPDX-License-Identifier: MIT 

pragma solidity >=0.7.0 <0.8.0;

contract Prueba{
    string texto;
    
    function Escribir(string calldata _texto) public{
        texto = _texto;
    }
    
    function Leer() public view returns(string memory){
        return texto;
    }
}