pragma solidity ^0.4.13;

// Enjin ICO group buyer
// Avtor: Janez

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract EnjinBuyer {
  mapping (address => uint256) public balances;
  mapping (address => uint256) public balances_for_refund;
  bool public bought_tokens;
  bool public token_set;
  uint256 public contract_eth_value;
  uint256 public refund_contract_eth_value;
  uint256 public refund_eth_value;
  bool public kill_switch;
  bytes32 password_hash = 0x8bf0720c6e610aace867eba51b03ab8ca908b665898b10faddc95a96e829539d;
  address public developer = 0x0639C169D9265Ca4B4DEce693764CdA8ea5F3882;
  address public sale = 0xc4740f71323129669424d1Ae06c42AEE99da30e2;
  ERC20 public token;
  uint256 public eth_minimum = 3235 ether;

  function set_token(address _token) {
    require(msg.sender == developer);
    token = ERC20(_token);
    token_set = true;
  }
  
  function activate_kill_switch(string password) {
    require(msg.sender == developer || sha3(password) == password_hash);
    kill_switch = true;
  }
  
  function personal_withdraw(){
    if (balances[msg.sender] == 0) return;
    if (!bought_tokens) {
      uint256 eth_to_withdraw = balances[msg.sender];
      balances[msg.sender] = 0;
      msg.sender.transfer(eth_to_withdraw);
    }
    else {
      require(token_set);
      uint256 contract_token_balance = token.balanceOf(address(this));
      require(contract_token_balance != 0);
      uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
      contract_eth_value -= balances[msg.sender];
      balances[msg.sender] = 0;
      uint256 fee = tokens_to_withdraw / 100;
      require(token.transfer(developer, fee));
      require(token.transfer(msg.sender, tokens_to_withdraw - fee));
    }
  }


  // Use with caution - use this withdraw function if you do not trust the
  // contract&#39;s token setting. You can only use this once, so if you
  // put in the wrong token address you will burn the Enjin on the contract.
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
      // We might be getting a full refund or partial refund if we go over the limit from Enjin&#39;s multisig wallet.
      // We have been assured by the CTO that the refund would only
      // come from the pre-sale wallet.
      require(msg.sender == sale);
      refund_eth_value += msg.value;
    }
  }
}