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


contract BTMC is ERC20,Ownable{
	using SafeMath for uint256;

	//the base info of the token
	string public constant name="MinerCoin";
	string public constant symbol="BTMC";
	string public constant version = "1.0";
	uint256 public constant decimals = 18;

	//奖励2亿
	uint256 public constant REWARD_SUPPLY=200000000*10**decimals;
	//运营2亿
	uint256 public constant OPERATE_SUPPLY=200000000*10**decimals;

	//可普通提现额度4亿
	uint256 public constant COMMON_WITHDRAW_SUPPLY=REWARD_SUPPLY+OPERATE_SUPPLY;

	//公募5亿
	uint256 public constant MAX_FUNDING_SUPPLY=500000000*10**decimals;

	//团队持有1亿
	uint256 public constant TEAM_KEEPING=100000000*10**decimals;	

	//总发行10亿
	uint256 public constant MAX_SUPPLY=COMMON_WITHDRAW_SUPPLY+MAX_FUNDING_SUPPLY+TEAM_KEEPING;

	//已普通提现额度
	uint256 public totalCommonWithdrawSupply;

	//公募参数
	//已经公募量
	uint256 public totalFundingSupply;
	uint256 public stepOneStartTime;
	uint256 public stepTwoStartTime;
	uint256 public endTime;
	uint256 public oneStepRate;
	uint256 public twoStepRate;

	//团队每次解禁
	uint256 public constant TEAM_UNFREEZE=20000000*10**decimals;
	bool public hasOneStepWithdraw;
	bool public hasTwoStepWithdraw;
	bool public hasThreeStepWithdraw;
	bool public hasFourStepWithdraw;
	bool public hasFiveStepWithdraw;


	 
	//ERC20的余额
    mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	

	function BTMC(){
		totalCommonWithdrawSupply= 0;
		totalSupply = 0 ;
		totalFundingSupply = 0;
	

		stepOneStartTime=1520352000;
		stepTwoStartTime=1521475200;
		endTime=1524153600;

		oneStepRate=5000;
		twoStepRate=4000;

		hasOneStepWithdraw=false;
		hasTwoStepWithdraw=false;
		hasThreeStepWithdraw=false;
		hasFourStepWithdraw=false;
		hasFiveStepWithdraw=false;

	}

	event CreateBTMC(address indexed _to, uint256 _value);


	modifier notReachTotalSupply(uint256 _value,uint256 _rate){
		assert(MAX_SUPPLY>=totalSupply.add(_value.mul(_rate)));
		_;
	}

	modifier notReachFundingSupply(uint256 _value,uint256 _rate){
		assert(MAX_FUNDING_SUPPLY>=totalFundingSupply.add(_value.mul(_rate)));
		_;
	}

	modifier notReachCommonWithdrawSupply(uint256 _value,uint256 _rate){
		assert(COMMON_WITHDRAW_SUPPLY>=totalCommonWithdrawSupply.add(_value.mul(_rate)));
		_;
	}


	modifier assertFalse(bool withdrawStatus){
		assert(!withdrawStatus);
		_;
	}

	modifier notBeforeTime(uint256 targetTime){
		assert(now>targetTime);
		_;
	}

	modifier notAfterTime(uint256 targetTime){
		assert(now<=targetTime);
		_;
	}


	//owner有权限提取账户中的eth
	function etherProceeds() external
		onlyOwner

	{
		if(!msg.sender.send(this.balance)) revert();
	}


	//代币分发函数，内部使用
	function processFunding(address receiver,uint256 _value,uint256 _rate) internal
		notReachTotalSupply(_value,_rate)
	{
		uint256 amount=_value.mul(_rate);
		totalSupply=totalSupply.add(amount);
		balances[receiver] +=amount;
		CreateBTMC(receiver,amount);
		Transfer(0x0, receiver, amount);
	}

	function funding (address receiver,uint256 _value,uint256 _rate) internal 
		notReachFundingSupply(_value,_rate)
	{
		processFunding(receiver,_value,_rate);
		uint256 amount=_value.mul(_rate);
		totalFundingSupply = totalFundingSupply.add(amount);
	}
	

	function () payable external
		notBeforeTime(stepOneStartTime)
		notAfterTime(endTime)
	{
		if(now>=stepOneStartTime&&now<stepTwoStartTime){
			funding(msg.sender,msg.value,oneStepRate);
		}else if(now>=stepTwoStartTime&&now<endTime){
			funding(msg.sender,msg.value,twoStepRate);
		}else {
			revert();
		}

	}

	//普通提币
	function commonWithdraw(uint256 _value) external
		onlyOwner
		notReachCommonWithdrawSupply(_value,1)

	{
		processFunding(msg.sender,_value,1);
		//增加已经普通提现份额
		totalCommonWithdrawSupply=totalCommonWithdrawSupply.add(_value);
	}
	//20180907可提
	function withdrawForOneStep() external
		onlyOwner
		assertFalse(hasOneStepWithdraw)
		notBeforeTime(1536249600)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		//标记团队已提现
		hasOneStepWithdraw = true;
	}

	//20190307
	function withdrawForTwoStep() external
		onlyOwner
		assertFalse(hasTwoStepWithdraw)
		notBeforeTime(1551888000)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		//标记团队已提现
		hasTwoStepWithdraw = true;
	}

	//20190907
	function withdrawForThreeStep() external
		onlyOwner
		assertFalse(hasThreeStepWithdraw)
		notBeforeTime(1567785600)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		//标记团队已提现
		hasThreeStepWithdraw = true;
	}

	//20200307
	function withdrawForFourStep() external
		onlyOwner
		assertFalse(hasFourStepWithdraw)
		notBeforeTime(1583510400)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		//标记团队已提现
		hasFourStepWithdraw = true;
	}

	//20200907
	function withdrawForFiveStep() external
		onlyOwner
		assertFalse(hasFiveStepWithdraw)
		notBeforeTime(1599408000)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		//标记团队已提现
		hasFiveStepWithdraw = true;
	}			


  	function transfer(address _to, uint256 _value) public  returns (bool)
 	{
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


	function setupFundingRate(uint256 _oneStepRate,uint256 _twoStepRate) external
		onlyOwner
	{
		oneStepRate=_oneStepRate;
		twoStepRate=_twoStepRate;
	}

    function setupFundingTime(uint256 _stepOneStartTime,uint256 _stepTwoStartTime,uint256 _endTime) external
        onlyOwner
    {
		stepOneStartTime=_stepOneStartTime;
		stepTwoStartTime=_stepTwoStartTime;
		endTime=_endTime;
    }
	  
}