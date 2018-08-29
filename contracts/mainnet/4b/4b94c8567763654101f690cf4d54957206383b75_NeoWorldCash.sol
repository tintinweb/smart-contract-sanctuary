pragma solidity 0.4.21;

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Ownable {
	event Pause();
	event Unpause();

	bool public paused = false;


	/**
	 * @dev modifier to allow actions only when the contract IS paused
	 */
	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	/**
	 * @dev modifier to allow actions only when the contract IS NOT paused
	 */
	modifier whenPaused {
		require(paused);
		_;
	}

	/**
	 * @dev called by the owner to pause, triggers stopped state
	 */
	function pause() onlyOwner whenNotPaused public returns (bool) {
		paused = true;
		emit Pause();
		return true;
	}

	/**
	 * @dev called by the owner to unpause, returns to normal state
	 */
	function unpause() onlyOwner whenPaused public returns (bool) {
		paused = false;
		emit Unpause();
		return true;
	}
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

library ContractLib {
	//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
	function isContract(address _addr) internal view returns (bool) {
		uint length;
		assembly {
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}
		return (length>0);
	}
}

/*
* Contract that is working with ERC223 tokens
*/
 
contract ContractReceiver {
	function tokenFallback(address _from, uint _value, bytes _data) public pure;
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
	function totalSupply() public constant returns (uint);
	function balanceOf(address tokenOwner) public constant returns (uint);
	function allowance(address tokenOwner, address spender) public constant returns (uint);
	function transfer(address to, uint tokens) public returns (bool);
	function approve(address spender, uint tokens) public returns (bool);
	function transferFrom(address from, address to, uint tokens) public returns (bool);

	function name() public constant returns (string);
	function symbol() public constant returns (string);
	function decimals() public constant returns (uint8);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 /**
 * ERC223 token by Dexaran
 *
 * https://github.com/Dexaran/ERC223-token-standard
 */
 

 /* New ERC223 contract interface */
 
contract ERC223 is ERC20Interface {
	function transfer(address to, uint value, bytes data) public returns (bool);
	
	event Transfer(address indexed from, address indexed to, uint tokens);
	event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

 
contract NeoWorldCash is ERC223, Pausable {

	using SafeMath for uint256;
	using ContractLib for address;

	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;
	
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;

	event Burn(address indexed from, uint256 value);
	
	// ------------------------------------------------------------------------
	// Constructor
	// ------------------------------------------------------------------------
	function NeoWorldCash() public {
		symbol = "NASH";
		name = "NEOWORLD CASH";
		decimals = 18;
		totalSupply = 100000000000 * 10**uint(decimals);
		balances[msg.sender] = totalSupply;
		emit Transfer(address(0), msg.sender, totalSupply);
	}
	
	
	// Function to access name of token .
	function name() public constant returns (string) {
		return name;
	}
	// Function to access symbol of token .
	function symbol() public constant returns (string) {
		return symbol;
	}
	// Function to access decimals of token .
	function decimals() public constant returns (uint8) {
		return decimals;
	}
	// Function to access total supply of tokens .
	function totalSupply() public constant returns (uint256) {
		return totalSupply;
	}
	
	// Function that is called when a user or another contract wants to transfer funds .
	function transfer(address _to, uint _value, bytes _data) public whenNotPaused returns (bool) {
		require(_to != 0x0);
		if(_to.isContract()) {
			return transferToContract(_to, _value, _data);
		}
		else {
			return transferToAddress(_to, _value, _data);
		}
	}
	
	// Standard function transfer similar to ERC20 transfer with no _data .
	// Added due to backwards compatibility reasons .
	function transfer(address _to, uint _value) public whenNotPaused returns (bool) {
		//standard function transfer similar to ERC20 transfer with no _data
		//added due to backwards compatibility reasons
		require(_to != 0x0);

		bytes memory empty;
		if(_to.isContract()) {
			return transferToContract(_to, _value, empty);
		}
		else {
			return transferToAddress(_to, _value, empty);
		}
	}



	//function that is called when transaction target is an address
	function transferToAddress(address _to, uint _value, bytes _data) private returns (bool) {
		balances[msg.sender] = balanceOf(msg.sender).sub(_value);
		balances[_to] = balanceOf(_to).add(_value);
		emit Transfer(msg.sender, _to, _value);
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}
	
  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
	    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
	    balances[_to] = balanceOf(_to).add(_value);
	    ContractReceiver receiver = ContractReceiver(_to);
	    receiver.tokenFallback(msg.sender, _value, _data);
	    emit Transfer(msg.sender, _to, _value);
	    emit Transfer(msg.sender, _to, _value, _data);
	    return true;
	}
	
	function balanceOf(address _owner) public constant returns (uint) {
		return balances[_owner];
	}  

	function burn(uint256 _value) public whenNotPaused returns (bool) {
		require (_value > 0); 
		require (balanceOf(msg.sender) >= _value);            // Check if the sender has enough
		balances[msg.sender] = balanceOf(msg.sender).sub(_value);                      // Subtract from the sender
		totalSupply = totalSupply.sub(_value);                                // Updates totalSupply
		emit Burn(msg.sender, _value);
		return true;
	}

	// ------------------------------------------------------------------------
	// Token owner can approve for `spender` to transferFrom(...) `tokens`
	// from the token owner&#39;s account
	//
	// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
	// recommends that there are no checks for the approval double-spend attack
	// as this should be implemented in user interfaces 
	// ------------------------------------------------------------------------
	function approve(address spender, uint tokens) public whenNotPaused returns (bool) {
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}

	function increaseApproval (address _spender, uint _addedValue) public whenNotPaused
	    returns (bool success) {
	    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
	    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	    return true;
	}

	function decreaseApproval (address _spender, uint _subtractedValue) public whenNotPaused
	    returns (bool success) {
	    uint oldValue = allowed[msg.sender][_spender];
	    if (_subtractedValue > oldValue) {
	      allowed[msg.sender][_spender] = 0;
	    } else {
	      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
	    }
	    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	    return true;
	}	

	// ------------------------------------------------------------------------
	// Transfer `tokens` from the `from` account to the `to` account
	// 
	// The calling account must already have sufficient tokens approve(...)-d
	// for spending from the `from` account and
	// - From account must have sufficient balance to transfer
	// - Spender must have sufficient allowance to transfer
	// - 0 value transfers are allowed
	// ------------------------------------------------------------------------
	function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool) {
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		balances[from] = balances[from].sub(tokens);
		balances[to] = balances[to].add(tokens);
		emit Transfer(from, to, tokens);
		return true;
	}

	// ------------------------------------------------------------------------
	// Returns the amount of tokens approved by the owner that can be
	// transferred to the spender&#39;s account
	// ------------------------------------------------------------------------
	function allowance(address tokenOwner, address spender) public constant returns (uint) {
		return allowed[tokenOwner][spender];
	}

	// ------------------------------------------------------------------------
	// Don&#39;t accept ETH
	// ------------------------------------------------------------------------
	function () public payable {
		revert();
	}

	// ------------------------------------------------------------------------
	// Owner can transfer out any accidentally sent ERC20 tokens
	// ------------------------------------------------------------------------
	function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool) {
		return ERC20Interface(tokenAddress).transfer(owner, tokens);
	}

	/* RO Token 预售 */
	/*
	预售的操作流程：
	1. 发行需要的新的ERC20 Token
	2. 将此Token的预售份额转入本合约地址
	3. 设定预售时间和价格
	4. 用户可以用过 joinPreSale 函数参加预售，卖完，逾期或者主动结束为止
	5. 管理员把预售的到的Nash转出
	MISC：因为必须制作预售页面通过MetaMask调用函数所以不存在交易所地址转账的问题。
	MISC：外部项目无法自行使用本预售功能
	*/
	address[] supportedERC20Token;
	mapping (address => bool) tokenSupported;
	mapping (address => uint256) prices;
	mapping (address => uint256) starttime;
	mapping (address => uint256) endtime;

	uint256 maxTokenCountPerTrans = 10000;
	uint256 nashInPool;

	event AddSupportedToken(
		address _address, 
		uint256 _price, 
		uint256 _startTime, 
		uint256 _endTime);

	event RemoveSupportedToken(
		address _address
	);

	function addSupportedToken(
		address _address, 
		uint256 _price, 
		uint256 _startTime, 
		uint256 _endTime
	) public onlyOwner returns (bool) {
		
		require(_address != 0x0);
		require(_address.isContract());
		require(_startTime < _endTime);
		require(_price > 0);
		require(_endTime > block.timestamp);

		for (uint256 i = 0; i < supportedERC20Token.length; i++) {
			require(supportedERC20Token[i] != _address);
		}

		supportedERC20Token.push(_address);
		tokenSupported[_address] = true;
		prices[_address] = _price;
		starttime[_address] = _startTime;
		endtime[_address] = _endTime;

		emit AddSupportedToken(_address, _price, _startTime, _endTime);

		return true;
	}

	function removeSupportedToken(address _address) public onlyOwner returns (bool) {
		require(_address != 0x0);
		uint256 length = supportedERC20Token.length;
		for (uint256 i = 0; i < length; i++) {
			if (supportedERC20Token[i] == _address) {
				if (i != length - 1) {
					supportedERC20Token[i] = supportedERC20Token[length - 1];
				}
                delete supportedERC20Token[length-1];
				supportedERC20Token.length--;

				prices[_address] = 0;
				starttime[_address] = 0;
				endtime[_address] = 0;
				tokenSupported[_address] = false;

				emit RemoveSupportedToken(_address);

				break;
			}
		}
		return true;
	}

	modifier canBuy(address _address) { 
		require(tokenSupported[_address]);
		require(block.timestamp > starttime[_address]);
		require(block.timestamp < endtime[_address]);
		_; 
	}

	function joinPreSale(address _tokenAddress, uint256 _tokenCount) public canBuy(_tokenAddress) returns (bool) {
		require(prices[_tokenAddress] > 0);
		uint256 total = _tokenCount.mul(prices[_tokenAddress]); // will not overflow here since the price will not be high
		balances[msg.sender] = balances[msg.sender].sub(total);
		nashInPool = nashInPool.add(total);

		require(ERC20Interface(_tokenAddress).transfer(msg.sender, _tokenCount));
		emit Transfer(msg.sender, this, total);

		return true;
	}

	function transferNashOut(address _to, uint256 count) public onlyOwner returns(bool) {
		require(_to != 0x0);
		nashInPool = nashInPool.sub(count);
		balances[_to] = balances[_to].add(count);

		emit Transfer(this, _to, count);

		return true;
	}

	function getSupportedTokens() public view returns (address[]) {
		return supportedERC20Token;
	}

	function getTokenStatus(address _tokenAddress) public view returns (uint256 _starttime, uint256 _endtime, uint256 _price) {
		_starttime = starttime[_tokenAddress];
		_endtime = endtime[_tokenAddress];
		_price = prices[_tokenAddress];
	}

	/* end of 预售逻辑 */

	/* 锁币逻辑 */ 
	// 此功能仅供项目组账号使用，使用后锁住自己的币且不能修改

	mapping(address => uint256) lockedBalanceTotal;
	mapping(address => uint256) lockedStartTime;
	mapping(address => uint256) unlockPeriod;
	mapping(address => uint256) unlockNumberOfCycles;

	mapping(address => uint256) lockedBalanceRemains;
	mapping(address => uint256) cyclesUnlocked;

	mapping(address => bool) addressAllowToLock;

	event Locked (address _address, uint256 _count, uint256 _starttime, uint256 _unlockPeriodInSeconds, uint256 _unlockNumberOfCycles);
	event Unlocked (address _address, uint256 _count);

	function allowToLock(address _address) public onlyOwner {
		require(_address != 0x0);
		addressAllowToLock[_address] = true;
	}

	function disallowToLock(address _address) public onlyOwner {
		require(_address != 0x0);
		addressAllowToLock[_address] = false;
	}

	function lock(uint256 _count, uint256 _starttime, uint256 _unlockPeriodInSeconds, uint256 _unlockNumberOfCycles) public returns (bool) {
		require(addressAllowToLock[msg.sender]);
		require(lockedStartTime[msg.sender] == 0);
		require(0 < _unlockNumberOfCycles && _unlockNumberOfCycles <= 10); 
		require(_unlockPeriodInSeconds > 0); 
		require(_count > 10000);
		require(_starttime > 0);

		balances[msg.sender] = balances[msg.sender].sub(_count);

		lockedBalanceTotal[msg.sender] = _count;
		lockedStartTime[msg.sender] = _starttime;
		unlockPeriod[msg.sender] = _unlockPeriodInSeconds;
		unlockNumberOfCycles[msg.sender] = _unlockNumberOfCycles;

		lockedBalanceRemains[msg.sender] = lockedBalanceTotal[msg.sender];

		emit Locked (msg.sender, _count, _starttime, _unlockPeriodInSeconds, _unlockNumberOfCycles);

		return true;
	}

	function tryUnlock() public returns (bool) {
		require(lockedBalanceRemains[msg.sender] > 0);
		uint256 cycle = (block.timestamp.sub(lockedStartTime[msg.sender])) / unlockPeriod[msg.sender];
		require(cycle > cyclesUnlocked[msg.sender]);

		if (cycle > unlockNumberOfCycles[msg.sender]) {
			cycle = unlockNumberOfCycles[msg.sender];
		}

		uint256 amount = lockedBalanceTotal[msg.sender].mul(cycle - cyclesUnlocked[msg.sender]) / unlockNumberOfCycles[msg.sender] ;
		lockedBalanceRemains[msg.sender] = lockedBalanceRemains[msg.sender].sub(amount);
		balances[msg.sender] = balances[msg.sender].add(amount);

		if (cycle == unlockNumberOfCycles[msg.sender]) {
			// cleanup
			lockedBalanceTotal[msg.sender] = 0;
			lockedStartTime[msg.sender] = 0;
			unlockPeriod[msg.sender] = 0;
			unlockNumberOfCycles[msg.sender] = 0;
			cyclesUnlocked[msg.sender] = 0;

			if (lockedBalanceRemains[msg.sender] > 0) {
				balances[msg.sender] = balances[msg.sender].add(lockedBalanceRemains[msg.sender]);
				lockedBalanceRemains[msg.sender] = 0;
			}

		}
		else {
			cyclesUnlocked[msg.sender] = cycle;
		}

		emit Unlocked(msg.sender, amount);

		return true;
	}

	function getLockStatus(address _address) public view returns (
		uint256 _lockTotal, 
		uint256 _starttime, 
		uint256 _unlockPeriodInSeconds,
		uint256 _unlockNumberOfCycles,
		uint256 _lockedBalanceRemains,
		uint256 _cyclesUnlocked 
		 ) {

		_lockTotal = lockedBalanceTotal[_address];
		_starttime = lockedStartTime[_address];
		_unlockPeriodInSeconds = unlockPeriod[_address];
		_unlockNumberOfCycles = unlockNumberOfCycles[_address];
		_lockedBalanceRemains = lockedBalanceRemains[_address];
		_cyclesUnlocked = cyclesUnlocked[_address];

	}

}