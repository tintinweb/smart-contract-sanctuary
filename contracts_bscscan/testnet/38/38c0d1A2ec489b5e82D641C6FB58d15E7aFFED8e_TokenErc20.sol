// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import './ERC20.sol';

contract TokenErc20 is ERC20 {
  address owner;
  uint mintRatio;

  constructor() ERC20("Test Token", "TTK") {
      owner = payable(msg.sender);
      super._mint(msg.sender, 100000000000000 * 10 ** 18);
      mintRatio = 10 ** 9;
  }

  modifier onlyOwner() {
      require(msg.sender == owner, "Only owner can make this request");
      _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
      if (newOwner != address(0)) {
        owner = newOwner;
      }
  }
  
  function deposit() external payable {
      require(msg.value > 0);
      _mint(msg.sender, mintRatio * msg.value);
  }

  function multisend(address[] memory dests, uint256 amount) public onlyOwner
      returns (uint256) {
        require(dests.length > 0, "Require at least 1 address");
        uint256 value = amount / dests.length;
        uint256 i = 0;
        while (i < dests.length) {
            transfer(dests[i], value);
            i += 1;
        }
        return(i);
  }
}