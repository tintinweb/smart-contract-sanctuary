/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

contract MyContract {
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address internal constant DAI_ADDRESS = 0x31F42841c2db5173425b5223809CF3A38FEde360;

  IUniswapV2Router02 private uniswapRouter;

  constructor() {
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
  }

  function swapEthForTokenWithUniswap(uint ethAmount, address tokenAddress) public {
    // Verify we have enough funds
    require(ethAmount <= address(this).balance, "Not enough Eth in contract to perform swap.");

    // Build arguments for uniswap router call
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = tokenAddress;

    // Make the call and give it 15 seconds
    // Set amountOutMin to 0 but no success with larger amounts either

    uniswapRouter.swapExactETHForTokens(ethAmount, path, address(this), block.timestamp);
  }

  function depositEth() external payable {
    // Nothing to do
  }
}