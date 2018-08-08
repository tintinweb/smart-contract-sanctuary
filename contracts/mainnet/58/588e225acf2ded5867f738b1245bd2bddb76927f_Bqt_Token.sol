// ----------------------------------------------------------------------------------------------
// Developer Nechesov Andrey: Facebook.com/Nechesov   
// Enjoy. (c) PRCR.org ICO Business Platform 2017. The PRCR Licence.
// Eth address: 0x788C45Dd60aE4dBE5055b5Ac02384D5dc84677b0
// ----------------------------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20

pragma solidity ^0.4.16;    

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
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
   
  contract Bqt_Token is ERC20Interface {

      string public constant symbol = "BQT";
      string public constant name = "BQT token";
      uint8 public constant decimals = 18; 
           
      uint256 public constant maxTokens = 200*10**6*10**18; 
      uint256 public constant ownerSupply = maxTokens*51/100;
      uint256 _totalSupply = ownerSupply;  

      uint256 public constant token_price = 10**18*1/250; 
      uint256 public pre_ico_start = 1506729600;
      uint256 public ico_start = 1512691200;
      uint256 public ico_finish = 1518134400; 
      uint public constant minValuePre = 10**18*1/1000000; 
      uint public constant minValue = 10**18*1/1000000; 
      uint public constant maxValue = 3000*10**18;

      uint8 public constant exchange_coefficient = 102;

      using SafeMath for uint;
      
      // Owner of this contract
      address public owner;
   
      // Balances for each account
      mapping(address => uint256) balances;
   
      // Owner of account approves the transfer of an amount to another account
      mapping(address => mapping (address => uint256)) allowed;

      // Orders holders who wish sell tokens, save amount
      mapping(address => uint256) public orders_sell_amount;

      // Orders holders who wish sell tokens, save price
      mapping(address => uint256) public orders_sell_price;

      //orders list
      address[] public orders_sell_list;

      // Triggered on set SELL order
      event Order_sell(address indexed _owner, uint256 _max_amount, uint256 _price);      

      // Triggered on execute SELL order
      event Order_execute(address indexed _from, address indexed _to, uint256 _amount, uint256 _price);      
   
      // Functions with this modifier can only be executed by the owner
      modifier onlyOwner() {
          if (msg.sender != owner) {
              throw;
          }
          _;
      }      
   
      // Constructor
      function Bqt_Token() {
          //owner = msg.sender;
          owner = 0x2eee6534bfa5512ded7f700d8d26e88c1688c854;
          balances[owner] = ownerSupply;
      }
      
      //default function      
      function() payable {        
          tokens_buy();        
      }
      
      function totalSupply() constant returns (uint256 totalSupply) {
          totalSupply = _totalSupply;
      }

      //Withdraw money from contract balance to owner
      function withdraw(uint256 _amount) onlyOwner returns (bool result) {
          uint256 balance;
          balance = this.balance;
          if(_amount > 0) balance = _amount;
          owner.send(balance);
          return true;
      }

      //Change ico_start date
      function change_ico_start(uint256 _ico_start) onlyOwner returns (bool result) {
          ico_start = _ico_start;
          return true;
      }

      //Change ico_finish date
      function change_ico_finish(uint256 _ico_finish) onlyOwner returns (bool result) {
          ico_finish = _ico_finish;
          return true;
      }
   
      // Total tokens on user address
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
    
     //Return param, how many tokens can send _spender from _owner account  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     } 

      /**
      * Buy tokens on pre-ico and ico with bonuses on time boundaries
      */
      function tokens_buy() payable returns (bool) { 

        uint256 tnow = now;
        
        //if(tnow < pre_ico_start) throw;
        if(tnow > ico_finish) throw;
        if(_totalSupply >= maxTokens) throw;
        if(!(msg.value >= token_price)) throw;
        if(!(msg.value >= minValue)) throw;
        if(msg.value > maxValue) throw;

        uint tokens_buy = (msg.value*10**18).div(token_price);
        uint tokens_buy_total;

        if(!(tokens_buy > 0)) throw;   
        
        //Bonus for total tokens amount for all contract
        uint b1 = 0;
        //Time bonus on Pre-ICO && ICO
        uint b2 = 0;
        //Individual bonus for tokens amount
        uint b3 = 0;

        if(_totalSupply <= 5*10**6*10**18) {
          b1 = tokens_buy*30/100;
        }
        if((5*10**6*10**18 < _totalSupply)&&(_totalSupply <= 10*10**6*10**18)) {
          b1 = tokens_buy*25/100;
        }
        if((10*10**6*10**18 < _totalSupply)&&(_totalSupply <= 15*10**6*10**18)) {
          b1 = tokens_buy*20/100;
        }
        if((15*10**6*10**18 < _totalSupply)&&(_totalSupply <= 20*10**6*10**18)) {
          b1 = tokens_buy*15/100;
        }
        if((20*10**6*10**18 < _totalSupply)&&(_totalSupply <= 25*10**6*10**18)) {
          b1 = tokens_buy*10/100;
        }
        if(25*10**6*10**18 <= _totalSupply) {
          b1 = tokens_buy*5/100;
        }        

        if(tnow < ico_start) {
          b2 = tokens_buy*50/100;
        }
        if((ico_start + 86400*0 <= tnow)&&(tnow < ico_start + 86400*5)){
          b2 = tokens_buy*10/100;
        } 
        if((ico_start + 86400*5 <= tnow)&&(tnow < ico_start + 86400*10)){
          b2 = tokens_buy*8/100;        
        } 
        if((ico_start + 86400*10 <= tnow)&&(tnow < ico_start + 86400*20)){
          b2 = tokens_buy*6/100;        
        } 
        if((ico_start + 86400*20 <= tnow)&&(tnow < ico_start + 86400*30)){
          b2 = tokens_buy*4/100;        
        } 
        if(ico_start + 86400*30 <= tnow){
          b2 = tokens_buy*2/100;        
        }
        

        if((1000*10**18 <= tokens_buy)&&(5000*10**18 <= tokens_buy)) {
          b3 = tokens_buy*5/100;
        }
        if((5001*10**18 <= tokens_buy)&&(10000*10**18 < tokens_buy)) {
          b3 = tokens_buy*10/100;
        }
        if((10001*10**18 <= tokens_buy)&&(15000*10**18 < tokens_buy)) {
          b3 = tokens_buy*15/100;
        }
        if((15001*10**18 <= tokens_buy)&&(20000*10**18 < tokens_buy)) {
          b3 = tokens_buy*20/100;
        }
        if(20001*10**18 <= tokens_buy) {
          b3 = tokens_buy*25/100;
        }

        tokens_buy_total = tokens_buy.add(b1);
        tokens_buy_total = tokens_buy_total.add(b2);
        tokens_buy_total = tokens_buy_total.add(b3);        

        if(_totalSupply.add(tokens_buy_total) > maxTokens) throw;
        _totalSupply = _totalSupply.add(tokens_buy_total);
        balances[msg.sender] = balances[msg.sender].add(tokens_buy_total);         

        return true;
      }
      
      /**
      * Get total SELL orders
      */      
      function orders_sell_total () constant returns (uint256) {
        return orders_sell_list.length;
      } 

      /**
      * Get how many tokens can buy from this SELL order
      */
      function get_orders_sell_amount(address _from) constant returns(uint) {

        uint _amount_max = 0;

        if(!(orders_sell_amount[_from] > 0)) return _amount_max;

        if(balanceOf(_from) > 0) _amount_max = balanceOf(_from);
        if(orders_sell_amount[_from] < _amount_max) _amount_max = orders_sell_amount[_from];

        return _amount_max;
      }

      /**
      * User create SELL order.  
      */
      function order_sell(uint256 _max_amount, uint256 _price) returns (bool) {

        if(!(_max_amount > 0)) throw;
        if(!(_price > 0)) throw;        

        orders_sell_amount[msg.sender] = _max_amount;
        orders_sell_price[msg.sender] = (_price*exchange_coefficient).div(100);
        orders_sell_list.push(msg.sender);        

        Order_sell(msg.sender, _max_amount, orders_sell_price[msg.sender]);      

        return true;
      }

      /**
      * Order Buy tokens - it&#39;s order search sell order from user _from and if all ok, send token and money 
      */
      function order_buy(address _from, uint256 _max_price) payable returns (bool) {
        
        if(!(msg.value > 0)) throw;
        if(!(_max_price > 0)) throw;        
        if(!(orders_sell_amount[_from] > 0)) throw;
        if(!(orders_sell_price[_from] > 0)) throw; 
        if(orders_sell_price[_from] > _max_price) throw;

        uint _amount = (msg.value*10**18).div(orders_sell_price[_from]);
        uint _amount_from = get_orders_sell_amount(_from);

        if(_amount > _amount_from) _amount = _amount_from;        
        if(!(_amount > 0)) throw;        

        uint _total_money = (orders_sell_price[_from]*_amount).div(10**18);
        if(_total_money > msg.value) throw;

        uint _seller_money = (_total_money*100).div(exchange_coefficient);
        uint _buyer_money = msg.value - _total_money;

        if(_seller_money > msg.value) throw;
        if(_seller_money + _buyer_money > msg.value) throw;

        if(_seller_money > 0) _from.send(_seller_money);
        if(_buyer_money > 0) msg.sender.send(_buyer_money);

        orders_sell_amount[_from] -= _amount;        
        balances[_from] -= _amount;
        balances[msg.sender] += _amount; 

        Order_execute(_from, msg.sender, _amount, orders_sell_price[_from]);

      }
      
 }