contract ERC20 {
  function transfer(address _recipient, uint256 _value) public returns (bool success);
  function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
}

contract FreeEtherWallet {
  function MultiAddressSend(ERC20 token, address[] memory recipients, uint256[] memory values) public {
    for (uint256 i = 0; i < recipients.length; i++) {
      token.transferFrom(msg.sender,recipients[i], values[i]);
    }
  }
  
  function SingleAddressSend(ERC20 token, address recipient, uint256 value) public {
      token.transferFrom(msg.sender,recipient, value);
  }
}