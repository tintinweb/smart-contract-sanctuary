pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

contract XuYiMiao {
    // Using statements.
    using SafeMath for uint;
    using SafeMath for uint256;

    // Constants.
    address constant teamAddress = 0x575A1fAad74133E5cD7db8cA7576837397a69908;
    uint256 constant teamPortion = 2; // 2%.
    uint256 constant dividendPortion = 70; // 70%.
    uint256 constant delayPeriod = 30; // 30s.
    uint256 constant initialPeriod = 86400; // 24h.
    uint256 constant icoPeriod = 7200; // 2h.
    uint256 constant coolingPeriodBetweenRounds = 7200; // 2h.
    
    struct wallet {
        uint256 dividend; // ETH, in unit of Wei.
        uint256 second; // Ha second.
    }
    
    address public luckyPlayer;

    address[] public players;
    mapping (address => wallet) public wallets;

    uint256 public unitPrice = 10**14; // Price of a second, in unit of Wei.
    uint256 public totalSeconds = 0; // Total seconds in the current game round.
    uint256 public startTime = now;
    uint256 public expirationTime = now.add(initialPeriod);
    uint256 public icoExpirationTime = now.add(icoPeriod);
    uint256 public totalEtherOfCurrentRound = 0;
    uint256 public totalEtherOfAllRounds = 0;

    // Events.
    event BuySecond(address indexed _player, uint256 _value);
    event Withdraw(address indexed _player, uint256 _value);
    event EndRound(uint256 _unitPrice, uint256 _totalSeconds, uint256 _totalEther);
    
    modifier isStarted() {
        require(now > startTime);
        _;
    }

    constructor() public {
        players.push(teamAddress);
        wallets[teamAddress] = wallet(0, 0);
    }
    
    // Buy seconds with ETH, leading to updates on unit price and expiration
    // time. A portion of the purchasing ETH becomes dividends of previous
    // users in the current game round.
    function buySecond() public payable isStarted returns(bool) {
        if (expirationTime < now) {
            endRound();
            return false;
        }
        
        // Dividend.
        uint256 dividendValue = msg.value.mul(dividendPortion).div(100);
        bool senderAlreadyInPlayers = false;
        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i];
            if (player == msg.sender) {
                senderAlreadyInPlayers = true;
            }
            if (wallets[player].second == 0) {
                continue;
            }
            wallets[player].dividend = wallets[player].dividend.add(
                wallets[player].second.mul(dividendValue).div(totalSeconds));
        }
        
        // Management fee.
        wallets[teamAddress].dividend = wallets[teamAddress].dividend.add(
            msg.value.mul(teamPortion).div(100));
        
        // Add sender address to players if it is not already there.
        if (!senderAlreadyInPlayers) {
            players.push(msg.sender);
            wallets[msg.sender] = wallet(0, 0);
        }
        
        // Update seconds.
        uint256 newSeconds = msg.value.div(unitPrice);
        wallets[msg.sender].second = wallets[msg.sender].second.add(newSeconds);
        totalSeconds = totalSeconds.add(newSeconds);
        
        // Update unit price.
        if (icoExpirationTime < now) {
            unitPrice = unitPrice.mul(1001).div(1000);
        }
        
        // Update expirationTime.
        expirationTime = expirationTime.add(delayPeriod);
        uint256 maxExpirationTime = now.add(initialPeriod);
        if (expirationTime > maxExpirationTime) {
            expirationTime = maxExpirationTime;
        }

        // Update lucky player address.
        luckyPlayer = msg.sender;
        
        // Statistics.
        totalEtherOfCurrentRound = totalEtherOfCurrentRound.add(msg.value);
        totalEtherOfAllRounds = totalEtherOfAllRounds.add(msg.value);
        
        // Event.
        emit BuySecond(msg.sender, msg.value);
        
        return true;
    }
    
    // End the current round as expiration time is past. Finalize all necessary
    // payments.
    function endRound() private {
        // Dividend reward, including team management fee.
        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i];
            uint256 amount = wallets[player].dividend;
            if (amount != 0) {
                wallets[player].dividend = 0;
                player.transfer(amount);
            }
            
            // Clear second wallets to prepare for next round.
            wallets[player].second = 0;
            wallets[player].dividend = 0;
        }
        
        // lucky player reward.
        luckyPlayer.transfer(address(this).balance);
        
        // Event.
        emit EndRound(unitPrice, totalSeconds, totalEtherOfCurrentRound);
        
        // Reset to prepare for next round.
        unitPrice = 10**14;
        totalSeconds = 0;
        startTime = now.add(coolingPeriodBetweenRounds);
        expirationTime = startTime.add(initialPeriod);
        icoExpirationTime = startTime.add(icoPeriod);
        totalEtherOfCurrentRound = 0;
    }
    
    // Withdraw dividends before the current game round ends.
    function withdraw() public isStarted returns(bool) {
        uint256 amount = wallets[msg.sender].dividend;
        if (amount > 0) {
            wallets[msg.sender].dividend = 0;
            msg.sender.transfer(amount);
        }
        
        // Event.
        emit Withdraw(msg.sender, amount);
        
        return true;
    }

    // Get current expiration time, in UNIX time.
    function getCurrentExpirationTime() public returns(uint256) {
        if (expirationTime < now) {
            endRound();
        }
        return expirationTime;
    }
    
    // Get current ICO expiration time, in UNIX time.
    function getCurrentICOExpirationTime() public view returns(uint256) {
        return icoExpirationTime;
    }
    
    // Get start time of the current round, in UNIX time.
    function getCurrentStartTime() public view returns(uint256) {
        return startTime;
    }
    
    // Get current price for buying one Ha second.
    function getCurrentUnitPrice() public view returns(uint256) {
        return unitPrice;
    }
    
    // Get total ether received by the contract in the current game round.
    function getTotalEtherOfCurrentRound() public view returns(uint256) {
        return totalEtherOfCurrentRound;
    }
    
    // Get the grand total ether received by this contract for all game rounds.
    function getTotalEtherOfAllRounds() public view returns(uint256) {
        return totalEtherOfAllRounds;
    }
    
    // Get the number of seconds in my account for the current game round.
    function getMySecondAmount() public view returns(uint256) {
        return wallets[msg.sender].second;
    }
    
    // Get the amount of dividend in my account for the current game round.
    function getMyDividendAmount() public view returns(uint256) {
        return wallets[msg.sender].dividend;
    }
    
    // Get total seconds that are purchased during the current game round.
    function getTotalSeconds() public view returns(uint256) {
        return totalSeconds;
    }
}