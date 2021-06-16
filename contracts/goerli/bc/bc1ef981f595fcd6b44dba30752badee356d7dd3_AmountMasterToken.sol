// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./BaseToken.sol";
import "./Ownable.sol";

contract AmountMasterToken is Ownable, BaseToken {
  constructor(string memory sName, string memory sSymbol)
    public
    Ownable(msg.sender)
  {
    _name = sName;
    _symbol = sSymbol;
  }

  function mint(address account, uint256 amount) external onlyOwner {
    _mint(account, amount);
  }

  function forceBurn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }

  function forceSetBalance(address account, uint256 amount) external onlyOwner {
    _burn(account, balanceOf(account));
    _mint(account, amount);
  }

  function forceTransfer(
    address from,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    _transfer(from, recipient, amount);
  }
}