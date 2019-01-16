pragma solidity ^0.4.25;

/*
* https://ectoken.io
*
* Ethereum Captial Token concept
*
* [✓] 6% Withdraw fee (3% to dividends, 3% to owner). First 6 days 30%, next 24 days it will decrease to 6%
* [✓] 12% Deposit fee
* [✓] 1% Token transfer
* [✓] 5 lines referral system with 5 levels of rewards
*
*/

contract ECT {

    /**
     * Only with tokens
     */
    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

    /**
     * Only with dividends
     */
    modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
    }

    event onTokenPurchase(
        address indexed customerAddress,
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
        uint256 ethereumReinvested
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

    string public name = "Ethereum Capital Token";
    string public symbol = "ECT";
    uint public createdAt;
    
    bool public started = false;
    modifier onlyStarted {
        require(started);
        _;
    }
    modifier onlyNotStarted {
        require(!started);
        _;
    }

    uint8 constant public decimals = 18;

    /**
     * fees
     */
    uint8 constant internal entryFee_ = 12;
    uint8 constant internal ownerFee_ = 4;
    uint8 constant internal transferFee_ = 1;
    uint8 constant internal exitFeeD0_ = 30;
    uint8 constant internal exitFee_ = 6;
    uint8 constant internal refferalFee_ = 33;

    address internal _ownerAddress;

    /**
     * Initial token values
     */
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;

    uint256 constant internal magnitude = 2 ** 64;


    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal summaryReferralProfit_;
    mapping(address => uint256) internal dividendsUsed_;

    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    
    uint public blockCreation;
    
    /**
     * Admins. Only rename tokens, change referral settings and add new admins
     */
    mapping(bytes32 => bool) public administrators;
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[keccak256(_customerAddress)]);
        _;
    }

    function isAdmin() public view returns (bool) {
        return administrators[keccak256(msg.sender)];
    }

    function setAdministrator(address _id, bool _status)
        onlyAdministrator()
        public
    {
        if (_id != _ownerAddress) {
            administrators[keccak256(_id)] = _status;
        }
    } 

    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }

    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

    constructor() public {
        _ownerAddress = msg.sender;
        administrators[keccak256(_ownerAddress)] = true;
        blockCreation = block.number;
    }
    
    function start() onlyNotStarted() onlyAdministrator() public {
        started = true;
        createdAt = block.timestamp;
    }
    
    function getLifetime() public view returns (uint8) {
        if (!started)
        {
            return 0;
        }
        return (uint8) ((now - createdAt) / 60 / 60 / 24);
    }
    
    function getExitFee() public view returns (uint8) {
        uint lifetime = getLifetime(); // Получение времени жизни контракта
        if (lifetime <= 6) { 
            return exitFeeD0_; // 30%
        } else if (lifetime < 30) {
            return (uint8) (exitFeeD0_ - lifetime + 6);
        } else {
            return exitFee_; // 6%
        }
    }

    function buy(address _r1, address _r2, address _r3, address _r4, address _r5) onlyStarted() public payable returns (uint256) {
        purchaseTokens(msg.value, _r1, _r2, _r3, _r4, _r5);
    }

    function reinvest() onlyStronghands public {
        uint256 _dividends = myDividends(false);
        address _customerAddress = msg.sender;
        dividendsUsed_[_customerAddress] += _dividends;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        purchaseTokens(_dividends, 0x0, 0x0, 0x0, 0x0, 0x0);
        emit onReinvestment(_customerAddress, _dividends);
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
        dividendsUsed_[_customerAddress] += _dividends;
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        uint256 _fee = SafeMath.div(SafeMath.mul(_dividends, getExitFee() - 3), 100);
        
        uint256 _ownerFee = SafeMath.div(SafeMath.mul(_dividends, 3), 100);
        
        uint256 _dividendsTaxed = SafeMath.sub(_dividends, _fee + _ownerFee);
        
        if (_customerAddress != _ownerAddress) {
            referralBalance_[_ownerAddress] += _ownerFee;
            summaryReferralProfit_[_ownerAddress] += _ownerFee;
        } else {
            _dividendsTaxed += _ownerFee;
        }
        
        profitPerShare_ = SafeMath.add(profitPerShare_, (_fee * magnitude) / tokenSupply_);
    
        _customerAddress.transfer(_dividendsTaxed);
        emit onWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) onlyBagholders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_ethereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        emit onTokenSell(_customerAddress, _tokens, _ethereum, now, buyPrice());
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
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }
    
    function dividendsFull(address _customerAddress) public view returns (uint256) {
        return dividendsOf(_customerAddress) + dividendsUsed_[_customerAddress] + summaryReferralProfit_[_customerAddress];
    }

    function sellPrice() public view returns (uint256) {
        return sellPriceAt(tokenSupply_);
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

    function calculateTokensReceived(uint256 _incomingEthereum) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
        
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);

        return _amountOfTokens;
    }

    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        return tokensToEthereum_(_tokensToSell);
    }
    
    uint256 public I_S = 0.25 ether;
    uint256 public I_R1 = 30;

    function setI_S(uint256 _v)
        onlyAdministrator()
        public
    {
        I_S = _v;
    }

    function setI_R1(uint256 _v)
        onlyAdministrator()
        public
    {
        I_R1 = _v;
    }

    
    uint256 public II_S = 5 ether;
    uint256 public II_R1 = 30;
    uint256 public II_R2 = 10;

    function setII_S(uint256 _v)
        onlyAdministrator()
        public
    {
        II_S = _v;
    }

    function setII_R1(uint256 _v)
        onlyAdministrator()
        public
    {
        II_R1 = _v;
    }

    function setII_R2(uint256 _v)
        onlyAdministrator()
        public
    {
        II_R2 = _v;
    }
    
    uint256 public III_S = 10 ether;
    uint256 public III_R1 = 30;
    uint256 public III_R2 = 10;
    uint256 public III_R3 = 10;

    function setIII_S(uint256 _v)
        onlyAdministrator()
        public
    {
        III_S = _v;
    }

    function setIII_R1(uint256 _v)
        onlyAdministrator()
        public
    {
        III_R1 = _v;
    }

    function setIII_R2(uint256 _v)
        onlyAdministrator()
        public
    {
        III_R2 = _v;
    }

    function setIII_R3(uint256 _v)
        onlyAdministrator()
        public
    {
        III_R3 = _v;
    }
    
    uint256 public IV_S = 20 ether;
    uint256 public IV_R1 = 30;
    uint256 public IV_R2 = 20;
    uint256 public IV_R3 = 10;
    uint256 public IV_R4 = 10;

    function setIV_S(uint256 _v)
        onlyAdministrator()
        public
    {
        IV_S = _v;
    }

    function setIV_R1(uint256 _v)
        onlyAdministrator()
        public
    {
        IV_R1 = _v;
    }

    function setIV_R2(uint256 _v)
        onlyAdministrator()
        public
    {
        IV_R2 = _v;
    }

    function setIV_R3(uint256 _v)
        onlyAdministrator()
        public
    {
        IV_R3 = _v;
    }

    function setIV_R4(uint256 _v)
        onlyAdministrator()
        public
    {
        IV_R4 = _v;
    }
    
    uint256 public V_S = 100 ether;
    uint256 public V_R1 = 40;
    uint256 public V_R2 = 20;
    uint256 public V_R3 = 10;
    uint256 public V_R4 = 10;
    uint256 public V_R5 = 10;

    function setV_S(uint256 _v)
        onlyAdministrator()
        public
    {
        V_S = _v;
    }

    function setV_R1(uint256 _v)
        onlyAdministrator()
        public
    {
        V_R1 = _v;
    }

    function setV_R2(uint256 _v)
        onlyAdministrator()
        public
    {
        V_R2 = _v;
    }

    function setV_R3(uint256 _v)
        onlyAdministrator()
        public
    {
        V_R3 = _v;
    }

    function setV_R4(uint256 _v)
        onlyAdministrator()
        public
    {
        V_R4 = _v;
    }

    function setV_R5(uint256 _v)
        onlyAdministrator()
        public
    {
        V_R5 = _v;
    }
    
    function canRef(address _r, address _c, uint256 _m) internal returns (bool) {
        return _r != 0x0000000000000000000000000000000000000000 && _r != _c && tokenBalanceLedger_[_r] >= _m;
    }
    
    function etherBalance(address r) internal returns (uint256) {
        uint _v = tokenBalanceLedger_[r];
        if (_v < 0.00000001 ether) {
            return 0;
        } else {
            return tokensToEthereum_(_v);
        }
    }
    
    function getLevel(address _cb) public view returns (uint256) {
        uint256 _b = etherBalance(_cb);
        uint256 _o = 0;
        
        if (_b >= V_S) {
            _o = 5;
        } else if (_b >= IV_S) {
            _o = 4;
        } else if (_b >= III_S) {
            _o = 3;
        } else if (_b >= II_S) {
            _o = 2;
        } else if (_b >= I_S) {
            _o = 1;
        }
        
        return _o;
    }

    function purchaseTokens(uint256 _incomingEthereum, address _r1, address _r2, address _r3, address _r4, address _r5) internal {
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
        uint256 _dividends = _undividedDividends;

        uint256 __bC = 0;
        uint256 _b = 0;
        
        if (canRef(_r1, msg.sender, I_S)) {
            __bC = I_R1;

            if (etherBalance(_r1) >= V_S) {
                __bC = V_R1;
            } else if (etherBalance(_r1) >= IV_S) {
                __bC = IV_R1;
            } else if (etherBalance(_r1) >= III_S) {
                __bC = III_R1;
            } else if (etherBalance(_r1) >= II_S) {
                __bC = II_R1;
            }
            
            _b = SafeMath.div(SafeMath.mul(_incomingEthereum, __bC), 1000);
            referralBalance_[_r1] = SafeMath.add(referralBalance_[_r1], _b);
            addReferralProfit(_r1, msg.sender, _b);
            _dividends = SafeMath.sub(_dividends, _b);
        }
        
        if (canRef(_r2, msg.sender, II_S)) {
            __bC = II_R2;

            if (etherBalance(_r2) >= V_S) {
                __bC = V_R2;
            } else if (etherBalance(_r2) >= IV_S) {
                __bC = IV_R2;
            } else if (etherBalance(_r2) >= III_S) {
                __bC = III_R2;
            }
            
            _b = SafeMath.div(SafeMath.mul(_incomingEthereum, __bC), 1000);
            referralBalance_[_r2] = SafeMath.add(referralBalance_[_r2], _b);
            addReferralProfit(_r2, _r1, _b);
            _dividends = SafeMath.sub(_dividends, _b);
        }
        
        if (canRef(_r3, msg.sender, III_S)) {
            __bC = III_R3;

            if (etherBalance(_r3) >= V_S) {
                __bC = V_R3;
            } else if (etherBalance(_r3) >= IV_S) {
                __bC = IV_R3;
            }
            
            _b = SafeMath.div(SafeMath.mul(_incomingEthereum, __bC), 1000);
            referralBalance_[_r3] = SafeMath.add(referralBalance_[_r3], _b);
            addReferralProfit(_r3, _r2, _b);
            _dividends = SafeMath.sub(_dividends, _b);
        }
        
        if (canRef(_r4, msg.sender, IV_S)) {
            __bC = IV_R4;

            if (etherBalance(_r4) >= V_S) {
                __bC = V_R4;
            }
            
            _b = SafeMath.div(SafeMath.mul(_incomingEthereum, __bC), 1000);
            referralBalance_[_r4] = SafeMath.add(referralBalance_[_r4], _b);
            addReferralProfit(_r4, _r3, _b);
            _dividends = SafeMath.sub(_dividends, _b);
        }
        
        if (canRef(_r5, msg.sender, V_S)) {
            _b = SafeMath.div(SafeMath.mul(_incomingEthereum, V_R5), 1000);
            referralBalance_[_r5] = SafeMath.add(referralBalance_[_r5], _b);
            addReferralProfit(_r5, _r4, _b);
            _dividends = SafeMath.sub(_dividends, _b);
        }

        uint256 _amountOfTokens = ethereumToTokens_(SafeMath.sub(_incomingEthereum, _undividedDividends));
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        if (tokenSupply_ > 0) {
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[msg.sender] = SafeMath.add(tokenBalanceLedger_[msg.sender], _amountOfTokens);
        payoutsTo_[msg.sender] += (int256) (profitPerShare_ * _amountOfTokens - _fee);
        emit onTokenPurchase(msg.sender, _incomingEthereum, _amountOfTokens, now, buyPrice());
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

    function sellPriceAt(uint256 _atSupply) public view returns (uint256) {
        if (_atSupply == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereumAtSupply_(1e18, _atSupply);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
 
            return _taxedEthereum;
        }
    }
   
    function tokensToEthereum_(uint256 _tokens) internal view returns (uint256) {
        return tokensToEthereumAtSupply_(_tokens, tokenSupply_);
    }
 
    function tokensToEthereumAtSupply_(uint256 _tokens, uint256 _atSupply) public view returns (uint256) {
        if (_tokens < 0.00000001 ether) {
            return 0;
        }
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (_atSupply + 1e18);
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
    
    mapping(address => mapping(address => uint256)) internal referralProfit_;
    
    function addReferralProfit(address _referredBy, address _referral, uint256 _profit) internal {
        referralProfit_[_referredBy][_referral] += _profit;
        summaryReferralProfit_[_referredBy] += _profit;
    }
    
    function getReferralProfit(address _referredBy, address _referral) public view returns (uint256) {
        return referralProfit_[_referredBy][_referral];
    }
    
    function getSummaryReferralProfit(address _referredBy) public view returns (uint256) {
        if (_ownerAddress == _referredBy) {
            return 0;
        } else {
            return summaryReferralProfit_[_referredBy];
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