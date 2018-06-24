pragma solidity ^0.4.23;

library SafeMath {

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

contract TokenLiquidityContract { 

  using SafeMath for uint256;  


  address public admin;

  address public traded_token;

  
  uint256 public eth_seed_amount;

  uint256 public traded_token_seed_amount;
  
  uint256 public commission_ratio;

  uint256 public eth_balance;

  uint256 public traded_token_balance;


  bool public eth_is_seeded;

  bool public traded_token_is_seeded;
  
  bool public trading_deactivated;

  bool public admin_commission_activated;


  modifier only_admin() {
      require(msg.sender == admin);
      _;
  }
  
  modifier trading_activated() {
      require(trading_deactivated == false);
      _;
  }

  
  constructor(address _traded_token,uint256 _eth_seed_amount, uint256 _traded_token_seed_amount, uint256 _commission_ratio) public {
      
    admin = tx.origin;  
    
    traded_token = _traded_token;
    
    eth_seed_amount = _eth_seed_amount;
    
    traded_token_seed_amount = _traded_token_seed_amount;

    commission_ratio = _commission_ratio;
    
  }
  
  function transferTokensThroughProxyToContract(address _from, address _to, uint256 _amount) private {

    traded_token_balance = traded_token_balance.add(_amount);

    require(Token(traded_token).transferFrom(_from,_to,_amount));
     
  }  

  function transferTokensFromContract(address _to, uint256 _amount) private {

    traded_token_balance = traded_token_balance.sub(_amount);

    require(Token(traded_token).transfer(_to,_amount));
     
  }

  function transferETHToContract() private {

    eth_balance = eth_balance.add(msg.value);
      
  }
  
  function transferETHFromContract(address _to, uint256 _amount) private {

    eth_balance = eth_balance.sub(_amount);
      
    _to.transfer(_amount);
      
  }
  
  function deposit_token(uint256 _amount) private { 

    transferTokensThroughProxyToContract(msg.sender, this, _amount);

  }  

  function deposit_eth() private { 

    transferETHToContract();

  }  
  
  function withdraw_token(uint256 _amount) public only_admin {

    transferTokensFromContract(admin, _amount);
      
  }
  
  function withdraw_eth(uint256 _amount) public only_admin {
      
    transferETHFromContract(admin, _amount);
      
  }

  function set_traded_token_as_seeded() private {
   
    traded_token_is_seeded = true;
 
  }

  function set_eth_as_seeded() private {

    eth_is_seeded = true;

  }

  function seed_traded_token() public only_admin {

    require(!traded_token_is_seeded);
  
    set_traded_token_as_seeded();

    deposit_token(traded_token_seed_amount); 

  }
  
  function seed_eth() public payable only_admin {

    require(!eth_is_seeded);

    require(msg.value == eth_seed_amount);
 
    set_eth_as_seeded();

    deposit_eth(); 

  }

  function seed_additional_token(uint256 _amount) public only_admin {

    require(market_is_open());
    
    deposit_token(_amount);

  }

  function seed_additional_eth() public payable only_admin {
  
    require(market_is_open());
    
    deposit_eth();

  }

  function market_is_open() private view returns(bool) {
  
    return (eth_is_seeded && traded_token_is_seeded);

  }

  function deactivate_trading() public only_admin {
  
    require(!trading_deactivated);
    
    trading_deactivated = true;

  }
  
  function reactivate_trading() public only_admin {
      
    require(trading_deactivated);
    
    trading_deactivated = false;
    
  }

  function get_amount_sell(uint256 _amount) public view returns(uint256) {
 
    uint256 traded_token_balance_plus_amount_ = traded_token_balance.add(_amount);
    
    return (2*eth_balance*_amount)/(traded_token_balance + traded_token_balance_plus_amount_);
    
  }

  function get_amount_buy(uint256 _amount) public view returns(uint256) {

    uint256 eth_balance_plus_amount_ = eth_balance + _amount;
    
    return (_amount*traded_token_balance*(eth_balance_plus_amount_ + eth_balance))/(2*eth_balance_plus_amount_*eth_balance);
   
  }
  
  function get_amount_minus_commission(uint256 _amount) private view returns(uint256) {
      
    return (_amount*(1 ether - commission_ratio))/(1 ether);  
    
  }

  function activate_admin_commission() public only_admin {

    require(!admin_commission_activated);

    admin_commission_activated = true;

  }

  function deactivate_admin_comission() public only_admin {

    require(admin_commission_activated);

    admin_commission_activated = false;

  }

  function change_admin_commission(uint256 _new_commission_ratio) public only_admin {
  
     require(_new_commission_ratio != commission_ratio);

     commission_ratio = _new_commission_ratio;

  }


  function complete_sell_exchange(uint256 _amount_give) private {

    uint256 amount_get_ = get_amount_sell(_amount_give);

    uint256 amount_get_minus_commission_ = get_amount_minus_commission(amount_get_);
    
    transferTokensThroughProxyToContract(msg.sender,this,_amount_give);

    transferETHFromContract(msg.sender,amount_get_minus_commission_);  

    if(admin_commission_activated) {

      uint256 admin_commission_ = amount_get_ - amount_get_minus_commission_;

      transferETHFromContract(admin, admin_commission_);     

    }
    
  }
  
  function complete_buy_exchange() private {

    uint256 amount_give_ = msg.value;

    uint256 amount_get_ = get_amount_buy(amount_give_);

    uint256 amount_get_minus_commission_ = get_amount_minus_commission(amount_get_);

    transferETHToContract();

    transferTokensFromContract(msg.sender, amount_get_minus_commission_);

    if(admin_commission_activated) {

      uint256 admin_commission_ = amount_get_ - amount_get_minus_commission_;

      transferTokensFromContract(admin, admin_commission_);

    }
    
  }
  
  function sell_tokens(uint256 _amount_give) public trading_activated {

    require(market_is_open());

    complete_sell_exchange(_amount_give);

  }
  
  function buy_tokens() private trading_activated {

    require(market_is_open());

    complete_buy_exchange();

  }


  function() public payable {

    buy_tokens();

  }

}

contract TokenLiquidity { 

  function create_a_new_market(address _traded_token, uint256 _base_token_seed_amount, uint256 _traded_token_seed_amount, uint256 _commission_ratio) public {

    new TokenLiquidityContract(_traded_token, _base_token_seed_amount, _traded_token_seed_amount, _commission_ratio);

  }
  
  function() public payable {

    revert();

  }

}