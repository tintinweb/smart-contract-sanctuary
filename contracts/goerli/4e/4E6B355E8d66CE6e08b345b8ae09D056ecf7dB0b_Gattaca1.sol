pragma solidity =0.5.16;

import './ERC20Detailed.sol';
import './ERC20.sol';

contract Gattaca1 is ERC20 {
  constructor() ERC20(10000000000000000000) public {}

  function faucet(address to, uint amount) external {
    _mint(to, amount);
  }
}