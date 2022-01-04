// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./IGatherToken.sol";
import "./IUniswapV2Router02.sol";

contract WithdrawLP {
  IUniswapV2Router02 public constant uniswapRouterV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  IERC20 public constant lpToken = IERC20(0xb38bE7fD90669abCDfb314dBDDF6143AA88D3110);
  IGatherToken public constant gatherToken = IGatherToken(0xc3771d47E2Ab5A519E2917E61e23078d0C05Ed7f);
  address public constant gatherTokenController = 0x3b0C627f65ca4EEDf6f84FD6802506E710ddbe8B;
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

  function transferOwnershipOfGatherToken(address to) public onlyOwner {
    require(to != address(0));
    gatherToken.transferOwnership(to);
    require(gatherToken.owner() == to, "Failed in transferring ownership of gather token");
  }

  function withdrawToken(address tokenAddress, address to, uint256 amount) public onlyOwner returns (bool) {
    require(to != address(0));
    require(amount != 0);
    IERC20 token = IERC20(tokenAddress);
    return token.transfer(to, amount);
  }

  function withdrawLP(uint256 amount, address to) public onlyOwner returns (uint256 amountA, uint256 amountB) {
    require(to != address(0));
    require(amount != 0);
    
    // Make sure that the LP token amount is in custody before calling withdraw on router
    uint256 lpBalance = lpToken.balanceOf(address(this));
    require(lpBalance >= amount, "Insufficient balance of LP token");

    // Approve lp token to router address
    lpToken.approve(address(uniswapRouterV2), amount);

    // Unpause gather token
    gatherToken.unpauseTransfer();

    // withdraw LP
    address GTH = address(gatherToken);
    address WETH = uniswapRouterV2.WETH();
    (amountA, amountB) = uniswapRouterV2.removeLiquidity(
      GTH,
      WETH,
      amount,
      0,
      0,
      to,
      block.timestamp
    );

    // Paurse gather token
    gatherToken.pauseTransfer();

    // return ownership to old gather token controller
    transferOwnershipOfGatherToken(gatherTokenController);
  }
}