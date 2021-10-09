/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract EscribirEnlaBlockchain {
    
    string texto;
    
    function EscribirTexto(string calldata _texto)public{
        texto = _texto;
    }
    
    function LeerTexto()public view returns(string memory){
        return texto;
    }
    
    
}