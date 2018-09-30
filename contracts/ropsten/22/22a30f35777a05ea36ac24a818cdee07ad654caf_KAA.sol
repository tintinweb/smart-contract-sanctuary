pragma solidity ^0.4.24;


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


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

contract KAA is ERC20,Pausable{
	using SafeMath for uint256;

	//the base info of the token
	string public constant name="KAA";
	string public constant symbol="KAA";
	string public constant version = "1.0";
	uint256 public constant decimals = 18;



	//平台基金13395000000
	uint256 public constant PLATFORM_FUNDING_SUPPLY=13395000000*10**decimals;


	//创始团队13395000000
	uint256 public constant TEAM_KEEPING=13395000000*10**decimals;

	//战略伙伴8037000000	
	uint256 public constant COOPERATE_REWARD=8037000000*10**decimals;

	//分享奖励8930000000
	uint256 public constant SHARDING_REWARD=8930000000*10**decimals;

	//挖矿奖励45543000000
	uint256 public constant MINING_REWARD=45543000000*10**decimals;

	//可普通提现额度8930000000+45543000000=54473000000
	uint256 public constant COMMON_WITHDRAW_SUPPLY=SHARDING_REWARD+MINING_REWARD;


	//总发行54473000000+13395000000+13395000000+8037000000=89300000000
	uint256 public constant MAX_SUPPLY=COMMON_WITHDRAW_SUPPLY+PLATFORM_FUNDING_SUPPLY+TEAM_KEEPING+COOPERATE_REWARD;

	//内部锁仓基准时间
	uint256 public innerlockStartTime;
	//外部锁仓基准时间
	uint256 public outterlockStartTime;
	//解锁步长（30天）
	uint256 public unlockStepLong;

	//平台已提现
	uint256 public platformFundingSupply;
	//平台每期可提现
	uint256 public platformFundingPerEpoch;

	//团队已提现
	uint256 public teamKeepingSupply;
	//团队每期可提现
	uint256 public teamKeepingPerEpoch;

	//战略伙伴已经分发额度
	uint256 public cooperateRewardSupply;


	//已经普通提现量
	uint256 public totalCommonWithdrawSupply;

    //战略伙伴锁仓总额度
    mapping(address=>uint256) public lockAmount;
	 
	//ERC20的余额
    mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	

     constructor() public{
		totalSupply = 0 ;

		platformFundingSupply=0;
		teamKeepingSupply=0;
		cooperateRewardSupply=0;
		totalCommonWithdrawSupply=0;

		//分12期解锁 13395000000/12
		platformFundingPerEpoch=1116250000*10**decimals;
		teamKeepingPerEpoch=1116250000*10**decimals;


		//初始时间 20210818
		innerlockStartTime = 1629216000;
		//初始时间 20190818
		outterlockStartTime=1566057600;

		unlockStepLong=2592000;

	}

	event CreateKAA(address indexed _to, uint256 _value);


	modifier notReachTotalSupply(uint256 _value){
		assert(MAX_SUPPLY>=totalSupply.add(_value));
		_;
	}

	//平台最大提现额度
	modifier notReachPlatformFundingSupply(uint256 _value){
		assert(PLATFORM_FUNDING_SUPPLY>=platformFundingSupply.add(_value));
		_;
	}

	modifier notReachTeamKeepingSupply(uint256 _value){
		assert(TEAM_KEEPING>=teamKeepingSupply.add(_value));
		_;
	}


	modifier notReachCooperateRewardSupply(uint256 _value){
		assert(COOPERATE_REWARD>=cooperateRewardSupply.add(_value));
		_;
	}

	modifier notReachCommonWithdrawSupply(uint256 _value){
		assert(COMMON_WITHDRAW_SUPPLY>=totalCommonWithdrawSupply.add(_value));
		_;
	}



	//统一代币分发函数，内部使用
	function processFunding(address receiver,uint256 _value) internal
		notReachTotalSupply(_value)
	{
		totalSupply=totalSupply.add(_value);
		balances[receiver]=balances[receiver].add(_value);
		emit CreateKAA(receiver,_value);
		emit Transfer(0x0, receiver, _value);
	}



	//普通分发,给分享和挖矿使用
	function commonWithdraw(uint256 _value) external
		onlyOwner
		notReachCommonWithdrawSupply(_value)

	{
		processFunding(msg.sender,_value);
		//增加已经普通提现份额
		totalCommonWithdrawSupply=totalCommonWithdrawSupply.add(_value);
	}


	//平台基金提币（不持币锁仓，12期释放）
	function withdrawToPlatformFunding(uint256 _value) external
		onlyOwner
		notReachPlatformFundingSupply(_value)
	{
		//判断可提现额度是否足够
		if (!canPlatformFundingWithdraw(_value)) {
			revert();
		}else{
			processFunding(msg.sender,_value);
			//平台已提现额度
			platformFundingSupply=platformFundingSupply.add(_value);
		}

	}	

	//团队提币（不持币锁仓，12期释放）
	function withdrawToTeam(uint256 _value) external
		onlyOwner
		notReachTeamKeepingSupply(_value)	
	{
		//判断可提现额度是否足够
		if (!canTeamKeepingWithdraw(_value)) {
			revert();
		}else{
			processFunding(msg.sender,_value);
			//团队已提现额度
			teamKeepingSupply=teamKeepingSupply.add(_value);
		}
	}

	//提币给战略伙伴（持币锁仓，12期释放）
	function withdrawToCooperate(address _to,uint256 _value) external
		onlyOwner
		notReachCooperateRewardSupply(_value)
	{
		processFunding(_to,_value);
		cooperateRewardSupply=cooperateRewardSupply.add(_value);

		//记录分发份额
		lockAmount[_to]=lockAmount[_to].add(_value);
	}

	//平台是否可提现
	function canPlatformFundingWithdraw(uint256 _value)public view returns (bool) {
		//如果小于基准时间，直接返回false
		if(queryNow()<innerlockStartTime){
			return false;
		}

		//当前期数=（现时间-初始时间)/期数步长
		uint256 epoch=queryNow().sub(innerlockStartTime).div(unlockStepLong);
		//如果超出12期时间，那么就设置为12
		if (epoch>12) {
			epoch=12;
		}

		//计算已经释放额度 = 每期可提现额度*期数
		uint256 releaseAmount = platformFundingPerEpoch.mul(epoch);
		//计算可提现额度=已经释放额度-已经提现额度
		uint256 canWithdrawAmount=releaseAmount.sub(platformFundingSupply);
		if(canWithdrawAmount>=_value){
			return true;
		}else{
			return false;
		}
	}

	function canTeamKeepingWithdraw(uint256 _value)public view returns (bool) {
		//如果小于基准时间，直接返回false
		if(queryNow()<innerlockStartTime){
			return false;
		}

		//当前期数=（现时间-初始时间)/期数步长
		uint256 epoch=queryNow().sub(innerlockStartTime).div(unlockStepLong);
		//如果超出12期时间，那么就设置为12
		if (epoch>12) {
			epoch=12;
		}

		//计算已经释放额度 = 每期可提现额度*期数
		uint256 releaseAmount=teamKeepingPerEpoch.mul(epoch);
		//计算可提现额度=已经释放额度-已经提现额度
		uint256 canWithdrawAmount=releaseAmount.sub(teamKeepingSupply);
		if(canWithdrawAmount>=_value){
			return true;
		}else{
			return false;
		}
	}


	function clacCooperateNeedLockAmount(uint256 totalLockAmount)public view returns (uint256) {
		//如果小于基准时间，直接返回最大锁仓量
		if(queryNow()<outterlockStartTime){
			return totalLockAmount;
		}		
		
		//当前期数=（现时间-初始时间)/期数步长
		uint256 epoch=queryNow().sub(outterlockStartTime).div(unlockStepLong);
		//如果超出12期时间，那么就设置为12
		if (epoch>12) {
			epoch=12;
		}

		//剩余期数
		uint256 remainingEpoch=uint256(12).sub(epoch);

		//计算每期可释放转账额度（总分发额度/12）
		uint256 cooperatePerEpoch= totalLockAmount.div(12);

		//计算剩余锁仓额度（每期可释放转账额度*剩余期数）
		return cooperatePerEpoch.mul(remainingEpoch);
	}
    function queryNow() public view returns(uint256){
        return now;
    }
	function () payable external
	{
		revert();
	}



  //转账前，先校验减去转出份额后，是否大于等于锁仓份额
  	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool)
 	{
		require(_to != address(0));

		//计算锁仓份额
		uint256 needLockBalance=0;
		if (lockAmount[msg.sender]>0) {
			needLockBalance=clacCooperateNeedLockAmount(lockAmount[msg.sender]);
		}


		require(balances[msg.sender].sub(_value)>=needLockBalance);

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
  	}

  	function balanceOf(address _owner) public constant returns (uint256 balance) 
  	{
		return balances[_owner];
  	}


  //从委托人账上转出份额时，还要判断委托人的余额-转出份额是否大于等于锁仓份额
  	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) 
  	{
		require(_to != address(0));

		//计算锁仓份额
		uint256 needLockBalance=0;
		if (lockAmount[_from]>0) {
			needLockBalance=clacCooperateNeedLockAmount(lockAmount[_from]);
		}


		require(balances[_from].sub(_value)>=needLockBalance);

		uint256 _allowance = allowed[_from][msg.sender];

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
  	}

  	function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) 
  	{
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
  	}

  	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) 
  	{
		return allowed[_owner][_spender];
  	}
	  
}