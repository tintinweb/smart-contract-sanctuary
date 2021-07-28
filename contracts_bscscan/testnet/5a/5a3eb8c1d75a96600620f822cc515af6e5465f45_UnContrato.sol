/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// SPDX-License-Identifier:  MIT 
pragma solidity >=0.7.0 <0.8.0;
contract UnContrato {
    string texto;
    
    function escribir(string calldata _texto) public {
        texto = _texto;
    }
    
    function leer() public view returns(string memory) {
        return texto;
    }
}