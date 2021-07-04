/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

pragma solidity ^0.8.3;

interface IERC20 {
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswap {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

contract FinalDefiProject {
    IUniswap uniswap;
    IERC20 private _token;
    
    constructor(){
        uniswap = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = IERC20(0xa29cD8EcC47262073DA4B12F390CD392632e6860);
    }
    //----steps---------//
    //-----1. approve msg.sender
    //----2. approve contract
    //----3. approve uniswap
    //----4. execute transfer from
    //----5. swapTokensForEth
    
    
    function approve(address spender,uint amountIn) external {
        _token.approve(spender,amountIn);
    }
    function tansferFrom(uint amountIn) external {
        _token.transferFrom(msg.sender,address(this),amountIn);
    }
    
    function swapTokensForEth(uint amountIn, uint amountOutMin) external {
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = uniswap.WETH();
        uniswap.swapExactTokensForETH(amountIn,amountOutMin,path,msg.sender,block.timestamp+300);
    }
}