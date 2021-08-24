/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

/**
 *Submitted for verification at Etherscan.io on 2018-04-10
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
contract Divide {



  function percent(uint numerator, uint denominator, uint precision) internal 



  pure returns(uint quotient) {

         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);

  }



}
contract Percentage is Divide{



    uint256 internal baseValue = 100;



    function onePercent(uint256 _value) internal view returns (uint256)  {

        uint256 roundValue = SafeMath.ceil(_value, baseValue);

        uint256 Percent = SafeMath.div(SafeMath.mul(roundValue, baseValue), 10000);

        return  Percent;

    }

}

contract Verifier {
    function recoverAddr(
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        return ecrecover(msgHash, v, r, s);
    }

    function isSigned(
        address _addr,
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bool) {
        return ecrecover(msgHash, v, r, s) == _addr;
    }
}

contract BSB is Percentage , Verifier{
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
     /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    // administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // -> change the PoS difficulty 
    // they CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[bytes32(uint256(_customerAddress) << 96)]);
        _;
    }
    
    
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;
        
      
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                // is the customer in the ambassador list?
                ambassadors_[_customerAddress] == true &&
                
                // does the customer purchase exceed the max ambassador quota?
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_
                
            );
            
            // updated the accumulated quota    
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
        
            // execute
            _;
        } else {
            // in case the ether count drops low, the ambassador phase won't reinitiate
            onlyAmbassadors = false;
            _;    
        }
        
    }
    
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event Buy(
        string nature,
        address indexed _buyer,
        uint256 _tokens,
        uint256 _amounts
    );
    
     event LastRef(
        uint256 _allaff,
        address _aff6
    );
      event FirstRef(
        uint256 _trx,
        address _allaff
    );
    event Sell(
        string nature,
        address indexed _seller,
        uint256 _tokens,
        uint256 _amounts
    );
    
    event Withdraw(
        string nature,
        address indexed _drawer,
        uint256 _amountWithDrawn
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
    string public name = "BSB";
    string public symbol = "BSB";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;
    uint256 constant internal magnitude = 2**64;
    // uint256 baseValue=1000;
    uint256 startTime;
    address payable public  owner;
    uint256 initialPrice=0.01*10**18;
    // proof of stake (defaults at 1 token)
    uint256 public stakingRequirement = 10**14;
    // ambassador program
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 10**6;
    uint256 constant internal ambassadorQuota_ = 10**6;
    
    
    struct Users{



        uint256 totalWithdrawn;

        uint256 totalTRXDeposited;
        
        address _upline;
        
        uint256 AchievedOne;
        uint256 AchievedThree;
        uint256 AchievedTen;

    }

    mapping(address=>Users)public users;
    
   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) public referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    uint256 public marketCapValue;
    
    address [] internal AchieveOneBNB;
    address [] internal AchievethreeBNB;
    address [] internal AchieveTenBNB;
    uint256 public Last_BuyingAmount;
    uint256 public Last_SellingAmount;
    
    uint256 ownerWithdrawl;
    address public signatureAddress;
    // administrator list (see above on what they can do)
    mapping(bytes32 => bool) public administrators;
    
      // event Multisended(uint256 total, addr
    mapping(bytes32 => mapping(uint256 => bool)) public seenNonces;
    
    
    bool public onlyAmbassadors = false;
    


    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor(address _admin)
        public
    {
        // add administrators here
        administrators[bytes32(uint256(_admin) << 96)] = true;
						 
   
        ambassadors_[0x0000000000000000000000000000000000000000] = true;
        startTime=now;
        owner=msg.sender;
        signatureAddress = owner;
    }
    
    
    function Change_signatureAddress(address _address) public onlyOwner
    {
        signatureAddress = _address;
    } 
   function Chackdistributing(address _add) internal {
      
      
        if(referralBalance_[_add] >= 0.001 ether && users[_add].AchievedOne == 0 )
        {
                  AchieveOneBNB.push(_add); 
                  users[_add].AchievedOne = 1;
        }
        if(referralBalance_[_add] >= 0.003 ether  && users[_add].AchievedThree == 0)
        {
            AchievethreeBNB.push(_add);
            users[_add].AchievedThree = 3;
        }
        if(referralBalance_[_add] >= 0.010 ether && users[_add].AchievedTen == 0)
        {
            AchieveTenBNB.push(_add);
            users[_add].AchievedTen = 10;
        }
    }
    function distributeRefferalLast(uint256 _trx,uint256 _allaff,address _affAddr6)private returns(uint256,uint256,address){
        uint256 _affRewards = 0;
        address _affAddr7 = users[_affAddr6]._upline;
        address _affAddr8 = users[_affAddr7]._upline;
        address _affAddr9 = users[_affAddr8]._upline;
        address _affAddr10 = users[_affAddr9]._upline;
        address _affAddr11 = users[_affAddr10]._upline;
        if (_affAddr7 != address(0)) {
            _affRewards = SafeMath.div(SafeMath.mul(_trx,2),baseValue);
            _allaff = SafeMath.sub(_allaff,_affRewards);
            referralBalance_[_affAddr7] = SafeMath.add(referralBalance_[_affAddr7],_affRewards);
              Chackdistributing(_affAddr7);
        }
        if (_affAddr8 != address(0)) {
            _affRewards = SafeMath.div(SafeMath.mul(_trx,2),baseValue);
            _allaff = SafeMath.sub(_allaff,_affRewards);
            referralBalance_[_affAddr8] = SafeMath.add(referralBalance_[_affAddr8],_affRewards);
             Chackdistributing(_affAddr8);
        }
        
        if (_affAddr9 != address(0)) {
            _affRewards = SafeMath.div(SafeMath.mul(_trx,2),baseValue);
            _allaff = SafeMath.sub(_allaff,_affRewards);
            referralBalance_[_affAddr9] = SafeMath.add(referralBalance_[_affAddr9],_affRewards);
            //referralBalance_[_affAddr9].transfer(_affRewards);
            Chackdistributing(_affAddr9);
        }
        
        if (_affAddr10 != address(0)) {
            _affRewards = SafeMath.div(SafeMath.mul(_trx,2),baseValue);
            _allaff = SafeMath.sub(_allaff,_affRewards);
            referralBalance_[_affAddr10] = SafeMath.add(referralBalance_[_affAddr10],_affRewards);
            //referralBalance_[_affAddr10].transfer(_affRewards);
             Chackdistributing(_affAddr10);
        }
        
        if (_affAddr11 != address(0)) {
            _affRewards = SafeMath.div(SafeMath.mul(_trx,2),baseValue);
            _allaff = SafeMath.sub(_allaff,_affRewards);
            referralBalance_[_affAddr11] = SafeMath.add(referralBalance_[_affAddr11],_affRewards);
                Chackdistributing(_affAddr11);
        }
        

        if(_allaff > 0 ){
            referralBalance_[owner]=SafeMath.add(referralBalance_[owner],_allaff);
           Chackdistributing(owner);
        }
      emit  LastRef(_allaff,_affAddr6);
    }
    
    function distributeRefferalFisrst(uint256 _trx, address __upline) private{
        uint256 _allaff = SafeMath.div(SafeMath.mul(_trx,40),baseValue);
        uint256 totalrefs;
		totalrefs = SafeMath.add(totalrefs,_allaff);
		address _affAddr1=__upline;
        address _affAddr2 = users[_affAddr1]._upline;
        address _affAddr3 = users[_affAddr2]._upline;
        address _affAddr4 = users[_affAddr3]._upline;
        address _affAddr5 = users[_affAddr4]._upline;
        address _affAddr6 = users[_affAddr5]._upline;
        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            _affRewards = SafeMath.div(SafeMath.mul(_trx,20),baseValue);
            _allaff = SafeMath.sub(_allaff,_affRewards);
            referralBalance_[__upline] = SafeMath.add(referralBalance_[_affAddr1],_affRewards);
            Chackdistributing(_affAddr1);
        
            emit  FirstRef(_affRewards,_affAddr1);
        }
        if (_affAddr2 != address(0)) {
            _affRewards = SafeMath.div(SafeMath.mul(_trx,2),baseValue);
            _allaff = SafeMath.sub(_allaff,_affRewards);
            referralBalance_[_affAddr2] = SafeMath.add(referralBalance_[_affAddr2],_affRewards);
            Chackdistributing(_affAddr2);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = SafeMath.div(SafeMath.mul(_trx,2),baseValue);
            _allaff = SafeMath.sub(_allaff,_affRewards);
            referralBalance_[_affAddr3] = SafeMath.add(referralBalance_[_affAddr3],_affRewards);
            Chackdistributing(_affAddr3);
        }

        if (_affAddr4 != address(0)) {
          _affRewards = SafeMath.div(SafeMath.mul(_trx,2),baseValue);
            _allaff = SafeMath.sub(_allaff,_affRewards);
            referralBalance_[_affAddr4] = SafeMath.add(referralBalance_[_affAddr4],_affRewards);
            Chackdistributing(_affAddr4);
        }

        if (_affAddr5 != address(0)) {
            _affRewards = SafeMath.div(SafeMath.mul(_trx,2),baseValue);
            _allaff = SafeMath.sub(_allaff,_affRewards);
            referralBalance_[_affAddr5] = SafeMath.add(referralBalance_[_affAddr5],_affRewards);
           Chackdistributing(_affAddr5);
        }

        if (_affAddr6 != address(0)) {
          _affRewards = SafeMath.div(SafeMath.mul(_trx,2),baseValue);
            _allaff = SafeMath.sub(_allaff,_affRewards);
            referralBalance_[_affAddr6] = SafeMath.add(referralBalance_[_affAddr6],_affRewards);
            Chackdistributing(_affAddr6);
        }
        distributeRefferalLast(_trx,_allaff, _affAddr6);
        emit  FirstRef(_trx,_affAddr3);

    }
    /**
     * Converts all incoming Ethereum to tokens for the caller, and passes down the referral address (if any)
     */
    function buyToken(address _referredBy)
        public
        payable
        returns(uint256)
    {
        purchaseTokens(msg.value, _referredBy);
        Last_BuyingAmount = msg.value;
    }
    
    
    // function()
    //     payable
    //     public
    // {
    //     purchaseTokens(msg.value, 0x0);
    // }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
        onlyhodler()
        public
    {
        // setup data
        address payable _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code
        
        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // delivery service
        users[_customerAddress].totalWithdrawn+=_dividends;
        _customerAddress.transfer(_dividends);
        // fire event
        emit Withdraw("Withdraw",_customerAddress, _dividends);
    }
    
    /**
     * Liquifies tokens to ethereum.
     */
    function sellToken(uint256 _amountOfTokens)
        onlybelievers ()
        public
    {
      
        address _customerAddress = msg.sender;
       
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToBNB(_tokens);
        uint256 _dividends=SafeMath.mul(onePercent(_ethereum),SafeMath.div(45,1000));
        uint256 _taxedEthereum =calculateBNBReceived(_amountOfTokens);
        uint256 ownerDividend;
        ownerDividend=SafeMath.mul(onePercent(_ethereum),SafeMath.div(5,1000));
        _dividends=SafeMath.sub(_dividends,ownerDividend);
        //update refferalBonus
        distributeRefferalFisrst(_ethereum,users[msg.sender]._upline);
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
        
        marketCapValue-=_ethereum;
        owner.transfer(ownerDividend);
        Last_SellingAmount = _amountOfTokens;
        
        // fire event
       emit  Sell("Sell",_customerAddress,_taxedEthereum,_tokens);
    }

    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's a 10% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlybelievers ()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        
        // make sure we have the requested tokens
     
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) withdraw();
        
        // liquify 10% of the tokens that are transfered
        // these are dispersed to shareholders
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToBNB(_tokenFee);
  
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
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);
        
        // ERC20
        return true;
       
    }
    
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    /**
     * administrator can manually disable the ambassador phase.
     */
    function disableInitialStage()
        onlyAdministrator()
        public
    {
        onlyAmbassadors = false;
    }
    
   
    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[bytes32(uint256(_identifier) << 96)] = _status;
    }
    
   
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }
    
    
    function setName(string memory _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
    
   
    function setSymbol(string memory _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
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
        return address(this).balance+ownerWithdrawl;
    }
    
    /**
     * Retrieve the total token supply.
     */
    function circulatingSupply()
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
       */ 
    function myDividends(bool _includeReferralBonus) 
        public 
        view 
        returns(uint256)
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
    return ((uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude);
    }
    
    /**
     * Return the buy price of 1 individual token.
     */
   
    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = BNBToTokens_(_taxedEthereum);
        
        return _amountOfTokens;
    }
    
   
    function calculateBNBReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToBNB(_tokensToSell);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint256 _incomingTrx, address _referredBy)
        antiEarlyWhale(_incomingTrx)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingTrx, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends,2);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingTrx, _undividedDividends);
        uint256 _amountOfTokens = BNBToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
        uint256 ownerDividend;
      
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_),"invalid Token Amount");
        
        // is the user referred by a karmalink?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != _customerAddress &&
            
        
            tokenBalanceLedger_[_referredBy] >= stakingRequirement||
            _referredBy==owner
        ){
            //set Refferal in user struct
            users[_customerAddress]._upline=_referredBy;
            // wealth redistribution
            //distributeRefferalFisrst(_incomingTrx,_referredBy);
            referralBalance_[_referredBy] += msg.value;
            
            Chackdistributing(_referredBy);
            
            ownerDividend=SafeMath.mul(onePercent(_dividends),5);

        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            ownerDividend=SafeMath.mul(onePercent(_dividends),5);
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        _dividends=SafeMath.sub(_dividends,ownerDividend);
        // we can't give people infinite ethereum
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
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        payoutsTo_[_customerAddress] +=  (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        users[_customerAddress].totalTRXDeposited+=_incomingTrx;
        marketCapValue+=_taxedEthereum;
        owner.transfer(ownerDividend);
        // fire event
        emit Buy("Buy",_customerAddress, _amountOfTokens,_incomingTrx);
        return _amountOfTokens;
    }
    
    function userBNBWithdraw(
        uint256 amount,
        uint256 nonce,
        bytes32[] memory msgHash_r_s,
        uint8 v
    ) public {
        // Signature Verification
        require(
            isSigned(
                signatureAddress,
                msgHash_r_s[0],
                v,
                msgHash_r_s[1],
                msgHash_r_s[2]
            ),
            "Signature Failed"
        );
        // Duplication check
        require(seenNonces[msgHash_r_s[0]][nonce] == false);
        seenNonces[msgHash_r_s[0]][nonce] = true;
        // TRX Transfer
        msg.sender.transfer(amount);
        emit Transfer(address(this), msg.sender, amount);
    }
    
    

    /**
     * Calculate Token price based on an amount of incoming ethereum
     * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
     function buyPriceCalculation() public view returns(uint){

        require(startTime != 0,"contract isn't deployed yet!");

        uint256 increment= ((now - startTime)/(1 days))*10**14;

        return increment;

       }
     function BNBToTokens_(uint256 _trxvalue)
        public
        view
        returns(uint256)
      {

       uint256 price= (buyPriceCalculation()+initialPrice);
        return (_trxvalue*10**36/price)/(10**18);
      }
    
     function marketCap()public view returns(uint256){

        // return (SafeMath.sub(totalEthereumBalance(),(onePercent(totalEthereumBalance())*10)));
        return marketCapValue;
      }
    /**
     * Calculate token sell value.
          */
      function sellPriceCalculation()internal view returns(uint256){
        if(tokenSupply_==0){

         return 0;   

        }else{
        require(tokenSupply_>0,"No token bought yet");

        uint256 marketCapValueOf=SafeMath.mul(marketCap(),10**12);

        uint256 price= SafeMath.div(marketCapValueOf,circulatingSupply());

        return price;  
        }
        

       }
     function BNB_To_BSB()public view returns(uint256){

        return buyPriceCalculation()+initialPrice;

     }
     function BSB_To_BNB()public view returns(uint256){

       if(circulatingSupply()==0){

         return 0;   

        }

        else{

        return SafeMath.div(sellPriceCalculation(),10**18);  

        }  

     }
      function tokensToBNB(uint256 _tokens)
        public
        view
        returns(uint256)
     {
 
        uint256 price=SafeMath.mul(_tokens,sellPriceCalculation());

        return SafeMath.div(price,10**12);  
     }
    
    
    
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    } 
        function _AchieveOneBNB() public view returns (address[] memory ) {
        return AchieveOneBNB;
    }
     function _AchievethreeBNB() public view returns (address[] memory ) {
        return AchievethreeBNB;
    }
     function _AchieveTenBNB() public view returns (address[] memory ) {
        return AchieveTenBNB;
    }
    
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }

/**
* Also in memory of JPK, miss you Dad.
*/
    
}