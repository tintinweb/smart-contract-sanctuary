// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract FamosoEvent {
    event Mint(address indexed famosoPair, uint32 blockTimestamp, address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed famosoPair, uint32 blockTimestamp, address indexed sender, uint256 amount, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed famosoPair, uint32 blockTimestamp, address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(address indexed famosoPair, uint32 blockTimestamp, uint112 reserve0, uint112 reserve1);
    constructor() {}
}