/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

pragma solidity ^0.5.17;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 





contract DCTFactory {
    using SafeMath for uint;
    
   constructor()public{
       last_block = block.number;
   }
    
    uint public cash = 1e6;
    uint public borrow = 1e6;


    uint public constant_y = 50000;
    uint public constant_k = 120000;
    uint public utilization;
    
    
    uint public last_block;
    uint public proof;
    uint public year = 2102400;
    
   
    
    
    
    function mint_block()public {
        proof = block.number.sub(last_block);
        last_block = block.number;
        last_utilization();
    }
    
    
    function last_utilization()public {
        utilization = uint(1e6).mul(borrow).div(borrow.add(cash));
    }
    
    
    function last_borrows()public{
        uint credit = constant_y.add(utilization.mul(constant_k).div(1e6));
        uint a = borrow.mul(credit).mul(proof).div(year).div(1e6);
        borrow = borrow.add(a);
    }
    
    
    
   
    
    
    
}