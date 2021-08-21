/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

pragma solidity ^0.5.16;



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


/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
// contract InterestRateModel {
//     /// @notice Indicator that this is an InterestRateModel contract (for inspection)
//     bool public constant isInterestRateModel = true;

//     function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

//     function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);
// }


contract Compound{
    using SafeMath for uint;
    
    uint public now_block;
    
    constructor()public {
        now_block = block.number;
    }
    
      
    function get_blocknumber()public returns(uint){
        
        uint a = block.number.sub(now_block);
        now_block = block.number;
        return a;
        
    }
    
    
      
    
}