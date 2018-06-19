pragma solidity ^0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title TheNextBlock
 * @dev This is smart contract for dapp game
 * in which players bet to guess miner of their transactions.
 */
contract TheNextBlock {
    
    using SafeMath for uint256;
    
    event BetReceived(address sender, address betOnMiner, address miner);
    event Jackpot(address winner, uint256 amount);
    
    struct Owner {
        uint256 balance;
        address addr;
    }
    
    Owner public owner;
    
    /**
    * This is exact amount of ether player can bet.
    * If bet is less than this amount, transaction is reverted.
    * If moore, contract will send excess amout back to player.
    */
    uint256 constant public allowedBetAmount = 5000000000000000; // 0.005 ETH
    /**
    * You need to guess requiredPoints times in a row to win jackpot.
    */
    uint256 constant public requiredPoints = 3;
    /**
    * Every bet is split: 10% to owner, 70% to prize pool
    * we preserve 20% for next prize pool
    */
    uint256 constant public ownerProfitPercent = 10;
    uint256 constant public nextPrizePoolPercent = 20;
    uint256 constant public prizePoolPercent = 70; 
    uint256 public prizePool = 0;
    uint256 public nextPrizePool = 0;
    uint256 public totalBetCount = 0;
    
    struct Player {
        uint256 balance;
        uint256 lastBlock;
    }
    
    mapping(address => Player) public playersStorage;
    mapping(address => uint256) public playersPoints;


    modifier notContract(address sender)  {
      uint32 size;
      assembly {
        size := extcodesize(sender)
      }
      require (size == 0);
      _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner.addr);
        _;
    }

    modifier notLess() {
        require(msg.value >= allowedBetAmount);
        _;
    }

    modifier notMore() {
        if(msg.value > allowedBetAmount) {
            msg.sender.transfer( SafeMath.sub(msg.value, allowedBetAmount) );
        }
        _;
    }
    
    modifier onlyOnce() {
        Player storage player = playersStorage[msg.sender];
        require(player.lastBlock != block.number);
        player.lastBlock = block.number;
        _;
    }
    
    function safeGetPercent(uint256 amount, uint256 percent) private pure returns(uint256) {
        return SafeMath.mul( SafeMath.div( SafeMath.sub(amount, amount%100), 100), percent );
    }
    
    function TheNextBlock() public {
        owner.addr = msg.sender;
    }

    /**
     * This is left for donations.
     * Ether received in this(fallback) function
     * will appear on owners balance.
     */
    function () public payable {
         owner.balance = owner.balance.add(msg.value);
    }

    function placeBet(address _miner) 
        public
        payable
        notContract(msg.sender)
        notLess
        notMore
        onlyOnce {
            
            totalBetCount = totalBetCount.add(1);
            BetReceived(msg.sender, _miner, block.coinbase);

            owner.balance = owner.balance.add( safeGetPercent(allowedBetAmount, ownerProfitPercent) );
            prizePool = prizePool.add( safeGetPercent(allowedBetAmount, prizePoolPercent) );
            nextPrizePool = nextPrizePool.add( safeGetPercent(allowedBetAmount, nextPrizePoolPercent) );

            if(_miner == block.coinbase) {
                
                playersPoints[msg.sender]++;

                if(playersPoints[msg.sender] == requiredPoints) {
                    
                    if(prizePool >= allowedBetAmount) {
                        Jackpot(msg.sender, prizePool);
                        playersStorage[msg.sender].balance = playersStorage[msg.sender].balance.add(prizePool);
                        prizePool = nextPrizePool;
                        nextPrizePool = 0;
                        playersPoints[msg.sender] = 0;
                    } else {
                        playersPoints[msg.sender]--;
                    }
                }

            } else {
                playersPoints[msg.sender] = 0;
            }
    }

    function getPlayerData(address playerAddr) public view returns(uint256 lastBlock, uint256 balance) {
        balance =  playersStorage[playerAddr].balance;
        lastBlock =  playersStorage[playerAddr].lastBlock;
    }

    function getPlayersBalance(address playerAddr) public view returns(uint256) {
        return playersStorage[playerAddr].balance;
    }
    
    function getPlayersPoints(address playerAddr) public view returns(uint256) {
        return playersPoints[playerAddr];
    }

    function getMyPoints() public view returns(uint256) {
        return playersPoints[msg.sender];
    }
    
    function getMyBalance() public view returns(uint256) {
        return playersStorage[msg.sender].balance;
    }
    
    function withdrawMyFunds() public {
        uint256 balance = playersStorage[msg.sender].balance;
        if(balance != 0) {
            playersStorage[msg.sender].balance = 0;
            msg.sender.transfer(balance);
        }
    }
    
    function withdrawOwnersFunds() public onlyOwner {
        uint256 balance = owner.balance;
        owner.balance = 0;
        owner.addr.transfer(balance);
    }
    
    function getOwnersBalance() public view returns(uint256) {
        return owner.balance;
    }
    
    function getPrizePool() public view returns(uint256) {
        return prizePool;
    }

    function getNextPrizePool() public view returns(uint256) {
        return nextPrizePool;
    }
    
    
    function getBalance() public view returns(uint256) {
        return this.balance;
    }
        
    function changeOwner(address newOwner) public onlyOwner {
        owner.addr = newOwner;
    }

}