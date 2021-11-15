pragma solidity ^0.4.15;

import "./ERC20Token.sol";
import "./BTCPriceOracleInterface.sol";

contract EUSDToken is ERC20Token {
  BTCPriceOracleInterface priceOracle;
  string public constant symbol = "EUSD";
  string public constant name = "BIRTE";
  uint8 public constant decimals = 18;

  function EUSDToken(address btcPriceOracleAddress) {
    priceOracle = BTCPriceOracleInterface(btcPriceOracleAddress);
  }

  function donate() payable {}

  function issue() payable {
    uint amountInCents = (msg.value * priceOracle.price()) / 1;
    _totalSupply += amountInCents;
    balances[msg.sender] += amountInCents;
  }

  function getPrice() returns (uint) {
    return priceOracle.price();
  }

  function withdraw(uint amountInCents) returns (uint amountInWei){
    assert(amountInCents <= balanceOf(msg.sender));
    amountInWei = (amountInCents * 1) / priceOracle.price();

    // If we don't have enough Ether in the contract to pay out the full amount
    // pay an amount proportinal to what we have left.
    // this way user's net worth will never drop at a rate quicker than
    // the collateral itself.

    // For Example:
    // A user deposits 1 Ether when the price of Ether is $300
    // the price then falls to $150.
    // If we have enough Ether in the contract we cover ther losses
    // and pay them back 2 ether (the same amount in USD).
    // if we don't have enough money to pay them back we pay out
    // proportonailly to what we have left. In this case they'd
    // get back their original deposit of 1 Ether.
    if(this.balance <= amountInWei) {
      amountInWei = (amountInWei * this.balance * priceOracle.price()) / (1 ether * _totalSupply);
    }

    balances[msg.sender] -= amountInCents;
    _totalSupply -= amountInCents;
    msg.sender.transfer(amountInWei);
  }
}

pragma solidity ^0.4.15;

import "./ERC20Interface.sol";

contract ERC20Token is ERC20Interface {
  uint256 _totalSupply = 0;
  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;

  function totalSupply() constant returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _amount) returns (bool success) {
    if (balances[msg.sender] >= _amount 
        && _amount > 0
      && balances[_to] + _amount > balances[_to]) {
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(msg.sender, _to, _amount);
        return true;
      } else {
        return false;
      }
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) returns (bool success) {
    if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
      && _amount > 0
      && balances[_to] + _amount > balances[_to]) {
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(_from, _to, _amount);
        return true;
      } else {
        return false;
      }
  }

  function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

pragma solidity ^0.4.15;

contract BTCPriceOracleInterface {
  function price() public constant returns (uint);
}

pragma solidity ^0.4.15;

contract ERC20Interface {
  // Get the total token supply
  function totalSupply() constant returns (uint256);

  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) constant returns (uint256 balance);

  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) returns (bool success);

  // Send _value amount of tokens from address _from to address _to
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

  // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
  // If this function is called again it overwrites the current allowance with _value.
  // this function is required for some DEX functionality
  function approve(address _spender, uint256 _value) returns (bool success);

  // Returns the amount which _spender is still allowed to withdraw from _owner
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // Triggered whenever approve(address _spender, uint256 _value) is called.
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

