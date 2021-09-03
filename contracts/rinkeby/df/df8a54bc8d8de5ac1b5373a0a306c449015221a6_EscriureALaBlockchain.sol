/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// SPDX-License-Identifier: MIT

pragma  solidity >=0.7.0 <0.8.0;

contract EscriureALaBlockchain{
    
    string text;
    
    function Escriure(string calldata _text) public{
        
        text= _text;
    }
    
    function Llegir() public view returns(string memory){
        
        return text;
    }
}