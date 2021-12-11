// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.5.0;

import "./EpicFailGuyCoin.sol";

contract DirectSale {
  string public name = "EFGC Direct Sale";
  EpicFailGuyCoin public token;
  uint public rate = 5000;
  address owner;

  event TransferReceived(address _from, uint _amount);
  event TransferSent(address _from, address recipient, uint _amount);
  event TokensPurchased(address account, address token, uint amount,uint rate);

  constructor(EpicFailGuyCoin _token) public {
    token = _token;
    owner = msg.sender;
  }

  function buyTokens() public payable {
    // Calculate the number of tokens to buy
    uint tokenAmount = msg.value * rate;

    // Require that DirectSale has enough tokens
    require(token.balanceOf(address(this)) >= tokenAmount);

    // Transfer tokens to the user
    token.transfer(msg.sender, tokenAmount);

    // Emit an event
    emit TokensPurchased(msg.sender, address(token), tokenAmount, rate);
  }
  
  function withdraw(address payable recipient, uint amount) external {
        require(msg.sender == owner);
        require(recipient == owner);
        recipient.transfer(amount);
    } 
}