pragma solidity ^0.4.13;


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

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


contract QKL is ERC20,Pausable{
	using SafeMath for uint256;

	string public constant name="QKL";
	string public symbol="QKL";
	string public constant version = "1.0";
	uint256 public constant decimals = 18;
	uint256 public totalSupply;

	uint256 public constant INIT_SUPPLY=10000000000*10**decimals;

	//锁仓期数
    struct epoch  {
        uint256 lockEndTime;
        uint256 lockAmount;
    }

    mapping(address=>epoch[]) public lockEpochsMap;

	
    mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	event GetETH(address indexed _from, uint256 _value);
	event Burn(address indexed burner, uint256 value);

	//owner一次性获取代币
	function QKL(){
		totalSupply=INIT_SUPPLY;
		balances[msg.sender] = INIT_SUPPLY;
		Transfer(0x0, msg.sender, INIT_SUPPLY);
	}
    /**
    *销毁代币,用户只能自己销毁自己的
     */
    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

  	//锁仓接口，可分多期锁仓，多期锁仓金额可累加，这里的锁仓是指限制转账
	function lockBalance(address user, uint256 lockAmount,uint256 lockEndTime) external
		onlyOwner
	{
		 epoch[] storage epochs = lockEpochsMap[user];
		 epochs.push(epoch(lockEndTime,lockAmount));
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

  	function transfer(address _to, uint256 _value) whenNotPaused  public  returns (bool)
 	{
		require(_to != address(0));

		//计算锁仓份额
		epoch[] epochs = lockEpochsMap[msg.sender];
		uint256 needLockBalance = 0;
		for(uint256 i = 0;i<epochs.length;i++)
		{
			//如果当前时间小于当期结束时间,则此期有效
			if( now < epochs[i].lockEndTime )
			{
				needLockBalance=needLockBalance.add(epochs[i].lockAmount);
			}
		}

		require(balances[msg.sender].sub(_value)>=needLockBalance);

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

  	function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool) 
  	{
		require(_to != address(0));

		//计算锁仓份额
		epoch[] epochs = lockEpochsMap[_from];
		uint256 needLockBalance = 0;
		for(uint256 i = 0;i<epochs.length;i++)
		{
			//如果当前时间小于当期结束时间,则此期有效
			if( now < epochs[i].lockEndTime )
			{
				needLockBalance = needLockBalance.add(epochs[i].lockAmount);
			}
		}

		require(balances[_from].sub(_value)>=needLockBalance);

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