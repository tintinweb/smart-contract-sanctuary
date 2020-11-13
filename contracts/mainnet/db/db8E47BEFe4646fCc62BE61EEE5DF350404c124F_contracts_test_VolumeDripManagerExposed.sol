pragma solidity >=0.6.0 <0.7.0;

import "../drip/VolumeDripManager.sol";

contract VolumeDripManagerExposed {
  using VolumeDripManager for VolumeDripManager.State;
  using VolumeDrip for VolumeDrip.State;

  VolumeDripManager.State manager;

  function activate(
    address measure,
    address dripToken,
    uint32 periodSeconds,
    uint112 dripAmount,
    uint32 endTime
  )
    external
  {
    manager.activate(measure, dripToken, periodSeconds, dripAmount, endTime);
  }

  function deactivate(
    address measure,
    address dripToken,
    address prevDripToken
  )
    external
  {
    manager.deactivate(measure, dripToken, prevDripToken);
  }

  function set(address measure, address dripToken, uint32 periodSeconds, uint112 dripAmount) external {
    manager.set(measure, dripToken, periodSeconds, dripAmount);
  }

  function isActive(address measure, address dripToken) external view returns (bool) {
    return manager.isActive(measure, dripToken);
  }

  function getPeriod(
    address measure,
    address dripToken,
    uint32 period
  )
    external
    view
    returns (
      uint112 totalSupply,
      uint112 dripAmount,
      uint32 endTime
    )
  {
    VolumeDrip.State storage drip = manager.getDrip(measure, dripToken);
    VolumeDrip.Period memory state = drip.periods[period];
    totalSupply = state.totalSupply;
    dripAmount = state.dripAmount;
    endTime = state.endTime;
  }

  function getActiveVolumeDrips(address measure) external view returns (address[] memory) {
    return manager.getActiveVolumeDrips(measure);
  }

  function getDrip(
    address measure,
    address dripToken
  )
    external
    view
    returns (
      uint32 periodSeconds,
      uint112 dripAmount
    )
  {
    VolumeDrip.State storage drip = manager.getDrip(measure, dripToken);
    dripAmount = drip.nextDripAmount;
    periodSeconds = drip.nextPeriodSeconds;
  }
}
