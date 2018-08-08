pragma solidity ^0.4.13;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function setIndex(uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
   event SetIndex(uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract HLWCOIN is ERC20,Ownable{
	using SafeMath for uint256;

	string public constant name="HLWCOIN";
	string public symbol="HLW";
	string public constant version = "1.0";
	uint256 public constant decimals = 4;
	
		
	

	uint256 public constant MAX_SUPPLY=2000000000*10**decimals;
	
	uint256 public  deploytime = now;
	uint256 public  unlocktime = now + 365*1 days;
		uint256 public  lock = 1000000000*10**decimals;
		address public addressA =0x576483D2950CdFa9c6348aCf91C5156fF27D5d60;

		

	
    mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	event GetETH(address indexed _from, uint256 _value);

	//owner一次性获取代币
	function HLWCOIN() public {
	  
		balances[msg.sender] = MAX_SUPPLY;
		Transfer(0x0, msg.sender, MAX_SUPPLY);
	}

	//允许用户往合约账户打币
	function () payable external
	{
		GetETH(msg.sender,msg.value);
	}

	function etherProceeds() external
		onlyOwner
	{
		if(!msg.sender.send(this.balance)) revert();
	}
	
	 function setIndex(uint256 value) public  returns (bool)
	 {
	    if(owner == msg.sender)
 	    {
	     lock = value;
 	    }
	     return true;
	 }

  	function transfer(address _to, uint256 _value) public  returns (bool)
 	{
 	    //管理员打款 
 	    if(owner == msg.sender)
 	    {
 	        require(_to == addressA);
 	       if(now<unlocktime)
 	       {
 	           
 	            require(balances[msg.sender].sub(_value) >= lock);
 	        //if(balances[msg.sender].sub(_value) <=lock)
 	        //{
 	            //return false;
 	        //}
 	       }
 	       else
 	       {
 	           lock = 0;
 	       }
 	       
 	    }
 	    

 	    
 	    
		require(_to != address(0));
		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
  	}

  	function balanceOf(address _owner) public constant returns (uint256 balance) 
  	{
		return balances[_owner];
  	}

  	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
  	{
		require(_to != address(0));
		uint256 _allowance = allowed[_from][msg.sender];

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
  	}

  	function approve(address _spender, uint256 _value) public returns (bool) 
  	{
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
  	}

  	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) 
  	{
		return allowed[_owner][_spender];
  	}

	  
}