/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
// import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol"; 

interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
}

contract bnbSwap{

  address owner =msg.sender;     
  
  IUniswapV2Router02 uniswap = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
  
  address private token_address = 0xe7473653259AecaFBC3af3DB5a2AcfF2c717b619; 
  address private constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  uint public amount = 1000000000000000;
  
//   function getPathForETHtoToken() private view returns (address[] memory) {
//      address[] memory path = new address[](2);
//      path[0] = uni.WETH();
//      path[1] = token_address;
//   return path;
//   }
   
//   function swapContractEthToLink() public {  
//   uni.swapExactETHForTokens(0,getPathForETHtoToken(), owner, block.timestamp + 15);  
//   }  
    

    fallback() external payable {
        require(msg.value == amount);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token_address;
    
        uniswap.swapExactETHForTokens{value: msg.value}(0,path,address(this),block.timestamp+15);
    }
}