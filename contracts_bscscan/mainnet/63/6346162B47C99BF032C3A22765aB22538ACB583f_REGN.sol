// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20.sol";

contract REGN is BEP20Detailed, BEP20 {
  constructor() BEP20Detailed("REGN", "REGN", 18) {
    uint256 totalTokens = 10000000 * 10**uint256(decimals());
    _mint(msg.sender, totalTokens);
  }
  
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function Mint(uint256 amount) external onlyOwner {
    _mint(msg.sender,amount);
  }

}