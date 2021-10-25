//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.9.0;

interface IUniswapV2Router01{
    function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB, uint liquidity);

    function swapTokensForExactTokens(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
}

interface IERC20{
     function approve(address spender, uint256 value) external returns (bool);
}


contract uniSwwap{
    
    IUniswapV2Router01 router = IUniswapV2Router01(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a);
    
    function addLiquidity(address tokenA,address tokenB,uint _amountA,uint _amountB,uint _deadline) public returns(uint A,uint B,uint LPToken){
        (uint _A,uint _B,uint _LPToken) = router.addLiquidity(tokenA, tokenB, _amountA, _amountB, 1, 1, msg.sender, _deadline);

        return (_A,_B,_LPToken);
    }

    function swapToken(address tokenIn, address tokenOut,uint _amountIn,uint minOut,address _to,uint _deadline) public returns(uint[] memory _amounts){

        IERC20(tokenIn).approve(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a, _amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        _amounts = router.swapTokensForExactTokens(_amountIn,minOut,path,_to,_deadline);
    }
}