/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

pragma solidity ^ 0.4.26;

/*
   _____  .__.__  .__  .__                ____   ____            .__   __   
  /     \ |__|  | |  | |__| ____   ____   \   \ /   /____   __ __|  |_/  |_ 
 /  \ /  \|  |  | |  | |  |/  _ \ /    \   \   Y   /\__  \ |  |  \  |\   __\
/    Y    \  |  |_|  |_|  (  <_> )   |  \   \     /  / __ \|  |  /  |_|  |  
\____|__  /__|____/____/__|\____/|___|  /    \___/  (____  /____/|____/__|  
        \/                            \/                 \/                 

Mechanics:
---------

This is a stable hourglass without a bonding curve, long term staking 
is highly recommended. 

10% entry fee, 10% exit fee 
1% transfer fee 
2% referral fee (no deposit required to earn ref bonus)

First time deposit mints a free NFT in Team3D's InventoryV2 

*/

contract InventoryV2 {
 function createFromTemplate(uint256 _templateId, uint8 _feature1, uint8 _feature2, uint8 _feature3, uint8 _feature4, uint8 _equipmentPosition) public returns(uint256);
}

contract TOKEN {
 function totalSupply() external view returns(uint256);
 function balanceOf(address account) external view returns(uint256);
 function transfer(address recipient, uint256 amount) external returns(bool);
 function allowance(address owner, address spender) external view returns(uint256);
 function approve(address spender, uint256 amount) external returns(bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

contract Ownable {
 address public owner;
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 constructor() public {
  owner = msg.sender;
 }
 modifier onlyOwner() {
  require(msg.sender == owner);
  _;
 }
 function transferOwnership(address newOwner) public onlyOwner {
  require(newOwner != address(0));
  emit OwnershipTransferred(owner, newOwner);
  owner = newOwner;
 }
}

contract MillionVault is Ownable {

 modifier onlyTokenHolders {
  require(myTokens() > 0);
  _;
 }

 modifier onlyDivis {
  require(myDividends(true) > 0);
  _;
 }

 event onDistribute(
  address indexed customerAddress,
  uint256 price
 );

 event onTokenPurchase(
  address indexed customerAddress,
  uint256 incomingMM,
  uint256 tokensMinted,
  address indexed referredBy,
  uint timestamp
 );

 event onTokenSell(
  address indexed customerAddress,
  uint256 tokensBurned,
  uint256 mmEarned,
  uint timestamp
 );

 event onReinvestment(
  address indexed customerAddress,
  uint256 mmReinvested,
  uint256 tokensMinted
 );

 event onWithdraw(
  address indexed customerAddress,
  uint256 mmWithdrawn
 );

 event Transfer(
  address indexed from,
  address indexed to,
  uint256 tokens
 );

 string public name = "Million Vault";
 string public symbol = "MV";
 uint8 constant public decimals = 18;
 uint256 internal entryFee_ = 10;
 uint256 internal transferFee_ = 1;
 uint256 internal exitFee_ = 10;
 uint256 internal referralFee_ = 20;
 uint256 constant internal magnitude = 2 ** 64;
 mapping(address => uint256) internal tokenBalanceLedger_;
 mapping(address => uint256) internal referralBalance_;
 mapping(address => int256) internal payoutsTo_;
 mapping(address => uint256) internal invested_;
 mapping(address => bool) internal minted;
 uint256 internal tokenSupply_;
 uint256 internal profitPerShare_;
 uint256 public stakingRequirement = 0;
 uint256 public totalHolder = 0;
 uint256 public totalDonation = 0;
 TOKEN erc20;
 InventoryV2 item;

 constructor() public {
  erc20 = TOKEN(address(0x6B4c7A5e3f0B99FCD83e9c089BDDD6c7FCe5c611));
  item = InventoryV2(address(0x9680223F7069203E361f55fEFC89B7c1A952CDcc));
 }

 function checkAndTransferMM(uint256 _amount) private {
  require(erc20.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
 }

 function distribute(uint256 _amount) public returns(uint256) {
  require(_amount > 0, "must be a positive value");
  checkAndTransferMM(_amount);
  totalDonation += _amount;
  profitPerShare_ = SafeMath.add(profitPerShare_, (_amount * magnitude) / tokenSupply_);
  emit onDistribute(msg.sender, _amount);
 }

 function buy(uint256 _amount, address _referredBy) public returns(uint256) {
  checkAndTransferMM(_amount);
  return purchaseTokens(_referredBy, msg.sender, _amount);
 }

 function buyFor(uint256 _amount, address _customerAddress, address _referredBy) public returns(uint256) {
  checkAndTransferMM(_amount);
  return purchaseTokens(_referredBy, _customerAddress, _amount);
 }

 function() payable public {
  revert();
 }

 function reinvest() onlyDivis public {
  address _customerAddress = msg.sender;
  uint256 _dividends = myDividends(false);
  payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);
  _dividends += referralBalance_[_customerAddress];
  referralBalance_[_customerAddress] = 0;
  uint256 _tokens = purchaseTokens(0x0, _customerAddress, _dividends);
  emit onReinvestment(_customerAddress, _dividends, _tokens);
 }

 function exit() external {
  address _customerAddress = msg.sender;
  uint256 _tokens = tokenBalanceLedger_[_customerAddress];
  if (_tokens > 0) sell(_tokens);
  withdraw();
 }

 function withdraw() onlyDivis public {
  address _customerAddress = msg.sender;
  uint256 _dividends = myDividends(false);
  payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);
  _dividends += referralBalance_[_customerAddress];
  referralBalance_[_customerAddress] = 0;
  erc20.transfer(_customerAddress, _dividends);
  emit onWithdraw(_customerAddress, _dividends);
 }

 function sell(uint256 _amountOfTokens) onlyTokenHolders public {
  address _customerAddress = msg.sender;
  require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

  uint256 _dividends = SafeMath.div(SafeMath.mul(_amountOfTokens, exitFee_), 100);
  uint256 _taxedMM = SafeMath.sub(_amountOfTokens, _dividends);

  tokenSupply_ = SafeMath.sub(tokenSupply_, _amountOfTokens);
  tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

  int256 _updatedPayouts = (int256)(profitPerShare_ * _amountOfTokens + (_taxedMM * magnitude));
  payoutsTo_[_customerAddress] -= _updatedPayouts;

  if (tokenSupply_ > 0) {
   profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
  }

  emit Transfer(_customerAddress, address(0), _amountOfTokens);
  emit onTokenSell(_customerAddress, _amountOfTokens, _taxedMM, now);
 }

 function transfer(address _toAddress, uint256 _amountOfTokens) onlyTokenHolders external returns(bool) {
  address _customerAddress = msg.sender;
  require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

  if (myDividends(true) > 0) {
   withdraw();
  }

  uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee_), 100);
  uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
  uint256 _dividends = _tokenFee;

  tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

  tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
  tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

  payoutsTo_[_customerAddress] -= (int256)(profitPerShare_ * _amountOfTokens);
  payoutsTo_[_toAddress] += (int256)(profitPerShare_ * _taxedTokens);

  profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

  emit Transfer(_customerAddress, _toAddress, _taxedTokens);

  return true;
 }

 function setName(string _name) onlyOwner public {
  name = _name;
 }

 function setSymbol(string _symbol) onlyOwner public {
  symbol = _symbol;
 }

 function totalMMBalance() public view returns(uint256) {
  return erc20.balanceOf(address(this));
 }

 function totalSupply() public view returns(uint256) {
  return tokenSupply_;
 }

 function myTokens() public view returns(uint256) {
  address _customerAddress = msg.sender;
  return balanceOf(_customerAddress);
 }

 function myDividends(bool _includeReferralBonus) public view returns(uint256) {
  address _customerAddress = msg.sender;
  return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
 }

 function balanceOf(address _customerAddress) public view returns(uint256) {
  return tokenBalanceLedger_[_customerAddress];
 }

 function dividendsOf(address _customerAddress) public view returns(uint256) {
  return (uint256)((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
 }

 function sellPrice() public view returns(uint256) {
  uint256 _mm = 1e18;
  uint256 _dividends = SafeMath.div(SafeMath.mul(_mm, exitFee_), 100);
  uint256 _taxedMM = SafeMath.sub(_mm, _dividends);

  return _taxedMM;
 }

 function buyPrice() public view returns(uint256) {
  uint256 _mm = 1e18;
  uint256 _dividends = SafeMath.div(SafeMath.mul(_mm, entryFee_), 100);
  uint256 _taxedMM = SafeMath.add(_mm, _dividends);

  return _taxedMM;
 }

 function calculateTokensReceived(uint256 _mmToSpend) public view returns(uint256) {
  uint256 _dividends = SafeMath.div(SafeMath.mul(_mmToSpend, entryFee_), 100);
  uint256 _amountOfTokens = SafeMath.sub(_mmToSpend, _dividends);

  return _amountOfTokens;
 }

 function calculateMMReceived(uint256 _tokensToSell) public view returns(uint256) {
  require(_tokensToSell <= tokenSupply_);
  uint256 _dividends = SafeMath.div(SafeMath.mul(_tokensToSell, exitFee_), 100);
  uint256 _taxedMM = SafeMath.sub(_tokensToSell, _dividends);

  return _taxedMM;
 }

 function getInvested() public view returns(uint256) {
  return invested_[msg.sender];
 }

 function purchaseTokens(address _referredBy, address _customerAddress, uint256 _incomingMM) internal returns(uint256) {
  if (getInvested() == 0) {
   totalHolder++;
  }

  invested_[msg.sender] += _incomingMM;

  uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingMM, entryFee_), 100);

  uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, referralFee_), 100);

  uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
  uint256 _amountOfTokens = SafeMath.sub(_incomingMM, _undividedDividends);
  uint256 _fee = _dividends * magnitude;

  require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

  if (_referredBy != address(0) && _referredBy != _customerAddress && tokenBalanceLedger_[_referredBy] >= stakingRequirement) {
   referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
  } else {
   _dividends = SafeMath.add(_dividends, _referralBonus);
   _fee = _dividends * magnitude;
  }

  if (tokenSupply_ > 0) {
   tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
   profitPerShare_ += (_dividends * magnitude / tokenSupply_);
   _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
  } else {
   tokenSupply_ = _amountOfTokens;
  }

  tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

  int256 _updatedPayouts = (int256)(profitPerShare_ * _amountOfTokens - _fee);
  payoutsTo_[_customerAddress] += _updatedPayouts;
  
  if(!minted[msg.sender]) {
      minted[msg.sender] = true;
      item.createFromTemplate(39,0,0,0,0,0);
  }

  emit Transfer(address(0), msg.sender, _amountOfTokens);
  emit onTokenPurchase(_customerAddress, _incomingMM, _amountOfTokens, _referredBy, now);

  return _amountOfTokens;
 }

 function multiData()
 public
 view
 returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
  return (

   // [0] Total MM in contract 
   totalMMBalance(),

   // [1] Total MV supply
   totalSupply(),

   // [2] User MV balance 
   balanceOf(msg.sender),

   // [3] User MM balance
   erc20.balanceOf(msg.sender),

   // [4] User divs 
   dividendsOf(msg.sender),

   // [5] Buy price 
   buyPrice(),

   // [6] Sell price 
   sellPrice()

  );
 }
}

library SafeMath {

 function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
  if (a == 0) {
   return 0;
  }
  c = a * b;
  assert(c / a == b);
  return c;
 }

 function div(uint256 a, uint256 b) internal pure returns(uint256) {
  return a / b;
 }

 function sub(uint256 a, uint256 b) internal pure returns(uint256) {
  assert(b <= a);
  return a - b;
 }

 function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
  c = a + b;
  assert(c >= a);
  return c;
 }

}