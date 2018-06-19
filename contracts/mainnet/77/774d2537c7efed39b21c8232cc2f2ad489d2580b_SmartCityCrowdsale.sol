pragma solidity ^0.4.18;

/**
 *  @title Smart City Crowdsale contract http://www.smartcitycoin.io
 */

contract SmartCityToken {
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {}
    
    function setTokenStart(uint256 _newStartTime) public {}

    function burn() public {}
}

contract SmartCityCrowdsale {
    using SafeMath for uint256;

    // State

    struct Account {
        uint256 accounted;   // received amount and bonus
        uint256 received;    // received amount
    }

    /// Crowdsale participants
    mapping (address => Account) public buyins;

    /// Balances of Fixed Price sale participants.
    mapping(address => uint256) public purchases;

    /// Total amount of ether received.
    uint256 public totalReceived = 0;

    /// Total amount of ether accounted.
    uint256 public totalAccounted = 0;

    /// Total tokens purchased during Phase 2.
    uint256 public tokensPurchased = 0;

    /// Total amount of ether which has been finalised.
    uint256 public totalFinalised = 0;
    
    /// Phase 1 end time.
    uint256 public firstPhaseEndTime;
    
    /// Phase 2 start time.
    uint256 public secondPhaseStartTime;
    
    /// Campaign end time.
    uint256 public endTime;

    /// The price per token aftre Phase 1. Works also as an effective price in Phase 2 for Phase 1 participants.
    uint256 public auctionEndPrice;
    
    /// The price for token within Phase 2 which is effective for those who did not participate in Phase 1
    uint256 public fixedPrice;

    /// The current percentage of bonus.
    uint256 public currentBonus = 15;

    /// Bonus that will be applied to purchases if Target is reached in Phase 1. Initially zero.
    uint256 public auctionSuccessBonus = 0;
    
    /// Must be false for any public function to be called.
    bool public paused = false;
    
    /// Campaign is ended
    bool public campaignEnded = false;

    // Constants after constructor:

    /// CITY token contract.
    SmartCityToken public tokenContract;

    /// The owner address.
    address public owner;

    /// The wallet address.
    address public wallet;

    /// Sale start time.
    uint256 public startTime;

    /// Amount of tokens allocated for Phase 1.
    /// Once totalAccounted / currentPrice is greater than this value, Phase 1 ends.
    uint256 public tokenCapPhaseOne;
    
    /// Amount of tokens allocated for Phase 2
    uint256 public tokenCapPhaseTwo;


    // Static constants:

    /// Target
    uint256 constant public FUNDING_GOAL = 109573 ether;
    
    /// Minimum token price after Phase 1 for Phase 2 to be started.
    uint256 constant public TOKEN_MIN_PRICE_THRESHOLD = 100000000; // 0,00001 ETH per 1 CITY
    
    /// Maximum duration of Phase 1
    uint256 constant public FIRST_PHASE_MAX_SPAN = 21 days;
    
    /// Maximum duration of Phase 2
    uint256 constant public SECOND_PHASE_MAX_SPAN = 33 days;
    
    /// Minimum investment amount
    uint256 constant public DUST_LIMIT = 5 finney;

    /// Number of days from Phase 1 beginning when bonus is available. Bonus percentage drops by 1 percent a day.
    uint256 constant public BONUS_DURATION = 15;
    
    /// Percentage of bonus that will be applied to all purchases if Target is reached in Phase 1
    uint256 constant public SUCCESS_BONUS = 15;
    
    /// token price in Phase 2 is by 20 % higher when resulting auction price
    /// for those who did not participate in auction
    uint256 constant public SECOND_PHASE_PRICE_FACTOR = 20;

    /// 1e15
    uint256 constant public FACTOR = 1 finney;

    /// Divisor of the token.
    uint256 constant public DIVISOR = 100000;

    // Events

    /// Buyin event.
    event Buyin(address indexed receiver, uint256 accounted, uint256 received, uint256 price);

    /// Phase 1 just ended.
    event PhaseOneEnded(uint256 price);
    
    /// Phase 2 is engagaed.
    event PhaseTwoStared(uint256 fixedPrice);

    /// Investement event.
    event Invested(address indexed receiver, uint256 received, uint256 tokens);

    /// The campaign just ended.
    event Ended(bool goalReached);

    /// Finalised the purchase for receiver.
    event Finalised(address indexed receiver, uint256 tokens);

    /// Campaign is over. All accounts finalised.
    event Retired();
    
    // Modifiers
    
    /// Ensure the sale is ended.
    modifier when_ended { require (now >= endTime); _; }

    /// Ensure sale is not paused.
    modifier when_not_halted { require (!paused); _; }

    /// Ensure `_receiver` is a participant.
    modifier only_investors(address _receiver) { require (buyins[_receiver].accounted != 0 || purchases[_receiver] != 0); _; }

    /// Ensure sender is owner.
    modifier only_owner { require (msg.sender == owner); _; }
    
    /// Ensure sale is in progress.
    modifier when_active { require (!campaignEnded); _;}

    /// Ensure phase 1 is in progress
    modifier only_in_phase_1 { require (now >= startTime && now < firstPhaseEndTime); _; }
    
    /// Ensure phase 1 is over
    modifier after_phase_1 { require (now >= firstPhaseEndTime); _; }

    /// Ensure phase 2 is in progress
    modifier only_in_phase_2 { require (now >= secondPhaseStartTime && now < endTime); _; }

    /// Ensure the value sent is above threshold.
    modifier reject_dust { require ( msg.value >= DUST_LIMIT ); _; }

    // Constructor

    function SmartCityCrowdsale(
        address _tokenAddress,
        address _owner,
        address _walletAddress,
        uint256 _startTime,
        uint256 _tokenCapPhaseOne,
        uint256 _tokenCapPhaseTwo
    )
        public
    {
        tokenContract = SmartCityToken(_tokenAddress);
        wallet = _walletAddress;
        owner = _owner;
        startTime = _startTime;
        firstPhaseEndTime = startTime.add(FIRST_PHASE_MAX_SPAN);
        secondPhaseStartTime = 253402300799; // initialise by setting to 9999/12/31
        endTime = secondPhaseStartTime.add(SECOND_PHASE_MAX_SPAN);
        tokenCapPhaseOne = _tokenCapPhaseOne;
        tokenCapPhaseTwo = _tokenCapPhaseTwo;
    }

    /// The default fallback function
    /// Calls buyin or invest function depending on current campaign phase
    /// Throws if campaign has already ended
    function()
        public
        payable
        when_not_halted
        when_active
    {
        if (now >= startTime && now < firstPhaseEndTime) { // phase 1 is ongoing
            _buyin(msg.sender, msg.value);
        }
        else {
            _invest(msg.sender, msg.value);
        }
    }

    // Phase 1 functions

    /// buyin function.
    function buyin()
        public
        payable
        when_not_halted
        when_active
        only_in_phase_1
        reject_dust
    {
        _buyin(msg.sender, msg.value);
    }
    
    ///  buyinAs function. takes the receiver address as an argument
    function buyinAs(address _receiver)
        public
        payable
        when_not_halted
        when_active
        only_in_phase_1
        reject_dust
    {
        require (_receiver != address(0));
        _buyin(_receiver, msg.value);
    }
    
    /// internal buyin functionality
    function _buyin(address _receiver, uint256 _value)
        internal
    {
        if (currentBonus > 0) {
            uint256 daysSinceStart = (now.sub(startTime)).div(86400); // # of days

            if (daysSinceStart < BONUS_DURATION &&
                BONUS_DURATION.sub(daysSinceStart) != currentBonus) {
                currentBonus = BONUS_DURATION.sub(daysSinceStart);
            }
            if (daysSinceStart >= BONUS_DURATION) {
                currentBonus = 0;
            }
        }

        uint256 accounted;
        bool refund;
        uint256 price;

        (accounted, refund, price) = theDeal(_value);

        // effective cap should not be exceeded, throw
        require (!refund);

        // change state
        buyins[_receiver].accounted = buyins[_receiver].accounted.add(accounted);
        buyins[_receiver].received = buyins[_receiver].received.add(_value);
        totalAccounted = totalAccounted.add(accounted);
        totalReceived = totalReceived.add(_value);
        firstPhaseEndTime = calculateEndTime();

        Buyin(_receiver, accounted, _value, price);

        // send to wallet
        wallet.transfer(_value);
    }

    /// The current end time of the sale assuming that nobody else buys in.
    function calculateEndTime()
        public
        constant
        when_active
        only_in_phase_1
        returns (uint256)
    {
        uint256 res = (FACTOR.mul(240000).div(DIVISOR.mul(totalAccounted.div(tokenCapPhaseOne)).add(FACTOR.mul(4).div(100)))).add(startTime).sub(4848);

        if (res >= firstPhaseEndTime) {
            return firstPhaseEndTime;
        }
        else {
            return res;
        }
    }
    

    /// The current price for a token
    function currentPrice()
        public
        constant
        when_active
        only_in_phase_1
        returns (uint256 weiPerIndivisibleTokenPart)
    {
        return ((FACTOR.mul(240000).div(now.sub(startTime).add(4848))).sub(FACTOR.mul(4).div(100))).div(DIVISOR);
    }

    /// Returns the total tokens which can be purchased right now.
    function tokensAvailable()
        public
        constant
        when_active
        only_in_phase_1
        returns (uint256 tokens)
    {
        uint256 _currentCap = totalAccounted.div(currentPrice());
        if (_currentCap >= tokenCapPhaseOne) {
            return 0;
        }
        return tokenCapPhaseOne.sub(_currentCap);
    }

    /// The largest purchase than can be done right now. For informational puproses only
    function maxPurchase()
        public
        constant
        when_active
        only_in_phase_1
        returns (uint256 spend)
    {
        return tokenCapPhaseOne.mul(currentPrice()).sub(totalAccounted);
    }

    /// Returns the number of tokens available per given price.
    /// If this number exceeds tokens being currently available, returns refund = true
    function theDeal(uint256 _value)
        public
        constant
        when_active
        only_in_phase_1
        returns (uint256 accounted, bool refund, uint256 price)
    {
        uint256 _bonus = auctionBonus(_value);

        price = currentPrice();
        accounted = _value.add(_bonus);

        uint256 available = tokensAvailable();
        uint256 tokens = accounted.div(price);
        refund = (tokens > available);
    }

    /// Returns bonus for given amount
    function auctionBonus(uint256 _value)
        public
        constant
        when_active
        only_in_phase_1
        returns (uint256 extra)
    {
        return _value.mul(currentBonus).div(100);
    }

    // After Phase 1
    
    /// Checks the results of the first phase
    /// Changes state only once
    function finaliseFirstPhase()
        public
        when_not_halted
        when_active
        after_phase_1
        returns(uint256)
    {
        if (auctionEndPrice == 0) {
            auctionEndPrice = totalAccounted.div(tokenCapPhaseOne);
            PhaseOneEnded(auctionEndPrice);

            // check if second phase should be engaged
            if (totalAccounted >= FUNDING_GOAL ) {
                // funding goal is reached: phase 2 is not engaged, all auction participants receive additional bonus, campaign is ended
                auctionSuccessBonus = SUCCESS_BONUS;
                endTime = firstPhaseEndTime;
                campaignEnded = true;
                
                tokenContract.setTokenStart(endTime);

                Ended(true);
            }
            
            else if (auctionEndPrice >= TOKEN_MIN_PRICE_THRESHOLD) {
                // funding goal is not reached, auctionEndPrice is above or equal to threshold value: engage phase 2
                fixedPrice = auctionEndPrice.add(auctionEndPrice.mul(SECOND_PHASE_PRICE_FACTOR).div(100));
                secondPhaseStartTime = now;
                endTime = secondPhaseStartTime.add(SECOND_PHASE_MAX_SPAN);

                PhaseTwoStared(fixedPrice);
            }
            else if (auctionEndPrice < TOKEN_MIN_PRICE_THRESHOLD && auctionEndPrice > 0){
                // funding goal is not reached, auctionEndPrice is below threshold value: phase 2 is not engaged, campaign is ended
                endTime = firstPhaseEndTime;
                campaignEnded = true;

                tokenContract.setTokenStart(endTime);

                Ended(false);
            }
            else { // no one came, we are all alone in this world :(
                auctionEndPrice = 1 wei;
                endTime = firstPhaseEndTime;
                campaignEnded = true;

                tokenContract.setTokenStart(endTime);

                Ended(false);

                Retired();
            }
        }
        
        return auctionEndPrice;
    }

    // Phase 2 functions

    /// Make an investment during second phase
    function invest()
        public
        payable
        when_not_halted
        when_active
        only_in_phase_2
        reject_dust
    {
        _invest(msg.sender, msg.value);
    }
    
    ///
    function investAs(address _receiver)
        public
        payable
        when_not_halted
        when_active
        only_in_phase_2
        reject_dust
    {
        require (_receiver != address(0));
        _invest(_receiver, msg.value);
    }
    
    /// internal invest functionality
    function _invest(address _receiver, uint256 _value)
        internal
    {
        uint256 tokensCnt = getTokens(_receiver, _value); 

        require(tokensCnt > 0);
        require(tokensPurchased.add(tokensCnt) <= tokenCapPhaseTwo); // should not exceed available tokens
        require(_value <= maxTokenPurchase(_receiver)); // should not go above target

        purchases[_receiver] = purchases[_receiver].add(_value);
        totalReceived = totalReceived.add(_value);
        totalAccounted = totalAccounted.add(_value);
        tokensPurchased = tokensPurchased.add(tokensCnt);

        Invested(_receiver, _value, tokensCnt);
        
        // send to wallet
        wallet.transfer(_value);

        // check if we&#39;ve reached the target
        if (totalAccounted >= FUNDING_GOAL) {
            endTime = now;
            campaignEnded = true;
            
            tokenContract.setTokenStart(endTime);
            
            Ended(true);
        }
    }
    
    /// Tokens currently available for purchase in Phase 2
    function getTokens(address _receiver, uint256 _value)
        public
        constant
        when_active
        only_in_phase_2
        returns(uint256 tokensCnt)
    {
        // auction participants have better price in second phase
        if (buyins[_receiver].received > 0) {
            tokensCnt = _value.div(auctionEndPrice);
        }
        else {
            tokensCnt = _value.div(fixedPrice);
        }

    }
    
    /// Maximum current purchase amount in Phase 2
    function maxTokenPurchase(address _receiver)
        public
        constant
        when_active
        only_in_phase_2
        returns(uint256 spend)
    {
        uint256 availableTokens = tokenCapPhaseTwo.sub(tokensPurchased);
        uint256 fundingGoalOffset = FUNDING_GOAL.sub(totalReceived);
        uint256 maxInvestment;
        
        if (buyins[_receiver].received > 0) {
            maxInvestment = availableTokens.mul(auctionEndPrice);
        }
        else {
            maxInvestment = availableTokens.mul(fixedPrice);
        }

        if (maxInvestment > fundingGoalOffset) {
            return fundingGoalOffset;
        }
        else {
            return maxInvestment;
        }
    }

    // After sale end
    
    /// Finalise purchase: transfers the tokens to caller address
    function finalise()
        public
        when_not_halted
        when_ended
        only_investors(msg.sender)
    {
        finaliseAs(msg.sender);
    }

    /// Finalise purchase for address provided: transfers the tokens purchased by given participant to their address
    function finaliseAs(address _receiver)
        public
        when_not_halted
        when_ended
        only_investors(_receiver)
    {
        bool auctionParticipant;
        uint256 total;
        uint256 tokens;
        uint256 bonus;
        uint256 totalFixed;
        uint256 tokensFixed;

        // first time calling finalise after phase 2 has ended but target was not reached
        if (!campaignEnded) {
            campaignEnded = true;
            
            tokenContract.setTokenStart(endTime);
            
            Ended(false);
        }

        if (buyins[_receiver].accounted != 0) {
            auctionParticipant = true;

            total = buyins[_receiver].accounted;
            tokens = total.div(auctionEndPrice);
            
            if (auctionSuccessBonus > 0) {
                bonus = tokens.mul(auctionSuccessBonus).div(100);
            }
            totalFinalised = totalFinalised.add(total);
            delete buyins[_receiver];
        }
        
        if (purchases[_receiver] != 0) {
            totalFixed = purchases[_receiver];
            
            if (auctionParticipant) {
                tokensFixed = totalFixed.div(auctionEndPrice);
            }
            else {
                tokensFixed = totalFixed.div(fixedPrice);
            }
            totalFinalised = totalFinalised.add(totalFixed);
            delete purchases[_receiver];
        }

        tokens = tokens.add(bonus).add(tokensFixed);

        require (tokenContract.transferFrom(owner, _receiver, tokens));

        Finalised(_receiver, tokens);

        if (totalFinalised == totalAccounted) {
            tokenContract.burn(); // burn all unsold tokens
            Retired();
        }
    }

    // Owner functions

    /// Emergency function to pause buy-in and finalisation.
    function setPaused(bool _paused) public only_owner { paused = _paused; }

    /// Emergency function to drain the contract of any funds.
    function drain() public only_owner { wallet.transfer(this.balance); }
    
    /// Returns true if the campaign is in progress.
    function isActive() public constant returns (bool) { return now >= startTime && now < endTime; }

    /// Returns true if all purchases are finished.
    function allFinalised() public constant returns (bool) { return now >= endTime && totalAccounted == totalFinalised; }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

    /**
    *            CITY token by www.SmartCityCoin.io
    * 
    *          .ossssss:                      `+sssss`      
    *         ` +ssssss+` `.://++++++//:.`  .osssss+       
    *            /sssssssssssssssssssssssss+ssssso`        
    *             -sssssssssssssssssssssssssssss+`         
    *            .+sssssssss+:--....--:/ossssssss+.        
    *          `/ssssssssssso`         .sssssssssss/`      
    *         .ossssss+sssssss-       :sssss+:ossssso.     
    *        `ossssso. .ossssss:    `/sssss/  `/ssssss.    
    *        ossssso`   `+ssssss+` .osssss:     /ssssss`   
    *       :ssssss`      /sssssso:ssssso.       +o+/:-`   
    *       osssss+        -sssssssssss+`                  
    *       ssssss:         .ossssssss/                    
    *       osssss/          `+ssssss-                     
    *       /ssssso           :ssssss                      
    *       .ssssss-          :ssssss                      
    *        :ssssss-         :ssssss          `           
    *         /ssssss/`       :ssssss        `/s+:`        
    *          :sssssso:.     :ssssss      ./ssssss+`      
    *           .+ssssssso/-.`:ssssss``.-/osssssss+.       
    *             .+ssssssssssssssssssssssssssss+-         
    *               `:+ssssssssssssssssssssss+:`           
    *                  `.:+osssssssssssso+:.`              
    *                        `/ssssss.`                    
    *                         :ssssss                      
    */