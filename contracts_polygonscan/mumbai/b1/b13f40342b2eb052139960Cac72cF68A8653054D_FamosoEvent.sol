// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract FamosoEvent {
    event EFMint(address indexed famosoPair, uint32 blockTimestamp, address indexed sender, uint256 amount0, uint256 amount1);
    event EFBurn(address indexed famosoPair, uint32 blockTimestamp, address indexed sender, uint256 amount, uint256 amount0, uint256 amount1);
    event EFSwap(address indexed famosoPair, uint32 blockTimestamp, address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out);
    event EFSync(address indexed famosoPair, uint32 blockTimestamp, uint112 reserve0, uint112 reserve1);
    constructor() {}
    function FMint(address sender, uint256 amount0, uint256 amount1) external {
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        emit EFMint(msg.sender, blockTimestamp, sender, amount0, amount1);
    }
    function FBurn(address sender, uint256 amount, uint256 amount0, uint256 amount1) external {
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        emit EFBurn(msg.sender, blockTimestamp, sender, amount, amount0, amount1);
    }
    function FSwap(address sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out) external {
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        emit EFSwap(msg.sender, blockTimestamp, sender, amount0In, amount1In, amount0Out, amount1Out);
    }
    function FSync(uint112 reserve0, uint112 reserve1) external {
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        emit EFSync(msg.sender, blockTimestamp, reserve0, reserve1);
    }
}