/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

pragma solidity ^0.8.0;

contract AddressCompare {
    function compare(address tokenA, address tokenB)
        public
        pure
        returns (address token0)
    {
        return tokenA < tokenB ? tokenA : tokenB;
    }
}