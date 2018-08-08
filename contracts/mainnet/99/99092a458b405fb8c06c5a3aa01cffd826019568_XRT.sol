pragma solidity ^0.4.21;
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256 _user){}
  function transfer(address to, uint256 value) public returns (bool success){}
  function allowance(address owner, address spender) public view returns (uint256 value){}
  function transferFrom(address from, address to, uint256 value) public returns (bool success){}
  function approve(address spender, uint256 value) public returns (bool success){}

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
}

contract OnlyOwner {
  address public owner;
  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function OnlyOwner() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier isOwner {
    require(msg.sender == owner);
    _;
  }

}

contract StandardToken is ERC20{
	using SafeMath for uint256;

  	mapping(address => uint256) balances;
  	mapping (address => mapping (address => uint256)) allowed;

  	event Minted(address receiver, uint256 amount);
  	
  	

  	

  	function _transfer(address _from, address _to, uint256 _value) internal view returns (bool success){
  		//prevent sending of tokens from genesis address or to self
	    require(_from != address(0) && _from != _to);
	    require(_to != address(0));
	    //subtract tokens from the sender on transfer
	    balances[_from] = balances[_from].safeSub(_value);
	    //add tokens to the receiver on reception
	    balances[_to] = balances[_to].safeAdd(_value);
	    return true;
  	}

	function transfer(address _to, uint256 _value) onlyPayloadSize(2*32) returns (bool success) 
	{ 
		require(_value <= balances[msg.sender]);
	    _transfer(msg.sender,_to,_value);
	    Transfer(msg.sender, _to, _value);
	    return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    	uint256 _allowance = allowed[_from][msg.sender];
    	//value must be less than allowed value
    	require(_value <= _allowance);
    	//balance of sender + token value transferred by sender must be greater than balance of sender
    	require(balances[_to] + _value > balances[_to]);
    	//call transfer function
    	_transfer(_from,_to,_value);
    	//subtract the amount allowed to the sender 
     	allowed[_from][msg.sender] = _allowance.safeSub(_value);
     	//trigger Transfer event
    	Transfer(_from, _to, _value);
    	return true;
  	}

  	function balanceOf(address _owner) public constant returns (uint balance) {
    	return balances[_owner];
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
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].safeAdd(_addedValue);
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
  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.safeSub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	} 

}

contract XRT is StandardToken, OnlyOwner{
	uint8 public constant decimals = 18;
    uint256 private constant multiplier = billion*10**18;
  	string public constant name = "XRT Token";
  	string public constant symbol = "XRT";
  	string public version = "X1.0";
  	uint256 private billion = 10*10**8;
  	uint256 private maxSupply = multiplier;
    uint256 public totalSupply = (50*maxSupply)/100;
  	
  	function XRT() public{
  	    balances[msg.sender] = totalSupply;
  	}
  	
  	function maximumToken() isOwner returns (uint){
  	    return maxSupply;
  	}
  	
  	event Mint(address indexed to, uint256 amount);
  	event MintFinished();
    
 	bool public mintingFinished = false;


	modifier canMint() {
		require(!mintingFinished);
		require(totalSupply <= maxSupply);
		_;
	}

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
	function mint(address _to, uint256 _amount) isOwner canMint public returns (bool) {
	    uint256 newAmount = _amount.safeMul(multiplier.safeDiv(100));
	    require(totalSupply <= maxSupply.safeSub(newAmount));
	    totalSupply = totalSupply.safeAdd(newAmount);
		balances[_to] = balances[_to].safeAdd(newAmount);
		Mint(_to, newAmount);
		Transfer(address(0), _to, newAmount);
		return true;
	}

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  	function finishMinting() isOwner canMint public returns (bool) {
    	mintingFinished = true;
    	MintFinished();
    	return true;
  	}
}