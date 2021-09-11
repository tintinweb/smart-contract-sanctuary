/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view
        returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

contract sendAndSwap{
    
    address private constant sushiSwapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 ;
    address private constant UNI = 0x71d82Eb6A5051CfF99582F4CDf2aE9cD402A4882;
    address private constant DAI = 0xc2118d4d90b274016cB7a54c03EF52E6c537D957;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    function send() external payable{
        
    }
    
    function checkBalance(address _token, address _holder) public view returns(uint) {
        IERC20 token = IERC20(_token);
        return token.balanceOf(_holder);
    }
    
    // function checkBalance() external view returns(uint){
    //     return address(this).balance;
    // }
    
    
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external {
        
        // IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        // IERC20(_tokenIn).approve(sushiSwapRouter, _amountIn);
       

        
        if(_tokenIn == UNI || _tokenIn == DAI || _tokenIn == WETH){
            
            address[] memory path;
            path = new address[](3);
            path[0] = _tokenIn ;
            path[1] = WETH ;
            path[2] = _tokenOut;
            
            IUniswapV2Router(sushiSwapRouter).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                path,
                _to,
                block.timestamp
            );
        }
        else{
            
            address[] memory path;
            path = new address[](3);
            path[0] = WETH ;
            path[2] = _tokenOut;
            
            IUniswapV2Router(sushiSwapRouter).swapExactETHForTokens(
                _amountOutMin , 
                path,
                _to,
                block.timestamp
            );
        }
        
        
    }
    
    
}