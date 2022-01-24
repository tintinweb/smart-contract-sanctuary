/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract MiContrato{
    string texto;
    string textote;

    function Escribir(string calldata _texto) public{
        texto = _texto;
        textote = string(abi.encodePacked(_texto, "001"));
    }

    function Leer() public view returns(string memory){
        return texto;
    }

    function Leer2() public view returns(string memory){
        return textote;
    }
}