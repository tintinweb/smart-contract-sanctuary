pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
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
    address public teamAddress;
    address public luckyPlayer;

    uint256 public unitPrice = 10**14;
    address[] public players;
    mapping (address => uint256) public dividendWallets;
    mapping (address => uint256) public secondWallets;
    
    uint256 public totalSeconds = 0;
    uint256 public initialPeriod = 86400; // 24h.
    uint256 public expirationTime = SafeMath.add(now, initialPeriod);
    

    uint256 teamPortion = 5;
    uint256 luckyPlayerPortion = 25;
    uint256 dividendPortion = 70;
    
    constructor() public {
        teamAddress = 0xCC4D0F785b428497E317Fa7724F9A8b5Ec151968;
    }
    
    function buySecond() public payable {
        // Dividend.
        uint256 dividendValue = SafeMath.div(SafeMath.mul(msg.value, dividendPortion), 100);
        uint256 i;
        bool senderAlreadyInPlayers = false;
        for (i = 0; i < players.length; i++) {
            address player = players[i];
            if (player == msg.sender) {
                senderAlreadyInPlayers = true;
            }
            if (secondWallets[player] == 0) {
                continue;
            }
            dividendWallets[player] = SafeMath.add(dividendWallets[player], SafeMath.div(SafeMath.mul(secondWallets[player], dividendValue), totalSeconds));
        }
        
        // Add sender address to players if it is not already there.
        if (!senderAlreadyInPlayers) {
            players.push(msg.sender);
        }
        
        // Update seconds.
        uint256 newSeconds = SafeMath.div(msg.value, unitPrice);
        secondWallets[msg.sender] = SafeMath.add(secondWallets[msg.sender], newSeconds);
        totalSeconds = SafeMath.add(totalSeconds, newSeconds);
        
        // Update unit price.
		unitPrice = SafeMath.div(SafeMath.mul(unitPrice, 1001), 1000);
        
        // Update expirationTime.
        expirationTime = SafeMath.add(expirationTime, 1);
        
        // Update lucky player address.
        luckyPlayer = msg.sender;
    }
    
    function endRound() private {
        if (players.length == 0) {
            return;
        }
        
        // Dividend reward.
        uint256 i;
        for (i = 0; i < players.length; i++) {
            address player = players[i];
            if (dividendWallets[player] != 0) {
                player.transfer(dividendWallets[player]);
            }
            
            // Clear mappings.
            secondWallets[player] = 0;
            dividendWallets[player] = 0;
        }
        
        // Team reward and lucky player reward.
        uint256 totalLeftPercentage = SafeMath.add(teamPortion, luckyPlayerPortion);
        teamAddress.transfer(SafeMath.div(SafeMath.mul(address(this).balance, teamPortion), totalLeftPercentage));
        luckyPlayer.transfer(SafeMath.div(SafeMath.mul(address(this).balance, luckyPlayerPortion), totalLeftPercentage));
        
        // Reset.
        expirationTime = now + initialPeriod;
        unitPrice = 10**14;
        totalSeconds = 0;
    }
    
    function withdraw() public {
        require(msg.sender.send(dividendWallets[msg.sender]));
        dividendWallets[msg.sender] = 0;
    }
    
    function getTimeLeft() public returns(uint256) {
        if (expirationTime < now) {
            endRound();
        }
        return SafeMath.sub(expirationTime, now);
    }
    
    function getCurrentUnitPrice() public view returns(uint256) {
        return unitPrice;
    }
    
    function getCurrentTotalEther() public view returns(uint256) {
        return address(this).balance;
    }
}