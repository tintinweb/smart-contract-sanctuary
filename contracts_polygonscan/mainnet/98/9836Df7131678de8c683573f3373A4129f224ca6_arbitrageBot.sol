/**
 *Submitted for verification at polygonscan.com on 2021-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IUniswapV2Router01 {
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns(bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

}

contract arbitrageBot {
    
    address private _owner;
    address private WETH;
    bool public lastTrade = false;
    
    constructor(address ETH) {
        _owner = msg.sender;
        WETH = ETH;
    }
    
    fallback() external payable {}  

    
    function buyToken(address[] calldata tokenAndExchange, uint256 amountToSpendOn) external {
        require(msg.sender == _owner);
        IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(tokenAndExchange[1]);
            
            address[] memory path = new address[](2);
            path[0] = WETH;//token we're r=trting to sell
            path[1] = tokenAndExchange[0];//// token we're trying to sell it for
            
            uniswapV2Router.swapExactETHForTokens{value: amountToSpendOn}(0, path, address(this), block.timestamp);
    }
    
    function getWETH(uint256 amount) external {
        IERC20 token = IERC20(WETH);
        token.transferFrom(msg.sender, address(this), amount);
    }
    
    function arbitrageToken(address[] calldata exchangesAndToken, uint256 amount) external{
        require(msg.sender == _owner);
        
        uint256 bestBuyAmount;
        address bestBuyExchange;
        
        uint256 bestSellAmount;
        address bestSellExchange;
        
        address ETH = WETH;
        
        address[] memory path = new address[](2);
            path[0] = ETH;//token we're r=trting to sell
            path[1] = exchangesAndToken[0];//// token we're trying to sell it for
            
        for(uint256 t=1; t < exchangesAndToken.length; ++t){
            IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(exchangesAndToken[t]);
            
            uint256 tokenAmount = uniswapV2Router.getAmountsOut(amount, path)[1];
            if(tokenAmount > bestBuyAmount){bestBuyAmount = tokenAmount; bestBuyExchange = exchangesAndToken[t];}
        }
        
        address[] memory path1 = new address[](2);
            path1[0] = exchangesAndToken[0];
            path1[1] = ETH;
            
        for(uint256 t=1; t < exchangesAndToken.length; ++t){
            IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(exchangesAndToken[t]);
            
            uint256 sellingAmount = uniswapV2Router.getAmountsOut(bestBuyAmount, path1)[1];
            
            if(sellingAmount > bestSellAmount) {bestSellAmount = sellingAmount; bestSellExchange = exchangesAndToken[t];}
        }
        
        if(bestSellAmount > amount) {
            IUniswapV2Router01 buyingRouter = IUniswapV2Router01(bestBuyExchange);
            buyingRouter.swapExactETHForTokens{value: amount}(bestBuyAmount, path, address(this), block.timestamp);
            
            IERC20 token = IERC20(exchangesAndToken[0]);
            token.approve(bestSellExchange, bestBuyAmount);
            
            IUniswapV2Router01 sellingRouter = IUniswapV2Router01(bestSellExchange);
            sellingRouter.swapExactTokensForETH(bestBuyAmount, amount, path1, address(this), block.timestamp);
            
            lastTrade = true;
        }

    }
    
    function arbitrageTokenForToken(address[] calldata exchangesAndToken, uint256 amount) external{
        require(msg.sender == _owner);
        
        //exchangesAndToken 0 the one we have
        //exchangesAndToken 1 the one we want to buy and sell
        
        uint256 bestBuyAmount;
        address bestBuyExchange;
        
        uint256 bestSellAmount;
        address bestSellExchange;
        
        address[] memory path = new address[](2);
            path[0] = exchangesAndToken[0];//token we're r=trting to sell
            path[1] = exchangesAndToken[1];//// token we're trying to sell it for
            
        for(uint256 t=2; t < exchangesAndToken.length; ++t){
            IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(exchangesAndToken[t]);
            
            uint256 tokenAmount = uniswapV2Router.getAmountsOut(amount, path)[1];
            if(tokenAmount > bestBuyAmount){bestBuyAmount = tokenAmount; bestBuyExchange = exchangesAndToken[t];}
        }
        
        address[] memory path1 = new address[](2);
            path1[0] = exchangesAndToken[1];
            path1[1] = exchangesAndToken[0];
            
        for(uint256 t=2; t < exchangesAndToken.length; ++t){
            IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(exchangesAndToken[t]);
            
            uint256 sellingAmount = uniswapV2Router.getAmountsOut(bestBuyAmount, path1)[1];
            
            if(sellingAmount > bestSellAmount) {bestSellAmount = sellingAmount; bestSellExchange = exchangesAndToken[t];}
        }
        
        if(bestSellAmount > amount) {
            
            IERC20 token = IERC20(exchangesAndToken[0]);
            token.approve(bestBuyExchange, amount);
            
            IUniswapV2Router01 buyingRouter = IUniswapV2Router01(bestBuyExchange);
            buyingRouter.swapExactTokensForTokens(amount, bestBuyAmount, path, address(this), block.timestamp);
            
            IERC20 token1 = IERC20(exchangesAndToken[1]);
            token1.approve(bestSellExchange, bestBuyAmount);
            
            IUniswapV2Router01 sellingRouter = IUniswapV2Router01(bestSellExchange);
            sellingRouter.swapExactTokensForTokens(bestBuyAmount, amount, path1, address(this), block.timestamp);
            
            lastTrade = true;
        }

    }
    
    function withdrawCoins(uint256 amount, address payable to) external {
        require(msg.sender == _owner);
        to.transfer(amount);
    }
    
    function withdrawTokens(uint256 amount, address to, address tokenAddress) external {
        require(msg.sender == _owner);
        IERC20 token = IERC20(tokenAddress);
        token.transfer(to, amount);
    }


}