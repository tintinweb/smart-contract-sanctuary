/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity ^0.8.0;

interface IDAI {
    function balanceOf(address account) external view returns (uint256);
}
    
interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

contract MyContract {
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address internal constant DAI_CONTRACT_ADDRESS = 0x31F42841c2db5173425b5223809CF3A38FEde360;

  IUniswapV2Router02 private uniswapRouter;
  IDAI private daiContract;

  constructor() {
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    daiContract = IDAI(DAI_CONTRACT_ADDRESS);
  }
  
  function daiAmountOf(address account) external view returns (uint256) {
      return daiContract.balanceOf(account);
  }

  function swapEthForTokenWithUniswap(uint ethAmount, address tokenAddress) public {
    require(ethAmount <= address(this).balance, "Not enough Eth in contract to perform swap.");
    
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = tokenAddress;
    
    uniswapRouter.swapExactETHForTokens(0, path, address(this), block.timestamp);
  }

  function depositEth() external payable {
    // lmao. But seriously it's needed 
  }
}