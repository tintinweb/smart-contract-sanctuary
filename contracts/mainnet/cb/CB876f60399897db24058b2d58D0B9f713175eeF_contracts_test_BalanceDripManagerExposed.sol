pragma solidity >=0.6.0 <0.7.0;

import "../drip/BalanceDripManager.sol";

contract BalanceDripManagerExposed {
  using BalanceDripManager for BalanceDripManager.State;

  BalanceDripManager.State dripManager;

  function activateDrip(address measure, address dripToken, uint256 dripRatePerSecond) external {
    dripManager.activateDrip(measure, dripToken, dripRatePerSecond);
  }

  function deactivateDrip(address measure, address prevDripToken, address dripToken, uint32 currentTime, uint256 maxNewTokens) external {
    dripManager.deactivateDrip(measure, prevDripToken, dripToken, currentTime, maxNewTokens);
  }

  function isDripActive(address measure, address dripToken) external view returns (bool) {
    return dripManager.isDripActive(measure, dripToken);
  }

  function setDripRate(address measure, address dripToken, uint256 dripRatePerSecond, uint32 currentTime, uint256 maxNewTokens) external {
    dripManager.setDripRate(measure, dripToken, dripRatePerSecond, currentTime, maxNewTokens);
  }

  function getActiveBalanceDrips(address measure) external view returns (address[] memory) {
    return dripManager.getActiveBalanceDrips(measure);
  }

  function getDrip(
    address measure,
    address dripToken
  )
    external
    view
    returns (
      uint256 dripRatePerSecond,
      uint128 exchangeRateMantissa,
      uint32 timestamp
    )
  {
    BalanceDrip.State storage dripState = dripManager.getDrip(measure, dripToken);
    dripRatePerSecond = dripState.dripRatePerSecond;
    exchangeRateMantissa = dripState.exchangeRateMantissa;
    timestamp = dripState.timestamp;
  }
}
