pragma solidity ^0.4.23;

// From OpenZeppelin
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// from Open-Zeppelin
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  // 1 denied / 0 allow
  mapping(address => uint8) permissionsList;
  
  function SetPermissionsList(address _address, uint8 _sign) public onlyOwner{
    permissionsList[_address] = _sign; 
  }
  function GetPermissionsList(address _address) public constant onlyOwner returns(uint8){
    return permissionsList[_address]; 
  }  
  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(permissionsList[msg.sender] == 0);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(permissionsList[msg.sender] == 0);
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is PausableToken {
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
  function mint(address _to, uint256 _amount) onlyOwner canMint whenNotPaused public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}
contract BurnableByOwner is BasicToken {

  event Burn(address indexed burner, uint256 value);
  function burn(address _address, uint256 _value) public onlyOwner{
    require(_value <= balances[_address]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = _address;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}

contract TRND is Ownable, MintableToken, BurnableByOwner {
  using SafeMath for uint256;    
  string public constant name = "Trends";
  string public constant symbol = "TRND";
  uint32 public constant decimals = 18;
  
  address public addressPrivateSale;
  address public addressAirdrop;
  address public addressFoundersShare;
  address public addressPartnershipsAndExchanges;

  uint256 public summPrivateSale;
  uint256 public summAirdrop;
  uint256 public summFoundersShare;
  uint256 public summPartnershipsAndExchanges;
 // uint256 public totalSupply;

  function TRND() public {
    addressPrivateSale   = 0xAfB042EE51FE904F67935222744628e1Ce3F6584;
    addressFoundersShare = 0x6E3F6b1cB72B4C315d0Ae719aACbE8436638b134;
    addressPartnershipsAndExchanges  = 0xedc57Ed34370139E9f8144C7cf3D0374fa1f0eCf; 
    addressAirdrop       = 0xA1f99816B7DD6913bF8BDe68d71A1a3a6A47513B;
	
    summPrivateSale   = 5000000 * (10 ** uint256(decimals)); 
    summFoundersShare = 5000000 * (10 ** uint256(decimals));  
    summPartnershipsAndExchanges  = 7500000 * (10 ** uint256(decimals));  		    
    summAirdrop       = 2500000 * (10 ** uint256(decimals));  
    // Founders and supporters initial Allocations
    mint(addressPrivateSale, summPrivateSale);
    mint(addressAirdrop, summAirdrop);
    mint(addressFoundersShare, summFoundersShare);
    mint(addressPartnershipsAndExchanges, summPartnershipsAndExchanges);
  }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where Contributors can make
 * token Contributions and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive. The contract requires a MintableToken that will be
 * minted as contributions arrive, note that the crowdsale contract
 * must be owner of the token in order to be able to mint it.
 */
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  // soft cap
  uint256 softcap;
  // hard cap
  uint256 hardcapPreICO; 
  uint256 hardcapMainSale;  
  TRND public token;
  // balances for softcap
  mapping(address => uint) public balances;

  // start and end timestamps where investments are allowed (both inclusive)
  // start
  uint256 public startIcoPreICO;  
  uint256 public startIcoPreICO2ndRound;  
  uint256 public startIcoMainSale;  
  // end 
  uint256 public endIcoPreICO; 
  uint256 public endIcoMainSale;   

  //token distribution
  uint256 public totalSoldTokens;
  uint256 public minPurchasePreICO;     
  
  // how many token units a Contributor gets per wei
  uint256 public rateIcoPreICO;
  uint256 public rateIcoMainSale;

  //Unconfirmed sum
  uint256 public unconfirmedSum;
  mapping(address => uint) public unconfirmedSumAddr;

  // address where funds are collected
  address public wallet;
  
  bool isTesting;
  
/**
* event for token Procurement logging
* @param contributor who Pledged for the tokens
* @param beneficiary who got the tokens
* @param value weis Contributed for Procurement
* @param amount amount of tokens Procured
*/
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);
  
  function Crowdsale() public {
    //isTesting = _isTesting;
    token = createTokenContract();
    //soft cap in tokens
    softcap            = 20000000 * 1 ether; 
    hardcapPreICO      =  5000000 * 1 ether; 
    hardcapMainSale    = 75000000 * 1 ether; 
	
    //min Purchase in wei = 0.1 ETH
    minPurchasePreICO      = 100000000000000000;
    
    // start and end timestamps where investments are allowed
    startIcoPreICO   = 1530435600;        // 07/01/2018 @ 9:00am (UTC)
    startIcoPreICO2ndRound = 1531731600;  // 07/16/2018 @ 9:00am (UTC)
    endIcoPreICO     = 1533027600;        // 07/31/2018 @ 9:00am (UTC)
    startIcoMainSale = 1534323600;        // 08/15/2018 @ 9:00am (UTC)
    endIcoMainSale   = 1538557200;        // 10/03/2018 @ 9:00am (UTC)

    //rate; 0.1875$ for ETH = 550$
    rateIcoPreICO = 2933;
    //rate; 0.25$ for ETH = 550$
    rateIcoMainSale = 2200;

    // address where funds are collected
    wallet = 0xca5EdAE100d4D262DC3Ec2dE96FD9943Ea659d04;
  }


// for testing
  function contractBalanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

// for testing
  function tokenBalanceOf(address _owner) public view returns (uint256) {
    return token.balanceOf(_owner);
  }

  function setStartIcoPreICO(uint256 _startIcoPreICO) public onlyOwner  { 
    // Enforce consistency of dates
    require(_startIcoPreICO < endIcoPreICO);
    // Once Pre-ICO has started, none of the dates can be moved anymore.
    require(now < startIcoPreICO); // removed so this can be tested
	  startIcoPreICO   = _startIcoPreICO;
  }

  function setStartIcoPreICO2ndRound(uint256 _startIcoPreICO2ndRound) public onlyOwner  { 
    // Enforce consistency of dates
    require(_startIcoPreICO2ndRound > startIcoPreICO && _startIcoPreICO2ndRound < endIcoPreICO);
    // Once Pre-ICO has started, none of the dates can be moved anymore.
    require(now < startIcoPreICO);
	  startIcoPreICO2ndRound   = _startIcoPreICO2ndRound;
  }

  function setEndIcoPreICO(uint256 _endIcoPreICO) public onlyOwner  {     
	// Enforce consistency of dates
    require(startIcoPreICO < _endIcoPreICO && _endIcoPreICO < startIcoMainSale);
    // Once Pre-ICO has started, none of the dates can be moved anymore.
    require(now < startIcoPreICO);
	  endIcoPreICO   = _endIcoPreICO;
  }
  
  function setStartIcoMainICO(uint256 _startIcoMainSale) public onlyOwner  { 
    // Enforce consistency of dates
    require(endIcoPreICO < _startIcoMainSale && _startIcoMainSale < endIcoMainSale);
    // Once Pre-ICO has started, none of the dates can be moved anymore.    
    require(now < startIcoPreICO);
	  startIcoMainSale   = _startIcoMainSale;
  }
  
  function setEndIcoMainICO(uint256 _endIcoMainSale) public onlyOwner  { 
    // Enforce consistency of dates
    require(startIcoMainSale < _endIcoMainSale);
    // Once Pre-ICO has started, none of the dates can be moved anymore.
    require(now < startIcoPreICO);
	  endIcoMainSale   = _endIcoMainSale;
  }
  
  // set all the dates
  function setIcoDates(
                  uint256 _startIcoPreICO,
                  uint256 _startIcoPreICO2ndRound,
                  uint256 _endIcoPreICO,
                  uint256 _startIcoMainSale,
                  uint256 _endIcoMainSale
    ) public onlyOwner  { 
    // Enforce consistency of dates
    require(_startIcoPreICO < _startIcoPreICO2ndRound);
    require(_startIcoPreICO2ndRound < _endIcoPreICO);
    require(_endIcoPreICO <= _startIcoMainSale);
    require(_startIcoMainSale < _endIcoMainSale);
    // Once Pre-ICO has started, none of the dates can be moved anymore.
    require(now < startIcoPreICO); 

	  startIcoPreICO   = _startIcoPreICO;
	  startIcoPreICO2ndRound = _startIcoPreICO2ndRound;
    endIcoPreICO = _endIcoPreICO;
    startIcoMainSale = _startIcoMainSale;
	  endIcoMainSale = _endIcoMainSale;
  }
  function setRateIcoPreICO(uint256 _rateIcoPreICO) public onlyOwner  {
    rateIcoPreICO = _rateIcoPreICO;
  }   
  
  function setRateIcoMainSale(uint _rateIcoMainSale) public onlyOwner  {
    rateIcoMainSale = _rateIcoMainSale;
  }
       
  // fallback function can be used to Procure tokens
  function () external payable {
    procureTokens(msg.sender);
  }
  
  function createTokenContract() internal returns (TRND) {
    return new TRND();
  }
  
  function getRateIcoWithBonus() public view returns (uint256) {
    return getRateIcoWithBonusByDate(now);
  }    

  // testable method
  function getRateIcoWithBonusByDate(uint256 _date) public view returns (uint256) {
    uint256 bonus;
	  uint256 rateICO;
    //icoPreICO   
    if (_date >= startIcoPreICO && _date < endIcoPreICO){
      rateICO = rateIcoPreICO;
    }  

    //icoMainSale   
    if (_date >= startIcoMainSale  && _date < endIcoMainSale){
      rateICO = rateIcoMainSale;
    }  

    // bonus
    // Note: Multiplying percentages with 10, later dividing by 1000 instead of 100
    // This deals with our 0.2% daily decrease. 
    if (_date >= startIcoPreICO && _date < startIcoPreICO2ndRound){
      bonus = 300; // 30% * 10
    } else if (_date >= startIcoPreICO2ndRound && _date < endIcoPreICO){
      bonus = 200; // 20% * 10
    } else if (_date >= startIcoMainSale) {
      // note: 86400 seconds in a day, decrease by 0.2% daily
      uint256 daysSinceMainIcoStarted = (_date - startIcoMainSale) / 86400;
      bonus = 100 - (2 * daysSinceMainIcoStarted); // 10% - 0.2 per day * 10
      if (bonus < 0) { // safety - all the dates can be changed
        bonus = 0;
      }
    }

    return rateICO + rateICO.mul(bonus).div(1000);
  }    

  // low level token Pledge function
  function procureTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 backAmount;
    uint256 rate;
    uint hardCap;
    require(beneficiary != address(0));
    rate = getRateIcoWithBonus();
    //icoPreICO   
    hardCap = hardcapPreICO;
    if (now >= startIcoPreICO && now < endIcoPreICO && totalSoldTokens < hardCap){
	    require(weiAmount >= minPurchasePreICO);
      tokens = weiAmount.mul(rate);
      if (hardCap.sub(totalSoldTokens) < tokens){
        tokens = hardCap.sub(totalSoldTokens); 
        weiAmount = tokens.div(rate);
        backAmount = msg.value.sub(weiAmount);
      }
    }  
    //icoMainSale  
    hardCap = hardcapMainSale.add(hardcapPreICO);
    if (now >= startIcoMainSale  && now < endIcoMainSale  && totalSoldTokens < hardCap){
      tokens = weiAmount.mul(rate);
      if (hardCap.sub(totalSoldTokens) < tokens){
        tokens = hardCap.sub(totalSoldTokens); 
        weiAmount = tokens.div(rate);
        backAmount = msg.value.sub(weiAmount);
      }
    }         
    require(tokens > 0);
    totalSoldTokens = totalSoldTokens.add(tokens);
    balances[msg.sender] = balances[msg.sender].add(weiAmount);
    token.mint(msg.sender, tokens);
	  unconfirmedSum = unconfirmedSum.add(tokens);
	  unconfirmedSumAddr[msg.sender] = unconfirmedSumAddr[msg.sender].add(tokens);
	  token.SetPermissionsList(beneficiary, 1);
    if (backAmount > 0){
      msg.sender.transfer(backAmount);    
    }
    emit TokenProcurement(msg.sender, beneficiary, weiAmount, tokens);
  }

  function refund() public{
    require(totalSoldTokens.sub(unconfirmedSum) < softcap && now > endIcoMainSale);
    require(balances[msg.sender] > 0);
    uint value = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(value);
  }
  
  function transferEthToMultisig() public onlyOwner {
    address _this = this;
    // during main sale, all funds are protected by soft cap, all funds will be restored if softcap is not hit
    require(now < startIcoMainSale || (totalSoldTokens.sub(unconfirmedSum) >= softcap && now > endIcoMainSale));  
    wallet.transfer(_this.balance);
  } 
  
  function refundUnconfirmed() public{
    // you can claim a refund 24h after main sale ended
    require(now > endIcoMainSale + 24*60*60);
    require(balances[msg.sender] > 0);
    require(token.GetPermissionsList(msg.sender) == 1);
    uint value = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(value);
   // token.burn(msg.sender, token.balanceOf(msg.sender));
    uint uvalue = unconfirmedSumAddr[msg.sender];
    unconfirmedSumAddr[msg.sender] = 0;
    token.burn(msg.sender, uvalue );
   // totalICO = totalICO.sub(token.balanceOf(msg.sender));    
  } 
  
  function SetPermissionsList(address _address, uint8 _sign) public onlyOwner{
      uint8 sign;
      sign = token.GetPermissionsList(_address);
      token.SetPermissionsList(_address, _sign);
      if (_sign == 0){
          if (sign != _sign){  
			      unconfirmedSum = unconfirmedSum.sub(unconfirmedSumAddr[_address]);
			      unconfirmedSumAddr[_address] = 0;
          }
      }
   }
   
   function GetPermissionsList(address _address) public constant onlyOwner returns(uint8){
     return token.GetPermissionsList(_address); 
   }   
   
   function pause() onlyOwner public {
     token.pause();
   }

   function unpause() onlyOwner public {
     token.unpause();
   }
    
}