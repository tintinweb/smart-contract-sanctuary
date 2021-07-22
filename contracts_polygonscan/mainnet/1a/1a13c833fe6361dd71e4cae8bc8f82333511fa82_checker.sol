/**
 *Submitted for verification at polygonscan.com on 2021-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IUniswapV2Router01 {
    function WETH() external pure returns (address);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
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

}

contract checker {
    
    address private _owner;
    address private WETH;
    bool public lastTrade = false;
    
    constructor(address ETH) {
        _owner = msg.sender;
        WETH = ETH;
    }
    
    fallback() external payable {}  

    function test(address[] calldata exchangesAndToken, uint256 amount) external view returns(uint256[] memory data) {
        IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(exchangesAndToken[1]);
            
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();//token we're r=trting to sell
            path[1] = exchangesAndToken[0];//// token we're trying to sell it for
            
            return uniswapV2Router.getAmountsOut(amount, path);
    }
    
    function arbitrageToken(address[] calldata exchangesAndToken, uint256 amount) external returns(uint256){
        uint256 lowestBuyingPrice;
        address lowestBuyingPriceExchange;
        
        uint256 highestSellingPrice;
        address highestSellingPriceExchange;
        
        address ETH = WETH;
        
        address[] memory path = new address[](2);
            path[0] = ETH;//token we're r=trting to sell
            path[1] = exchangesAndToken[0];//// token we're trying to sell it for
            
        for(uint256 t=1; t < exchangesAndToken.length; ++t){
            IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(exchangesAndToken[t]);
            
            uint256 buyingPrice = uniswapV2Router.getAmountsOut(amount, path)[1];
            if(buyingPrice < lowestBuyingPrice || lowestBuyingPrice == 0){lowestBuyingPrice = buyingPrice; lowestBuyingPriceExchange = exchangesAndToken[t];}
        }
        
        address[] memory path1 = new address[](2);
            path1[0] = exchangesAndToken[0];
            path1[1] = ETH;
            
        for(uint256 t=1; t < exchangesAndToken.length; ++t){
            IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(exchangesAndToken[t]);
            
            uint256 sellingPrice = uniswapV2Router.getAmountsOut(lowestBuyingPrice, path1)[1];
            
            if(sellingPrice > highestSellingPrice) {highestSellingPrice = sellingPrice; highestSellingPriceExchange = exchangesAndToken[t];}
        }
        
        if(highestSellingPrice > amount) {
            IUniswapV2Router01 buyingRouter = IUniswapV2Router01(lowestBuyingPriceExchange);
            buyingRouter.swapExactETHForTokens(address(this).balance, path, address(this), block.timestamp);
            
            IUniswapV2Router01 sellingRouter = IUniswapV2Router01(lowestBuyingPriceExchange);
            sellingRouter.swapExactTokensForETH(lowestBuyingPrice, 0, path, address(this), block.timestamp);
            
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