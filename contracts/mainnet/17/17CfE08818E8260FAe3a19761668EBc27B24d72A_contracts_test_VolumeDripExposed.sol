pragma solidity >=0.6.0 <0.7.0;

import "../drip/VolumeDrip.sol";

contract VolumeDripExposed {
  using VolumeDrip for VolumeDrip.State;

  event DripTokensBurned(address user, uint256 amount);
  event Minted(uint256 amount);
  event MintedTotalSupply(uint256 amount);

  VolumeDrip.State state;

  function setNewPeriod(uint32 periodSeconds, uint112 dripAmount, uint32 endTime) external {
    state.setNewPeriod(periodSeconds, dripAmount, endTime);
  }

  function setNextPeriod(uint32 periodSeconds, uint112 dripAmount) external {
    state.setNextPeriod(periodSeconds, dripAmount);
  }

  function drip(uint256 currentTime, uint256 maxNewTokens) external returns (uint256) {
    uint256 newTokens = state.drip(currentTime, maxNewTokens);

    emit MintedTotalSupply(newTokens);

    return newTokens;
  }

  function mint(address user, uint256 amount) external returns (uint256) {
    uint256 accrued = state.mint(user, amount);

    emit Minted(accrued);

    return accrued;
  }

  function getDrip()
    external
    view
    returns (
      uint32 periodSeconds,
      uint128 dripAmount
    )
  {
    periodSeconds = state.nextPeriodSeconds;
    dripAmount = state.nextDripAmount;
  }

  function getPeriod(uint32 period)
    external
    view
    returns (
      uint112 totalSupply,
      uint112 dripAmount,
      uint32 endTime
    )
  {
    totalSupply = state.periods[period].totalSupply;
    endTime = state.periods[period].endTime;
    dripAmount = state.periods[period].dripAmount;
  }

  function getDeposit(address user)
    external
    view
    returns (
      uint112 balance,
      uint32 period
    )
  {
    balance = state.deposits[user].balance;
    period = state.deposits[user].period;
  }

}
