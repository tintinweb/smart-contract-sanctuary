pragma solidity ^0.4.21;

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library IterableMapping
{
  struct itmap
  {
    mapping(address => IndexValue) data;
    KeyFlag[] keys;
    uint size;
  }
  struct IndexValue { uint keyIndex; uint256 value; }
  struct KeyFlag { address key; bool deleted; }
  function insert(itmap storage self, address key, uint256 value) returns (bool replaced)
  {
    uint keyIndex = self.data[key].keyIndex;
    self.data[key].value = value;
    if (keyIndex > 0)
      return true;
    else
    {
      keyIndex = self.keys.length++;
      self.data[key].keyIndex = keyIndex + 1;
      self.keys[keyIndex].key = key;
      self.size++;
      return false;
    }
  }
  function remove(itmap storage self, address key) returns (bool success)
  {
    uint keyIndex = self.data[key].keyIndex;
    if (keyIndex == 0)
      return false;
    delete self.data[key];
    self.keys[keyIndex - 1].deleted = true;
    self.size --;
  }
  function contains(itmap storage self, address key) returns (bool)
  {
    return self.data[key].keyIndex > 0;
  }
  function iterate_start(itmap storage self) returns (uint keyIndex)
  {
    return iterate_next(self, uint(-1));
  }
  function iterate_valid(itmap storage self, uint keyIndex) returns (bool)
  {
    return keyIndex < self.keys.length;
  }
  function iterate_next(itmap storage self, uint keyIndex) returns (uint r_keyIndex)
  {
    keyIndex++;
    while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
      keyIndex++;
    return keyIndex;
  }
  function iterate_get(itmap storage self, uint keyIndex) returns (address key, uint256 value)
  {
    key = self.keys[keyIndex].key;
    value = self.data[key].value;
  }
}



contract ExhibationLinkingCoin is ERC20Interface {
	

	function totalSupply()public constant returns (uint) {
		return totalEXLCSupply;
	}
	
	function balanceOf(address tokenOwner)public constant returns (uint balance) {
		return balances[tokenOwner];
	}

	function transfer(address to, uint tokens)public returns (bool success) {
		if (balances[msg.sender] >= tokens && tokens > 0 && balances[to] + tokens > balances[to]) {
            if(lockedUsers[msg.sender].lockedTokens > 0){
                TryUnLockBalance(msg.sender);
                if(balances[msg.sender] - tokens < lockedUsers[msg.sender].lockedTokens)
                {
                    return false;
                }
            }
            
			balances[msg.sender] -= tokens;
			balances[to] += tokens;
			emit Transfer(msg.sender, to, tokens);
			return true;
		} else {
			return false;
		}
	}
	

	function transferFrom(address from, address to, uint tokens)public returns (bool success) {
		if (balances[from] >= tokens && allowed[from].data[to].value >= tokens && tokens > 0 && balances[to] + tokens > balances[to]) {
            if(lockedUsers[from].lockedTokens > 0)
            {
                TryUnLockBalance(from);
                if(balances[from] - tokens < lockedUsers[from].lockedTokens)
                {
                    return false;
                }
            }
            
			balances[from] -= tokens;
			allowed[from].data[msg.sender].value -= tokens;
			balances[to] += tokens;
			return true;
		} else {
			return false;
		}
	}
	
	
	function approve(address spender, uint tokens)public returns (bool success) {
	    IterableMapping.insert(allowed[msg.sender], spender, tokens);
		return true;
	}
	
	function allowance(address tokenOwner, address spender)public constant returns (uint remaining) {
		return allowed[tokenOwner].data[spender].value;
	}
	
		
    string public name = "ExhibationLinkingCoin";
    string public symbol = "EXLC";
    uint8 public decimals = 18;
	uint256 private totalEXLCSupply = 10000000000000000000000000000;
	uint256 private _totalBalance = totalEXLCSupply;
	
	struct LockUser{
	    uint256 lockedTokens;
	    uint lockedTime;
	    uint lockedIdx;
	}
	
	
	address public owner = 0x0;
	address public auther_user = 0x0;
	address public operater = 0x0;
	
    mapping (address => uint256) balances;
    mapping(address => IterableMapping.itmap) allowed;

	mapping(address => LockUser) lockedUsers;
	
	
 	uint  constant    private ONE_DAY_TIME_LEN = 86400;
 	uint  constant    private ONE_YEAR_TIME_LEN = 946080000;
	uint32 private constant MAX_UINT32 = 0xFFFFFFFF;
	

	uint256   public creatorsTotalBalance =    1130000000000000000000000000; 
	uint256   public jiGouTotalBalance =       1000000000000000000000000000;
	uint256   public icoTotalBalance =         1000000000000000000000000000;
	uint256   public mineTotalBalance =        2000000000000000000000000000;
	uint256   public marketorsTotalBalance =   685000000000000000000000000;
	uint256   public businessersTotalBalance = 685000000000000000000000000;
	uint256   public taskTotalBalance =        3500000000000000000000000000;

	uint256   public mineBalance = 0;
	
	bool public isIcoStart = false;	
	bool public isIcoFinished = false;
	uint256 public icoPrice = 500000000000000000000000;

	
	
	uint256[] public mineBalanceArry = new uint256[](30); 
	uint      public lastUnlockMineBalanceTime = 0;
	uint public dayIdx = 0;
	
	event SendTo(uint32 indexed _idx, uint8 indexed _type, address _from, address _to, uint256 _value);
	
	uint32 sendToIdx = 0;
	
	function safeToNextIdx() internal{
        if (sendToIdx >= MAX_UINT32){
			sendToIdx = 1;
		}
        else{
			sendToIdx += 1;
		}
    }

    constructor() public {
		owner = msg.sender;
		mineBalanceArry[0] = 1000000000000000000000000;
		for(uint i=1; i<30; i++){
			mineBalanceArry[i] = mineBalanceArry[i-1] * 99 / 100;
		}
		mineBalance = taskTotalBalance;
		balances[owner] = mineBalance;
		lastUnlockMineBalanceTime = block.timestamp;
    }
	
	
	function StartIco() public {
		if ((msg.sender != operater && msg.sender != auther_user && msg.sender != owner) || isIcoStart) 
		{
		    revert();
		}
		
		isIcoStart = true;
		isIcoFinished = false;		
	}
	
	function StopIco() public {
		if ((msg.sender != operater && msg.sender != auther_user && msg.sender != owner) || isIcoFinished) 
		{
		    revert();
		}
		
		balances[owner] += icoTotalBalance;
		icoTotalBalance = 0;
		
		isIcoStart = false;
		isIcoFinished = true;
	}
	
	function () public payable
    {
		uint256 coin;
		
			if(isIcoFinished || !isIcoStart)
			{
				revert();
			}
		
			coin = msg.value * icoPrice / 1 ether;
			if(coin > icoTotalBalance)
			{
				revert();
			}

			icoTotalBalance -= coin;
			_totalBalance -= coin;
			balances[msg.sender] += coin;
			
			emit Transfer(operater, msg.sender, coin);
			
			safeToNextIdx();
			emit SendTo(sendToIdx, 2, 0x0, msg.sender, coin);
		
    }

	
	function TryUnLockBalance(address target) public {
	    if(target == 0x0)
	    {
	        revert();
	    }
	    LockUser storage user = lockedUsers[target];
	    if(user.lockedIdx > 0 && user.lockedTokens > 0)
	    {
	        if(block.timestamp >= user.lockedTime)
	        {
	            if(user.lockedIdx == 1)
	            {
	                user.lockedIdx = 0;
	                user.lockedTokens = 0;
	            }
	            else
	            {
	                uint256 append = user.lockedTokens/user.lockedIdx;
	                user.lockedTokens -= append;
        			user.lockedIdx--;
        			user.lockedTime = block.timestamp + ONE_YEAR_TIME_LEN;
        			lockedUsers[target] = user;
	            }
	        }
	    }
		
	}
	
	function QueryUnlockTime(address target) public constant returns (uint time) {
	    if(target == 0x0)
	    {
	        revert();
	    }
	    LockUser storage user = lockedUsers[target];
	    if(user.lockedIdx > 0 && user.lockedTokens > 0)
	    {
	        return user.lockedTime;
	    }
	    return 0x0;
	}
	

	function miningEveryDay() public{
		if (msg.sender != operater && msg.sender != auther_user && msg.sender != owner) 
		{
		    revert();
		}
		uint day = uint((block.timestamp - lastUnlockMineBalanceTime) / ONE_DAY_TIME_LEN);
		if(day > 0){
			int max_while = 30;
			uint256 val;
			while(day > 0 && max_while > 0 && mineTotalBalance > 0){
				max_while--;
				day -= 1;
				dayIdx += 1;
				val = mineBalanceArry[(dayIdx/365) % 30];
				if(mineTotalBalance >= val)
				{
					mineBalance += val;
					mineTotalBalance -= val;
					balances[owner] += val;
				}
				else
				{
					mineBalance += mineTotalBalance;
					mineTotalBalance = 0;
					balances[owner] += mineTotalBalance;
					break;
				}
			}
			lastUnlockMineBalanceTime = block.timestamp;
		}
	}

	
	function sendMinerByOwner(address _to, uint256 _value) public {
	
		if (msg.sender != operater && msg.sender != auther_user && msg.sender != owner) 
		{
		    revert();
		}
		
		if(_to == 0x0){
			revert();
		}
		
		
		if(_value > mineBalance){
			revert();
		}
		
		
		mineBalance -= _value;
		balances[owner] -= _value;
		balances[_to] += _value;
		_totalBalance -= _value;
		
		emit Transfer(msg.sender, _to, _value);
		
		safeToNextIdx();
		emit SendTo(sendToIdx, 3, owner, _to, _value);
	}

	function sendICOByOwner(address _to, uint256 _value) public {
		if (msg.sender != operater && msg.sender != owner && msg.sender != auther_user) 
		{
		    revert();
		}
		
		if(_to == 0x0){
			revert();
		}
		
		if(!isIcoFinished && isIcoStart)
		{
			revert();
		}		

		if(_value > icoTotalBalance){
			revert();
		}

		icoTotalBalance -= _value;
		_totalBalance -= _value;
		balances[_to] += _value;
			
		emit Transfer(msg.sender, _to, _value);
			
		safeToNextIdx();
		emit SendTo(sendToIdx, 6, 0x0, _to, _value);
	
	}
	
	function sendCreatorByOwner(address _to, uint256 _value) public {
		if (msg.sender != operater && msg.sender != owner && msg.sender != auther_user) 
		{
		    revert();
		}
		
		if(_to == 0x0){
			revert();
		}
		
		if(_value > creatorsTotalBalance){
			revert();
		}
		
		
		creatorsTotalBalance -= _value;
		_totalBalance -= _value;
		balances[_to] += _value;
		LockUser storage lockUser = lockedUsers[_to];
		lockUser.lockedTime = block.timestamp + ONE_YEAR_TIME_LEN;
		lockUser.lockedTokens += _value;
		lockUser.lockedIdx = 2;

        lockedUsers[_to] = lockUser;
		
		emit Transfer(msg.sender, _to, _value);
		
		safeToNextIdx();
		emit SendTo(sendToIdx, 4, 0x0, _to, _value);
	}

	function sendJigouByOwner(address _to, uint256 _value) public {
		if (msg.sender != operater && msg.sender != owner && msg.sender != auther_user) 
		{
		    revert();
		}
		
		if(_to == 0x0){
			revert();
		}
		
		if(_value > jiGouTotalBalance){
			revert();
		}
		
		
		jiGouTotalBalance -= _value;
		_totalBalance -= _value;
		balances[_to] += _value;
		LockUser storage lockUser = lockedUsers[_to];
		lockUser.lockedTime = block.timestamp + ONE_YEAR_TIME_LEN;
		lockUser.lockedTokens += _value;
		lockUser.lockedIdx = 1;

        lockedUsers[_to] = lockUser;
		
		emit Transfer(msg.sender, _to, _value);
		
		safeToNextIdx();
		emit SendTo(sendToIdx, 4, 0x0, _to, _value);
	}
	
	function sendMarketByOwner(address _to, uint256 _value) public {
	
		if (msg.sender != operater && msg.sender != owner && msg.sender != auther_user) 
		{
		    revert();
		}
		
		if(_to == 0x0){
			revert();
		}
		
		if(_value > marketorsTotalBalance){
			revert();
		}
		
		
		marketorsTotalBalance -= _value;
		_totalBalance -= _value;
		balances[_to] += _value;
		
		emit Transfer(msg.sender, _to, _value);
		
		safeToNextIdx();
		emit SendTo(sendToIdx, 7, 0x0, _to, _value);
	}
	

	function sendBussinessByOwner(address _to, uint256 _value) public {
	
		if (msg.sender != operater && msg.sender != owner && msg.sender != auther_user) 
		{
		    revert();
		}
		
		if(_to == 0x0){
			revert();
		}
		
		if(_value > businessersTotalBalance){
			revert();
		}
		
		
		businessersTotalBalance -= _value;
		_totalBalance -= _value;
		balances[_to] += _value;
		
		emit Transfer(msg.sender, _to, _value);
		
		safeToNextIdx();
		emit SendTo(sendToIdx, 5, 0x0, _to, _value);
	}
	
	function Save() public {
		if (msg.sender != owner) {
		    revert();
		}
		owner.transfer(address(this).balance);
    }
	
	
	function changeAutherOwner(address newOwner) public {
		if ((msg.sender != owner && msg.sender != auther_user) || newOwner == 0x0) 
		{
		    revert();
		}
		else
		{
		    if(msg.sender != owner)
		    {
		        balances[msg.sender] = balances[owner];
		        for (var i = IterableMapping.iterate_start(allowed[owner]); IterableMapping.iterate_valid(allowed[owner], i); i = IterableMapping.iterate_next(allowed[owner], i))
                {
                    var (key, value) = IterableMapping.iterate_get(allowed[owner], i);
                    IterableMapping.insert(allowed[msg.sender], key, value);
                }
			    balances[owner] = 0;
			    for (var j = IterableMapping.iterate_start(allowed[owner]); IterableMapping.iterate_valid(allowed[owner], j); j = IterableMapping.iterate_next(allowed[owner], j))
                {
                    var (key2, value2) = IterableMapping.iterate_get(allowed[owner], j);
                    IterableMapping.remove(allowed[owner], key2);
                }
		    }
			
			auther_user = newOwner;
			owner = msg.sender;
		}
    }
	
	function destruct() public {
		if (msg.sender != owner) 
		{
		    revert();
		}
		else
		{
			selfdestruct(owner);
		}
    }
	
	function setOperater(address op) public {
		if ((msg.sender != owner && msg.sender != auther_user && msg.sender != operater) || op == 0x0) 
		{
		    revert();
		}
		else
		{
			operater = op;
		}
    }
}