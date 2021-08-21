/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Router {
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts) {} 

  function getAmountsOut(
    uint amountIn, 
    address[] memory path
  )
    public
    view
    returns (uint[] memory amounts) {}

  function swapETHForExactTokens(
    uint amountOut, 
    address[] calldata path, 
    address to, 
    uint deadline
  )
  external
  payable
  returns (uint[] memory amounts){}

  function getAmountsIn(
    uint amountOut, 
    address[] memory path
  ) 
  public view returns (uint[] memory amounts){}

  function WETH() external pure returns (address){}

}

contract Contract {
    Router router = Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function purchaseTokenSet(address[] memory tokenAddresses, uint[] memory amounts) public payable returns (uint256) {

        // check if the lengths match
        require(tokenAddresses.length == amounts.length, "Arrays must have the same length.");

        // check if you have enough money to make the trade
        uint totalSpend = 0;
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        for(uint i=0;i<tokenAddresses.length;i++){
            path[1] = tokenAddresses[i];
            totalSpend += router.getAmountsIn(amounts[i], path)[0];
        }
        require(totalSpend <= msg.value, "Not enough eth provided.");
        
        // make the trades
        for(uint i=0;i<tokenAddresses.length;i++){
            path[1] = tokenAddresses[i];
            router.swapETHForExactTokens(amounts[i], path, msg.sender, block.timestamp);
        }
        
        return totalSpend;
    }

}