pragma solidity ^0.4.24;

contract Token {
 
  function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
  function transfer(address to, uint256 tokens) public returns (bool success);

}

contract Test {
 
   address token_address = 0x6eacf7590c3842AF65cC718Ea9e87406B5F6Db7D;
 
  function sendTokens() public {
    Token(token_address).transfer(msg.sender,300);
  }      
    
}