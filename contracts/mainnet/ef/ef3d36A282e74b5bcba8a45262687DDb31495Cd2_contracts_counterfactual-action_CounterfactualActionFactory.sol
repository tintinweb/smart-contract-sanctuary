// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/Create2.sol";
import "./CounterfactualAction.sol";
import "../utils/MinimalProxyLibrary.sol";

contract CounterfactualActionFactory {

  CounterfactualAction public depositor;
  PrizePool public prizePool;

  function initialize(PrizePool _prizePool) external {
    require(address(_prizePool) != address(0), "CounterfactualActionFactory/prize-pool-not-zero");
    depositor = new CounterfactualAction();
    prizePool = _prizePool;
  }

  function calculateAddress(address payable user) external view returns (address) {
    return Create2.computeAddress(salt(user), keccak256(MinimalProxyLibrary.minimalProxy(address(depositor))));
  }

  function depositTo(address payable user, address token, address referrer) external {
    CounterfactualAction d = newAction(user);
    d.depositTo(user, prizePool, token, referrer);
  }

  function cancel(address payable user) external {
    CounterfactualAction d = newAction(user);
    d.cancel(user, prizePool);
  }

  function newAction(address payable user) internal returns (CounterfactualAction) {
    return CounterfactualAction(Create2.deploy(0, salt(user), MinimalProxyLibrary.minimalProxy(address(depositor))));
  }

  function salt(address payable user) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(user));
  }

  function code() external view returns (bytes memory) {
    return MinimalProxyLibrary.minimalProxy(address(depositor));
  }
}
