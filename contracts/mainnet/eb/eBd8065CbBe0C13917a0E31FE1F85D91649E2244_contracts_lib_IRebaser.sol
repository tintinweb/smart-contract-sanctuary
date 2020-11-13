pragma solidity 0.5.17;

interface IRebaser {
  function registerVelocity(uint256 amount) external;
  function sEMA() external view returns (uint256); 
  function fEMA() external view returns (uint256); 
}
