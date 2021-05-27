/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract Escribir2{
    string texto;
    
    function PrimerSCJordiIsaias(string calldata _texto) public{
        texto = _texto;
    }
    function Leer() public view returns (string memory){
        return texto;
    }
}