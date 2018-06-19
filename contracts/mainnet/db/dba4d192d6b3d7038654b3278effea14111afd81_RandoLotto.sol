pragma solidity 0.4.23;

// Random lottery
// Smart contracts can&#39;t bet

// Pay 0.001eth or higher to get a random number
// You probably shouldn&#39;t pay higher than 0.001eth, there&#39;s no reason.
// If your random number is the highest so far you&#39;re in the lead
// If no one beats you in 1 day you can claim your winnnings - the entire balance.

// 1% dev fee on winnings
contract RandoLotto {
    using SafeMath for uint256;
    
    event NewLeader(address newLeader, uint256 highScore);
    event BidAttempt(uint256 randomNumber, uint256 highScore);
    event NewRound(uint256 payout, uint256 highScore);
    
    address public currentWinner;
    
    uint256 public highScore;
    uint256 public lastTimestamp;
    
    address internal dev;
    
    Random randomContract;
    
    modifier GTFOSmartContractHackerz {
        require(msg.sender == tx.origin);
        _;    
    }
    
    constructor () public payable {
        dev = msg.sender;
        highScore = 0;
        currentWinner = msg.sender;
        lastTimestamp = now;
        randomContract = new Random();
    }
    
    function () public payable GTFOSmartContractHackerz {
        require(msg.value >= 0.001 ether);
        
        if (now > lastTimestamp + 1 days) { sendWinnings(); }
    
        // We include msg.sender in the randomNumber so that it&#39;s not the same for different blocks
        uint256 randomNumber = randomContract.random(10000000000000000000);
        
        if (randomNumber > highScore) {
            highScore = randomNumber;
            currentWinner = msg.sender;
            lastTimestamp = now;
            
            emit NewLeader(msg.sender, highScore);
        }
        
        emit BidAttempt(randomNumber, highScore);
    }
    
    function sendWinnings() public {
        require(now > lastTimestamp + 1 days);
        
        uint256 toWinner;
        uint256 toDev;
        
        if (address(this).balance > 0) {
            uint256 totalPot = address(this).balance;
            
            toDev = totalPot.div(100);
            toWinner = totalPot.sub(toDev);
         
            dev.transfer(toDev);
            currentWinner.transfer(toWinner);
        }
        
        highScore = 0;
        currentWinner = msg.sender;
        lastTimestamp = now;
        
        emit NewRound(toWinner, highScore);
    }
}

contract Random {
  uint256 _seed;

  // The upper bound of the number returns is 2^bits - 1
  function bitSlice(uint256 n, uint256 bits, uint256 slot) public pure returns(uint256) {
      uint256 offset = slot * bits;
      // mask is made by shifting left an offset number of times
      uint256 mask = uint256((2**bits) - 1) << offset;
      // AND n with mask, and trim to max of 5 bits
      return uint256((n & mask) >> offset);
  }

  function maxRandom() public returns (uint256 randomNumber) {
    _seed = uint256(keccak256(
        _seed,
        blockhash(block.number - 1),
        block.coinbase,
        block.difficulty
    ));
    return _seed;
  }

  // return a pseudo random number with an upper bound
  function random(uint256 upper) public returns (uint256 randomNumber) {
    return maxRandom() % upper;
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