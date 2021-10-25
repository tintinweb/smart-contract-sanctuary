// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

contract Observable {
  int56 public tick1;
  int56 public tick2;
  address public token0;
  address public token1;

  function observe(uint32[] calldata secondsAgos)
    external
    view
    returns (int56[] memory tickCumulatives, uint160[] memory)
  {
    tickCumulatives[0] = tick1;
    tickCumulatives[1] = tick2;
  }

  function setTicks(int56 _tick1, int56 _tick2) public {
    tick1 = _tick1;
    tick2 = _tick2;
  }

  function setTokens(address _token0, address _token1) public {
    token0 = _token0;
    token1 = _token1;
  }

}