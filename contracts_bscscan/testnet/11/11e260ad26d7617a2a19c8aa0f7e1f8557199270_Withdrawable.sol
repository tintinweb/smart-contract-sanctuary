// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Ownable.sol';
import './IBEP20.sol';

contract Withdrawable is Ownable {

  receive() external payable {}

  /* ========== WITHDRAW TO OWNER ========== */

  function withdraw(uint256 amount) public onlyOwner {
    withdrawTo(owner(), amount);
  }

  function withdrawAll() public onlyOwner {
    withdrawAllTo(owner());
  }

  function withdrawTokens(address tokenContract, uint256 amount) public onlyOwner {
    withdrawTokensTo(owner(), tokenContract, amount);
  }

  function withdrawAllTokens(address tokenContract) external onlyOwner {
    withdrawAllTokensTo(owner(), tokenContract);
  }

  /* ========== WITHDRAW TO ANY ADDRESS ========== */

  function withdrawTo(address recipient, uint256 amount) public onlyOwner {
    require(recipient != address(0), 'Withdrawable: Recipient cannot be the zero address');
    require(amount != 0, 'Withdrawable: Amount cannot be zero');
    payable(recipient).transfer(amount);
  }

  function withdrawAllTo(address recipient) public onlyOwner {
    require(recipient != address(0), 'Withdrawable: Recipient cannot be the zero address');
    payable(recipient).transfer(address(this).balance);
  }

  function withdrawTokensTo(address recipient, address tokenContract, uint256 amount) public onlyOwner {
    require(recipient != address(0), 'Withdrawable: Recipient cannot be the zero address');
    require(amount != 0, 'Withdrawable: Amount cannot be zero');
    IBEP20(tokenContract).transfer(recipient, amount);
  }

  function withdrawAllTokensTo(address recipient, address tokenContract) public onlyOwner {
    require(recipient != address(0), 'Withdrawable: Recipient cannot be the zero address');
    IBEP20 token = IBEP20(tokenContract);
    uint256 amount = token.balanceOf(address(this));
    token.transfer(recipient, amount);
  }
}