pragma solidity ^0.4.24;

/* SNAILFARM 2

// We keep the same basics as SnailFarm: hatch eggs into snails, buy or sell eggs for money.
// Hatching now comes with a small ETH cost.
// Your snails don&#39;t die anymore when you sell eggs.
// Referrals are gone.
// The formula for buying and selling eggs is simplified.
// Only a finite number of eggs is available for sale.
// This number is based on initial seed, and varies based on player buys and sells.
// Eggs sell for half of the current buy price.
// There is no more extra inflation tied to hatching.

// The ultimate goal of the game is the Snailmaster title.
// The reward is now a lump sum rather than a constant fee.
// To become Snailmaster, you need a certain number of snails.
// Once you take the Snailmaster title, you lose 90% of your snails.
// 20% of the snailpot is immediately paid out to the Snailmaster.
// When someone becomes the Snailmaster, a new round starts.
// The amount of snails required to claim the title increases with each new round.
// The amount of starting snails also increases by that same amount for new players.

// We introduce a new mechanic: the Ethertree.
// Every ETH added to the contract is split 50/50 between the snailpot and the treepot.
// Players can claim ETH from the ethertree through selling acorns.
// Players can buy acorns for twice their current price.
// (Half of the ETH goes in the snailpot, half of the ETH buys acorns at their going rate.)
// Players get a better rate on acorn buys if the current snailpot is under the previous snailpot.
// The price of acorns can only rise over time.

// We add three hot potato items: the SpiderQueen, the TadpolePrince, and the SquirrelDuke.
// Owning any of these boosts adds base hatch size to your hatch, cumulative.
// (With 2 boosts, you get 1+1+1 = 3 times the snails when you hatch your eggs.)
// The Tadpole Prince costs ETH, and rises by 20% with every buy.
// 10% goes to the previous holder, 5% goes to the snailpot, 5% to the treepot.
// The Spider Queen costs snails, this cost doubles with every buy.
// The Squirrel Duke costs acorns, this cost doubles with every buy.

*/

contract SnailFarm2 {
    using SafeMath for uint;
    
    /* Event */
    
    event SoldAcorn (address indexed seller, uint acorns, uint eth);
    event BoughtAcorn (address indexed buyer, uint acorns, uint eth);
    event BecameMaster (address indexed newmaster, uint indexed round, uint reward, uint pot);
    event WithdrewEarnings (address indexed player, uint eth);
    event Hatched (address indexed player, uint eggs, uint snails);
    event SoldEgg (address indexed seller, uint eggs, uint eth);
    event BoughtEgg (address indexed buyer, uint eggs, uint eth);
    event StartedSnailing (address indexed player, uint indexed round);
    event BecameQueen (address indexed newqueen, uint indexed round, uint newreq);
    event BecameDuke (address indexed newduke, uint indexed round, uint newreq);
    event BecamePrince (address indexed newprince, uint indexed round, uint newreq);

    /* Constants */
    
    uint256 public TIME_TO_HATCH_1SNAIL = 86400; //seconds in a day
    uint256 public STARTING_SNAIL       = 200;
    uint256 public SNAILMASTER_INCREASE = 100000;
    uint256 public STARTING_SNAIL_COST  = 0.004 ether;
    uint256 public HATCHING_COST        = 0.0008 ether;
    uint256 public SPIDER_BASE_REQ      = 80;
    uint256 public SPIDER_BOOST         = 1;
    uint256 public TADPOLE_BASE_REQ     = 0.02 ether;
    uint256 public TADPOLE_BOOST        = 1;
	uint256 public SQUIRREL_BASE_REQ    = 1;
    uint256 public SQUIRREL_BOOST       = 1;

	
    /* Variables */
    
	//Becomes true one time to start the game
    bool public gameStarted             = false;
	
	//Used to ensure a proper game start
    address public gameOwner;
	
	//Current round
    uint256 public round                = 0;
	
	//Owners of hot potatoes
    address public currentSpiderOwner;
    address public currentTadpoleOwner;
	address public currentSquirrelOwner;
	
	//Current requirement for hot potatoes
	uint256 public spiderReq;
    uint256 public tadpoleReq;
	uint256 public squirrelReq;
	
	//Current requirement for snailmaster
    uint256 public snailmasterReq       = SNAILMASTER_INCREASE;
    
    //Current amount of snails given to new players
	uint256 public startingSnailAmount  = STARTING_SNAIL;
	
	//Current number of eggs for sale
    uint256 public marketEggs;
	
	//Current number of acorns in existence
	uint256 public totalAcorns;
		
	//Ether pots
    uint256 public snailPot;
	uint256 public previousSnailPot;
    uint256 public treePot;

    	
    /* Mappings */
    
	mapping (address => bool) public hasStartingSnails;
    mapping (address => uint256) public hatcherySnail;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => uint256) public playerAcorns;
    mapping (address => uint256) public playerEarnings;
    mapping (address => uint256) public playerProdBoost;
    
	
    /* Functions */
    
    // Constructor
    // Sets msg.sender as gameOwner for SeedMarket purposes
    // Assigns all hot potatoes to gameOwner and sets his prodBoost accordingly
    // (gameOwner is banned from playing the game)
    
    constructor() public {
        gameOwner = msg.sender;
        
        currentTadpoleOwner = gameOwner;
        currentSquirrelOwner = gameOwner;
        currentSpiderOwner = gameOwner;
        hasStartingSnails[gameOwner] = true; //prevents buying starting snails
        playerProdBoost[gameOwner] = 4; //base+tadpole+squirrel+spider
    }
    
    // SeedMarket
    // Sets eggs and acorns, funds the pot, starts the game
	
	// 10000:1 ratio for _eggs:msg.value gives near parity with starting snails
	// Recommended ratio = 5000:1
	// Acorns can be any amount, the higher the better as we deal with integers
	// Recommended value = 1000000
	// 1% of the acorns are left without an owner
	// This prevents an infinite acorn price rise,
	// In the case of a complete acorn dump followed by egg buys
    
    function SeedMarket(uint256 _eggs, uint256 _acorns) public payable {
        require(msg.value > 0);
        require(round == 0);
        require(msg.sender == gameOwner);
        
        marketEggs = _eggs.mul(TIME_TO_HATCH_1SNAIL); //for readability
        snailPot = msg.value.div(10); //10% to the snailpot
        treePot = msg.value.sub(snailPot); //remainder to the treepot
		previousSnailPot = snailPot.mul(10); //encourage early acorn funding
        totalAcorns = _acorns; 
        playerAcorns[msg.sender] = _acorns.mul(99).div(100); 
        spiderReq = SPIDER_BASE_REQ;
        tadpoleReq = TADPOLE_BASE_REQ;
		squirrelReq = SQUIRREL_BASE_REQ;
        round = 1;
        gameStarted = true;
    }
    
    // SellAcorns
    // Takes a given amount of acorns, increases player ETH balance
    
    function SellAcorns(uint256 _acorns) public {
        require(playerAcorns[msg.sender] > 0);
        
        playerAcorns[msg.sender] = playerAcorns[msg.sender].sub(_acorns);
        uint256 _acornEth = ComputeAcornPrice().mul(_acorns);
        totalAcorns = totalAcorns.sub(_acorns);
        treePot = treePot.sub(_acornEth);
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_acornEth);
        
        emit SoldAcorn(msg.sender, _acorns, _acornEth);
    }
    
    // BuyAcorns
    // Takes a given amount of ETH, gives acorns in return
	
	// If current snailpot is under previous snailpot, 3 acorns for the price of 4
	// If current snailpot is equal or above, 1 acorn for the price of 
    
    function BuyAcorns() public payable {
        require(msg.value > 0);
        require(tx.origin == msg.sender);
        require(gameStarted);
        
		if (snailPot < previousSnailPot) {
			uint256 _acornBought = ((msg.value.div(ComputeAcornPrice())).mul(3)).div(4);
			AcornPotSplit(msg.value);
		} else {
			_acornBought = (msg.value.div(ComputeAcornPrice())).div(2);
			PotSplit(msg.value);
		}
        totalAcorns = totalAcorns.add(_acornBought);
        playerAcorns[msg.sender] = playerAcorns[msg.sender].add(_acornBought);
        
        emit BoughtAcorn(msg.sender, _acornBought, msg.value);
    }
    
    // BecomeSnailmaster
    // Gives out 20% of the snailpot and increments round for a snail sacrifice
	
    // Increases Snailmaster requirement
    // Resets Spider and Tadpole reqs to initial values
    
    function BecomeSnailmaster() public {
        require(gameStarted);
        require(hatcherySnail[msg.sender] >= snailmasterReq);
        
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].div(10);
        
        uint256 _snailReqIncrease = round.mul(SNAILMASTER_INCREASE);
        snailmasterReq = snailmasterReq.add(_snailReqIncrease);
        uint256 _startingSnailIncrease = round.mul(STARTING_SNAIL);
        startingSnailAmount = startingSnailAmount.add(_startingSnailIncrease);
        
        spiderReq = SPIDER_BASE_REQ;
        tadpoleReq = TADPOLE_BASE_REQ;
        squirrelReq = SQUIRREL_BASE_REQ;
        
        previousSnailPot = snailPot;
        uint256 _rewardSnailmaster = snailPot.div(5);
        snailPot = snailPot.sub(_rewardSnailmaster);
        round++;
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_rewardSnailmaster);
        
        emit BecameMaster(msg.sender, round, _rewardSnailmaster, snailPot);
    }
    
    // WithdrawEarnings
    // Withdraws all ETH earnings of a player to his wallet
    
    function WithdrawEarnings() public {
        require(playerEarnings[msg.sender] > 0);
        
        uint _amount = playerEarnings[msg.sender];
        playerEarnings[msg.sender] = 0;
        msg.sender.transfer(_amount);
        
        emit WithdrewEarnings(msg.sender, _amount);
    }
    
    // PotSplit
	// Splits value equally between the two pots
	
    // Should be called each time ether is spent on the game
    
    function PotSplit(uint256 _msgValue) private {
        uint256 _potBoost = _msgValue.div(2);
        snailPot = snailPot.add(_potBoost);
        treePot = treePot.add(_potBoost);
    }
	
	// AcornPotSplit	
    // Gives one fourth to the snailpot, three fourths to the treepot
    
	// Variant of PotSplit with a privileged rate
	// Encourages pot funding with each new round
	
    function AcornPotSplit(uint256 _msgValue) private {
        uint256 _snailBoost = _msgValue.div(4);
		uint256 _treeBoost = _msgValue.sub(_snailBoost);
        snailPot = snailPot.add(_snailBoost);
        treePot = treePot.add(_treeBoost);
    }
    
    // HatchEggs
    // Hatches eggs into snails for a slight ETH cost
	
    // If the player owns a hot potato, adjust prodBoost accordingly
    
    function HatchEggs() public payable {
        require(gameStarted);
        require(msg.value == HATCHING_COST);		
        
        PotSplit(msg.value);
        uint256 eggsUsed = ComputeMyEggs();
        uint256 newSnail = (eggsUsed.div(TIME_TO_HATCH_1SNAIL)).mul(playerProdBoost[msg.sender]);
        claimedEggs[msg.sender]= 0;
        lastHatch[msg.sender]= now;
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].add(newSnail);
        
        emit Hatched(msg.sender, eggsUsed, newSnail);
    }
    
    // SellEggs
    // Sells current player eggs for ETH at a snail cost
	
    // One fifth of the player&#39;s snails are killed
	// Eggs sold are added to the market
    
    function SellEggs() public {
        require(gameStarted);
        
        uint256 eggsSold = ComputeMyEggs();
        uint256 eggValue = ComputeSell(eggsSold);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = marketEggs.add(eggsSold);
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(eggValue);
        
        emit SoldEgg(msg.sender, eggsSold, eggValue);
    }
    
    // BuyEggs
    // Buy a calculated amount of eggs for a given amount of ETH
	
	// Eggs bought are removed from the market
    
    function BuyEggs() public payable {
        require(gameStarted);
        require(hasStartingSnails[msg.sender] == true);
        require(msg.sender != gameOwner);
        
        uint256 eggsBought = ComputeBuy(msg.value);
        PotSplit(msg.value);
        marketEggs = marketEggs.sub(eggsBought);
        claimedEggs[msg.sender] = claimedEggs[msg.sender].add(eggsBought);
        
        emit BoughtEgg(msg.sender, eggsBought, msg.value);
    }
    
    // BuyStartingSnails
    // Gives starting snails and sets playerProdBoost to 1
    
    function BuyStartingSnails() public payable {
        require(gameStarted);
        require(tx.origin == msg.sender);
        require(hasStartingSnails[msg.sender] == false);
        require(msg.value == STARTING_SNAIL_COST); 

        PotSplit(msg.value);
		hasStartingSnails[msg.sender] = true;
        lastHatch[msg.sender] = now;
		playerProdBoost[msg.sender] = 1;
        hatcherySnail[msg.sender] = startingSnailAmount;
        
        emit StartedSnailing(msg.sender, round);
    }
    
    // BecomeSpiderQueen
    // Increases playerProdBoost while held, obtained with a snail sacrifice
	
	// Hot potato item, requirement doubles with every buy
    
    function BecomeSpiderQueen() public {
        require(gameStarted);
        require(hatcherySnail[msg.sender] >= spiderReq);

        // Remove sacrificed snails, increase req
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].sub(spiderReq);
        spiderReq = spiderReq.mul(2);
        
        // Lower prodBoost of old spider owner
        playerProdBoost[currentSpiderOwner] = playerProdBoost[currentSpiderOwner].sub(SPIDER_BOOST);
        
        // Give ownership to msg.sender, then increases his prodBoost
        currentSpiderOwner = msg.sender;
        playerProdBoost[currentSpiderOwner] = playerProdBoost[currentSpiderOwner].add(SPIDER_BOOST);
        
        emit BecameQueen(msg.sender, round, spiderReq);
    }
	
	// BecomeSquirrelDuke
	// Increases playerProdBoost while held, obtained with an acorn sacrifice

    // Hot potato item, requirement doubles with every buy
    
    function BecomeSquirrelDuke() public {
        require(gameStarted);
        require(hasStartingSnails[msg.sender] == true);
        require(playerAcorns[msg.sender] >= squirrelReq);
        
        // Remove sacrificed acorns, change totalAcorns in consequence, increase req
        playerAcorns[msg.sender] = playerAcorns[msg.sender].sub(squirrelReq);
		totalAcorns = totalAcorns.sub(squirrelReq);
        squirrelReq = squirrelReq.mul(2);
        
        // Lower prodBoost of old squirrel owner
        playerProdBoost[currentSquirrelOwner] = playerProdBoost[currentSquirrelOwner].sub(SQUIRREL_BOOST);
        
        // Give ownership to msg.sender, then increases his prodBoost
        currentSquirrelOwner = msg.sender;
        playerProdBoost[currentSquirrelOwner] = playerProdBoost[currentSquirrelOwner].add(SQUIRREL_BOOST);
        
        emit BecameDuke(msg.sender, round, squirrelReq);
    }
    
    // BecomeTadpolePrince
    // Increases playerProdBoost while held, obtained with ETH
	
    // Hot potato item, price increases by 20% with every buy
    
    function BecomeTadpolePrince() public payable {
        require(gameStarted);
        require(hasStartingSnails[msg.sender] == true);
        require(msg.value >= tadpoleReq);
        
        // If player sent more ETH than needed, refund excess to playerEarnings
        if (msg.value > tadpoleReq) {
            uint _excess = msg.value.sub(tadpoleReq);
            playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_excess);
        }  
        
        // Calculate +10% from previous price
        // Give result to the potsplit
        uint _extra = tadpoleReq.div(12); 
        PotSplit(_extra);
        
        // Calculate 110% of previous price
        // Give result to the previous owner
        uint _previousFlip = tadpoleReq.mul(11).div(12);
        playerEarnings[currentTadpoleOwner] = playerEarnings[currentTadpoleOwner].add(_previousFlip);
        
        // Increase ETH required for next buy by 20%
        tadpoleReq = (tadpoleReq.mul(6)).div(5); 
        
        // Lower prodBoost of old tadpole owner
        playerProdBoost[currentTadpoleOwner] = playerProdBoost[currentTadpoleOwner].sub(TADPOLE_BOOST);
        
        // Give ownership to msg.sender, then increase his prodBoost
        currentTadpoleOwner = msg.sender;
        playerProdBoost[currentTadpoleOwner] = playerProdBoost[currentTadpoleOwner].add(TADPOLE_BOOST);
        
        emit BecamePrince(msg.sender, round, tadpoleReq);
    }
    
    // ComputeAcornPrice
	// Returns the current ether value of one acorn
	
    // Acorn price = treePot / totalAcorns
    
    function ComputeAcornPrice() public view returns(uint256) {
        return treePot.div(totalAcorns);
    }
    
    // ComputeSell
	// Calculates ether value for a given amount of eggs being sold
    
	// ETH = (eggs / (eggs + marketeggs)) * snailpot / 2
	// A sale can never give more than half of the snailpot
    
    function ComputeSell(uint256 eggspent) public view returns(uint256) {
        uint256 _eggPool = eggspent.add(marketEggs);
        uint256 _eggFactor = eggspent.mul(snailPot).div(_eggPool);
        return _eggFactor.div(2);
    }
    
    // ComputeBuy
	// Calculates number of eggs bought for a given amount of ether
	
    // Eggs bought = ETH spent / (ETH spent + snailpot) * marketeggs
    
    function ComputeBuy(uint256 ethspent) public view returns(uint256) {
        uint256 _ethPool = ethspent.add(snailPot);
        uint256 _ethFactor = ethspent.mul(marketEggs).div(_ethPool);
        return _ethFactor;
    }
    
    // ComputeMyEggs
    // Returns current player eggs
    
    function ComputeMyEggs() public view returns(uint256) {
        return claimedEggs[msg.sender].add(ComputeEggsSinceLastHatch(msg.sender));
    }
    
    // ComputeEggsSinceLastHatch
    // Returns eggs produced since last hatch
    
    function ComputeEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(TIME_TO_HATCH_1SNAIL , now.sub(lastHatch[adr]));
        return secondsPassed.mul(hatcherySnail[adr]);
    }
    
    // Helper function for CalculateEggsSinceLastHatch
	// If a < b, return a
	// Else, return b
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    // Gets
    
    function GetMySnail() public view returns(uint256) {
        return hatcherySnail[msg.sender];
    }
	
	function GetMyProd() public view returns(uint256) {
		return playerProdBoost[msg.sender];
	}
    
    function GetMyEgg() public view returns(uint256) {
        return ComputeMyEggs().div(TIME_TO_HATCH_1SNAIL);
    }
    
    function GetMyAcorn() public view returns(uint256) {
        return playerAcorns[msg.sender];
    }
	
	function GetMyEarning() public view returns(uint256) {
	    return playerEarnings[msg.sender];
	}
}

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