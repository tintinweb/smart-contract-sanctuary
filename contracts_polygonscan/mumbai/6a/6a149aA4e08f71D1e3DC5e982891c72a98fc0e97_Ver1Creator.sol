// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ver1 {
  address private immutable _bridge;

  constructor() {
    _bridge = msg.sender;
  }

  function bridge() public view virtual returns (address) {
      return _bridge;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ver1.sol";

contract Ver1Creator {

  mapping(uint256 => address) public getLiquidity;

  function createLiquidity(
    uint256 _num
  ) 
    public 
    returns (address liquidity)
  {
    liquidity = address(new Ver1{salt: keccak256(abi.encode(_num))}());
    getLiquidity[_num] = liquidity;

  }

  
}

