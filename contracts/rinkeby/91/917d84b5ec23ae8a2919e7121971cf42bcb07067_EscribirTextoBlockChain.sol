/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract EscribirTextoBlockChain{
    string sTexto;
    
    function Escribir(string calldata _inTexto) public{
        sTexto = _inTexto;
    }
    
    function Leer() public view returns(string memory){
        
        return sTexto;
    }
}