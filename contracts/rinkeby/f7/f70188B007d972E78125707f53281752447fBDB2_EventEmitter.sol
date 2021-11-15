// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract EventEmitter {
  constructor() {
  }

  uint256 constant MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  uint256 constant EVENT_TOPIC = 0x57050ab73f6b9ebdd9f76b8d4997793f48cf956e965ee070551b9ca0bb71584e;
  event Event();

  function create(uint256 number) public {
    while (number != 0) {
      emit Event();
      unchecked {
        number--;
      }
    }
  }

  function createEfficient(uint256 n) public {
    assembly {
      for { } gt(n, 0) { } {
        log1(0,0,EVENT_TOPIC)
        n := add(n, MAX_UINT256)
      }
    }
  }
}

