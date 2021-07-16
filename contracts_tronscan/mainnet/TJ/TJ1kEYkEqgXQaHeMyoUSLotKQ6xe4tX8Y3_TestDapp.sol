//SourceUnit: test1.sol

pragma solidity ^0.4.25;
 
/*
*
* Test Dapp by Test.net
* 33% Buy Fees
* 33% Sell Fees
* 1% Transfer Fees
* 10% Affiliate Commission
* 0.75% Daily Interest (As long as sufficient ETH is available in the allocated pool)
* Website: Test.net
* Casino Website: Test.net
*/


contract Ownable {
    
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}


contract TestDapp is Ownable{
    using SafeMath for uint256;
    
     modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }
      
     modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
    }
    
   
      
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingTron,
        uint256 tokensMinted,
        address indexed referredBy,
        uint timestamp,
        uint256 price
);

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 tronEarned,
        uint timestamp,
        uint256 price
);

    event onReinvestment(
        address indexed customerAddress,
        uint256 tronReinvested,
        uint256 tokensMinted
);

    event onWithdraw(
        address indexed customerAddress,
        uint256 tronWithdrawn
);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
);

    string public name = "TestDapp";
    string public symbol = "Test";
    uint8 constant public decimals = 18;
    uint8 constant internal entryFee_ = 41; //Includes the dev fee, old dapp feeding & the money alloted for the daily fixed interest. 33% is the actual fee that will be distributed as dividends.
    uint8 constant internal transferFee_ = 1;
    uint8 constant internal ExitFee_ = 33; 
    uint8 constant internal refferalFee_ = 10;
    uint8 constant internal DevFee_ = 15; //Actual dev fee is only 1.5%. This value will be divided by 10 and used. Since we cannot use a decimal here, a round number is used.
    uint8 constant internal OldDappFeed_ = 2;
    uint8 constant internal DailyInterest_ = 75; //Actual daily interest is only 0.75%. This value will be divided by 100 and used. Since we cannot use a decimal here, a round number is used. 
    uint8 constant internal IntFee_ = 45; //This value will be divided by 10 and used. Since we cannot use a decimal here, a round number is used.
    uint256 public InterestPool_ = 0; 
    uint256 constant internal tokenPriceInitial_ = 3;
    uint256 constant internal tokenPriceIncremental_ = 1;
    uint256 constant internal magnitude = 2**64;
    uint256 public stakingRequirement = 22000e18;
    uint256 public launchtime = 1572967800;
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    address dev = owner;
    address feed = owner; // The money sent to this address will feed the previous dapp - ETH Exchange.
    

        function buy(address _referredBy) public payable returns (uint256) {
        require(now >= launchtime);
        uint256 DevFee1 = msg.value.div(100).mul(DevFee_);
        uint256 DevFeeFinal = SafeMath.div(DevFee1, 10);
        dev.transfer(DevFeeFinal);
        uint256 feedFee = msg.value.div(100).mul(OldDappFeed_);
        feed.transfer(feedFee);
        uint256 DailyInt1 = msg.value.div(100).mul(IntFee_);
        uint256 DailyIntFinal = SafeMath.div(DailyInt1, 10);
        InterestPool_ += DailyIntFinal;
        purchaseTokens(msg.value, _referredBy);
    }
    
        function() payable public {
        require(now >= launchtime);
        uint256 DevFee1 = msg.value.div(100).mul(DevFee_);
        uint256 DevFeeFinal = SafeMath.div(DevFee1, 10);
        dev.transfer(DevFeeFinal);
        uint256 feedFee = msg.value.div(100).mul(OldDappFeed_);
        feed.transfer(feedFee);
        uint256 DailyInt1 = msg.value.div(100).mul(IntFee_);
        uint256 DailyIntFinal = SafeMath.div(DailyInt1, 10);
        InterestPool_ += DailyIntFinal;
        purchaseTokens(msg.value, 0x0);
    }
    
        function IDD() public {
        require(msg.sender==owner);
        uint256 Contract_Bal = SafeMath.sub((address(this).balance), InterestPool_);
        uint256 DailyInterest1 = SafeMath.div(SafeMath.mul(Contract_Bal, DailyInterest_), 100);   
        uint256 DailyInterestFinal = SafeMath.div(DailyInterest1, 100);
        InterestPool_ -= DailyInterestFinal;
        DividendsDistribution(DailyInterestFinal, 0x0);
     }
    
    function DivsAddon() public payable returns (uint256) {
        DividendsDistribution(msg.value, 0x0);
    }
    
    

        function reinvest() onlyStronghands public {
        uint256 _dividends = myDividends(false);
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(_dividends, 0x0);
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
        uint256 _tron = tokensToTron_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, exitFee()), 100);
        uint256 _devexit = SafeMath.div(SafeMath.mul(_tron, 8), 100);
        uint256 _taxedTron1 = SafeMath.sub(_tron, _dividends);
        uint256 _taxedTron = SafeMath.sub(_taxedTron1, _devexit);
        uint256 _devexitindividual = SafeMath.div(SafeMath.mul(_tron, DevFee_), 100);
        uint256 _devexitindividual_final = SafeMath.div(_devexitindividual, 10);
        uint256 feedFee = SafeMath.div(SafeMath.mul(_tron, OldDappFeed_), 100);
        uint256 DailyInt1 = SafeMath.div(SafeMath.mul(_tron, IntFee_), 100);
        uint256 DailyIntFinal = SafeMath.div(DailyInt1, 10);
        InterestPool_ += DailyIntFinal;
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        dev.transfer(_devexitindividual_final); 
        feed.transfer(feedFee);
        
        
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedTron * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        emit onTokenSell(_customerAddress, _tokens, _taxedTron, now, buyPrice());
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        if (myDividends(true) > 0) {
            withdraw();
        }

        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee_), 100);
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


    function totalTronBalance() public view returns (uint256) {
        return this.balance;
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
            uint256 _tron = tokensToTron_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, exitFee()), 100);
            uint256 _devexit = SafeMath.div(SafeMath.mul(_tron, 8), 100);
            uint256 _taxedTron1 = SafeMath.sub(_tron, _dividends);
            uint256 _taxedTron = SafeMath.sub(_taxedTron1, _devexit);
            return _taxedTron;
        }
    }

    function buyPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _tron = tokensToTron_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, entryFee_), 100);
            uint256 _devexit = SafeMath.div(SafeMath.mul(_tron, 8), 100);
            uint256 _taxedTron1 = SafeMath.add(_tron, _dividends);
            uint256 _taxedTron = SafeMath.add(_taxedTron1, _devexit);
            return _taxedTron;
        }
    }

    function calculateTokensReceived(uint256 _tronToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tronToSpend, entryFee_), 100);
        uint256 _devbuyfees = SafeMath.div(SafeMath.mul(_tronToSpend, 8), 100);
        uint256 _taxedTron1 = SafeMath.sub(_tronToSpend, _dividends);
        uint256 _taxedTron = SafeMath.sub(_taxedTron1, _devbuyfees);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        return _amountOfTokens;
    }

    function calculateTronReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _tron = tokensToTron_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, exitFee()), 100);
        uint256 _devexit = SafeMath.div(SafeMath.mul(_tron, 8), 100);
        uint256 _taxedTron1 = SafeMath.sub(_tron, _dividends);
        uint256 _taxedTron = SafeMath.sub(_taxedTron1, _devexit);
        return _taxedTron;
    }

   function exitFee() public view returns (uint8) {
        return ExitFee_;
    }
    


  function purchaseTokens(uint256 _incomingTron, address _referredBy) internal returns (uint256) {
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingTron, entryFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, refferalFee_), 100);
        uint256 _devbuyfees = SafeMath.div(SafeMath.mul(_incomingTron, 8), 100);
        uint256 _dividends1 = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _dividends = SafeMath.sub(_dividends1, _devbuyfees);
        uint256 _taxedTron = SafeMath.sub(_incomingTron, _undividedDividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
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
        emit onTokenPurchase(_customerAddress, _incomingTron, _amountOfTokens, _referredBy, now, buyPrice());

        return _amountOfTokens;
    }


       function DividendsDistribution(uint256 _incomingTron, address _referredBy) internal returns (uint256) {
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingTron, 100), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, refferalFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedTron = SafeMath.sub(_incomingTron, _undividedDividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens >= 0 && SafeMath.add(_amountOfTokens, tokenSupply_) >= tokenSupply_);

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
        emit onTokenPurchase(_customerAddress, _incomingTron, _amountOfTokens, _referredBy, now, buyPrice());

        return _amountOfTokens;
    }

    function tronToTokens_(uint256 _tron) internal view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
            (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                (_tokenPriceInitial ** 2)
                                +
                                (2 * (tokenPriceIncremental_ * 1e18) * (_tron * 1e18))
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

    function tokensToTron_(uint256 _tokens) internal view returns (uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
            (
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

      function setLaunchTime(uint256 _LaunchTime) public {
      require(msg.sender==owner);
      launchtime = _LaunchTime;
    }

    function updateDev(address _address)  {
       require(msg.sender==owner);
       dev = _address;
    }
    
    function updateFeed(address _address)  {
        require(msg.sender==owner);
        feed = _address;
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