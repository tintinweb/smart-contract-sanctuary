pragma solidity 0.4.20;

/*
* Team AppX presents - Moon, Inc. | Competitive Ethereum Idle Pyramid
* 
* - You can buy workers with ETH to increase your cookies production.
* - You can sell your cookies and claim a proportion of the cookie fund.
* - You cannot sell cookies within the first hour of a new production unit launch.
* - The selling price of a cookie depends on the Cookie Fund and the total cookies supply, the formula is:
*   CookiePrice = CookieFund / TotalCookieSupply * Multiplier
*   * Where Multiplier is a number from 0.5 to 1, which starts with 0.5 after a new production unit started, and reaches maximum value (1) after 5 days.
* - You can sell your workers at any time like normal tokens
*
*/

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

contract ProductionUnitToken {

    /*=================================
    =            MODIFIERS            =
    =================================*/

    /// @dev Only people with tokens
    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

    /// @dev Only people with profits
    modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
    }


    /*==============================
    =            EVENTS            =
    ==============================*/

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


    /*=====================================
    =            DEPENDENCIES             =
    =====================================*/

    // MoonInc contract
    MoonInc public moonIncContract;


    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/

    string public name = "Production Unit | Moon, Inc.";
    string public symbol = "ProductionUnit";
    uint8 constant public decimals = 18;

    /// @dev dividends for token purchase
    uint8 public entryFee_;

    /// @dev dividends for token transfer
    uint8 public transferFee_;

    /// @dev dividends for token selling
    uint8 public exitFee_;

    /// @dev 20% of entryFee_ is given to referrer
    uint8 constant internal refferalFee_ = 20;

    uint256 public tokenPriceInitial_; // original is 0.0000001 ether
    uint256 public tokenPriceIncremental_; // original is 0.00000001 ether
    uint256 constant internal magnitude = 2 ** 64;

    /// @dev proof of stake (10 tokens)
    uint256 public stakingRequirement = 10e18;

    // cookie production multiplier (how many cookies do 1 token make per second)
    uint256 public cookieProductionMultiplier;

    // auto start timer
    uint256 public startTime;

    // Maximum amount of dev one time pre-mine
    mapping(address => uint) public ambassadorsMaxPremine;
    mapping(address => bool) public ambassadorsPremined;
    mapping(address => address) public ambassadorsPrerequisite;


   /*=================================
    =            DATASETS            =
    ================================*/

    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_;


    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/

    /// @dev Set the MoonInc contract address to notify when token amount changes
    function ProductionUnitToken(
        address _moonIncContractAddress, uint8 _entryFee, uint8 _transferFee, uint8 _exitFee,
        uint _tokenPriceInitial, uint _tokenPriceIncremental, uint _cookieProductionMultiplier, uint _startTime
    ) public {
        moonIncContract = MoonInc(_moonIncContractAddress);
        entryFee_ = _entryFee;
        transferFee_ = _transferFee;
        exitFee_ = _exitFee;
        tokenPriceInitial_ = _tokenPriceInitial;
        tokenPriceIncremental_ = _tokenPriceIncremental;
        cookieProductionMultiplier = _cookieProductionMultiplier;
        startTime = _startTime;

        // Set ambassadors&#39; maximum one time pre-mine amount (Total 1.29 ETH pre-mine).
        uint BETA_DIVISOR = 1000; // TODO: remove this in main launch contract

        // MA
        ambassadorsMaxPremine[0xFEA0904ACc8Df0F3288b6583f60B86c36Ea52AcD] = 0.28 ether / BETA_DIVISOR;
        ambassadorsPremined[address(0)] = true; // first ambassador don&#39;t need prerequisite

        // BL
        ambassadorsMaxPremine[0xc951D3463EbBa4e9Ec8dDfe1f42bc5895C46eC8f] = 0.28 ether / BETA_DIVISOR;
        ambassadorsPrerequisite[0xc951D3463EbBa4e9Ec8dDfe1f42bc5895C46eC8f] = 0xFEA0904ACc8Df0F3288b6583f60B86c36Ea52AcD;

        // PH
        ambassadorsMaxPremine[0x183feBd8828a9ac6c70C0e27FbF441b93004fC05] = 0.28 ether / BETA_DIVISOR;
        ambassadorsPrerequisite[0x183feBd8828a9ac6c70C0e27FbF441b93004fC05] = 0xc951D3463EbBa4e9Ec8dDfe1f42bc5895C46eC8f;

        // RS
        ambassadorsMaxPremine[0x1fbc2Ca750E003A56d706C595b49a0A430EBA92d] = 0.09 ether / BETA_DIVISOR;
        ambassadorsPrerequisite[0x1fbc2Ca750E003A56d706C595b49a0A430EBA92d] = 0x183feBd8828a9ac6c70C0e27FbF441b93004fC05;

        // LN
        ambassadorsMaxPremine[0x41F29054E7c0BC59a8AF10f3a6e7C0E53B334e05] = 0.09 ether / BETA_DIVISOR;
        ambassadorsPrerequisite[0x41F29054E7c0BC59a8AF10f3a6e7C0E53B334e05] = 0x1fbc2Ca750E003A56d706C595b49a0A430EBA92d;

        // LE
        ambassadorsMaxPremine[0x15Fda64fCdbcA27a60Aa8c6ca882Aa3e1DE4Ea41] = 0.09 ether / BETA_DIVISOR;
        ambassadorsPrerequisite[0x15Fda64fCdbcA27a60Aa8c6ca882Aa3e1DE4Ea41] = 0x41F29054E7c0BC59a8AF10f3a6e7C0E53B334e05;

        // MI
        ambassadorsMaxPremine[0x0a3239799518E7F7F339867A4739282014b97Dcf] = 0.09 ether / BETA_DIVISOR;
        ambassadorsPrerequisite[0x0a3239799518E7F7F339867A4739282014b97Dcf] = 0x15Fda64fCdbcA27a60Aa8c6ca882Aa3e1DE4Ea41;

        // PO
        ambassadorsMaxPremine[0x31529d5Ab0D299D9b0594B7f2ef3515Be668AA87] = 0.09 ether / BETA_DIVISOR;
        ambassadorsPrerequisite[0x31529d5Ab0D299D9b0594B7f2ef3515Be668AA87] = 0x0a3239799518E7F7F339867A4739282014b97Dcf;
    }

    /// @dev Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
    function buy(address _referredBy) public payable returns (uint256) {
        purchaseTokens(msg.value, _referredBy);
    }

    /**
     * @dev Fallback function to handle ethereum that was send straight to the contract
     *  Unfortunately we cannot use a referral address this way.
     */
    function() payable public {
        purchaseTokens(msg.value, 0x0);
    }

    /// @dev Converts all of caller&#39;s dividends to tokens.
    function reinvest() onlyStronghands public {
        // fetch dividends
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code

        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, 0x0);

        // fire event
        onReinvestment(_customerAddress, _dividends, _tokens);
    }

    /// @dev Alias of sell() and withdraw().
    function exit() public {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);

        // lambo delivery service
        withdraw();
    }

    /// @dev Withdraws all of the callers earnings.
    function withdraw() onlyStronghands public {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // lambo delivery service
        _customerAddress.transfer(_dividends);

        // fire event
        onWithdraw(_customerAddress, _dividends);
    }

    /// @dev Liquifies tokens to ethereum.
    function sell(uint256 _amountOfTokens) onlyBagholders public {
        require(now >= startTime);

        // setup data
        address _customerAddress = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (_taxedEthereum * magnitude);
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        // Tell MoonInc contract for tokens amount change, and transfer dividends.
        moonIncContract.handleProductionDecrease.value(_dividends)(_customerAddress, _tokens * cookieProductionMultiplier);

        // fire event
        onTokenSell(_customerAddress, _tokens, _taxedEthereum, now, buyPrice());
    }

    /**
     * @dev Transfer tokens from the caller to a new holder.
     *  Remember, there&#39;s a fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // withdraw all outstanding dividends first
        if (myDividends(true) > 0) {
            withdraw();
        }

        // liquify 10% of the tokens that are transfered
        // these are dispersed to shareholders
        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee_), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);

        // burn the fee tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

        // Tell MoonInc contract for tokens amount change, and transfer dividends.
        moonIncContract.handleProductionDecrease.value(_dividends)(_customerAddress, _amountOfTokens * cookieProductionMultiplier);
        moonIncContract.handleProductionIncrease(_toAddress, _taxedTokens * cookieProductionMultiplier);

        // fire event
        Transfer(_customerAddress, _toAddress, _taxedTokens);

        // ERC20
        return true;
    }


    /*=====================================
    =      HELPERS AND CALCULATORS        =
    =====================================*/

    function getSettings() public view returns (uint8, uint8, uint8, uint256, uint256, uint256, uint256) {
        return (entryFee_, transferFee_, exitFee_, tokenPriceInitial_,
            tokenPriceIncremental_, cookieProductionMultiplier, startTime);
    }

    /**
     * @dev Method to view the current Ethereum stored in the contract
     *  Example: totalEthereumBalance()
     */
    function totalEthereumBalance() public view returns (uint256) {
        return this.balance;
    }

    /// @dev Retrieve the total token supply.
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    /// @dev Retrieve the tokens owned by the caller.
    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    /**
     * @dev Retrieve the dividends owned by the caller.
     *  If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
     *  The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     *  But in the internal calculations, we want them separate.
     */
    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    /// @dev Retrieve the token balance of any single address.
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    /// @dev Retrieve the dividend balance of any single address.
    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (-payoutsTo_[_customerAddress])) / magnitude;
    }

    /// @dev Return the sell price of 1 individual token.
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

    /// @dev Return the buy price of 1 individual token.
    function buyPrice() public view returns (uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, entryFee_), 100);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);

            return _taxedEthereum;
        }
    }

    /// @dev Function for the frontend to dynamically retrieve the price scaling of buy orders.
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, entryFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);

        return _amountOfTokens;
    }

    /// @dev Function for the frontend to dynamically retrieve the price scaling of sell orders.
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }


    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    /// @dev Internal function to actually purchase the tokens.
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) internal returns (uint256) {
        // Remove this on main launch
        require(_incomingEthereum <= 1 finney);

        require(
            // auto start
            now >= startTime ||
            // ambassador pre-mine within 1 hour before startTime, sequences enforced
            (now >= startTime - 1 hours && !ambassadorsPremined[msg.sender] && ambassadorsPremined[ambassadorsPrerequisite[msg.sender]] && _incomingEthereum <= ambassadorsMaxPremine[msg.sender]) ||
            // ambassador pre-mine within 10 minutes before startTime, sequences not enforced
            (now >= startTime - 10 minutes && !ambassadorsPremined[msg.sender] && _incomingEthereum <= ambassadorsMaxPremine[msg.sender])
        );

        if (now < startTime) {
            ambassadorsPremined[msg.sender] = true;
        }

        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, refferalFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);

        // no point in continuing execution if OP is a poorfag russian hacker
        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        // is the user referred by a masternode?
        if (
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != _customerAddress &&

            // does the referrer have at least X whole tokens?
            // i.e is the referrer a godly chad masternode
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
        }

        // add tokens to the pool
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        // Tell MoonInc contract for tokens amount change, and transfer dividends.
        moonIncContract.handleProductionIncrease.value(_dividends)(_customerAddress, _amountOfTokens * cookieProductionMultiplier);

        // fire event
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy, now, buyPrice());

        return _amountOfTokens;
    }

    /**
     * @dev Calculate Token price based on an amount of incoming ethereum
     *  It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     *  Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
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

    /**
     * @dev Calculate token sell value.
     *  It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     *  Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
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

contract MoonInc {

    string public constant name  = "Cookie | Moon, Inc.";
    string public constant symbol = "Cookie";
    uint8 public constant decimals = 18;

    // Total balances
    uint256 public totalEtherCookieResearchPool; // Eth dividends to be split between players&#39; cookie production
    uint256 public totalCookieProduction;
    uint256 private roughSupply;
    uint256 private lastTotalCookieSaveTime; // Last time any player claimed their produced cookie

    // Balances for each player
    mapping(address => uint256) public cookieProduction;
    mapping(address => uint256) public cookieBalance;
    mapping(address => uint256) private lastCookieSaveTime; // Last time player claimed their produced cookie

    // Mapping of approved ERC20 transfers (by player)
    mapping(address => mapping(address => uint256)) internal allowed;

    // Production unit contracts
    ProductionUnitToken[] public productionUnitTokenContracts;
    mapping(address => bool) productionUnitTokenContractAddresses;

    // Store the production unit start time to calculate sell price.
    uint256[] public tokenContractStartTime;

    uint256 public constant firstUnitStartTime = 1526763600; // TODO: change this in main launch contract
    
    // ERC20 events
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // Constructor
    function MoonInc() public payable {
        // Create first production unit (Space Kitty)
        createProductionUnit1Beta();

        // Create first production unit (Space Rabbit)
        // createProductionUnit2Beta();

        // Create first production unit (Space Hamster)
        // createProductionUnit3Beta();
    }

    function() public payable {
        // Fallback will add to research pot
        totalEtherCookieResearchPool += msg.value;
    }

    // TODO: Create 7 createProductionUnit functions in main launch contract

    function createProductionUnit1Beta() public {
        require(productionUnitTokenContracts.length == 0);

        createProductionUnitTokenContract(10, 10, 10, 0.0000001 ether / 1000, 0.00000001 ether / 1000, 1, firstUnitStartTime);
    }

    function createProductionUnit2Beta() public {
        require(productionUnitTokenContracts.length == 1);

        createProductionUnitTokenContract(15, 15, 15, 0.0000001 ether / 1000, 0.00000001 ether / 1000, 3, firstUnitStartTime + 1 days);
    }

    function createProductionUnit3Beta() public {
        require(productionUnitTokenContracts.length == 2);

        createProductionUnitTokenContract(20, 20, 20, 0.0000001 ether / 1000, 0.00000001 ether / 1000, 9, firstUnitStartTime + 2 days);
    }

    function createProductionUnitTokenContract(
        uint8 _entryFee, uint8 _transferFee, uint8 _exitFee, uint256 _tokenPriceInitial, 
        uint256 _tokenPriceIncremental, uint256 _cookieProductionMultiplier, uint256 _startTime
    ) internal {
        ProductionUnitToken newContract = new ProductionUnitToken(address(this),
            _entryFee, _transferFee, _exitFee, _tokenPriceInitial, _tokenPriceIncremental, _cookieProductionMultiplier, _startTime);
        productionUnitTokenContracts.push(newContract);
        productionUnitTokenContractAddresses[address(newContract)] = true;

        tokenContractStartTime.push(_startTime);
    }

    function productionUnitTokenContractCount() public view returns (uint) {
        return productionUnitTokenContracts.length;
    }

    function handleProductionIncrease(address player, uint256 amount) public payable {
        require(productionUnitTokenContractAddresses[msg.sender]);

        updatePlayersCookie(player);

        totalCookieProduction = SafeMath.add(totalCookieProduction, amount);
        cookieProduction[player] = SafeMath.add(cookieProduction[player], amount);

        if (msg.value > 0) {
            totalEtherCookieResearchPool += msg.value;
        }
    }

    function handleProductionDecrease(address player, uint256 amount) public payable {
        require(productionUnitTokenContractAddresses[msg.sender]);

        updatePlayersCookie(player);

        totalCookieProduction = SafeMath.sub(totalCookieProduction, amount);
        cookieProduction[player] = SafeMath.sub(cookieProduction[player], amount);

        if (msg.value > 0) {
            totalEtherCookieResearchPool += msg.value;
        }
    }

    function getState() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (totalCookieProduction, cookieProduction[msg.sender], totalSupply(), balanceOf(msg.sender), 
            totalEtherCookieResearchPool, lastTotalCookieSaveTime, computeSellPrice());
    }

    function totalSupply() public constant returns(uint256) {
        return roughSupply + balanceOfTotalUnclaimedCookie();
    }

    function balanceOf(address player) public constant returns(uint256) {
        return cookieBalance[player] + balanceOfUnclaimedCookie(player);
    }

    function balanceOfTotalUnclaimedCookie() public constant returns(uint256) {
        if (lastTotalCookieSaveTime > 0 && lastTotalCookieSaveTime < block.timestamp) {
            return (totalCookieProduction * (block.timestamp - lastTotalCookieSaveTime));
        }

        return 0;
    }

    function balanceOfUnclaimedCookie(address player) internal constant returns (uint256) {
        uint256 lastSave = lastCookieSaveTime[player];

        if (lastSave > 0 && lastSave < block.timestamp) {
            return (cookieProduction[player] * (block.timestamp - lastSave));
        }

        return 0;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        updatePlayersCookie(msg.sender);
        require(amount <= cookieBalance[msg.sender]);

        cookieBalance[msg.sender] -= amount;
        cookieBalance[recipient] += amount;

        Transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(address player, address recipient, uint256 amount) public returns (bool) {
        updatePlayersCookie(player);
        require(amount <= allowed[player][msg.sender] && amount <= cookieBalance[player]);

        cookieBalance[player] -= amount;
        cookieBalance[recipient] += amount;
        allowed[player][msg.sender] -= amount;

        Transfer(player, recipient, amount);

        return true;
    }

    function approve(address approvee, uint256 amount) public returns (bool){
        allowed[msg.sender][approvee] = amount;
        Approval(msg.sender, approvee, amount);

        return true;
    }

    function allowance(address player, address approvee) public constant returns(uint256){
        return allowed[player][approvee];
    }

    function updatePlayersCookie(address player) internal {
        uint256 cookieGain = balanceOfUnclaimedCookie(player);
        lastTotalCookieSaveTime = block.timestamp;
        lastCookieSaveTime[player] = block.timestamp;
        roughSupply += cookieGain;
        cookieBalance[player] += cookieGain;
    }

    // Sell all cookies, the eth earned is calculated by the proportion of cookies owned.
    // Selling of cookie is forbidden within one hour of new production unit launch.
    function sellAllCookies() public {
        updatePlayersCookie(msg.sender);

        uint256 sellPrice = computeSellPrice();

        require(sellPrice > 0);

        uint256 myCookies = cookieBalance[msg.sender];
        uint256 value = myCookies * sellPrice / (1 ether);

        cookieBalance[msg.sender] = 0;

        msg.sender.transfer(value);
    }

    // Compute sell price for 1 cookie, it is 0.5 when a new token contract is deployed,
    // and then goes up until it reaches the maximum sell price after 5 days.
    function computeSellPrice() public view returns (uint) {
        uint256 supply = totalSupply();

        if (supply == 0) {
            return 0;
        }

        uint index;
        uint lastTokenContractStartTime = now;

        while (index < tokenContractStartTime.length && tokenContractStartTime[index] < now) {
            lastTokenContractStartTime = tokenContractStartTime[index];
            index++;
        }

        if (now < lastTokenContractStartTime + 1 hours) {
            return 0;
        }

        uint timeToMaxValue = 2 days; // TODO: change to 5 days in main launch contract

        uint256 secondsPassed = now - lastTokenContractStartTime;
        secondsPassed = secondsPassed <= timeToMaxValue ? secondsPassed : timeToMaxValue;
        uint256 multiplier = 5000 + 5000 * secondsPassed / timeToMaxValue;

        return 1 ether * totalEtherCookieResearchPool / supply * multiplier / 10000;
    }

}