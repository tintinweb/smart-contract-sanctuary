/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: minutes

pragma solidity >= 0.7.0 <0.8.0;

contract escribirEnLaBlockchain{
    
    
    string texto;
    
    function escribir(string calldata _texto) public {
        texto = _texto;
    }
    
    function leer() public view returns (string memory){
        return texto;
    }
    
}