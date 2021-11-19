/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
contract Heyworld{
    string Texto;
    function Escribir(string calldata _Texto) public {
        Texto = _Texto;
    }
    function Leer() public view returns(string memory){
        return Texto;
    }
}