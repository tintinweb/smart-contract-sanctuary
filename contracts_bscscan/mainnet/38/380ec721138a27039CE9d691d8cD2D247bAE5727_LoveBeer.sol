pragma solidity ^0.8.3;

  import './AERC20.sol';

  // SPDX-License-Identifier: MIT

  contract LoveBeer is AERC20 {
    constructor() AERC20('Love Beer', 'LoveBeer') {
      _mint(msg.sender, 10000000000000000000000000000000); //suply
    }
  }