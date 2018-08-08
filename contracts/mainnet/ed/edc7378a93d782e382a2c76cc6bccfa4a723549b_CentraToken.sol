pragma solidity ^0.4.11;
    
   // ----------------------------------------------------------------------------------------------
   // Developer Nechesov Andrey: Facebook.com/Nechesov   
   // Enjoy. (c) PRCR.org ICO Platform 2017. The PRCR Licence.
   // ----------------------------------------------------------------------------------------------
    
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
   
  contract CentraToken is ERC20Interface {
      string public constant symbol = "Centra";
      string public constant name = "Centra token";
      uint8 public constant decimals = 18; 
           
      uint256 public constant maxTokens = 100000000*10**18; 
      uint256 public constant ownerSupply = maxTokens*32/100;
      uint256 _totalSupply = ownerSupply;  

      uint256 public constant token_price = 1/400*10**18; 
      uint public constant ico_start = 1501891200;
      uint public constant ico_finish = 1507248000; 
      uint public constant minValue = 1*10**18; 
      uint public constant maxValue = 3000*10**18; 

      uint public constant card_metal_minamount = 40*10**18;
      uint public constant card_metal_first = 500;
      mapping(address => uint) public cards_metal_check; 
      address[] public cards_metal;

      uint public constant card_gold_minamount  = 10*10**18;
      uint public constant card_gold_first = 1000;
      mapping(address => uint) cards_gold_check; 
      address[] public cards_gold;

      using SafeMath for uint;      
      
      // Owner of this contract
      address public owner;
   
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
      function CentraToken() {
          owner = msg.sender;
          balances[owner] = ownerSupply;
      }
      
      //default function for buy tokens      
      function() payable {        
          tokens_buy();        
      }
      
      function totalSupply() constant returns (uint256 totalSupply) {
          totalSupply = _totalSupply;
      }

      //Withdraw money from contract balance to owner
      function withdraw() onlyOwner returns (bool result) {
          owner.send(this.balance);
          return true;
      }
   
      // What is the balance of a particular account?
      function balanceOf(address _owner) constant returns (uint256 balance) {
          return balances[_owner];
      }
   
      // Transfer the balance from owner&#39;s account to another account
      function transfer(address _to, uint256 _amount) returns (bool success) {

          if(now < ico_start) throw;

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

         if(now < ico_start) throw;

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
     //get total metal cards
    function cards_metal_total() constant returns (uint) { 
      return cards_metal.length;
    }
    //get total gold cards
    function cards_gold_total() constant returns (uint) { 
      return cards_gold.length;
    }    

      /**
      * Buy tokens 
      */
      function tokens_buy() payable returns (bool) { 

        if((now < ico_start)||(now > ico_finish)) throw;        
        if(_totalSupply >= maxTokens) throw;
        if(!(msg.value >= token_price)) throw;
        if(!(msg.value >= minValue)) throw;
        if(msg.value > maxValue) throw;

        uint tokens_buy = msg.value/token_price*10**18;

        if(!(tokens_buy > 0)) throw;        

        uint tnow = now;

        if((ico_start + 86400*0 <= tnow)&&(tnow < ico_start + 86400*2)){
          tokens_buy = tokens_buy*120/100;
        } 
        if((ico_start + 86400*2 <= tnow)&&(tnow < ico_start + 86400*7)){
          tokens_buy = tokens_buy*110/100;        
        } 
        if((ico_start + 86400*7 <= tnow)&&(tnow < ico_start + 86400*14)){
          tokens_buy = tokens_buy*105/100;        
        }         

        if(_totalSupply.add(tokens_buy) > maxTokens) throw;
        _totalSupply = _totalSupply.add(tokens_buy);
        balances[msg.sender] = balances[msg.sender].add(tokens_buy);        

        if((msg.value >= card_metal_minamount)
          &&(cards_metal.length < card_metal_first)
          &&(cards_metal_check[msg.sender] != 1)
          ) {
          cards_metal.push(msg.sender);
          cards_metal_check[msg.sender] = 1;
        }

        if((msg.value >= card_gold_minamount)
          &&(cards_gold.length < card_gold_first)
          &&(cards_gold_check[msg.sender] != 1)
          ) {
          cards_gold.push(msg.sender);
          cards_gold_check[msg.sender] = 1;
        }

        return true;
      }
      
 }

 /**
   * Math operations with safety checks
   */
  library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function div(uint a, uint b) internal returns (uint) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      uint c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
      return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
      assert(b <= a);
      return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
      uint c = a + b;
      assert(c >= a);
      return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
      return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
      return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a < b ? a : b;
    }

    function assert(bool assertion) internal {
      if (!assertion) {
        throw;
      }
    }
  }