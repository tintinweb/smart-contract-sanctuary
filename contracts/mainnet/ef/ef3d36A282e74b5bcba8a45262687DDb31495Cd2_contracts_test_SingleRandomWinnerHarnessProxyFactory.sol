pragma solidity >=0.6.0 <0.7.0;

import "./SingleRandomWinnerHarness.sol";
import "../external/openzeppelin/ProxyFactory.sol";

contract SingleRandomWinnerHarnessProxyFactory is ProxyFactory {

  SingleRandomWinnerHarness public instance;

  constructor () public {
    instance = new SingleRandomWinnerHarness();
  }

  function create() external returns (SingleRandomWinnerHarness) {
    return SingleRandomWinnerHarness(deployMinimal(address(instance), ""));
  }
}