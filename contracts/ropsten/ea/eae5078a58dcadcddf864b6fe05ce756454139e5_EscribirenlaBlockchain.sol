/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

//SPDX-License-Identifyer: MIT

pragma solidity >=0.8.0 <0.8.9;

contract EscribirenlaBlockchain {
    string texto;
    function Escribir(string calldata _texto) public{
        texto = _texto;
    }
    function Leer() public view returns(string memory){
        return texto;
    }
    
}