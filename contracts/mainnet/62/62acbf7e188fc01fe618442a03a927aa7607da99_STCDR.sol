pragma solidity ^0.4.23;

contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  // mitigate short address attack
  // thanks to https://github.com/numerai/contract/blob/c182465f82e50ced8dacb3977ec374a892f5fa8c/contracts/Safe.sol#L30-L34.
  modifier onlyPayloadSize(uint numWords) {
     assert(msg.data.length >= numWords * 32 + 4);
     _;
  }
}

// ERC20 standard
contract Token {
    function balanceOf(address _owner) public  view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function approve(address _spender, uint256 _value)  public returns (bool success);
    function allowance(address _owner, address _spender) public  view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token, SafeMath {
    uint256 public totalSupply;

    function transfer(address _to, uint256 _value) public  onlyPayloadSize(2) returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // To change the approve amount you first have to reduce the addresses&#39;
    //  allowance to zero by calling &#39;approve(_spender, 0)&#39; if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success) {
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        emit Approval(msg.sender, _spender, _newValue);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
}

contract STCDR is StandardToken {
	string public name = "STCDR";
	string public symbol = "STCDR";
	uint256 public decimals = 8;
	string public version = "1.0";
	uint256 public tokenCap = 1000000000 * 10**8;
	uint256 public tokenBurned = 0;
	uint256 public tokenAllocated = 0;
  // root control
	address public fundWallet;
	// maps addresses
  mapping (address => bool) public whitelist;

	event Whitelist(address indexed participant);

  modifier onlyWhitelist {
		require(whitelist[msg.sender]);
		_;
	}
	modifier onlyFundWallet {
		require(msg.sender == fundWallet);
		_;
	}

	constructor() public  {
		fundWallet = msg.sender;
		whitelist[fundWallet] = true;
	}

	function setTokens(address participant, uint256  amountTokens) private {
		uint256 thisamountTokens = amountTokens;
		uint256 newtokenAllocated =  safeAdd(tokenAllocated, thisamountTokens);

    if(newtokenAllocated > tokenCap){
			thisamountTokens = safeSub(tokenCap,thisamountTokens);
			newtokenAllocated = safeAdd(tokenAllocated, thisamountTokens);
		}

		require(newtokenAllocated <= tokenCap);

		tokenAllocated = newtokenAllocated;
		whitelist[participant] = true;
		balances[participant] = safeAdd(balances[participant], thisamountTokens);
	}

	function allocateTokens(address participant, uint256  amountTokens, address recommended) external onlyFundWallet  {
		setTokens(participant, amountTokens);

		if (recommended != participant)	{
      require(whitelist[recommended]);
      setTokens(recommended, amountTokens);
    }
	}

	function burnTokens(address participant, uint256  amountTokens) external onlyFundWallet  {
		uint256 newTokValue = amountTokens;
		address thisparticipant = participant;

		if (balances[thisparticipant] < newTokValue) {
      newTokValue = balances[thisparticipant];
    }

		uint256 newtokenBurned = safeAdd(tokenBurned, newTokValue);
		require(newtokenBurned <= tokenCap);
		tokenBurned = newtokenBurned;
		balances[thisparticipant] = safeSub(balances[thisparticipant], newTokValue);
	}

	function burnMyTokens(uint256 amountTokens) external onlyWhitelist  {
		uint256 newTokValue = amountTokens;
		address thisparticipant = msg.sender;

    if (balances[thisparticipant] < newTokValue) {
      newTokValue = balances[thisparticipant];
    }

		uint256 newtokenBurned = safeAdd(tokenBurned, newTokValue);
		require(newtokenBurned <= tokenCap);
		tokenBurned = newtokenBurned;
		balances[msg.sender] = safeSub(balances[thisparticipant],newTokValue );
	}

  function buy() external payable {
		buyTo(msg.sender);
	}

  function buyTo(address participant) public payable onlyWhitelist {
		require(false);
	}

  function changeFundWallet(address newFundWallet) external onlyFundWallet {
		require(newFundWallet != address(0));
		fundWallet = newFundWallet;
	}

  // prevent transfers until trading allowed
	function transfer(address _to, uint256 _value) public returns (bool success) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		return super.transferFrom(_from, _to, _value);
	}
}