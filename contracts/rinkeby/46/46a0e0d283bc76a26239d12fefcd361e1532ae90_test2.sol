/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity ^0.5.17;

contract test2{
    
    
    uint last_block;
    uint proof;
    
    constructor()public {
        last_block = block.number;
    }
    
    
    
    function set_block()public {
        proof = block.number - last_block;
    }
    
    
    
}