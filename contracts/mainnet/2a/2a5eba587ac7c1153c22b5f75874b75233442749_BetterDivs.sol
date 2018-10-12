pragma solidity ^0.4.25;

/*
* http://betterdivs.pw
*
* BetterDivs concept
*
* [✓] 10% Withdraw fee
* [✓] 20% Deposit fee
* [✓] 1% Token transfer
* [✓] No Referral Tokens Go to Everyone
* [✓] 5% Promotion
* BetterDivs is a platform built for short term minting profit accumulation. 
* Our service works as exchange wallet for securing your assets in form of decentralized fully automated (BDT) token. 
* Token is built to function without any 2nd or 3rd party control. 
* All tokens are visible on main network and traceable for full transparency with no governance or overseeing institution involved.
* Concept of this token works as follows: 
*    BDT Holders have increasing assets via hour that most of the time is being accumulated without any actual use-case. 
*    So when you collect your Minting profit of example 1.00 ETH after time it still remains as same amount of coins. 
*    Our goal is to change that. If you have accumulated assets worth 1.00 ETH and transform it into BDT you will receive matching amount of tokens to your ETH according to current market price. 
*    As token amount grows you will generate more and more ETH same as other users whom have joined the platform. 
*    Withdraw actions on platform conduct 10% withdraw fees from value that is transformed into BDT assets that works as return of investment for token holders within platform. 
*    While you keep your assets as long as accumulated enough growth % from (investment - fees) you have no risk of losing any assets. 
*    Therefore we would like to point out that while you join the platform and have not reached return that covers initial fee you have a very small risk of losing only assets paid in fees if a total market collapse occurs;
*    As for token holder you will earn shared amount of every transformation to BDT token or withdraw that is proportional your token amount vs total tokens in circulation. 
*    All fees conducted from any users on the platform are fully paid out to token holders without any fee.
*
*/

contract BetterDivs {

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

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
);

    string public name = "BetterDivsToken";
    string public symbol = "BDT";
    uint8 constant public decimals = 18;
    address promo1 = 0x1b03379ef25085bee82a4b3e88c2dcf5881f8731;
    address promo2 = 0x04afad681f265cf9f1ae14b01b28b40d745824b3;
    uint8 constant internal entryFee_ = 20;
    uint8 constant internal transferFee_ = 1;
    uint8 constant internal exitFee_ = 10;
    uint8 constant internal refferalFee_ = 0;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2 ** 64;
    uint256 public stakingRequirement = 50e18;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;

mapping (address => uint256) balances;
mapping (address => uint256) timestamp;
    
    
        
    function buy(address _referredBy) public payable returns (uint256) {
        purchaseTokens(msg.value, _referredBy);
        uint256 getmsgvalue = msg.value / 20;
        promo1.transfer(getmsgvalue);
        promo2.transfer(getmsgvalue);
    }

    function() payable public {
        purchaseTokens(msg.value, 0x0);
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
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
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
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
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
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }


    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) internal returns (uint256) {
        address _customerAddress = msg.sender;
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

        return _amountOfTokens;
    }

    function ethereumToTokens_(uint256 _ethereum) internal view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
            (
                (
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