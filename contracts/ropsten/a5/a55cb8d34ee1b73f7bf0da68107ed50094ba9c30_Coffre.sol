/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

pragma solidity ^0.8.2;
//import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol"; 

interface IUniswap {

  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
  function WETH() external pure returns (address);
}

contract Coffre{

  address owner =msg.sender;     
  
  IUniswap uni = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  
  address private token_address = 0x8D55238C12948d3E29Ca450654f22f1DA091C7d7; //chainlink
  
  function getPathForETHtoToken() private view returns (address[] memory) {
     address[] memory path = new address[](2);
     path[0] = uni.WETH();
     path[1] = token_address;
   return path;
   }
   
  function swapContractEthToLink() external payable {  
  uni.swapExactETHForTokens{value: msg.value}(0,getPathForETHtoToken(), owner, block.timestamp + 15);  
  }  
  }