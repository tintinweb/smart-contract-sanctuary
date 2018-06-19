pragma solidity ^0.4.18;


/** * @dev Math operations with safety checks that throw on error */
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

  /**  * @dev Integer division of two numbers, truncating the quotient.  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).  */
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
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
  function transfer(address _to, uint256 _value) public returns (bool);

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256);

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
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  
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
    return true;                /*^ 23 ^*/
  }                            
}
contract knf is StandardToken {
  string public name; // solium-disable-line uppercase
  string public symbol; // solium-disable-line uppercase
  uint8 public decimals; // solium-disable-line uppercase
  uint256 DropedThisWeek;
  uint256 lastWeek;
  uint256 decimate;
  uint256 weekly_limit;
  uint256 air_drop;
  mapping(address => uint256) airdroped;
  address control;
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function availableSupply() public view returns (uint256) {
    return balances[owner];
  }
  
  modifier onlyControl() {
    require(msg.sender == control);
    _;
  }
  
  function changeName(string newName) onlyControl public {
    name = newName;
  }
  
  function RecordTransfer(address _from, address _to, uint256 _value) internal {
    Transfer(_from, _to, _value);
	if(airdroped[_from] == 0) airdroped[_from] = 1;
	if(airdroped[_to] == 0) airdroped[_to] = 1;
	if (thisweek() > lastWeek) {
	  lastWeek = thisweek();
	  DropedThisWeek = 0;
	}
  }
  
  /*** */
  function Award(address _to, uint256 _v) public onlyControl {
    require(_to != address(0));
	require(_v <= balances[owner]);
	balances[_to] += _v;
	balances[owner] -= _v;
	RecordTransfer(owner, _to, _v);
  }
  
  /*** @param newOwner  The address to transfer ownership to
    owner tokens go with owner, airdrops always from owner pool */
  function transferOwnership(address newOwner) public onlyControl {
    require(newOwner != address(0));
	OwnershipTransferred(owner, newOwner);
	owner = newOwner;
  } /*** @param newControl  The address to transfer control to.   */
  function transferControl(address newControl) public onlyControl {
    require(newControl != address(0) && newControl != address(this));  
	control =newControl;
 } /*init contract itself as owner of all its tokens, all tokens set&#39;&#39;&#39;&#39;&#39;to air drop, and always comes form owner&#39;s bucket 
   .+------+     +------+     +------+     +------+     +------+.     =================== ===================
 .&#39; |    .&#39;|    /|     /|     |      |     |\     |\    |`.    | `.   */function knf(uint256 _initialAmount,/*
+---+--+&#39;  |   +-+----+ |     +------+     | +----+-+   |  `+--+---+  */string _tokenName, uint8 _decimalUnits,/*
|   |  |   |   | |  K | |     |  N   |     | | F  | |   |   |  |   |  */string _tokenSymbol) public { control = msg.sender; /*
|  ,+--+---+   | +----+-+     +------+     +-+----+ |   +---+--+   |  */owner = address(this);OwnershipTransferred(address(0), owner);/*
|.&#39;    | .&#39;    |/     |/      |      |      \|     \|    `. |   `. |  */totalSupply_ = _initialAmount; balances[owner] = totalSupply_; /*
+------+&#39;      +------+       +------+       +------+      `+------+  */RecordTransfer(0x0, owner, totalSupply_);
    symbol = _tokenSymbol;   
	name = _tokenName;
    decimals = _decimalUnits;                            
	decimate = (10 ** uint256(decimals));
	weekly_limit = 100000 * decimate;
	air_drop = 1018 * decimate;	
  } /** rescue lost erc20 kin **/
  function transfererc20(address tokenAddress, address _to, uint256 _value) external onlyControl returns (bool) {
    require(_to != address(0));
	return ERC20(tokenAddress).transfer(_to, _value);
  } /** token no more **/
  function destroy() onlyControl external {
    require(owner != address(this)); selfdestruct(control);
  }  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
	require(_value <= allowed[_from][msg.sender]);
	if(balances[_from] == 0) { 
      uint256 qty = availableAirdrop(_from);
	  if(qty > 0) {  // qty is validated qty against balances in airdrop
	    balances[owner] -= qty;
	    balances[_to] += qty;
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		RecordTransfer(owner, _from, _value);
		RecordTransfer(_from, _to, _value);
		DropedThisWeek += qty;
		return true;
	  }	
	  revert(); // no go
	}
  
    require(_value <= balances[_from]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    RecordTransfer(_from, _to, _value);
	return true;
  }  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
	// if no balance, see if eligible for airdrop instead
    if(balances[msg.sender] == 0) { 
      uint256 qty = availableAirdrop(msg.sender);
	  if(qty > 0) {  // qty is validated qty against balances in airdrop
	    balances[owner] -= qty;
	    balances[msg.sender] += qty;
		RecordTransfer(owner, _to, _value);
		airdroped[msg.sender] = 1;
		DropedThisWeek += qty;
		return true;
	  }	
	  revert(); // no go
	}
  
    // existing balance
    if(balances[msg.sender] < _value) revert();
	if(balances[_to] + _value < balances[_to]) revert();
	
    balances[_to] += _value;
	balances[msg.sender] -= _value;
    RecordTransfer(msg.sender, _to, _value);
	return true;
  }  
  function balanceOf(address who) public view returns (uint256 balance) {
    balance = balances[who];
	if(balance == 0) 
	  return availableAirdrop(who);
	
    return balance;
  }  
  /*  * check the faucet  */  
  function availableAirdrop(address who) internal constant returns (uint256) {
    if(balances[owner] == 0) return 0;
	if(airdroped[who] > 0) return 0; // already seen this
	
    if (thisweek() > lastWeek || DropedThisWeek < weekly_limit) {
	  if(balances[owner] > air_drop) return air_drop;
	  else return balances[owner];
	}
	return 0;
  } 
  function thisweek() internal view returns (uint256) {
    return now / 1 weeks;
  }  
  function transferBalance(address upContract) external onlyControl {
    require(upContract != address(0) && upContract.send(this.balance));
  }
  function () payable public { }   
}