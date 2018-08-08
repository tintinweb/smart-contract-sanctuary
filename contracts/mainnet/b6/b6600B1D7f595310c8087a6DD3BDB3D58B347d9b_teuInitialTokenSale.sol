pragma solidity 0.4.21;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev revert()s if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



/**
 * Math operations with safety checks
 */
library SafeMath {
  
  
  function mul256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div256(uint256 a, uint256 b) internal returns (uint256) {
    require(b > 0); // Solidity automatically revert()s when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub256(uint256 a, uint256 b) internal returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }  
  

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public;
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev ERC20 interface with allowances. 
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public;
  function approve(address spender, uint256 value) public;
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public {
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    balances[_to] = balances[_to].add256(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

}




/**
 * @title Standard ERC20 token
 * @dev Implemantation of the basic standart token.
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already revert() if this condition is not met
    // if (_value > _allowance) revert();

    balances[_to] = balances[_to].add256(_value);
    balances[_from] = balances[_from].sub256(_value);
    allowed[_from][msg.sender] = _allowance.sub256(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public {

    //  To change the approve amount you first have to reduce the addresses
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}



/**
 * @title TeuToken
 * @dev The main TEU token contract
 * 
 */
 
contract TeuToken is StandardToken, Ownable{
  string public name = "20-footEqvUnit";
  string public symbol = "TEU";
  uint public decimals = 18;

  event TokenBurned(uint256 value);
  
  function TeuToken() public {
    totalSupply = (10 ** 8) * (10 ** decimals);
    balances[msg.sender] = totalSupply;
  }

  /**
   * @dev Allows the owner to burn the token
   * @param _value number of tokens to be burned.
   */
  function burn(uint _value) onlyOwner public {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    totalSupply = totalSupply.sub256(_value);
    TokenBurned(_value);
  }

}

/**
 * @title teuInitialTokenSale 
 * @dev The TEU token ICO contract
 * 
 */
contract teuInitialTokenSale is Ownable {
	using SafeMath for uint256;

    event LogContribution(address indexed _contributor, uint256 _etherAmount, uint256 _basicTokenAmount, uint256 _timeBonusTokenAmount, uint256 _volumeBonusTokenAmount);
    event LogContributionBitcoin(address indexed _contributor, uint256 _bitcoinAmount, uint256 _etherAmount, uint256 _basicTokenAmount, uint256 _timeBonusTokenAmount, uint256 _volumeBonusTokenAmount, uint _contributionDatetime);
    event LogOffChainContribution(address indexed _contributor, uint256 _etherAmount, uint256 _tokenAmount);
    event LogReferralAward(address indexed _refereeWallet, address indexed _referrerWallet, uint256 _referralBonusAmount);
    event LogTokenCollected(address indexed _contributor, uint256 _collectedTokenAmount);
    event LogClientIdentRejectListChange(address indexed _contributor, uint8 _newValue);


    TeuToken			                constant private		token = TeuToken(0xeEAc3F8da16bb0485a4A11c5128b0518DaC81448); // hard coded due to token already deployed
    address		                        constant private		etherHolderWallet = 0x00222EaD2D0F83A71F645d3d9634599EC8222830; // hard coded due to deployment for once only
    uint256		                        constant private 	    minContribution = 100 finney;
    uint                                         public         saleStart = 1523498400;
    uint                                         public         saleEnd = 1526090400;
    uint                                constant private        etherToTokenConversionRate = 400;
    uint                                constant private        referralAwardPercent = 20;
    uint256                             constant private        maxCollectableToken = 20 * 10 ** 6 * 10 ** 18;

    mapping (address => uint256)                private     referralContribution;  // record the referral contribution amount in ether for claiming of referral bonus
    mapping (address => uint)                   private     lastContribitionDate;  // record the last contribution date/time for valid the referral bonus claiming period

    mapping (address => uint256)                private     collectableToken;  // record the token amount to be collected of each contributor
    mapping (address => uint8)                  private     clientIdentRejectList;  // record a list of contributors who do not pass the client identification process
    bool                                        public      isCollectTokenStart = false;  // flag to indicate if token collection is started
    bool                                        public      isAllowContribution = true; // flag to enable/disable contribution.
    uint256                                     public      totalCollectableToken;  // the total amount of token will be colleceted after considering all the contribution and bonus

    //  ***** private helper functions ***************

    

    /**
    * @dev get the current datetime
    */   
    function getCurrentDatetime() private constant returns (uint) {
        return now; 
    }

    /**
    * @dev get the current sale day
    */   
    function getCurrentSaleDay() private saleIsOn returns (uint) {
        return getCurrentDatetime().sub256(saleStart).div256(86400).add256(1);
    }

    /**
    * @dev to get the time bonus Percentage based on the no. of sale day(s)
    * @param _days no of sale day to calculate the time bonus
    */      
    function getTimeBonusPercent(uint _days) private pure returns (uint) {
        if (_days <= 10)
            return 50;
        return 0;
    }

    /**
    * @dev to get the volumne bonus percentage based on the ether amount contributed
    * @param _etherAmount ether amount contributed.
    */          
    function getVolumeBonusPercent(uint256 _etherAmount) private pure returns (uint) {

        if (_etherAmount < 1 ether)
            return 0;
        if (_etherAmount < 2 ether)
            return 35;
        if (_etherAmount < 3 ether)
            return 40;
        if (_etherAmount < 4 ether)
            return 45;
        if (_etherAmount < 5 ether)
            return 50;
        if (_etherAmount < 10 ether)
            return 55;
        if (_etherAmount < 20 ether)
            return 60;
        if (_etherAmount < 30 ether)
            return 65;
        if (_etherAmount < 40 ether)
            return 70;
        if (_etherAmount < 50 ether)
            return 75;
        if (_etherAmount < 100 ether)
            return 80;
        if (_etherAmount < 200 ether)
            return 90;
        if (_etherAmount >= 200 ether)
            return 100;
        return 0;
    }
    
    /**
    * @dev to get the time bonus amount given the token amount to be collected from contribution
    * @param _tokenAmount token amount to be collected from contribution
    */ 
    function getTimeBonusAmount(uint256 _tokenAmount) private returns (uint256) {
        return _tokenAmount.mul256(getTimeBonusPercent(getCurrentSaleDay())).div256(100);
    }
    
    /**
    * @dev to get the volume bonus amount given the token amount to be collected from contribution and the ether amount contributed
    * @param _tokenAmount token amount to be collected from contribution
    * @param _etherAmount ether amount contributed
    */
    function getVolumeBonusAmount(uint256 _tokenAmount, uint256 _etherAmount) private returns (uint256) {
        return _tokenAmount.mul256(getVolumeBonusPercent(_etherAmount)).div256(100);
    }
    
    /**
    * @dev to get the referral bonus amount given the ether amount contributed
    * @param _etherAmount ether amount contributed
    */
    function getReferralBonusAmount(uint256 _etherAmount) private returns (uint256) {
        return _etherAmount.mul256(etherToTokenConversionRate).mul256(referralAwardPercent).div256(100);
    }
    
    /**
    * @dev to get the basic amount of token to be collected given the ether amount contributed
    * @param _etherAmount ether amount contributed
    */
    function getBasicTokenAmount(uint256 _etherAmount) private returns (uint256) {
        return _etherAmount.mul256(etherToTokenConversionRate);
    }
  
  
    // ****** modifiers  ************

    /**
    * @dev modifier to allow contribution only when the sale is ON
    */
    modifier saleIsOn() {
        require(getCurrentDatetime() >= saleStart && getCurrentDatetime() < saleEnd);
        _;
    }

    /**
    * @dev modifier to check if the sale is ended
    */    
    modifier saleIsEnd() {
        require(getCurrentDatetime() >= saleEnd);
        _;
    }

    /**
    * @dev modifier to check if token is collectable
    */    
    modifier tokenIsCollectable() {
        require(isCollectTokenStart);
        _;
    }
    
    /**
    * @dev modifier to check if contribution is over the min. contribution amount
    */    
    modifier overMinContribution(uint256 _etherAmount) {
        require(_etherAmount >= minContribution);
        _;
    }
    
    /**
    * @dev modifier to check if max. token pool is not reached
    */
    modifier underMaxTokenPool() {
        require(maxCollectableToken > totalCollectableToken);
        _;
    }

    /**
    * @dev modifier to check if contribution is allowed
    */
    modifier contributionAllowed() {
        require(isAllowContribution);
        _;
    }


    //  ***** public transactional functions ***************
    /**
    * @dev called by owner to set the new sale start date/time 
    * @param _newStart new start date/time
    */
    function setNewStart(uint _newStart) public onlyOwner {
	require(saleStart > getCurrentDatetime());
        require(_newStart > getCurrentDatetime());
	require(saleEnd > _newStart);
        saleStart = _newStart;
    }

    /**
    * @dev called by owner to set the new sale end date/time 
    * @param _newEnd new end date/time
    */
    function setNewEnd(uint _newEnd) public onlyOwner {
	require(saleEnd < getCurrentDatetime());
        require(_newEnd < getCurrentDatetime());
	require(_newEnd > saleStart);
        saleEnd = _newEnd;
    }

    /**
    * @dev called by owner to enable / disable contribution 
    * @param _isAllow true - allow contribution; false - disallow contribution
    */
    function enableContribution(bool _isAllow) public onlyOwner {
        isAllowContribution = _isAllow;
    }


    /**
    * @dev called by contributors to record a contribution 
    */
    function contribute() public payable saleIsOn overMinContribution(msg.value) underMaxTokenPool contributionAllowed {
        uint256 _basicToken = getBasicTokenAmount(msg.value);
        uint256 _timeBonus = getTimeBonusAmount(_basicToken);
        uint256 _volumeBonus = getVolumeBonusAmount(_basicToken, msg.value);
        uint256 _totalToken = _basicToken.add256(_timeBonus).add256(_volumeBonus);
        
        lastContribitionDate[msg.sender] = getCurrentDatetime();
        referralContribution[msg.sender] = referralContribution[msg.sender].add256(msg.value);
        
        collectableToken[msg.sender] = collectableToken[msg.sender].add256(_totalToken);
        totalCollectableToken = totalCollectableToken.add256(_totalToken);
        assert(etherHolderWallet.send(msg.value));

        LogContribution(msg.sender, msg.value, _basicToken, _timeBonus, _volumeBonus);
    }

    /**
    * @dev called by contract owner to record a off chain contribution by Bitcoin. The token collection process is the same as those ether contributors
    * @param _bitcoinAmount bitcoin amount contributed
    * @param _etherAmount ether equivalent amount contributed
    * @param _contributorWallet wallet address of contributor which will be used for token collection
    * @param _contributionDatetime date/time of contribution. For calculating time bonus and claiming referral bonus.
    */
    function contributeByBitcoin(uint256 _bitcoinAmount, uint256 _etherAmount, address _contributorWallet, uint _contributionDatetime) public overMinContribution(_etherAmount) onlyOwner contributionAllowed {
        require(_contributionDatetime <= getCurrentDatetime());

        uint256 _basicToken = getBasicTokenAmount(_etherAmount);
        uint256 _timeBonus = getTimeBonusAmount(_basicToken);
        uint256 _volumeBonus = getVolumeBonusAmount(_basicToken, _etherAmount);
        uint256 _totalToken = _basicToken.add256(_timeBonus).add256(_volumeBonus);
        
	    if (_contributionDatetime > lastContribitionDate[_contributorWallet])
            lastContribitionDate[_contributorWallet] = _contributionDatetime;
        referralContribution[_contributorWallet] = referralContribution[_contributorWallet].add256(_etherAmount);
    
        collectableToken[_contributorWallet] = collectableToken[_contributorWallet].add256(_totalToken);
        totalCollectableToken = totalCollectableToken.add256(_totalToken);
        LogContributionBitcoin(_contributorWallet, _bitcoinAmount, _etherAmount, _basicToken, _timeBonus, _volumeBonus, _contributionDatetime);
    }
    
    /**
    * @dev called by contract owner to record a off chain contribution by Ether. The token are distributed off chain already.  The contributor can only entitle referral bonus through this smart contract
    * @param _etherAmount ether equivalent amount contributed
    * @param _contributorWallet wallet address of contributor which will be used for referral bonus collection
    * @param _tokenAmount amunt of token distributed to the contributor. For reference only in the event log
    */
    function recordOffChainContribute(uint256 _etherAmount, address _contributorWallet, uint256 _tokenAmount) public overMinContribution(_etherAmount) onlyOwner {

        lastContribitionDate[_contributorWallet] = getCurrentDatetime();
        LogOffChainContribution(_contributorWallet, _etherAmount, _tokenAmount);
    }    

    /**
    * @dev called by contributor to claim the referral bonus
    * @param _referrerWallet wallet address of referrer.  Referrer must also be a contributor
    */
    function referral(address _referrerWallet) public {
	require (msg.sender != _referrerWallet);
        require (referralContribution[msg.sender] > 0);
        require (lastContribitionDate[_referrerWallet] > 0);
        require (getCurrentDatetime() - lastContribitionDate[msg.sender] <= (4 * 24 * 60 * 60));
        
        uint256 _referralBonus = getReferralBonusAmount(referralContribution[msg.sender]);
        referralContribution[msg.sender] = 0;
        
        collectableToken[msg.sender] = collectableToken[msg.sender].add256(_referralBonus);
        collectableToken[_referrerWallet] = collectableToken[_referrerWallet].add256(_referralBonus);
        totalCollectableToken = totalCollectableToken.add256(_referralBonus).add256(_referralBonus);
        LogReferralAward(msg.sender, _referrerWallet, _referralBonus);
    }
    
    /**
    * @dev called by contract owener to register a list of rejected clients who cannot pass the client identification process.
    * @param _clients an array of wallet address clients to be set
    * @param _valueToSet  1 - add to reject list, 0 - remove from reject list
    */
    function setClientIdentRejectList(address[] _clients, uint8 _valueToSet) public onlyOwner {
        for (uint i = 0; i < _clients.length; i++) {
            if (_clients[i] != address(0) && clientIdentRejectList[_clients[i]] != _valueToSet) {
                clientIdentRejectList[_clients[i]] = _valueToSet;
                LogClientIdentRejectListChange(_clients[i], _valueToSet);
            }
        }
    }
    
    /**
    * @dev called by contract owner to enable / disable token collection process
    * @param _enable true - enable collection; false - disable collection
    */
    function setTokenCollectable(bool _enable) public onlyOwner saleIsEnd {
        isCollectTokenStart = _enable;
    }
    
    /**
    * @dev called by contributor to collect tokens.  If they are rejected by the client identification process, error will be thrown
    */
    function collectToken() public tokenIsCollectable {
	uint256 _collToken = collectableToken[msg.sender];

	require(clientIdentRejectList[msg.sender] <= 0);
        require(_collToken > 0);

        collectableToken[msg.sender] = 0;

        token.transfer(msg.sender, _collToken);
        LogTokenCollected(msg.sender, _collToken);
    }

    /**
    * @dev Allow owner to transfer out the token left in the contract
    * @param _to address to transfer to
    * @param _amount amount to transfer
    */  
    function transferTokenOut(address _to, uint256 _amount) public onlyOwner {
        token.transfer(_to, _amount);
    }
    
    /**
    * @dev Allow owner to transfer out the ether left in the contract
    * @param _to address to transfer to
    * @param _amount amount to transfer
    */  
    function transferEtherOut(address _to, uint256 _amount) public onlyOwner {
        assert(_to.send(_amount));
    }  
    

    //  ***** public constant functions ***************

    /**
    * @dev to get the amount of token collectable by any contributor
    * @param _contributor contributor to get amont
    */  
    function collectableTokenOf(address _contributor) public constant returns (uint256) {
        return collectableToken[_contributor] ;
    }
    
    /**
    * @dev to get the amount of token collectable by any contributor
    * @param _contributor contributor to get amont
    */  
    function isClientIdentRejectedOf(address _contributor) public constant returns (uint8) {
        return clientIdentRejectList[_contributor];
    }    
    
    /**
    * @dev Fallback function which receives ether and create the appropriate number of tokens for the 
    * msg.sender.
    */
    function() external payable {
        contribute();
    }

}