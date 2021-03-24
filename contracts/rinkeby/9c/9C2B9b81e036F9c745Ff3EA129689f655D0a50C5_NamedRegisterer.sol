/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

interface Registerer {
    function registerMe() external pure returns(string memory);
}

contract NamedRegisterer is Registerer {
    
    constructor()  {}
    
     function registerMe() override external pure returns (string memory){
        
        return "Esther Nwaka";
        
    }
}