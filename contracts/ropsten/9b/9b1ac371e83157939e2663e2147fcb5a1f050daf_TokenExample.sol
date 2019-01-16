pragma solidity ^0.4.11;

interface ERC223Token {
  function balanceOf(address addr) external returns(uint);
  function transfer(address to, uint value) external;
}


contract TokenExample {
  
  function tokenFallback(address tokenAddr, uint value) public {
    ERC223Token token = ERC223Token(tokenAddr);
    token.transfer(msg.sender, value / 2);
  }

  function tokenFallback(address tokenAddr, uint value, bytes data) public {
    tokenFallback(tokenAddr, value);
  }
  
  function getBalance(address tokenAddr) public view returns(uint) {
    ERC223Token token = ERC223Token(tokenAddr);
    return token.balanceOf(this);
  }

}