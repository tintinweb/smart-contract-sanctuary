/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.7 < 0.9.0;

contract EscribirEnLaRedETH{
    
    string Txt;
    
    function Escribir(string calldata _Txt) public{
        
        Txt = _Txt;
    }
    
    function Leer() public view returns(string memory){
        
        return Txt;
    }
}