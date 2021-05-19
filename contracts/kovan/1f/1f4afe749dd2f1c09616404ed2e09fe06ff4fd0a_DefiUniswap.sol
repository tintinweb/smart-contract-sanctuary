/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IUniswap {
    function swapExactTokensForETH ( uint  amountIn , uint  amountOutMin , address [] calldata  path , address  to , uint  deadline )
        external
        returns (uint[] memory amounts);

    function WETH () external  pure  returns ( address );
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract DefiUniswap {
    IUniswap public uniswap;

    // get uniswap contract
    constructor(address _uniswap) {
        uniswap = IUniswap(_uniswap);
    }

    // get the address of token you want. => e.g. stable coin 
    function swapTokensForETH(
        address _token, // token address
        uint amountIn, // amount of token you will spend
        uint amountOut,// amount of token you will be received
        uint deadline  // timestamp when swap will be terminate
    ) external {
        require(_token != address(0x0), 'Error, token is not valid');
        IERC20 token = IERC20(_token);
        // send token to this contract
        require(token.transferFrom(msg.sender, address(this), amountIn), 'Error, token spending issue');
        // send token to the uniswap
        require(token.approve(address(this), amountIn), 'Error, refused');
        // swap tokens in uniswap via contract
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = uniswap.WETH();
        uniswap.swapExactTokensForETH(amountIn, amountOut, path, msg.sender, deadline);
        // send out token to user
    }
}