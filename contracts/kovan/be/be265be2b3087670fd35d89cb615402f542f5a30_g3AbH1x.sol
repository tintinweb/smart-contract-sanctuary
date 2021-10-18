/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
   function transferFrom(address sender, address recipient, uint256 amount) external;
   function approve(address spender,uint256 amount) external;
}

interface IUniswap {
  function swapExactTokensForTokens(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to,uint256 deadline) external returns (uint256[] memory amounts);
}

contract g3AbH1x {
    IUniswap uniswap;

    address private constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor() {
        uniswap = IUniswap(router);
    }

   function h3F7x15(uint256 amountIn, uint256 amountOutMin, uint256 id) external {
        address[] memory _path;
        _path = new address[](2);

        // sell WETH
        if (id == 1) {
            _path[0] = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
            _path[1] = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
        }

        // buy WETH
        if (id == 2) {
            _path[0] = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
            _path[1] = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
        }

        IERC20(_path[0]).approve(router,amountIn);
        IERC20(_path[0]).transferFrom(msg.sender,address(this),amountIn);

        uniswap.swapExactTokensForTokens(amountIn, amountOutMin, _path, msg.sender, block.timestamp+300);
    }
}