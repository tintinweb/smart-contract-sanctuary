/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.6.99 <0.9.1;
contract EscribirEnLaBlockchainIsaias{
    string texto;
    
    function Escribir(string calldata _texto) public {
        texto = _texto;
    }
    function Leer() public view returns(string memory){
        return texto;
    }
}