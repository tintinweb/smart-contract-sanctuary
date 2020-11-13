// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "./SingleRandomWinner.sol";
import "../../external/openzeppelin/ProxyFactory.sol";

contract SingleRandomWinnerProxyFactory is ProxyFactory {

  SingleRandomWinner public instance;

  constructor () public {
    instance = new SingleRandomWinner();
  }

  function create() external returns (SingleRandomWinner) {
    return SingleRandomWinner(deployMinimal(address(instance), ""));
  }
}