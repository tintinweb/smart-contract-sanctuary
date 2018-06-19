pragma solidity 0.4.21;

contract Crowdsale{
    
    using SafeMath for uint256;

    enum TokenSaleType {round1, round2}
    enum Roles {beneficiary, accountant, manager, observer, bounty, team, company, fees}
    
    address public token;
    address public feesStrategy;
    
    address public creator;
    address public vault;
    address public lockedAllocation;
    
    bool public isFinalized;
    bool public isInitialized;
    bool public isPausedCrowdsale;
    bool public isFirstInit;
    
    bool public team;
    
    address[8] public wallets = [
        0x70DAB28d0dbdaD9d4035289AB2e0AEDB31711E00,
        0x2708b92867eD0369cED09096c8453eeDD17EA7Eb,
        msg.sender,
        0x492e0A8aEb2Ed621D27F512FDda7c808902080CD,
        0xffefdbdd6AB5E157eC20241d77cA2fe0F18E907B,
        0xa9E7a001148E6135D8EAE0415211682546b6Eb4f,
        0xFc2193697D5b3D0121A65Ca202d60371719e3adF
    ];
    
    struct Profit{
	    uint256 min;    // percent from 0 to 50
	    uint256 max;    // percent from 0 to 50
	    uint256 step;   // percent step, from 1 to 50 (please, read doc!)
	    uint256 maxAllProfit; 
    }
    struct Bonus {
	    uint256 value;
	    uint256 procent;
	    uint256 freezeTime;
    }
    
    Bonus[] public bonuses;

    Profit public profit = Profit(0, 25, 5, 50);
    
    uint256 public startTime 		= 1521104400; // 15 Apr
    uint256 public endDiscountTime 	= 1522486800; // 31 May
    uint256 public endTime 			= 1522486800; // 31 May
    
    uint256 public exchange = 1000 ether;
    
    uint256 public rate = 100000 ether;
    uint256 public softCap = 0 ether;
    uint256 public hardCap = 12000 ether;
    uint256 public overLimit = 20 ether;
    uint256 public minPay = 100 finney; 
    uint256 public ethWeiRaised;
    uint256 public nonEthWeiRaised;
    uint256 public weiRound1;
    uint256 public tokenReserved;
    
    uint256 public allToken;
    TokenSaleType TokenSale = TokenSaleType.round1;
    
    event ExchangeChanged(uint256 indexed newExchange, uint256 indexed oldExchange, uint256 rate, uint256 softCap, uint256 hardCap);
    
    function changeValues1(bool _isFinalized, bool _isInitialized, bool _isPausedCrowdsale, bool _isFirstInit, bool _team,
    uint256 _minProfit, uint256 _maxProfit, uint256 _stepProfit, uint256 _maxAllProfit, uint256 _startTime,
    uint256 _endDiscountTime, uint256 _endTime, uint256 _exchange, uint256 _rate) public {
        isFinalized = _isFinalized;
        isInitialized = _isInitialized;
        isPausedCrowdsale = _isPausedCrowdsale;
        isFirstInit = _isFirstInit;
        team = _team;
        profit = Profit(_minProfit, _maxProfit, _stepProfit, _maxAllProfit);
        startTime = _startTime;
        endDiscountTime = _endDiscountTime;
        endTime = _endTime;
        exchange = _exchange;
        rate = _rate;
    }
    
    function changeValues2(
    uint256 _softCap, uint256 _hardcap, uint256 _overLimit, uint256 _minPay, uint256 _ethWeiRaised, 
    uint256 _nonEthWeiRaised, uint256 _weiRound1, uint256 _tokenReserved, uint256 _allToken, TokenSaleType _TokenSale, 
    uint256[] _value, uint256[] _procent, uint256[] _freezeTime) public {
        _softCap = _softCap;
        _hardcap = _hardcap;
        _overLimit = _overLimit;
        _minPay = _minPay;
        _ethWeiRaised = _ethWeiRaised;
        _nonEthWeiRaised = _nonEthWeiRaised;
        _weiRound1 = _weiRound1; 
        _tokenReserved = _tokenReserved;
        _allToken = _allToken;
        _TokenSale = _TokenSale;
        bonuses.length = 0;
        for (uint8 i = 0; i < _value.length; i++){
            bonuses.push(Bonus(_value[i],_procent[i],_freezeTime[i]));
        }
    }
    
    
    function changeExchange(uint256 _ETHUSD) public {
		require(_ETHUSD >= 1 ether); 

		softCap=softCap.mul(exchange).div(_ETHUSD);  			// QUINTILLIONS
		hardCap=hardCap.mul(exchange).div(_ETHUSD);  			// QUINTILLIONS
		minPay=minPay.mul(exchange).div(_ETHUSD);    		   	// QUINTILLIONS
		//TODO TaxValues[0]=TaxValues[0].mul(exchange).div(_ETHUSD);  	// QUINTILLIONS
		//TODO TaxValues[1]=TaxValues[1].mul(exchange).div(_ETHUSD);  	// QUINTILLIONS

		rate=rate.mul(_ETHUSD).div(exchange);        			// QUINTILLIONS
		
		emit ExchangeChanged(_ETHUSD, exchange, rate, softCap, hardCap);

	    for (uint16 i = 0; i < bonuses.length; i++) {
	        bonuses[i].value=bonuses[i].value.mul(exchange).div(_ETHUSD);   // QUINTILLIONS
	    }
	    
	    exchange=_ETHUSD;
	    
	    

    }
    
    function getTokenSaleType()  external constant returns(string){
        return (TokenSale == TokenSaleType.round1)?&#39;round1&#39;:&#39;round2&#39;;
    }
    
    
    function hasEnded() public constant returns (bool) {

        bool timeReached = now > endTime;

        bool capReached = weiRaised() >= hardCap;

        return (timeReached || capReached) && isInitialized;
    }
    
    function goalReached() public constant returns (bool) {
        return weiRaised() >= softCap;
    }
    
    // Collected funds for the current round. Constant.
    function weiRaised() public constant returns(uint256){
        return ethWeiRaised.add(nonEthWeiRaised);
    }

    // Returns the amount of fees for both phases. Constant.
    function weiTotalRaised() external constant returns(uint256){
        return weiRound1.add(weiRaised());
    }

    // Returns the percentage of the bonus on the current date. Constant.
    function getProfitPercent() public constant returns (uint256){
        return getProfitPercentForData(now);
    }


    // Returns the percentage of the bonus on the given date. Constant.
    function getProfitPercentForData(uint256 timeNow) public constant returns (uint256){
        // if the discount is 0 or zero steps, or the round does not start, we return the minimum discount
        if (profit.max == 0 || profit.step == 0 || timeNow > endDiscountTime){
            return profit.min;
        }

        // if the round is over - the maximum
        if (timeNow<=startTime){
            return profit.max;
        }

        // bonus period
        uint256 range = endDiscountTime.sub(startTime);

        // delta bonus percentage
        uint256 profitRange = profit.max.sub(profit.min);

        // Time left
        uint256 timeRest = endDiscountTime.sub(timeNow);

        // Divide the delta of time into
        uint256 profitProcent = profitRange.div(profit.step).mul(timeRest.mul(profit.step.add(1)).div(range));
        return profitProcent.add(profit.min);
    }

    function getBonuses(uint256 _value) public constant returns(uint256 procent, uint256 _dateUnfreeze){
        if(bonuses.length == 0 || bonuses[0].value > _value){
            return (0,0);
        }
        uint16 i = 1;
        for(i; i < bonuses.length; i++){
            if(bonuses[i].value > _value){
                break;
            }
        }
        return (bonuses[i-1].procent,bonuses[i-1].freezeTime);
    }
    
    
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this does not hold
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