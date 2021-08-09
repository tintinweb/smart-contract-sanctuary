//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Storage {

  address public governance;
  address public controller;

  // [whiteList]
  // An EOA can safely interact with the system no matter what.
  // If you're using Metamask, you're using an EOA.
  // Only smart contracts may be affected by this whiteList.
  //
  // Only smart contracts added to the whiteList may interact with the vaults.
  mapping (address => bool) public whiteList;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }

  // Only smart contracts will be affected by the whiteList.
  function addToWhiteList(address _target) public onlyGovernance {
    whiteList[_target] = true;
  }

  function removeFromWhiteList(address _target) public onlyGovernance {
    whiteList[_target] = false;
  }

  function checkWhitelist(address _target) public view returns (bool) {
    return whiteList[_target];
  }
}