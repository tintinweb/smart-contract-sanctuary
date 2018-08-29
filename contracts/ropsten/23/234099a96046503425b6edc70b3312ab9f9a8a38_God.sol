pragma solidity ^0.4.23;

contract God {
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }

    // only people with profits
    modifier onlyProfitsHolders() {
        require(myDividends(true) > 0);
        _;
    }

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }


    /*==============================
    =            EVENTS            =
    ==============================*/
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

    event onInjectEtherFromIco(uint _incomingEthereum, uint _dividends, uint profitPerShare_);

    event onInjectEtherToDividend(address sender, uint _incomingEthereum, uint profitPerShare_);

    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);



    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "God";
    string public symbol = "God";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2 ** 64;

    // proof of stake (defaults at 100 tokens)
    uint256 public stakingRequirement = 100e18;

    uint constant internal  MIN_TOKEN_TRANSFER = 1e10;


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

    mapping(address => mapping(address => uint256)) internal allowed;

    // administrator list (see above on what they can do)
    address internal owner;
    mapping(address => bool) public administrators;

    address bankAddress;
    mapping(address => bool) public contractAddresses;

    int internal contractPayout = 0;

    bool internal isProjectBonus = true;
    uint internal projectBonus = 0;
    uint internal projectBonusRate = 10;  // 1/10

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    constructor()
    public
    {
        // add administrators here
        owner = msg.sender;
        administrators[owner] = true;
    }

    /**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
     */
    function buy(address _referredBy)
    public
    payable
    returns (uint256)
    {
        purchaseTokens(msg.value, _referredBy);
    }

    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
    public
    payable
    {
        purchaseTokens(msg.value, 0x0);
    }

    function injectEtherFromIco()
    public
    payable
    {
        uint _incomingEthereum = msg.value;
        require(_incomingEthereum > 0);
        uint256 _dividends = SafeMath.div(_incomingEthereum, dividendFee_);

        if (isProjectBonus) {
            uint temp = SafeMath.div(_dividends, projectBonusRate);
            _dividends = SafeMath.sub(_dividends, temp);
            projectBonus = SafeMath.add(projectBonus, temp);
        }
        profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
        emit onInjectEtherFromIco(_incomingEthereum, _dividends, profitPerShare_);
    }

    function injectEtherToDividend()
    public
    payable
    {
        uint _incomingEthereum = msg.value;
        require(_incomingEthereum > 0);
        profitPerShare_ += (_incomingEthereum * magnitude / (tokenSupply_));
        emit onInjectEtherToDividend(msg.sender, _incomingEthereum, profitPerShare_);
    }

    function injectEther()
    public
    payable
    {}

    /**
     * Converts all of caller&#39;s dividends to tokens.
     */
    function reinvest()
    onlyProfitsHolders()
    public
    {
        // fetch dividends
        uint256 _dividends = myDividends(false);
        // retrieve ref. bonus later in the code

        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, 0x0);

        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
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
        if (_tokens > 0) sell(_tokens);

        // lambo delivery service
        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
    onlyProfitsHolders()
    public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        // get ref. bonus later in the code

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

    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens)
    onlyTokenHolders()
    public
    {
        // setup data
        address _customerAddress = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

        if (isProjectBonus) {
            uint temp = SafeMath.div(_dividends, projectBonusRate);
            _dividends = SafeMath.sub(_dividends, temp);
            projectBonus = SafeMath.add(projectBonus, temp);
        }

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

        // fire event
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }


    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there&#39;s a 10% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
    onlyTokenHolders()
    public
    returns (bool)
    {
        address _customerAddress = msg.sender;
        require(_amountOfTokens >= MIN_TOKEN_TRANSFER
        && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        bytes memory empty;
        transferFromInternal(_customerAddress, _toAddress, _amountOfTokens, empty);
        return true;
    }

    function transferFromInternal(address _from, address _toAddress, uint _amountOfTokens, bytes _data)
    internal
    {
        require(_toAddress != address(0x0));
        uint fromLength;
        uint toLength;
        assembly {
            fromLength := extcodesize(_from)
            toLength := extcodesize(_toAddress)
        }

        if (fromLength > 0 && toLength <= 0) {
            // contract to human
            contractAddresses[_from] = true;
            contractPayout -= (int) (_amountOfTokens);
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);

        } else if (fromLength <= 0 && toLength > 0) {
            // human to contract
            contractAddresses[_toAddress] = true;
            contractPayout += (int) (_amountOfTokens);
            tokenSupply_ = SafeMath.sub(tokenSupply_, _amountOfTokens);
            payoutsTo_[_from] -= (int256) (profitPerShare_ * _amountOfTokens);

        } else if (fromLength > 0 && toLength > 0) {
            // contract to contract
            contractAddresses[_from] = true;
            contractAddresses[_toAddress] = true;
        } else {
            // human to human
            payoutsTo_[_from] -= (int256) (profitPerShare_ * _amountOfTokens);
            payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);
        }

        // exchange tokens
        tokenBalanceLedger_[_from] = SafeMath.sub(tokenBalanceLedger_[_from], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

        // to contract
        if (toLength > 0) {
            ERC223Receiving receiver = ERC223Receiving(_toAddress);
            receiver.tokenFallback(_from, _amountOfTokens, _data);
        }

        // fire event
        emit Transfer(_from, _toAddress, _amountOfTokens);

    }

    function transferFrom(address _from, address _toAddress, uint _amountOfTokens)
    public
    returns (bool)
    {
        // Setup variables
        address _customerAddress = _from;
        bytes memory empty;
        // Make sure we own the tokens we&#39;re transferring, are ALLOWED to transfer that many tokens,
        // and are transferring at least one full token.
        require(_amountOfTokens >= MIN_TOKEN_TRANSFER
        && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]
        && _amountOfTokens <= allowed[_customerAddress][msg.sender]);

        transferFromInternal(_from, _toAddress, _amountOfTokens, empty);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _amountOfTokens);

        // Good old ERC20.
        return true;

    }

    function transferTo(address _from, address _to, uint _amountOfTokens, bytes _data)
    public
    {
        if (_from != msg.sender) {
            require(_amountOfTokens >= MIN_TOKEN_TRANSFER
            && _amountOfTokens <= tokenBalanceLedger_[_from]
            && _amountOfTokens <= allowed[_from][msg.sender]);
            allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _amountOfTokens);
        }
        else {
            require(_amountOfTokens >= MIN_TOKEN_TRANSFER
            && _amountOfTokens <= tokenBalanceLedger_[_from]);
        }
        transferFromInternal(_from, _to, _amountOfTokens, _data);
    }

    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/

    function setBank(address _identifier, uint256 value)
    onlyAdministrator()
    public
    {
        bankAddress = _identifier;
        contractAddresses[_identifier] = true;
        tokenBalanceLedger_[_identifier] = value;
    }

    /**
     * In case one of us dies, we need to replace ourselves.
     */
    function setAdministrator(address _identifier, bool _status)
    onlyAdministrator()
    public
    {
        require(_identifier != owner);
        administrators[_identifier] = _status;
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

    function getContractPayout()
    onlyAdministrator()
    public
    view
    returns (int)
    {
        return contractPayout;
    }

    function getIsProjectBonus()
    onlyAdministrator()
    public
    view
    returns (bool)
    {
        return isProjectBonus;
    }

    function setIsProjectBonus(bool value)
    onlyAdministrator()
    public
    {
        isProjectBonus = value;
    }

    function getProjectBonus()
    onlyAdministrator()
    public
    view
    returns (uint)
    {
        return projectBonus;
    }

    function takeProjectBonus(address to, uint value)
    onlyAdministrator()
    public {
        require(value <= projectBonus);
        to.transfer(value);
    }


    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */
    function totalEthereumBalance()
    public
    view
    returns (uint)
    {
        return address(this).balance;
    }

    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
    public
    view
    returns (uint256)
    {
        return tokenSupply_;
    }


    // erc 20
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
    public
    view
    returns (uint256)
    {
        address _customerAddress = msg.sender;
        return getBalance(_customerAddress);
    }

    function getProfitPerShare()
    public
    view
    returns (uint256)
    {
        return (uint256) ((int256)(tokenSupply_*profitPerShare_)) / magnitude;
    }

    function getContractETH()
    public
    view
    returns (uint256)
    {
        return address(this).balance;
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
    returns (uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
    view
    public
    returns (uint256)
    {
        if(contractAddresses[_customerAddress]){
            return 0;
        }
        return tokenBalanceLedger_[_customerAddress];
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function getBalance(address _customerAddress)
    view
    public
    returns (uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress)
    view
    public
    returns (uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    /**
     * Return the buy price of 1 individual token.
     */
    function sellPrice()
    public
    view
    returns (uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
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
    returns (uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
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
    returns (uint256)
    {
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
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
    returns (uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }


    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
    internal
    returns (uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);

        if (isProjectBonus) {
            uint temp = SafeMath.div(_undividedDividends, projectBonusRate);
            _dividends = SafeMath.sub(_dividends, temp);
            projectBonus = SafeMath.add(projectBonus, temp);
        }

        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_));

        // is the user referred by a masternode?
        if (
        // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != _customerAddress &&

            // does the referrer have at least X whole tokens?
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        // we can&#39;t give people infinite ethereum
        if (tokenSupply_ > 0) {

            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

            // calculate the amount of tokens the customer receives over his purchase
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        // Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them;
        //really i know you think you do but you don&#39;t
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        // fire event
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }

    /**
     * Calculate Token price based on an amount of incoming ethereum
     * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function ethereumToTokens_(uint256 _ethereum)
    internal
    view
    returns (uint256)
    {
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
            (((tokenPriceIncremental_) ** 2) * (tokenSupply_ ** 2))
            +
            (2 * (tokenPriceIncremental_) * _tokenPriceInitial * tokenSupply_)
        )
            ), _tokenPriceInitial
        )
        ) / (tokenPriceIncremental_)
        ) - (tokenSupply_)
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
    returns (uint256)
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
            tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e18))
            ) - tokenPriceIncremental_
            ) * (tokens_ - 1e18)
            ), (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e18)) / 2
        )
        / 1e18);
        return _etherReceived;
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

contract ERC223Receiving {
    function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
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