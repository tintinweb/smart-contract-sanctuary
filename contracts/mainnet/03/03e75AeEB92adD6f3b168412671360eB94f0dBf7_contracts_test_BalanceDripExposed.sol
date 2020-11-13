pragma solidity >=0.6.0 <0.7.0;

import "../drip/BalanceDrip.sol";

contract BalanceDripExposed {
  using BalanceDrip for BalanceDrip.State;

  event DrippedTotalSupply(
    uint256 newTokens
  );

  event Dripped(
    address indexed user,
    uint256 newTokens
  );

  BalanceDrip.State internal dripState;

  function setDripRate(
    uint256 dripRatePerSecond
  ) external {
    dripState.dripRatePerSecond = dripRatePerSecond;
  }

  function drip(
    uint256 measureTotalSupply,
    uint256 currentTime,
    uint256 maxNewTokens
  ) external returns (uint256) {
    uint256 newTokens = dripState.drip(
      measureTotalSupply,
      currentTime,
      maxNewTokens
    );

    emit DrippedTotalSupply(newTokens);

    return newTokens;
  }

  function captureNewTokensForUser(
    address user,
    uint256 userMeasureBalance
  ) external returns (uint128) {
    uint128 newTokens = dripState.captureNewTokensForUser(
      user,
      userMeasureBalance
    );

    emit Dripped(user, newTokens);

    return newTokens;
  }

  function dripTwice(
    uint256 measureTotalSupply,
    uint256 currentTime,
    uint256 maxNewTokens
  ) external returns (uint256) {
    uint256 newTokens = dripState.drip(
      measureTotalSupply,
      currentTime,
      maxNewTokens
    );

    newTokens = newTokens + dripState.drip(
      measureTotalSupply,
      currentTime,
      maxNewTokens
    );

    emit DrippedTotalSupply(newTokens);

    return newTokens;
  }

  function exchangeRateMantissa() external view returns (uint256) {
    return dripState.exchangeRateMantissa;
  }

  function totalDripped() external view returns (uint256) {
    return dripState.totalDripped;
  }

  function resetTotalDripped() external {
    dripState.resetTotalDripped();
  }
}
