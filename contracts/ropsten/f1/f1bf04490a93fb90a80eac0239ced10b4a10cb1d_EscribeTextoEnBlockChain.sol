/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract EscribeTextoEnBlockChain{
    string  texto;
    
    function Escribir(string calldata _texto) public{
        texto = _texto;
    }    
    
    function Leer() public view returns(string memory){
        return texto;
    }
}