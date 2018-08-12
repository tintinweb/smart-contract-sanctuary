pragma solidity ^0.4.21;

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
}

contract Token {
  function balanceOf(address _owner) public returns (uint256); 
  function transfer(address to, uint256 tokens) public returns (bool);
  function transferFrom(address from, address to, uint256 tokens) public returns(bool);
}

contract TokenLiquidityMarket { 
    
  using SafeMath for uint256;  

  address public platform;
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
  
  function TokenLiquidityMarket(address _traded_token,uint256 _eth_seed_amount, uint256 _traded_token_seed_amount, uint256 _commission_ratio) public {
    admin = tx.origin;
    platform = msg.sender; 
    traded_token = _traded_token;
    eth_seed_amount = _eth_seed_amount;
    traded_token_seed_amount = _traded_token_seed_amount;
    commission_ratio = _commission_ratio;
  }

  function change_admin(address _newAdmin) public only_admin() {
    admin = _newAdmin;
  }
  
  function withdraw_arbitrary_token(address _token, uint256 _amount) public only_admin() {
      require(_token != traded_token);
      require(Token(_token).transfer(admin, _amount));
  }

  function withdraw_excess_tokens() public only_admin() {
    uint256 queried_traded_token_balance_ = Token(traded_token).balanceOf(this);
    require(queried_traded_token_balance_ >= traded_token_balance);
    uint256 excess_ = queried_traded_token_balance_.sub(traded_token_balance);
    require(Token(traded_token).transfer(admin, excess_));
  }

  function transfer_tokens_through_proxy_to_contract(address _from, address _to, uint256 _amount) private {
    traded_token_balance = traded_token_balance.add(_amount);
    require(Token(traded_token).transferFrom(_from,_to,_amount));
  }  

  function transfer_tokens_from_contract(address _to, uint256 _amount) private {
    traded_token_balance = traded_token_balance.sub(_amount);
    require(Token(traded_token).transfer(_to,_amount));
  }

  function transfer_eth_to_contract() private {
    eth_balance = eth_balance.add(msg.value);
  }
  
  function transfer_eth_from_contract(address _to, uint256 _amount) private {
    eth_balance = eth_balance.sub(_amount);
    _to.transfer(_amount);
  }
  
  function deposit_token(uint256 _amount) private { 
    transfer_tokens_through_proxy_to_contract(msg.sender, this, _amount);
  }  

  function deposit_eth() private { 
    transfer_eth_to_contract();
  }  
  
  function withdraw_token(uint256 _amount) public only_admin() {
    transfer_tokens_from_contract(admin, _amount);
  }
  
  function withdraw_eth(uint256 _amount) public only_admin() {
    transfer_eth_from_contract(admin, _amount);
  }

  function set_traded_token_as_seeded() private {
    traded_token_is_seeded = true;
  }

  function set_eth_as_seeded() private {
    eth_is_seeded = true;
  }

  function seed_traded_token() public only_admin() {
    require(!traded_token_is_seeded);
    set_traded_token_as_seeded();
    deposit_token(traded_token_seed_amount); 
  }
  
  function seed_eth() public payable only_admin() {
    require(!eth_is_seeded);
    require(msg.value == eth_seed_amount);
    set_eth_as_seeded();
    deposit_eth(); 
  }

  function seed_additional_token(uint256 _amount) public only_admin() {
    require(market_is_open());
    deposit_token(_amount);
  }

  function seed_additional_eth() public payable only_admin() {
    require(market_is_open());
    deposit_eth();
  }

  function market_is_open() private view returns(bool) {
    return (eth_is_seeded && traded_token_is_seeded);
  }

  function deactivate_trading() public only_admin() {
    require(!trading_deactivated);
    trading_deactivated = true;
  }
  
  function reactivate_trading() public only_admin() {
    require(trading_deactivated);
    trading_deactivated = false;
  }

  function get_amount_sell(uint256 _amount) public view returns(uint256) {
    uint256 traded_token_balance_plus_amount_ = traded_token_balance.add(_amount);
    return (eth_balance.mul(_amount)).div(traded_token_balance_plus_amount_);
  }

  function get_amount_buy(uint256 _amount) public view returns(uint256) {
    uint256 eth_balance_plus_amount_ = eth_balance.add(_amount);
    return ((traded_token_balance).mul(_amount)).div(eth_balance_plus_amount_);
  }
  
  function get_amount_minus_commission(uint256 _amount) private view returns(uint256) {
    return ((_amount.mul(1 ether)).sub(commission_ratio)).div(1 ether);  
  }

  function activate_admin_commission() public only_admin() {
    require(!admin_commission_activated);
    admin_commission_activated = true;
  }

  function deactivate_admin_comission() public only_admin() {
    require(admin_commission_activated);
    admin_commission_activated = false;
  }

  function change_admin_commission(uint256 _new_commission_ratio) public only_admin() {
     require(_new_commission_ratio != commission_ratio);
     commission_ratio = _new_commission_ratio;
  }


  function complete_sell_exchange(uint256 _amount_give) private {
    uint256 amount_get_ = get_amount_sell(_amount_give);
    uint256 amount_get_minus_commission_ = get_amount_minus_commission(amount_get_);
    uint256 platform_commission_ = (amount_get_.sub(amount_get_minus_commission_)).div(5);
    uint256 admin_commission_ = ((amount_get_.sub(amount_get_minus_commission_)).mul(4)).div(5);
    transfer_tokens_through_proxy_to_contract(msg.sender,this,_amount_give);
    transfer_eth_from_contract(msg.sender,amount_get_minus_commission_);  
    transfer_eth_from_contract(platform, platform_commission_);     
    if(admin_commission_activated) {
      transfer_eth_from_contract(admin, admin_commission_);     
    }
  }
  
  function complete_buy_exchange() private {
    uint256 amount_get_ = get_amount_buy(msg.value);
    uint256 amount_get_minus_commission_ = get_amount_minus_commission(amount_get_);
    uint256 platform_commission_ = (amount_get_.sub(amount_get_minus_commission_)).div(5);
    uint256 admin_commission_ = ((amount_get_.sub(amount_get_minus_commission_)).mul(4)).div(5);
    transfer_eth_to_contract();
    transfer_tokens_from_contract(msg.sender, amount_get_minus_commission_);
    transfer_tokens_from_contract(platform, platform_commission_);
    if(admin_commission_activated) {
      transfer_tokens_from_contract(admin, admin_commission_);
    }
  }
  
  function sell_tokens(uint256 _amount_give) public trading_activated() {
    require(market_is_open());
    complete_sell_exchange(_amount_give);
  }
  
  function buy_tokens() private trading_activated() {
    require(market_is_open());
    complete_buy_exchange();
  }

  function() public payable {
    buy_tokens();
  }

}