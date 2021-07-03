/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2 <0.8.0;

contract lucas{
    string texto;

    function escribir(string calldata _texto) public{
        texto = _texto;
    }
    
    function leer() public view returns(string memory){
        return texto;
    }
}