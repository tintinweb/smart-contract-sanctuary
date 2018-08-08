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

contract UNIT is ERC20,Ownable{
	using SafeMath for uint256;

	//the base info of the token
	string public constant name="Unit Pay";
	string public constant symbol="UNIT";
	string public constant version = "1.0";
	uint256 public constant decimals = 18;

	uint256 public constant MAX_PRIVATE_FUNDING_SUPPLY=600000000*10**decimals;

	uint256 public constant COOPERATE_REWARD=300000000*10**decimals;

	uint256 public constant COMMON_WITHDRAW_SUPPLY=MAX_PRIVATE_FUNDING_SUPPLY+COOPERATE_REWARD;

	uint256 public constant PARTNER_SUPPLY=600000000*10**decimals;

	uint256 public constant MAX_PUBLIC_FUNDING_SUPPLY=150000000*10**decimals;

	uint256 public constant TEAM_KEEPING=1350000000*10**decimals;

	uint256 public constant MAX_SUPPLY=COMMON_WITHDRAW_SUPPLY+PARTNER_SUPPLY+MAX_PUBLIC_FUNDING_SUPPLY+TEAM_KEEPING;

	uint256 public rate;

	mapping(address=>uint256) public publicFundingWhiteList;
	

	uint256 public totalCommonWithdrawSupply;

	uint256 public totalPartnerWithdrawSupply;

	uint256 public totalPublicFundingSupply;

	uint256 public startTime;
	uint256 public endTime;

	uint256 public constant TEAM_UNFREEZE=270000000*10**decimals;
	bool public hasOneStepWithdraw;
	bool public hasTwoStepWithdraw;
	bool public hasThreeStepWithdraw;
	bool public hasFourStepWithdraw;
	bool public hasFiveStepWithdraw;	
	
    struct epoch  {
        uint256 lockEndTime;
        uint256 lockAmount;
    }

    mapping(address=>epoch[]) public lockEpochsMap;
	 
    mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	

	function UNIT(){
		totalSupply = 0 ;
		totalCommonWithdrawSupply=0;
		totalPartnerWithdrawSupply=0;
		totalPublicFundingSupply = 0;

		startTime = 1525104000;
		endTime = 1525104000;
		rate=80000;


		hasOneStepWithdraw=false;
		hasTwoStepWithdraw=false;
		hasThreeStepWithdraw=false;
		hasFourStepWithdraw=false;
		hasFiveStepWithdraw=false;
	}

	event CreateUNIT(address indexed _to, uint256 _value);


	modifier notReachTotalSupply(uint256 _value,uint256 _rate){
		assert(MAX_SUPPLY>=totalSupply.add(_value.mul(_rate)));
		_;
	}

	modifier notReachPublicFundingSupply(uint256 _value,uint256 _rate){
		assert(MAX_PUBLIC_FUNDING_SUPPLY>=totalPublicFundingSupply.add(_value.mul(_rate)));
		_;
	}

	modifier notReachCommonWithdrawSupply(uint256 _value,uint256 _rate){
		assert(COMMON_WITHDRAW_SUPPLY>=totalCommonWithdrawSupply.add(_value.mul(_rate)));
		_;
	}


	modifier notReachPartnerWithdrawSupply(uint256 _value,uint256 _rate){
		assert(PARTNER_SUPPLY>=totalPartnerWithdrawSupply.add(_value.mul(_rate)));
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
	function etherProceeds() external
		onlyOwner

	{
		if(!msg.sender.send(this.balance)) revert();
	}

	function processFunding(address receiver,uint256 _value,uint256 _rate) internal
		notReachTotalSupply(_value,_rate)
	{
		uint256 amount=_value.mul(_rate);
		totalSupply=totalSupply.add(amount);
		balances[receiver] +=amount;
		CreateUNIT(receiver,amount);
		Transfer(0x0, receiver, amount);
	}

	function commonWithdraw(uint256 _value) external
		onlyOwner
		notReachCommonWithdrawSupply(_value,1)

	{
		processFunding(msg.sender,_value,1);
		totalCommonWithdrawSupply=totalCommonWithdrawSupply.add(_value);
	}

	function withdrawToPartner(address _to,uint256 _value) external
		onlyOwner
		notReachPartnerWithdrawSupply(_value,1)
	{
		processFunding(_to,_value,1);
		totalPartnerWithdrawSupply=totalPartnerWithdrawSupply.add(_value);
		lockBalance(_to,_value,1541865600);
	}

	function () payable external
		notBeforeTime(startTime)
		notAfterTime(endTime)
		notReachPublicFundingSupply(msg.value,rate)
	{
		require(publicFundingWhiteList[msg.sender]==1);

		processFunding(msg.sender,msg.value,rate);
		uint256 amount=msg.value.mul(rate);
		totalPublicFundingSupply = totalPublicFundingSupply.add(amount);

	}


	function withdrawForOneStep() external
		onlyOwner
		assertFalse(hasOneStepWithdraw)
		notBeforeTime(1525968000)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		hasOneStepWithdraw = true;
	}

	//20181111
	function withdrawForTwoStep() external
		onlyOwner
		assertFalse(hasTwoStepWithdraw)
		notBeforeTime(1541865600)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		hasTwoStepWithdraw = true;
	}

	//20190511
	function withdrawForThreeStep() external
		onlyOwner
		assertFalse(hasThreeStepWithdraw)
		notBeforeTime(1557504000)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		hasThreeStepWithdraw = true;
	}

	//20191111
	function withdrawForFourStep() external
		onlyOwner
		assertFalse(hasFourStepWithdraw)
		notBeforeTime(1573401600)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		hasFourStepWithdraw = true;
	}

	//20200511
	function withdrawForFiveStep() external
		onlyOwner
		assertFalse(hasFiveStepWithdraw)
		notBeforeTime(1589126400)
	{
		processFunding(msg.sender,TEAM_UNFREEZE,1);
		hasFiveStepWithdraw = true;
	}			


  	function transfer(address _to, uint256 _value) public  returns (bool)
 	{
		require(_to != address(0));

		epoch[] epochs = lockEpochsMap[msg.sender];
		uint256 needLockBalance = 0;
		for(uint256 i = 0;i<epochs.length;i++)
		{
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


  	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
  	{
		require(_to != address(0));

		epoch[] epochs = lockEpochsMap[_from];
		uint256 needLockBalance = 0;
		for(uint256 i = 0;i<epochs.length;i++)
		{
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

	function lockBalance(address user, uint256 lockAmount,uint256 lockEndTime) internal
	{
		 epoch[] storage epochs = lockEpochsMap[user];
		 epochs.push(epoch(lockEndTime,lockAmount));
	}

    function addPublicFundingWhiteList(address[] _list) external
    	onlyOwner
    {
        uint256 count = _list.length;
        for (uint256 i = 0; i < count; i++) {
        	publicFundingWhiteList[_list [i]] = 1;
        }    	
    }

	function refreshRate(uint256 _rate) external
		onlyOwner
	{
		rate=_rate;
	}
	
    function refreshPublicFundingTime(uint256 _startTime,uint256 _endTime) external
        onlyOwner
    {
		startTime=_startTime;
		endTime=_endTime;
    }

	  
}