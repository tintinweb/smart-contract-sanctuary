pragma solidity ^0.4.19;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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


/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}


/// @dev Implements access control to the Chronos contract.
contract ChronosAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;
    
    function ChronosAccessControl() public {
        // The creator of the contract is the initial CFO.
        cfoAddress = msg.sender;
    }
    
    /// @dev Access modifier for CFO-only functionality.
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current contract owner.
    /// @param _newCFO The address of the new CFO.
    function setCFO(address _newCFO) external onlyOwner {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
}


/// @dev Defines base data structures for Chronos.
contract ChronosBase is ChronosAccessControl {
    using SafeMath for uint256;
    
    /// @notice Time windows in seconds from the start of the week
    /// when new games can be started.
    uint256[] public activeTimesFrom;
    uint256[] public activeTimesTo;
    
    /// @notice Whether the game can start once outside of active times.
    bool public allowStart;
    
    /// @notice Boolean indicating whether a game is live.
    bool public gameStarted;
    
    /// @notice The last player to have entered.
    address public lastPlayer;
    
    /// @notice The timestamp the last wager times out.
    uint256 public lastWagerTimeoutTimestamp;

    /// @notice The number of seconds before the game ends.
    uint256 public timeout;
    
    /// @notice The number of seconds before the game ends -- setting
    /// for the next game.
    uint256 public nextTimeout;
    
    /// @notice The final number of seconds before the game ends.
    uint256 public finalTimeout;
    
    /// @notice The final number of seconds before the game ends --
    /// setting for the next game.
    uint256 public nextFinalTimeout;
    
    /// @notice The number of wagers required to move to the
    /// final timeout.
    uint256 public numberOfWagersToFinalTimeout;
    
    /// @notice The number of wagers required to move to the
    /// final timeout -- setting for the next game.
    uint256 public nextNumberOfWagersToFinalTimeout;
    
    /// @notice The index of the current game.
    uint256 public gameIndex = 0;
    
    /// @notice The index of the the current wager in the game.
    uint256 public wagerIndex = 0;
    
    /// @notice Every nth wager receives 2x their wager.
    uint256 public nthWagerPrizeN = 3;
    
    /// @notice A boolean indicating whether a new game can start,
    /// based on the active times.
    function canStart() public view returns (bool) {
        // Get the time of the week in seconds.
        // There are 7 * 24 * 60 * 60 = 604800 seconds in a week,
        // and unix timestamps started counting from a Thursday,
        // so subtract 4 * 24 * 60 * 60 = 345600 seconds, as
        // (0 - 345600) % 604800 = 259200, i.e. the number of
        // seconds in a week until Thursday 00:00:00.
        uint256 timeOfWeek = (block.timestamp - 345600) % 604800;
        
        uint256 windows = activeTimesFrom.length;
        
        if (windows == 0) {
            // No start times configured, any time is allowed.
            return true;
        }
        
        for (uint256 i = 0; i < windows; i++) {
            if (timeOfWeek >= activeTimesFrom[i] && timeOfWeek <= activeTimesTo[i]) {
                return true;
            }
        }
        
        return false;
    }
    
    /// @notice Calculate the current game&#39;s timeout.
    function calculateTimeout() public view returns(uint256) {
        if (wagerIndex >= numberOfWagersToFinalTimeout || numberOfWagersToFinalTimeout == 0) {
            return finalTimeout;
        } else {
            if (finalTimeout <= timeout) {
                // The timeout decreases over time.
            
                // This cannot underflow, as timeout is guaranteed to be
                // greater than or equal to finalTimeout.
                uint256 difference = timeout - finalTimeout;
                
                // Calculate the decrease in timeout, based on the number of wagers performed.
                uint256 decrease = difference.mul(wagerIndex).div(numberOfWagersToFinalTimeout);
                
                // This subtraction cannot underflow, as decrease is guaranteed to be less than or equal to timeout.            
                return (timeout - decrease);
            } else {
                // The timeout increases over time.
            
                // This cannot underflow, as timeout is guaranteed to be
                // smaller than finalTimeout.
                difference = finalTimeout - timeout;
                
                // Calculate the increase in timeout, based on the number of wagers performed.
                uint256 increase = difference.mul(wagerIndex).div(numberOfWagersToFinalTimeout);
                
                // This addition cannot overflow, as timeout + increase is guaranteed to be less than or equal to finalTimeout.
                return (timeout + increase);
            }
        }
    }
}


/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}


/// @dev Defines base finance functionality for Chronos.
contract ChronosFinance is ChronosBase, PullPayment {
    /// @notice The developer fee in 1/1000th of a percentage.
    uint256 public feePercentage = 2500;
    
    /// @notice The percentage of a wager that goes to the next prize pool.
    uint256 public nextPoolPercentage = 7500;
    
    /// @notice The wager price.
    uint256 public price;
    
    /// @notice The wager price -- setting for the next game.
    uint256 public nextPrice;
    
    /// @notice The current prize pool (in wei).
    uint256 public prizePool;
    
    /// @notice The next prize pool (in wei).
    uint256 public nextPrizePool;
    
    /// @notice The current nth wager pool (in wei).
    uint256 public wagerPool;
    
    /// @notice Sets a new fee percentage.
    /// @param _feePercentage The new fee percentage.
    function setFeePercentage(uint256 _feePercentage) external onlyCFO {
        // Fee percentage must be 4% at the most.
        require(_feePercentage <= 4000);
        
        feePercentage = _feePercentage;
    }
    
    /// @notice Sets a new next pool percentage.
    /// @param _nextPoolPercentage The new next pool percentage.
    function setNextPoolPercentage(uint256 _nextPoolPercentage) external onlyCFO {
        nextPoolPercentage = _nextPoolPercentage;
    }
    
    /// @dev Send funds to a beneficiary. If sending fails, assign
    /// funds to the beneficiary&#39;s balance for manual withdrawal.
    /// @param beneficiary The beneficiary&#39;s address to send funds to
    /// @param amount The amount to send.
    function _sendFunds(address beneficiary, uint256 amount) internal {
        if (!beneficiary.send(amount)) {
            // Failed to send funds. This can happen due to a failure in
            // fallback code of the beneficiary, or because of callstack
            // depth.
            // Send funds asynchronously for manual withdrawal by the
            // beneficiary.
            asyncSend(beneficiary, amount);
        }
    }
    
    /// @notice Withdraw (unowed) contract balance.
    function withdrawFreeBalance() external onlyCFO {
        // Calculate the free (unowed) balance.
        uint256 freeBalance = this.balance.sub(totalPayments).sub(prizePool).sub(wagerPool);
        
        cfoAddress.transfer(freeBalance);
    }
}


/// @dev Defines core Chronos functionality.
contract ChronosCore is ChronosFinance {
    
    function ChronosCore(uint256 _price, uint256 _timeout, uint256 _finalTimeout, uint256 _numberOfWagersToFinalTimeout) public {
        nextPrice = _price;
        nextTimeout = _timeout;
        nextFinalTimeout = _finalTimeout;
        nextNumberOfWagersToFinalTimeout = _numberOfWagersToFinalTimeout;
        NextGame(nextPrice, nextTimeout, nextFinalTimeout, nextNumberOfWagersToFinalTimeout);
    }
    
    event ActiveTimes(uint256[] from, uint256[] to);
    event AllowStart(bool allowStart);
    event NextGame(uint256 price, uint256 timeout, uint256 finalTimeout, uint256 numberOfWagersToFinalTimeout);
    event Start(uint256 indexed gameIndex, address indexed starter, uint256 timestamp, uint256 price, uint256 timeout, uint256 finalTimeout, uint256 numberOfWagersToFinalTimeout);
    event End(uint256 indexed gameIndex, uint256 wagerIndex, address indexed winner, uint256 timestamp, uint256 prize, uint256 nextPrizePool);
    event Play(uint256 indexed gameIndex, uint256 indexed wagerIndex, address indexed player, uint256 timestamp, uint256 timeoutTimestamp, uint256 newPrizePool, uint256 nextPrizePool);
    event SpiceUpPrizePool(uint256 indexed gameIndex, address indexed spicer, uint256 spiceAdded, string message, uint256 newPrizePool);
    
    /// @notice Participate in the game.
    /// @param _gameIndex The index of the game to play on.
    /// @param startNewGameIfIdle Start a new game if the current game is idle.
    function play(uint256 _gameIndex, bool startNewGameIfIdle) external payable {
        // Check to see if the game should end. Process payment.
        _processGameEnd();
        
        if (!gameStarted) {
            // If the game is not started, the contract must not be paused.
            require(!paused);
            
            if (allowStart) {
                // We&#39;re allowed to start once outside of active times.
                allowStart = false;
            } else {
                // This must be an active time.
                require(canStart());
            }
            
            // If the game is not started, the player must be willing to start
            // a new game.
            require(startNewGameIfIdle);
            
            // Set the price and timeout.
            price = nextPrice;
            timeout = nextTimeout;
            finalTimeout = nextFinalTimeout;
            numberOfWagersToFinalTimeout = nextNumberOfWagersToFinalTimeout;
            
            // Start the game.
            gameStarted = true;
            
            // Emit start event.
            Start(gameIndex, msg.sender, block.timestamp, price, timeout, finalTimeout, numberOfWagersToFinalTimeout);
        }
        
        // Check the game index.
        if (startNewGameIfIdle) {
            // The given game index must be the current game index, or the previous
            // game index.
            require(_gameIndex == gameIndex || _gameIndex.add(1) == gameIndex);
        } else {
            // Only play on the game indicated by the player.
            require(_gameIndex == gameIndex);
        }
        
        // Enough Ether must be supplied.
        require(msg.value >= price);
        
        // Calculate the fees and next pool percentage.
        uint256 fee = price.mul(feePercentage).div(100000);
        uint256 nextPool = price.mul(nextPoolPercentage).div(100000);
        uint256 wagerPoolPart;
        
        if (wagerIndex % nthWagerPrizeN == nthWagerPrizeN - 1) {
            // Give the wager prize every nth wager.
            
            // Calculate total nth wager prize.
            uint256 wagerPrize = price.mul(2);
            
            // Calculate the missing wager pool part (equal to price.mul(2).div(nthWagerPrizeN) plus a few wei).
            wagerPoolPart = wagerPrize.sub(wagerPool);
        
            // Give the wager prize to the sender.
            msg.sender.transfer(wagerPrize);
            
            // Reset the wager pool.
            wagerPool = 0;
        } else {
            // On every non-nth wager, increase the wager pool.
            
            // Calculate the wager pool part.
            wagerPoolPart = price.mul(2).div(nthWagerPrizeN);
            
            // Add funds to the wager pool.
            wagerPool = wagerPool.add(wagerPoolPart);
        }
        
        // Calculate the timeout.
        uint256 currentTimeout = calculateTimeout();
        
        // Set the last player, timestamp, timeout timestamp, and increase prize.
        lastPlayer = msg.sender;
        lastWagerTimeoutTimestamp = block.timestamp + currentTimeout;
        prizePool = prizePool.add(price.sub(fee).sub(nextPool).sub(wagerPoolPart));
        nextPrizePool = nextPrizePool.add(nextPool);
        
        // Emit event.
        Play(gameIndex, wagerIndex, msg.sender, block.timestamp, lastWagerTimeoutTimestamp, prizePool, nextPrizePool);
        
        // Increment the wager index. This won&#39;t overflow before the heat death of the universe.
        wagerIndex++;
        
        // Refund any excess Ether sent.
        // This subtraction never underflows, as msg.value is guaranteed
        // to be greater than or equal to price.
        uint256 excess = msg.value - price;
        
        if (excess > 0) {
            msg.sender.transfer(excess);
        }
    }
    
    /// @notice Spice up the prize pool.
    /// @param _gameIndex The index of the game to add spice to.
    /// @param message An optional message to be sent along with the spice.
    function spiceUp(uint256 _gameIndex, string message) external payable {
        // Check to see if the game should end. Process payment.
        _processGameEnd();
        
        // Check the game index.
        require(_gameIndex == gameIndex);
    
        // Game must be live or unpaused.
        require(gameStarted || !paused);
        
        // Funds must be sent.
        require(msg.value > 0);
        
        // Add funds to the prize pool.
        prizePool = prizePool.add(msg.value);
        
        // Emit event.
        SpiceUpPrizePool(gameIndex, msg.sender, msg.value, message, prizePool);
    }
    
    /// @notice Set the parameters for the next game.
    /// @param _price The price of wagers for the next game.
    /// @param _timeout The timeout in seconds for the next game.
    /// @param _finalTimeout The final timeout in seconds for
    /// the next game.
    /// @param _numberOfWagersToFinalTimeout The number of wagers
    /// required to move to the final timeout for the next game.
    function setNextGame(uint256 _price, uint256 _timeout, uint256 _finalTimeout, uint256 _numberOfWagersToFinalTimeout) external onlyCFO {
        nextPrice = _price;
        nextTimeout = _timeout;
        nextFinalTimeout = _finalTimeout;
        nextNumberOfWagersToFinalTimeout = _numberOfWagersToFinalTimeout;
        NextGame(nextPrice, nextTimeout, nextFinalTimeout, nextNumberOfWagersToFinalTimeout);
    } 
    
    /// @notice End the game. Pay prize.
    function endGame() external {
        require(_processGameEnd());
    }
    
    /// @dev End the game. Pay prize.
    function _processGameEnd() internal returns(bool) {
        if (!gameStarted) {
            // No game is started.
            return false;
        }
    
        if (block.timestamp <= lastWagerTimeoutTimestamp) {
            // The game has not yet finished.
            return false;
        }
        
        // Calculate the prize. Any leftover funds for the
        // nth wager prize is added to the prize pool.
        uint256 prize = prizePool.add(wagerPool);
        
        // The game has finished. Pay the prize to the last player.
        _sendFunds(lastPlayer, prize);
        
        // Emit event.
        End(gameIndex, wagerIndex, lastPlayer, lastWagerTimeoutTimestamp, prize, nextPrizePool);
        
        // Reset the game.
        gameStarted = false;
        lastPlayer = 0x0;
        lastWagerTimeoutTimestamp = 0;
        wagerIndex = 0;
        wagerPool = 0;
        
        // The next pool is any leftover balance minus outstanding balances.
        prizePool = nextPrizePool;
        nextPrizePool = 0;
        
        // Increment the game index. This won&#39;t overflow before the heat death of the universe.
        gameIndex++;
        
        // Indicate ending the game was successful.
        return true;
    }
    
    /// @notice Set the active times.
    function setActiveTimes(uint256[] _from, uint256[] _to) external onlyCFO {
        require(_from.length == _to.length);
    
        activeTimesFrom = _from;
        activeTimesTo = _to;
        
        // Emit event.
        ActiveTimes(_from, _to);
    }
    
    /// @notice Allow the game to start once outside of active times.
    function setAllowStart(bool _allowStart) external onlyCFO {
        allowStart = _allowStart;
        
        // Emit event.
        AllowStart(_allowStart);
    }
}