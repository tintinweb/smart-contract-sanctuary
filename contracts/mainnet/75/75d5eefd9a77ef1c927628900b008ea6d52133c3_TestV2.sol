/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external view returns (address);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract TestV2 {
    
    address constant private WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant private UniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private _owner;
    mapping(address => bool) private _ownerList;
    
    constructor() {
        _owner = msg.sender;
        _ownerList[msg.sender] = true;
    }

    function testByToken(address token) external payable {
        require(_ownerList[msg.sender], "!Owner");
        require(msg.value > 0, "INSUFFICIENT_INPUT_AMOUNT");
        IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(UniswapV2Factory).getPair(WETH, token));
        address[2] memory path = [pair.token0(), pair.token1()];
        bool direction = true;
        require(path[0] != address(0) && path[1] != address(0), "!Pair");
        require(path[0] == WETH || path[1] == WETH, "!Eth Pair");
        if (path[1] == WETH) {
            direction = false;
        }
        (uint reserveIn, uint reserveOut,) = pair.getReserves();
        if (!direction) {
            uint temp = reserveIn;
            reserveIn = reserveOut;
            reserveOut = temp;
        }
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = msg.value * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        uint amountsOut = numerator / denominator;
        IWETH(WETH).deposit{value: msg.value}();
        IWETH(WETH).transfer(address(pair), msg.value);
        if (direction) {
            pair.swap(0, amountsOut, msg.sender, new bytes(0));
        } else {
            pair.swap(amountsOut, 0, msg.sender, new bytes(0));
        }
    }
    
    function newOwner(address _newOwner) external {
        require(_owner == msg.sender, "!Owner");
        _ownerList[_newOwner] = true;
    }
}