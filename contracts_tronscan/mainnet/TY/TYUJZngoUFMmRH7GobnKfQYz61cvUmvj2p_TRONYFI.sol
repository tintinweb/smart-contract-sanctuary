//SourceUnit: final_tyfi.sol

pragma solidity ^0.4.25;

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


contract TRONYFI {
      

    /**
    *Events            
    */
    event TokenPurchased(
        address indexed customerAddress,
        uint256 incomingTron,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event TokenSold(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 tronEarned
    );

    event Reinvested(
        address indexed customerAddress,
        uint256 tronReinvested,
        uint256 tokensMinted
    );

    event Withdrawed(
        address indexed customerAddress,
        uint256 trWithdrawedn
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


     /*=====================================
    =        Variable Declarations        =
    =====================================*/
    string public name = "TRONYFI";
    string public symbol = "TYFI";
    uint8 constant public decimals = 6;
    uint8 constant internal buyFee_ = 15;   //15% 
    uint8 constant internal sellFee_ = 10;  //10%
    uint256 constant internal tronDecimal = 1e6;
    uint256 constant internal initialSupply = 400000 * (10 ** uint256(6));

    uint256 internal tokenPriceInitial_ = 4 * (10 ** uint256(6));
    uint256 internal tokenPriceIncremental_ = 19;
    uint256 constant internal magnitude = 2 ** 64;
    uint256 public MaxSupply = 1500000 * (10 ** uint256(6));

    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

    uint256 public stakingRequirement = tronDecimal;
    uint256 public playerCount_;
    uint256 public totalInvested = 0;
    uint256 public totalDividends = 0;
    address internal devAddress_;

    bool public exchangeClosed = true;

    

    struct ReferralData {
        address affFrom;
        uint256 affRewardsSum;
        uint256 affCount1Sum;
        uint256 affCount2Sum;
        uint256 joinDate;
       
    }
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;
    
    

    mapping(address => bool) public players_;
    mapping(address => uint256) public totalDeposit_;
    mapping(address => uint256) public totalWithdraw_;
    
    
    mapping(address => uint256) public tokenStakeBalanceLedger_;
    mapping(address => uint256) public stakeTime;
    mapping(address => uint256) public totalPayout;

    mapping(address => ReferralData) public referralData;


    
    // only people with tokens
    modifier onlyTokenholders() {
        require(myTokens() > 0);
        _;
    }




    constructor()
        public
    {
        devAddress_ = msg.sender;
        tokenBalanceLedger_[devAddress_] = initialSupply; //400k Initial supply
        tokenSupply_ = initialSupply;
        referralData[msg.sender].affFrom = devAddress_;
    }

  
    function buy()
        public
        payable
        returns(uint256)
    {
        require(exchangeClosed);
        require(referralData[msg.sender].affFrom != address(0),"Register to TYFI System first");
        require(tokenSupply_<=MaxSupply,"Total Supply Limit Reached");
        totalInvested = SafeMath.add(totalInvested,msg.value);
        totalDeposit_[msg.sender] = SafeMath.add(totalDeposit_[msg.sender],msg.value);

        if(players_[msg.sender] == false){
          playerCount_ = playerCount_ + 1;
          players_[msg.sender] = true;
        }
        uint256 _amountOfTokens = purchaseTokens(msg.value, referralData[msg.sender].affFrom);

        emit TokenPurchased(msg.sender, msg.value, _amountOfTokens, referralData[msg.sender].affFrom);
    }

    function()
        payable
        public
    {
        purchaseTokens(msg.value, 0x0);
    }



 
 

    

    function sell(uint256 _amountOfTokens)
        onlyTokenholders()
        public
    {
        address _customerAddress = msg.sender;
        require(exchangeClosed);
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _tron = tokensToTron_(_tokens);
        uint256 _dividends = SafeMath.div(_tron, sellFee_);  
        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);

      
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        _customerAddress.transfer(_taxedTron);
        devAddress_.transfer(_dividends);
        
        // Decremental Price
        uint256 priceTokenInc = (incrementalPrice()*(_amountOfTokens))/tronDecimal;
        if(priceTokenInc == 0){
            priceTokenInc = incrementalPrice();
        }
        tokenPriceInitial_ = SafeMath.sub(tokenPriceInitial_, priceTokenInc);


        emit TokenSold(_customerAddress, _tokens, _taxedTron);
    }



    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyTokenholders()
        public
        returns(bool)
    {
        require(_toAddress != address(0));
        require(tokenBalanceLedger_[msg.sender] != 0);
        // setup
        address _customerAddress = msg.sender;

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        // ERC20
        return true;

    }
    
    
    // Staking Code

    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount*365/100; // 365% max Payout
    }
    
    function payoutOf(address _customerAddress) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(tokenStakeBalanceLedger_[_customerAddress]);
        // require(tokenSupply_<=MaxSupply,"Total Supply Limit Reached");
        if(totalPayout[_customerAddress] < max_payout) {
            payout = (tokenStakeBalanceLedger_[_customerAddress] * ((block.timestamp - stakeTime[_customerAddress]) / 1 days) / 100) - totalPayout[_customerAddress];
            
            if(totalPayout[_customerAddress] + payout > max_payout) {
                payout = max_payout - totalPayout[_customerAddress];
            }
        }
    }
    
    function withdrawDailyStakeInternal() internal {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        address _customerAddress = msg.sender;
        require(totalPayout[_customerAddress] < max_payout, "Full payouts");
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress],to_payout);
        totalPayout[_customerAddress] = SafeMath.add(totalPayout[_customerAddress],to_payout);
        tokenSupply_ = SafeMath.add(tokenSupply_, to_payout);

        // Price Incremental
        uint256 priceTokenInc = ((incrementalPrice())*(to_payout))/tronDecimal;
        if(priceTokenInc == 0){
            priceTokenInc = incrementalPrice();
        }
        
        tokenPriceInitial_ = SafeMath.add(tokenPriceInitial_, priceTokenInc);
    }

    function withdrawDailyStake() public{
        require(tokenStakeBalanceLedger_[msg.sender] != 0,'There is no Stake');
        withdrawDailyStakeInternal();
    }
   
    function holdStake(uint256 _amount)
        onlyTokenholders()
        public
        {
            require(_amount<=tokenBalanceLedger_[msg.sender]);
            require(tokenStakeBalanceLedger_[msg.sender]==0);
            stakeTime[msg.sender] = now; 
            tokenBalanceLedger_[msg.sender] = SafeMath.sub(tokenBalanceLedger_[msg.sender], _amount);
            tokenStakeBalanceLedger_[msg.sender] = SafeMath.add(tokenStakeBalanceLedger_[msg.sender], _amount);
            
        }
        
    function reStake(uint256 _amount)
        onlyTokenholders()
        public
        {
            require(_amount<=tokenBalanceLedger_[msg.sender]);
            require(tokenStakeBalanceLedger_[msg.sender]>0);
            withdrawDailyStakeInternal(); //Withdraws Daily Stake Before ReStaking
            
            tokenBalanceLedger_[msg.sender] = SafeMath.sub(tokenBalanceLedger_[msg.sender], _amount);
            tokenStakeBalanceLedger_[msg.sender] = SafeMath.add(tokenStakeBalanceLedger_[msg.sender], _amount);
  
        }
       
    function unstake()
        public
    {
        require(tokenStakeBalanceLedger_[msg.sender] != 0,'There is no Stake');
        withdrawDailyStakeInternal(); //Withdraws Daily Stake Before Unstaking

        uint256 secPassed = SafeMath.sub(now,stakeTime[msg.sender]);
        uint256 _amount = tokenStakeBalanceLedger_[msg.sender];
        address _customerAddress = msg.sender;
         
        if(secPassed>30 days){ 
            tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress],_amount);
            tokenStakeBalanceLedger_[_customerAddress] = SafeMath.sub(tokenStakeBalanceLedger_[_customerAddress], _amount);
            totalPayout[_customerAddress] = 0;
            tokenStakeBalanceLedger_[_customerAddress] =0;
        }
        else{
            uint256 penaltyCalculation = (_amount*3)/10;
            uint256 penalty = SafeMath.sub(_amount,penaltyCalculation);
            tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress],penalty);
            tokenBalanceLedger_[devAddress_] = SafeMath.add(tokenBalanceLedger_[_customerAddress],penaltyCalculation);
            tokenStakeBalanceLedger_[_customerAddress] = SafeMath.sub(tokenStakeBalanceLedger_[_customerAddress], _amount);
            tokenStakeBalanceLedger_[_customerAddress] =0;
            totalPayout[_customerAddress] = 0;
        }
        
    }


    function register(address _affFrom) public{
        require(_affFrom!=msg.sender, "Cannot Register with self address");
        registerUser(msg.sender,_affFrom);
    }


    
     function getContractData() public view returns(uint256, uint256, uint256,uint256, uint256){
       return(playerCount_, totalSupply(), totalTronBalance(), totalInvested, totalDividends);
     }

     function getPlayerData() public view returns(uint256, uint256, uint256, uint256, uint256, address){
       return(totalDeposit_[msg.sender], totalWithdraw_[msg.sender], 
                balanceOf(msg.sender),totalPayout[msg.sender],
                tokenStakeBalanceLedger_[msg.sender],referralData[msg.sender].affFrom);
     }

    function totalTronBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }

    function isOwner()
      public
      view
      returns(bool)
    {
      return msg.sender == devAddress_;
    }


    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }

    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

  
    

    function sellPrice()
        public
        view
        returns(uint256)
    {
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _tron = tokensToTron_(1000000);
            uint256 _dividends = SafeMath.div(_tron, sellFee_);
            uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
            return _taxedTron;
        }
    }

    function buyPrice()
        public
        view
        returns(uint256)
    {
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _incomingTron = 1000000; 
            uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingTron, buyFee_),100); // 15% Overall Value

            uint256 _taxedTron = SafeMath.sub(_incomingTron, _undividedDividends);
            uint256 _amountOfTokens = tronToTokens_(_taxedTron);
            return _amountOfTokens;
        }
    }


    function calculateTokensReceived(uint256 _tronToSpend)
        public
        view
        returns(uint256)
    {

        uint256 _incomingTron = _tronToSpend; 
            uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingTron, buyFee_),100); // 15% Overall Value

            uint256 _taxedTron = SafeMath.sub(_incomingTron, _undividedDividends);
            uint256 _amountOfTokens = tronToTokens_(_taxedTron);
            return _amountOfTokens;
        
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateTronReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _tron = tokensToTron_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_tron, sellFee_);
        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
        return _taxedTron;
    }

        /**
        *   INTERNAL FUNCTIONS            
        */
    function purchaseTokens(uint256 _incomingTron, address _referredBy)
       internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingTron, buyFee_),100); // 15% Overall Value
        uint256 _referralBonus = SafeMath.div(_incomingTron, 10); // 10% Distribution for Referral in the form of Tokens
        uint256 _devFee = _undividedDividends;

                
        uint256 _taxedTron = SafeMath.sub(_incomingTron, _undividedDividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        totalDividends = SafeMath.add(totalDividends,_undividedDividends);

        // Referral Registration
        if(referralData[msg.sender].affFrom == address(0) ){
          registerUser(msg.sender, _referredBy);
        }

        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        distributeReferral(msg.sender, _referralBonus);

       // Incremental Price

        uint256 priceTokenInc = ((incrementalPrice())*(_amountOfTokens))/tronDecimal;
        if(priceTokenInc == 0){
            priceTokenInc = incrementalPrice();
        }
        
        tokenPriceInitial_ = SafeMath.add(tokenPriceInitial_, priceTokenInc);



        if(tokenSupply_ > 0){
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
           

        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        // Dev Fee Transfer
        devAddress_.transfer(_devFee);

        return _amountOfTokens;
    }

    function registerUser(address _msgSender, address _affFrom)
      internal
    {
        ReferralData storage _referralData = referralData[_msgSender];
        if(_affFrom != _msgSender && tokenBalanceLedger_[_affFrom] >= stakingRequirement){
          _referralData.affFrom = _affFrom;
        }
        else{
          _referralData.affFrom = devAddress_;
        }
        referralData[_msgSender].joinDate = now;

        address _affAddr1 = _referralData.affFrom;
        address _affAddr2 = referralData[_affAddr1].affFrom;
    
        if (_affAddr1 != address(0) && tokenBalanceLedger_[_affAddr1] >= stakingRequirement) {
            referralData[_affAddr1].affCount1Sum = SafeMath.add(referralData[_affAddr1].affCount1Sum,1);
        }
        if (_affAddr2 != address(0) && tokenBalanceLedger_[_affAddr2] >= stakingRequirement) {
            referralData[_affAddr2].affCount2Sum = SafeMath.add(referralData[_affAddr2].affCount2Sum,1);
        }
     
    }


    function distributeReferral(address _msgSender, uint256 _allaff)
        internal
    {

        address _affAddr1 = referralData[msg.sender].affFrom;
        address _affAddr2 = referralData[_affAddr1].affFrom;
        uint256 tokenConversion = tronToTokens_(_allaff);
        uint256 _affRewards1 = (SafeMath.mul(tokenConversion, 8))/100; //8%
        uint256 _affRewards2 = (SafeMath.mul(tokenConversion, 2))/100; //2%

        if (_affAddr1 != address(0) && tokenBalanceLedger_[_affAddr1] >= stakingRequirement) {
            tokenBalanceLedger_[_affAddr1] = SafeMath.add(tokenBalanceLedger_[_affAddr1], _affRewards1);
            referralData[_affAddr1].affRewardsSum = SafeMath.add(referralData[_affAddr1].affRewardsSum, _affRewards1);
        }

        if (_affAddr2 != address(0) && tokenBalanceLedger_[_affAddr2] >= stakingRequirement) {
            tokenBalanceLedger_[_affAddr2] = SafeMath.add(tokenBalanceLedger_[_affAddr2], _affRewards2);
            referralData[_affAddr2].affRewardsSum = SafeMath.add(referralData[_affAddr2].affRewardsSum, _affRewards2);
        }


    }


    function tokensToTron_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {  

        uint256 priceInitial = tokenPriceInitial_;
        uint256 priceTokenInc = (priceInitial*(_tokens));

        uint256 tokenIncPrice = (priceTokenInc/tronDecimal);
        uint256 tempbase = (incrementalPrice());
        uint256 _tronReceived = SafeMath.add(tokenIncPrice , tempbase);

        
        return _tronReceived;
    }



     function tronToTokens_(uint256 _tron)
        internal
        view
        returns(uint256)
    {
  
        uint256 priceInitial = tokenPriceInitial_;

        uint256 _tokens = ((_tron * tronDecimal) / priceInitial);
        uint256 tempbase = (incrementalPrice());
        uint256 _tokensReceived =  SafeMath.sub(_tokens , tempbase);     

        return _tokensReceived;
    }


    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function incrementalPrice() internal view returns (uint256) {
        if(tokenSupply_>=0 && tokenSupply_<=590000*tronDecimal){
            return 19;
        }
        else if(tokenSupply_>590000*tronDecimal && tokenSupply_<=680000*tronDecimal){
            return 39;
        }
        else if(tokenSupply_>680000*tronDecimal && tokenSupply_<=760000*tronDecimal){
            return 78;
        }
        else if(tokenSupply_>760000*tronDecimal && tokenSupply_<=840000*tronDecimal){
            return 156;
        }
        else if(tokenSupply_>840000*tronDecimal && tokenSupply_<=910000*tronDecimal){
            return 311;
        }
        else if(tokenSupply_>910000*tronDecimal && tokenSupply_<=980000*tronDecimal){
            return 778;
        }
        else if(tokenSupply_>980000*tronDecimal && tokenSupply_<=1050000*tronDecimal){
            return 1401;
        }
        else if(tokenSupply_>1050000*tronDecimal && tokenSupply_<=1110000*tronDecimal){
            return 3113;
        }
        else if(tokenSupply_>1110000*tronDecimal && tokenSupply_<=1170000*tronDecimal){
            return 6225;
        }
        else if(tokenSupply_>1170000*tronDecimal && tokenSupply_<=1220000*tronDecimal){
            return 10894;
        }
        else if(tokenSupply_>1220000*tronDecimal && tokenSupply_<=1270000*tronDecimal){
            return 23344;
        }
        else if(tokenSupply_>1270000*tronDecimal && tokenSupply_<=1320000*tronDecimal){
            return 46688;
        } 
        else if(tokenSupply_>1320000*tronDecimal && tokenSupply_<=1360000*tronDecimal){
            return 93377;
        }
        else if(tokenSupply_>1360000*tronDecimal && tokenSupply_<=1400000*tronDecimal){
            return 171190;
        }
        else if(tokenSupply_>1400000*tronDecimal && tokenSupply_<=1440000*tronDecimal){
            return 466883;
        }
        else if(tokenSupply_>1440000*tronDecimal && tokenSupply_<=1470000*tronDecimal){
            return 933766;
        }
         else if(tokenSupply_>1470000*tronDecimal && tokenSupply_<=1500000*tronDecimal){
            return 1833532;
        }
        else if(tokenSupply_>1500000*tronDecimal){
            return 1833532;
        }
       
    }

    

    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/


    function setStakingRequirement(uint256 _amountOfTokens)
        public
    {
        require(msg.sender == devAddress_);
        stakingRequirement = _amountOfTokens;
    }

    function disableInitialStage()
        public
    {
        require(msg.sender == devAddress_);
        exchangeClosed = false;
    }
    function enableInitialStage()
        public
    {
        require(msg.sender == devAddress_);
        exchangeClosed = true;
    }

    function setDevAddress(address _newDev)
        public
    {
        require(msg.sender == devAddress_);
        devAddress_ = _newDev;
    }

   
}