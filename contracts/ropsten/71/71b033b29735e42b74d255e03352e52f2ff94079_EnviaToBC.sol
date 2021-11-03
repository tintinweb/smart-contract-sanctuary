/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: MIT 
pragma solidity >=0.7.0 < 8.0.0;
contract EnviaToBC{
    
    
    string text;
    
    function Enviar(string calldata _text)public{
        text = _text;
        
    }
    
    function recibir() public view returns(string memory){
        return text;        
    }
    
}