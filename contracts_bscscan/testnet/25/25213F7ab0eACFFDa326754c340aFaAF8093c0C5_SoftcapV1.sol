// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import './ISoftcap.sol';

contract SoftcapV1 is ISoftcap {

  uint256 public immutable cap = 100_000_000 ether;

  function getCap() override external pure returns(uint){
    return cap;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


interface ISoftcap {
  function getCap() external pure returns(uint);
}