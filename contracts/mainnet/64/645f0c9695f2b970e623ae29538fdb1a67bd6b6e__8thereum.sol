pragma solidity ^0.4.24;



contract _8thereum {



    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyTokenHolders() 
    {
        require(myTokens() > 0);
        _;
    }
    
    // only people with profits
    modifier onlyDividendPositive() 
    {
        require(myDividends(true) > 0);
        _;
    }

    // only owner
    modifier onlyOwner() 
    { 
        require (address(msg.sender) == owner); 
        _; 
    }
    
    // only non-whales
    modifier onlyNonOwner() 
    { 
        require (address(msg.sender) != owner); 
        _; 
    }
    
    modifier onlyFoundersIfNotPublic() 
    {
        if(!openToThePublic)
        {
            require (founders[address(msg.sender)] == true);   
        }
        _;
    }    
    
    modifier onlyApprovedContracts()
    {
        if(!gameList[msg.sender])
        {
            require (msg.sender == tx.origin);
        }
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
    
    event lotteryPayout(
        address customerAddress, 
        uint256 lotterySupply
    );
    
    event whaleDump(
        uint256 amount
    );
    
    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "8thereum";
    string public symbol = "BIT";
    bool public openToThePublic = false;
    address public owner;
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee = 15;
    uint256 constant internal tokenPrice = 500000000000000;//0.0005 ether
    uint256 constant internal magnitude = 2**64;
    uint256 constant public referralLinkRequirement = 5e18;// 5 token minimum for referral link
    
   /*================================
    =            DATASETS            =
    ================================*/
    mapping(address => bool) internal gameList;
    mapping(address => uint256) internal publicTokenLedger;
    mapping(address => uint256) public   whaleLedger;
    mapping(address => uint256) public   gameLedger;
    mapping(address => uint256) internal referralBalances;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => mapping(address => uint256)) public gamePlayers;
    mapping(address => bool) internal founders;
    address[] lotteryPlayers;
    uint256 internal lotterySupply = 0;
    uint256 internal tokenSupply = 0;
    uint256 internal gameSuppply = 0;
    uint256 internal profitPerShare_;
    
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor()
        public
    {
        // no admin, but the owner of the contract is the address used for whale
        owner = address(msg.sender);

        // add founders here... Founders don&#39;t get any special priveledges except being first in line at launch day
        founders[owner] = true; //owner&#39;s address
        founders[0x7e474fe5Cfb720804860215f407111183cbc2f85] = true; //KENNY
        founders[0x5138240E96360ad64010C27eB0c685A8b2eDE4F2] = true; //crypt0b!t 
        founders[0xAA7A7C2DECB180f68F11E975e6D92B5Dc06083A6] = true; //NumberOfThings 
        founders[0x6DC622a04Fd13B6a1C3C5B229CA642b8e50e1e74] = true; //supermanlxvi
        founders[0x41a21b264F9ebF6cF571D4543a5b3AB1c6bEd98C] = true; //Ravi
    }
    
     
    /**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral address
     */
    function buy(address referredyBy)
        onlyFoundersIfNotPublic()
        public
        payable
        returns(uint256)
    {
        require (msg.sender == tx.origin);
        excludeWhale(referredyBy); 
    }
    
    /**
     * Fallback function to handle ethereum that was send straight to the contract
     */
    function()
        onlyFoundersIfNotPublic()
        payable
        public
    {
        require (msg.sender == tx.origin);
        excludeWhale(0x0); 
    }
    
    /**
     * Converts all of caller&#39;s dividends to tokens.
     */
    function reinvest()
        onlyDividendPositive()
        onlyNonOwner()
        public
    {   
        
        require (msg.sender == tx.origin);
        
        // fetch dividends
        uint256 dividends = myDividends(false); // retrieve ref. bonus later in the code
        
        // pay out the dividends virtually
        address customerAddress = msg.sender;
        payoutsTo_[customerAddress] +=  int256(SafeMath.mul(dividends, magnitude));
        
        // retrieve ref. bonus
        dividends += referralBalances[customerAddress];
        referralBalances[customerAddress] = 0;
        
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(dividends, 0x0);
        
        // fire event for logging 
        emit onReinvestment(customerAddress, dividends, _tokens);
    }
    
    /**
     * Alias of sell() and withdraw().
     */
    function exit()
        onlyNonOwner()
        onlyTokenHolders()
        public
    {
        require (msg.sender == tx.origin);
        
        // get token count for caller & sell them all
        address customerAddress = address(msg.sender);
        uint256 _tokens = publicTokenLedger[customerAddress];
        
        if(_tokens > 0) 
        {
            sell(_tokens);
        }

        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
        onlyNonOwner()
        onlyDividendPositive()
        public
    {
        require (msg.sender == tx.origin);
        
        // setup data
        address customerAddress = msg.sender;
        uint256 dividends = myDividends(false); // get ref. bonus later in the code
        
        // update dividend tracker
        payoutsTo_[customerAddress] +=  int256(SafeMath.mul(dividends, magnitude));
        
        // add ref. bonus
        dividends += referralBalances[customerAddress];
        referralBalances[customerAddress] = 0;
        
        customerAddress.transfer(dividends);
        
        // fire event for logging 
        emit onWithdraw(customerAddress, dividends);
    }
    
    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens)
        onlyNonOwner()
        onlyTokenHolders()
        public
    {
        require (msg.sender == tx.origin);
        require((_amountOfTokens <= publicTokenLedger[msg.sender]) && (_amountOfTokens > 0));

        uint256 _tokens = _amountOfTokens;
        uint256 ethereum = tokensToEthereum_(_tokens);
        uint256 dividends = (ethereum * dividendFee) / 100;
        uint256 taxedEthereum = SafeMath.sub(ethereum, dividends);
        
        //Take some divs for the lottery and whale
        uint256 lotteryAndWhaleFee = dividends / 3;
        dividends -= lotteryAndWhaleFee;
        
        //figure out the lotteryFee
        uint256 lotteryFee = lotteryAndWhaleFee / 2;
        //add tokens to the whale
        uint256 whaleFee = lotteryAndWhaleFee - lotteryFee;
        whaleLedger[owner] += whaleFee;
        //add tokens to the lotterySupply
        lotterySupply += ethereumToTokens_(lotteryFee);
        // burn the sold tokens
        tokenSupply -=  _tokens;
        publicTokenLedger[msg.sender] -= _tokens;
        
        
        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (taxedEthereum * magnitude));
        payoutsTo_[msg.sender] -= _updatedPayouts;  
        
        // dividing by zero is a bad idea
        if (tokenSupply > 0) 
        {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (dividends * magnitude) / tokenSupply);
        }
        
        // fire event for logging 
        emit onTokenSell(msg.sender, _tokens, taxedEthereum);
    }
    
    
    /**
     * Transfer tokens from the caller to a new holder.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyNonOwner()
        onlyTokenHolders()
        onlyApprovedContracts()
        public
        returns(bool)
    {
        assert(_toAddress != owner);
        
        // setup
        if(gameList[msg.sender] == true) //If game is transferring tokens
        {
            require((_amountOfTokens <= gameLedger[msg.sender]) && (_amountOfTokens > 0 ));
             // exchange tokens
            gameLedger[msg.sender] -= _amountOfTokens;
            gameSuppply -= _amountOfTokens;
            publicTokenLedger[_toAddress] += _amountOfTokens; 
            
            // update dividend trackers
            payoutsTo_[_toAddress] += int256(profitPerShare_ * _amountOfTokens); 
        }
        else if (gameList[_toAddress] == true) //If customer transferring tokens to game
        {
            // make sure we have the requested tokens
            //each game should only cost one token to play
            require((_amountOfTokens <= publicTokenLedger[msg.sender]) && (_amountOfTokens > 0 && (_amountOfTokens == 1e18)));
             
             // exchange tokens
            publicTokenLedger[msg.sender] -=  _amountOfTokens;
            gameLedger[_toAddress] += _amountOfTokens; 
            gameSuppply += _amountOfTokens;
            gamePlayers[_toAddress][msg.sender] += _amountOfTokens;
            
            // update dividend trackers
            payoutsTo_[msg.sender] -= int256(profitPerShare_ * _amountOfTokens);
        }
        else{
            // make sure we have the requested tokens
            require((_amountOfTokens <= publicTokenLedger[msg.sender]) && (_amountOfTokens > 0 ));
                // exchange tokens
            publicTokenLedger[msg.sender] -= _amountOfTokens;
            publicTokenLedger[_toAddress] += _amountOfTokens; 
            
            // update dividend trackers
            payoutsTo_[msg.sender] -= int256(profitPerShare_ * _amountOfTokens);
            payoutsTo_[_toAddress] += int256(profitPerShare_ * _amountOfTokens); 
            
        }
        
        // fire event for logging 
        emit Transfer(msg.sender, _toAddress, _amountOfTokens); 
        
        // ERC20
        return true;
       
    }
    
    /*----------  OWNER ONLY FUNCTIONS  ----------*/

    /**
     * future games can be added so they can&#39;t earn divs on their token balances
     */
    function setGames(address newGameAddress)
    onlyOwner()
    public
    {
        gameList[newGameAddress] = true;
    }
    
    /**
     * Want to prevent snipers from buying prior to launch
     */
    function goPublic() 
        onlyOwner()
        public 
        returns(bool)

    {
        openToThePublic = true;
        return openToThePublic;
    }
    
    
    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Ethereum stored in the contract
     */
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    
    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return (tokenSupply + lotterySupply + gameSuppply); //adds the tokens from ambassadors to the supply (but not to the dividends calculation which is based on the supply)
    }
    
    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        return balanceOf(msg.sender);
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
        return _includeReferralBonus ? dividendsOf(msg.sender) + referralBalances[msg.sender] : dividendsOf(msg.sender) ;
    }
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 balance;

        if (customerAddress == owner) 
        { 
            // to show div balance of owner
            balance = whaleLedger[customerAddress]; 
        }
        else if(gameList[customerAddress] == true) 
        {
            // games can still see their token balance
            balance = gameLedger[customerAddress];
        }
        else 
        {   
            // to see token balance for anyone else
            balance = publicTokenLedger[customerAddress];
        }
        return balance;
    }
    
    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address customerAddress)
        view
        public
        returns(uint256)
    {
      return (uint256) ((int256)(profitPerShare_ * publicTokenLedger[customerAddress]) - payoutsTo_[customerAddress]) / magnitude;
    }
    
    /**
     * Return the buy and sell price of 1 individual token.
     */
    function buyAndSellPrice()
    public
    pure 
    returns(uint256)
    {
        uint256 ethereum = tokenPrice;
        uint256 dividends = SafeMath.div(SafeMath.mul(ethereum, dividendFee ), 100);
        uint256 taxedEthereum = SafeMath.sub(ethereum, dividends);
        return taxedEthereum;
    }
    
    /**
     * Function for the frontend to dynamically retrieve the price of buy orders.
     */
    function calculateTokensReceived(uint256 ethereumToSpend) 
        public 
        pure 
        returns(uint256)
    {
        require(ethereumToSpend >= tokenPrice);
        uint256 dividends = SafeMath.div(SafeMath.mul(ethereumToSpend, dividendFee ), 100);
        uint256 taxedEthereum = SafeMath.sub(ethereumToSpend, dividends);
        uint256 amountOfTokens = ethereumToTokens_(taxedEthereum);
        
        return amountOfTokens;
    }
    
    /**
     * Function for the frontend to dynamically retrieve the price of sell orders.
     */
    function calculateEthereumReceived(uint256 tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(tokensToSell <= tokenSupply);
        uint256 ethereum = tokensToEthereum_(tokensToSell);
        uint256 dividends = SafeMath.div(SafeMath.mul(ethereum, dividendFee ), 100);
        uint256 taxedEthereum = SafeMath.sub(ethereum, dividends);
        return taxedEthereum;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    
    
    function excludeWhale(address referredyBy) 
        onlyNonOwner()
        internal 
        returns(uint256) 
    { 
        require (msg.sender == tx.origin);
        uint256 tokenAmount;

        tokenAmount = purchaseTokens(msg.value, referredyBy); //redirects to purchaseTokens so same functionality

        if(gameList[msg.sender] == true)
        {
            tokenSupply = SafeMath.sub(tokenSupply, tokenAmount); // takes out game&#39;s tokens from the tokenSupply (important for redistribution)
            publicTokenLedger[msg.sender] = SafeMath.sub(publicTokenLedger[msg.sender], tokenAmount); // takes out game&#39;s tokens from its ledger so it is "officially" holding 0 tokens. (=> doesn&#39;t receive dividends anymore)
            gameLedger[msg.sender] += tokenAmount;    //it gets a special ledger so it can&#39;t sell its tokens
            gameSuppply += tokenAmount; // we need this for a correct totalSupply() number later
        }

        return tokenAmount;
    }


    function purchaseTokens(uint256 incomingEthereum, address referredyBy)
        internal
        returns(uint256)
    {
        require (msg.sender == tx.origin);
        // data setup
        uint256 undividedDivs = SafeMath.div(SafeMath.mul(incomingEthereum, dividendFee ), 100);
        
        //divide the divs
        uint256 lotteryAndWhaleFee = undividedDivs / 3;
        uint256 referralBonus = lotteryAndWhaleFee;
        uint256 dividends = SafeMath.sub(undividedDivs, (referralBonus + lotteryAndWhaleFee));
        uint256 taxedEthereum = incomingEthereum - undividedDivs;
        uint256 amountOfTokens = ethereumToTokens_(taxedEthereum);
        uint256 whaleFee = lotteryAndWhaleFee / 2;
        //add divs to whale
        whaleLedger[owner] += whaleFee;
        
        //add tokens to the lotterySupply
        lotterySupply += ethereumToTokens_(lotteryAndWhaleFee - whaleFee);
        
        //add entry to lottery
        lotteryPlayers.push(msg.sender);
       
        uint256 fee = dividends * magnitude;
 
        require(amountOfTokens > 0 && (amountOfTokens + tokenSupply) > tokenSupply);
        
        // is the user referred by a masternode?
        if(
            // is this a referred purchase?
            referredyBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            referredyBy != msg.sender && 
            
            //can&#39;t use games for referralBonus
            gameList[referredyBy] == false  &&
            
            // does the referrer have at least 5 tokens?
            publicTokenLedger[referredyBy] >= referralLinkRequirement
        )
        {
            // wealth redistribution
            referralBalances[referredyBy] += referralBonus;
        } else
        {
            // no ref purchase
            // add the referral bonus back
            dividends += referralBonus;
            fee = dividends * magnitude;
        }

        uint256 payoutDividends = isWhalePaying();
        
        // we can&#39;t give people infinite ethereum
        if(tokenSupply > 0)
        {
            // add tokens to the pool
            tokenSupply += amountOfTokens;
            
             // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += ((payoutDividends + dividends) * magnitude / (tokenSupply));
            
            // calculate the amount of tokens the customer receives over his purchase 
            fee -= fee-(amountOfTokens * (dividends * magnitude / (tokenSupply)));
        } else 
        {
            // add tokens to the pool
            tokenSupply = amountOfTokens;
            
            //if there are zero tokens prior to this buy, and the whale is triggered, send dividends back to whale
            if(whaleLedger[owner] == 0)
            {
                whaleLedger[owner] = payoutDividends;
            }
        }

        // update circulating supply & the ledger address for the customer
        publicTokenLedger[msg.sender] += amountOfTokens;
        
        // Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them;
        // BUT, you still get the whale&#39;s divs from your purchase.... so, you still get SOMETHING.
        int256 _updatedPayouts = int256((profitPerShare_ * amountOfTokens) - fee);
        payoutsTo_[msg.sender] += _updatedPayouts;
        
     
        // fire event for logging 
        emit onTokenPurchase(msg.sender, incomingEthereum, amountOfTokens, referredyBy);
        
        return amountOfTokens;
    }
    
    
     /**
     * Calculate token sell value.
     * It&#39;s a simple algorithm. Hopefully, you don&#39;t need a whitepaper with it in scientific notation.
     */
    function isWhalePaying()
    private
    returns(uint256)
    {
        uint256 payoutDividends = 0;
         // this is where we check for lottery winner
        if(whaleLedger[owner] >= 1 ether)
        {
            if(lotteryPlayers.length > 0)
            {
                uint256 winner = uint256(blockhash(block.number-1))%lotteryPlayers.length;
                
                publicTokenLedger[lotteryPlayers[winner]] += lotterySupply;
                emit lotteryPayout(lotteryPlayers[winner], lotterySupply);
                tokenSupply += lotterySupply;
                lotterySupply = 0;
                delete lotteryPlayers;
               
            }
            //whale pays out everyone its divs
            payoutDividends = whaleLedger[owner];
            whaleLedger[owner] = 0;
            emit whaleDump(payoutDividends);
        }
        return payoutDividends;
    }

    /**
     * Calculate Token price based on an amount of incoming ethereum
     *It&#39;s a simple algorithm. Hopefully, you don&#39;t need a whitepaper with it in scientific notation.
     */
    function ethereumToTokens_(uint256 ethereum)
        internal
        pure
        returns(uint256)
    {
        uint256 tokensReceived = ((ethereum / tokenPrice) * 1e18);
               
        return tokensReceived;
    }
    
    /**
     * Calculate token sell value.
     * It&#39;s a simple algorithm. Hopefully, you don&#39;t need a whitepaper with it in scientific notation.
     */
     function tokensToEthereum_(uint256 coin)
        internal
        pure
        returns(uint256)
    {
        uint256 ethReceived = tokenPrice * (SafeMath.div(coin, 1e18));
        
        return ethReceived;
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