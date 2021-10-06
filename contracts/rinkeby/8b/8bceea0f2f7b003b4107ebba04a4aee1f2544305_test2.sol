/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity ^0.5.17;

contract test2{
    
    
    uint public last_block;
    uint public proof;
    
    uint year = 2102400;
    uint borrows = 100e6;
    
    
    constructor()public {
        last_block = block.number;
    }
    
    
    
    function mint()public {
        set_block();
        borrows = borrows+((borrows*50/1000)*proof/year);
    }
    
    
    function set_block()public {
        proof = block.number - last_block;
    }
    
    
    
}