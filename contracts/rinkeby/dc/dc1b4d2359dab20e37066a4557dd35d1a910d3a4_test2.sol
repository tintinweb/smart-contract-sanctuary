/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity ^0.5.17;

contract test2{
    
    
    uint public last_block;
    uint public proof;
    
    uint year = 2102400;
    uint public borrows;
    uint public cash;
    
    
    constructor()public {
        last_block = block.number;
    }
    
    
    
    function deposit(uint amount)public {
        cash = cash + amount;
        mint();
    }
    
    
    function borrow(uint amount)public {
        cash = cash - amount;
        borrows = borrows + amount;
        mint();
    }
    
    
    
    
    
    
    function mint()public {
        set_block();
        borrows = borrows+((borrows*50/1000)*proof/year);
    }
    
    
    function set_block()private {
        proof = block.number - last_block;    
    }
    
    
    
    
    
}