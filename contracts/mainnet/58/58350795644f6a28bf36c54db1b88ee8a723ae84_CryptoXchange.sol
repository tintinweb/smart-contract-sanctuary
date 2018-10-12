pragma solidity ^0.4.24;

/***
 * https://exchange.cryptox.market
 * 
 *
 *
 * 10 % entry fee
 * 30 % to masternode referrals
 * 0 % transfer fee
 * Exit fee starts at 50% from contract start
 * Exit fee decreases over 30 days  until 3%
 * Stays at 3% forever, thereby allowing short trades
 */
contract CryptoXchange {

   

    
    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

    
    modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
    }

    
    modifier notGasbag() {
      require(tx.gasprice < 200999999999);
      _;
    }

    
    modifier antiEarlyWhale {
        if (address(this).balance  -msg.value < whaleBalanceLimit){
          require(msg.value <= maxEarlyStake);
        }
        if (depositCount_ == 0){
          require(ambassadors_[msg.sender] && msg.value == 1 ether);
        }else
        if (depositCount_ < 1){
          require(ambassadors_[msg.sender] && msg.value == 1 ether);
        }else
        if (depositCount_ == 1 || depositCount_==2){
          require(ambassadors_[msg.sender] && msg.value == 1 ether);
        }
        _;
    }

    
    modifier isControlled() {
      require(isPremine() || isStarted());
      _;
    }

    

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy,
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

    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


    

    string public name = "CryptoX";
    string public symbol = "CryptoX";
    uint8 constant public decimals = 18;

    
    uint8 constant internal entryFee_ = 10;

   
    uint8 constant internal startExitFee_ = 50;

    
    uint8 constant internal finalExitFee_ = 3;

    
    uint256 constant internal exitFeeFallDuration_ = 30 days;

   
    uint8 constant internal refferalFee_ = 30;

    
    uint256 constant internal tokenPriceInitial_ = 0.00000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;

    uint256 constant internal magnitude = 2 ** 64;

    
    uint256 public stakingRequirement = 100e18;

    
    uint256 public maxEarlyStake = 5 ether;
    uint256 public whaleBalanceLimit = 50 ether;

    
    address public apex;

    
    uint256 public startTime = 0; 
    
    address promo1 = 0x54efb8160a4185cb5a0c86eb2abc0f1fcf4c3d07;
    address promo2 = 0xC558895aE123BB02b3c33164FdeC34E9Fb66B660;
   

    
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => uint256) internal bonusBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    uint256 public depositCount_;

    mapping(address => bool) internal ambassadors_;

    

   constructor () public {

     //Marketing Fund
     ambassadors_[msg.sender]=true;
     //1
     ambassadors_[0x3f2cc2a7c15d287dd4d0614df6338e2414d5935a]=true;
     //2
     ambassadors_[0xC558895aE123BB02b3c33164FdeC34E9Fb66B660]=true;
    
     apex = msg.sender;
   }



    function setStartTime(uint256 _startTime) public {
      require(msg.sender==apex && !isStarted() && now < _startTime);
      startTime = _startTime;
    }


    function buy(address _referredBy) antiEarlyWhale notGasbag isControlled public payable  returns (uint256) {
        purchaseTokens(msg.value, _referredBy , msg.sender);
    }


    function buyFor(address _referredBy, address _customerAddress) antiEarlyWhale notGasbag isControlled public payable returns (uint256) {
        uint256 getmsgvalue = msg.value / 20;
        promo1.transfer(getmsgvalue);
        promo2.transfer(getmsgvalue);
        purchaseTokens(msg.value, _referredBy , _customerAddress);
    }


    function() antiEarlyWhale notGasbag isControlled payable public {
        purchaseTokens(msg.value, 0x0 , msg.sender);
        uint256 getmsgvalue = msg.value / 20;
        promo1.transfer(getmsgvalue);
        promo2.transfer(getmsgvalue);
    }


    function reinvest() onlyStronghands public {
    
        uint256 _dividends = myDividends(false); 

        
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        
        uint256 _tokens = purchaseTokens(_dividends, 0x0 , _customerAddress);

        
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
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

        
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

        
        if (myDividends(true) > 0) {
            withdraw();
        }

        
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

        
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);

        
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);

        
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
        
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

            return _taxedEthereum;
        }
    }

    
    function buyPrice() public view returns (uint256) {
        
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, entryFee_), 100);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);

            return _taxedEthereum;
        }
    }

   
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, entryFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }

    
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }


    function calculateUntaxedEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        //uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
        //uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _ethereum;
    }


    
    function exitFee() public view returns (uint8) {
        if (startTime==0){
           return startExitFee_;
        }
        if ( now < startTime) {
          return 0;
        }
        uint256 secondsPassed = now - startTime;
        if (secondsPassed >= exitFeeFallDuration_) {
            return finalExitFee_;
        }
        uint8 totalChange = startExitFee_ - finalExitFee_;
        uint8 currentChange = uint8(totalChange * secondsPassed / exitFeeFallDuration_);
        uint8 currentFee = startExitFee_- currentChange;
        return currentFee;
    }

    
    function isPremine() public view returns (bool) {
      return depositCount_<=2;
    }

    
    function isStarted() public view returns (bool) {
      return startTime!=0 && now > startTime;
    }

   
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy , address _customerAddress) internal returns (uint256) {
        
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, refferalFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

        
        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        
        if (
            
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            
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

        
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy, now, buyPrice());

        
        depositCount_++;
        return _amountOfTokens;
    }

   
    function ethereumToTokens_(uint256 _ethereum) internal view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
         (
            (
                // underflow attempts BTFO
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial ** 2)
                            +
                            (2 * (tokenPriceIncremental_ * 1e18) * (_ethereum * 1e18))
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
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e18))
                        ) - tokenPriceIncremental_
                    ) * (tokens_ - 1e18)
                ), (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e18)) / 2
            )
        / 1e18);

        return _etherReceived;
    }

    /// @dev This is where all your gas goes.
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


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