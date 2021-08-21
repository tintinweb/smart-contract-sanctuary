pragma solidity ^0.5.0;

import "./Exorg.sol";

contract ExorgSwap {
  string public name = "Exorg Founders Instant Exchange";
  Exorg public exorg;
  uint public rate = 17500;

  event TokensPurchased(
    address account,
    address token,
    uint amount,
    uint rate
  );

  event TokensSold(
    address account,
    address token,
    uint amount,
    uint rate
  );

  constructor(Exorg _exorg) public {
    exorg = _exorg;
  }

  function buyTokens() public payable {
    // Calculate the number of tokens to buy
    uint exorgAmount = msg.value * rate;

    // Require that EthSwap has enough tokens
    require(exorg.balanceOf(address(this)) >= exorgAmount);

    // Transfer tokens to the user
    exorg.transfer(msg.sender, exorgAmount);

    // Emit an event
    emit TokensPurchased(msg.sender, address(exorg), exorgAmount, rate);
  }

  function sellTokens(uint _amount) public {
    // User can't sell more tokens than they have
    require(exorg.balanceOf(msg.sender) >= _amount);

    // Calculate the amount of Ether to redeem
    uint bnbAmount = _amount / rate;

    // Require that EthSwap has enough Ether
    require(address(this).balance >= bnbAmount);

    // Perform sale
    exorg.transferFrom(msg.sender, address(this), _amount);
    msg.sender.transfer(bnbAmount);

    // Emit an event
    emit TokensSold(msg.sender, address(exorg), _amount, rate);
  }

}