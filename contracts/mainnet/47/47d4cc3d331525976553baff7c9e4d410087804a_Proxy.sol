pragma solidity ^0.4.23;

contract Contract {
  mapping (address => uint256) public balances_bonus;
  uint256 public contract_eth_value_bonus;
}

contract ERC20 {
  function transfer(address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) public constant returns (uint256 balance);
}

contract Proxy {

  Contract contr;
  uint256 public eth_balance;
  ERC20 public token;
  mapping (address => bool) public withdrew;
  address owner;

  constructor(address _contract, address _token) {
      owner = msg.sender;
      contr = Contract(_contract);
      token = ERC20(_token);
      eth_balance = contr.contract_eth_value_bonus();
  }

  function withdraw()  {
      require(withdrew[msg.sender] == false);
      withdrew[msg.sender] = true;
      uint256 balance = contr.balances_bonus(msg.sender);
      uint256 contract_token_balance = token.balanceOf(address(this));
      uint256 tokens_to_withdraw = (balance*contract_token_balance)/eth_balance;
      eth_balance -= balance;
      require(token.transfer(msg.sender, tokens_to_withdraw));

  }

  function emergency_withdraw(address _token) {
      require(msg.sender == owner);
      require(ERC20(_token).transfer(owner, ERC20(_token).balanceOf(this)));
  }

}