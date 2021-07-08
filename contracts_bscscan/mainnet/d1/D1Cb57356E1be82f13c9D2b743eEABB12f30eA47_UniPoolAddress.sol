/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity ^0.6.12;

contract UniPoolAddress {
    function pairFor(address tokenA, address tokenB) public pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5'
            ))));
    }
}