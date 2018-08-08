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

library IexecLib
{
	/***************************************************************************/
	/*                              Market Order                               */
	/***************************************************************************/
	enum MarketOrderDirectionEnum
	{
		UNSET,
		BID,
		ASK,
		CLOSED
	}
	struct MarketOrder
	{
		MarketOrderDirectionEnum direction;
		uint256 category;        // runtime selection
		uint256 trust;           // for PoCo
		uint256 value;           // value/cost/price
		uint256 volume;          // quantity of instances (total)
		uint256 remaining;       // remaining instances
		address workerpool;      // BID can use null for any
		address workerpoolOwner; // fix ownership if workerpool ownership change during the workorder steps
	}

	/***************************************************************************/
	/*                               Work Order                                */
	/***************************************************************************/
	enum WorkOrderStatusEnum
	{
		UNSET,     // Work order not yet initialized (invalid address)
		ACTIVE,    // Marketed → constributions are open
		REVEALING, // Starting consensus reveal
		CLAIMED,   // failed consensus
		COMPLETED  // Concensus achieved
	}

	/***************************************************************************/
	/*                                Consensus                                */
	/*                                   ---                                   */
	/*                         used in WorkerPool.sol                          */
	/***************************************************************************/
	struct Consensus
	{
		uint256 poolReward;
		uint256 stakeAmount;
		bytes32 consensus;
		uint256 revealDate;
		uint256 revealCounter;
		uint256 consensusTimeout;
		uint256 winnerCount;
		address[] contributors;
		address workerpoolOwner;
		uint256 schedulerRewardRatioPolicy;

	}

	/***************************************************************************/
	/*                              Contribution                               */
	/*                                   ---                                   */
	/*                         used in WorkerPool.sol                          */
	/***************************************************************************/
	enum ContributionStatusEnum
	{
		UNSET,
		AUTHORIZED,
		CONTRIBUTED,
		PROVED,
		REJECTED
	}
	struct Contribution
	{
		ContributionStatusEnum status;
		bytes32 resultHash;
		bytes32 resultSign;
		address enclaveChallenge;
		uint256 score;
		uint256 weight;
	}

	/***************************************************************************/
	/*                Account / ContributionHistory / Category                 */
	/*                                   ---                                   */
	/*                          used in IexecHub.sol                           */
	/***************************************************************************/
	struct Account
	{
		uint256 stake;
		uint256 locked;
	}

	struct ContributionHistory // for credibility computation, f = failed/total
	{
		uint256 success;
		uint256 failed;
	}

	struct Category
	{
		uint256 catid;
		string  name;
		string  description;
		uint256 workClockTimeRef;
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
contract MarketplaceInterface
{
	function createMarketOrder(
		IexecLib.MarketOrderDirectionEnum _direction,
		uint256 _category,
		uint256 _trust,
		uint256 _value,
		address _workerpool,
		uint256 _volume)
	public returns (uint);

	function closeMarketOrder(
		uint256 _marketorderIdx)
	public returns (bool);

	function getMarketOrderValue(
		uint256 _marketorderIdx)
	public view returns(uint256);

	function getMarketOrderWorkerpoolOwner(
		uint256 _marketorderIdx)
	public view returns(address);

	function getMarketOrderCategory(
		uint256 _marketorderIdx)
	public view returns (uint256);

	function getMarketOrderTrust(
		uint256 _marketorderIdx)
	public view returns(uint256);

	function getMarketOrder(
		uint256 _marketorderIdx)
	public view returns(
		IexecLib.MarketOrderDirectionEnum direction,
		uint256 category,       // runtime selection
		uint256 trust,          // for PoCo
		uint256 value,          // value/cost/price
		uint256 volume,         // quantity of instances (total)
		uint256 remaining,      // remaining instances
		address workerpool);    // BID can use null for any
}




pragma solidity ^0.4.21;


contract MarketplaceAccessor
{
	address              internal marketplaceAddress;
	MarketplaceInterface internal marketplaceInterface;
/* not used
	modifier onlyMarketplace()
	{
		require(msg.sender == marketplaceAddress);
		_;
	}*/

	function MarketplaceAccessor(address _marketplaceAddress) public
	{
		require(_marketplaceAddress != address(0));
		marketplaceAddress   = _marketplaceAddress;
		marketplaceInterface = MarketplaceInterface(_marketplaceAddress);
	}
}


pragma solidity ^0.4.21;

contract WorkOrder
{


	event WorkOrderActivated();
	event WorkOrderReActivated();
	event WorkOrderRevealing();
	event WorkOrderClaimed  ();
	event WorkOrderCompleted();

	/**
	 * Members
	 */
	IexecLib.WorkOrderStatusEnum public m_status;

	uint256 public m_marketorderIdx;

	address public m_app;
	address public m_dataset;
	address public m_workerpool;
	address public m_requester;

	uint256 public m_emitcost;
	string  public m_params;
	address public m_callback;
	address public m_beneficiary;

	bytes32 public m_resultCallbackProof;
	string  public m_stdout;
	string  public m_stderr;
	string  public m_uri;

	address public m_iexecHubAddress;

	modifier onlyIexecHub()
	{
		require(msg.sender == m_iexecHubAddress);
		_;
	}

	/**
	 * Constructor
	 */
	function WorkOrder(
		uint256 _marketorderIdx,
		address _requester,
		address _app,
		address _dataset,
		address _workerpool,
		uint256 _emitcost,
		string  _params,
		address _callback,
		address _beneficiary)
	public
	{
		m_iexecHubAddress = msg.sender;
		require(_requester != address(0));
		m_status         = IexecLib.WorkOrderStatusEnum.ACTIVE;
		m_marketorderIdx = _marketorderIdx;
		m_app            = _app;
		m_dataset        = _dataset;
		m_workerpool     = _workerpool;
		m_requester      = _requester;
		m_emitcost       = _emitcost;
		m_params         = _params;
		m_callback       = _callback;
		m_beneficiary    = _beneficiary;
		// needed for the scheduler to authorize api token access on this m_beneficiary address in case _requester is a smart contract.
	}

	function startRevealingPhase() public returns (bool)
	{
		require(m_workerpool == msg.sender);
		require(m_status == IexecLib.WorkOrderStatusEnum.ACTIVE);
		m_status = IexecLib.WorkOrderStatusEnum.REVEALING;
		emit WorkOrderRevealing();
		return true;
	}

	function reActivate() public returns (bool)
	{
		require(m_workerpool == msg.sender);
		require(m_status == IexecLib.WorkOrderStatusEnum.REVEALING);
		m_status = IexecLib.WorkOrderStatusEnum.ACTIVE;
		emit WorkOrderReActivated();
		return true;
	}


	function claim() public onlyIexecHub
	{
		require(m_status == IexecLib.WorkOrderStatusEnum.ACTIVE || m_status == IexecLib.WorkOrderStatusEnum.REVEALING);
		m_status = IexecLib.WorkOrderStatusEnum.CLAIMED;
		emit WorkOrderClaimed();
	}


	function setResult(string _stdout, string _stderr, string _uri) public onlyIexecHub
	{
		require(m_status == IexecLib.WorkOrderStatusEnum.REVEALING);
		m_status = IexecLib.WorkOrderStatusEnum.COMPLETED;
		m_stdout = _stdout;
		m_stderr = _stderr;
		m_uri    = _uri;
		m_resultCallbackProof =keccak256(_stdout,_stderr,_uri);
		emit WorkOrderCompleted();
	}

}

pragma solidity ^0.4.21;

contract IexecCallbackInterface
{

	function workOrderCallback(
		address _woid,
		string  _stdout,
		string  _stderr,
		string  _uri) public returns (bool);

	event WorkOrderCallback(address woid, string stdout, string stderr, string uri);
}


pragma solidity ^0.4.21;

contract Marketplace is IexecHubAccessor
{
	using SafeMathOZ for uint256;

	/**
	 * Marketplace
	 */
	uint                                 public m_orderCount;
	mapping(uint =>IexecLib.MarketOrder) public m_orderBook;

	uint256 public constant ASK_STAKE_RATIO  = 30;

	/**
	 * Events
	 */
	event MarketOrderCreated   (uint marketorderIdx);
	event MarketOrderClosed    (uint marketorderIdx);
	event MarketOrderAskConsume(uint marketorderIdx, address requester);

	/**
	 * Constructor
	 */
	function Marketplace(address _iexecHubAddress)
	IexecHubAccessor(_iexecHubAddress)
	public
	{
	}

	/**
	 * Market orders
	 */
	function createMarketOrder(
		IexecLib.MarketOrderDirectionEnum _direction,
		uint256 _category,
		uint256 _trust,
		uint256 _value,
		address _workerpool,
		uint256 _volume)
	public returns (uint)
	{
		require(iexecHubInterface.existingCategory(_category));
		require(_volume >0);
		m_orderCount = m_orderCount.add(1);
		IexecLib.MarketOrder storage marketorder    = m_orderBook[m_orderCount];
		marketorder.direction      = _direction;
		marketorder.category       = _category;
		marketorder.trust          = _trust;
		marketorder.value          = _value;
		marketorder.volume         = _volume;
		marketorder.remaining      = _volume;

		if (_direction == IexecLib.MarketOrderDirectionEnum.ASK)
		{
			require(WorkerPool(_workerpool).m_owner() == msg.sender);

			require(iexecHubInterface.lockForOrder(msg.sender, _value.percentage(ASK_STAKE_RATIO).mul(_volume))); // mul must be done after percentage to avoid rounding errors
			marketorder.workerpool      = _workerpool;
			marketorder.workerpoolOwner = msg.sender;
		}
		else
		{
			// no BID implementation
			revert();
		}
		emit MarketOrderCreated(m_orderCount);
		return m_orderCount;
	}

	function closeMarketOrder(uint256 _marketorderIdx) public returns (bool)
	{
		IexecLib.MarketOrder storage marketorder = m_orderBook[_marketorderIdx];
		if (marketorder.direction == IexecLib.MarketOrderDirectionEnum.ASK)
		{
			require(marketorder.workerpoolOwner == msg.sender);
			require(iexecHubInterface.unlockForOrder(marketorder.workerpoolOwner, marketorder.value.percentage(ASK_STAKE_RATIO).mul(marketorder.remaining))); // mul must be done after percentage to avoid rounding errors
		}
		else
		{
			// no BID implementation
			revert();
		}
		marketorder.direction = IexecLib.MarketOrderDirectionEnum.CLOSED;
		emit MarketOrderClosed(_marketorderIdx);
		return true;
	}


	/**
	 * Assets consumption
	 */
	function consumeMarketOrderAsk(
		uint256 _marketorderIdx,
		address _requester,
		address _workerpool)
	public onlyIexecHub returns (bool)
	{
		IexecLib.MarketOrder storage marketorder = m_orderBook[_marketorderIdx];
		require(marketorder.direction  == IexecLib.MarketOrderDirectionEnum.ASK);
		require(marketorder.remaining  >  0);
		require(marketorder.workerpool == _workerpool);

		marketorder.remaining = marketorder.remaining.sub(1);
		if (marketorder.remaining == 0)
		{
			marketorder.direction = IexecLib.MarketOrderDirectionEnum.CLOSED;
		}
		require(iexecHubInterface.lockForOrder(_requester, marketorder.value));
		emit MarketOrderAskConsume(_marketorderIdx, _requester);
		return true;
	}

	function existingMarketOrder(uint256 _marketorderIdx) public view  returns (bool marketOrderExist)
	{
		return m_orderBook[_marketorderIdx].category > 0;
	}

	/**
	 * Views
	 */
	function getMarketOrderValue(uint256 _marketorderIdx) public view returns (uint256)
	{
		require(existingMarketOrder(_marketorderIdx)); // no silent value returned
		return m_orderBook[_marketorderIdx].value;
	}
	function getMarketOrderWorkerpoolOwner(uint256 _marketorderIdx) public view returns (address)
	{
		require(existingMarketOrder(_marketorderIdx)); // no silent value returned
		return m_orderBook[_marketorderIdx].workerpoolOwner;
	}
	function getMarketOrderCategory(uint256 _marketorderIdx) public view returns (uint256)
	{
		require(existingMarketOrder(_marketorderIdx)); // no silent value returned
		return m_orderBook[_marketorderIdx].category;
	}
	function getMarketOrderTrust(uint256 _marketorderIdx) public view returns (uint256)
	{
		require(existingMarketOrder(_marketorderIdx)); // no silent value returned
		return m_orderBook[_marketorderIdx].trust;
	}
	function getMarketOrder(uint256 _marketorderIdx) public view returns
	(
		IexecLib.MarketOrderDirectionEnum direction,
		uint256 category,       // runtime selection
		uint256 trust,          // for PoCo
		uint256 value,          // value/cost/price
		uint256 volume,         // quantity of instances (total)
		uint256 remaining,      // remaining instances
		address workerpool,     // BID can use null for any
		address workerpoolOwner)
	{
		require(existingMarketOrder(_marketorderIdx)); // no silent value returned
		IexecLib.MarketOrder storage marketorder = m_orderBook[_marketorderIdx];
		return (
			marketorder.direction,
			marketorder.category,
			marketorder.trust,
			marketorder.value,
			marketorder.volume,
			marketorder.remaining,
			marketorder.workerpool,
			marketorder.workerpoolOwner
		);
	}

	/**
	 * Callback Proof managment
	 */

	event WorkOrderCallbackProof(address indexed woid, address requester, address beneficiary,address indexed callbackTo, address indexed gasCallbackProvider,string stdout, string stderr , string uri);

	//mapping(workorder => bool)
	 mapping(address => bool) m_callbackDone;

	 function isCallbackDone(address _woid) public view  returns (bool callbackDone)
	 {
		 return m_callbackDone[_woid];
	 }

	 function workOrderCallback(address _woid,string _stdout, string _stderr, string _uri) public
	 {
		 require(iexecHubInterface.isWoidRegistred(_woid));
		 require(!isCallbackDone(_woid));
		 m_callbackDone[_woid] = true;
		 require(WorkOrder(_woid).m_status() == IexecLib.WorkOrderStatusEnum.COMPLETED);
		 require(WorkOrder(_woid).m_resultCallbackProof() == keccak256(_stdout,_stderr,_uri));
		 address callbackTo =WorkOrder(_woid).m_callback();
		 require(callbackTo != address(0));
		 require(IexecCallbackInterface(callbackTo).workOrderCallback(
			 _woid,
			 _stdout,
			 _stderr,
			 _uri
		 ));
		 emit WorkOrderCallbackProof(_woid,WorkOrder(_woid).m_requester(),WorkOrder(_woid).m_beneficiary(),callbackTo,tx.origin,_stdout,_stderr,_uri);
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


pragma solidity ^0.4.21;

contract Dataset is OwnableOZ, IexecHubAccessor
{

	/**
	 * Members
	 */
	string            public m_datasetName;
	uint256           public m_datasetPrice;
	string            public m_datasetParams;

	/**
	 * Constructor
	 */
	function Dataset(
		address _iexecHubAddress,
		string  _datasetName,
		uint256 _datasetPrice,
		string  _datasetParams)
	IexecHubAccessor(_iexecHubAddress)
	public
	{
		// tx.origin == owner
		// msg.sender == DatasetHub
		require(tx.origin != msg.sender);
		setImmutableOwnership(tx.origin); // owner → tx.origin

		m_datasetName   = _datasetName;
		m_datasetPrice  = _datasetPrice;
		m_datasetParams = _datasetParams;

	}


}


pragma solidity ^0.4.21;


contract DatasetHub is OwnableOZ // is Owned by IexecHub
{
	using SafeMathOZ for uint256;

	/**
	 * Members
	 */
	mapping(address => uint256)                     m_datasetCountByOwner;
	mapping(address => mapping(uint256 => address)) m_datasetByOwnerByIndex;
	mapping(address => bool)                        m_datasetRegistered;

	mapping(uint256 => address)                     m_datasetByIndex;
	uint256 public                                  m_totalDatasetCount;



	/**
	 * Constructor
	 */
	function DatasetHub() public
	{
	}

	/**
	 * Methods
	 */
	function isDatasetRegistred(address _dataset) public view returns (bool)
	{
		return m_datasetRegistered[_dataset];
	}
	function getDatasetsCount(address _owner) public view returns (uint256)
	{
		return m_datasetCountByOwner[_owner];
	}
	function getDataset(address _owner, uint256 _index) public view returns (address)
	{
		return m_datasetByOwnerByIndex[_owner][_index];
	}
	function getDatasetByIndex(uint256 _index) public view returns (address)
	{
		return m_datasetByIndex[_index];
	}

	function addDataset(address _owner, address _dataset) internal
	{
		uint id = m_datasetCountByOwner[_owner].add(1);
		m_totalDatasetCount = m_totalDatasetCount.add(1);
		m_datasetByIndex       [m_totalDatasetCount] = _dataset;
		m_datasetCountByOwner  [_owner]              = id;
		m_datasetByOwnerByIndex[_owner][id]          = _dataset;
		m_datasetRegistered    [_dataset]            = true;
	}

	function createDataset(
		string _datasetName,
		uint256 _datasetPrice,
		string _datasetParams)
	public onlyOwner /*owner == IexecHub*/ returns (address createdDataset)
	{
		// tx.origin == owner
		// msg.sender == IexecHub
		address newDataset = new Dataset(
			msg.sender,
			_datasetName,
			_datasetPrice,
			_datasetParams
		);
		addDataset(tx.origin, newDataset);
		return newDataset;
	}
}


pragma solidity ^0.4.21;



/**
 * @title IexecHub
 */

contract IexecHub
{
	using SafeMathOZ for uint256;

	/**
	* RLC contract for token transfers.
	*/
	RLC public rlc;

	uint256 public constant STAKE_BONUS_RATIO         = 10;
	uint256 public constant STAKE_BONUS_MIN_THRESHOLD = 1000;
	uint256 public constant SCORE_UNITARY_SLASH       = 50;

	/**
	 * Slaves contracts
	 */
	AppHub        public appHub;
	DatasetHub    public datasetHub;
	WorkerPoolHub public workerPoolHub;

	/**
	 * Market place
	 */
	Marketplace public marketplace;
	modifier onlyMarketplace()
	{
		require(msg.sender == address(marketplace));
		_;
	}
	/**
	 * Categories
	 */
	mapping(uint256 => IexecLib.Category) public m_categories;
	uint256                               public m_categoriesCount;
	address                               public m_categoriesCreator;
	modifier onlyCategoriesCreator()
	{
		require(msg.sender == m_categoriesCreator);
		_;
	}

	/**
	 * Escrow
	 */
	mapping(address => IexecLib.Account) public m_accounts;


	/**
	 * workOrder Registered
	 */
	mapping(address => bool) public m_woidRegistered;
	modifier onlyRegisteredWoid(address _woid)
	{
		require(m_woidRegistered[_woid]);
		_;
	}

	/**
	 * Reputation for PoCo
	 */
	mapping(address => uint256)  public m_scores;
	IexecLib.ContributionHistory public m_contributionHistory;


	event WorkOrderActivated(address woid, address indexed workerPool);
	event WorkOrderClaimed  (address woid, address workerPool);
	event WorkOrderCompleted(address woid, address workerPool);

	event CreateApp       (address indexed appOwner,        address indexed app,        string appName,     uint256 appPrice,     string appParams    );
	event CreateDataset   (address indexed datasetOwner,    address indexed dataset,    string datasetName, uint256 datasetPrice, string datasetParams);
	event CreateWorkerPool(address indexed workerPoolOwner, address indexed workerPool, string workerPoolDescription                                        );

	event CreateCategory  (uint256 catid, string name, string description, uint256 workClockTimeRef);

	event WorkerPoolSubscription  (address indexed workerPool, address worker);
	event WorkerPoolUnsubscription(address indexed workerPool, address worker);
	event WorkerPoolEviction      (address indexed workerPool, address worker);

	event AccurateContribution(address woid, address indexed worker);
	event FaultyContribution  (address woid, address indexed worker);

	event Deposit (address owner, uint256 amount);
	event Withdraw(address owner, uint256 amount);
	event Reward  (address user,  uint256 amount);
	event Seize   (address user,  uint256 amount);

	/**
	 * Constructor
	 */
	function IexecHub()
	public
	{
		m_categoriesCreator = msg.sender;
	}

	function attachContracts(
		address _tokenAddress,
		address _marketplaceAddress,
		address _workerPoolHubAddress,
		address _appHubAddress,
		address _datasetHubAddress)
	public onlyCategoriesCreator
	{
		require(address(rlc) == address(0));
		rlc                = RLC          (_tokenAddress        );
		marketplace        = Marketplace  (_marketplaceAddress  );
		workerPoolHub      = WorkerPoolHub(_workerPoolHubAddress);
		appHub             = AppHub       (_appHubAddress       );
		datasetHub         = DatasetHub   (_datasetHubAddress   );

	}

	function setCategoriesCreator(address _categoriesCreator)
	public onlyCategoriesCreator
	{
		m_categoriesCreator = _categoriesCreator;
	}
	/**
	 * Factory
	 */

	function createCategory(
		string  _name,
		string  _description,
		uint256 _workClockTimeRef)
	public onlyCategoriesCreator returns (uint256 catid)
	{
		m_categoriesCount                  = m_categoriesCount.add(1);
		IexecLib.Category storage category = m_categories[m_categoriesCount];
		category.catid                     = m_categoriesCount;
		category.name                      = _name;
		category.description               = _description;
		category.workClockTimeRef          = _workClockTimeRef;
		emit CreateCategory(m_categoriesCount, _name, _description, _workClockTimeRef);
		return m_categoriesCount;
	}

	function createWorkerPool(
		string  _description,
		uint256 _subscriptionLockStakePolicy,
		uint256 _subscriptionMinimumStakePolicy,
		uint256 _subscriptionMinimumScorePolicy)
	external returns (address createdWorkerPool)
	{
		address newWorkerPool = workerPoolHub.createWorkerPool(
			_description,
			_subscriptionLockStakePolicy,
			_subscriptionMinimumStakePolicy,
			_subscriptionMinimumScorePolicy,
			address(marketplace)
		);
		emit CreateWorkerPool(tx.origin, newWorkerPool, _description);
		return newWorkerPool;
	}

	function createApp(
		string  _appName,
		uint256 _appPrice,
		string  _appParams)
	external returns (address createdApp)
	{
		address newApp = appHub.createApp(
			_appName,
			_appPrice,
			_appParams
		);
		emit CreateApp(tx.origin, newApp, _appName, _appPrice, _appParams);
		return newApp;
	}

	function createDataset(
		string  _datasetName,
		uint256 _datasetPrice,
		string  _datasetParams)
	external returns (address createdDataset)
	{
		address newDataset = datasetHub.createDataset(
			_datasetName,
			_datasetPrice,
			_datasetParams
			);
		emit CreateDataset(tx.origin, newDataset, _datasetName, _datasetPrice, _datasetParams);
		return newDataset;
	}

	/**
	 * WorkOrder Emission
	 */
	function buyForWorkOrder(
		uint256 _marketorderIdx,
		address _workerpool,
		address _app,
		address _dataset,
		string  _params,
		address _callback,
		address _beneficiary)
	external returns (address)
	{
		address requester = msg.sender;
		require(marketplace.consumeMarketOrderAsk(_marketorderIdx, requester, _workerpool));

		uint256 emitcost = lockWorkOrderCost(requester, _workerpool, _app, _dataset);

		WorkOrder workorder = new WorkOrder(
			_marketorderIdx,
			requester,
			_app,
			_dataset,
			_workerpool,
			emitcost,
			_params,
			_callback,
			_beneficiary
		);

		m_woidRegistered[workorder] = true;

		require(WorkerPool(_workerpool).emitWorkOrder(workorder, _marketorderIdx));

		emit WorkOrderActivated(workorder, _workerpool);
		return workorder;
	}

	function isWoidRegistred(address _woid) public view returns (bool)
	{
		return m_woidRegistered[_woid];
	}

	function lockWorkOrderCost(
		address _requester,
		address _workerpool, // Address of a smartcontract
		address _app,        // Address of a smartcontract
		address _dataset)    // Address of a smartcontract
	internal returns (uint256)
	{
		// APP
		App app = App(_app);
		require(appHub.isAppRegistered (_app));
		// initialize usercost with dapp price
		uint256 emitcost = app.m_appPrice();

		// DATASET
		if (_dataset != address(0)) // address(0) → no dataset
		{
			Dataset dataset = Dataset(_dataset);
			require(datasetHub.isDatasetRegistred(_dataset));
			// add optional datasetPrice for userCost
			emitcost = emitcost.add(dataset.m_datasetPrice());
		}

		// WORKERPOOL
		require(workerPoolHub.isWorkerPoolRegistered(_workerpool));

		require(lock(_requester, emitcost)); // Lock funds for app + dataset payment

		return emitcost;
	}

	/**
	 * WorkOrder life cycle
	 */

	function claimFailedConsensus(address _woid)
	public onlyRegisteredWoid(_woid) returns (bool)
	{
		WorkOrder  workorder  = WorkOrder(_woid);
		require(workorder.m_requester() == msg.sender);
		WorkerPool workerpool = WorkerPool(workorder.m_workerpool());

		IexecLib.WorkOrderStatusEnum currentStatus = workorder.m_status();
		require(currentStatus == IexecLib.WorkOrderStatusEnum.ACTIVE || currentStatus == IexecLib.WorkOrderStatusEnum.REVEALING);
		// Unlock stakes for all workers
		require(workerpool.claimFailedConsensus(_woid));
		workorder.claim(); // revert on error

		/* uint256 value           = marketplace.getMarketOrderValue(workorder.m_marketorderIdx()); // revert if not exist */
		/* address workerpoolOwner = marketplace.getMarketOrderWorkerpoolOwner(workorder.m_marketorderIdx()); // revert if not exist */
		uint256 value;
		address workerpoolOwner;
		(,,,value,,,,workerpoolOwner) = marketplace.getMarketOrder(workorder.m_marketorderIdx()); // Single call cost less gas
		uint256 workerpoolStake = value.percentage(marketplace.ASK_STAKE_RATIO());

		require(unlock (workorder.m_requester(), value.add(workorder.m_emitcost()))); // UNLOCK THE FUNDS FOR REINBURSEMENT
		require(seize  (workerpoolOwner,         workerpoolStake));
		// put workerpoolOwner stake seize into iexecHub address for bonus for scheduler on next well finalized Task
		require(reward (this,                    workerpoolStake));
		require(lock   (this,                    workerpoolStake));

		emit WorkOrderClaimed(_woid, workorder.m_workerpool());
		return true;
	}

	function finalizeWorkOrder(
		address _woid,
		string  _stdout,
		string  _stderr,
		string  _uri)
	public onlyRegisteredWoid(_woid) returns (bool)
	{
		WorkOrder workorder = WorkOrder(_woid);
		require(workorder.m_workerpool() == msg.sender);
		require(workorder.m_status()     == IexecLib.WorkOrderStatusEnum.REVEALING);

		// APP
		App     app      = App(workorder.m_app());
		uint256 appPrice = app.m_appPrice();
		if (appPrice > 0)
		{
			require(reward(app.m_owner(), appPrice));
		}

		// DATASET
		Dataset dataset = Dataset(workorder.m_dataset());
		if (dataset != address(0))
		{
			uint256 datasetPrice = dataset.m_datasetPrice();
			if (datasetPrice > 0)
			{
				require(reward(dataset.m_owner(), datasetPrice));
			}
		}

		// WORKERPOOL → rewarding done by the caller itself

		/**
		 * seize stacked funds from requester.
		 * reward = value: was locked at market making
		 * emitcost: was locked at when emiting the workorder
		 */
		/* uint256 value           = marketplace.getMarketOrderValue(workorder.m_marketorderIdx()); // revert if not exist */
		/* address workerpoolOwner = marketplace.getMarketOrderWorkerpoolOwner(workorder.m_marketorderIdx()); // revert if not exist */
		uint256 value;
		address workerpoolOwner;
		(,,,value,,,,workerpoolOwner) = marketplace.getMarketOrder(workorder.m_marketorderIdx()); // Single call cost less gas
		uint256 workerpoolStake       = value.percentage(marketplace.ASK_STAKE_RATIO());

		require(seize (workorder.m_requester(), value.add(workorder.m_emitcost()))); // seize funds for payment (market value + emitcost)
		require(unlock(workerpoolOwner,         workerpoolStake)); // unlock scheduler stake

		// write results
		workorder.setResult(_stdout, _stderr, _uri); // revert on error

		// Rien ne se perd, rien ne se cr&#233;e, tout se transfere
		// distribute bonus to scheduler. jackpot bonus come from scheduler stake loose on IexecHub contract
		// we reuse the varaible value for the kitty / fraction of the kitty (stack too deep)
		/* (,value) = checkBalance(this); // kitty is locked on `this` wallet */
		value = m_accounts[this].locked; // kitty is locked on `this` wallet
		if(value > 0)
		{
			value = value.min(value.percentage(STAKE_BONUS_RATIO).max(STAKE_BONUS_MIN_THRESHOLD));
			require(seize(this,             value));
			require(reward(workerpoolOwner, value));
		}

		emit WorkOrderCompleted(_woid, workorder.m_workerpool());
		return true;
	}

	/**
	 * Views
	 */
	function getCategoryWorkClockTimeRef(uint256 _catId) public view returns (uint256 workClockTimeRef)
	{
		require(existingCategory(_catId));
		return m_categories[_catId].workClockTimeRef;
	}

	function existingCategory(uint256 _catId) public view  returns (bool categoryExist)
	{
		return m_categories[_catId].catid > 0;
	}

	function getCategory(uint256 _catId) public view returns (uint256 catid, string name, string  description, uint256 workClockTimeRef)
	{
		require(existingCategory(_catId));
		return (
			m_categories[_catId].catid,
			m_categories[_catId].name,
			m_categories[_catId].description,
			m_categories[_catId].workClockTimeRef
		);
	}

	function getWorkerStatus(address _worker) public view returns (address workerPool, uint256 workerScore)
	{
		return (workerPoolHub.getWorkerAffectation(_worker), m_scores[_worker]);
	}

	function getWorkerScore(address _worker) public view returns (uint256 workerScore)
	{
		return m_scores[_worker];
	}

	/**
	 * Worker subscription
	 */
	function registerToPool(address _worker) public returns (bool subscribed)
	// msg.sender = workerPool
	{
		WorkerPool workerpool = WorkerPool(msg.sender);
		// Check credentials
		require(workerPoolHub.isWorkerPoolRegistered(msg.sender));
		// Lock worker deposit
		require(lock(_worker, workerpool.m_subscriptionLockStakePolicy()));
		// Check subscription policy
		require(m_accounts[_worker].stake >= workerpool.m_subscriptionMinimumStakePolicy());
		require(m_scores[_worker]         >= workerpool.m_subscriptionMinimumScorePolicy());
		// Update affectation
		require(workerPoolHub.registerWorkerAffectation(msg.sender, _worker));
		// Trigger event notice
		emit WorkerPoolSubscription(msg.sender, _worker);
		return true;
	}

	function unregisterFromPool(address _worker) public returns (bool unsubscribed)
	// msg.sender = workerPool
	{
		require(removeWorker(msg.sender, _worker));
		// Trigger event notice
		emit WorkerPoolUnsubscription(msg.sender, _worker);
		return true;
	}

	function evictWorker(address _worker) public returns (bool unsubscribed)
	// msg.sender = workerpool
	{
		require(removeWorker(msg.sender, _worker));
		// Trigger event notice
		emit WorkerPoolEviction(msg.sender, _worker);
		return true;
	}

	function removeWorker(address _workerpool, address _worker) internal returns (bool unsubscribed)
	{
		WorkerPool workerpool = WorkerPool(_workerpool);
		// Check credentials
		require(workerPoolHub.isWorkerPoolRegistered(_workerpool));
		// Unlick worker stake
		require(unlock(_worker, workerpool.m_subscriptionLockStakePolicy()));
		// Update affectation
		require(workerPoolHub.unregisterWorkerAffectation(_workerpool, _worker));
		return true;
	}

	/**
	 * Stake, reward and penalty functions
	 */
	/* Marketplace */
	function lockForOrder(address _user, uint256 _amount) public onlyMarketplace returns (bool)
	{
		require(lock(_user, _amount));
		return true;
	}
	function unlockForOrder(address _user, uint256 _amount) public  onlyMarketplace returns (bool)
	{
		require(unlock(_user, _amount));
		return true;
	}
	/* Work */
	function lockForWork(address _woid, address _user, uint256 _amount) public onlyRegisteredWoid(_woid) returns (bool)
	{
		require(WorkOrder(_woid).m_workerpool() == msg.sender);
		require(lock(_user, _amount));
		return true;
	}
	function unlockForWork(address _woid, address _user, uint256 _amount) public onlyRegisteredWoid(_woid) returns (bool)
	{
		require(WorkOrder(_woid).m_workerpool() == msg.sender);
		require(unlock(_user, _amount));
		return true;
	}
	function rewardForWork(address _woid, address _worker, uint256 _amount, bool _reputation) public onlyRegisteredWoid(_woid) returns (bool)
	{
		require(WorkOrder(_woid).m_workerpool() == msg.sender);
		require(reward(_worker, _amount));
		if (_reputation)
		{
			m_contributionHistory.success = m_contributionHistory.success.add(1);
			m_scores[_worker] = m_scores[_worker].add(1);
			emit AccurateContribution(_woid, _worker);
		}
		return true;
	}
	function seizeForWork(address _woid, address _worker, uint256 _amount, bool _reputation) public onlyRegisteredWoid(_woid) returns (bool)
	{
		require(WorkOrder(_woid).m_workerpool() == msg.sender);
		require(seize(_worker, _amount));
		if (_reputation)
		{
			m_contributionHistory.failed = m_contributionHistory.failed.add(1);
			m_scores[_worker] = m_scores[_worker].sub(m_scores[_worker].min(SCORE_UNITARY_SLASH));
			emit FaultyContribution(_woid, _worker);
		}
		return true;
	}
	/**
	 * Wallet methods: public
	 */
	function deposit(uint256 _amount) external returns (bool)
	{
		require(rlc.transferFrom(msg.sender, address(this), _amount));
		m_accounts[msg.sender].stake = m_accounts[msg.sender].stake.add(_amount);
		emit Deposit(msg.sender, _amount);
		return true;
	}
	function withdraw(uint256 _amount) external returns (bool)
	{
		m_accounts[msg.sender].stake = m_accounts[msg.sender].stake.sub(_amount);
		require(rlc.transfer(msg.sender, _amount));
		emit Withdraw(msg.sender, _amount);
		return true;
	}
	function checkBalance(address _owner) public view returns (uint256 stake, uint256 locked)
	{
		return (m_accounts[_owner].stake, m_accounts[_owner].locked);
	}
	/**
	 * Wallet methods: Internal
	 */
	function reward(address _user, uint256 _amount) internal returns (bool)
	{
		m_accounts[_user].stake = m_accounts[_user].stake.add(_amount);
		emit Reward(_user, _amount);
		return true;
	}
	function seize(address _user, uint256 _amount) internal returns (bool)
	{
		m_accounts[_user].locked = m_accounts[_user].locked.sub(_amount);
		emit Seize(_user, _amount);
		return true;
	}
	function lock(address _user, uint256 _amount) internal returns (bool)
	{
		m_accounts[_user].stake  = m_accounts[_user].stake.sub(_amount);
		m_accounts[_user].locked = m_accounts[_user].locked.add(_amount);
		return true;
	}
	function unlock(address _user, uint256 _amount) internal returns (bool)
	{
		m_accounts[_user].locked = m_accounts[_user].locked.sub(_amount);
		m_accounts[_user].stake  = m_accounts[_user].stake.add(_amount);
		return true;
	}
}


pragma solidity ^0.4.21;


contract WorkerPool is OwnableOZ, IexecHubAccessor, MarketplaceAccessor
{
	using SafeMathOZ for uint256;


	/**
	 * Members
	 */
	string                      public m_description;
	uint256                     public m_stakeRatioPolicy;               // % of reward to stake
	uint256                     public m_schedulerRewardRatioPolicy;     // % of reward given to scheduler
	uint256                     public m_subscriptionLockStakePolicy;    // Stake locked when in workerpool - Constant set by constructor, do not update
	uint256                     public m_subscriptionMinimumStakePolicy; // Minimum stake for subscribing
	uint256                     public m_subscriptionMinimumScorePolicy; // Minimum score for subscribing
	address[]                   public m_workers;
	mapping(address => uint256) public m_workerIndex;

	// mapping(woid => IexecLib.Consensus)
	mapping(address => IexecLib.Consensus) public m_consensus;
	// mapping(woid => worker address => Contribution);
	mapping(address => mapping(address => IexecLib.Contribution)) public m_contributions;

	uint256 public constant REVEAL_PERIOD_DURATION_RATIO  = 2;
	uint256 public constant CONSENSUS_DURATION_RATIO      = 10;

	/**
	 * Address of slave/related contracts
	 */
	address        public  m_workerPoolHubAddress;


	/**
	 * Events
	 */
	event WorkerPoolPolicyUpdate(
		uint256 oldStakeRatioPolicy,               uint256 newStakeRatioPolicy,
		uint256 oldSchedulerRewardRatioPolicy,     uint256 newSchedulerRewardRatioPolicy,
		uint256 oldSubscriptionMinimumStakePolicy, uint256 newSubscriptionMinimumStakePolicy,
		uint256 oldSubscriptionMinimumScorePolicy, uint256 newSubscriptionMinimumScorePolicy);

	event WorkOrderActive         (address indexed woid);
	event WorkOrderClaimed        (address indexed woid);

	event AllowWorkerToContribute (address indexed woid, address indexed worker, uint256 workerScore);
	event Contribute              (address indexed woid, address indexed worker, bytes32 resultHash);
	event RevealConsensus         (address indexed woid, bytes32 consensus);
	event Reveal                  (address indexed woid, address indexed worker, bytes32 result);
	event Reopen                  (address indexed woid);
  event FinalizeWork            (address indexed woid, string stdout, string stderr, string uri);



	event WorkerSubscribe         (address indexed worker);
	event WorkerUnsubscribe       (address indexed worker);
	event WorkerEviction          (address indexed worker);

	/**
	 * Methods
	 */
	// Constructor
	function WorkerPool(
		address _iexecHubAddress,
		string  _description,
		uint256 _subscriptionLockStakePolicy,
		uint256 _subscriptionMinimumStakePolicy,
		uint256 _subscriptionMinimumScorePolicy,
		address _marketplaceAddress)
	IexecHubAccessor(_iexecHubAddress)
	MarketplaceAccessor(_marketplaceAddress)
	public
	{
		// tx.origin == owner
		// msg.sender ==  WorkerPoolHub
		require(tx.origin != msg.sender);
		setImmutableOwnership(tx.origin); // owner → tx.origin

		m_description                    = _description;
		m_stakeRatioPolicy               = 30; // % of the work order price to stake
		m_schedulerRewardRatioPolicy     = 1;  // % of the work reward going to scheduler vs workers reward
		m_subscriptionLockStakePolicy    = _subscriptionLockStakePolicy; // only at creation. cannot be change to respect lock/unlock of worker stake
		m_subscriptionMinimumStakePolicy = _subscriptionMinimumStakePolicy;
		m_subscriptionMinimumScorePolicy = _subscriptionMinimumScorePolicy;
		m_workerPoolHubAddress           = msg.sender;

	}

	function changeWorkerPoolPolicy(
		uint256 _newStakeRatioPolicy,
		uint256 _newSchedulerRewardRatioPolicy,
		uint256 _newSubscriptionMinimumStakePolicy,
		uint256 _newSubscriptionMinimumScorePolicy)
	public onlyOwner
	{
		emit WorkerPoolPolicyUpdate(
			m_stakeRatioPolicy,               _newStakeRatioPolicy,
			m_schedulerRewardRatioPolicy,     _newSchedulerRewardRatioPolicy,
			m_subscriptionMinimumStakePolicy, _newSubscriptionMinimumStakePolicy,
			m_subscriptionMinimumScorePolicy, _newSubscriptionMinimumScorePolicy
		);
		require(_newSchedulerRewardRatioPolicy <= 100);
		m_stakeRatioPolicy               = _newStakeRatioPolicy;
		m_schedulerRewardRatioPolicy     = _newSchedulerRewardRatioPolicy;
		m_subscriptionMinimumStakePolicy = _newSubscriptionMinimumStakePolicy;
		m_subscriptionMinimumScorePolicy = _newSubscriptionMinimumScorePolicy;
	}

	/************************* worker list management **************************/
	function getWorkerAddress(uint _index) public view returns (address)
	{
		return m_workers[_index];
	}
	function getWorkerIndex(address _worker) public view returns (uint)
	{
		uint index = m_workerIndex[_worker];
		require(m_workers[index] == _worker);
		return index;
	}
	function getWorkersCount() public view returns (uint)
	{
		return m_workers.length;
	}

	function subscribeToPool() public returns (bool)
	{
		// msg.sender = worker
		require(iexecHubInterface.registerToPool(msg.sender));
		uint index = m_workers.push(msg.sender);
		m_workerIndex[msg.sender] = index.sub(1);
		emit WorkerSubscribe(msg.sender);
		return true;
	}

	function unsubscribeFromPool() public  returns (bool)
	{
		// msg.sender = worker
		require(iexecHubInterface.unregisterFromPool(msg.sender));
		require(removeWorker(msg.sender));
		emit WorkerUnsubscribe(msg.sender);
		return true;
	}

	function evictWorker(address _worker) public onlyOwner returns (bool)
	{
		// msg.sender = scheduler
		require(iexecHubInterface.evictWorker(_worker));
		require(removeWorker(_worker));
		emit WorkerEviction(_worker);
		return true;
	}

	function removeWorker(address _worker) internal returns (bool)
	{
		uint index = getWorkerIndex(_worker); // fails if worker not registered
		address lastWorker = m_workers[m_workers.length.sub(1)];
		m_workers    [index     ] = lastWorker;
		m_workerIndex[lastWorker] = index;
		delete m_workers[m_workers.length.sub(1)];
		m_workers.length = m_workers.length.sub(1);
		return true;
	}

	function getConsensusDetails(address _woid) public view returns (
		uint256 c_poolReward,
		uint256 c_stakeAmount,
		bytes32 c_consensus,
		uint256 c_revealDate,
		uint256 c_revealCounter,
		uint256 c_consensusTimeout,
		uint256 c_winnerCount,
		address c_workerpoolOwner)
	{
		IexecLib.Consensus storage consensus = m_consensus[_woid];
		return (
			consensus.poolReward,
			consensus.stakeAmount,
			consensus.consensus,
			consensus.revealDate,
			consensus.revealCounter,
			consensus.consensusTimeout,
			consensus.winnerCount,
			consensus.workerpoolOwner
		);
	}

	function getContributorsCount(address _woid) public view returns (uint256 contributorsCount)
	{
		return m_consensus[_woid].contributors.length;
	}

	function getContributor(address _woid, uint256 index) public view returns (address contributor)
	{
		return m_consensus[_woid].contributors[index];
	}

	function existingContribution(address _woid, address _worker) public view  returns (bool contributionExist)
	{
		return m_contributions[_woid][_worker].status != IexecLib.ContributionStatusEnum.UNSET;
	}

	function getContribution(address _woid, address _worker) public view returns
	(
		IexecLib.ContributionStatusEnum status,
		bytes32 resultHash,
		bytes32 resultSign,
		address enclaveChallenge,
		uint256 score,
		uint256 weight)
	{
		require(existingContribution(_woid, _worker)); // no silent value returned
		IexecLib.Contribution storage contribution = m_contributions[_woid][_worker];
		return (
			contribution.status,
			contribution.resultHash,
			contribution.resultSign,
			contribution.enclaveChallenge,
			contribution.score,
			contribution.weight
		);
	}


	/**************************** Works management *****************************/
	function emitWorkOrder(address _woid, uint256 _marketorderIdx) public onlyIexecHub returns (bool)
	{
		uint256 catid   = marketplaceInterface.getMarketOrderCategory(_marketorderIdx);
		uint256 timeout = iexecHubInterface.getCategoryWorkClockTimeRef(catid).mul(CONSENSUS_DURATION_RATIO).add(now);

		IexecLib.Consensus storage consensus = m_consensus[_woid];
		consensus.poolReward                 = marketplaceInterface.getMarketOrderValue(_marketorderIdx);
		consensus.workerpoolOwner            = marketplaceInterface.getMarketOrderWorkerpoolOwner(_marketorderIdx);
		consensus.stakeAmount                = consensus.poolReward.percentage(m_stakeRatioPolicy);
		consensus.consensusTimeout            = timeout;
		consensus.schedulerRewardRatioPolicy = m_schedulerRewardRatioPolicy;

		emit WorkOrderActive(_woid);

		return true;
	}

	function claimFailedConsensus(address _woid) public onlyIexecHub returns (bool)
	{
	  IexecLib.Consensus storage consensus = m_consensus[_woid];
		require(now > consensus.consensusTimeout);
		uint256 i;
		address w;
		for (i = 0; i < consensus.contributors.length; ++i)
		{
			w = consensus.contributors[i];
			if (m_contributions[_woid][w].status != IexecLib.ContributionStatusEnum.AUTHORIZED)
			{
				require(iexecHubInterface.unlockForWork(_woid, w, consensus.stakeAmount));
			}
		}
		emit WorkOrderClaimed(_woid);
		return true;
	}

	function allowWorkersToContribute(address _woid, address[] _workers, address _enclaveChallenge) public onlyOwner /*onlySheduler*/ returns (bool)
	{
		for (uint i = 0; i < _workers.length; ++i)
		{
			require(allowWorkerToContribute(_woid, _workers[i], _enclaveChallenge));
		}
		return true;
	}

	function allowWorkerToContribute(address _woid, address _worker, address _enclaveChallenge) public onlyOwner /*onlySheduler*/ returns (bool)
	{
		require(iexecHubInterface.isWoidRegistred(_woid));
		require(WorkOrder(_woid).m_status() == IexecLib.WorkOrderStatusEnum.ACTIVE);
		IexecLib.Contribution storage contribution = m_contributions[_woid][_worker];
		IexecLib.Consensus    storage consensus    = m_consensus[_woid];
		require(now <= consensus.consensusTimeout);

		address workerPool;
		uint256 workerScore;
		(workerPool, workerScore) = iexecHubInterface.getWorkerStatus(_worker); // workerPool, workerScore
		require(workerPool == address(this));

		require(contribution.status == IexecLib.ContributionStatusEnum.UNSET);
		contribution.status           = IexecLib.ContributionStatusEnum.AUTHORIZED;
		contribution.enclaveChallenge = _enclaveChallenge;

		emit AllowWorkerToContribute(_woid, _worker, workerScore);
		return true;
	}

	function contribute(address _woid, bytes32 _resultHash, bytes32 _resultSign, uint8 _v, bytes32 _r, bytes32 _s) public returns (uint256 workerStake)
	{
		require(iexecHubInterface.isWoidRegistred(_woid));
		IexecLib.Consensus    storage consensus    = m_consensus[_woid];
		require(now <= consensus.consensusTimeout);
		require(WorkOrder(_woid).m_status() == IexecLib.WorkOrderStatusEnum.ACTIVE); // can&#39;t contribute on a claimed or completed workorder
		IexecLib.Contribution storage contribution = m_contributions[_woid][msg.sender];

		// msg.sender = a worker
		require(_resultHash != 0x0);
		require(_resultSign != 0x0);
		if (contribution.enclaveChallenge != address(0))
		{
			require(contribution.enclaveChallenge == ecrecover(keccak256("\x19Ethereum Signed Message:\n64", _resultHash, _resultSign), _v, _r, _s));
		}

		require(contribution.status == IexecLib.ContributionStatusEnum.AUTHORIZED);
		contribution.status     = IexecLib.ContributionStatusEnum.CONTRIBUTED;
		contribution.resultHash = _resultHash;
		contribution.resultSign = _resultSign;
		contribution.score      = iexecHubInterface.getWorkerScore(msg.sender);
		consensus.contributors.push(msg.sender);

		require(iexecHubInterface.lockForWork(_woid, msg.sender, consensus.stakeAmount));
		emit Contribute(_woid, msg.sender, _resultHash);
		return consensus.stakeAmount;
	}

	function revealConsensus(address _woid, bytes32 _consensus) public onlyOwner /*onlySheduler*/ returns (bool)
	{
		require(iexecHubInterface.isWoidRegistred(_woid));
		IexecLib.Consensus storage consensus = m_consensus[_woid];
		require(now <= consensus.consensusTimeout);
		require(WorkOrder(_woid).startRevealingPhase());

		consensus.winnerCount = 0;
		for (uint256 i = 0; i<consensus.contributors.length; ++i)
		{
			address w = consensus.contributors[i];
			if (
				m_contributions[_woid][w].resultHash == _consensus
				&&
				m_contributions[_woid][w].status == IexecLib.ContributionStatusEnum.CONTRIBUTED // REJECTED contribution must not be count
			)
			{
				consensus.winnerCount = consensus.winnerCount.add(1);
			}
		}
		require(consensus.winnerCount > 0); // you cannot revealConsensus if no worker has contributed to this hash

		consensus.consensus  = _consensus;
		consensus.revealDate = iexecHubInterface.getCategoryWorkClockTimeRef(marketplaceInterface.getMarketOrderCategory(WorkOrder(_woid).m_marketorderIdx())).mul(REVEAL_PERIOD_DURATION_RATIO).add(now); // is it better to store th catid ?
		emit RevealConsensus(_woid, _consensus);
		return true;
	}

	function reveal(address _woid, bytes32 _result) public returns (bool)
	{
		require(iexecHubInterface.isWoidRegistred(_woid));
		IexecLib.Consensus    storage consensus    = m_consensus[_woid];
		require(now <= consensus.consensusTimeout);
		IexecLib.Contribution storage contribution = m_contributions[_woid][msg.sender];

		require(WorkOrder(_woid).m_status() == IexecLib.WorkOrderStatusEnum.REVEALING     );
		require(consensus.revealDate        >  now                                        );
		require(contribution.status         == IexecLib.ContributionStatusEnum.CONTRIBUTED);
		require(contribution.resultHash     == consensus.consensus                        );
		require(contribution.resultHash     == keccak256(_result                        ) );
		require(contribution.resultSign     == keccak256(_result ^ keccak256(msg.sender)) );

		contribution.status     = IexecLib.ContributionStatusEnum.PROVED;
		consensus.revealCounter = consensus.revealCounter.add(1);

		emit Reveal(_woid, msg.sender, _result);
		return true;
	}

	function reopen(address _woid) public onlyOwner /*onlySheduler*/ returns (bool)
	{
		require(iexecHubInterface.isWoidRegistred(_woid));
		IexecLib.Consensus storage consensus = m_consensus[_woid];
		require(now <= consensus.consensusTimeout);
		require(consensus.revealDate <= now && consensus.revealCounter == 0);
		require(WorkOrder(_woid).reActivate());

		for (uint256 i = 0; i < consensus.contributors.length; ++i)
		{
			address w = consensus.contributors[i];
			if (m_contributions[_woid][w].resultHash == consensus.consensus)
			{
				m_contributions[_woid][w].status = IexecLib.ContributionStatusEnum.REJECTED;
			}
		}
		// Reset to status before revealConsensus. Must be after REJECTED traitement above because of consensus.consensus check
		consensus.winnerCount = 0;
		consensus.consensus   = 0x0;
		consensus.revealDate  = 0;
		emit Reopen(_woid);
		return true;
	}

	// if sheduler never call finalized ? no incetive to do that. schedulermust be pay also at this time
	function finalizeWork(address _woid, string _stdout, string _stderr, string _uri) public onlyOwner /*onlySheduler*/ returns (bool)
	{
		require(iexecHubInterface.isWoidRegistred(_woid));
		IexecLib.Consensus storage consensus = m_consensus[_woid];
		require(now <= consensus.consensusTimeout);
		require((consensus.revealDate <= now && consensus.revealCounter > 0) || (consensus.revealCounter == consensus.winnerCount)); // consensus.winnerCount never 0 at this step

		// add penalized to the call worker to contribution and they never contribute ?
		require(distributeRewards(_woid, consensus));

		require(iexecHubInterface.finalizeWorkOrder(_woid, _stdout, _stderr, _uri));
		emit FinalizeWork(_woid,_stdout,_stderr,_uri);
		return true;
	}

	function distributeRewards(address _woid, IexecLib.Consensus _consensus) internal returns (bool)
	{
		uint256 i;
		address w;
		uint256 workerBonus;
		uint256 workerWeight;
		uint256 totalWeight;
		uint256 individualWorkerReward;
		uint256 totalReward = _consensus.poolReward;
		address[] memory contributors = _consensus.contributors;
		for (i = 0; i<contributors.length; ++i)
		{
			w = contributors[i];
			IexecLib.Contribution storage c = m_contributions[_woid][w];
			if (c.status == IexecLib.ContributionStatusEnum.PROVED)
			{
				workerBonus  = (c.enclaveChallenge != address(0)) ? 3 : 1; // TODO: bonus sgx = 3 ?
				workerWeight = 1 + c.score.mul(workerBonus).log();
				totalWeight  = totalWeight.add(workerWeight);
				c.weight     = workerWeight; // store so we don&#39;t have to recompute
			}
			else // ContributionStatusEnum.REJECT or ContributionStatusEnum.CONTRIBUTED (not revealed)
			{
				totalReward = totalReward.add(_consensus.stakeAmount);
			}
		}
		require(totalWeight > 0);

		// compute how much is going to the workers
		uint256 totalWorkersReward = totalReward.percentage(uint256(100).sub(_consensus.schedulerRewardRatioPolicy));

		for (i = 0; i<contributors.length; ++i)
		{
			w = contributors[i];
			if (m_contributions[_woid][w].status == IexecLib.ContributionStatusEnum.PROVED)
			{
				individualWorkerReward = totalWorkersReward.mulByFraction(m_contributions[_woid][w].weight, totalWeight);
				totalReward  = totalReward.sub(individualWorkerReward);
				require(iexecHubInterface.unlockForWork(_woid, w, _consensus.stakeAmount));
				require(iexecHubInterface.rewardForWork(_woid, w, individualWorkerReward, true));
			}
			else // WorkStatusEnum.POCO_REJECT or ContributionStatusEnum.CONTRIBUTED (not revealed)
			{
				require(iexecHubInterface.seizeForWork(_woid, w, _consensus.stakeAmount, true));
				// No Reward
			}
		}
		// totalReward now contains the scheduler share
		require(iexecHubInterface.rewardForWork(_woid, _consensus.workerpoolOwner, totalReward, false));

		return true;
	}

}



pragma solidity ^0.4.21;


contract WorkerPoolHub is OwnableOZ // is Owned by IexecHub
{

	using SafeMathOZ for uint256;

	/**
	 * Members
	 */
	// worker => workerPool
	mapping(address => address)                     m_workerAffectation;
	// owner => index
	mapping(address => uint256)                     m_workerPoolCountByOwner;
	// owner => index => workerPool
	mapping(address => mapping(uint256 => address)) m_workerPoolByOwnerByIndex;
	//  workerPool => owner // stored in the workerPool
	/* mapping(address => address)                     m_ownerByWorkerPool; */
	mapping(address => bool)                        m_workerPoolRegistered;

	mapping(uint256 => address)                     m_workerPoolByIndex;
	uint256 public                                  m_totalWorkerPoolCount;



	/**
	 * Constructor
	 */
	function WorkerPoolHub() public
	{
	}

	/**
	 * Methods
	 */
	function isWorkerPoolRegistered(address _workerPool) public view returns (bool)
	{
		return m_workerPoolRegistered[_workerPool];
	}
	function getWorkerPoolsCount(address _owner) public view returns (uint256)
	{
		return m_workerPoolCountByOwner[_owner];
	}
	function getWorkerPool(address _owner, uint256 _index) public view returns (address)
	{
		return m_workerPoolByOwnerByIndex[_owner][_index];
	}
	function getWorkerPoolByIndex(uint256 _index) public view returns (address)
	{
		return m_workerPoolByIndex[_index];
	}
	function getWorkerAffectation(address _worker) public view returns (address workerPool)
	{
		return m_workerAffectation[_worker];
	}

	function addWorkerPool(address _owner, address _workerPool) internal
	{
		uint id = m_workerPoolCountByOwner[_owner].add(1);
		m_totalWorkerPoolCount = m_totalWorkerPoolCount.add(1);
		m_workerPoolByIndex       [m_totalWorkerPoolCount] = _workerPool;
		m_workerPoolCountByOwner  [_owner]                 = id;
		m_workerPoolByOwnerByIndex[_owner][id]             = _workerPool;
		m_workerPoolRegistered    [_workerPool]            = true;
	}

	function createWorkerPool(
		string _description,
		uint256 _subscriptionLockStakePolicy,
		uint256 _subscriptionMinimumStakePolicy,
		uint256 _subscriptionMinimumScorePolicy,
		address _marketplaceAddress)
	external onlyOwner /*owner == IexecHub*/ returns (address createdWorkerPool)
	{
		// tx.origin == owner
		// msg.sender == IexecHub
		// At creating ownership is transfered to tx.origin
		address newWorkerPool = new WorkerPool(
			msg.sender, // iexecHubAddress
			_description,
			_subscriptionLockStakePolicy,
			_subscriptionMinimumStakePolicy,
			_subscriptionMinimumScorePolicy,
			_marketplaceAddress
		);
		addWorkerPool(tx.origin, newWorkerPool);
		return newWorkerPool;
	}

	function registerWorkerAffectation(address _workerPool, address _worker) public onlyOwner /*owner == IexecHub*/ returns (bool subscribed)
	{
		// you must have no cuurent affectation on others worker Pool
		require(m_workerAffectation[_worker] == address(0));
		m_workerAffectation[_worker] = _workerPool;
		return true;
	}

	function unregisterWorkerAffectation(address _workerPool, address _worker) public onlyOwner /*owner == IexecHub*/ returns (bool unsubscribed)
	{
		require(m_workerAffectation[_worker] == _workerPool);
		m_workerAffectation[_worker] = address(0);
		return true;
	}
}