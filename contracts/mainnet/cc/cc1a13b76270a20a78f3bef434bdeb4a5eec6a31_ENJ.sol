pragma solidity ^0.4.13;

contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract ENJ {
  mapping (address => uint256) public balances;
  mapping (address => uint256) public balances_for_refund;
  bool public bought_tokens;
  bool public token_set;
  uint256 public contract_eth_value;
  uint256 public refund_contract_eth_value;
  uint256 public refund_eth_value;
  bool public kill_switch;
  bytes32 password_hash = 0x8bf0720c6e610aace867eba51b03ab8ca908b665898b10faddc95a96e829539d;
  address public developer = 0x859271eF2F73A447a1EfD7F95037017667c9d326;
  address public sale = 0xc4740f71323129669424d1Ae06c42AEE99da30e2;
  ERC20 public token;
  uint256 public eth_minimum = 3235 ether;

  function set_token(address _token) {
    require(msg.sender == developer);
    token = ERC20(_token);
    token_set = true;
  }
  
  function personal_withdraw(uint256 transfer_amount){
      require(msg.sender == developer);
      developer.transfer(transfer_amount);
  }

  function withdraw_token(address _token){
    ERC20 myToken = ERC20(_token);
    if (balances[msg.sender] == 0) return;
    require(msg.sender != sale);
    if (!bought_tokens) {
      uint256 eth_to_withdraw = balances[msg.sender];
      balances[msg.sender] = 0;
      msg.sender.transfer(eth_to_withdraw);
    }
    else {
      uint256 contract_token_balance = myToken.balanceOf(address(this));
      require(contract_token_balance != 0);
      uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
      contract_eth_value -= balances[msg.sender];
      balances[msg.sender] = 0;
      uint256 fee = tokens_to_withdraw / 100;
      require(myToken.transfer(developer, fee));
      require(myToken.transfer(msg.sender, tokens_to_withdraw - fee));
    }
  }

  // This handles the withdrawal of refunds. Also works with partial refunds.
  function withdraw_refund(){
    require(refund_eth_value!=0);
    require(balances_for_refund[msg.sender] != 0);
    uint256 eth_to_withdraw = (balances_for_refund[msg.sender] * refund_eth_value) / refund_contract_eth_value;
    refund_contract_eth_value -= balances_for_refund[msg.sender];
    refund_eth_value -= eth_to_withdraw;
    balances_for_refund[msg.sender] = 0;
    msg.sender.transfer(eth_to_withdraw);
  }

  function () payable {
    if (!bought_tokens) {
      balances[msg.sender] += msg.value;
      balances_for_refund[msg.sender] += msg.value;
      if (this.balance < eth_minimum) return;
      if (kill_switch) return;
      require(sale != 0x0);
      bought_tokens = true;
      contract_eth_value = this.balance;
      refund_contract_eth_value = this.balance;
      require(sale.call.value(contract_eth_value)());
      require(this.balance==0);
    } else {

      require(msg.sender == sale);
      refund_eth_value += msg.value;
    }
  }
}