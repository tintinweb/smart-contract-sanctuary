// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IUniswapV2Router02.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
contract SampleSell is Context,ReentrancyGuard {
  IUniswapV2Router02 public uniswapV2Router;
  mapping(address => uint256) public EthBalance;
  constructor() ReentrancyGuard() {
    // Uniswap: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function SellTokens(address tokenToSend,uint256 tokenAmount) nonReentrant() public {
      uint256 currentContractBalance = address(this).balance;
      address[] memory path = new address[](2);
      path[0] = tokenToSend;
      path[1] = uniswapV2Router.WETH();
      // make the swap
      uniswapV2Router.swapExactTokensForETH(
        tokenAmount,
        0,
        path,
        address(this),
        block.timestamp
      );
      uint256 newContractBalance = address(this).balance;
      EthBalance[_msgSender()] = EthBalance[_msgSender()] + (newContractBalance - currentContractBalance);
    }
    function CollectEth() public {
      require(EthBalance[_msgSender()] > 0);
			payable(_msgSender()).transfer(EthBalance[_msgSender()]);
      EthBalance[_msgSender()] = 0;
    }
}