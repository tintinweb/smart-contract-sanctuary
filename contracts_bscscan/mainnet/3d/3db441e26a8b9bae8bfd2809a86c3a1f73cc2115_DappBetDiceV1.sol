/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

pragma solidity >=0.4.22 <0.7.0;

contract DappBetDiceV1 {
    struct Bet {
        uint amount; // wei
        bytes32 seedHash; // seed hash. Shown to player before they make a bet to prove we can't change result
        string randomSeed;
        bytes32 playerSeed; // seed provided by player to combine with random seed to calculate result
        uint roll;  // result of roll
        uint target; // target the player was trying to roll under
        address payable player; 
        bool settled; 
    }
    
    uint constant public MIN_BET = 0.001 ether;
    
    address public owner;
    address public settler;
    
    mapping (uint => Bet) bets;
    
    uint public maxProfit;
    uint128 private lockedFunds;
    uint private leverage = 2;
    
    event BetResult(address indexed player, uint winAmount, bytes32 playerSeed, bytes32 seedHash, uint target, string randomSeed, uint roll);
    event BetPlaced(bytes32 hash);
    event FailedPayment(address indexed player, uint amount, bytes32 seedHash);
    
    constructor () public {
      owner = msg.sender;
      settler = msg.sender;
    }
    
    receive () external payable {
        updateMaxProfit();
    }
    
    modifier onlyOwner {
        require (msg.sender == owner, "Only the owner can call this method.");
        _;
    }
    
    modifier onlySettler {
        require (msg.sender == settler, "Only the settler to call this method.");
        _;
    }

    function setSettler(address newSettler) external onlyOwner {
        settler = newSettler;
    }

    function updateMaxProfit() private {
      maxProfit = ((address(this).balance - lockedFunds) / 100) * leverage;
    }
    
    function setLeverage(uint _leverage) public onlyOwner {
        leverage = _leverage;
        updateMaxProfit();
    }

    function withdrawFunds(address payable receiver, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance, "amount larger than balance.");
        receiver.send(withdrawAmount);
        updateMaxProfit();
    }

    function kill() public onlyOwner {
        require (lockedFunds == 0, "Still bets locked up.");
        selfdestruct(msg.sender);
    }
    
    function placeBet(bytes32 playerSeed, bytes32 seedHash, uint target) external payable {
        require(target > 1 && target <= 100, "target out of range"); 
      
        uint betAmount = msg.value;
        require(betAmount >= MIN_BET, "betAmount too small");

        uint payout = (betAmount - (betAmount / 100)) * 100 / target; 
        require (payout <= betAmount + maxProfit, "Payout is more than max allowed profit.");

        lockedFunds += uint128(payout);
        require (lockedFunds <= address(this).balance, "Cannot take bet.");
      
        Bet storage bet = bets[uint(seedHash)];
        
        //check bet doesnt exist with hash
        require(bet.seedHash != seedHash, "Bet with hash already exists");
    
        bet.seedHash = seedHash;
        bet.amount = betAmount;
        bet.player = msg.sender;
        bet.playerSeed = playerSeed;
        bet.target = target;
        bet.settled = false;
        
        updateMaxProfit();
        emit BetPlaced(seedHash);
    }
    
    function settleBet(string calldata randomSeed) external onlySettler {
         bytes32 seedHash = keccak256(abi.encodePacked(randomSeed));
         Bet storage bet = bets[uint(seedHash)];

         require(bet.seedHash == seedHash, "No bet found with server seed");
         require(bet.settled == false, "Bet already settled");
         
         uint amount = bet.amount;
         uint target = bet.target;
         uint payout = (amount - (amount / 100)) * 100 / target;
         
         bytes32 combinedHash = keccak256(abi.encodePacked(randomSeed, bet.playerSeed));
         bet.roll = uint(combinedHash) % 100;
         
         if(bet.roll < bet.target) {
          if (!bet.player.send(payout)) {
            emit FailedPayment(bet.player, payout, bet.seedHash);
          }
          emit BetResult(bet.player, payout, bet.playerSeed, bet.seedHash, target, randomSeed, bet.roll);
        } else {
            emit BetResult(bet.player, 0, bet.playerSeed, bet.seedHash, target, randomSeed, bet.roll);
        }

         lockedFunds -= uint128(payout);
         bet.settled = true;
         bet.randomSeed = randomSeed;

         updateMaxProfit();
    }
}