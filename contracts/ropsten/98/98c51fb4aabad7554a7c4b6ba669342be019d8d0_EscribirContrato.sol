/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT 

pragma  solidity >=0.7.0 <0.8.8;

contract EscribirContrato {
    
    string texto;
    
    function Escribir(string calldata _texto) public {
        texto = _texto;
    }
    
    function leer() public view returns(string memory) {
        return texto;
    }
}