// SPDX-License-Identifier: GPL-3.0



pragma solidity ^0.8.0;



contract UniswapDai{

    address private _dai = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;
    address private _uniswap = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address private _weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    IUniswapV2Router02 ur = IUniswapV2Router02(_uniswap);
    Dai dai = Dai(_dai);
    WETH9 we = WETH9(_weth);

      address[] path1 = [_weth,_dai];
      address[] path2 = [_dai,_weth];

    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyowner{
    require(msg.sender == owner,"only for owner");
    _;
    }

    function swapExactETHForTokens(uint amountOutMin, uint deadline)
        public
        payable
        onlyowner
        returns (uint[] memory amounts){

         amounts =  ur.swapExactETHForTokens(amountOutMin,path1,owner,deadline);

    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, uint deadline)
        public
        onlyowner
        returns (uint[] memory amounts){

         amounts =  ur.swapExactTokensForETH(amountIn,amountOutMin,path2,owner,deadline);

    }






  // important to receive ETH
  receive() payable external {}
}





interface IUniswapV2Router02  {


    function factory() external pure returns (address);
  function WETH() external pure returns (address);



  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);


  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);


}

interface Dai {

    function transferFrom(address src, address dst, uint wad)
        external returns (bool);
             function balanceOf (address)
        external returns(uint);


}

interface WETH9{
    function transferFrom(address src, address dst, uint wad)
        external
        returns (bool);
          function balanceOf (address)
        external returns(uint);


}