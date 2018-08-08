pragma solidity ^0.4.21;
    
   // ----------------------------------------------------------------------------------------------
   // Project Delta 
   // DELTA - New Crypto-Platform with own currency, verified semantic contracts and multi blockchains!
   // Site: http://delta.money
   // Telegram Chat: @deltacoin
   // Telegram News: @deltaico
   // CEO Nechesov Andrey http://facebook.com/Nechesov     
   // Ltd. "Delta"   
   // Tokens Delta: BUY and SELL into this smart contract on exchange
   // ----------------------------------------------------------------------------------------------
    
  library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
      uint256 c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
      return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
  }

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

  contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
  }      
   
  contract TokenBase is ERC20Interface {

      using SafeMath for uint;

      string public constant symbol = "DELTA";
      string public constant name = "DELTA token";
      uint8 public constant decimals = 18; 
           
      uint256 public constant maxTokens = (2**32-1)*10**18; 
      uint256 public constant ownerSupply = maxTokens*25/100;
      uint256 _totalSupply = ownerSupply;              

      // For future
      // If migration to a new contract is allowed
      bool public migrationAllowed = false;

      // New contract address
      address public migrationAddress;

      // How many tokens were migrated to a new contract 
      uint256 public totalMigrated = 0; 
      
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

      // Triggered orders sell/buy
      event Orders_sell(address indexed _from, address indexed _to, uint256 _amount, uint256 _price, uint256 _seller_money, uint256 _buyer_money);
   
      // Functions with this modifier can only be executed by the owner
      modifier onlyOwner() {
          if (msg.sender != owner) {
              throw;
          }
          _;
      }

      // Migrate tokens to a new contract
      function migrate(uint256 _value) external {
          require(migrationAllowed);
          require(migrationAddress != 0x0);
          require(_value > 0);
          require(_value <= balances[msg.sender]);

          balances[msg.sender] = balances[msg.sender].sub(_value);
          _totalSupply = _totalSupply.sub(_value);
          totalMigrated = totalMigrated.add(_value);

          MigrationAgent(migrationAddress).migrateFrom(msg.sender, _value);
      }  
      
      function configureMigrate(bool _migrationAllowed, address _migrationAddress) onlyOwner {
          migrationAllowed = _migrationAllowed;
          migrationAddress = _migrationAddress;
      }

  }

  contract DELTA_Token is TokenBase {

      using SafeMath for uint;

      uint256 public constant token_price = 10**18*1/100; 

      uint public pre_ico_start = 1522540800;
      uint public ico_start = 1525132800;
      uint public ico_finish = 1530403200;             

      uint public p1 = 250;             
      uint public p2 = 200;             
      uint public p3 = 150;             
      uint public p4 = 125;             
      uint public p5 = 100;

      uint public coef = 105;      
   
      // Constructor
      function DELTA_Token() {
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
      function withdraw(uint256 _amount) onlyOwner returns (bool result) {
          uint256 balance;
          balance = this.balance;
          if(_amount > 0) balance = _amount;
          owner.send(balance);
          return true;
      }

      //Change coef
      function change_coef(uint256 _coef) onlyOwner returns (bool result) {
          coef = _coef;
          return true;
      }

      function change_p1(uint256 _p1) onlyOwner returns (bool result) {
          p1 = _p1;
          return true;
      }

      function change_p2(uint256 _p2) onlyOwner returns (bool result) {
          p2 = _p2;
          return true;
      }

      function change_p3(uint256 _p3) onlyOwner returns (bool result) {
          p3 = _p3;
          return true;
      }

      function change_p4(uint256 _p4) onlyOwner returns (bool result) {
          p4 = _p4;
          return true;
      }

      function change_p5(uint256 _p5) onlyOwner returns (bool result) {
          p5 = _p5;
          return true;
      }

      //Change pre_ico_start date
      function change_pre_ico_start(uint256 _pre_ico_start) onlyOwner returns (bool result) {
          pre_ico_start = _pre_ico_start;
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

      /**
      * Buy tokens on pre-ico and ico 
      */
      function tokens_buy() payable returns (bool) { 

        uint tnow = now;        
        
        require(tnow <= ico_finish);
        require(_totalSupply < maxTokens);
        require(msg.value >= token_price);        

        uint tokens_buy = msg.value*10**18/token_price;

        require(tokens_buy > 0);   
        
        if(tnow < ico_start + 86400*0){          
          tokens_buy = tokens_buy*p1/100;
        } 
        if((ico_start + 86400*0 <= tnow)&&(tnow < ico_start + 86400*2)){
          tokens_buy = tokens_buy*p2/100;
        } 
        if((ico_start + 86400*2 <= tnow)&&(tnow < ico_start + 86400*7)){
          tokens_buy = tokens_buy*p3/100;        
        } 
        if((ico_start + 86400*7 <= tnow)&&(tnow < ico_start + 86400*14)){
          tokens_buy = tokens_buy*p4/100;        
        }
        if(ico_start + 86400*14 <= tnow){
          tokens_buy = tokens_buy*p5/100;        
        }         

        require(_totalSupply.add(tokens_buy) <= maxTokens);
        _totalSupply = _totalSupply.add(tokens_buy);
        balances[msg.sender] = balances[msg.sender].add(tokens_buy);         

        return true;
      }      

      function orders_sell_total () constant returns (uint) {
        return orders_sell_list.length;
      } 

      function get_orders_sell_amount(address _from) constant returns(uint) {

        uint _amount_max = 0;

        if(!(orders_sell_amount[_from] > 0)) return _amount_max;

        if(balanceOf(_from) > 0) _amount_max = balanceOf(_from);
        if(orders_sell_amount[_from] < _amount_max) _amount_max = orders_sell_amount[_from];

        return _amount_max;
      }

      /**
      * Order Sell tokens  
      */
      function order_sell(uint256 _max_amount, uint256 _price) returns (bool) {

        require(_max_amount > 0);
        require(_price > 0);        

        orders_sell_amount[msg.sender] = _max_amount;
        orders_sell_price[msg.sender] = (_price*coef).div(100);
        orders_sell_list.push(msg.sender);        

        return true;
      }

      function order_buy(address _from, uint256 _max_price) payable returns (bool) {
        
        require(msg.value > 0);
        require(_max_price > 0);        
        require(orders_sell_amount[_from] > 0);
        require(orders_sell_price[_from] > 0); 
        require(orders_sell_price[_from] <= _max_price);

        uint _amount = (msg.value*10**18).div(orders_sell_price[_from]);
        uint _amount_from = get_orders_sell_amount(_from);

        if(_amount > _amount_from) _amount = _amount_from;        
        require(_amount > 0);        

        uint _total_money = (orders_sell_price[_from]*_amount).div(10**18);        
        require(_total_money <= msg.value);

        uint _seller_money = (_total_money*100).div(coef);
        uint _buyer_money = msg.value - _total_money;

        require(_seller_money > 0);        
        require(_seller_money + _buyer_money <= msg.value);
        
        _from.send(_seller_money);
        msg.sender.send(_buyer_money);

        orders_sell_amount[_from] -= _amount;        
        balances[_from] -= _amount;
        balances[msg.sender] += _amount; 

        Orders_sell(_from, msg.sender, _amount, orders_sell_price[_from], _seller_money, _buyer_money);

      }
      
 }