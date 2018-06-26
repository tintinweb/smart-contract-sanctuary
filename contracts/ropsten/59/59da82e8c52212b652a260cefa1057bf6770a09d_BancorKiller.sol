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
  
  modifier onlyAdmin() {
      msg.sender == admin;
      _;
  }

  constructor(address _base_token, address _traded_token,uint256 _base_token_seed_amount, uint256 _traded_token_seed_amount, uint256 _commission_ratio) public {
      
    admin = tx.origin;  
      
    base_token = _base_token;
    
    traded_token = _traded_token;
    
    base_token_seed_amount = _base_token_seed_amount;
    
    traded_token_seed_amount = _traded_token_seed_amount;

    commission_ratio = _commission_ratio;
    
  }

  function transferTokensThroughProxy(address _from, address _to, uint256 _amount) private {

    require(Token(traded_token).transferFrom(_from,_to,_amount));
     
  }
  
    function transferTokens(address _to, uint256 _amount) private {

    require(Token(traded_token).transfer(_to,_amount));
     
  }

  function transferETH(address _to, uint256 _amount) private {
      
    _to.transfer(_amount);
      
  }
  
  function deposit_token(address _token, uint256 _amount) private { 

    token_balance[_token] = token_balance[_token].add(_amount);

    transferTokensThroughProxy(msg.sender, this, _amount);

  }  

  function deposit_eth() private { 

    token_balance[0] = token_balance[0].add(msg.value);

  }  
  
  function withdraw_token(uint256 _amount) onlyAdmin public {
      
      uint256 currentBalance_ = token_balance[traded_token];
      
      require(currentBalance_ >= _amount);
      
      transferTokens(msg.sender, _amount);
      
  }
  
  function withdraw_eth(uint256 _amount) onlyAdmin public {
      
      uint256 currentBalance_ = token_balance[0];
      
      require(currentBalance_ >= _amount);
      
      transferETH(msg.sender, _amount);
      
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

    deposit_token(traded_token, traded_token_seed_amount); 

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

  function calculate_price(uint256 _pre_pay_in_price,uint256 _post_pay_in_price) private pure returns(uint256) {

    return (_pre_pay_in_price.add(_post_pay_in_price)).div(2);

  }

  function get_amount_get_sell(uint256 _amount) private view returns(uint256) {
   
    uint256 traded_token_balance_ = token_balance[traded_token]*1 ether;
    
    uint256 base_token_balance_ = token_balance[base_token];    

    uint256 pre_pay_in_price_ = traded_token_balance_.div(base_token_balance_);

    uint256 post_pay_in_price_ = (traded_token_balance_.add(_amount)).div(base_token_balance_);
   
    uint256 adjusted_price_ = calculate_price(pre_pay_in_price_,post_pay_in_price_);

    return (_amount.div(adjusted_price_)).div(1 ether);   
      
  }

  function get_amount_get_buy(uint256 _amount) private view returns(uint256) {
 
    uint256 traded_token_balance_ = token_balance[traded_token]*1 ether;
    
    uint256 base_token_balance_ = token_balance[base_token];    

    uint256 pre_pay_in_price_ = traded_token_balance_.div(base_token_balance_);

    uint256 post_pay_in_price_ = traded_token_balance_.div(base_token_balance_.add(_amount));
   
    uint256 adjusted_price_ = calculate_price(pre_pay_in_price_,post_pay_in_price_);

    return (_amount.mul(adjusted_price_)).div(1 ether);
    
  }

  function complete_sell_exchange(uint256 _amount_give) private {

    uint256 amount_get_ = get_amount_get_sell(_amount_give);
    
    uint256 amount_get_minus_fee_ = (amount_get_.mul(1 ether - commission_ratio)).div(1 ether);
    
    uint256 admin_fee = amount_get_ - amount_get_minus_fee_;

    transferTokensThroughProxy(msg.sender,this,_amount_give);

    transferETH(msg.sender,amount_get_minus_fee_);  
    
    transferETH(admin, admin_fee);      
      
  }
  
  function complete_buy_exchange() private {
    
    uint256 amount_give_ = msg.value;

    uint256 amount_get_ = get_amount_get_buy(amount_give_);
    
    uint256 amount_get_minus_fee_ = (amount_get_.mul(1 ether - commission_ratio)).div(1 ether);

    uint256 admin_fee = amount_get_ - amount_get_minus_fee_;

    transferTokens(msg.sender, amount_get_minus_fee_);
    
    transferETH(admin, admin_fee);
    
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