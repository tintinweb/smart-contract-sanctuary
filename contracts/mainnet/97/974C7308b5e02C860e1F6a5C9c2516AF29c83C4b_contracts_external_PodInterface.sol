pragma solidity ^0.6.12;

interface PodInterface {
  function tokenToCollateralValue(uint256 tokens) external view returns (uint256);
  function balanceOfUnderlying(address user) external view returns (uint256);
}