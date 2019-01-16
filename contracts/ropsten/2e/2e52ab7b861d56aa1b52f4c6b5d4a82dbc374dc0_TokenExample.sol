pragma solidity ^0.4.11;

interface ERC223Token {
  function balanceOf(address addr) external view returns(uint);
  function transfer(address to, uint value) external;
}


contract TokenExample {
  address public sender;
  address public msgSender;
  address public txOrigin;
  
  function tokenFallback(address _sender, uint value) public {
    ERC223Token token = ERC223Token(msg.sender);
    
    sender = _sender;
    msgSender = msg.sender;
    txOrigin = tx.origin;
    
    // token.transfer(sender, value / 2);
  }

//   function tokenFallback(address sender, uint value, bytes data) public {
//     tokenFallback(sender, value);
//   }
  
  function getBalance(address tokenAddr) public view returns(uint) {
    ERC223Token token = ERC223Token(tokenAddr);
    return token.balanceOf(this);
  }

}