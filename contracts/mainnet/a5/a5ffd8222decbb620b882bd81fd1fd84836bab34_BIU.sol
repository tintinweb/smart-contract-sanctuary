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
contract BIU is ERC20,Ownable{
	using SafeMath for uint256;

	//the base info of the token
	string public constant name="BigBull";
	string public constant symbol="BIU";
	string public constant version = "1.0";
	uint256 public constant decimals = 18;

	//总发行2亿
	uint256 public constant MAX_SUPPLY=200000000*10**decimals;

	uint256 public constant INIT_SUPPLY=20000000*10**decimals;

	//公募1亿
	uint256 public constant MAX_FUNDING_SUPPLY=100000000*10**decimals;

	//已经公募量
	uint256 public totalFundingSupply;


	//1年解禁
	uint256 public constant ONE_YEAR_KEEPING=16000000*10**decimals;
	bool public hasOneYearWithdraw;

	//2年解禁
	uint256 public constant TWO_YEAR_KEEPING=16000000*10**decimals;
	bool public hasTwoYearWithdraw;

	//3年解禁
	uint256 public constant THREE_YEAR_KEEPING=16000000*10**decimals;	
	bool public hasThreeYearWithdraw;


	//4年解禁
	uint256 public constant FOUR_YEAR_KEEPING=16000000*10**decimals;	
	bool public hasFourYearWithdraw;

	//5年解禁
	uint256 public constant FIVE_YEAR_KEEPING=16000000*10**decimals;	
	bool public hasFiveYearWithdraw;


	//私募开始结束时间
	uint256 public startBlock;
	uint256 public endBlock;
	uint256 public rate;

	 
	//ERC20的余额
    mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	

	function BIU(){
		totalSupply = 0 ;
		totalFundingSupply = 0;

		hasOneYearWithdraw=false;
		hasTwoYearWithdraw=false;
		hasThreeYearWithdraw=false;
		hasFourYearWithdraw=false;
		hasFiveYearWithdraw=false;

		startBlock = 4000000;
		endBlock = 6000000;
		rate=8000;

		//初始分发
		totalSupply=INIT_SUPPLY;
		balances[msg.sender] = INIT_SUPPLY;
		Transfer(0x0, msg.sender, INIT_SUPPLY);
	}

	event CreateBIU(address indexed _to, uint256 _value);

	modifier beforeBlock(uint256 _blockNum){
		assert(getCurrentBlockNum()<_blockNum);
		_;
	}

	modifier afterBlock(uint256 _blockNum){
		assert(getCurrentBlockNum()>=_blockNum);
		_;
	}

	modifier notReachTotalSupply(uint256 _value,uint256 _rate){
		assert(MAX_SUPPLY>=totalSupply.add(_value.mul(_rate)));
		_;
	}

	modifier notReachFundingSupply(uint256 _value,uint256 _rate){
		assert(MAX_FUNDING_SUPPLY>=totalFundingSupply.add(_value.mul(_rate)));
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
		CreateBIU(receiver,amount);
		Transfer(0x0, receiver, amount);
	}




	function () payable external
		afterBlock(startBlock)
		beforeBlock(endBlock)
		notReachFundingSupply(msg.value,rate)
	{
		processFunding(msg.sender,msg.value,rate);
		uint256 amount=msg.value.mul(rate);
		totalFundingSupply = totalFundingSupply.add(amount);
	}




	//一年解禁，提到owner账户，只有未提过才能提 ,
	function withdrawForOneYear() external
		onlyOwner
		assertFalse(hasOneYearWithdraw)
		notBeforeTime(1514736000)
	{
		processFunding(msg.sender,ONE_YEAR_KEEPING,1);
		//标记团队已提现
		hasOneYearWithdraw = true;
	}

	//两年解禁，提到owner账户，只有未提过才能提
	function withdrawForTwoYear() external
		onlyOwner
		assertFalse(hasTwoYearWithdraw)
		notBeforeTime(1546272000)
	{
		processFunding(msg.sender,TWO_YEAR_KEEPING,1);
		//标记团队已提现
		hasTwoYearWithdraw = true;
	}

	//三年解禁，提到owner账户，只有未提过才能提
	function withdrawForThreeYear() external
		onlyOwner
		assertFalse(hasThreeYearWithdraw)
		notBeforeTime(1577808000)
	{
		processFunding(msg.sender,THREE_YEAR_KEEPING,1);
		//标记团队已提现
		hasThreeYearWithdraw = true;
	}


	//四年解禁，提到owner账户，只有未提过才能提
	function withdrawForFourYear() external
		onlyOwner
		assertFalse(hasFourYearWithdraw)
		notBeforeTime(1609344000)
	{
		processFunding(msg.sender,FOUR_YEAR_KEEPING,1);
		//标记团队已提现
		hasFourYearWithdraw = true;
	}


	//五年解禁，提到owner账户，只有未提过才能提
	function withdrawForFiveYear() external
		onlyOwner
		assertFalse(hasFiveYearWithdraw)
		notBeforeTime(1640880000)
	{
		processFunding(msg.sender,FIVE_YEAR_KEEPING,1);
		//标记团队已提现
		hasFiveYearWithdraw = true;
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

	function getCurrentBlockNum() internal returns (uint256)
	{
		return block.number;
	}


	function setRate(uint256 _rate) external
		onlyOwner
	{
		rate=_rate;
	}

	
    function setupFundingInfo(uint256 _startBlock,uint256 _endBlock) external
        onlyOwner
    {
		startBlock=_startBlock;
		endBlock=_endBlock;
    }
	  
}