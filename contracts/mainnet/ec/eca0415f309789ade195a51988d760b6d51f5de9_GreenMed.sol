pragma solidity ^0.4.11;

//----------------------------------------------------------------------------------------------
// GreenMed token contract
// The MIT Licence.
//----------------------------------------------------------------------------------------------
   
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

 contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }
  
 contract GreenMed is ERC20Interface {
     string public constant symbol = "GRMD";
     string public constant name = "GreenMed";
     uint8 public constant decimals = 18;
     uint256 _totalSupply = 100000000000000000000000000;
     
     // Owner of this contract
     address public owner;

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
  
     // Balances for each account
     mapping(address => uint256) balances;
  
     // Owner of account approves the transfer of an amount to another account
     mapping(address => mapping (address => uint256)) allowed;
  
     // Functions with this modifier can only be executed by the owner
     modifier onlyOwner() {
         if (msg.sender != owner) {
             throw;
         }
         _;
     }
  
     // Constructor
     function GreenMed() {
         owner = msg.sender;
         balances[owner] = _totalSupply;
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

     /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }
     function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable {
        uint amount = msg.value / buyPrice;                // calculates the amount
        if (balances[this] < amount) throw;               // checks if it has enough to sell
        balances[msg.sender] += amount;                   // adds the amount to buyer&#39;s balance
        balances[this] -= amount;                         // subtracts amount from seller&#39;s balance
        Transfer(this, msg.sender, amount);                // execute an event reflecting the change
    }

    function sell(uint256 amount) {
        if (balances[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
        balances[this] += amount;                         // adds the amount to owner&#39;s balance
        balances[msg.sender] -= amount;                   // subtracts the amount from seller&#39;s balance
        if (!msg.sender.send(amount * sellPrice)) {        // sends ether to the seller. It&#39;s important
            throw;                                         // to do this last to avoid recursion attacks
        } else {
            Transfer(msg.sender, this, amount);            // executes an event reflecting on the change
        }               
    }
 }