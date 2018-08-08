pragma solidity ^0.4.18;

/*
*   CrowdSale DapCar (DAPX)
*   Created by Starlag Labs (www.starlag.com)
*   Copyright &#169; DapCar.io 2018. All rights reserved.
*   https://www.dapcar.io
*/

library Math {
    function mul(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Utils {
    function Utils() public {}

    modifier greaterThanZero(uint256 _value) 
    {
        require(_value > 0);
        _;
    }

    modifier validUint(uint256 _value) 
    {
        require(_value >= 0);
        _;
    }

    modifier validAddress(address _address) 
    {
        require(_address != address(0));
        _;
    }

    modifier notThis(address _address) 
    {
        require(_address != address(this));
        _;
    }

    modifier validAddressAndNotThis(address _address) 
    {
        require(_address != address(0) && _address != address(this));
        _;
    }

    modifier notEmpty(string _data)
    {
        require(bytes(_data).length > 0);
        _;
    }

    modifier stringLength(string _data, uint256 _length)
    {
        require(bytes(_data).length == _length);
        _;
    }
    
    modifier validBytes32(bytes32 _bytes)
    {
        require(_bytes != 0);
        _;
    }

    modifier validUint64(uint64 _value) 
    {
        require(_value >= 0 && _value < 4294967296);
        _;
    }

    modifier validUint8(uint8 _value) 
    {
        require(_value >= 0 && _value < 256);
        _;
    }

    modifier validBalanceThis(uint256 _value)
    {
        require(_value <= address(this).balance);
        _;
    }
}

contract Authorizable is Utils {
    using Math for uint256;

    address public owner;
    address public newOwner;
    mapping (address => Level) authorizeds;
    uint256 public authorizedCount;

    /*  
    *   ZERO 0 - bug for null object
    *   OWNER 1
    *   ADMIN 2
    *   DAPP 3
    */  
    enum Level {ZERO,OWNER,ADMIN,DAPP}

    event OwnerTransferred(address indexed _prevOwner, address indexed _newOwner);
    event Authorized(address indexed _address, Level _level);
    event UnAuthorized(address indexed _address);

    function Authorizable() 
    public 
    {
        owner = msg.sender;
        authorizeds[msg.sender] = Level.OWNER;
        authorizedCount = authorizedCount.add(1);
    }

    modifier onlyOwner {
        require(authorizeds[msg.sender] == Level.OWNER);
        _;
    }

    modifier onlyOwnerOrThis {
        require(authorizeds[msg.sender] == Level.OWNER || msg.sender == address(this));
        _;
    }

    modifier notOwner(address _address) {
        require(authorizeds[_address] != Level.OWNER);
        _;
    }

    modifier authLevel(Level _level) {
        require((authorizeds[msg.sender] > Level.ZERO) && (authorizeds[msg.sender] <= _level));
        _;
    }

    modifier authLevelOnly(Level _level) {
        require(authorizeds[msg.sender] == _level);
        _;
    }
    
    modifier notSender(address _address) {
        require(msg.sender != _address);
        _;
    }

    modifier isSender(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier checkLevel(Level _level) {
        require((_level > Level.ZERO) && (Level.DAPP >= _level));
        _;
    }

    function transferOwnership(address _newOwner) 
    public 
    {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) 
    onlyOwner 
    validAddress(_newOwner)
    notThis(_newOwner)
    internal 
    {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() 
    validAddress(newOwner)
    isSender(newOwner)
    public 
    {
        OwnerTransferred(owner, newOwner);
        if (authorizeds[owner] == Level.OWNER) {
            delete authorizeds[owner];
        }
        if (authorizeds[newOwner] > Level.ZERO) {
            authorizedCount = authorizedCount.sub(1);
        }
        owner = newOwner;
        newOwner = address(0);
        authorizeds[owner] = Level.OWNER;
    }

    function cancelOwnership() 
    onlyOwner
    public 
    {
        newOwner = address(0);
    }

    function authorized(address _address, Level _level) 
    public  
    {
        _authorized(_address, _level);
    }

    function _authorized(address _address, Level _level) 
    onlyOwner
    validAddress(_address)
    notOwner(_address)
    notThis(_address)
    checkLevel(_level)
    internal  
    {
        if (authorizeds[_address] == Level.ZERO) {
            authorizedCount = authorizedCount.add(1);
        }
        authorizeds[_address] = _level;
        Authorized(_address, _level);
    }

    function unAuthorized(address _address) 
    onlyOwner
    validAddress(_address)
    notOwner(_address)
    notThis(_address)
    public  
    {
        if (authorizeds[_address] > Level.ZERO) {
            authorizedCount = authorizedCount.sub(1);
        }
        delete authorizeds[_address];
        UnAuthorized(_address);
    }

    function isAuthorized(address _address) 
    validAddress(_address)
    notThis(_address)
    public 
    constant 
    returns (Level) 
    {
        return authorizeds[_address];
    }
}

contract IERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ITokenRecipient { function receiveApproval(address _spender, uint256 _value, address _token, bytes _extraData) public; }

contract ICouponToken {
    function updCouponConsumed(string _code, bool _consumed) public returns (bool success);
    function getCoupon(string _code) public view returns (uint256 bonus, 
        bool disposable, bool consumed, bool enabled);
}

contract IDapCarToken {
    function mint(address _address, uint256 _value) public returns (bool);
    function balanceOf(address _owner) public constant returns (uint balance);
}

contract IAirDropToken {
    function burnAirDrop(address[] _address) public;
    function balanceOf(address _owner) public constant returns (uint balance);
}

contract CrowdSaleDapCar is Authorizable {
    string public version = "0.1";
    string public publisher = "https://www.dapcar.io";
    string public description = "This is an official CrowdSale DapCar (DAPX)";

    address public walletWithdraw;
    IDapCarToken public dapCarToken;
    IAirDropToken public airDropToken;
    ICouponToken public couponToken;

    uint256 public weiRaised = 0;
    uint256 public soldToken = 0;
    uint256 public fundToken = 0;
    uint256 public weiDonated = 0;
    uint256 public minPurchaseLimit = 10 finney;

    bool public crowdSaleEnabled = true;
    bool public crowdSaleFinalized = false;
    bool public crowdSaleInitialized = false;

    bool public airDropTokenEnabled = true;
    bool public airDropTokenDestroy = true;
    bool public amountBonusEnabled = true;
    bool public couponBonusEnabled = true;

    mapping (uint8 => Rate) rates;

    mapping (address => Investor) investors;
    uint256 public investorCount;

    /*  
    *   ZERO 0 - bug for null object
    *   PRESALE 1
    *   PREICO 2
    *   ICO 3
    *   PRERELEASE 4
    */ 
    enum Period {ZERO,PRESALE,PREICO,ICO,PRERELEASE}

    struct Rate {
        Period period;
        uint256 rate;
        uint256 bonusAirDrop;
        uint64 start;
        uint64 stop;
        uint64 updated;
        bool enabled;
        bool initialized;
    }

    struct Investor {
        address wallet;
        uint256 bonus;
        uint64 updated;
        bool preSaleEnabled;
        bool enabled;
        bool initialized;
    }


    event Donate(address indexed sender, uint256 value);
    event WalletWithdrawChanged(address indexed sender, address indexed oldWallet, address indexed newWallet);
    event Withdraw(address indexed sender, address indexed wallet, uint256 amount);
    event WithdrawTokens(address indexed sender, address indexed wallet, address indexed token, uint256 amount);
    event ReceiveTokens(address indexed spender, address indexed token, uint256 value, bytes extraData);
    event RatePropsChanged(address indexed sender, uint8 period, string props, bool value);
    event RateChanged(address indexed sender, uint8 period, uint256 oldBonus, uint256 newBonus);
    event RateBonusChanged(address indexed sender, uint8 period, uint256 oldBonus, uint256 newBonus);
    event RateTimeChanged(address indexed sender, uint8 period, uint64 oldStart, uint64 oldStop, 
        uint64 newStart, uint64 newStop);
    event InvestorDeleted(address indexed sender, address indexed wallet);
    event InvestorPropsChanged(address indexed sender, address indexed wallet, string props, bool value);
    event InvestorBonusChanged(address indexed sender, address indexed wallet, uint256 oldBonus, uint256 newBonus);
    event InvestorCreated(address indexed sender, address indexed wallet, uint256 bonus);
    event Purchase(address indexed sender, uint256 amountWei, uint256 amountToken, uint256 totalBonus);
    event PropsChanged(address indexed sender, string props, bool oldValue, bool newValue);
    event MinPurchaseLimitChanged(address indexed sender, uint256 oldValu, uint256 newValue);
    event Finalized(address indexed sender, uint64 time, uint256 weiRaised, uint256 soldToken, 
        uint256 fundToken, uint256 weiDonated);

    modifier validPeriod(Period _period) 
    {
        require(_period > Period.ZERO && _period <= Period.PRERELEASE);
        _;
    }

    function CrowdSaleDapCar() public {
        crowdSalePeriodInit();
    }

    /*
    *   PRESALE: 1 DAPX = 1$
    *   Monday, 5 March 2018, 00:00:00 GMT - Sunday, 25 March 2018, 23:59:59 GMT
    *   PREICO: 1 DAPX = 2$
    *   Monday, 9 April 2018, 00:00:00 GMT - Sunday, 29 April 2018, 23:59:59 GMT
    *   ICO: 1 DAPX = 5$
    *   Monday, 7 May 2018, 00:00:00 GMT - Sunday, 17 June 2018, 23:59:59 GMT
    *   PRERELEASE: 1 DAPX = 10$
    *   Monday, 18 June 2018, 00:00:00 GMT - Sunday, 1 July 2018, 23:59:59 GMT
    *   RELEASE GAME: 1 DAPX = 1 DAPBOX >= 15$
    */
    
    function crowdSalePeriodInit()
    onlyOwnerOrThis
    public
    returns (bool success)
    {
        if (!crowdSaleInitialized) {
            Rate memory ratePreSale = Rate({
                period: Period.PRESALE,
                rate: 740,
                bonusAirDrop: 0,
                start: 1520208000,
                stop: 1522022399,
                updated: 0,
                enabled: true,
                initialized: true
            });
            rates[uint8(Period.PRESALE)] = ratePreSale;

            Rate memory ratePreIco = Rate({
                period: Period.PREICO,
                rate: 370,
                bonusAirDrop: 10,
                start: 1523232000,
                stop: 1525046399,
                updated: 0,
                enabled: true,
                initialized: true
            });
            rates[uint8(Period.PREICO)] = ratePreIco;

            Rate memory rateIco = Rate({
                period: Period.ICO,
                rate: 148,
                bonusAirDrop: 5,
                start: 1525651200,
                stop: 1529279999,
                updated: 0,
                enabled: true,
                initialized: true
            });
            rates[uint8(Period.ICO)] = rateIco;

            Rate memory ratePreRelease = Rate({
                period: Period.PRERELEASE,
                rate: 74,
                bonusAirDrop: 0,
                start: 1529280000,
                stop: 1530489599,
                updated: 0,
                enabled: true,
                initialized: true
            });
            rates[uint8(Period.PRERELEASE)] = ratePreRelease;
        
            crowdSaleInitialized = true;
            return true;
        } else {
            return false;
        }
    }

    function nowPeriod()
    public
    constant
    returns (Period)
    {
        uint64 now64 = uint64(now);
        Period period = Period.ZERO;
        for (uint8 i = 1; i <= uint8(Period.PRERELEASE); i++) {
            Rate memory rate = rates[i];
            if (!rate.initialized || !rate.enabled) { 
                continue; 
            }
            if (rate.start == 0 || rate.stop == 0 || rate.rate == 0) { 
                continue; 
            }
            
            if (now64 >= rate.start && now64 < rate.stop) {
                period = rate.period;
                break;
            }
        }

        return period;
    }

    function updCrowdSaleEnabled(bool _value)
    authLevel(Level.ADMIN)
    public
    returns (bool success)
    {
        PropsChanged(msg.sender, "crowdSaleEnabled", crowdSaleEnabled, _value);
        crowdSaleEnabled = _value;
        return true;
    }

    function updAirDropTokenEnabled(bool _value)
    authLevel(Level.ADMIN)
    public
    returns (bool success)
    {
        PropsChanged(msg.sender, "airDropTokenEnabled", airDropTokenEnabled, _value);
        airDropTokenEnabled = _value;
        return true;
    }

    function updAirDropTokenDestroy(bool _value)
    authLevel(Level.ADMIN)
    public
    returns (bool success)
    {
        PropsChanged(msg.sender, "airDropTokenDestroy", airDropTokenDestroy, _value);
        airDropTokenDestroy = _value;
        return true;
    }

    function updAmountBonusEnabled(bool _value)
    authLevel(Level.ADMIN)
    public
    returns (bool success)
    {
        PropsChanged(msg.sender, "amountBonusEnabled", amountBonusEnabled, _value);
        amountBonusEnabled = _value;
        return true;
    }

    function updCouponBonusEnabled(bool _value)
    authLevel(Level.ADMIN)
    public
    returns (bool success)
    {
        PropsChanged(msg.sender, "couponBonusEnabled", couponBonusEnabled, _value);
        couponBonusEnabled = _value;
        return true;
    }

    function updMinPurchaseLimit(uint256 _limit)
    authLevel(Level.ADMIN)
    validUint(_limit)
    public
    returns (bool success)
    {
        MinPurchaseLimitChanged(msg.sender, minPurchaseLimit, _limit);
        minPurchaseLimit = _limit;
        return true;
    }
    
    function getRate(Period _period)
    validPeriod(_period)
    public
    constant
    returns (uint256 rateValue, uint256 bonusAirDrop, uint64 start, uint64 stop, uint64 updated, bool enabled)
    {
        uint8 period = uint8(_period);
        Rate memory rate = rates[period];
        require(rate.initialized);

        return (rate.rate, rate.bonusAirDrop, rate.start, rate.stop, rate.updated, rate.enabled);
    }

    function updRate(Period _period, uint256 _rate)
    authLevel(Level.DAPP)
    validPeriod(_period)
    greaterThanZero(_rate)
    public
    returns (bool success)
    {
        uint8 period = uint8(_period);
        require(rates[period].initialized);

        RateChanged(msg.sender, period, rates[period].rate, _rate);
        rates[period].rate = _rate;
        rates[period].updated = uint64(now);
        return true;
    }

    function updRateBonusAirDrop(Period _period, uint256 _bonusAirDrop)
    authLevel(Level.DAPP)
    validPeriod(_period)
    validUint(_bonusAirDrop)
    public
    returns (bool success)
    {
        uint8 period = uint8(_period);
        require(rates[period].initialized);

        RateBonusChanged(msg.sender, period, rates[period].bonusAirDrop, _bonusAirDrop);
        rates[period].bonusAirDrop = _bonusAirDrop;
        rates[period].updated = uint64(now);
        return true;
    }

    function updRateTimes(Period _period, uint64 _start, uint64 _stop)
    authLevel(Level.ADMIN)
    validPeriod(_period)
    validUint64(_start)
    validUint64(_stop)
    public
    returns (bool success)
    {
        require(_start < _stop);
        uint8 period = uint8(_period);
        require(rates[period].initialized);

        RateTimeChanged(msg.sender, period, rates[period].start, rates[period].stop, _start, _stop);
        rates[period].start = _start;
        rates[period].stop = _stop;
        rates[period].updated = uint64(now);
        return true;
    }

    function updRateEnabled(Period _period, bool _enabled)
    authLevel(Level.ADMIN)
    validPeriod(_period)
    public
    returns (bool success)
    {
        uint8 period = uint8(_period);
        require(rates[period].initialized);

        rates[period].enabled = _enabled;
        rates[period].updated = uint64(now);
        RatePropsChanged(msg.sender, period, "enabled", _enabled);
        return true;
    }

    function setInvestor(address _wallet, uint256 _bonus)
    authLevel(Level.ADMIN)
    validAddress(_wallet)
    notThis(_wallet)
    validUint(_bonus)
    public
    returns (bool success)
    {
        uint64 now64 = uint64(now);
        if (investors[_wallet].initialized) {
            InvestorBonusChanged(msg.sender, _wallet, investors[_wallet].bonus, _bonus);
            investors[_wallet].bonus = _bonus;
            investors[_wallet].updated = now64;
        } else {
            Investor memory investor = Investor({
                wallet: _wallet,
                bonus: _bonus,
                updated: now64,
                preSaleEnabled: false,
                enabled: true,
                initialized: true
            });
            investors[_wallet] = investor;
            investorCount = investorCount.add(1);
            InvestorCreated(msg.sender, _wallet, _bonus);
        }

        return true;
    }

    function updInvestorEnabled(address _wallet, bool _enabled)
    authLevel(Level.ADMIN)
    validAddress(_wallet)
    notThis(_wallet)
    public
    returns (bool success)
    {
        require(investors[_wallet].initialized);

        investors[_wallet].enabled = _enabled;
        investors[_wallet].updated = uint64(now);
        InvestorPropsChanged(msg.sender, _wallet, "enabled", _enabled);
        return true;
    }

    function updInvestorPreSaleEnabled(address _wallet, bool _preSaleEnabled)
    authLevel(Level.ADMIN)
    validAddress(_wallet)
    notThis(_wallet)
    public
    returns (bool success)
    {
        require(investors[_wallet].initialized);

        investors[_wallet].preSaleEnabled = _preSaleEnabled;
        investors[_wallet].updated = uint64(now);
        InvestorPropsChanged(msg.sender, _wallet, "preSaleEnabled", _preSaleEnabled);
        return true;
    }

    function delInvestor(address _wallet)
    authLevel(Level.ADMIN)
    validAddress(_wallet)
    notThis(_wallet)
    public
    returns (bool success)
    {
        require(investors[_wallet].initialized);

        delete investors[_wallet];
        investorCount = investorCount.sub(1);
        InvestorDeleted(msg.sender, _wallet);
        return true;
    }

    function getInvestor(address _wallet)
    validAddress(_wallet)
    notThis(_wallet)
    public
    constant
    returns (uint256 bonus, uint64 updated, bool preSaleEnabled, bool enabled)
    {
        Investor memory investor = investors[_wallet];
        require(investor.initialized);

        return (investor.bonus,
            investor.updated,
            investor.preSaleEnabled,
            investor.enabled);
    }

    function setWalletWithdraw(address _wallet)
    onlyOwner
    notThis(_wallet)
    public
    returns (bool success)
    {
        WalletWithdrawChanged(msg.sender, walletWithdraw, _wallet);
        walletWithdraw = _wallet;
        return true;
    }

    function setDapCarToken(address _token)
    authLevel(Level.ADMIN)
    validAddress(_token)
    notThis(_token)
    notOwner(_token)
    public
    returns (bool success)
    {
        dapCarToken = IDapCarToken(_token);
        return true;
    }

    function setCouponToken(address _token)
    authLevel(Level.ADMIN)
    validAddress(_token)
    notThis(_token)
    notOwner(_token)
    public
    returns (bool success)
    {
        couponToken = ICouponToken(_token);
        return true;
    }

    function setAirDropToken(address _token)
    authLevel(Level.ADMIN)
    validAddress(_token)
    notThis(_token)
    notOwner(_token)
    public
    returns (bool success)
    {
        airDropToken = IAirDropToken(_token);
        return true;
    }

    function balanceAirDropToken(address _address)
    validAddress(_address)
    notOwner(_address)
    public
    view
    returns (uint256 balance)
    {
        if (address(airDropToken) != 0) {
            return airDropToken.balanceOf(_address);
        } else {
            return 0;
        }
    }

    function donate() 
    internal 
    {
        if (msg.value > 0) {
            weiDonated = weiDonated.add(msg.value);
            Donate(msg.sender, msg.value);
            if (walletWithdraw != address(0)) {
                walletWithdraw.transfer(msg.value);
            }
        }
	}

    function withdrawTokens(address _token, uint256 _amount)
    authLevel(Level.ADMIN)
    validAddress(_token)
    notOwner(_token)
    notThis(_token)
    greaterThanZero(_amount)
    public 
    returns (bool success) 
    {
        address wallet = walletWithdraw;
        if (wallet == address(0)) {
            wallet = msg.sender;
        }

        bool result = IERC20(_token).transfer(wallet, _amount);
        if (result) {
            WithdrawTokens(msg.sender, wallet, _token, _amount);
        }
        return result;
    }

    function withdraw() 
    public 
    returns (bool success)
    {
        return withdrawAmount(address(this).balance);
    }

    function withdrawAmount(uint256 _amount) 
    authLevel(Level.ADMIN) 
    greaterThanZero(address(this).balance)
    greaterThanZero(_amount)
    validBalanceThis(_amount)
    public 
    returns (bool success)
    {
        address wallet = walletWithdraw;
        if (wallet == address(0)) {
            wallet = msg.sender;
        }

        Withdraw(msg.sender, wallet, _amount);
        wallet.transfer(_amount);
        return true;
    }

    function balanceToken(address _token)
    validAddress(_token)
    notOwner(_token)
    notThis(_token)
    public 
    constant
    returns (uint256 amount) 
    {
        return IERC20(_token).balanceOf(address(this));
    }

    function getCouponBonus(string _code)
    internal
    view
    returns (uint256) 
    {
        uint bonus = 0;
        if (couponToken == address(0) || bytes(_code).length != 8) {
            return bonus;
        }

        bool disposable;
        bool consumed;
        bool enabled;
        (bonus, disposable, consumed, enabled) = couponToken.getCoupon(_code);

        if (enabled && (!disposable || (disposable && !consumed))) { 
            return bonus;
        } else {
            return 0;
        }
    }

    function updCouponBonusConsumed(string _code, bool _consumed)
    internal
    returns (bool success) 
    {
        if (couponToken == address(0) || bytes(_code).length != 8) {
            return false;
        }
        return couponToken.updCouponConsumed(_code, _consumed);
    }

    function purchase()
    notThis(msg.sender)
    greaterThanZero(msg.value)
    internal
    {
        Period period = nowPeriod();
        if (crowdSaleFinalized || !crowdSaleEnabled || period == Period.ZERO || msg.value <= minPurchaseLimit) {
            donate();
        } else if (dapCarToken == address(0)) {
            donate();
        } else {
            Rate memory rate = rates[uint8(period)];
            Investor memory investor = investors[msg.sender];
            uint256 bonus = 0;
            if (period == Period.PRESALE) {
                if (!investor.preSaleEnabled) {
                    donate();
                    return;
                } 
            }
            if (investor.enabled) {
                if (investor.bonus > 0) {
                    bonus = bonus.add(investor.bonus);
                }
            }
            if (msg.data.length == 8) {
                uint256 bonusCoupon = getCouponBonus(string(msg.data));
                if (bonusCoupon > 0 && updCouponBonusConsumed(string(msg.data), true)) {
                    bonus = bonus.add(bonusCoupon);
                }
            }
            if (airDropTokenEnabled) {
                if (balanceAirDropToken(msg.sender) > 0) {
                    bonus = bonus.add(rate.bonusAirDrop);
                    if (airDropTokenDestroy && address(airDropToken) != 0) {
                        address[] memory senders = new address[](1);
                        senders[0] = msg.sender;
                        airDropToken.burnAirDrop(senders);
                    }
                }
            }
            if (amountBonusEnabled) {
                if (msg.value >= 5 ether && msg.value < 10 ether) {
                    bonus = bonus.add(5);
                } else if (msg.value >= 10 ether && msg.value < 50 ether) {
                    bonus = bonus.add(10);
                } else if (msg.value >= 50 ether) {
                    bonus = bonus.add(15);
                }
            }
            
            uint256 purchaseToken = rate.rate.mul(1 ether).mul(msg.value).div(1 ether).div(1 ether);
            if (bonus > 0) {
                purchaseToken = purchaseToken.add(purchaseToken.mul(bonus).div(100));
            }

            if (walletWithdraw != address(0)) {
                walletWithdraw.transfer(msg.value);
            }

            dapCarToken.mint(msg.sender, purchaseToken);
            Purchase(msg.sender, msg.value, purchaseToken, bonus);

            weiRaised = weiRaised.add(msg.value);
            soldToken = soldToken.add(purchaseToken);
        }
    }

    function () 
    notThis(msg.sender)
    greaterThanZero(msg.value)
    external 
    payable 
    {
        purchase();
	}

    function receiveApproval(address _spender, uint256 _value, address _token, bytes _extraData)
    validAddress(_spender)
    validAddress(_token)
    greaterThanZero(_value)
    public 
    {
        IERC20 token = IERC20(_token);
        require(token.transferFrom(_spender, address(this), _value));
        ReceiveTokens(_spender, _token, _value, _extraData);
    }

    function finalize()
    onlyOwner
    public
    returns (bool success)
    {
        return finalization();
    }

    function finalization()
    internal
    returns (bool success)
    {
        if (address(this).balance > 0) {
            address wallet = walletWithdraw;
            if (wallet == address(0)) {
                wallet = owner;
            }

            Withdraw(msg.sender, wallet, address(this).balance);
            wallet.transfer(address(this).balance);
        }

        //42% for Team, Advisor, Bounty, Reserve and Charity funds.
        fundToken = soldToken.mul(42).div(100);
        dapCarToken.mint(walletWithdraw, fundToken);

        Finalized(msg.sender, uint64(now), weiRaised, soldToken, fundToken, weiDonated);
        crowdSaleFinalized = true;
        return true;
    }

    function kill() 
    onlyOwner 
    public 
    { 
        if (crowdSaleFinalized) {
            selfdestruct(owner);
        }
    }

}