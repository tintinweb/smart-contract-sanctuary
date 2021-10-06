/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: MTI

pragma solidity >=0.7.0 <0.8.0;

contract HolaMundo{
    string texto;
    
    function Escribir(string calldata _texto) public{
        texto = _texto;
    }
    
    function Leer() public view returns(string memory){
        return texto;
    }
}