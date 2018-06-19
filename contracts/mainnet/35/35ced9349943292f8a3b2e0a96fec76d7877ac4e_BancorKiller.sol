pragma solidity ^0.4.23;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

}

contract Token {
 
  function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

  function transfer(address to, uint256 tokens) public returns (bool success);
     
}

contract BancorKillerContract { 

  using SafeMath for uint256;


  address public admin;

  address public base_token;

  address public traded_token;

  
  uint256 public base_token_seed_amount;

  uint256 public traded_token_seed_amount;
  
  uint256 public commission_ratio;


  bool public base_token_is_seeded;

  bool public traded_token_is_seeded;
  

  mapping (address => uint256) public token_balance;

  constructor(address _base_token, address _traded_token,uint256 _base_token_seed_amount, uint256 _traded_token_seed_amount, uint256 _commission_ratio) public {
      
    admin = tx.origin;  
      
    base_token = _base_token;
    
    traded_token = _traded_token;
    
    base_token_seed_amount = _base_token_seed_amount;
    
    traded_token_seed_amount = _traded_token_seed_amount;

    commission_ratio = _commission_ratio;
    
  }
  
  function transferTokensThroughProxyToContract(address _from, address _to, uint256 _amount) private {

    token_balance[traded_token] = token_balance[traded_token].add(_amount);

    require(Token(traded_token).transferFrom(_from,_to,_amount));
     
  }  

  function transferTokensFromContract(address _to, uint256 _amount) private {

    token_balance[traded_token] = token_balance[traded_token].sub(_amount);

    require(Token(traded_token).transfer(_to,_amount));
     
  }

  function transferETHToContract() private {

    token_balance[0] = token_balance[0].add(msg.value);
      
  }
  
  function transferETHFromContract(address _to, uint256 _amount) private {

    token_balance[0] = token_balance[0].sub(_amount);
      
    _to.transfer(_amount);
      
  }
  
  function deposit_token(uint256 _amount) private { 

    transferTokensThroughProxyToContract(msg.sender, this, _amount);

  }  

  function deposit_eth() private { 

    transferETHToContract();

  }  
  
  function withdraw_token(uint256 _amount) public {

      require(msg.sender == admin);
      
      uint256 currentBalance_ = token_balance[traded_token];
      
      require(currentBalance_ >= _amount);
      
      transferTokensFromContract(admin, _amount);
      
  }
  
  function withdraw_eth(uint256 _amount) public {
      
      require(msg.sender == admin);

      uint256 currentBalance_ = token_balance[0];
      
      require(currentBalance_ >= _amount);
      
      transferETHFromContract(admin, _amount);
      
  }

  function set_traded_token_as_seeded() private {
   
    traded_token_is_seeded = true;
 
  }

  function set_base_token_as_seeded() private {

    base_token_is_seeded = true;

  }

  function seed_traded_token() public {

    require(!market_is_open());
  
    set_traded_token_as_seeded();

    deposit_token(traded_token_seed_amount); 

  }
  
  function seed_base_token() public payable {

    require(!market_is_open());

    require(msg.value == base_token_seed_amount);
 
    set_base_token_as_seeded();

    deposit_eth(); 

  }

  function market_is_open() private view returns(bool) {
  
    return (base_token_is_seeded && traded_token_is_seeded);

  }

  function get_amount_sell(uint256 _amount) public view returns(uint256) {
 
    uint256 base_token_balance_ = token_balance[base_token]; 

    uint256 traded_token_balance_ = token_balance[traded_token];

    uint256 traded_token_balance_plus_amount_ = traded_token_balance_ + _amount;
    
    return (2*base_token_balance_*_amount)/(traded_token_balance_ + traded_token_balance_plus_amount_);
    
  }

  function get_amount_buy(uint256 _amount) public view returns(uint256) {
 
    uint256 base_token_balance_ = token_balance[base_token]; 

    uint256 traded_token_balance_ = token_balance[traded_token];

    uint256 base_token_balance_plus_amount_ = base_token_balance_ + _amount;
    
    return (_amount*traded_token_balance_*(base_token_balance_plus_amount_ + base_token_balance_))/(2*base_token_balance_plus_amount_*base_token_balance_);
   
  }
  
  function get_amount_minus_fee(uint256 _amount) private view returns(uint256) {
      
    return (_amount*(1 ether - commission_ratio))/(1 ether);  
    
  }

  function complete_sell_exchange(uint256 _amount_give) private {

    uint256 amount_get_ = get_amount_sell(_amount_give);

    require(amount_get_ < token_balance[base_token]);
    
    uint256 amount_get_minus_fee_ = get_amount_minus_fee(amount_get_);
    
    uint256 admin_fee = amount_get_ - amount_get_minus_fee_;

    transferTokensThroughProxyToContract(msg.sender,this,_amount_give);

    transferETHFromContract(msg.sender,amount_get_minus_fee_);  
    
    transferETHFromContract(admin, admin_fee);     
      
  }
  
  function complete_buy_exchange() private {

    uint256 amount_give_ = msg.value;

    uint256 amount_get_ = get_amount_buy(amount_give_);

    require(amount_get_ < token_balance[traded_token]);
    
    uint256 amount_get_minus_fee_ = get_amount_minus_fee(amount_get_);

    uint256 admin_fee = amount_get_ - amount_get_minus_fee_;
    
    transferETHToContract();

    transferTokensFromContract(msg.sender, amount_get_minus_fee_);
    
    transferTokensFromContract(admin, admin_fee);
    
  }
  
  function sell_tokens(uint256 _amount_give) public {

    require(market_is_open());

    complete_sell_exchange(_amount_give);

  }
  
  function buy_tokens() private {

    require(market_is_open());

    complete_buy_exchange();

  }

  function() public payable {

    buy_tokens();

  }

}

contract BancorKiller { 

  function create_a_new_market(address _base_token, address _traded_token, uint _base_token_seed_amount, uint _traded_token_seed_amount, uint _commission_ratio) public {

    new BancorKillerContract(_base_token, _traded_token, _base_token_seed_amount, _traded_token_seed_amount, _commission_ratio);

  }
  
  function() public payable {

    revert();

  }

}