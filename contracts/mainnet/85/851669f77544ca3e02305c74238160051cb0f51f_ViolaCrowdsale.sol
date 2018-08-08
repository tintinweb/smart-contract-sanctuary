pragma solidity 0.4.20;

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


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
}


// ----------------------------------------------------------------------------
// VIOLET ERC20 Standard Token
// ----------------------------------------------------------------------------
contract VLTToken is ERC20Interface {
    using SafeMath for uint256;

    address public owner = msg.sender;

    bytes32 public symbol;
    bytes32 public name;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function VLTToken() public {
        symbol = "VAI";
        name = "VIOLET";
        decimals = 18;
        _totalSupply = 250000000 * 10**uint256(decimals);
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }


    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        // allow sending 0 tokens
        if (_value == 0) {
            Transfer(msg.sender, _to, _value);    // Follow the spec to louch the event when transfer 0
            return;
        }
        
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // allow sending 0 tokens
        if (_value == 0) {
            Transfer(_from, _to, _value);    // Follow the spec to louch the event when transfer 0
            return;
        }

        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }


    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        Burn(burner, _value);
        Transfer(burner, address(0), _value);
    }

    /**
     * Destroy tokens from other account
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(_value <= balances[_from]);               // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowed allowance
        balances[_from] = balances[_from].sub(_value);  // Subtract from the targeted balance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);             // Subtract from the sender&#39;s allowance
        _totalSupply = _totalSupply.sub(_value);                              // Update totalSupply
        Burn(_from, _value);
        Transfer(_from, address(0), _value);
        return true;
    } 

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



/**
 * @title ViolaCrowdsale
 * @dev ViolaCrowdsale reserves token from supply when eth is received
 * funds will be forwarded after the end of crowdsale. Tokens will be claimable
 * within 7 days after crowdsale ends.
 */
 
contract ViolaCrowdsale is Ownable {
  using SafeMath for uint256;

  enum State { Deployed, PendingStart, Active, Paused, Ended, Completed }

  //Status of contract
  State public status = State.Deployed;

  // The token being sold
  VLTToken public violaToken;

  //For keeping track of whitelist address. cap >0 = whitelisted
  mapping(address=>uint) public maxBuyCap;

  //For checking if address passed KYC
  mapping(address => bool)public addressKYC;

  //Total wei sum an address has invested
  mapping(address=>uint) public investedSum;

  //Total violaToken an address is allocated
  mapping(address=>uint) public tokensAllocated;

    //Total violaToken an address purchased externally is allocated
  mapping(address=>uint) public externalTokensAllocated;

  //Total bonus violaToken an address is entitled after vesting
  mapping(address=>uint) public bonusTokensAllocated;

  //Total bonus violaToken an address purchased externally is entitled after vesting
  mapping(address=>uint) public externalBonusTokensAllocated;

  //Store addresses that has registered for crowdsale before (pushed via setWhitelist)
  //Does not mean whitelisted as it can be revoked. Just to track address for loop
  address[] public registeredAddress;

  //Total amount not approved for withdrawal
  uint256 public totalApprovedAmount = 0;

  //Start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;
  uint256 public bonusVestingPeriod = 60 days;


  /**
   * Note all values are calculated in wei(uint256) including token amount
   * 1 ether = 1000000000000000000 wei
   * 1 viola = 1000000000000000000 vi lawei
   */


  //Address where funds are collected
  address public wallet;

  //Min amount investor can purchase
  uint256 public minWeiToPurchase;

  // how many token units *in wei* a buyer gets *per wei*
  uint256 public rate;

  //Extra bonus token to give *in percentage*
  uint public bonusTokenRateLevelOne = 20;
  uint public bonusTokenRateLevelTwo = 15;
  uint public bonusTokenRateLevelThree = 10;
  uint public bonusTokenRateLevelFour = 0;

  //Total amount of tokens allocated for crowdsale
  uint256 public totalTokensAllocated;

  //Total amount of tokens reserved from external sources
  //Sub set of totalTokensAllocated ( totalTokensAllocated - totalReservedTokenAllocated = total tokens allocated for purchases using ether )
  uint256 public totalReservedTokenAllocated;

  //Numbers of token left above 0 to still be considered sold
  uint256 public leftoverTokensBuffer;

  /**
   * event for front end logging
   */

  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount, uint256 bonusAmount);
  event ExternalTokenPurchase(address indexed purchaser, uint256 amount, uint256 bonusAmount);
  event ExternalPurchaseRefunded(address indexed purchaser, uint256 amount, uint256 bonusAmount);
  event TokenDistributed(address indexed tokenReceiver, uint256 tokenAmount);
  event BonusTokenDistributed(address indexed tokenReceiver, uint256 tokenAmount);
  event TopupTokenAllocated(address indexed tokenReceiver, uint256 amount, uint256 bonusAmount);
  event CrowdsalePending();
  event CrowdsaleStarted();
  event CrowdsaleEnded();
  event BonusRateChanged();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  //Set inital arguments of the crowdsale
  function initialiseCrowdsale (uint256 _startTime, uint256 _rate, address _tokenAddress, address _wallet) onlyOwner external {
    require(status == State.Deployed);
    require(_startTime >= now);
    require(_rate > 0);
    require(address(_tokenAddress) != address(0));
    require(_wallet != address(0));

    startTime = _startTime;
    endTime = _startTime + 30 days;
    rate = _rate;
    wallet = _wallet;
    violaToken = VLTToken(_tokenAddress);

    status = State.PendingStart;

    CrowdsalePending();

  }

  /**
   * Crowdsale state functions
   * To track state of current crowdsale
   */


  // To be called by Ethereum alarm clock or anyone
  //Can only be called successfully when time is valid
  function startCrowdsale() external {
    require(withinPeriod());
    require(violaToken != address(0));
    require(getTokensLeft() > 0);
    require(status == State.PendingStart);

    status = State.Active;

    CrowdsaleStarted();
  }

  //To be called by owner or contract
  //Ends the crowdsale when tokens are sold out
  function endCrowdsale() public {
    if (!tokensHasSoldOut()) {
      require(msg.sender == owner);
    }
    require(status == State.Active);

    bonusVestingPeriod = now + 60 days;

    status = State.Ended;

    CrowdsaleEnded();
  }
  //Emergency pause
  function pauseCrowdsale() onlyOwner external {
    require(status == State.Active);

    status = State.Paused;
  }
  //Resume paused crowdsale
  function unpauseCrowdsale() onlyOwner external {
    require(status == State.Paused);

    status = State.Active;
  }

  function completeCrowdsale() onlyOwner external {
    require(hasEnded());
    require(violaToken.allowance(owner, this) == 0);
    status = State.Completed;

    _forwardFunds();

    assert(this.balance == 0);
  }

  function burnExtraTokens() onlyOwner external {
    require(hasEnded());
    uint256 extraTokensToBurn = violaToken.allowance(owner, this);
    violaToken.burnFrom(owner, extraTokensToBurn);
    assert(violaToken.allowance(owner, this) == 0);
  }

  // send ether to the fund collection wallet
  function _forwardFunds() internal {
    wallet.transfer(this.balance);
  }

  function partialForwardFunds(uint _amountToTransfer) onlyOwner external {
    require(status == State.Ended);
    require(_amountToTransfer < totalApprovedAmount);
    totalApprovedAmount = totalApprovedAmount.sub(_amountToTransfer);
    
    wallet.transfer(_amountToTransfer);
  }

  /**
   * Setter functions for crowdsale parameters
   * Only owner can set values
   */


  function setLeftoverTokensBuffer(uint256 _tokenBuffer) onlyOwner external {
    require(_tokenBuffer > 0);
    require(getTokensLeft() >= _tokenBuffer);
    leftoverTokensBuffer = _tokenBuffer;
  }

  //Set the ether to token rate
  function setRate(uint _rate) onlyOwner external {
    require(_rate > 0);
    rate = _rate;
  }

  function setBonusTokenRateLevelOne(uint _rate) onlyOwner external {
    //require(_rate > 0);
    bonusTokenRateLevelOne = _rate;
    BonusRateChanged();
  }

  function setBonusTokenRateLevelTwo(uint _rate) onlyOwner external {
    //require(_rate > 0);
    bonusTokenRateLevelTwo = _rate;
    BonusRateChanged();
  }

  function setBonusTokenRateLevelThree(uint _rate) onlyOwner external {
    //require(_rate > 0);
    bonusTokenRateLevelThree = _rate;
    BonusRateChanged();
  }
  function setBonusTokenRateLevelFour(uint _rate) onlyOwner external {
    //require(_rate > 0);
    bonusTokenRateLevelFour = _rate;
    BonusRateChanged();
  }

  function setMinWeiToPurchase(uint _minWeiToPurchase) onlyOwner external {
    minWeiToPurchase = _minWeiToPurchase;
  }


  /**
   * Whitelisting and KYC functions
   * Whitelisted address can buy tokens, KYC successful purchaser can claim token. Refund if fail KYC
   */


  //Set the amount of wei an address can purchase up to
  //@dev Value of 0 = not whitelisted
  //@dev cap is in *18 decimals* ( 1 token = 1*10^18)
  
  function setWhitelistAddress( address _investor, uint _cap ) onlyOwner external {
        require(_cap > 0);
        require(_investor != address(0));
        maxBuyCap[_investor] = _cap;
        registeredAddress.push(_investor);
        //add event
    }

  //Remove the address from whitelist
  function removeWhitelistAddress(address _investor) onlyOwner external {
    require(_investor != address(0));
    
    maxBuyCap[_investor] = 0;
    uint256 weiAmount = investedSum[_investor];

    if (weiAmount > 0) {
      _refund(_investor);
    }
  }

  //Flag address as KYC approved. Address is now approved to claim tokens
  function approveKYC(address _kycAddress) onlyOwner external {
    require(_kycAddress != address(0));
    addressKYC[_kycAddress] = true;

    uint256 weiAmount = investedSum[_kycAddress];
    totalApprovedAmount = totalApprovedAmount.add(weiAmount);
  }

  //Set KYC status as failed. Refund any eth back to address
  function revokeKYC(address _kycAddress) onlyOwner external {
    require(_kycAddress != address(0));
    addressKYC[_kycAddress] = false;

    uint256 weiAmount = investedSum[_kycAddress];
    totalApprovedAmount = totalApprovedAmount.sub(weiAmount);

    if (weiAmount > 0) {
      _refund(_kycAddress);
    }
  }

  /**
   * Getter functions for crowdsale parameters
   * Does not use gas
   */

  //Checks if token has been sold out
    function tokensHasSoldOut() view internal returns (bool) {
      if (getTokensLeft() <= leftoverTokensBuffer) {
        return true;
      } else {
        return false;
      }
    }

      // @return true if the transaction can buy tokens
  function withinPeriod() public view returns (bool) {
    return now >= startTime && now <= endTime;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    if (status == State.Ended) {
      return true;
    }
    return now > endTime;
  }

  function getTokensLeft() public view returns (uint) {
    return violaToken.allowance(owner, this).sub(totalTokensAllocated);
  }

  function transferTokens (address receiver, uint tokenAmount) internal {
     require(violaToken.transferFrom(owner, receiver, tokenAmount));
  }

  function getTimeBasedBonusRate() public view returns(uint) {
    bool bonusDuration1 = now >= startTime && now <= (startTime + 1 days);  //First 24hr
    bool bonusDuration2 = now > (startTime + 1 days) && now <= (startTime + 3 days);//Next 48 hr
    bool bonusDuration3 = now > (startTime + 3 days) && now <= (startTime + 10 days);//4th to 10th day
    bool bonusDuration4 = now > (startTime + 10 days) && now <= endTime;//11th day onwards
    if (bonusDuration1) {
      return bonusTokenRateLevelOne;
    } else if (bonusDuration2) {
      return bonusTokenRateLevelTwo;
    } else if (bonusDuration3) {
      return bonusTokenRateLevelThree;
    } else if (bonusDuration4) {
      return bonusTokenRateLevelFour;
    } else {
      return 0;
    }
  }

  function getTotalTokensByAddress(address _investor) public view returns(uint) {
    return getTotalNormalTokensByAddress(_investor).add(getTotalBonusTokensByAddress(_investor));
  }

  function getTotalNormalTokensByAddress(address _investor) public view returns(uint) {
    return tokensAllocated[_investor].add(externalTokensAllocated[_investor]);
  }

  function getTotalBonusTokensByAddress(address _investor) public view returns(uint) {
    return bonusTokensAllocated[_investor].add(externalBonusTokensAllocated[_investor]);
  }

  function _clearTotalNormalTokensByAddress(address _investor) internal {
    tokensAllocated[_investor] = 0;
    externalTokensAllocated[_investor] = 0;
  }

  function _clearTotalBonusTokensByAddress(address _investor) internal {
    bonusTokensAllocated[_investor] = 0;
    externalBonusTokensAllocated[_investor] = 0;
  }


  /**
   * Functions to handle buy tokens
   * Fallback function as entry point for eth
   */


  // Called when ether is sent to contract
  function () external payable {
    buyTokens(msg.sender);
  }

  //Used to buy tokens
  function buyTokens(address investor) internal {
    require(status == State.Active);
    require(msg.value >= minWeiToPurchase);

    uint weiAmount = msg.value;

    checkCapAndRecord(investor,weiAmount);

    allocateToken(investor,weiAmount);
    
  }

  //Internal call to check max user cap
  function checkCapAndRecord(address investor, uint weiAmount) internal {
      uint remaindingCap = maxBuyCap[investor];
      require(remaindingCap >= weiAmount);
      maxBuyCap[investor] = remaindingCap.sub(weiAmount);
      investedSum[investor] = investedSum[investor].add(weiAmount);
  }

  //Internal call to allocated tokens purchased
    function allocateToken(address investor, uint weiAmount) internal {
        // calculate token amount to be created
        uint tokens = weiAmount.mul(rate);
        uint bonusTokens = tokens.mul(getTimeBasedBonusRate()).div(100);
        
        uint tokensToAllocate = tokens.add(bonusTokens);
        
        require(getTokensLeft() >= tokensToAllocate);
        totalTokensAllocated = totalTokensAllocated.add(tokensToAllocate);

        tokensAllocated[investor] = tokensAllocated[investor].add(tokens);
        bonusTokensAllocated[investor] = bonusTokensAllocated[investor].add(bonusTokens);

        if (tokensHasSoldOut()) {
          endCrowdsale();
        }
        TokenPurchase(investor, weiAmount, tokens, bonusTokens);
  }



  /**
   * Functions for refunds & claim tokens
   * 
   */



  //Refund users in case of unsuccessful crowdsale
  function _refund(address _investor) internal {
    uint256 investedAmt = investedSum[_investor];
    require(investedAmt > 0);

  
      uint totalInvestorTokens = tokensAllocated[_investor].add(bonusTokensAllocated[_investor]);

    if (status == State.Active) {
      //Refunded tokens go back to sale pool
      totalTokensAllocated = totalTokensAllocated.sub(totalInvestorTokens);
    }

    _clearAddressFromCrowdsale(_investor);

    _investor.transfer(investedAmt);

    Refunded(_investor, investedAmt);
  }

    //Partial refund users
  function refundPartial(address _investor, uint _refundAmt, uint _tokenAmt, uint _bonusTokenAmt) onlyOwner external {

    uint investedAmt = investedSum[_investor];
    require(investedAmt > _refundAmt);
    require(tokensAllocated[_investor] > _tokenAmt);
    require(bonusTokensAllocated[_investor] > _bonusTokenAmt);

    investedSum[_investor] = investedSum[_investor].sub(_refundAmt);
    tokensAllocated[_investor] = tokensAllocated[_investor].sub(_tokenAmt);
    bonusTokensAllocated[_investor] = bonusTokensAllocated[_investor].sub(_bonusTokenAmt);


    uint totalRefundTokens = _tokenAmt.add(_bonusTokenAmt);

    if (status == State.Active) {
      //Refunded tokens go back to sale pool
      totalTokensAllocated = totalTokensAllocated.sub(totalRefundTokens);
    }

    _investor.transfer(_refundAmt);

    Refunded(_investor, _refundAmt);
  }

  //Used by investor to claim token
    function claimTokens() external {
      require(hasEnded());
      require(addressKYC[msg.sender]);
      address tokenReceiver = msg.sender;
      uint tokensToClaim = getTotalNormalTokensByAddress(tokenReceiver);

      require(tokensToClaim > 0);
      _clearTotalNormalTokensByAddress(tokenReceiver);

      violaToken.transferFrom(owner, tokenReceiver, tokensToClaim);

      TokenDistributed(tokenReceiver, tokensToClaim);

    }

    //Used by investor to claim bonus token
    function claimBonusTokens() external {
      require(hasEnded());
      require(now >= bonusVestingPeriod);
      require(addressKYC[msg.sender]);

      address tokenReceiver = msg.sender;
      uint tokensToClaim = getTotalBonusTokensByAddress(tokenReceiver);

      require(tokensToClaim > 0);
      _clearTotalBonusTokensByAddress(tokenReceiver);

      violaToken.transferFrom(owner, tokenReceiver, tokensToClaim);

      BonusTokenDistributed(tokenReceiver, tokensToClaim);
    }

    //Used by owner to distribute bonus token
    function distributeBonusTokens(address _tokenReceiver) onlyOwner external {
      require(hasEnded());
      require(now >= bonusVestingPeriod);

      address tokenReceiver = _tokenReceiver;
      uint tokensToClaim = getTotalBonusTokensByAddress(tokenReceiver);

      require(tokensToClaim > 0);
      _clearTotalBonusTokensByAddress(tokenReceiver);

      transferTokens(tokenReceiver, tokensToClaim);

      BonusTokenDistributed(tokenReceiver,tokensToClaim);

    }

    //Used by owner to distribute token
    function distributeICOTokens(address _tokenReceiver) onlyOwner external {
      require(hasEnded());

      address tokenReceiver = _tokenReceiver;
      uint tokensToClaim = getTotalNormalTokensByAddress(tokenReceiver);

      require(tokensToClaim > 0);
      _clearTotalNormalTokensByAddress(tokenReceiver);

      transferTokens(tokenReceiver, tokensToClaim);

      TokenDistributed(tokenReceiver,tokensToClaim);

    }

    //For owner to reserve token for presale
    // function reserveTokens(uint _amount) onlyOwner external {

    //   require(getTokensLeft() >= _amount);
    //   totalTokensAllocated = totalTokensAllocated.add(_amount);
    //   totalReservedTokenAllocated = totalReservedTokenAllocated.add(_amount);

    // }

    // //To distribute tokens not allocated by crowdsale contract
    // function distributePresaleTokens(address _tokenReceiver, uint _amount) onlyOwner external {
    //   require(hasEnded());
    //   require(_tokenReceiver != address(0));
    //   require(_amount > 0);

    //   violaToken.transferFrom(owner, _tokenReceiver, _amount);

    //   TokenDistributed(_tokenReceiver,_amount);

    // }

    //For external purchases & pre-sale via btc/fiat
    function externalPurchaseTokens(address _investor, uint _amount, uint _bonusAmount) onlyOwner external {
      require(_amount > 0);
      uint256 totalTokensToAllocate = _amount.add(_bonusAmount);

      require(getTokensLeft() >= totalTokensToAllocate);
      totalTokensAllocated = totalTokensAllocated.add(totalTokensToAllocate);
      totalReservedTokenAllocated = totalReservedTokenAllocated.add(totalTokensToAllocate);

      externalTokensAllocated[_investor] = externalTokensAllocated[_investor].add(_amount);
      externalBonusTokensAllocated[_investor] = externalBonusTokensAllocated[_investor].add(_bonusAmount);
      
      ExternalTokenPurchase(_investor,  _amount, _bonusAmount);

    }

    function refundAllExternalPurchase(address _investor) onlyOwner external {
      require(_investor != address(0));
      require(externalTokensAllocated[_investor] > 0);

      uint externalTokens = externalTokensAllocated[_investor];
      uint externalBonusTokens = externalBonusTokensAllocated[_investor];

      externalTokensAllocated[_investor] = 0;
      externalBonusTokensAllocated[_investor] = 0;

      uint totalInvestorTokens = externalTokens.add(externalBonusTokens);

      totalReservedTokenAllocated = totalReservedTokenAllocated.sub(totalInvestorTokens);
      totalTokensAllocated = totalTokensAllocated.sub(totalInvestorTokens);

      ExternalPurchaseRefunded(_investor,externalTokens,externalBonusTokens);
    }

    function refundExternalPurchase(address _investor, uint _amountToRefund, uint _bonusAmountToRefund) onlyOwner external {
      require(_investor != address(0));
      require(externalTokensAllocated[_investor] >= _amountToRefund);
      require(externalBonusTokensAllocated[_investor] >= _bonusAmountToRefund);

      uint totalTokensToRefund = _amountToRefund.add(_bonusAmountToRefund);
      externalTokensAllocated[_investor] = externalTokensAllocated[_investor].sub(_amountToRefund);
      externalBonusTokensAllocated[_investor] = externalBonusTokensAllocated[_investor].sub(_bonusAmountToRefund);

      totalReservedTokenAllocated = totalReservedTokenAllocated.sub(totalTokensToRefund);
      totalTokensAllocated = totalTokensAllocated.sub(totalTokensToRefund);

      ExternalPurchaseRefunded(_investor,_amountToRefund,_bonusAmountToRefund);
    }

    function _clearAddressFromCrowdsale(address _investor) internal {
      tokensAllocated[_investor] = 0;
      bonusTokensAllocated[_investor] = 0;
      investedSum[_investor] = 0;
      maxBuyCap[_investor] = 0;
    }

    function allocateTopupToken(address _investor, uint _amount, uint _bonusAmount) onlyOwner external {
      require(hasEnded());
      require(_amount > 0);
      uint256 tokensToAllocate = _amount.add(_bonusAmount);

      require(getTokensLeft() >= tokensToAllocate);
      totalTokensAllocated = totalTokensAllocated.add(_amount);

      tokensAllocated[_investor] = tokensAllocated[_investor].add(_amount);
      bonusTokensAllocated[_investor] = bonusTokensAllocated[_investor].add(_bonusAmount);

      TopupTokenAllocated(_investor,  _amount, _bonusAmount);
    }

  //For cases where token are mistakenly sent / airdrops
  function emergencyERC20Drain( ERC20 token, uint amount ) external onlyOwner {
    require(status == State.Completed);
    token.transfer(owner,amount);
  }

}