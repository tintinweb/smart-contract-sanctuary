//v1.0.14
//License: Apache2.0
pragma solidity ^0.4.8;

contract TokenSpender {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

pragma solidity ^0.4.8;

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity ^0.4.8;

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * last open zepplin version used for : add sub mul div function : https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
* commit : https://github.com/OpenZeppelin/zeppelin-solidity/commit/815d9e1f457f57cfbb1b4e889f2255c9a517f661
 */
library SafeMathOZ
{
	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		assert(b <= a);
		return a - b;
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		if (a == 0)
		{
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function max(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return a >= b ? a : b;
	}

	function min(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return a < b ? a : b;
	}

	function mulByFraction(uint256 a, uint256 b, uint256 c) internal pure returns (uint256)
	{
		return div(mul(a, b), c);
	}

	function percentage(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return mulByFraction(a, b, 100);
	}
	// Source : https://ethereum.stackexchange.com/questions/8086/logarithm-math-operation-in-solidity
	function log(uint x) internal pure returns (uint y)
	{
		assembly
		{
			let arg := x
			x := sub(x,1)
			x := or(x, div(x, 0x02))
			x := or(x, div(x, 0x04))
			x := or(x, div(x, 0x10))
			x := or(x, div(x, 0x100))
			x := or(x, div(x, 0x10000))
			x := or(x, div(x, 0x100000000))
			x := or(x, div(x, 0x10000000000000000))
			x := or(x, div(x, 0x100000000000000000000000000000000))
			x := add(x, 1)
			let m := mload(0x40)
			mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
			mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
			mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
			mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
			mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
			mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
			mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
			mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
			mstore(0x40, add(m, 0x100))
			let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
			let shift := 0x100000000000000000000000000000000000000000000000000000000000000
			let a := div(mul(x, magic), shift)
			y := div(mload(add(m,sub(255,a))), shift)
			y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
		}
	}
}


pragma solidity ^0.4.8;

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}

pragma solidity ^0.4.21;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract OwnableOZ
{
	address public m_owner;
	bool    public m_changeable;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner()
	{
		require(msg.sender == m_owner);
		_;
	}

	/**
	 * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	function OwnableOZ() public
	{
		m_owner      = msg.sender;
		m_changeable = true;
	}

	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
	 * @param _newOwner The address to transfer ownership to.
	 */
	function setImmutableOwnership(address _newOwner) public onlyOwner
	{
		require(m_changeable);
		require(_newOwner != address(0));
		emit OwnershipTransferred(m_owner, _newOwner);
		m_owner      = _newOwner;
		m_changeable = false;
	}

}


pragma solidity ^0.4.8;

contract RLC is ERC20, SafeMath, Ownable {

    /* Public variables of the token */
  string public name;       //fancy name
  string public symbol;
  uint8 public decimals;    //How many decimals to show.
  string public version = &#39;v0.1&#39;;
  uint public initialSupply;
  uint public totalSupply;
  bool public locked;
  //uint public unlockBlock;

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  // lock transfer during the ICO
  modifier onlyUnlocked() {
    if (msg.sender != owner && locked) throw;
    _;
  }

  /*
   *  The RLC Token created with the time at which the crowdsale end
   */

  function RLC() {
    // lock the transfer function during the crowdsale
    locked = true;
    //unlockBlock=  now + 45 days; // (testnet) - for mainnet put the block number

    initialSupply = 87000000000000000;
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply;// Give the creator all initial tokens
    name = &#39;iEx.ec Network Token&#39;;        // Set the name for display purposes
    symbol = &#39;RLC&#39;;                       // Set the symbol for display purposes
    decimals = 9;                        // Amount of decimals for display purposes
  }

  function unlock() onlyOwner {
    locked = false;
  }

  function burn(uint256 _value) returns (bool){
    balances[msg.sender] = safeSub(balances[msg.sender], _value) ;
    totalSupply = safeSub(totalSupply, _value);
    Transfer(msg.sender, 0x0, _value);
    return true;
  }

  function transfer(address _to, uint _value) onlyUnlocked returns (bool) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) onlyUnlocked returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

    /* Approve and then comunicate the approved contract in a single tx */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData){
      TokenSpender spender = TokenSpender(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, this, _extraData);
      }
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


pragma solidity ^0.4.21;


contract IexecHubInterface
{
	RLC public rlc;

	function attachContracts(
		address _tokenAddress,
		address _marketplaceAddress,
		address _workerPoolHubAddress,
		address _appHubAddress,
		address _datasetHubAddress)
		public;

	function setCategoriesCreator(
		address _categoriesCreator)
	public;

	function createCategory(
		string  _name,
		string  _description,
		uint256 _workClockTimeRef)
	public returns (uint256 catid);

	function createWorkerPool(
		string  _description,
		uint256 _subscriptionLockStakePolicy,
		uint256 _subscriptionMinimumStakePolicy,
		uint256 _subscriptionMinimumScorePolicy)
	external returns (address createdWorkerPool);

	function createApp(
		string  _appName,
		uint256 _appPrice,
		string  _appParams)
	external returns (address createdApp);

	function createDataset(
		string  _datasetName,
		uint256 _datasetPrice,
		string  _datasetParams)
	external returns (address createdDataset);

	function buyForWorkOrder(
		uint256 _marketorderIdx,
		address _workerpool,
		address _app,
		address _dataset,
		string  _params,
		address _callback,
		address _beneficiary)
	external returns (address);

	function isWoidRegistred(
		address _woid)
	public view returns (bool);

	function lockWorkOrderCost(
		address _requester,
		address _workerpool, // Address of a smartcontract
		address _app,        // Address of a smartcontract
		address _dataset)    // Address of a smartcontract
	internal returns (uint256);

	function claimFailedConsensus(
		address _woid)
	public returns (bool);

	function finalizeWorkOrder(
		address _woid,
		string  _stdout,
		string  _stderr,
		string  _uri)
	public returns (bool);

	function getCategoryWorkClockTimeRef(
		uint256 _catId)
	public view returns (uint256 workClockTimeRef);

	function existingCategory(
		uint256 _catId)
	public view  returns (bool categoryExist);

	function getCategory(
		uint256 _catId)
		public view returns (uint256 catid, string name, string  description, uint256 workClockTimeRef);

	function getWorkerStatus(
		address _worker)
	public view returns (address workerPool, uint256 workerScore);

	function getWorkerScore(address _worker) public view returns (uint256 workerScore);

	function registerToPool(address _worker) public returns (bool subscribed);

	function unregisterFromPool(address _worker) public returns (bool unsubscribed);

	function evictWorker(address _worker) public returns (bool unsubscribed);

	function removeWorker(address _workerpool, address _worker) internal returns (bool unsubscribed);

	function lockForOrder(address _user, uint256 _amount) public returns (bool);

	function unlockForOrder(address _user, uint256 _amount) public returns (bool);

	function lockForWork(address _woid, address _user, uint256 _amount) public returns (bool);

	function unlockForWork(address _woid, address _user, uint256 _amount) public returns (bool);

	function rewardForWork(address _woid, address _worker, uint256 _amount, bool _reputation) public returns (bool);

	function seizeForWork(address _woid, address _worker, uint256 _amount, bool _reputation) public returns (bool);

	function deposit(uint256 _amount) external returns (bool);

	function withdraw(uint256 _amount) external returns (bool);

	function checkBalance(address _owner) public view returns (uint256 stake, uint256 locked);

	function reward(address _user, uint256 _amount) internal returns (bool);

	function seize(address _user, uint256 _amount) internal returns (bool);

	function lock(address _user, uint256 _amount) internal returns (bool);

	function unlock(address _user, uint256 _amount) internal returns (bool);
}


pragma solidity ^0.4.21;


contract IexecHubAccessor
{
	IexecHubInterface internal iexecHubInterface;

	modifier onlyIexecHub()
	{
		require(msg.sender == address(iexecHubInterface));
		_;
	}

	function IexecHubAccessor(address _iexecHubAddress) public
	{
		require(_iexecHubAddress != address(0));
		iexecHubInterface = IexecHubInterface(_iexecHubAddress);
	}

}


pragma solidity ^0.4.21;


contract App is OwnableOZ, IexecHubAccessor
{

	/**
	 * Members
	 */
	string        public m_appName;
	uint256       public m_appPrice;
	string        public m_appParams;

	/**
	 * Constructor
	 */
	function App(
		address _iexecHubAddress,
		string  _appName,
		uint256 _appPrice,
		string  _appParams)
	IexecHubAccessor(_iexecHubAddress)
	public
	{
		// tx.origin == owner
		// msg.sender == DatasetHub
		require(tx.origin != msg.sender);
		setImmutableOwnership(tx.origin); // owner → tx.origin

		m_appName   = _appName;
		m_appPrice  = _appPrice;
		m_appParams = _appParams;

	}



}


pragma solidity ^0.4.21;



contract AppHub is OwnableOZ // is Owned by IexecHub
{

	using SafeMathOZ for uint256;

	/**
	 * Members
	 */
	mapping(address => uint256)                     m_appCountByOwner;
	mapping(address => mapping(uint256 => address)) m_appByOwnerByIndex;
	mapping(address => bool)                        m_appRegistered;

	mapping(uint256 => address)                     m_appByIndex;
	uint256 public                                  m_totalAppCount;

	/**
	 * Constructor
	 */
	function AppHub() public
	{
	}

	/**
	 * Methods
	 */
	function isAppRegistered(address _app) public view returns (bool)
	{
		return m_appRegistered[_app];
	}
	function getAppsCount(address _owner) public view returns (uint256)
	{
		return m_appCountByOwner[_owner];
	}
	function getApp(address _owner, uint256 _index) public view returns (address)
	{
		return m_appByOwnerByIndex[_owner][_index];
	}
	function getAppByIndex(uint256 _index) public view returns (address)
	{
		return m_appByIndex[_index];
	}

	function addApp(address _owner, address _app) internal
	{
		uint id = m_appCountByOwner[_owner].add(1);
		m_totalAppCount=m_totalAppCount.add(1);
		m_appByIndex       [m_totalAppCount] = _app;
		m_appCountByOwner  [_owner]          = id;
		m_appByOwnerByIndex[_owner][id]      = _app;
		m_appRegistered    [_app]            = true;
	}

	function createApp(
		string  _appName,
		uint256 _appPrice,
		string  _appParams)
	public onlyOwner /*owner == IexecHub*/ returns (address createdApp)
	{
		// tx.origin == owner
		// msg.sender == IexecHub
		address newApp = new App(
			msg.sender,
			_appName,
			_appPrice,
			_appParams
		);
		addApp(tx.origin, newApp);
		return newApp;
	}

}