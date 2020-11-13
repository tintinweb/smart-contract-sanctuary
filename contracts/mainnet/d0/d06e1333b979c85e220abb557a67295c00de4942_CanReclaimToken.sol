pragma solidity ^0.4.18;

import "./Ownable.sol";
import "./ERC20Basic.sol";
import "./SafeERC20.sol";

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }
  }