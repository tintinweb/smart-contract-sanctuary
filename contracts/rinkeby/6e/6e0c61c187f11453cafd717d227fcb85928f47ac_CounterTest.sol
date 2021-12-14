/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;


abstract contract Owner {
  address payable public immutable pokeMe;

  constructor(address payable _pokeMe) {
    pokeMe = _pokeMe;
  }

  modifier onlyOwner() {
    require(msg.sender == pokeMe, "Owner: onlyOwner");
    _;
  }
}

contract CounterTest is Owner {
  uint256 public count;
  uint256 public lastExecuted;

  constructor(address payable _pokeMe) Owner(_pokeMe) {}

  function increaseCount(uint256 amount) external onlyOwner {
    require(
      ((block.timestamp - lastExecuted) > 10),
      "Counter: increaseCount: Time not elapsed"
    );

    count += amount;
    lastExecuted = block.timestamp;
  }
}