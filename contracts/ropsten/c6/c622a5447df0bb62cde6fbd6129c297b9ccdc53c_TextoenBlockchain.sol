/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

// SDPX-License-Identifier: MIT 

pragma solidity >=0.7.0 <0.8.0;

contract TextoenBlockchain{
    string texto;
    
    function escribir (string calldata _texto) public{
        texto = _texto;
    }
    
    function Leer() public view returns(string memory){
        return texto;
    }
    
}