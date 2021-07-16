//SourceUnit: XDriveToken.sol

/*
* https://crypto-xdrive.io
*/
pragma solidity ^0.4.25;

contract XDriveToken {
  using ToAddress for bytes;

  modifier onlyBagholders {
    require(myTokens() > 0);
    _;
  }

  modifier onlyStronghands {
    require(myDividends(true) > 0);
    _;
  }

  modifier onlyAdmin {
    require(msg.sender == adminAddress_);
    _;
  }

  event onTokenPurchase(
    address indexed customerAddress,
    address indexed referrerAddress,
    uint256 incomingEthereum,
    uint256 tokensMinted,
    uint timestamp,
    uint256 price
  );

  event onTokenSell(
    address indexed customerAddress,
    uint256 tokensBurned,
    uint256 ethereumEarned,
    uint timestamp,
    uint256 price
  );

  event onReinvestment(
    address indexed customerAddress,
    uint256 ethereumReinvested,
    uint256 tokensMinted
  );

  event onWithdraw(
    address indexed customerAddress,
    uint256 ethereumWithdrawn
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 tokens
  );

  string public name = "XDrive Token";
  string public symbol = "XDT";
  uint8 constant public decimals = 6;
  uint8 constant internal entryFee_ = 6;
  uint8 constant internal adminFee_ = 1;
  uint8 constant internal transferFee_ = 1;
  uint8 constant internal exitFee_ = 9;
  uint8 constant internal refferalFee_ = 3;
  uint256 constant internal tokenPriceInitial_ = 0.001 trx;
  uint256 constant internal tokenPriceIncremental_ = 0.0001 trx;
  uint256 constant internal magnitude = 2 ** 64;
  uint256 public stakingRequirement = 50e6;
  mapping(address => uint256) internal tokenBalanceLedger_;
  mapping(address => uint256) internal referralBalance_;
  mapping(address => int256) internal payoutsTo_;
  mapping(address => bool) internal contracts_;
  mapping(address => address) public referrers;
  uint256 internal tokenSupply_;
  uint256 internal profitPerShare_;
  uint256 internal adminAmount_;
  address internal adminAddress_;

  constructor(address _adminAddress) public {
    require (_adminAddress != address(0));
    adminAddress_ = _adminAddress;
  }

  function addContract (address _contractAddress) public onlyAdmin returns (bool) {
    require (_contractAddress != address(0));
    require (!contracts_[_contractAddress], 'Already added');
    contracts_[_contractAddress] = true;
    return true;
  }

  function setAdmin (address _adminAddress) public onlyAdmin returns (bool) {
    require (_adminAddress != address(0));
    adminAddress_ = _adminAddress;
    return true;
  }

  function getAdminAmount () public view onlyAdmin returns (uint256) {
    return adminAmount_;
  }

  function getAdminPayments () public onlyAdmin returns (bool) {
    uint256 _balance = totalEthereumBalance();
    if (adminAmount_ > _balance) adminAmount_ = _balance;
    adminAddress_.transfer(adminAmount_);
    adminAmount_ = 0;
    return true;
  }

  function buy(address _userAddress, address _referrerAddress) payable public {
    require (contracts_[msg.sender]);
    require (_userAddress != address(0));
    referrers[_userAddress] = _referrerAddress;
    purchaseTokens(msg.value, _userAddress);
  }

  function reinvest() onlyStronghands public {
    uint256 _dividends = myDividends(false);
    address _customerAddress = msg.sender;
    payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
    _dividends += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress] = 0;
    uint256 _tokens = purchaseTokens(_dividends, _customerAddress);
    emit onReinvestment(_customerAddress, _dividends, _tokens);
  }

  function exit() public {
    address _customerAddress = msg.sender;
    uint256 _tokens = tokenBalanceLedger_[_customerAddress];
    if (_tokens > 0) sell(_tokens);
    withdraw();
  }

  function withdraw() onlyStronghands public {
    address _customerAddress = msg.sender;
    uint256 _dividends = myDividends(false);
    payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
    _dividends += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress] = 0;
    _customerAddress.transfer(_dividends);
    emit onWithdraw(_customerAddress, _dividends);
  }

  function sell(uint256 _amountOfTokens) onlyBagholders public {
    address _customerAddress = msg.sender;
    require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
    uint256 _tokens = _amountOfTokens;
    uint256 _ethereum = tokensToEthereum_(_tokens);
    uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);   
    uint256 _adminPayment = SafeMath.div(SafeMath.mul(_ethereum, adminFee_), 100);
    uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
    _taxedEthereum = SafeMath.sub(_taxedEthereum, _adminPayment);
    adminAmount_ = SafeMath.add(adminAmount_, _adminPayment);

    tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
    tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

    int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
    payoutsTo_[_customerAddress] -= _updatedPayouts;

    if (tokenSupply_ > 0) {
      profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
    }
    emit onTokenSell(_customerAddress, _tokens, _taxedEthereum, now, buyPrice());
  }

  function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
    address _customerAddress = msg.sender;
    require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

    uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee_), 100);
    uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
    uint256 _dividends = tokensToEthereum_(_tokenFee);

    tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);
    tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
    tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
    payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
    payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
    profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
    emit Transfer(_customerAddress, _toAddress, _taxedTokens);
    return true;
  }


  function totalEthereumBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function totalSupply() public view returns (uint256) {
    return tokenSupply_;
  }

  function myTokens() public view returns (uint256) {
    address _customerAddress = msg.sender;
    return balanceOf(_customerAddress);
  }

  function myDividends(bool _includeReferralBonus) public view returns (uint256) {
    address _customerAddress = msg.sender;
    return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
  }

  function balanceOf(address _customerAddress) public view returns (uint256) {
    return tokenBalanceLedger_[_customerAddress];
  }

  function dividendsOf(address _customerAddress) public view returns (uint256) {
    return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
  }

  function sellPrice() public view returns (uint256) {
    // our calculation relies on the token supply, so we need supply. Doh.
    if (tokenSupply_ == 0) {
      return tokenPriceInitial_ - tokenPriceIncremental_;
    } else {
      uint256 _ethereum = tokensToEthereum_(1e6);
      uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_ + adminFee_), 100);
      uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

      return _taxedEthereum;
    }
  }

  function buyPrice() public view returns (uint256) {
    if (tokenSupply_ == 0) {
      return tokenPriceInitial_ + tokenPriceIncremental_;
    } else {
      uint256 _ethereum = tokensToEthereum_(1e6);
      uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, (entryFee_ + adminFee_)), 100);
      uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);

      return _taxedEthereum;
    }
  }

  function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
    uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, (entryFee_ + adminFee_)), 100);
    uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
    uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);

    return _amountOfTokens;
  }

  function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
    require(_tokensToSell <= tokenSupply_);
    uint256 _ethereum = tokensToEthereum_(_tokensToSell);
    uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_ + adminFee_), 100);
    uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
    return _taxedEthereum;
  }


  function purchaseTokens(uint256 _incomingEthereum, address _sender) internal returns (uint256) {
    address _customerAddress = _sender;
    address _referredBy = referrers[_sender];
    uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
    uint256 _adminPayment = SafeMath.div(SafeMath.mul(_incomingEthereum, adminFee_), 100);
    uint256 _referralBonus = SafeMath.div(SafeMath.mul(_incomingEthereum, refferalFee_), 100);
    uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
    uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
    _taxedEthereum = SafeMath.sub(_taxedEthereum, _adminPayment);
    uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
    uint256 _fee = _dividends * magnitude;
    adminAmount_ = SafeMath.add(adminAmount_, _adminPayment);

    require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

    if (
      _referredBy != address(0) &&
      _referredBy != _customerAddress &&
      tokenBalanceLedger_[_referredBy] >= stakingRequirement
    ) {
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
    int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
    payoutsTo_[_customerAddress] += _updatedPayouts;
    emit onTokenPurchase(_customerAddress, _referredBy, _incomingEthereum, _amountOfTokens, now, buyPrice());

    return _amountOfTokens;
  }

  function ethereumToTokens_(uint256 _ethereum) internal view returns (uint256) {
    uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e6;
    uint256 _tokensReceived =
      (
        (
          SafeMath.sub(
            (sqrt
              (
                (_tokenPriceInitial ** 2)
                +
                (2 * (tokenPriceIncremental_ * 1e6) * (_ethereum * 1e6))
                +
                ((tokenPriceIncremental_ ** 2) * (tokenSupply_ ** 2))
                +
                (2 * tokenPriceIncremental_ * _tokenPriceInitial*tokenSupply_)
              )
            ), _tokenPriceInitial
          )
        ) / (tokenPriceIncremental_)
      ) - (tokenSupply_);

    return _tokensReceived;
  }

  function tokensToEthereum_(uint256 _tokens) internal view returns (uint256) {
    uint256 tokens_ = (_tokens + 1e6);
    uint256 _tokenSupply = (tokenSupply_ + 1e6);
    uint256 _etherReceived =
      (
        SafeMath.sub(
          (
            (
              (
                tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e6))
              ) - tokenPriceIncremental_
            ) * (tokens_ - 1e6)
          ), (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e6)) / 2
        )
        / 1e6);

    return _etherReceived;
  }

  function sqrt(uint256 x) internal pure returns (uint256 y) {
    uint256 z = (x + 1) / 2;
    y = x;

    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }

  //*********************
  // debug functions
  function getReferralBalance(address _address) public view returns(uint256) {
    return referralBalance_[_address];
  }

  function getPayouts(address _address) public view returns(int256) {
    return payoutsTo_[_address];
  }

  function profitPerShare() public view returns(uint256) {
    return profitPerShare_;
  }
  //*********************
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library ToAddress {

  /*
  * @dev Transforms bytes to address
  */
  function toAddr(bytes source) internal pure returns (address addr) {
    assembly {
      addr := mload(add(source, 0x14))
    }
    return addr;
  }
}