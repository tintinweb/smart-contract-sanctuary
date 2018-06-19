contract ERC20 {
  function transfer(address _recipient, uint256 _value) public returns (bool success);
}

contract AirdropEth {
  function drop(address[] recipients, uint256[] values) payable public {
    for (uint256 i = 0; i < recipients.length; i++) {
      recipients[i].transfer(values[i]);
    }
  }
}