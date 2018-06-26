pragma solidity ^0.4.18;

contract Shop {
  mapping (address=>uint16) myApple;


  function buyApple() payable  external {
        myApple[msg.sender]++;
  }

  function getMyApples() view external returns(uint16) {
        return myApple[msg.sender];
  }

  function sellMyApple(uint _applePrice) payable external {
        uint refund = (myApple[msg.sender] * _applePrice);
        myApple[msg.sender] = 0;
        msg.sender.transfer(refund);
  }

  mapping (address=>uint16) myBanana;


  function buyBanana() payable  external {
        myBanana[msg.sender]++;
  }

  function getMyBananas() view external returns(uint16) {
        return myBanana[msg.sender];
  }

  function sellMyBanana(uint _bananaPrice) payable external {
        uint refund = (myBanana[msg.sender] * _bananaPrice);
        myBanana[msg.sender] = 0;
        msg.sender.transfer(refund);
  }
}