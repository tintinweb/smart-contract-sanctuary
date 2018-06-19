pragma solidity 0.4.20;

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
    uint256 c = a / b;
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

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Claimable is Ownable {
  address public pendingOwner;

  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }
  
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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
 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

contract JackpotAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;
    
    function JackpotAccessControl() public {
        cfoAddress = msg.sender;
    }
    
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    function setCFO(address _newCFO) external onlyOwner {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
}

contract JackpotBase is JackpotAccessControl {
    using SafeMath for uint256;
 
    bool public gameStarted;
    
    address public gameStarter;
    address public lastPlayer;
	address public player2;
	address public player3;
	address public player4;
	address public player5;
	
    uint256 public lastWagerTimeoutTimestamp;
	uint256 public player2Timestamp;
	uint256 public player3Timestamp;
	uint256 public player4Timestamp;
	uint256 public player5Timestamp;
	
    uint256 public timeout;
    uint256 public nextTimeout;
    uint256 public minimumTimeout;
    uint256 public nextMinimumTimeout;
    uint256 public numberOfWagersToMinimumTimeout;
    uint256 public nextNumberOfWagersToMinimumTimeout;
	
	uint256 currentTimeout;
	
    uint256 public wagerIndex = 0;
    
	uint256 public currentBalance;
	
    function calculateTimeout() public view returns(uint256) {
        if (wagerIndex >= numberOfWagersToMinimumTimeout || numberOfWagersToMinimumTimeout == 0) {
            return minimumTimeout;
        } else {
            uint256 difference = timeout - minimumTimeout;
            
            uint256 decrease = difference.mul(wagerIndex).div(numberOfWagersToMinimumTimeout);
                   
            return (timeout - decrease);
        }
    }
}

contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);
	
    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}

contract JackpotFinance is JackpotBase, PullPayment {
    uint256 public feePercentage = 2500;
    
    uint256 public gameStarterDividendPercentage = 2500;
    
    uint256 public price;
    
    uint256 public nextPrice;
    
    uint256 public prizePool;
    
    // The current 5th wager pool (in wei).
    uint256 public wagerPool5;
	
	// The current 13th wager pool (in wei).
	uint256 public wagerPool13;
    
    function setGameStarterDividendPercentage(uint256 _gameStarterDividendPercentage) external onlyCFO {
        require(_gameStarterDividendPercentage <= 4000);
        
        gameStarterDividendPercentage = _gameStarterDividendPercentage;
    }
    
    function _sendFunds(address beneficiary, uint256 amount) internal {
        if (!beneficiary.send(amount)) {
            asyncSend(beneficiary, amount);
        }
    }
    
    function withdrawFreeBalance() external onlyCFO {
		
        uint256 freeBalance = this.balance.sub(totalPayments).sub(prizePool).sub(wagerPool5).sub(wagerPool13);
        
        cfoAddress.transfer(freeBalance);
		currentBalance = this.balance;
    }
}

contract JackpotCore is JackpotFinance {
    
    function JackpotCore(uint256 _price, uint256 _timeout, uint256 _minimumTimeout, uint256 _numberOfWagersToMinimumTimeout) public {
        require(_timeout >= _minimumTimeout);
        
        nextPrice = _price;
        nextTimeout = _timeout;
        nextMinimumTimeout = _minimumTimeout;
        nextNumberOfWagersToMinimumTimeout = _numberOfWagersToMinimumTimeout;
        //NextGame(nextPrice, nextTimeout, nextMinimumTimeout, nextNumberOfWagersToMinimumTimeout);
    }
    
    //event NextGame(uint256 price, uint256 timeout, uint256 minimumTimeout, uint256 numberOfWagersToMinimumTimeout);
    event Start(address indexed starter, uint256 timestamp, uint256 price, uint256 timeout, uint256 minimumTimeout, uint256 numberOfWagersToMinimumTimeout);
    event End(address indexed winner, uint256 timestamp, uint256 prize);
    event Bet(address player, uint256 timestamp, uint256 timeoutTimestamp, uint256 wagerIndex, uint256 newPrizePool);
    event TopUpPrizePool(address indexed donater, uint256 ethAdded, string message, uint256 newPrizePool);
    
    function bet(bool startNewGameIfIdle) external payable {
		require(msg.value >= price);
		
        _processGameEnd();
		
        if (!gameStarted) {
            require(!paused);

            require(startNewGameIfIdle);
            
            price = nextPrice;
            timeout = nextTimeout;
            minimumTimeout = nextMinimumTimeout;
            numberOfWagersToMinimumTimeout = nextNumberOfWagersToMinimumTimeout;
            
            gameStarted = true;
            
            gameStarter = msg.sender;
            
            Start(msg.sender, now, price, timeout, minimumTimeout, numberOfWagersToMinimumTimeout);
        }
        
        // Calculate the fees and dividends.
        uint256 fee = price.mul(feePercentage).div(100000);
        uint256 dividend = price.mul(gameStarterDividendPercentage).div(100000);
		
        uint256 wagerPool5Part;
		uint256 wagerPool13Part;
        
		// Calculate the wager pool part.
        wagerPool5Part = price.mul(2).div(10);
		wagerPool13Part = price.mul(3).div(26);
            
        // Add funds to the wager pool.
        wagerPool5 = wagerPool5.add(wagerPool5Part);
		wagerPool13 = wagerPool13.add(wagerPool13Part);
		
		prizePool = prizePool.add(price);
		prizePool = prizePool.sub(fee);
		prizePool = prizePool.sub(dividend);
		prizePool = prizePool.sub(wagerPool5Part);
		prizePool = prizePool.sub(wagerPool13Part);
		
		if (wagerIndex % 5 == 4) {
            // On every 5th wager, give 2x back
			
            uint256 wagerPrize5 = price.mul(2);
            
            // Calculate the missing wager pool part, remove earlier added wagerPool5Part
            uint256 difference5 = wagerPrize5.sub(wagerPool5);
			prizePool = prizePool.sub(difference5);
        
            msg.sender.transfer(wagerPrize5);
            
            wagerPool5 = 0;
        }
		
		if (wagerIndex % 13 == 12) {
			// On every 13th wager, give 3x back
			
			uint256 wagerPrize13 = price.mul(3);
			
			uint256 difference13 = wagerPrize13.sub(wagerPool13);
			prizePool = prizePool.sub(difference13);
			
			msg.sender.transfer(wagerPrize13);
			
			wagerPool13 = 0;
		}

		player5 = player4;
		player4 = player3;
		player3 = player2;
		player2 = lastPlayer;
		
		player5Timestamp = player4Timestamp;
		player4Timestamp = player3Timestamp;
		player3Timestamp = player2Timestamp;
		
		if (lastWagerTimeoutTimestamp > currentTimeout) {
			player2Timestamp = lastWagerTimeoutTimestamp.sub(currentTimeout);
		}
		
		currentTimeout = calculateTimeout();
		
        lastPlayer = msg.sender;
        lastWagerTimeoutTimestamp = now + currentTimeout;
        
		wagerIndex = wagerIndex.add(1);
		
        Bet(msg.sender, now, lastWagerTimeoutTimestamp, wagerIndex, prizePool);
        
        _sendFunds(gameStarter, dividend);
		//_sendFunds(cfoAddress, fee);
        
        uint256 excess = msg.value - price;
        
        if (excess > 0) {
            msg.sender.transfer(excess);
        }
		
		currentBalance = this.balance;
    }
    
    function topUp(string message) external payable {
        require(gameStarted || !paused);
        
        require(msg.value > 0);
        
        prizePool = prizePool.add(msg.value);
        
        TopUpPrizePool(msg.sender, msg.value, message, prizePool);
    }
    
    function setNextGame(uint256 _price, uint256 _timeout, uint256 _minimumTimeout, uint256 _numberOfWagersToMinimumTimeout) external onlyCFO {
        require(_timeout >= _minimumTimeout);
    
        nextPrice = _price;
        nextTimeout = _timeout;
        nextMinimumTimeout = _minimumTimeout;
        nextNumberOfWagersToMinimumTimeout = _numberOfWagersToMinimumTimeout;
        //NextGame(nextPrice, nextTimeout, nextMinimumTimeout, nextNumberOfWagersToMinimumTimeout);
    } 
    
    function endGame() external {
        require(_processGameEnd());
    }
    
    function _processGameEnd() internal returns(bool) {
        if (!gameStarted) {
            return false;
        }
    
        if (now <= lastWagerTimeoutTimestamp) {
            return false;
        }
        
		// gameStarted AND past the time limit
        uint256 excessPool = wagerPool5.add(wagerPool13);
        
        _sendFunds(lastPlayer, prizePool);
		_sendFunds(cfoAddress, excessPool);
        
        End(lastPlayer, lastWagerTimeoutTimestamp, prizePool);
        
        gameStarted = false;
        gameStarter = 0x0;
        lastPlayer = 0x0;
		player2 = 0x0;
		player3 = 0x0;
		player4 = 0x0;
		player5 = 0x0;
        lastWagerTimeoutTimestamp = 0;
		player2Timestamp = 0;
		player3Timestamp = 0;
		player4Timestamp = 0;
		player5Timestamp = 0;
        wagerIndex = 0;
        prizePool = 0;
        wagerPool5 = 0;
		wagerPool13 = 0;
		currentBalance = this.balance;
        
        return true;
    }
}