pragma solidity ^0.4.25;


contract Wargame {
    using SafeMath for *;
    
    /*=================================
    =            MODIFIERS            =
    =================================*/
    modifier onlyAdministrator() {
        address _customerAddress = msg.sender;
        require(administrator_ == _customerAddress);
        _;
    }
    
    
    /*=================================
    =             EVENTS              =
    =================================*/
    event onCardFlip(
        uint8 index,
        address indexed owner,
        uint256 price,
		uint256 timeEnd
    );
    
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    // attack timers
    uint256 internal baseTenMinutes_ = 10 minutes;
    uint256 internal baseOneMinutes_ = 2 minutes;
    
    // base price for a card
    uint256 internal initialPrice_ = 0.005 ether;
    
    // warmup phase countdown after starting new round
    uint256 internal countdown_ = 5 minutes;
    
    // game shall be activated manually for the first round.
    // Also if the wargame shall be upgraded (with new contract deployment),
    // it can be deactivated, which will users not allow to start the next round,
    // but they can still withdraw the pot
    bool internal contractActivated_ = false;
	bool internal roundRunning_ = false;
    
    
    /*=================================
    =             DATASET             =
    =================================*/
    address internal administrator_;    // administrator address
    address internal fundAddress_;      // fund address
    address internal currentWinner_;    // this rounds winner
    
    // Cards
    Card[12] internal nations_;         // always 12 Cards
    
    // timer
    uint256 public roundEnd_;           // end of round time stamp
    uint256 public roundStart_;         // start of round time stamp
    
    
    /*=================================
    =   PRIVATE / INTERNAL FUNCTIONS  =
    =================================*/
    function initCards()
		internal 
	{
        for (uint8 i = 0; i < nations_.length; i++) {
            Card storage _nation = nations_[i];
            uint256 _baseTenMinutes = uint256((i/4) + 1) * baseTenMinutes_;
            uint256 _column = (i%4);
            uint256 _baseOneMinutes = _column * baseOneMinutes_;
            
            // set time for each card
            _nation.time = _baseTenMinutes + _baseOneMinutes;
        }
    }
    
    /**
     * Set up cards for a new round by resetting price and owner of each card
     */
    function resetCards() 
		internal 
	{
        for (uint8 i = 0; i < nations_.length; i++) {
            Card storage _nation = nations_[i];
            
            // reset Cards
            _nation.price = initialPrice_;  // reset price
            _nation.owner = address(this);  // reset owner to this contract
        }
    }
    
    /**
     * Set new values of a card when flipping it
     */
    function setCard(Card storage _nation, address _buyer)
        internal 
    {
        // reset Cards
        _nation.price = _nation.price * 2;  // double the price
        _nation.owner = _buyer;             // set owner equal to buyer
    }
	
	function setNewRound() 
		internal 
	{
		// set globale variables and therefore start a new round
		resetCards();
		currentWinner_ = address(0x0);
		roundStart_ = now + countdown_;
		roundEnd_   = 0;
	}
    
    /**
     * Buy a card by index for the given value of eth
     */
    function _buyNationInternal(uint8 _index, uint256 _value)
        internal
    {
		// round needs to run to perform buys
		require(roundRunning_);
		
		// round has already ended
		if (now >= roundEnd_ && roundEnd_ > 0) {
			roundRunning_ = false;
			return;
		}
		
        Card storage _nation = nations_[_index];
        
        address _buyer = msg.sender;    // new card owner
        address _owner = _nation.owner; // old card owner
        require(_buyer != _owner);      // restrict self flipping, use second account instead
        
        // 62,5 % to current owner
        // 6% to fund
        // 31,5% to pot
        uint256 _ethToOwner = _value.mul(5).div(8);     // 62,5% owner
        
        // if the buy order is for the first card, do nothing bcs contract already has the eth.
        // Instead pay fund at the end of the round
        if (_nation.price != initialPrice_) {
            _owner.transfer(_ethToOwner);   // instant delivery service
        }
        
        setCard(_nation, _buyer);   // set new values for the flipped card
        
        // set globale variables
        currentWinner_ = _buyer;            // set buyer as current winner
        roundEnd_ = now + _nation.time;     // reset round end timer to nation time
        
        // trigger event
        emit onCardFlip(_index, _buyer, _nation.price, roundEnd_);
    }
	
	function deliveryService(uint256 _balance, uint256 _winnings, uint256 _fund) 
		internal 
	{
		// only deliver if there is eth left
		require(_balance > 0);
		
		currentWinner_.transfer(_winnings);	// 69% to winner
		fundAddress_.transfer(_fund);		// 6% or rest to fund
	}
    
    
    /*=================================
    =         PUBLIC FUNCTIONS        =
    =================================*/
    constructor() 
        public
    {
        administrator_ = 0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825;
        fundAddress_ = 0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825;
        
        initCards();
        resetCards();
    }
    
    /**
     * Accept eth to increase the pot
     */
    function() public payable {}
    
    /**
     * Start a round. 
     */
    function startRound()
        public
    {
		// calculate percentages
        uint256 _balance  = address(this).balance;      // 100% => 25% stays in contract for next rounds pot
        uint256 _winnings = _balance.mul(69).div(100);  // 69% to winner
        uint256 _fund     = _balance.mul(6).div(100);   // 6% fund
		
		// start new round
		if (contractActivated_) {
			// round is over
			if
			(
				now >= roundEnd_ && roundEnd_ > 0 || 	// round has ended now
				!roundRunning_							// round has already ended
			)
			{
				// payout winner and fund
				deliveryService(_balance, _winnings, _fund);
				roundRunning_ = false;
			}
			
			// if the round is not running, activate it
			if (!roundRunning_) {
				setNewRound();
				roundRunning_ = true;
			}
		} else {	// payout winner and send rest to fund
			// make sure winner is set
			require(currentWinner_ != address(0x0));
			deliveryService(_balance, _winnings, _balance.sub(_winnings));
			roundRunning_ = false;
		}
    }
    
    /**
     * Buy the nation for the exact amount of eth 
     */
    function buyNation(uint8 _index)
        public
        payable
    {		
        Card storage _nation = nations_[_index];
        uint256 _value = msg.value;
        
        // nation is buyable for the exact amount of eth
        require(_value == _nation.price, "Nation has already been bought");
        
        _buyNationInternal(_index, _value);
    }
    
    /**
     * Buy the nation for up to the amount of eth 
     */
    function overbidNation(uint8 _index)
        public 
        payable
    {		
        Card storage _nation = nations_[_index];
        uint256 _value = msg.value;
        
        // nation is buyable for the exact amount of eth
        require(_value >= _nation.price, "Nation has already been bought");
        _value = _nation.price; // set value equal to price of the nation
        
        _buyNationInternal(_index, _value);
        
        // 62,5 % to current owner
        // 6% to fund
        // 31,5% to pot
        uint256 _ethToOwner = _value.mul(5).div(8);     // 62,5% owner
        uint256 _ethToFund  = _value.mul(6).div(100);   // 6%    fund
        uint256 _ethToPot   = _value.mul(63).div(200);  // 31,5% pot
        
        // transfer back the overbid amount
        uint256 _overbid = msg.value.sub(_ethToOwner).sub(_ethToFund).sub(_ethToPot);
        if (_overbid > 0) {
            address _buyer = msg.sender;
            _buyer.transfer(_overbid);
        }
    }
    
    /* Views */
    function getNation(uint8 _index)
        public 
        view 
        returns(uint256, uint256, address)
    {
        Card storage _nation = nations_[_index];
        return (_nation.price, _nation.time, _nation.owner);
    }
    
    /* Setter */
    function setGameStatus(bool _status) 
        onlyAdministrator()
        public
    {
        contractActivated_ = _status;
    }
    
    
    /*=================================
    =            DATA TYPES           =
    =================================*/
    struct Card {
        uint256 price;
        uint256 time;
        address owner;
    }
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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