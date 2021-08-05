/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract EscribirBlockchain{
    string text;
    
    function Escribir(string calldata _text) public{
        text = _text;
    }
    
    function Leer() public view returns(string memory){
        return text;
    }
}