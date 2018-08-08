pragma solidity 0.4.24;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract ERC20 is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances; 

 
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
 function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is ERC20, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  bool public mintingFinished = false;
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}




/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}


/**
 * @title MintedCrowdsale
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting. 
 */
contract MintedCrowdsale is Crowdsale {

  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}



/**
 * @title EscrowAccountCrowdsale.
 */
contract EscrowAccountCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;
  EscrowVault public vault;
  /**
   * @dev Constructor, creates EscrowAccountCrowdsale.
   */
   function EscrowAccountCrowdsale() public {
    vault = new EscrowVault(wallet);
  }
  /**
   * @dev Investors can claim refunds here if whitelisted is unsuccessful
   */
  function returnInvestoramount(address _beneficiary, uint256 _percentage) internal onlyOwner {
    vault.refund(_beneficiary,_percentage);
  }

  function afterWhtelisted(address _beneficiary) internal onlyOwner{
      vault.closeAfterWhitelisted(_beneficiary);
  }
  /**
   * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
   */
  function _forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

}

/**
 * @title EscrowVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if whitelist fails,
 * and forwarding it if whitelist is successful.
 */
contract EscrowVault is Ownable {
  using SafeMath for uint256;
  mapping (address => uint256) public deposited;
  address public wallet;
  event Closed();
  event Refunded(address indexed beneficiary, uint256 weiAmount);
  /**
   * @param _wallet Vault address
   */
  function EscrowVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
   
  }
  /**
   * @param investor Investor address
   */
  function deposit(address investor) onlyOwner  payable {
    deposited[investor] = deposited[investor].add(msg.value);
  }
   function closeAfterWhitelisted(address _beneficiary) onlyOwner public {
   
    uint256 depositedValue = deposited[_beneficiary];
    deposited[_beneficiary] = 0;
    wallet.transfer(depositedValue);
  }
   

  /**
   * @param investor Investor address
   */
  function refund(address investor, uint256 _percentage)onlyOwner  {
    uint256 depositedValue = deposited[investor];
    depositedValue=depositedValue.sub(_percentage);
   
    investor.transfer(depositedValue);
    wallet.transfer(_percentage);
    emit Refunded(investor, depositedValue);
     deposited[investor] = 0;
  }
}

/**
 * @title PostDeliveryCrowdsale
 * @dev Crowdsale that locks tokens from withdrawal until it whitelisted and crowdsale ends.
 */
contract PostDeliveryCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  /**
   * @dev Withdraw tokens only after whitelisted ends and after crowdsale ends.
   */
   
  
  function withdrawTokens() public {
   require(hasClosed());
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
  }
  
  
   function failedWhitelist(address _beneficiary) internal  {
    require(_beneficiary != address(0));
    uint256 amount = balances[_beneficiary];
    balances[_beneficiary] = 0;
  }
  function getInvestorDepositAmount(address _investor) public constant returns(uint256 paid){
     
     return balances[_investor];
 }

  /**
   * @dev Overrides parent by storing balances instead of issuing tokens right away.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }

}


contract CryptoAssetCrowdsale is TimedCrowdsale, MintedCrowdsale,EscrowAccountCrowdsale,PostDeliveryCrowdsale {

 enum Stage {PROCESS1_FAILED, PROCESS1_SUCCESS,PROCESS2_FAILED, PROCESS2_SUCCESS,PROCESS3_FAILED, PROCESS3_SUCCESS} 	
 	//stage Phase1 or Phase2 or Phase
	enum Phase {PHASE1, PHASE2,PHASE3}
	//stage ICO
	Phase public phase;
 
  struct whitelisted{
       Stage  stage;
 }
  uint256 public adminCharge_p1=0.010 ether;
  uint256 public adminCharge_p2=0.13 ether;
  uint256 public adminCharge_p3=0.14 ether;
  uint256 public cap=750 ether;// softcap is 750 ether
  uint256 public goal=4500 ether;// hardcap is 4500 ether
  uint256 public minContribAmount = 0.1 ether; // min invesment
  mapping(address => whitelisted) public whitelist;
  // How much ETH each address has invested to this crowdsale
  mapping (address => uint256) public investedAmountOf;
    // How many distinct addresses have invested
  uint256 public investorCount;
    // decimalFactor
  uint256 public constant DECIMALFACTOR = 10**uint256(18);
  event updateRate(uint256 tokenRate, uint256 time);
  
   /**
 	* @dev CryptoAssetCrowdsale is a base contract for managing a token crowdsale.
 	* CryptoAssetCrowdsale have a start and end timestamps, where investors can make
 	* token purchases and the crowdsale will assign them tokens based
 	* on a token per ETH rate. Funds collected are forwarded to a wallet
 	* as they arrive.
 	*/
  
 function CryptoAssetCrowdsale(uint256 _starttime, uint256 _endTime, uint256 _rate, address _wallet,ERC20 _token)
  TimedCrowdsale(_starttime,_endTime)Crowdsale(_rate, _wallet,_token)
  {
      phase = Phase.PHASE1;
  }
    
  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }
  
  function buyTokens(address _beneficiary) public payable onlyWhileOpen{
    require(_beneficiary != address(0));
    require(validPurchase());
  
    uint256 weiAmount = msg.value;
    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);
    uint256 volumebasedBonus=0;
    if(phase == Phase.PHASE1){
    volumebasedBonus = tokens.mul(getTokenVolumebasedBonusRateForPhase1(tokens)).div(100);

    }else if(phase == Phase.PHASE2){
    volumebasedBonus = tokens.mul(getTokenVolumebasedBonusRateForPhase2(tokens)).div(100);

    }else{
    volumebasedBonus = tokens.mul(getTokenVolumebasedBonusRateForPhase3(tokens)).div(100);

    }

    tokens=tokens.add(volumebasedBonus);
    _preValidatePurchase( _beneficiary,  weiAmount);
    weiRaised = weiRaised.add(weiAmount);
    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    _forwardFunds();
    if(investedAmountOf[msg.sender] == 0) {
           // A new investor
           investorCount++;
        }
        // Update investor
        investedAmountOf[msg.sender] = investedAmountOf[msg.sender].add(weiAmount);
  }
    function tokensaleToOtherCoinUser(address beneficiary, uint256 weiAmount) public onlyOwner onlyWhileOpen {
    require(beneficiary != address(0) && weiAmount > 0);
    uint256 tokens = weiAmount.mul(rate);
    uint256 volumebasedBonus=0;
    if(phase == Phase.PHASE1){
    volumebasedBonus = tokens.mul(getTokenVolumebasedBonusRateForPhase1(tokens)).div(100);

    }else if(phase == Phase.PHASE2){
    volumebasedBonus = tokens.mul(getTokenVolumebasedBonusRateForPhase2(tokens)).div(100);

    }else{
    volumebasedBonus = tokens.mul(getTokenVolumebasedBonusRateForPhase3(tokens)).div(100);

    }

    tokens=tokens.add(volumebasedBonus);
    weiRaised = weiRaised.add(weiAmount);
    _processPurchase(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }
    
    function validPurchase() internal constant returns (bool) {
    bool minContribution = minContribAmount <= msg.value;
    return  minContribution;
  }
  
  
  function getTokenVolumebasedBonusRateForPhase1(uint256 value) internal constant returns (uint256) {
        uint256 bonusRate = 0;
        uint256 valume = value.div(DECIMALFACTOR);

        if (valume <= 50000 && valume >= 149999) {
            bonusRate = 30;
        } else if (valume <= 150000 && valume >= 299999) {
            bonusRate = 35;
        } else if (valume <= 300000 && valume >= 500000) {
            bonusRate = 40;
        } else{
            bonusRate = 25;
        }

        return bonusRate;
    }
  
   function getTokenVolumebasedBonusRateForPhase2(uint256 value) internal constant returns (uint256) {
        uint256 bonusRate = 0;
        uint valume = value.div(DECIMALFACTOR);

        if (valume <= 50000 && valume >= 149999) {
            bonusRate = 25;
        } else if (valume <= 150000 && valume >= 299999) {
            bonusRate = 30;
        } else if (valume <= 300000 && valume >= 500000) {
            bonusRate = 35;
        } else{
            bonusRate = 20;
        }

        return bonusRate;
    }
    
     function getTokenVolumebasedBonusRateForPhase3(uint256 value) internal constant returns (uint256) {
        uint256 bonusRate = 0;
        uint valume = value.div(DECIMALFACTOR);

        if (valume <= 50000 && valume >= 149999) {
            bonusRate = 20;
        } else if (valume <= 150000 && valume >= 299999) {
            bonusRate = 25;
        } else if (valume <= 300000 && valume >= 500000) {
            bonusRate = 30;
        } else{
            bonusRate = 15;
        }

        return bonusRate;
    }
  
  /**
 	* @dev change the Phase from phase1 to phase2 
 	*/
  	function startPhase2(uint256 _startTime) public onlyOwner {
      	require(_startTime>0);
      	phase = Phase.PHASE2;
      	openingTime=_startTime;
      
   }
   
     /**
 	* @dev change the Phase from phase2 to phase3 sale
 	*/
  	function startPhase3(uint256 _startTime) public onlyOwner {
      	require(0> _startTime);
      	phase = Phase.PHASE3;
        openingTime=_startTime;

   }

 /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary].stage==Stage.PROCESS3_SUCCESS);
    _;
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary,uint256 _stage) external onlyOwner {
      require(_beneficiary != address(0));
      require(_stage>0);  
 if(_stage==1){
     whitelist[_beneficiary].stage=Stage.PROCESS1_FAILED;
     returnInvestoramount(_beneficiary,adminCharge_p1);
     failedWhitelist(_beneficiary);
     investedAmountOf[_beneficiary]=0;
 }else if(_stage==2){
     whitelist[_beneficiary].stage=Stage.PROCESS1_SUCCESS;
 }else if(_stage==3){
     whitelist[_beneficiary].stage=Stage.PROCESS2_FAILED;
     returnInvestoramount(_beneficiary,adminCharge_p2);
     failedWhitelist(_beneficiary);
          investedAmountOf[_beneficiary]=0;
 }else if(_stage==4){
     whitelist[_beneficiary].stage=Stage.PROCESS2_SUCCESS;
 }else if(_stage==5){
     whitelist[_beneficiary].stage=Stage.PROCESS3_FAILED;
     returnInvestoramount(_beneficiary,adminCharge_p3);
     failedWhitelist(_beneficiary);
          investedAmountOf[_beneficiary]=0;
     }else if(_stage==6){
     whitelist[_beneficiary].stage=Stage.PROCESS3_SUCCESS;
     afterWhtelisted( _beneficiary);
 }
 
 }
 
  /**
   * @dev Withdraw tokens only after Investors added into whitelist .
   */
  function withdrawTokens() public isWhitelisted(msg.sender)  {
    require(hasClosed());
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
   
  }
  
 /**
 * @dev Change crowdsale ClosingTime
 * @param  _endTime is End time in Seconds
 */
  function changeEndtime(uint256 _endTime) public onlyOwner {
    require(_endTime > 0); 
    closingTime = _endTime;
    }

 /**
 * @dev Change Token rate per ETH
 * @param  _rate is set the current rate of AND Token
 */
  function changeRate(uint256 _rate) public onlyOwner {
    require(_rate > 0); 
    rate = _rate;
    emit updateRate(_rate,block.timestamp);
    }
  /**
 * @dev Change admin chargers
 * @param  _p1 for first Kyc Failed-$5
 * @param  _p2 for second AML Failed-$7
 * @param  _p3 for third AI Failed-$57
 */
  function changeAdminCharges(uint256 _p1,uint256 _p2,uint256 _p3) public onlyOwner {
    require(_p1 > 0);
    require(_p2 > 0); 
    require(_p3 > 0); 
    adminCharge_p1=_p1;
    adminCharge_p2=_p2;
    adminCharge_p3=_p3;
    
    }
    
 /**
   * @dev Change minContribution amountAmount.
   * @param _minInvestment for minimum contribution ETH amount
   */
  function changeMinInvestment(uint256 _minInvestment) public onlyOwner {
     require(_minInvestment > 0);
     minContribAmount=_minInvestment;
  }
  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }
  /**
   * @dev Checks whether the goal has been reached.
   * @return Whether the goal was reached
   */
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }
  
  	/**
 	* @param _to is beneficiary address
 	* @param _value  Amount if tokens
 	* @dev  tokens distribution
 	*/
	function tokenDistribution(address _to, uint256 _value)public onlyOwner {
        require (
           _to != 0x0 && _value > 0);
        _processPurchase(_to, _value);
        whitelist[_to].stage=Stage.PROCESS3_SUCCESS;
    }
}