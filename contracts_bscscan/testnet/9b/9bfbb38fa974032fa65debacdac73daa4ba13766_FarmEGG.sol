/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

pragma solidity ^0.4.24;

contract FarmEGG {
    using SafeMath for uint;
    
    /* Event */
    
    event PlantedRoot(address indexed player, uint eth, uint pecan, uint treesize);
    event GavePecan(address indexed player, uint eth, uint pecan);
    event ClaimedShare(address indexed player, uint eth, uint pecan);
    event GrewTree(address indexed player, uint eth, uint pecan, uint boost);
    event WonRound (address indexed player, uint indexed round, uint eth);
    event WithdrewBalance (address indexed player, uint eth);
    event PaidThrone (address indexed player, uint eth);
    event BoostedPot (address indexed player, uint eth);

    /* Constants */
    
    uint256 constant SECONDS_IN_HOUR    = 3600;
    uint256 constant SECONDS_IN_DAY     = 86400;
    uint256 constant PECAN_WIN_FACTOR   = 0.0000000001 ether; //add 1B pecans per 0.1 ETH in pot
    uint256 constant TREE_SIZE_COST     = 0.0000005 ether; //= 1 treeSize
    uint256 constant REWARD_SIZE_ETH    = 0.00000002 ether; //4% per day per treeSize
    address constant SNAILTHRONE        = 0xfD259E5a4591Bd6E3f7d902bC656F93049a760BB;

    /* Variables */
    
	//Current round
    uint256 public gameRound            = 0;
	
	//Fund for %claims
	uint256 public treePot              = 0;
	
	//Direct rewards
	uint256 public wonkPot              = 0;
	
	//Round winner reward
	uint256 public jackPot              = 0;
	
	//Divs for SnailThrone holders
	uint256 public thronePot            = 0;
	
	//Pecans required to win this round
	uint256 public pecanToWin           = 0;
	
	//Pecans given this round
	uint256 public pecanGiven           = 0;
	
	//Last ETH investment
	uint256 public lastRootPlant        = 0;
	
    /* Mappings */
    
    mapping (address => uint256) playerRound;
    mapping (address => uint256) playerBalance;
    mapping (address => uint256) treeSize;
    mapping (address => uint256) pecan;
    mapping (address => uint256) lastClaim;
    mapping (address => uint256) boost;

    /* Functions */
    
    // Constructor
    // Sets round to 1 and lastRootPlant to now
    
    constructor() public {
        gameRound = 1;
        pecanToWin = 1;
        lastRootPlant = now;
    }
    
    //-- PRIVATE --
    
    // CheckRound
    // Ensures player is on correct round
    // If not, reduce his treeSize by 20% per round missed
    // Increase his round until he's on the correct one
    
    function CheckRound() private {       
        while(playerRound[msg.sender] != gameRound){
            treeSize[msg.sender] = treeSize[msg.sender].mul(4).div(5);
            playerRound[msg.sender] = playerRound[msg.sender].add(1);
            boost[msg.sender] = 1;
        }
    }
    
    // WinRound
    // Called when a player gives enough Pecans to Wonkers
    // Gives his earnings to winner
    
    function WinRound(address _msgSender) private {
        
        //Increment round
        uint256 _round = gameRound;
        gameRound = gameRound.add(1);
        
        //Compute reward and adjust pot
        uint256 _reward = jackPot.div(5);
        jackPot = jackPot.sub(_reward);
        
        //Reset pecan given to 0
        pecanGiven = 0;
        
        //Set new pecan requirement
        pecanToWin = ComputePecanToWin();
    
        //Send reward
        playerBalance[_msgSender] = playerBalance[_msgSender].add(_reward);
        
        emit WonRound(_msgSender, _round, _reward);
    }
    
    // PotSplit
	// Allocates the ETH of every transaction
	// 40% treePot, 30% wonkPot, 20% jackPot, 10% thronePot
    
    function PotSplit(uint256 _msgValue) private {
        
        treePot = treePot.add(_msgValue.mul(4).div(10));
        wonkPot = wonkPot.add(_msgValue.mul(3).div(10));
        jackPot = jackPot.add(_msgValue.div(5));
        thronePot = thronePot.add(_msgValue.div(10));
    }
    
    //-- GAME ACTIONS --
    
    // PlantRoot
    // Gives player treeSize and pecan
    // Sets lastRootPlant and lastClaim to now
    
    function PlantRoot() public payable {
        require(tx.origin == msg.sender, "no contracts allowed");
        require(msg.value >= 0.001 ether, "at least 1 finney to plant a root");

        //Check if player is in correct round
        CheckRound();

        //Split ETH to pot
        PotSplit(msg.value);
        
        //Set new pecan requirement
        pecanToWin = ComputePecanToWin();
        
        //Get pecans to give
        uint256 _newPecan = ComputePlantPecan(msg.value);
        
        //Set claims to now
        lastRootPlant = now;
        lastClaim[msg.sender] = now;
        
        //Get treeSize to give
        uint256 _treePlant = msg.value.div(TREE_SIZE_COST);
        
        //Add player treeSize
        treeSize[msg.sender] = treeSize[msg.sender].add(_treePlant);
        
        //Add player pecans
        pecan[msg.sender] = pecan[msg.sender].add(_newPecan);
        
        emit PlantedRoot(msg.sender, msg.value, _newPecan, treeSize[msg.sender]);
    }
    
    // GivePecan
    // Exchanges player Pecans for ETH
	// Wins the round if enough Pecans are given
    
    function GivePecan(uint256 _pecanGift) public {
        require(pecan[msg.sender] >= _pecanGift, "not enough pecans");
        
        //Check if player is in correct round
        CheckRound();
        
        //Get reward
        uint256 _ethReward = ComputeWonkTrade(_pecanGift);
        
        //Lower player pecan
        pecan[msg.sender] = pecan[msg.sender].sub(_pecanGift);
        
        //Adjust pecan given
        pecanGiven = pecanGiven.add(_pecanGift);
        
        //Lower wonkPot
        wonkPot = wonkPot.sub(_ethReward);
        
        //Give reward
        playerBalance[msg.sender] = playerBalance[msg.sender].add(_ethReward);
        
        //Check if player Wins
        if(pecanGiven >= pecanToWin){
            WinRound(msg.sender);
        } else {
			emit GavePecan(msg.sender, _ethReward, _pecanGift);
		}
    }
    
    // ClaimShare
    // Gives player his share of ETH, and Pecans
    // Sets his lastClaim to now
    
    function ClaimShare() public {
        require(treeSize[msg.sender] > 0, "plant a root first");
		
        //Check if player is in correct round
        CheckRound();
        
        //Get ETH reward
        uint256 _ethReward = ComputeEtherShare(msg.sender);
        
        //Get Pecan reward
        uint256 _pecanReward = ComputePecanShare(msg.sender);
        
        //Set lastClaim
        lastClaim[msg.sender] = now;
        
        //Lower treePot
        treePot = treePot.sub(_ethReward);
        
        //Give rewards
        pecan[msg.sender] = pecan[msg.sender].add(_pecanReward);
        playerBalance[msg.sender] = playerBalance[msg.sender].add(_ethReward);
        
        emit ClaimedShare(msg.sender, _ethReward, _pecanReward);
    }
    
    // GrowTree
    // Uses player share to grow his treeSize
    // Gives share pecans multiplied by boost
    // Increases boost if last claim was at least one hour ago
    
    function GrowTree() public {
        require(treeSize[msg.sender] > 0, "plant a root first");

        //Check if player is in correct round
        CheckRound();
        
        //Get ETH used
        uint256 _ethUsed = ComputeEtherShare(msg.sender);
        
        //Get Pecan reward
        uint256 _pecanReward = ComputePecanShare(msg.sender);
        
        //Check if player gets a boost increase
        uint256 _timeSpent = now.sub(lastClaim[msg.sender]);
        
        //Set lastClaim
        lastClaim[msg.sender] = now;
        
        //Get treeSize to give
        uint256 _treeGrowth = _ethUsed.div(TREE_SIZE_COST);
        
        //Add player treeSize
        treeSize[msg.sender] = treeSize[msg.sender].add(_treeGrowth);
        
        //Give boost if eligible (maximum +10 at once)
        if(_timeSpent >= SECONDS_IN_HOUR){
            uint256 _boostPlus = _timeSpent.div(SECONDS_IN_HOUR);
            if(_boostPlus > 10){
                _boostPlus = 10;
            }
            boost[msg.sender] = boost[msg.sender].add(_boostPlus);
        }
        
        //Give Pecan reward
        pecan[msg.sender] = pecan[msg.sender].add(_pecanReward);
        
        emit GrewTree(msg.sender, _ethUsed, _pecanReward, boost[msg.sender]);
    }
    
    //-- MISC ACTIONS --
    
    // WithdrawBalance
    // Withdraws the ETH balance of a player to his wallet
    
    function WithdrawBalance() public {
        require(playerBalance[msg.sender] > 0, "no ETH in player balance");
        
        uint _amount = playerBalance[msg.sender];
        playerBalance[msg.sender] = 0;
        msg.sender.transfer(_amount);
        
        emit WithdrewBalance(msg.sender, _amount);
    }
    
    // PayThrone
    // Sends thronePot to SnailThrone
    
    function PayThrone() public {
        uint256 _payThrone = thronePot;
        thronePot = 0;
        if (!SNAILTHRONE.call.value(_payThrone)()){
            revert();
        }
        
        emit PaidThrone(msg.sender, _payThrone);
    }
    
    // fallback function
    // Feeds the jackPot
    
    function() public payable {
        jackPot = jackPot.add(msg.value);
        
        emit BoostedPot(msg.sender, msg.value);
    }
    
    //-- CALCULATIONS --
    
    // ComputeEtherShare
    // Returns ETH reward for a claim
    // Reward = 0.00000002 ETH per treeSize per day
    
    function ComputeEtherShare(address adr) public view returns(uint256) {
        
        //Get time since last claim
        uint256 _timeLapsed = now.sub(lastClaim[adr]);
        
        //Compute reward
        uint256 _reward = _timeLapsed.mul(REWARD_SIZE_ETH).mul(treeSize[adr]).div(SECONDS_IN_DAY);
        
        //Check reward isn't above remaining treePot
        if(_reward >= treePot){
            _reward = treePot;
        }
        return _reward;
    }
    
    // ComputeShareBoostFactor
    // Returns current personal Pecan multiplier
    // Starts at 4, adds 1 per hour
    
    function ComputeShareBoostFactor(address adr) public view returns(uint256) {
        
        //Get time since last claim
        uint256 _timeLapsed = now.sub(lastClaim[adr]);
        
        //Compute boostFactor (starts at 4, +1 per hour)
        uint256 _boostFactor = (_timeLapsed.div(SECONDS_IN_HOUR)).add(4);
        return _boostFactor;
    }
    
    // ComputePecanShare
    // Returns Pecan reward for a claim
    // Reward = 1 Pecan per treeSize per day, multiplied by personal boost
    
    function ComputePecanShare(address adr) public view returns(uint256) {
        
        //Get time since last claim
        uint256 _timeLapsed = now.sub(lastClaim[adr]);
        
        //Get boostFactor
        uint256 _shareBoostFactor = ComputeShareBoostFactor(adr);
        
        //Compute reward
        uint256 _reward = _timeLapsed.mul(treeSize[adr]).mul(_shareBoostFactor).mul(boost[msg.sender]).div(SECONDS_IN_DAY);
        return _reward;
    }
    
    // ComputePecanToWin
    // Returns amount of Pecans that must be given to win the round
    // Pecans to win = 1B + (1B per 0.2 ETH in jackpot) 
    
    function ComputePecanToWin() public view returns(uint256) {
        uint256 _pecanToWin = jackPot.div(PECAN_WIN_FACTOR);
        return _pecanToWin;
    }
    
    // ComputeWonkTrade
    // Returns ETH reward for a given amount of Pecans
    // % of wonkPot rewarded = (Pecans gifted / Pecans to win) / 2, maximum 50% 
    
    function ComputeWonkTrade(uint256 _pecanGift) public view returns(uint256) {
        
        //Make sure gift isn't above requirement to win
        if(_pecanGift > pecanToWin) {
            _pecanGift = pecanToWin;
        }
        uint256 _reward = _pecanGift.mul(wonkPot).div(pecanToWin).div(2);
        return _reward;
    }
    
    // ComputePlantBoostFactor
    // Returns global boost multiplier
    // +1% per second
    
    function ComputePlantBoostFactor() public view returns(uint256) {
        
        //Get time since last global plant
        uint256 _timeLapsed = now.sub(lastRootPlant);
        
        //Compute boostFactor (starts at 100, +1 per second)
        uint256 _boostFactor = (_timeLapsed.mul(1)).add(100);
        return _boostFactor;
    }
    
    // ComputePlantPecan
    // Returns Pecan reward for a given buy
    // 1 Pecan per the cost of 1 Tree Size, multiplied by global boost
    
    function ComputePlantPecan(uint256 _msgValue) public view returns(uint256) {

        //Get boostFactor
        uint256 _treeBoostFactor = ComputePlantBoostFactor();
        
        //Compute reward 
        uint256 _reward = _msgValue.mul(_treeBoostFactor).div(TREE_SIZE_COST).div(100);
        return _reward;
    }

    //-- GETTERS --
    
    function GetTree(address adr) public view returns(uint256) {
        return treeSize[adr];
    }
    
    function GetPecan(address adr) public view returns(uint256) {
        return pecan[adr];
    }
	
	function GetMyBoost() public view returns(uint256) {
        return boost[msg.sender];
    }
	
	function GetMyBalance() public view returns(uint256) {
	    return playerBalance[msg.sender];
	}
	
	function GetMyRound() public view returns(uint256) {
	    return playerRound[msg.sender];
	}
	
	function GetMyLastClaim() public view returns(uint256) {
	    return lastClaim[msg.sender];
	}
}

/* SafeMath library */

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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