pragma solidity 0.4.24;

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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  //event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  //function renounceOwnership() public onlyOwner {
  //  emit OwnershipRenounced(owner);
  //  owner = address(0);
  //}
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping(address => uint256) bonusTokens;
  mapping(address => uint256) bonusReleaseTime;
  
  mapping(address => bool) internal blacklist;
  bool public isTokenReleased = false;
  
  address addressSaleContract;
  event BlacklistUpdated(address badUserAddress, bool registerStatus);
  event TokenReleased(address tokenOwnerAddress, bool tokenStatus);

  uint256 totalSupply_;

  modifier onlyBonusSetter() {
      require(msg.sender == owner || msg.sender == addressSaleContract);
      _;
  }

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
    require(isTokenReleased);
    require(!blacklist[_to]);
    require(!blacklist[msg.sender]);
    
    if (bonusReleaseTime[msg.sender] > block.timestamp) {
        require(_value <= balances[msg.sender].sub(bonusTokens[msg.sender]));
    }
    
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
    require(msg.sender == owner || !blacklist[_owner]);
    require(!blacklist[msg.sender]);
    return balances[_owner];
  }

  /**
  * @dev Set the specified address to blacklist.
  * @param _badUserAddress The address of bad user.
  */
  function registerToBlacklist(address _badUserAddress) onlyOwner public {
      if (blacklist[_badUserAddress] != true) {
	  	  blacklist[_badUserAddress] = true;
	  }
      emit BlacklistUpdated(_badUserAddress, blacklist[_badUserAddress]);   
  }
  
  /**
  * @dev Remove the specified address from blacklist.
  * @param _badUserAddress The address of bad user.
  */
  function unregisterFromBlacklist(address _badUserAddress) onlyOwner public {
      if (blacklist[_badUserAddress] == true) {
	  	  blacklist[_badUserAddress] = false;
	  }
      emit BlacklistUpdated(_badUserAddress, blacklist[_badUserAddress]);
  }

  /**
  * @dev Check the address registered in blacklist.
  * @param _address The address to check.
  * @return a bool representing registration of the passed address.
  */
  function checkBlacklist (address _address) onlyOwner public view returns (bool) {
      return blacklist[_address];
  }
  
  /**
  * @dev Release the token (enable all token functions).
  */
  function releaseToken() onlyOwner public {
      if (isTokenReleased == false) {
		isTokenReleased = true;
	  }
      emit TokenReleased(msg.sender, isTokenReleased);
  }
  
  /**
  * @dev Withhold the token (disable all token functions).
  */
  function withholdToken() onlyOwner public {
      if (isTokenReleased == true) {
		isTokenReleased = false;
      }
	  emit TokenReleased(msg.sender, isTokenReleased);
  }
  
  /**
  * @dev Set bonus token amount and bonus token release time for the specified address.
  * @param _tokenHolder The address of bonus token holder
  *        _bonusTokens The bonus token amount
  *        _holdingPeriodInDays Bonus token holding period (in days) 
  */  
  function setBonusTokenInDays(address _tokenHolder, uint256 _bonusTokens, uint256 _holdingPeriodInDays) onlyBonusSetter public {
      bonusTokens[_tokenHolder] = _bonusTokens;
      bonusReleaseTime[_tokenHolder] = SafeMath.add(block.timestamp, _holdingPeriodInDays * 1 days);
  }

  /**
  * @dev Set bonus token amount and bonus token release time for the specified address.
  * @param _tokenHolder The address of bonus token holder
  *        _bonusTokens The bonus token amount
  *        _bonusReleaseTime Bonus token release time
  */  
  function setBonusToken(address _tokenHolder, uint256 _bonusTokens, uint256 _bonusReleaseTime) onlyBonusSetter public {
      bonusTokens[_tokenHolder] = _bonusTokens;
      bonusReleaseTime[_tokenHolder] = _bonusReleaseTime;
  }
  
  /**
  * @dev Set bonus token amount and bonus token release time for the specified address.
  * @param _tokenHolders The address of bonus token holder [ ] 
  *        _bonusTokens The bonus token amount [ ] 
  *        _bonusReleaseTime Bonus token release time
  */  
  function setMultiBonusTokens(address[] _tokenHolders, uint256[] _bonusTokens, uint256 _bonusReleaseTime) onlyBonusSetter public {
      for (uint i = 0; i < _tokenHolders.length; i++) {
        bonusTokens[_tokenHolders[i]] = _bonusTokens[i];
        bonusReleaseTime[_tokenHolders[i]] = _bonusReleaseTime;
      }
  }

  /**
  * @dev Set the address of the crowd sale contract which can call setBonusToken method.
  * @param _addressSaleContract The address of the crowd sale contract.
  */
  function setBonusSetter(address _addressSaleContract) onlyOwner public {
      addressSaleContract = _addressSaleContract;
  }
  
  function getBonusSetter() public view returns (address) {
      require(msg.sender == addressSaleContract || msg.sender == owner);
      return addressSaleContract;
  }
  
  /**
  * @dev Display token holder&#39;s bonus token amount.
  * @param _bonusHolderAddress The address of bonus token holder.
  */
  function checkBonusTokenAmount (address _bonusHolderAddress) public view returns (uint256) {
      return bonusTokens[_bonusHolderAddress];
  }
  
  /**
  * @dev Display token holder&#39;s remaining bonus token holding period.
  * @param _bonusHolderAddress The address of bonus token holder.
  */
  function checkBonusTokenHoldingPeriodRemained (address _bonusHolderAddress) public view returns (uint256) {
      uint256 returnValue = 0;
      if (bonusReleaseTime[_bonusHolderAddress] > now) {
          returnValue = bonusReleaseTime[_bonusHolderAddress].sub(now);
      }
      return returnValue;
  }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) onlyOwner public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) onlyOwner internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
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
    require(!blacklist[_from]);
    require(!blacklist[_to]);
	require(!blacklist[msg.sender]);
    require(isTokenReleased);

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
    require(isTokenReleased);
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);

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
    require(!blacklist[_owner]);
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);

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
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);

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
    require(!blacklist[_spender]);    
	require(!blacklist[msg.sender]);

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
 * @title TrustVerse Token
 * @dev Burnable ERC20 standard Token
 */
contract TrustVerseToken is BurnableToken, StandardToken {
  string public constant name = "TrustVerse"; // solium-disable-line uppercase
  string public constant symbol = "TVS"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase
  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
  
  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }
}