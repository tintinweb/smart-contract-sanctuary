/**
 * www.the8020.ch
*/

pragma solidity ^0.6.0;

   /*==================================================================================
    =  The 80/20 is a Wealth Distribution system that is open for anyone to use.      =  
    =  We created this application with hopes that it will provide a steady stream    =
    =  of passive income for generations to come. The foundation that stands behind   =
    =  this product would like you to live happy, free, and prosperous.               =
    =  Stay tuned for more dApps from the GSG Global Marketing Group.                 =
    =  #LuckyRico #LACGold #JCunn24 #BoHarvey #LennyBones #WealthWithPhelps 	      =
    =  #ShahzainTariq >= developer of this smart contract		 				      =
    ================================================================================*/

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract auto_pool is IERC20{
    
    using SafeMath for uint256;
    
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlybelievers () {
        require(myTokens() > 0);
        _;
    }
    
    // only people with profits
    modifier onlyhodler() {
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
        uint256 time,
        uint256 totalTokens
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint256 time,
        uint256 totalTokens
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
    
    event distrubuteBonusFund(
        address,
        uint256
        );
        
    event amountDistributedToSponsor(
        address,
        address,
        uint256
        );
    
    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens,
        uint256 time
    );
    
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name ;
    string public symbol ;
    uint8 public decimals ;
    uint8 internal dividendFee_ ;
    uint256 internal tokenPriceInitial_ ;
    uint256 internal tokenPriceIncremental_ ;
    uint256 internal magnitude;

    uint256 public tokenPool;
    uint256 public loyaltyPool;
    uint256 public developmentFund;
    uint256 public sponsorsPaid;
    uint256 public gsg_foundation;
    address dev1;
    address dev2;
    address GSGO_Official_LoyaltyPlan;
    uint256 public currentId;
    uint256 public day;
    uint256 public claimedLoyalty;
    uint256 public totalDeposited;    
    uint256 public totalWithdraw;
  
  
    
    
   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => uint256) public  referralBalance_;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => int256) public payoutsTo_;
    mapping(address => basicData) public users;
    mapping(uint256 => address) public userList;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    uint256 internal profitperLoyalty;
    
    //Users's data set
    struct basicData{
        bool isExist;
        uint256 id;
        uint256 referrerId;
        address referrerAdd;
    }

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor() public{
        name = "The-Eighty-Twenty";
        symbol = "GS20";
        decimals = 18;
        dividendFee_ = 10;
        tokenPriceInitial_ = 0.0000001 ether;
        tokenPriceIncremental_ = 0.00000001 ether;
        magnitude = 2**64;
        // "This is the distribution contract for holders of the GSG-Official (GSGO) Token."
        GSGO_Official_LoyaltyPlan = address(0x727395b95C90DEab2F220Ce42615d9dD0F44e187);
        dev1 = address(0x88F2E544359525833f606FB6c63826E143132E7b);
        dev2 = address(0x7cF196415CDD1eF08ca2358a8282D33Ba089B9f3);
        currentId = 0;
        day = now;
    
    }
    
     
    /**
     * Converts all incoming Ethereum to tokens for the caller, and passes down the referral address (if any)
     */
    function buy(address _referredAdd)
        public  
        payable
        returns(uint256)
    {
        require(msg.value >= 0.1 ether, "ERROR: minimun 0.1 ethereum ");
        require(_referredAdd != msg.sender,"ERROR: cannot become own ref");
        
        if(!users[msg.sender].isExist) register(msg.sender,_referredAdd);
        
        purchaseTokens(msg.value,_referredAdd);
         
        //Distributing Ethers
        loyaltyPool += ((msg.value.mul(12)).div(100));
        developmentFund += ((msg.value.mul(2)).div(100));
        gsg_foundation += ((msg.value.mul(2)).div(100));
        payable(GSGO_Official_LoyaltyPlan).transfer((msg.value.mul(2)).div(100));
        payable(dev1).transfer((msg.value.mul(1)).div(100));
        payable(dev2).transfer((msg.value.mul(1)).div(100));
        totalDeposited += msg.value;

    }
    
    receive() external payable {
         require(msg.value >= 0.1 ether, "ERROR: minimun 0.1 ethereum .");

     if(!users[msg.sender].isExist) register(msg.sender,address(0));

        purchaseTokens(msg.value,address(0));
         
        //Distributing Ethers
        loyaltyPool += ((msg.value.mul(12)).div(100));
        developmentFund += ( (msg.value.mul(2)).div(100));
        gsg_foundation += ((msg.value.mul(2)).div(100));
        payable(GSGO_Official_LoyaltyPlan).transfer((msg.value.mul(2)).div(100));
        payable(dev1).transfer((msg.value.mul(1)).div(100));
        payable(dev2).transfer((msg.value.mul(1)).div(100)); 
    }
    
    fallback()
        payable
        external
    {
    require(msg.value >= 0.1 ether, "ERROR: minimun 0.1 ethereum .");

     if(!users[msg.sender].isExist) register(msg.sender,address(0));

        purchaseTokens(msg.value,address(0));
         
        //Distributing Ethers
        loyaltyPool += ((msg.value.mul(12)).div(100));
        developmentFund += ( (msg.value.mul(2)).div(100));
        gsg_foundation += ((msg.value.mul(2)).div(100));
        payable(GSGO_Official_LoyaltyPlan).transfer((msg.value.mul(2)).div(100));
        payable(dev1).transfer((msg.value.mul(1)).div(100));
        payable(dev2).transfer((msg.value.mul(1)).div(100));    }
    
    /**
     * Converts all of caller's dividends to tokens.
     */
    function reinvest()
        onlyhodler()
        public
    {
        address _customerAddress = msg.sender;
        // fetch dividends
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code
        
        uint256 _loyaltyEth = loyaltyOf();
        if(_loyaltyEth > 0 ether){
            payable(address(_customerAddress)).transfer(_loyaltyEth);
                loyaltyPool -= _loyaltyEth;
                claimedLoyalty += _loyaltyEth;
                totalWithdraw += _loyaltyEth;
        }       
        
        // pay out the dividends virtually
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        
        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        address refAdd = users[_customerAddress].referrerAdd;
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends,refAdd);
        loyaltyPool += ((_dividends.mul(12)).div(100));
        developmentFund += ((_dividends.mul(2)).div(100));
        gsg_foundation += ((_dividends.mul(2)).div(100));
        payable(GSGO_Official_LoyaltyPlan).transfer((_dividends.mul(2)).div(100));
        payable(dev1).transfer((_dividends.mul(1)).div(100));
        payable(dev2).transfer((_dividends.mul(1)).div(100));
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
        if(_tokens > 0) sell(_tokens);
        
        
        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
        onlyhodler()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code
        uint256 _loyaltyEth = loyaltyOf();

        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        if(_loyaltyEth > 0 ether) {
            _dividends += _loyaltyEth;
            loyaltyPool -= _loyaltyEth;
            claimedLoyalty += _loyaltyEth;
        }       
        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        totalWithdraw += _dividends;

        // delivery service
        payable(address(_customerAddress)).transfer(_dividends);
        
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    
    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens)
        onlybelievers ()
        public
    {
      
        address _customerAddress = msg.sender;
       
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        //initializating values; 
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 tax = (_ethereum.mul(5)).div(100);
        loyaltyPool = SafeMath.add(loyaltyPool,tax);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, tax);
    
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        
       //updates dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;       
        payoutsTo_[_customerAddress] += (int256) (_taxedEthereum*magnitude);       
     
        totalWithdraw += _taxedEthereum; 
   
        //tranfer amout of ethers to user
        payable(address(_customerAddress)).transfer(_taxedEthereum);
        
        if(_ethereum < tokenPool) {
            tokenPool = SafeMath.sub(tokenPool, _ethereum);   
        }
        // fire event
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum,now,tokenBalanceLedger_[_customerAddress]);
    }
    
    
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
     function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
     function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's a 10% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlybelievers ()
        public
        override
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        
        // make sure we have the requested tokens
     
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        
        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);
        
       // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens,now);
        
        // ERC20
        return true;
       
    }
    
    function transferFrom(address sender, address _toAddress, uint _amountOfTokens) public override returns (bool) {
        // setup
        address _customerAddress = sender;
        
        // make sure we have the requested tokens
     
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        
        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);
        
       // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens,now);
        
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(_amountOfTokens, "ERC20: transfer amount exceeds allowance"));
        return true;
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
        return address(this).balance;
    }
    
    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        override
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
       */ 
    function myDividends(bool _includeReferralBonus) 
        public 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        override
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
       
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 tax = (_ethereum.mul(5)).div(100);
            uint256 _dividends = SafeMath.div(_ethereum, tax);
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
        
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    
   
    function calculateTokensReceived(uint256 _ethToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _ethereumToSpend = (_ethToSpend.mul(64)).div(100);
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        
        return _amountOfTokens;
    }
    
    
    function getReferrer() public view returns(address){
        return users[msg.sender].referrerAdd;
    }
   
    function calculateEthereumReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 tax = (_ethereum.mul(5)).div(100);
        uint256 _dividends = SafeMath.div(_ethereum, tax);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
   
    function loyaltyOf() public view returns(uint256){
        address _customerAddress = msg.sender;
        
        // user should hold 2500 tokens for qualify for loyalty bonus;
        if(tokenBalanceLedger_[_customerAddress] >= 2000*10**uint256(decimals)){
            // return loyalty bonus users
            return ((uint256) ((int256)((profitperLoyalty) * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude)*14/5;
        }
        else{
            return 0;
        }
    }
    
    function userReferrer(address _address) public view returns(address){
        return userList[users[_address].referrerId];
    }
 
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint256 _eth, address _referredBy)
        internal
        returns(uint256)
    {
        uint256 _incomingEthereum = (_eth.mul(64)).div(100);
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
        tokenPool += _taxedEthereum;

      
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
       
        // is the user referred by a karmalink?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != _customerAddress 
            
        ){
            // wealth redistribution
            
            distributeToSponsor(_referredBy,_eth);
            
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        
        // we can't give people infinite ethereum
        if(tokenSupply_ > 0){
            
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
 
            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            profitperLoyalty += ((_dividends) * magnitude / (tokenSupply_));


            // calculate the amount of tokens the customer receives over his purchase 
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }
        
        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        //update dividends tracker
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
            
        // fire event
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy,now,tokenBalanceLedger_[_customerAddress]);
        
        return _amountOfTokens;
    }

       
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

         _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * Calculate Token price based on an amount of incoming ethereum
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
    
    
    function register(address _sender, address _referredBy) internal {
        
        uint256 _id = users[_referredBy].id; 
        
        basicData memory UserStruct;
        currentId++;
        
        //add users data
        UserStruct = basicData({
            isExist: true,
            id: currentId,
            referrerId: _id,
            referrerAdd: _referredBy
        });
        

        userList[currentId] = _sender;
        users[msg.sender] = UserStruct;
    }
    
    function distributeToSponsor(address _address,uint256 _eth) internal {
        uint256 _sp1 = (_eth.mul(10)).div(100);
        uint256 _sp2 = (_eth.mul(7)).div(100);
        uint256 _sp3 = (_eth.mul(3)).div(100);
        
        address add1 = _address;
        address add2 = users[_address].referrerAdd;
        address add3 = users[add2].referrerAdd;
        
        //add amount of ref bonus to referrer
        referralBalance_[add1] +=  (_sp1);
        
        sponsorsPaid += _sp1;
        //fire event on distributionToSponsor
        emit amountDistributedToSponsor(msg.sender, add1,_sp1);
        
        //add amount of ref bonus to referrer
        referralBalance_[add2] += (_sp2);
        
        sponsorsPaid += _sp2;
        //fire event on distributionToSponsor
        emit amountDistributedToSponsor(msg.sender, add2, _sp2);

        //add amount of ref bonus to referrer
        referralBalance_[add3] +=  (_sp3);
        
        sponsorsPaid += _sp3;
        //fire event on distributionToSponsor
        emit amountDistributedToSponsor(msg.sender, add3, _sp3);
    }
    
    
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
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}