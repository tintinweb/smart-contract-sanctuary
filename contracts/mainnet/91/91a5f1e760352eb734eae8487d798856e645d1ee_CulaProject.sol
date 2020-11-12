// SPDX-License-Identifier: MIT

pragma solidity 0.7.1;

interface IUniswapV2Router02 {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
        
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
        
    function getAmountsIn(uint amountOut, address[] memory path)
        external
        view
        returns (uint[] memory amounts);
        
    function getAmountsOut(uint amountIn, address[] memory path) 
        external 
        view 
        returns (uint[] memory amounts);
        
    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract CulaProject {
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;
    address internal constant UNISWAP_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f ;
    IUniswapV2Router02 uniswap;
    IUniswapV2Factory factory;
    
    constructor() {
        uniswap = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        factory = IUniswapV2Factory(UNISWAP_FACTORY_ADDRESS);
    }
    
    // Transfer
    function transfer(address tokenAddress, address receipment, uint tokenAmount) external {
        IERC20(tokenAddress).transferFrom(msg.sender, receipment, tokenAmount);
    }
    
    /************* Trade from Token to ETH *************/
    // Swap ERC20 token to ETH
    function tradeTokenToEth(address tokenAddress, uint amountIn, uint amountOutMin) external {
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed.');
        
        require(IERC20(tokenAddress).approve(address(uniswap), amountIn), 'approve failed.');
        
        uniswap.swapExactTokensForETH(amountIn, amountOutMin, getPathForTokenToETH(tokenAddress), msg.sender, block.timestamp);
    } 
    
    // Amount of ETH required for the amount of Tokens
    function estimateTokenToEth(address tokenAddress, uint amount) public view returns (uint[] memory) {
        return uniswap.getAmountsOut(amount, getPathForTokenToETH(tokenAddress));
    }
    
    // Path ETH to Token
    function getPathForTokenToETH(address tokenAddress) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswap.WETH();
        
        return path;
    }
    
    /************* Trade from ETH to Token *************/
    // Swap ETH to ERC20 token
    function tradeEthToToken(address tokenAddress, uint amount) external payable {
        uniswap.swapETHForExactTokens{ value: msg.value }(amount, getPathForETHtoToken(tokenAddress), msg.sender, block.timestamp);
        
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require(success, "refund failed");
    }
    
    // Amount of ETH required for the amount of Tokens
    function estimateEthToToken(address tokenAddress, uint amount) public view returns (uint[] memory) {
        return uniswap.getAmountsIn(amount, getPathForETHtoToken(tokenAddress));
    }
    
    // Path ETH to Token
    function getPathForETHtoToken(address tokenAddress) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = tokenAddress;
        
        return path;
    }
    
    /************* Create Pairs *************/
    // Register Pair to token
    function createPair(address token1, address token2) external {
        factory.createPair(token1, token2);
    }
    
    // Register Pair to ETH
    function createPair(address token1) external {
        address token2 = uniswap.WETH();
        factory.createPair(token1, token2);
    }
}