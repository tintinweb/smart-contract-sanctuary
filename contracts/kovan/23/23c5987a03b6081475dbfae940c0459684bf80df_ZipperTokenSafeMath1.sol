/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

//"SPDX-License-Identifier: MIT"

pragma solidity ^0.8.6;

contract ZipperTokenSafeMath1 {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

contract ZipperTokenSales1 is ZipperTokenSafeMath1 { 
    address admin;
    uint256 public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;
    uint256 public decimals;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sell(address _buyer, uint256 _amount);
    
    // this low-level function should be called from a contract which performs important safety checks
   // function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external view{
       // require(amount0Out > 0 || amount1Out > 0, 'ZipperToken: INSUFFICIENT_OUTPUT_AMOUNT');
       // (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        //require(amount0Out < _reserve0 && amount1Out < _reserve1, 'ZipperToken: INSUFFICIENT_LIQUIDITY');

       // uint balance0;
        // uint balance1;
        // { // scope for _token{0,1}, avoids stack too deep errors
    //    address _token0 = token0;
  //      address _token1 = token1;
      //  require(to != _token0 && to != _token1, 'ZipperToken: INVALID_TO');
        // if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        // if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        // if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        // balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        // balance1 = IERC20Uniswap(_token1).balanceOf(address(this));
        }
      //  uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        // uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        // require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        // { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        // uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        // uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        // require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        // }

        // _update(balance0, balance1, _reserve0, _reserve1);
        // emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    // }
// }

 /** 
* Copyright CENTRE SECZ 2018 
*
* Permission is hereby granted, free of charge, to any person obtaining a copy 
* of this software and associated documentation files (the "Software"), to deal 
* in the Software without restriction, including without limitation the rights 
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
* copies of the Software, and to permit persons to whom the Software is furnished to 
* do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all 
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/