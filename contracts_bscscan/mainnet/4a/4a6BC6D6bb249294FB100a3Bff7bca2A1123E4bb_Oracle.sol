// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IPancakePair.sol";

/// @custom:security-contact [email protected]
contract Oracle {
  IPancakePair public pair;

  constructor(address _pairAddress) {
    pair = IPancakePair(_pairAddress);
  }

  function getRate(uint256 _amountToInWei) public view returns (uint256) {
    (uint112 fromReserve, uint112 toReserve, ) = pair.getReserves();
    return (_amountToInWei * toReserve) / fromReserve;
  }
}