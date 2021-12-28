/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FlashloanArb {
    address arbOwner;
    address constant quickswap = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address constant sushiswap = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    constructor() payable {
        //arbOwner = msg.sender;
    }

    function getPrice() external {
        uint quickRet;
        uint sushiRet;

        address[] memory wmatic_usdc = new address[](2);
        //address[2] wmatic_usdc = [0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174];
        //address[2] usdc_wmatic = [0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270];
        //address[] memory usdc_wmatic = new address[](2);
        uint amount = 1000000000000000000000;
        wmatic_usdc[0] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        wmatic_usdc[1] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        //usdc_wmatic[0] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        //usdc_wmatic[1] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

        quickRet = Iquickswap(quickswap).getAmountsOut(amount, wmatic_usdc)[1];

        wmatic_usdc[1] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        wmatic_usdc[0] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        sushiRet = Isushiswap(sushiswap).getAmountsOut(quickRet, wmatic_usdc)[1];

        //require(sushiRet > amount, "f");
        if (sushiRet > amount) {
            sushiRet = 0;
        }
    }
/*
    modifier onlyOwner () {
        require(msg.sender == arbOwner, "owner");
        _;
    }
*/
/*
    //token0 wmatic - token1 stable
    //IUniswapV2Factory(factory).getPair(token0, token1)
    function getArb(address token0, address token1, uint256 amount0, uint256 amount1, address pairAddress) external onlyOwner {
        IquickswapPair(pairAddress).swap(amount0, amount1, address(this), bytes("empty"));
    }

    function uniswapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        address[] memory path = new address[](2);
        //uint256 amountToken = _amount0 == 0 ? _amount1 : _amount0;
        uint256 amountToken = _amount1;
        address token0 = IquickswapPair(msg.sender).token0();
        address token1 = IquickswapPair(msg.sender).token1();

        path[0] = token0;
        path[1] = token1;
        uint256 amountRequired = Iquickswap(quickswap).getAmountsIn(amountToken, path)[0];

        path[0] = token1;
        path[1] = token0;
        IERC20(token1).approve(sushiswap, amountToken);
        uint256 amountReceivedtoken0 = Isushiswap(sushiswap).swapExactTokensForTokens(amountToken, 0, path, address(this), block.timestamp)[1];

        IERC20(token0).transfer(msg.sender, amountRequired);
        //IERC20(token0).transfer(tx.origin, amountReceivedtoken0 - amountRequired);
    }
*/
/*
    function getPrice(address from, address[] memory _tokens, uint[] memory _amount) public view returns(uint[5][5] memory, uint[5][5] memory) {
        uint[5][5] memory Qret;
        uint[5][5] memory Sret;
        uint[] memory quickRet;
        uint[] memory sushiRet;
        address[] memory path = new address[](2);
        
        for (uint t = 0; t < _tokens.length; t++) {
            for (uint a = 0; a < _amount.length; a++) {
                
                path[0] = from;
                path[1] = _tokens[t];
                quickRet = Iquickswap(quickswap).getAmountsOut(_amount[a], path);
                
                path[0] = _tokens[t];
                path[1] = from;
                sushiRet = Isushiswap(sushiswap).getAmountsOut(quickRet[1], path);
                
                Qret[t][a] = quickRet[1];
                Sret[t][a] = sushiRet[1];
                
            }
        }
        return (Qret, Sret);
    }
*/
/*
    function transferAnyERC20Token(address tokenAddress, uint256 amount) public onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(msg.sender, amount);
    }
    
    function transferAnyETH(uint256 amount) public onlyOwner {
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "failed to send ether");
    }
*/
/*
    function get() public view returns(uint[] memory) {
        uint[] memory quickRet;
        address[] memory path = new address[](2);
        
        path[0] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        path[1] = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

        quickRet = Iquickswap(quickswap).getAmountsOut(10000000000000000000, path);
        
        return quickRet;

    }
*/
}

interface Iquickswap {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
    
interface Isushiswap {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}
/*
interface IquickswapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}
*/
interface IERC20 {
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
}