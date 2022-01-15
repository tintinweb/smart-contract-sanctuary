/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CustomLib {
   function customSend(uint256 value, address receiver) public {}
}

contract Token {

    uint256 tokenPrice = 1;
    uint256 supply;
    address owner;
    mapping(address => uint256) balance;

    event Purchase(address buyer, uint256 amount);
    event Transfer(address sender, address receiver, uint256 amount);
    event Sell(address seller, uint256 amount);
    event Price(uint256 price);

    address customLibAddress  = 0xc0b843678E1E73c090De725Ee1Af6a9F728E2C47;

    constructor() {
        owner = msg.sender;
    }

    function willBalanceNotOverflow(address add, uint256 value) private view returns (bool) {
      return balance[add] <= balance[add] + value;
    }

    function buyToken(uint256 amount) public payable returns (bool) {
      require(msg.value >= amount * tokenPrice, "You need more weis");
      require(willBalanceNotOverflow(msg.sender, amount), "You have too much balance, please withdraw first");
      supply += amount;
      balance[msg.sender] += amount;
      emit Purchase(msg.sender, amount);
      return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
      require(balance[msg.sender] >= amount, "You don't own this many tokens");
      require(willBalanceNotOverflow(recipient, amount), "The recipient's balance is too high, please withdraw first");
      balance[msg.sender] -= amount;
      balance[recipient] += amount;
      emit Transfer(msg.sender, recipient, amount);
      return true;
    }

    function sellToken(uint256 amount) public returns (bool) {
      require(balance[msg.sender] >= amount, "You don't own this many tokens");
      supply -= amount;
      balance[msg.sender] -= amount;
      CustomLib customLib = CustomLib(customLibAddress);
      customLib.customSend(amount * tokenPrice, msg.sender);
      emit Sell(msg.sender, amount);
      return true;
    }

    function changePrice(uint256 price) public returns (bool) {
      require(msg.sender == owner, "You are not the owner");
      require(price * supply <= address(this).balance, "Not enough deposit to back up token");
      tokenPrice = price;
      emit Price(price);
      return true;
    }

    function getBalance() public view returns (uint256) {
      return balance[msg.sender];
    }
}