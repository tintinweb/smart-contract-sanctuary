pragma solidity ^0.4.0;

contract CrowdSale {
  mapping (address => uint256) balances;
  mapping (address => uint) reward;
  address client;
  uint TotalToken = 10000;
  uint tokenPrice = 1000000000000000000;

  modifier isOwner() {
    if(client != msg.sender){
      return;
    }
    else{
      _;
    }
  }

  function () {
    return;
  }

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event TokenPurchased(address indexed owner, uint _amt, string indexed msg);
  event TokenTransfered(address indexed _from, address indexed _to, uint _amt, string indexed msg);
  event BalanceDeposited(address indexed _to, uint _amt, string indexed msg);

  function CrowdSale() {
    client = msg.sender;
    balances[msg.sender] += 500;
  }

  function DepositBalance() payable{
    uint _amt = msg.value;
    if(_amt > 0){
      balances[msg.sender] += _amt;
      BalanceDeposited(msg.sender, msg.value, "Balance Deposited");
    }
  }

  function TokenLeft() constant isOwner returns (uint){
    return TotalToken;
  }

  function BuyToken(uint _amt) {
    uint total = tokenPrice * _amt;
    if(balances[msg.sender] >= total && _amt > 0 && TotalToken >= _amt) {
      balances[client] += total;
      balances[msg.sender] -= total;
      reward[msg.sender] += _amt;
      TotalToken -= _amt;
      TokenPurchased(msg.sender, _amt, "Token Purchased.");
    }
  }

  function TransferToken(address _to, uint _amt){
    if(reward[msg.sender] >= _amt){
      reward[msg.sender] -= _amt;
      reward[_to] += _amt;
      TokenTransfered(msg.sender, _to, _amt, "Token Transfered.");
    }
  }

  function ViewToken() constant returns (uint) {
    return reward[msg.sender];
  }

  function transfer(address _to, uint _value) {
    if(balances[msg.sender] >= _value && _value > 0){
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(client, _to, _value);
    }
  }

  function addValue(address _to, uint _value) isOwner{
    balances[_to] += _value;
  }

  function balanceOf() constant returns (uint amount){
    return balances[msg.sender];
  }
 }