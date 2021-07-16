//SourceUnit: TRX_PLAT_final.sol

pragma solidity 0.5.8;

contract TRXPlatinum {
    modifier onlyBagholders() {require(myTokens() > 0);_;}
    modifier onlyStronghands() {require(myDividends(true) > 0);_;}

    event onTokenPurchase(address indexed customerAddress, uint256 incomingTron, uint256 tokensMinted, address indexed referredBy);
    event onTokenSell(address indexed customerAddress, uint256 tokensBurned, uint256 tronEarned);
    event onReinvestment(address indexed customerAddress, uint256 tronReinvested, uint256 tokensMinted);
    event onWithdraw(address indexed customerAddress, uint256 tronWithdrawn);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    string public name = "TRX Platinum";
    string public symbol = "TRXP";
    uint8 constant public decimals = 18;
    uint8 constant internal referralFee_ = 3;
    uint8 constant internal dividendFee_ = 10;
    uint8 constant internal devFee_ = 4;
    uint8 constant internal marketingFee_ = 4;
    uint256 constant internal tokenPriceInitial_ = 1000;
    uint256 constant internal tokenPriceIncremental_ = 10;
    uint256 constant internal magnitude = 2 ** 64;
    uint256 public stakingRequirement = 1e18;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    address payable devAddress_;
    constructor()
        public
    {
        devAddress_ = msg.sender;
    }

    struct FeeStructure {
        uint256 _devTax;
        uint256 _marketingTax;
    }
    

    function() payable external {}
    function buy(address _referredBy) public payable returns (uint256) {purchaseTokens(msg.value, _referredBy);}

    function reinvest() onlyStronghands public {
        uint256 _dividends = myDividends(false);
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(_dividends, msg.sender);
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function exit() public {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    function withdraw() onlyStronghands public {
        address payable _customerAddress = msg.sender;
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
        uint256 _tron = tokensToTron_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, dividendFee_), 100);
        uint256 _devTax = SafeMath.div(SafeMath.mul(_tron, devFee_), 100);
        uint256 _marketingTax = SafeMath.div(SafeMath.mul(_tron, marketingFee_), 100);
        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
        _taxedTron = SafeMath.sub(_taxedTron, _devTax);
        _taxedTron = SafeMath.sub(_taxedTron, _marketingTax);
        uint256 _payYourTaxes = SafeMath.add(_devTax, _marketingTax);

        devAddress_.transfer(_payYourTaxes);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedTron * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        if (tokenSupply_ > 0) {profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);}
        emit onTokenSell(_customerAddress, _tokens, _taxedTron);
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        if (myDividends(true) > 0) {withdraw();}

        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, dividendFee_), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToTron_(_tokenFee);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);
        return true;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function totalSupply() public view returns (uint256) {return tokenSupply_;}
    function totalTronBalance() public view returns (uint256) {return address(this).balance;}
    function balanceOf(address _customerAddress) public view returns (uint256) {return tokenBalanceLedger_[_customerAddress];}
    function dividendsOf(address _customerAddress) public view returns (uint256) {return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;}

    function sellPrice() public view returns (uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _tron = tokensToTron_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, dividendFee_), 100);
            uint256 _devTax = SafeMath.div(SafeMath.mul(_tron, devFee_), 100);
            uint256 _marketingTax = SafeMath.div(SafeMath.mul(_tron, marketingFee_), 100);           
            uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
            _taxedTron = SafeMath.sub(_taxedTron, _devTax);
            _taxedTron = SafeMath.sub(_taxedTron, _marketingTax);
            return _taxedTron;
        }
    }

    function buyPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _tron = tokensToTron_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, dividendFee_), 100);
            uint256 _devTax = SafeMath.div(SafeMath.mul(_tron, devFee_), 100);
            uint256 _marketingTax = SafeMath.div(SafeMath.mul(_tron, marketingFee_), 100);
            uint256 _taxedTron = SafeMath.add(_tron, _dividends);
            _taxedTron = SafeMath.sub(_taxedTron, _devTax);
            _taxedTron = SafeMath.sub(_taxedTron, _marketingTax);
            return _taxedTron;
        }
    }

    function calculateTokensReceived(uint256 _tronToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tronToSpend, dividendFee_), 100);
        uint256 _devTax = SafeMath.div(SafeMath.mul(_tronToSpend, devFee_), 100);
        uint256 _marketingTax = SafeMath.div(SafeMath.mul(_tronToSpend, marketingFee_), 100);
        uint256 _taxedTron = SafeMath.sub(_tronToSpend, _dividends);
        _taxedTron = SafeMath.sub(_taxedTron, _devTax);
        _taxedTron = SafeMath.sub(_taxedTron, _marketingTax);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        return _amountOfTokens;
    }

    function calculateTronReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _tron = tokensToTron_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, dividendFee_), 100);
        uint256 _devTax = SafeMath.div(SafeMath.mul(_tron, devFee_), 100);
        uint256 _marketingTax = SafeMath.div(SafeMath.mul(_tron, marketingFee_), 100);
        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
        _taxedTron = SafeMath.sub(_taxedTron, _devTax);
        _taxedTron = SafeMath.sub(_taxedTron, _marketingTax);
        return _taxedTron;
    }

    function purchaseTokens(uint256 _incomingTron, address _referredBy) internal returns (uint256) {
        FeeStructure memory feez;
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingTron, dividendFee_), 100);
        feez._devTax = SafeMath.div(SafeMath.mul(_incomingTron, devFee_), 100);
        feez._marketingTax = SafeMath.div(SafeMath.mul(_incomingTron, marketingFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, referralFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedTron = SafeMath.sub(_incomingTron, _undividedDividends);
        _taxedTron = SafeMath.sub(_taxedTron, feez._devTax);
        _taxedTron = SafeMath.sub(_taxedTron, feez._marketingTax);
        uint256 _payYourTaxes = SafeMath.add(feez._devTax, feez._marketingTax);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        uint256 _fee = _dividends * magnitude;

        devAddress_.transfer(_payYourTaxes);

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
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        emit onTokenPurchase(_customerAddress, _incomingTron, _amountOfTokens, _referredBy);
        return _amountOfTokens;
    }

    function tronToTokens_(uint256 _tron) internal view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = ((SafeMath.sub((sqrt((_tokenPriceInitial ** 2)
        + (2 * (tokenPriceIncremental_ * 1e18) * (_tron * 1e18))
        + ((tokenPriceIncremental_ ** 2) * (tokenSupply_ ** 2))
        + (2 * tokenPriceIncremental_ * _tokenPriceInitial*tokenSupply_)
        )), _tokenPriceInitial)) / (tokenPriceIncremental_)) - (tokenSupply_);
        return _tokensReceived;
    }

    function tokensToTron_(uint256 _tokens) internal view returns (uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _tronReceived = (SafeMath.sub((((tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e18))
            ) - tokenPriceIncremental_) * (tokens_ - 1e18)
            ), (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e18)) / 2)/ 1e18);
        return _tronReceived;
    }

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
        if (a == 0) {return 0;}
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