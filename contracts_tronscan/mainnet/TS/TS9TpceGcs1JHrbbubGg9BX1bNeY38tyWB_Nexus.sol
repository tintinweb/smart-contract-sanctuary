//SourceUnit: NexusTron.sol

pragma solidity ^0.4.25;

/******************************
*******************************
* https://tron.nexus-dapp.com *
*******************************
******************************/

contract Nexus {

    /*=================================
    =            MODIFIERS            =
    =================================*/

    /// @dev Only people with tokens
    modifier onlyBagholders {
        require(myTokens(msg.sender) > 0);
        _;
    }

    /// @dev Only people with profits
    modifier onlyStronghands {
        require(myDividends(true, msg.sender) > 0);
        _;
    }


    /// @dev isControlled
    modifier isControlled() {
      require(isStarted());
      _;
    }

    /*==============================
    =            EVENTS            =
    ==============================*/

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

    // TRC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
	
    event Approval(
		address indexed admin, 
		address indexed spender, 
		uint256 value
	);

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/

    string public name = "Nexus";
    string public symbol = "NEX";
    uint8 constant public decimals = 18;

    /// @dev 5% dividends for token selling
    uint8 constant internal exitFee_ = 5;

    /// @dev 33% masternode
    uint8 constant internal refferalFee_ = 30;

    /// @dev P3D pricing
    uint256 constant internal tokenPriceInitial_ = 1;
    uint256 constant internal tokenPriceIncremental_ = 1;

    uint256 constant internal magnitude = 2 ** 64;

    /// @dev 100 needed for masternode activation
    uint256 public stakingRequirement = 100e18;

    /// @dev light the marketing
    address public marketing;
	
	// @dev TRC20 allowances
	mapping (address => mapping (address => uint256)) private _allowances;


   /*=================================
    =            DATASETS            =
    ================================*/

    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) public payoutsTo_;
    mapping(address => uint256) public referralBalance_;
	
	// referrers
	mapping(address => address) public referrers_;	
    
	uint256 public jackPot_;
	address public jackPotPretender_;	
	uint256 public jackPotStartTime_;
	
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    uint256 public depositCount_;


    /*=======================================
    =            CONSTRUCTOR                =
    =======================================*/

   constructor (address _marketing) public {

		marketing = _marketing;
		jackPotStartTime_ = now;
		jackPot_ = 2e11; //200000 trx
 
   }

    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/

    /**
     * @dev Fallback function to handle tron that was send straight to the contract
     *  Unfortunately we cannot use a referral address this way.
     */
    
	function() external isControlled payable  {	
        purchaseTokens(msg.value, address(0), msg.sender);
    }

    /// @dev Converts all incoming tron to tokens for the caller, and passes down the referral addy (if any)
    function buyNEX(address _referredBy) isControlled public payable  returns (uint256) {
        purchaseTokens(msg.value, _referredBy , msg.sender);
    }

    /// @dev Converts to tokens on behalf of the customer - this allows gifting and integration with other systems
    function purchaseFor(address _referredBy, address _customerAddress) isControlled public payable returns (uint256) {
        purchaseTokens(msg.value, _referredBy , _customerAddress);
    }

    /// @dev Converts all of caller's dividends to tokens.
    function reinvest() onlyStronghands public {
        // fetch dividends
        uint256 _dividends = myDividends(false, msg.sender); // retrieve ref. bonus later in the code

        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, address(0) , _customerAddress);

        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }
	
	/// @dev The new user welcome function
    function reg() public returns(bool) {	
		return true;
	}
	
    /// @dev Alias of sell() and withdraw().
    function exit() public {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);

        // capitulation
        withdraw();
    }

    /// @dev Withdraws all of the callers earnings.
    function withdraw() onlyStronghands public {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false, msg.sender); // get ref. bonus later in the code

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // lambo delivery service
        _customerAddress.transfer(_dividends);

        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }

    /// @dev Liquifies tokens to tron.
    function sell(uint256 _amountOfTokens) onlyBagholders public {
        // setup data
        address _customerAddress = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _tron = tokensToTron_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, exitFee_), 100);
        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedTron * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        // fire event
		emit Transfer(_customerAddress, address(0), _tokens);
        emit onTokenSell(_customerAddress, _tokens, _taxedTron, now, buyPrice());
    }
	
    /**
     * @dev TRC20 functions.
     */
    function allowance(address _admin, address _spender) public view returns (uint256) {
        return _allowances[_admin][_spender];
    }

    function approve(address _spender, uint256 _amountOfTokens) public returns (bool) {
        approveInternal(msg.sender, _spender, _amountOfTokens);
        return true;
    }

    function approveInternal(address _admin, address _spender, uint256 _amountOfTokens) internal {
        require(_admin != address(0), "TRC20: approve from the zero address");
        require(_spender != address(0), "TRC20: approve to the zero address");

        _allowances[_admin][_spender] = _amountOfTokens;
        emit Approval(_admin, _spender, _amountOfTokens);
    }
	
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        approveInternal(msg.sender, spender, SafeMath.add(_allowances[msg.sender][spender], addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        approveInternal(msg.sender, spender, SafeMath.sub(_allowances[msg.sender][spender], subtractedValue));
        return true;
    }	
	
    /**
     * @dev Transfer tokens from the caller to a new holder.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // withdraw all outstanding dividends first
        if (myDividends(true, msg.sender) > 0) {
            withdraw();
        }

        return transferInternal(_toAddress,_amountOfTokens,_customerAddress);
    }
	
    function transferFrom(address _fromAddress, address _toAddress, uint256 _amountOfTokens) public returns (bool) {
        transferInternal(_toAddress, _amountOfTokens, _fromAddress);
        approveInternal(_fromAddress, msg.sender, SafeMath.sub(_allowances[_fromAddress][msg.sender], _amountOfTokens));
        return true;
    }	

    function transferInternal(address _toAddress, uint256 _amountOfTokens , address _fromAddress) internal returns (bool) {
        // setup
        address _customerAddress = _fromAddress;

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);

        // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);

        // TRC20
        return true;
    }
	

    /*=====================================
    =      HELPERS AND CALCULATORS        =
    =====================================*/

    /**
     * @dev Mtrxod to view the current Tron stored in the contract
     *  Example: totalTronBalance()
     */
    function totalTronBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Retrieve the total token supply.
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    /// @dev Retrieve the tokens balance.
    function myTokens(address _customerAddress) public view returns (uint256) {
        return balanceOf(_customerAddress);
    }

    /**
     * @dev Retrieve the dividends owned by the caller.
     *  If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
     *  The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     *  But in the internal calculations, we want them separate.
     */
    function myDividends(bool _includeReferralBonus, address _customerAddress) public view returns (uint256) {
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    /// @dev Retrieve the token balance of any single address.
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    /// @dev Retrieve the dividend balance of any single address.
    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    /// @dev Return the sell price of 1 individual token.
    function sellPrice() public view returns (uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _tron = tokensToTron_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, exitFee_), 100);
            uint256 _taxedTron = SafeMath.sub(_tron, _dividends);

            return _taxedTron;
        }
    }

    /// @dev Return the buy price of 1 individual token.
    function buyPrice() public view returns (uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _tron = tokensToTron_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, entryFee()), 100);
            uint256 _taxedTron = SafeMath.add(_tron, _dividends);

            return _taxedTron;
        }
    }

    /// @dev Function for the frontend to dynamically retrieve the price scaling of buy orders.
    function calculateTokensReceived(uint256 _tronToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tronToSpend, entryFee()), 100);
        uint256 _taxedTron = SafeMath.sub(_tronToSpend, _dividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        return _amountOfTokens;
    }

    /// @dev Function for the frontend to dynamically retrieve the price scaling of sell orders.
    function calculateTronReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _tron = tokensToTron_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, exitFee_), 100);
        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
        return _taxedTron;
    }

    /// @dev Function for the frontend to get untaxed receivable tron.
    function calculateUntaxedTronReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _tron = tokensToTron_(_tokensToSell);
        //uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, exitFee()), 100);
        //uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
        return _tron;
    }

    function entryFee() private view returns (uint8){
      uint256 volume = address(this).balance  - msg.value;

      if (volume<=1e9){
        return 22;
      }
      if (volume<=2e9){
        return 21;
      }
      if (volume<=1e14){
        return 20;
      }
      if (volume<=2e14){
        return 19;
      }
      if (volume<=3e14){
        return 18;
      }

      return 17;
	  
    }

     // @dev Function for find if premine
    function jackPotInfo() public view returns (uint256 jackPot, uint256 timer, address jackPotPretender) {
		jackPot = jackPot_;
		if (jackPot > address(this).balance) {
			jackPot = address(this).balance;
		}
		jackPot = SafeMath.div(jackPot,2);
		
		timer = now - jackPotStartTime_;
		jackPotPretender = jackPotPretender_;
    }
	
	// @dev Function for find if premine
    function isPremine() public view returns (bool) {
      return depositCount_<=5;
    }

    // @dev Function for find if premine
    function isStarted() public pure returns (bool) {
      return true; //startTime!=0 && now > startTime;
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    /// @dev Internal function to actually purchase the tokens.
    function purchaseTokens(uint256 _incomingTron, address _referredBy , address _customerAddress) internal returns (uint256) {
        // data setup
		require (_incomingTron > 0);
		
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingTron, entryFee()), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, refferalFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedTron = SafeMath.sub(_incomingTron, _undividedDividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        uint256 _fee = _dividends * magnitude;
		uint256 _marketing = SafeMath.div(SafeMath.mul(_incomingTron, 4), 100); //4%
		
        // no point in continuing execution if OP is a poorfag russian hacker
        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        // is the user referred by a masternode?
        if (
            // is this a referred purchase?
            _referredBy != address(0) &&

            // no cheating!
            _referredBy != _customerAddress &&

            // does the referrer have at least X whole tokens?
            // i.e is the referrer a godly chad masternode
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
            // wealth redistribution
			if (referrers_[_customerAddress] == address(0)) {
				referrers_[_customerAddress] = _referredBy;
			}
			calculateReferrers(_customerAddress, _referralBonus, 1);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        // we can't give people infinite tron
        if (tokenSupply_ > 0) {
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
			
			// fire event
			emit Transfer(address(0), _customerAddress, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);

            // calculate the amount of tokens the customer receives over his purchase
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        // Tells the contract that the buyer doesn't deserve dividends for the tokens before they owned them;
        // really i know you think you do but you don't
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
		
		// JackPot calculate
		calculateJackPot(_incomingTron, _customerAddress);
		
		// 4% for marketing 
		marketing.send(_marketing);

        // fire event
        emit onTokenPurchase(_customerAddress, _incomingTron, _amountOfTokens, _referredBy, now, buyPrice());

        // Keep track
        depositCount_++;
        return _amountOfTokens;
    }

    /**
     * @dev Calculate Referrers reward 
     * Level 1: 35%, Level 2: 20%, Level 3: 15%, Level 4: 10%, Level 5: 10%, Level 6: 5%, Level 7: 5%
     */	
	function calculateReferrers(address _customerAddress, uint256 _referralBonus, uint8 _level) internal {
		address _referredBy = referrers_[_customerAddress];
		uint256 _percent = 35;
		if (_referredBy != address(0)) {
			if (_level == 2) _percent = 20;
			if (_level == 3) _percent = 15;
			if (_level == 4 || _level == 5) _percent = 10;
			if (_level == 6 || _level == 7) _percent = 5;
			uint256 _newReferralBonus = SafeMath.div(SafeMath.mul(_referralBonus, _percent), 100);
			referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _newReferralBonus);
			if (_level < 7) {
				calculateReferrers(_referredBy, _referralBonus, _level+1);
			}
		}
	}

    /**
     * @dev Calculate JackPot 
     * 40% from entryFee is going to JackPot 
     * The last investor (with 2000 trx) will receive the jackpot in 12 hours 
     */	
	function calculateJackPot(uint256 _incomingTron, address _customerAddress) internal {
		uint256 timer = SafeMath.div(SafeMath.sub(now, jackPotStartTime_), 12 hours);
		if (timer > 0 && jackPotPretender_ != address(0) && jackPot_ > 0) {
			//pay jackPot
			if (address(this).balance < jackPot_) {
				jackPot_ = address(this).balance;
			}
				
			jackPotPretender_.send(SafeMath.div(jackPot_,2));
			jackPot_ = SafeMath.div(jackPot_,2);
			jackPotStartTime_ = now;
			jackPotPretender_ = address(0);
		}
		
		uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingTron, entryFee()), 100);
		jackPot_ += SafeMath.div(SafeMath.mul(_undividedDividends, 40), 100);
		
		if (_incomingTron >= 2e9) {  //2000 trx
			jackPotPretender_ = _customerAddress;
			jackPotStartTime_ = now;
		}
	}	
	
    /**
     * @dev Calculate Token price based on an amount of incoming tron
     *  It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     *  Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tronToTokens_(uint256 _tron) internal view returns (uint256) {
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

    /**
     * @dev Calculate token sell value.
     *  It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     *  Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tokensToTron_(uint256 _tokens) internal view returns (uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _tronReceived =
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

        return _tronReceived;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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