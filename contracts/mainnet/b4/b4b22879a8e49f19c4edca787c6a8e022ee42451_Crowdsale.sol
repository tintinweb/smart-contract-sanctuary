pragma solidity ^0.4.23;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken {
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


contract BVA is Ownable, MintableToken {
  using SafeMath for uint256;    
  string public constant name = "BlockchainValley";
  string public constant symbol = "BVA";
  uint32 public constant decimals = 18;
  address public addressFounders;
  uint256 public summFounders;
  function BVA() public {
    addressFounders = 0x6e69307fe1fc55B2fffF680C5080774D117f1154;  
    summFounders = 35340000 * (10 ** uint256(decimals));  
    mint(addressFounders, summFounders);      
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
  BVA public token;
  //Start timestamps where investments are allowed
  uint256 public startPreICO;
  uint256 public endPreICO;  
  uint256 public startICO;
  uint256 public endICO;
  //Hard cap
  uint256 public sumHardCapPreICO;
  uint256 public sumHardCapICO;
  uint256 public sumPreICO;
  uint256 public sumICO;
  //Min Max Investment
  uint256 public minInvestmentPreICO;
  uint256 public minInvestmentICO;
  uint256 public maxInvestmentICO;
  //rate
  uint256 public ratePreICO; 
  uint256 public rateICO;
  //address where funds are collected
  address public wallet;
  //referral system
  uint256 public maxRefererTokens;
  uint256 public allRefererTokens;
/**
* event for token Procurement logging
* @param contributor who Pledged for the tokens
* @param beneficiary who got the tokens
* @param value weis Contributed for Procurement
* @param amount amount of tokens Procured
*/
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);
  
  function Crowdsale() public {
    token = createTokenContract();
    //Hard cap
    sumHardCapPreICO = 15000000 * 1 ether;
    sumHardCapICO = 1000000 * 1 ether;
    //referral system
    maxRefererTokens = 2500000 * 1 ether;
    //Min Max Investment
    minInvestmentPreICO = 3 * 1 ether;
    minInvestmentICO = 100000000000000000; //0.1 ether
    maxInvestmentICO = 5 * 1 ether;
    //rate;
    ratePreICO = 1500;
    rateICO = 1000;    
    // address where funds are collected
    wallet = 0x00a134aE23247c091Dd4A4dC1786358f26714ea3;
  }

  function setRatePreICO(uint256 _ratePreICO) public onlyOwner  {
    ratePreICO = _ratePreICO;
  } 
  
  function setRateICO(uint256 _rateICO) public onlyOwner  {
    rateICO = _rateICO;
  }  
  
  function setStartPreICO(uint256 _startPreICO) public onlyOwner  {
    //require(_startPreICO < endPreICO);  
    startPreICO = _startPreICO;
  }   

  function setEndPreICO(uint256 _endPreICO) public onlyOwner  {
    //require(_endPreICO > startPreICO);
    //require(_endPreICO < startICO);
    endPreICO = _endPreICO;
  }

  function setStartICO(uint256 _startICO) public onlyOwner  {
    //require(_startICO > endPreICO); 
    //require(_startICO < endICO);  
    startICO = _startICO;
  }

  function setEndICO(uint256 _endICO) public onlyOwner  {
    //require(_endICO > startICO); 
    endICO = _endICO;
  }
  
  // fallback function can be used to Procure tokens
  function () external payable {
    procureTokens(msg.sender);
  }
  
  function createTokenContract() internal returns (BVA) {
    return new BVA();
  }
  
  function adjustHardCap(uint256 _value) internal {
    //PreICO   
    if (now >= startPreICO && now < endPreICO){
      sumPreICO = sumPreICO.add(_value);
    }  
    //ICO   
    if (now >= startICO && now < endICO){
      sumICO = sumICO.add(_value);
    }       
  }  

  function checkHardCap(uint256 _value) view public {
    //PreICO   
    if (now >= startPreICO && now < endPreICO){
      require(_value.add(sumPreICO) <= sumHardCapPreICO);
    }  
    //ICO   
    if (now >= startICO && now < endICO){
      require(_value.add(sumICO) <= sumHardCapICO);
    }       
  } 
  
  function checkMinMaxInvestment(uint256 _value) view public {
    //PreICO   
    if (now >= startPreICO && now < endPreICO){
      require(_value >= minInvestmentPreICO);
    }  
    //ICO   
    if (now >= startICO && now < endICO){
      require(_value >= minInvestmentICO);
      require(_value <= maxInvestmentICO);
    }       
  }
  
  function bytesToAddress(bytes source) internal pure returns(address) {
    uint result;
    uint mul = 1;
    for(uint i = 20; i > 0; i--) {
      result += uint8(source[i-1])*mul;
      mul = mul*256;
    }
    return address(result);
  }
  
  function procureTokens(address _beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    address _this = this;
    uint256 rate;
    address referer;
    uint256 refererTokens;
    require(now >= startPreICO);
    require(now <= endICO);
    require(_beneficiary != address(0));
    checkMinMaxInvestment(weiAmount);
    rate = getRate();
    tokens = weiAmount.mul(rate);
    //referral system
	if(msg.data.length == 20) {
      referer = bytesToAddress(bytes(msg.data));
      require(referer != msg.sender);
	  //add tokens to the referrer
      refererTokens = tokens.mul(5).div(100);
    }
    checkHardCap(tokens.add(refererTokens));
    adjustHardCap(tokens.add(refererTokens));
    wallet.transfer(_this.balance);
	if (refererTokens != 0 && allRefererTokens.add(refererTokens) <= maxRefererTokens){
	  allRefererTokens = allRefererTokens.add(refererTokens);
      token.mint(referer, refererTokens);	  
	}    
    token.mint(_beneficiary, tokens);
    emit TokenProcurement(msg.sender, _beneficiary, weiAmount, tokens);
  }
  
  function getRate() public view returns (uint256) {
    uint256 rate;
    //PreICO   
    if (now >= startPreICO && now < endPreICO){
      rate = ratePreICO;
    }  
    //ICO   
    if (now >= startICO && now < endICO){
      rate = rateICO;
    }      
    return rate;
  }  
}