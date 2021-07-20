/**
 *Submitted for verification at polygonscan.com on 2021-07-20
*/

pragma solidity ^0.4.24;

//import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.4/ChainlinkClient.sol";
//import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.4/vendor/Ownable.sol";


contract ZHToken{

    string public constant name = "ZHToken";
    string public constant symbol = "ZH";
    uint8 public constant decimals = 5;  
    //uint256 constant private ORACLE_PAYMENT = 1 * LINK;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    //event RequestDayFulfilled(bytes32 indexed requestId,uint256 indexed day);
    //event RequestMonthFulfilled(bytes32 indexed requestId,uint256 indexed month);


    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    //mapping(address => uint256) public lastDay;
    //mapping(address => uint256) public lastMonth;
    //mapping(address => uint) public accumulatedAmountDay;
    
    uint256 totalSupply_;
    //uint256 public currentDay;
    //uint256 public currentMonth;

    using SafeMath for uint256;


   constructor() public {  
	totalSupply_ = 0;
	//setPublicChainlinkToken();
   }
   
   function faucet(address account, uint256 amount) external {
    uint256 _amount = amount * 10**5;
    require(account != address(0), "ERC20: mint to the zero address");
    /*require(balances[account] + _amount <= 10**12, "users cannot hold more than 10 millions");
    if(lastDay[account] != currentDay || lastMonth[account] != currentMonth) {
        lastDay[account] = currentDay;
        lastMonth[account] = currentMonth;
        accumulatedAmountDay[account] = _amount;
    }
    else {
        require(accumulatedAmountDay[account] + _amount <= 10**10, "100k daily limit reached");
        accumulatedAmountDay[account] += _amount;
    }*/
    totalSupply_ += _amount;
    balances[account] += _amount;
  }

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        Transfer(owner, buyer, numTokens);
        return true;
    }
    
    /*function requestDate(address oracle, string _jobId)
    public
  {
    Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), this, this.fulfillDay.selector);
    req.add("get", "https://timezoneapi.io/api/timezone/?Europe/Paris&token=aaXbizuspzVdTBcFtmUi");
    req.add("path", "data.datetime.day");
    sendChainlinkRequestTo(oracle, req, ORACLE_PAYMENT);
    
    Chainlink.Request memory req2 = buildChainlinkRequest(stringToBytes32(_jobId), this, this.fulfillMonth.selector);
    req2.add("get", "https://timezoneapi.io/api/timezone/?Europe/Paris&token=aaXbizuspzVdTBcFtmUi");
    req2.add("path", "data.datetime.month");
    sendChainlinkRequestTo(oracle, req2, ORACLE_PAYMENT);
  }
  
  function fulfillDay(bytes32 _requestId, uint256 _day)
    public
    recordChainlinkFulfillment(_requestId)
  {
    emit RequestDayFulfilled(_requestId, _day);
    currentDay = _day;
  }
  
  function fulfillMonth(bytes32 _requestId, uint256 _month)
    public
    recordChainlinkFulfillment(_requestId)
  {
    emit RequestMonthFulfilled(_requestId, _month);
    currentMonth = _month;
  }
  
  function stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly { // solhint-disable-line no-inline-assembly
      result := mload(add(source, 32))
    }
  }*/
}

library SafeMath { 
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