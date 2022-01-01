/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

pragma solidity ^0.4.8;
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {
     // Get the total token supply
     function totalSupply() constant returns (uint256 totalSupply);
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

 contract ERC20 is ERC20Interface {
     string public constant symbol = "ERC20";
     string public constant name = "ERC20";
     uint8 public constant decimals = 1;
     uint256 _totalSupply = 1000000;

     address public owner;

     mapping(address => uint256) balances;

     mapping(address => mapping (address => uint256)) allowed;

     modifier onlyOwner() {
         require (msg.sender != owner);
         _;
     }

     function ERC20() {
         owner = msg.sender;
         balances[owner] = _totalSupply;
     }

     function totalSupply() constant returns (uint256 totalSupply) {
         totalSupply = _totalSupply;
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