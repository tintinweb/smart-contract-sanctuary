pragma solidity ^0.4.21;

/*


  ______ .______     ____    ____ .______   .___________.  ______      ____    __    ____  ___      .______          _______.
 /      ||   _  \    \   \  /   / |   _  \  |           | /  __  \     \   \  /  \  /   / /   \     |   _  \        /       |
|  ,----&#39;|  |_)  |    \   \/   /  |  |_)  | `---|  |----`|  |  |  |     \   \/    \/   / /  ^  \    |  |_)  |      |   (----`
|  |     |      /      \_    _/   |   ___/      |  |     |  |  |  |      \            / /  /_\  \   |      /        \   \    
|  `----.|  |\  \----.   |  |     |  |          |  |     |  `--&#39;  |       \    /\    / /  _____  \  |  |\  \----.----)   |   
 \______|| _| `._____|   |__|     | _|          |__|      \______/         \__/  \__/ /__/     \__\ | _| `._____|_______/    
                                                                                                                             

website:    https://cryptowars.ga

discord:    https://discord.gg/8AFP9gS

25% Dividends Fees/Payouts

Crypto Warriors Card Game is also included in the contract and played on the same page as the Exchange

2% of Fees go into the card game insurance accounts for card holders that face a half-life cut

5% of all Card gains go to Card insurance accounts

Referral Program pays out 33% of Buy/Sell Fees to user of masternode link

*/

contract AcceptsExchange {
    cryptowars public tokenContract;

    function AcceptsExchange(address _tokenContract) public {
        tokenContract = cryptowars(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

    /**
    * @dev Standard ERC677 function that will handle incoming token transfers.
    *
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
    function tokenFallbackExpanded(address _from, uint256 _value, bytes _data, address _sender, address _referrer) external returns (bool);
}

contract cryptowars {
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    
    // only people with profits
    modifier onlyStronghands() {
        require(myDividends(true) > 0 || ownerAccounts[msg.sender] > 0);
        //require(myDividends(true) > 0);
        _;
    }
    
      modifier notContract() {
      require (msg.sender == tx.origin);
      _;
    }

    modifier allowPlayer(){
        
        require(boolAllowPlayer);
        _;
    }

    // administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // -> change the PoS difficulty (How many tokens it costs to hold a masternode, in case it gets crazy high later)
    // they CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }
    
    modifier onlyActive(){
        require(boolContractActive);
        _;
    }

     modifier onlyCardActive(){
        require(boolCardActive);
        _;
    }

    
    // ensures that the first tokens in the contract will be equally distributed
    // meaning, no divine dump will be ever possible
    // result: healthy longevity.
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;
        
        // are we still in the vulnerable phase?
        // if so, enact anti early whale protocol 
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                // is the customer in the ambassador list?
                (ambassadors_[_customerAddress] == true &&
                
                // does the customer purchase exceed the max ambassador quota?
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_) ||

                (_customerAddress == dev)
                
            );
            
            // updated the accumulated quota    
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
        
            // execute
            _;
        } else {
            // in case the ether count drops low, the ambassador phase won&#39;t reinitiate
            onlyAmbassadors = false;
            _;    
        }
        
    }
    
    /*==============================
    =            EVENTS            =
    ==============================*/

    event onCardBuy(
        address customerAddress,
        uint256 incomingEthereum,
        uint256 card,
        uint256 newPrice,
        uint256 halfLifeTime
    );

    event onInsuranceChange(
        address customerAddress,
        uint256 card,
        uint256 insuranceAmount
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
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
    
       // HalfLife
    event Halflife(
        address customerAddress,
        uint card,
        uint price,
        uint newBlockTime,
        uint insurancePay,
        uint cardInsurance
    );
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "CryptoWars";
    string public symbol = "JEDI";
    uint8 constant public decimals = 18;
    uint256 constant internal tokenPriceInitial_ = 0.00000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.000000001 ether;
    uint256 constant internal magnitude = 2**64;
    
    // proof of stake (defaults at 100 tokens)
    uint256 public stakingRequirement = 100e18;
    
    // ambassador program
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 3 ether;
    uint256 constant internal ambassadorQuota_ = 20 ether;
    
    address dev;

    uint nextAvailableCard;

    address add2 = 0x0;

    uint public totalCardValue = 0;

    uint public totalCardInsurance = 0;

    bool public boolAllowPlayer = false;
    
    
   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

    //CARDS
    mapping(uint => address) internal cardOwner;
    mapping(uint => uint) public cardPrice;
    mapping(uint => uint) public basePrice;
    mapping(uint => uint) internal cardPreviousPrice;
    mapping(address => uint) internal ownerAccounts;
    mapping(uint => uint) internal totalCardDivs;
    mapping(uint => uint) internal totalCardDivsETH;
    mapping(uint => string) internal cardName;
    mapping(uint => uint) internal cardInsurance;

    uint public cardInsuranceAccount;

    uint cardPriceIncrement = 1250;   //25% Price Increases
   
    uint totalDivsProduced;

    //card rates
    uint public ownerDivRate = 500;
    uint public distDivRate = 400;
    uint public devDivRate = 50;
    uint public insuranceDivRate = 50;
    uint public referralRate = 50;
    



    mapping(uint => uint) internal cardBlockNumber;

    uint public halfLifeTime = 5900;            //1 day half life period
    uint public halfLifeRate = 900;             //cut price by 1/10 each half life period
    uint public halfLifeReductionRate = 667;    //cut previous price by 1/3

    bool public allowHalfLife = true;  //for cards

    bool public allowReferral = false;  //for cards

    uint public insurancePayoutRate = 250; //pay 25% of the remaining insurance fund for that card on each half-life

   
    address inv1 = 0x387E7E1580BbE37a06d847985faD20f353bBeB1b;
    address inv2 = 0xD87fA3D0cF18fD2C14Aa34BcdeaF252Bf4d56644;
    address inv3 = 0xc4166D533336cf49b85b3897D7315F5bB60E420b;


    uint8 public dividendFee_ = 200; // 20% dividend fee on each buy and sell dividendFee_
    uint8 public cardInsuranceFeeRate_ = 20;//20; // 2% fee rate on each buy and sell for Giants Card Insurance
    uint8 public investorFeeRate_ = 10;//10; // 1% fee for investors

    uint public maxCards = 50;

    bool public boolContractActive = false;
    bool public boolCardActive = false;

    // administrator list (see above on what they can do)
    mapping(address => bool) public administrators;
    
    // when this is set to true, only ambassadors can purchase tokens (this prevents a whale premine, it ensures a fairly distributed upper pyramid)
    bool public onlyAmbassadors = true;

      // Special Wall Street Market Platform control from scam game contracts on Wall Street Market platform
    mapping(address => bool) public canAcceptTokens_; // contracts, which can accept Wall Street tokens


    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    function cryptowars()
        public
    {
        allowHalfLife = true;
        allowReferral = false;

        // add administrators here
        administrators[msg.sender] = true;

        dev = msg.sender;

        ambassadors_[dev] = true;
        ambassadors_[inv1] = true;
        ambassadors_[inv2] = true;
        ambassadors_[inv3] = true;

        ambassadors_[0x96762288ebb2560a19F8eAdAaa2012504F64278B] = true;
        ambassadors_[0x5145A296e1bB9d4Cf468d6d97d7B6D15700f39EF] = true;
        ambassadors_[0xE74b1ea522B9d558C8e8719c3b1C4A9050b531CA] = true;
        ambassadors_[0xb62A0AC2338C227748E3Ce16d137C6282c9870cF] = true;
        ambassadors_[0x836e5abac615b371efce0ab399c22a04c1db5ecf] = true;
        ambassadors_[0xAe3dC7FA07F9dD030fa56C027E90998eD9Fe9D61] = true;
        ambassadors_[0x38602d1446fe063444B04C3CA5eCDe0cbA104240] = true;
        ambassadors_[0x3825c8BA07166f34cE9a2cD1e08A68b105c82cB9] = true;
        ambassadors_[0xa6662191F558e4C611c8f14b50c784EDA9Ace98d] = true;
        

        nextAvailableCard = 13;

        cardOwner[1] = dev;
        cardPrice[1] = 5 ether;
        basePrice[1] = cardPrice[1];
        cardPreviousPrice[1] = 0;

        cardOwner[2] = dev;
        cardPrice[2] = 4 ether;
        basePrice[2] = cardPrice[2];
        cardPreviousPrice[2] = 0;

        cardOwner[3] = dev;
        cardPrice[3] = 3 ether;
        basePrice[3] = cardPrice[3];
        cardPreviousPrice[3] = 0;

        cardOwner[4] = dev;
        cardPrice[4] = 2 ether;
        basePrice[4] = cardPrice[4];
        cardPreviousPrice[4] = 0;

        cardOwner[5] = dev;
        cardPrice[5] = 1.5 ether;
        basePrice[5] = cardPrice[5];
        cardPreviousPrice[5] = 0;

        cardOwner[6] = 0xb62A0AC2338C227748E3Ce16d137C6282c9870cF;
        cardPrice[6] = 1 ether;
        basePrice[6] = cardPrice[6];
        cardPreviousPrice[6] = 0;

        cardOwner[7] = 0x96762288ebb2560a19f8eadaaa2012504f64278b;
        cardPrice[7] = 0.8 ether;
        basePrice[7] = cardPrice[7];
        cardPreviousPrice[7] = 0;

        cardOwner[8] = 0x836e5abac615b371efce0ab399c22a04c1db5ecf;
        cardPrice[8] = 0.6 ether;
        basePrice[8] = cardPrice[8];
        cardPreviousPrice[8] = 0;

        cardOwner[9] = 0xAe3dC7FA07F9dD030fa56C027E90998eD9Fe9D61;
        cardPrice[9] = 0.4 ether;
        basePrice[9] = cardPrice[9];
        cardPreviousPrice[9] = 0;

        cardOwner[10] = dev;
        cardPrice[10] = 0.2 ether;
        basePrice[10] = cardPrice[10];
        cardPreviousPrice[10] = 0;

        cardOwner[11] = dev;
        cardPrice[11] = 0.1 ether;
        basePrice[11] = cardPrice[11];
        cardPreviousPrice[11] = 0;

        cardOwner[12] = dev;
        cardPrice[12] = 0.1 ether;
        basePrice[12] = cardPrice[12];
        cardPreviousPrice[12] = 0;

        getTotalCardValue();

    }
    
     
    /**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
     */
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        purchaseTokens(msg.value, _referredBy);
    }
    
    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        payable
        public
    {
        purchaseTokens(msg.value, 0x0);
    }
    
    /**
     * Converts all of caller&#39;s dividends to tokens.
     */
    function reinvest()
        onlyStronghands()
        public
    {
        // fetch dividends
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code
        
        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress] + ownerAccounts[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        ownerAccounts[_customerAddress] = 0;
        
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, 0x0);
        
        // fire event
        onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
    /**
     * Alias of sell() and withdraw().
     */
    function exit()
        public
    {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
        
        // lambo delivery service
        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
        onlyStronghands()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code
        
        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // add ref. bonus
        _dividends += referralBalance_[_customerAddress] + ownerAccounts[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        ownerAccounts[_customerAddress] = 0;
        
        // lambo delivery service
        _customerAddress.transfer(_dividends);
        
        // fire event
        onWithdraw(_customerAddress, _dividends);
    }
    
    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_),1000);
       // uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        
        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;       
        
        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        checkHalfLife();
        
        // fire event
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    
    
    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there&#39;s a 10% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        
        // make sure we have the requested tokens
        // also disables transfers until ambassador phase is over
        // ( we dont want whale premines )
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) withdraw();
        
        // liquify 20% of the tokens that are transfered
        // these are dispersed to shareholders
        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, dividendFee_),1000);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);
  
        // burn the fee tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        
        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
        
        // disperse dividends among holders
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        
        // fire event
        Transfer(_customerAddress, _toAddress, _taxedTokens);
        
        // ERC20
        return true;
       
    }
    
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    /**
     * In case the amassador quota is not met, the administrator can manually disable the ambassador phase.
     */
    function disableInitialStage()
        onlyAdministrator()
        public
    {
        onlyAmbassadors = false;
    }
    
    /**
     * In case one of us dies, we need to replace ourselves.
     */
    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
    }

    function setAllowHalfLife(bool _allow)
        onlyAdministrator()
    {
        allowHalfLife = _allow;
    
    }

    function setAllowReferral(bool _allow)
        onlyAdministrator()
    {
        allowReferral = _allow;
    
    }

    function setInv1(address _newInvestorAddress)
        onlyAdministrator()
        public
    {
        inv1 = _newInvestorAddress;
    }

    function setInv2(address _newInvestorAddress)
        onlyAdministrator()
        public
    {
        inv2 = _newInvestorAddress;
    }

    function setInv3(address _newInvestorAddress)
        onlyAdministrator()
        public
    {
        inv3 = _newInvestorAddress;
    }

    /**
     * Set fees/rates
     */
    function setFeeRates(uint8 _newDivRate, uint8 _newInvestorFee, uint8 _newCardFee)
        onlyAdministrator()
        public
    {
        require(_newDivRate <= 250);
        require(_newInvestorFee + _newCardFee <= 50);  //5% -- 50 out of 1000

        dividendFee_ = _newDivRate;
        investorFeeRate_ = _newInvestorFee;
        cardInsuranceFeeRate_ = _newCardFee;
    }
    
    /**
     * In case one of us dies, we need to replace ourselves.
     */
    function setContractActive(bool _status)
        onlyAdministrator()
        public
    {
        boolContractActive = _status;
    }

    /**
     * In case one of us dies, we need to replace ourselves.
     */
    function setCardActive(bool _status)
        onlyAdministrator()
        public
    {
        boolCardActive = _status;
    }
    

    /**
     * Precautionary measures in case we need to adjust the masternode rate.
     */
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }
    
    /**
     * If we want to rebrand, we can.
     */
    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
    
    /**
     * If we want to rebrand, we can.
     */
    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

    
    function setMaxCards(uint _card)  
        onlyAdministrator()
        public
    {
        maxCards = _card;
    }

    function setHalfLifeTime(uint _time)
        onlyAdministrator()
        public
    {
        halfLifeTime = _time;
    }

    function setHalfLifeRate(uint _rate)
        onlyAdministrator()
        public
    {
        halfLifeRate = _rate;
    }

    function addNewCard(uint _price) 
        onlyAdministrator()
        public
    {
        require(nextAvailableCard < maxCards);
        cardPrice[nextAvailableCard] = _price;
        basePrice[nextAvailableCard] = cardPrice[nextAvailableCard];
        cardOwner[nextAvailableCard] = dev;
        totalCardDivs[nextAvailableCard] = 0;
        cardPreviousPrice[nextAvailableCard] = 0;
        nextAvailableCard = nextAvailableCard + 1;
        getTotalCardValue();
        
    }


    function addAmbassador(address _newAmbassador) 
        onlyAdministrator()
        public
    {
        ambassadors_[_newAmbassador] = true;
    }
    
    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return this.balance;
    }
    
    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }
    
    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
    /**
     * Retrieve the dividends owned by the caller.
     * If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
     * The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     * But in the internal calculations, we want them separate. 
     */ 
    function myDividends(bool _includeReferralBonus) 
        public 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function myCardDividends()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return ownerAccounts[_customerAddress];
    }
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }
    
    /**
     * Return the buy price of 1 individual token.
     */
    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_  ),1000);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    
    /**
     * Return the sell price of 1 individual token.
     */
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_  ),1000);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    
    /**
     * Function for the frontend to dynamically retrieve the price scaling of buy orders.
     */
    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, dividendFee_  ),1000);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        
        return _amountOfTokens;
    }
    
    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateEthereumReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_  ),1000);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/


    function getNextAvailableCard()
        public
        view
        returns(uint)
    {
        return nextAvailableCard;
    }

    function getTotalCardValue()
    internal
    view
    {
        uint counter = 1;
        uint _totalVal = 0;

        while (counter < nextAvailableCard) { 

            _totalVal = SafeMath.add(_totalVal,cardPrice[counter]);
                
            counter = counter + 1;
        } 
        totalCardValue = _totalVal;
            
    }

    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
        onlyActive()
        internal
        returns(uint256)
    {
        // data setup

        cardInsuranceAccount = SafeMath.add(cardInsuranceAccount, SafeMath.div(SafeMath.mul(_incomingEthereum, cardInsuranceFeeRate_), 1000));
        ownerAccounts[inv1] = SafeMath.add(ownerAccounts[inv1] , SafeMath.div(SafeMath.mul(_incomingEthereum, investorFeeRate_), 1000));
        ownerAccounts[inv2] = SafeMath.add(ownerAccounts[inv2] , SafeMath.div(SafeMath.mul(_incomingEthereum, investorFeeRate_), 1000));
        ownerAccounts[inv3] = SafeMath.add(ownerAccounts[inv3] , SafeMath.div(SafeMath.mul(_incomingEthereum, investorFeeRate_), 1000));


        _incomingEthereum = SafeMath.sub(_incomingEthereum,SafeMath.div(SafeMath.mul(_incomingEthereum, cardInsuranceFeeRate_), 1000) + SafeMath.div(SafeMath.mul(_incomingEthereum, investorFeeRate_), 1000)*3);

      
        uint256 _referralBonus = SafeMath.div(SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_  ),1000), 3);
        uint256 _dividends = SafeMath.sub(SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_  ),1000), _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_  ),1000));
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
 
        // no point in continuing execution if OP is a poorfag russian hacker
        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
        // is the user referred by a masternode?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != msg.sender &&
            
            // does the referrer have at least X whole tokens?
            // i.e is the referrer a godly chad masternode
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        
        // we can&#39;t give people infinite ethereum
        if(tokenSupply_ > 0){
            
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
 
            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            
            // calculate the amount of tokens the customer receives over his purchase 
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }
        
        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[msg.sender] = SafeMath.add(tokenBalanceLedger_[msg.sender], _amountOfTokens);
        
        // Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them;
        //really i know you think you do but you don&#39;t
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[msg.sender] += _updatedPayouts;

        distributeInsurance();
        checkHalfLife();
        
        // fire event
        onTokenPurchase(msg.sender, _incomingEthereum, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }



    function buyCard(uint _card, address _referrer)
        public
        payable
        onlyCardActive()
    {
        require(_card <= nextAvailableCard);
        require(_card > 0);
        require(msg.value >= cardPrice[_card]);
       
        cardBlockNumber[_card] = block.number;   //reset block number for this card for half life calculations


         //Determine the total dividends
        uint _baseDividends = msg.value - cardPreviousPrice[_card];
        totalDivsProduced = SafeMath.add(totalDivsProduced, _baseDividends);

        //uint _devDividends = SafeMath.div(SafeMath.mul(_baseDividends,devDivRate),100);
        uint _ownerDividends = SafeMath.div(SafeMath.mul(_baseDividends,ownerDivRate),1000);
        _ownerDividends = SafeMath.add(_ownerDividends,cardPreviousPrice[_card]);  //owner receovers price they paid initially
        uint _insuranceDividends = SafeMath.div(SafeMath.mul(_baseDividends,insuranceDivRate),1000);

        totalCardDivs[_card] = SafeMath.add(totalCardDivs[_card],_ownerDividends);
        
        cardInsuranceAccount = SafeMath.add(cardInsuranceAccount, _insuranceDividends);
            
        uint _distDividends = SafeMath.div(SafeMath.mul(_baseDividends,distDivRate),1000);

        if (allowReferral && (_referrer != msg.sender) && (_referrer != 0x0000000000000000000000000000000000000000)) {
                
            uint _referralDividends = SafeMath.div(SafeMath.mul(_baseDividends,referralRate),1000);
            _distDividends = SafeMath.sub(_distDividends,_referralDividends);
            ownerAccounts[_referrer] = SafeMath.add(ownerAccounts[_referrer],_referralDividends);
        }
            
        distributeYield(_distDividends);

        //distribute dividends to accounts
        address _previousOwner = cardOwner[_card];
        address _newOwner = msg.sender;

        ownerAccounts[_previousOwner] = SafeMath.add(ownerAccounts[_previousOwner],_ownerDividends);
        ownerAccounts[dev] = SafeMath.add(ownerAccounts[dev],SafeMath.div(SafeMath.mul(_baseDividends,devDivRate),1000));

        cardOwner[_card] = _newOwner;

        //Increment the card Price
        cardPreviousPrice[_card] = msg.value;
        cardPrice[_card] = SafeMath.div(SafeMath.mul(msg.value,cardPriceIncrement),1000);
  
        getTotalCardValue();
        distributeInsurance();
        checkHalfLife();

        emit onCardBuy(msg.sender, msg.value, _card, SafeMath.div(SafeMath.mul(msg.value,cardPriceIncrement),1000), halfLifeTime + block.number);
     
    }


    function distributeInsurance() internal
    {
        uint counter = 1;
        uint _cardDistAmount = cardInsuranceAccount;
        cardInsuranceAccount = 0;
        uint tempInsurance = 0;

        while (counter < nextAvailableCard) { 
  
            uint _distAmountLocal = SafeMath.div(SafeMath.mul(_cardDistAmount, cardPrice[counter]),totalCardValue);
            
            cardInsurance[counter] = SafeMath.add(cardInsurance[counter], _distAmountLocal);
            tempInsurance = tempInsurance + cardInsurance[counter];
            emit onInsuranceChange(0x0, counter, cardInsurance[counter]);
    
            counter = counter + 1;
        } 
        totalCardInsurance = tempInsurance;
    }


    function distributeYield(uint _distDividends) internal
    //tokens
    {
        uint counter = 1;
        uint currentBlock = block.number;
        uint insurancePayout = 0;

        while (counter < nextAvailableCard) { 

            uint _distAmountLocal = SafeMath.div(SafeMath.mul(_distDividends, cardPrice[counter]),totalCardValue);
            ownerAccounts[cardOwner[counter]] = SafeMath.add(ownerAccounts[cardOwner[counter]],_distAmountLocal);
            totalCardDivs[counter] = SafeMath.add(totalCardDivs[counter],_distAmountLocal);

            counter = counter + 1;
        } 
        getTotalCardValue();
        checkHalfLife();
    }

    function extCheckHalfLife() 
    public
    {
        bool _boolDev = (msg.sender == dev);
        if (_boolDev || boolAllowPlayer){
            checkHalfLife();
        }
    }


    function checkHalfLife() 
    internal
    
    //tokens
    {

        uint counter = 1;
        uint currentBlock = block.number;
        uint insurancePayout = 0;
        uint tempInsurance = 0;

        while (counter < nextAvailableCard) { 

            //HalfLife Check
            if (allowHalfLife) {

                if (cardPrice[counter] > basePrice[counter]) {
                    uint _life = SafeMath.sub(currentBlock, cardBlockNumber[counter]);

                    if (_life > halfLifeTime) {
                    
                        cardBlockNumber[counter] = currentBlock;  //Reset the clock for this card
                        if (SafeMath.div(SafeMath.mul(cardPrice[counter], halfLifeRate),1000) < basePrice[counter]){
                            
                            cardPrice[counter] = basePrice[counter];
                            insurancePayout = SafeMath.div(SafeMath.mul(cardInsurance[counter],insurancePayoutRate),1000);
                            cardInsurance[counter] = SafeMath.sub(cardInsurance[counter],insurancePayout);
                            ownerAccounts[cardOwner[counter]] = SafeMath.add(ownerAccounts[cardOwner[counter]], insurancePayout);
                            
                        }else{

                            cardPrice[counter] = SafeMath.div(SafeMath.mul(cardPrice[counter], halfLifeRate),1000);  
                            cardPreviousPrice[counter] = SafeMath.div(SafeMath.mul(cardPrice[counter],halfLifeReductionRate),1000);

                            insurancePayout = SafeMath.div(SafeMath.mul(cardInsurance[counter],insurancePayoutRate),1000);
                            cardInsurance[counter] = SafeMath.sub(cardInsurance[counter],insurancePayout);
                            ownerAccounts[cardOwner[counter]] = SafeMath.add(ownerAccounts[cardOwner[counter]], insurancePayout);

                        }
                        emit onInsuranceChange(0x0, counter, cardInsurance[counter]);
                        emit Halflife(cardOwner[counter], counter, cardPrice[counter], halfLifeTime + block.number, insurancePayout, cardInsurance[counter]);

                    }
                    //HalfLife Check
                    
                }
               
            }
            
            tempInsurance = tempInsurance + cardInsurance[counter];
            counter = counter + 1;
        } 
        totalCardInsurance = tempInsurance;
        getTotalCardValue();

    }

    /**
     * Calculate Token price based on an amount of incoming ethereum
     * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function ethereumToTokens_(uint256 _ethereum)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = 
         (
            (
                // underflow attempts BTFO
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(tokenSupply_)
        ;
  
        return _tokensReceived;
    }
    
    /**
     * Calculate token sell value.
     * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
     function tokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
        return _etherReceived;
    }


    function getCardPrice(uint _card)
        public
        view
        returns(uint)
    {
        require(_card <= nextAvailableCard);
        return cardPrice[_card];
    }

   function getCardInsurance(uint _card)
        public
        view
        returns(uint)
    {
        require(_card <= nextAvailableCard);
        return cardInsurance[_card];
    }


    function getCardOwner(uint _card)
        public
        view
        returns(address)
    {
        require(_card <= nextAvailableCard);
        return cardOwner[_card];
    }

    function gettotalCardDivs(uint _card)
        public
        view
        returns(uint)
    {
        require(_card <= nextAvailableCard);
        return totalCardDivs[_card];
    }

    function getTotalDivsProduced()
        public
        view
        returns(uint)
    {
     
        return totalDivsProduced;
    }
    
    
    //This is where all your gas goes, sorry
    //Not sorry, you probably only paid 1 gwei
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
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