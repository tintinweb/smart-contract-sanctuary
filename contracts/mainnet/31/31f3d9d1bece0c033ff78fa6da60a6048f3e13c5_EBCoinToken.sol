pragma solidity ^0.4.18;

/* -------------------------------------------------------------------------------- */

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

/* -------------------------------------------------------------------------------- */

/**
 * @title Ownable
 */
contract Ownable 
{
  address public owner;

  event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);
	
	function Ownable() public
  {
    owner = msg.sender;
  }

  modifier onlyOwner() 
  {
    require(msg.sender == owner);
    _;
  }

  function changeOwner(address _newOwner) onlyOwner public 
  {
    require(_newOwner != address(0));
    
    address oldOwner = owner;
    if (oldOwner != _newOwner)
    {
    	owner = _newOwner;
    	
    	OwnerChanged(oldOwner, _newOwner);
    }
  }

}

/* -------------------------------------------------------------------------------- */

/**
 * @title Manageable
 */
contract Manageable is Ownable
{
	address public manager;
	
	event ManagerChanged(address indexed _oldManager, address _newManager);
	
	function Manageable() public
	{
		manager = msg.sender;
	}
	
	modifier onlyManager()
	{
		require(msg.sender == manager);
		_;
	}
	
	modifier onlyOwnerOrManager() 
	{
		require(msg.sender == owner || msg.sender == manager);
		_;
	}
	
	function changeManager(address _newManager) onlyOwner public 
	{
		require(_newManager != address(0));
		
		address oldManager = manager;
		if (oldManager != _newManager)
		{
			manager = _newManager;
			
			ManagerChanged(oldManager, _newManager);
		}
	}
	
}

/* -------------------------------------------------------------------------------- */

/**
 * @title EBCoinToken
 */
contract EBCoinToken is Manageable
{
  using SafeMath for uint256;

  string public constant name     = "EBCoin";
  string public constant symbol   = "EBC";
  uint8  public constant decimals = 18;
  
  uint256 public totalSupply;
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping (address => uint256) public releaseTime;
  bool public released;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Mint(address indexed _to, uint256 _value);
  event Burn(address indexed _from, uint256 _value);
  event ReleaseTimeChanged(address indexed _owner, uint256 _oldReleaseTime, uint256 _newReleaseTime);
  event ReleasedChanged(bool _oldReleased, bool _newReleased);

  modifier canTransfer(address _from)
  {
  	if (releaseTime[_from] == 0)
  	{
  		require(released);
  	}
  	else
  	{
  		require(releaseTime[_from] <= now);
  	}
  	_;
  }

  function balanceOf(address _owner) public constant returns (uint256)
  {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) canTransfer(msg.sender) public returns (bool) 
  {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    
    Transfer(msg.sender, _to, _value);
    
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256) 
  {
    return allowed[_owner][_spender];
  }
  
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from) public returns (bool) 
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    
    Transfer(_from, _to, _value);
    
    return true;
  }
  
 	function approve(address _spender, uint256 _value) public returns (bool) 
 	{
    allowed[msg.sender][_spender] = _value;
    
    Approval(msg.sender, _spender, _value);
    
    return true;
  }

  function mint(address _to, uint256 _value, uint256 _releaseTime) onlyOwnerOrManager public returns (bool) 
  {
  	require(_to != address(0));
  	
    totalSupply = totalSupply.add(_value);
    balances[_to] = balances[_to].add(_value);
    
    Mint(_to, _value);
    Transfer(0x0, _to, _value);
    
    setReleaseTime(_to, _releaseTime);
    
    return true;
  }
  
  function burn(address _from, uint256 _value) onlyOwnerOrManager public returns (bool)
  {
    require(_from != address(0));
    require(_value <= balances[_from]);
    
    balances[_from] = balances[_from].sub(_value);
    totalSupply = totalSupply.sub(_value);
    
    Burn(_from, _value);
    
  	return true;
  }

  function setReleaseTime(address _owner, uint256 _newReleaseTime) onlyOwnerOrManager public returns (bool)
  {
    require(_owner != address(0));
    
  	uint256 oldReleaseTime = releaseTime[_owner];
  	if (oldReleaseTime != _newReleaseTime)
  	{
  		releaseTime[_owner] = _newReleaseTime;
    
    	ReleaseTimeChanged(_owner, oldReleaseTime, _newReleaseTime);
    	
    	return true;
    }
    
    return false;
  }
  
  function setReleased(bool _newReleased) onlyOwnerOrManager public returns (bool)
  {
  	bool oldReleased = released;
  	if (oldReleased != _newReleased)
  	{
  		released = _newReleased;
  	
  		ReleasedChanged(oldReleased, _newReleased);
  		
  		return true;
  	}
  	
  	return false;
  }
  
}

/* -------------------------------------------------------------------------------- */