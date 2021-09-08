/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.7.0;


contract Contract {
    
    function t1(uint tokenReserveAfter, uint112 tp1_reserve0, uint112 tp1_reserve1) public pure returns (uint) {
        uint amountInWithFee = (tokenReserveAfter - tp1_reserve0)  * 9970;
        uint numerator = amountInWithFee* tp1_reserve1;
        uint denominator = tp1_reserve0 * 10000 + amountInWithFee;
        return numerator / denominator;
    }

    function t2(uint tokenReserveAfter, uint tp1_reserve0, uint tp1_reserve1) public view returns (uint) {
        uint amountInWithFee = (tokenReserveAfter - tp1_reserve0)  * 9970;
        uint numerator = amountInWithFee* tp1_reserve1;
        uint denominator = tp1_reserve0 * 10000 + amountInWithFee;
        return numerator / denominator;
    }
    
    function t3(uint balance0, uint balance1) public view returns (bool) {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Pancake: OVERFLOW');
        return true;
    }
}