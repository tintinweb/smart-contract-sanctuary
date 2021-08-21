// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import { PokeMeReady } from "./PokeMeReady.sol";

contract Counter is PokeMeReady {
  uint256 public count;
  uint256 public lastExecuted;

  constructor(address payable _pokeMe) PokeMeReady(_pokeMe) {}

  function increaseCount(uint256 amount) external onlyPokeMe {
    require(
      ((block.timestamp - lastExecuted) > 180),
      "Counter: increaseCount: Time not elapsed"
    );

    count += amount;
    lastExecuted = block.timestamp;
  }
}