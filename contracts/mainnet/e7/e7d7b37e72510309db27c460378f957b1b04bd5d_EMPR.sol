pragma solidity ^0.4.19;




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Owned {
	address private Owner;
	
	function Owned() public{
	    
	    Owner = msg.sender;
	}
    
	function IsOwner(address addr) view public returns(bool)
	{
	    return Owner == addr;
	}
	
	function TransferOwner(address newOwner) public onlyOwner
	{
	    Owner = newOwner;
	}
	
	function Terminate() public onlyOwner
	{
	    selfdestruct(Owner);
	}
	
	modifier onlyOwner(){
        require(msg.sender == Owner);
        _;
    }
}

contract EMPR is Owned {
    using SafeMath for uint256;
    string public constant name = "empowr";
    string public constant symbol = "EMPR";
    uint256 public constant decimals = 18;  // 18 is the most common number of decimal places
    bool private tradeable;
    uint256 private currentSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address=> uint256)) private allowed;
    mapping(address => bool) private lockedAccounts;  
	
	/*
		Incoming Ether
	*/	
    event ReceivedEth(address indexed _from, uint256 _value);
	//this is the fallback
	function () payable public {
		emit ReceivedEth(msg.sender, msg.value);		
	}
	
	event TransferredEth(address indexed _to, uint256 _value);
	function FoundationTransfer(address _to, uint256 amtEth, uint256 amtToken) public onlyOwner
	{
		require(address(this).balance >= amtEth && balances[this] >= amtToken );
		
		if(amtEth >0)
		{
			_to.transfer(amtEth);
			emit TransferredEth(_to, amtEth);
		}
		
		if(amtToken > 0)
		{
			require(balances[_to] + amtToken > balances[_to]);
			balances[this] -= amtToken;
			balances[_to] += amtToken;
			emit Transfer(this, _to, amtToken);
		}
		
		
	}	
	/*
		End Incoming Ether
	*/
	
	
	
    function EMPR( ) public
    {
        uint256 initialTotalSupply = 500000000;
        balances[this] = initialTotalSupply * (10**decimals);
        
        currentSupply =  initialTotalSupply * (10**decimals);
	    emit Transfer(address(0), this, currentSupply);
        
    }
  
	uint256 constant startTime = 1525132800; // Date.UTC(2018, 4, 1) as seconds
	uint256 constant startAmt = 95000000;
	uint256 _lastDayPaid = 0;
	uint256 _currentMonth = 0;
	uint256 factor = 10000000;
	
    event DayMinted(uint256 day,uint256 val, uint256 now);
    function DailyMint() public {
        uint256 day = (now-startTime)/(60*60*24);
        require(startTime <= now);
        require(day >= _lastDayPaid);
        uint256 month = _lastDayPaid/30;
        if(month > _currentMonth){
            _currentMonth += 1;
            factor = (factor * 99)/100;
        }
        uint256 todaysPayout = (((factor * startAmt )/10000000)/30)* (10**decimals);
        balances[this] +=todaysPayout;
        currentSupply += todaysPayout;
        emit Transfer(address(0), this, todaysPayout);
        emit DayMinted(_lastDayPaid, todaysPayout, now);
        _lastDayPaid+=1;
	
    }
    function lastDayPaid() public view returns(uint256){
        return _lastDayPaid;
    }
    

    
    
	function MintToken(uint256 amt) public onlyOwner {
	    currentSupply += amt;
	    balances[this] += amt;
	    emit Transfer(address(0), this, amt);
	}
	
	function DestroyToken(uint256 amt) public onlyOwner {
	    require ( balances[this] >= amt);
	    currentSupply -= amt;
	    balances[this] -= amt;
	    emit Transfer(this,address(0), amt);
	}
	
	
	
    event SoldToken(address _buyer, uint256 _value, string note);
    function BuyToken(address _buyer, uint256 _value, string note) public onlyOwner
    {
		require(balances[this] >= _value && balances[_buyer] + _value > balances[_buyer]);
		
        emit SoldToken( _buyer,  _value,  note);
        balances[this] -= _value;
        balances[_buyer] += _value;
        emit Transfer(this, _buyer, _value);
    }
    
    function LockAccount(address toLock) public onlyOwner
    {
        lockedAccounts[toLock] = true;
    }
    function UnlockAccount(address toUnlock) public onlyOwner
    {
        delete lockedAccounts[toUnlock];
    }
    
    function SetTradeable(bool t) public onlyOwner
    {
        tradeable = t;
    }
    function IsTradeable() public view returns(bool)
    {
        return tradeable;
    }
    
    
    function totalSupply() constant public returns (uint256)
    {
        return currentSupply;
    }
    function balanceOf(address _owner) constant public returns (uint256 balance)
    {
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public notLocked returns (bool success) {
        require(tradeable);
         if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
             emit Transfer( msg.sender, _to,  _value);
             balances[msg.sender] -= _value;
             balances[_to] += _value;
             return true;
         } else {
             return false;
         }
     }
    function transferFrom(address _from, address _to, uint _value)public notLocked returns (bool success) {
        require(!lockedAccounts[_from] && !lockedAccounts[_to]);
		require(tradeable);
        if (balances[_from] >= _value
            && allowed[_from][msg.sender] >= _value
            && balances[_to] + _value > balances[_to]) {
                
            emit Transfer( _from, _to,  _value);
                
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            return true;
        } else {
            return false;
        }
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
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
   
   modifier notLocked(){
       require (!lockedAccounts[msg.sender]);
       _;
   }
}