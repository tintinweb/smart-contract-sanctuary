pragma solidity ^0.4.13;
  
 // ----------------------------------------------------------------------------------------------
 // Special coin of Midnighters Club Facebook community
 // https://facebook.com/theMidnightersClub/
 // ----------------------------------------------------------------------------------------------
  
 // ERC Token Standard #20 Interface
 // https://github.com/ethereum/EIPs/issues/20
 contract ERC20 {
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
  
 contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
  
 contract MidnightCoin is ERC20, Owned {
     string public constant symbol = "MNC";
     string public constant name = "Midnight Coin";
     uint8 public constant decimals = 18;
     uint256 _totalSupply = 100000000000000000000;
     uint public constant FREEZE_PERIOD = 1 years;
     uint public crowdSaleStartTimestamp;
     string public lastLoveLetter = "";
     
     // Balances for each account
     mapping(address => uint256) balances;
  
     // Owner of account approves the transfer of an amount to another account
     mapping(address => mapping (address => uint256)) allowed;
     

     // Constructor
     function MidnightCoin() {
         owner = msg.sender;
         balances[owner] = 1000000000000000000;
         crowdSaleStartTimestamp = now + 7 days;
     }
  
     function totalSupply() constant returns (uint256 totalSupply) {
         totalSupply = _totalSupply;
     }
  
     // What is the balance of a particular account?
     function balanceOf(address _owner) constant returns (uint256 balance) {
         return balances[_owner];
     }
  
     // Transfer the balance from owner&#39;s account to another account
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
  
     // Send _value amount of tokens from address _from to address _to
     // The transferFrom method is used for a withdraw workflow, allowing contracts to send
     // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
     // fees in sub-currencies; the command should fail unless the _from account has
     // deliberately authorized the sender of the message via some mechanism; we propose
     // these standardized APIs for approval:
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
  
     // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     // If this function is called again it overwrites the current allowance with _value.
     function approve(address _spender, uint256 _amount) returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }
     
     // features
     
     function kill() onlyOwner {
        selfdestruct(owner);
     }

     function withdraw() public onlyOwner {
        require( _totalSupply == 0 );
        owner.transfer(this.balance);
     }
  
     function buyMNC(string _loveletter) payable{
        require (now > crowdSaleStartTimestamp);
        require( _totalSupply >= msg.value);
        balances[msg.sender] += msg.value;
        _totalSupply -= msg.value;
        lastLoveLetter = _loveletter;
     }
     
     function sellMNC(uint256 _amount) {
        require (now > crowdSaleStartTimestamp + FREEZE_PERIOD);
        require( balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        _totalSupply += _amount;
        msg.sender.transfer(_amount);
     }
     
     function() payable{
        buyMNC("Hi! I am anonymous holder");
     }
     
 }