pragma solidity ^0.4.24;

/* SNAILFARM 3

// SnailFarm 3 is an idlegame in which you buy or sell eggs,
// Which you can hatch into snails, who continuously produce more eggs
// The goal of the game is to reach 1 million snails.
// At that point, you win the round (and the ETH jackpot that comes with it)

// SnailFarm 3 is the latest of a series of iterations over a few months.
// We will attempt to identify the key strengths of each of these iterations
// Focus on refining these features, in order to make for a fun, simple and
// Sustainable experience.

// Shrimpfarm&#39;s killer feature: buying and selling eggs directly to the smart contract.
// Snailfarm 1: capturing and holding the Snailmaster position, a ruler collecting dividends.
// Snailfarm 2: juggling with hot potato boosts to increase hatch size.

// SnailFarm 3 in a nutshell:

// The game is played in rounds.
// Buy your starting snails once, play every round at your convenience.
// Player snails are reinitialised at the end of each round.
// Losing players receive "red eggs" as a percentage of their snails.
// Red eggs persist from round to round.
// Red eggs can be hatched as regular eggs for no ETH cost, or used to claim boosts.

// Eggs can be bought and sold directly to the contract.
// No more than 20% of the egg supply can be bought at once.
// On sale, price is divided by 2.

// Hatching eggs into snails come with a slight, fixed, ETH cost.
// The size of a hatch can be improved with special boosts.
// Each boost adds a fixed bonus of an extra full hatch.
// One boost means double hatch. Three boosts means quadruple hatch.
// Two types of boosts exist: hot potato, and personal.

// Hot potato boosts: only one player can hold any of these at a time.
// The price of hot potato boosts rises with each player claim.
// The price of hot potato boosts is reinitialised as the round ends.
// Owners keep hot potato boosts between rounds, until another player claims them.
// SPIDERQUEEN- requires snails. Amount doubles with each claim.
// SQUIRRELDUKE- requires red eggs. Amount doubles with each claim.
// TADPOLEPRINCE- requires ETH. Amount raises by 20% with each claim,
// and the previous owner receives 110% of the ETH he spent.

// Personal boosts: all players can hold them.
// Each personal boost has different rules.

// SLUG- this boost persists between rounds.
// Slug requires a snail sacrifice of at least 100,000 snails.
// It will sacrifice ALL the snails the player own at the moment of the claim.

// LETTUCE- this boost lasts for only one round.
// Lettuce requires red eggs.
// The price of lettuce starts high, and decreases with each lettuce buy.
// The price of lettuce is reinitialised and increases from round to round.

// CARROT- this boost lasts for three rounds in a row.
// Carrot requires ETH.
// The price of carrot is fixed at 0.02 ETH.

// The Snailmaster position as in SnailFarm 1 returns with a twist.
// While still a hot potato, becoming the Snailmaster now requires red eggs.
// That requirement doubles with each claim, and halves between each round.
// Being the Snailmaster persists between rounds.
// The Snailmaster gets a significant cut of every ETH transaction.

// New mechanic: Red Harvest
// The red harvest lets players purchase red eggs for ETH.
// The red harvest works as a dutch auction, similar to cryptokitties.
// Starting price is equal to the current round pot.
// End price is a trivial amount of ETH.
// The auction lasts at most 4 hours.
// Price drops sharply at first, and slower near the end.
// The red harvest contains as many red eggs as the starting snail amount.
// When a player buys the red harvest, a new one is immediately put for sale.

// Bankroll: players can fund the game and receive acorns in exchange.
// Acorns cannot be sold or actively used in any way.
// Acorn holders receive 10% of the ETH invested, proportional to their share.
// Acorns start at half-price to encourage early funding kickstarting the game.
// After that, acorn price slowly decreases from round to round.
// Potential dilution of early holdings encourages refunding the bankroll later on.

// SnailFarm 3 is part of the SnailThrone ecosystem.
// A portion of the ETH spent in SnailFarm 3 is saved as throneDivs.
// SnailThrone holders are rewarded proportionally by throneDivs.

// ETH of every SnailFarm 3 transaction is split as such:
// 50% to the snailPot
// 25% to the eggPot
// 10% to the acorn holders
// 10% to the throneDivs
// 5% to the SnailMaster

*/

contract SnailFarm3 {
    using SafeMath for uint;
    
    /* Event */
    
    event FundedTree (address indexed player, uint eth, uint acorns);
    event ClaimedShare (address indexed player, uint eth, uint acorns);
    event BecameMaster (address indexed player, uint indexed round);
    event WithdrewBalance (address indexed player, uint eth);
    event Hatched (address indexed player, uint eggs, uint snails, uint hatchery);
    event SoldEgg (address indexed player, uint eggs, uint eth);
    event BoughtEgg (address indexed player, uint eggs, uint eth, uint playereggs);
    event StartedSnailing (address indexed player, uint indexed round);
    event BecameQueen (address indexed player, uint indexed round, uint spiderreq, uint hatchery);
    event BecameDuke (address indexed player, uint indexed round, uint squirrelreq, uint playerreds);
    event BecamePrince (address indexed player, uint indexed round, uint tadpolereq);
    event WonRound (address indexed roundwinner, uint indexed round, uint eth);
    event BeganRound (uint indexed round);
    event JoinedRound (address indexed player, uint indexed round, uint playerreds);
    event GrabbedHarvest (address indexed player, uint indexed round, uint eth, uint playerreds);
    event UsedRed (address indexed player, uint eggs, uint snails, uint hatchery);
    event FoundSlug (address indexed player, uint indexed round, uint snails);
    event FoundLettuce (address indexed player, uint indexed round, uint lettucereq, uint playerreds);
    event FoundCarrot (address indexed player, uint indexed round);
    event PaidThrone (address indexed player, uint eth);
    event BoostedPot (address indexed player, uint eth);

    /* Constants */
    
    uint256 public constant START_TIMESTAMP      = 0; //set to 1544904000 for launch on 15th december at 8pm GMT
    uint256 public constant TIME_TO_HATCH_1SNAIL = 86400; //seconds in a day
    uint256 public constant STARTING_SNAIL       = 300;
    uint256 public constant FROGKING_REQ         = 1000000;
    uint256 public constant ACORN_PRICE          = 0.001 ether;
    uint256 public constant ACORN_MULT           = 10;
    uint256 public constant STARTING_SNAIL_COST  = 0.004 ether;
    uint256 public constant HATCHING_COST        = 0.0008 ether;
    uint256 public constant SPIDER_BASE_REQ      = 80;
    uint256 public constant SQUIRREL_BASE_REQ    = 2;
    uint256 public constant TADPOLE_BASE_REQ     = 0.02 ether;
    uint256 public constant SLUG_MIN_REQ         = 100000;
    uint256 public constant LETTUCE_BASE_REQ     = 20;
    uint256 public constant CARROT_COST          = 0.02 ether;
    uint256 public constant HARVEST_COUNT        = 300;
    uint256 public constant HARVEST_DURATION     = 14400; //4 hours in seconds
    uint256 public constant HARVEST_DUR_ROOT     = 120; //saves computation
    uint256 public constant HARVEST_MIN_COST     = 0.002 ether;
    uint256 public constant SNAILMASTER_REQ      = 4096;
    uint256 public constant ROUND_DOWNTIME       = 43200; //12 hours between rounds
    address public constant SNAILTHRONE          = 0xc9F2B548Ccbfb8d909D4f0925DcE0096dD02c8C6; // Ropsten SnailThrone. Mainnet: 0x261d650a521103428C6827a11fc0CBCe96D74DBc

    /* Variables */
    
	//False for downtime between rounds, true when round is ongoing
    bool public gameActive             = false;
	
	//Used to ensure a proper game start
    address public dev;
	
	//Current round
    uint256 public round                = 0;
	
	//Current top snail holder
	address public currentLeader;
	
	//Owners of hot potatoes
    address public currentSpiderOwner;
    address public currentTadpoleOwner;
	address public currentSquirrelOwner;
	address public currentSnailmaster;
	
	//Current requirement for hot potatoes
	uint256 public spiderReq;
    uint256 public tadpoleReq;
	uint256 public squirrelReq;
	
	//Current requirement for lettuce
	uint256 public lettuceReq;
	
	//Current requirement for Snailmaster
	uint256 public snailmasterReq       = SNAILMASTER_REQ;
	
	//Starting time for next round
	uint256 public nextRoundStart;
	
	//Starting price for Red Harvest auction
	uint256 public harvestStartCost;
	
	//Starting time for Red Harvest auction
	uint256 public harvestStartTime;
	
	//Current number of acorns over all holders
	uint256 public maxAcorn             = 0;
	
	//Current divs per acorn
	uint256 public divPerAcorn          = 0;
	
	//Current number of eggs for sale
    uint256 public marketEgg            = 0;
		
	//Reserve pot and round jackpot
    uint256 public snailPot             = 0;
    uint256 public roundPot             = 0;
    
	//Egg pot
    uint256 public eggPot               = 0;
    
    //SnailThrone div pot
    uint256 public thronePot            = 0;

    /* Mappings */
    
	mapping (address => bool) public hasStartingSnail;
	mapping (address => bool) public hasSlug;
	mapping (address => bool) public hasLettuce;
	mapping (address => uint256) public gotCarrot;
	mapping (address => uint256) public playerRound;
    mapping (address => uint256) public hatcherySnail;
    mapping (address => uint256) public claimedEgg;
    mapping (address => uint256) public lastHatch;
    mapping (address => uint256) public redEgg;
    mapping (address => uint256) public playerBalance;
    mapping (address => uint256) public prodBoost;
    mapping (address => uint256) public acorn;
    mapping (address => uint256) public claimedShare;
    
    /* Functions */
    
    // Constructor
    // Assigns all hot potatoes to dev for a proper game start
    // (dev is banned from playing the game)
    
    constructor() public {
        nextRoundStart = START_TIMESTAMP;
        
        //Assigns hot potatoes to dev originally
        dev = msg.sender;
        currentSnailmaster = msg.sender;
        currentTadpoleOwner = msg.sender;
        currentSquirrelOwner = msg.sender;
        currentSpiderOwner = msg.sender;
        currentLeader = msg.sender;
        prodBoost[msg.sender] = 4; //base+tadpole+squirrel+spider
    }
    
    // BeginRound
    // Can be called by anyone to start a new round once downtime is over
    // Sets appropriate values, and starts new round
    
    function BeginRound() public {
        require(gameActive == false, "cannot start round while game is active");
        require(now > nextRoundStart, "round downtime isn&#39;t over");
        require(snailPot > 0, "cannot start round on empty pot");
        
        round = round.add(1);
		marketEgg = STARTING_SNAIL;
        roundPot = snailPot.div(10);
        spiderReq = SPIDER_BASE_REQ;
        tadpoleReq = TADPOLE_BASE_REQ;
        squirrelReq = SQUIRREL_BASE_REQ;
        lettuceReq = LETTUCE_BASE_REQ.mul(round);
        if(snailmasterReq > 2) {
            snailmasterReq = snailmasterReq.div(2);
        }
        harvestStartTime = now;
        harvestStartCost = roundPot;
        
        gameActive = true;
        
        emit BeganRound(round);
    }
    
    // FundTree
    // Buy a share of the bankroll
    // Acorn price lowers from round to round
    
    function FundTree() public payable {
        require(tx.origin == msg.sender, "no contracts allowed");
        
        uint256 _acornsBought = ComputeAcornBuy(msg.value);
        
        //Previous divs are considered claimed
        claimedShare[msg.sender] = claimedShare[msg.sender].add(_acornsBought.mul(divPerAcorn));
        
        //Add to maxAcorn
        maxAcorn = maxAcorn.add(_acornsBought);
        
        //Split ETH to pot
        PotSplit(msg.value);
        
        //Add player acorns
        acorn[msg.sender] = acorn[msg.sender].add(_acornsBought);
        
        emit FundedTree(msg.sender, msg.value, _acornsBought);
    }
    
    // ClaimAcornShare
    // Sends unclaimed dividends to playerBalance
    // Adjusts claimable dividends
    
    function ClaimAcornShare() public {
        
        uint256 _playerShare = ComputeMyShare();
        
        if(_playerShare > 0) {
            
            //Add new divs to claimed divs
            claimedShare[msg.sender] = claimedShare[msg.sender].add(_playerShare);
            
            //Send divs to playerEarnings
            playerBalance[msg.sender] = playerBalance[msg.sender].add(_playerShare);
            
            emit ClaimedShare(msg.sender, _playerShare, acorn[msg.sender]);
        }
    }
    
    // BecomeSnailmaster
    // Hot potato with red eggs 
    // Receives 5% of all incoming ETH
    // Requirement halves every round, doubles on every claim
	
    function BecomeSnailmaster() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(redEgg[msg.sender] >= snailmasterReq, "not enough red eggs");
        
        redEgg[msg.sender] = redEgg[msg.sender].sub(snailmasterReq);
        snailmasterReq = snailmasterReq.mul(2);
        currentSnailmaster = msg.sender;
        
        emit BecameMaster(msg.sender, round);
    }
    
    // WithdrawBalance
    // Withdraws the ETH balance of a player to his wallet
    
    function WithdrawBalance() public {
        require(playerBalance[msg.sender] > 0, "no ETH in player balance");
        
        uint _amount = playerBalance[msg.sender];
        playerBalance[msg.sender] = 0;
        msg.sender.transfer(_amount);
        
        emit WithdrewBalance(msg.sender, _amount);
    }
    
    // PotSplit
	// Allocates the ETH of every transaction
	// 50% snailpot, 25% eggpot, 10% to acorn holders, 10% thronepot, 5% snailmaster
    
    function PotSplit(uint256 _msgValue) private {
        
        snailPot = snailPot.add(_msgValue.div(2));
        eggPot = eggPot.add(_msgValue.div(4));
        thronePot = thronePot.add(_msgValue.div(10));
        
        //Increase div per acorn proportionally
        divPerAcorn = divPerAcorn.add(_msgValue.div(10).div(maxAcorn));
        
        //Snailmaster
        playerBalance[currentSnailmaster] = playerBalance[currentSnailmaster].add(_msgValue.div(20));
    }
    
    // JoinRound
    // Gives red egg reward to player and lets them join the new round
    
    function JoinRound() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] != round, "player already in current round");
        require(hasStartingSnail[msg.sender] == true, "buy starting snails first");
        
        uint256 _bonusRed = hatcherySnail[msg.sender].div(100);
        hatcherySnail[msg.sender] = STARTING_SNAIL;
        redEgg[msg.sender] = redEgg[msg.sender].add(_bonusRed);
        
        //Check if carrot is owned, remove 1 to count if so
        if(gotCarrot[msg.sender] > 0) {
            gotCarrot[msg.sender] = gotCarrot[msg.sender].sub(1);
            
            //Check if result puts us at 0, lower prodBoost if so
            if(gotCarrot[msg.sender] == 0) {
                prodBoost[msg.sender] = prodBoost[msg.sender].sub(1);
            }
        }
        
        //Check if lettuce is owned, lower prodBoost if so
        if(hasLettuce[msg.sender]) {
            prodBoost[msg.sender] = prodBoost[msg.sender].sub(1);
            hasLettuce[msg.sender] = false;
        }
        
		//Set lastHatch to now
		lastHatch[msg.sender] = now;
        playerRound[msg.sender] = round;
        
        emit JoinedRound(msg.sender, round, redEgg[msg.sender]);
    }
    
    // WinRound
    // Called when a player meets the snail requirement
    // Gives his earnings to winner
    // Pauses the game for 12 hours
    
    function WinRound(address _msgSender) private {
        
        gameActive = false;
        nextRoundStart = now.add(ROUND_DOWNTIME);
        
        hatcherySnail[_msgSender] = 0;
        snailPot = snailPot.sub(roundPot);
        playerBalance[_msgSender] = playerBalance[_msgSender].add(roundPot);
        
        emit WonRound(_msgSender, round, roundPot);
    }
    
    // HatchEgg
    // Hatches eggs into snails for a slight fixed ETH cost
    // If the player owns boosts, adjust result accordingly
    
    function HatchEgg() public payable {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(msg.value == HATCHING_COST, "wrong ETH cost");
        
        PotSplit(msg.value);
        uint256 eggUsed = ComputeMyEgg(msg.sender);
        uint256 newSnail = eggUsed.mul(prodBoost[msg.sender]);
        claimedEgg[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].add(newSnail);
        
        if(hatcherySnail[msg.sender] > hatcherySnail[currentLeader]) {
            currentLeader = msg.sender;
        }
        
        if(hatcherySnail[msg.sender] >= FROGKING_REQ) {
            WinRound(msg.sender);
        }
        
        emit Hatched(msg.sender, eggUsed, newSnail, hatcherySnail[msg.sender]);
    }
    
    // SellEgg
    // Exchanges player eggs for ETH
	// Eggs sold are added to the market
    
    function SellEgg() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        
        uint256 eggSold = ComputeMyEgg(msg.sender);
        uint256 eggValue = ComputeSell(eggSold);
        claimedEgg[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEgg = marketEgg.add(eggSold);
        eggPot = eggPot.sub(eggValue);
        playerBalance[msg.sender] = playerBalance[msg.sender].add(eggValue);
        
        emit SoldEgg(msg.sender, eggSold, eggValue);
    }
    
    // BuyEgg
    // Buy a calculated amount of eggs for a given amount of ETH
	
	// Eggs bought are removed from the market
    
    function BuyEgg() public payable {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        
        uint256 _eggBought = ComputeBuy(msg.value);
        
        //Define final buy price
        uint256 _ethSpent = msg.value;
        
        //Refund player if he overpays. maxBuy is a fourth of eggPot
        //(a/a+b) implies 1/4 of b gets the maximum 20% supply
        uint256 _maxBuy = eggPot.div(4);
        if (msg.value > _maxBuy) {
            uint _excess = msg.value.sub(_maxBuy);
            playerBalance[msg.sender] = playerBalance[msg.sender].add(_excess);
            _ethSpent = _maxBuy;
        }  
        
        PotSplit(_ethSpent);
        marketEgg = marketEgg.sub(_eggBought);
        claimedEgg[msg.sender] = claimedEgg[msg.sender].add(_eggBought);
        
        emit BoughtEgg(msg.sender, _eggBought, _ethSpent, hatcherySnail[msg.sender]);
    }
    
    // BuyStartingSnail
    // Gives starting snails and sets prodBoost to 1
    
    function BuyStartingSnail() public payable {
        require(gameActive, "game is paused");
        require(tx.origin == msg.sender, "no contracts allowed");
        require(hasStartingSnail[msg.sender] == false, "player already active");
        require(msg.value == STARTING_SNAIL_COST, "wrongETH cost");
        require(msg.sender != dev, "shoo shoo, developer");

        PotSplit(msg.value);
		hasStartingSnail[msg.sender] = true;
        lastHatch[msg.sender] = now;
		prodBoost[msg.sender] = 1;
		playerRound[msg.sender] = round;
        hatcherySnail[msg.sender] = STARTING_SNAIL;
        
        emit StartedSnailing(msg.sender, round);
    }
    
    // GrabRedHarvest
    // Gets red eggs for ETH
    // Works as a dutch auction
    
    function GrabRedHarvest() public payable {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        
        //Check current harvest cost
        uint256 _harvestCost = ComputeHarvest();
        require(msg.value >= _harvestCost);
        
        //If player sent more ETH than needed, refund excess to playerBalance
        if (msg.value > _harvestCost) {
            uint _excess = msg.value.sub(_harvestCost);
            playerBalance[msg.sender] = playerBalance[msg.sender].add(_excess);
        }
        
        PotSplit(_harvestCost);
        
        //Reset the harvest
        harvestStartCost = roundPot;
        harvestStartTime = now;
        
        //Give red eggs to player
        redEgg[msg.sender] = redEgg[msg.sender].add(HARVEST_COUNT);
        
        emit GrabbedHarvest(msg.sender, round, msg.value, redEgg[msg.sender]);
    }
    
    // UseRedEgg
    // Hatches a defined number of red eggs into snails
    // No ETH cost
    
    function UseRedEgg(uint256 _redAmount) public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(redEgg[msg.sender] >= _redAmount, "not enough red eggs");
        
        redEgg[msg.sender] = redEgg[msg.sender].sub(_redAmount);
        uint256 _newSnail = _redAmount.mul(prodBoost[msg.sender]);
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].add(_newSnail);
        
        if(hatcherySnail[msg.sender] > hatcherySnail[currentLeader]) {
            currentLeader = msg.sender;
        }
        
        if(hatcherySnail[msg.sender] >= FROGKING_REQ) {
            WinRound(msg.sender);
        }
        
        emit UsedRed(msg.sender, _redAmount, _newSnail, hatcherySnail[msg.sender]);
    }
    
    // FindSlug
    // Sacrifices all the snails the player owns (minimum 100k)
    // Raises his prodBoost by 1 permanently
    
    function FindSlug() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(hasSlug[msg.sender] == false, "already owns slug");
        require(hatcherySnail[msg.sender] >= SLUG_MIN_REQ, "not enough snails");
        
		uint256 _sacrifice = hatcherySnail[msg.sender];
        hatcherySnail[msg.sender] = 0;
        hasSlug[msg.sender] = true;
        prodBoost[msg.sender] = prodBoost[msg.sender].add(1);

        emit FoundSlug(msg.sender, round, _sacrifice);
    }
    
    // FindLettuce
    // Exchanges red eggs for lettuce (+1 prodBoost for the round)
    // Lowers next lettuce requirement
    
    function FindLettuce() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(hasLettuce[msg.sender] == false, "already owns lettuce");
        require(redEgg[msg.sender] >= lettuceReq, "not enough red eggs");
        
        uint256 _eventLettuceReq = lettuceReq;
        redEgg[msg.sender] = redEgg[msg.sender].sub(lettuceReq);
        lettuceReq = lettuceReq.sub(LETTUCE_BASE_REQ);
        if(lettuceReq < LETTUCE_BASE_REQ) {
            lettuceReq = LETTUCE_BASE_REQ;
        }
        
        hasLettuce[msg.sender] = true;
        prodBoost[msg.sender] = prodBoost[msg.sender].add(1);

        emit FoundLettuce(msg.sender, round, _eventLettuceReq, redEgg[msg.sender]);
    }
    
    // FindCarrot
    // Trades ETH for carrot (+1 prodBoost for 3 rounds)
    
    function FindCarrot() public payable {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(gotCarrot[msg.sender] == 0, "already owns carrot");
        require(msg.value == CARROT_COST);
        
        PotSplit(msg.value);
        gotCarrot[msg.sender] = 3;
        prodBoost[msg.sender] = prodBoost[msg.sender].add(1);

        emit FoundCarrot(msg.sender, round);
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
    
    // BecomeSpiderQueen
    // Increases playerProdBoost while held, obtained with a snail sacrifice
	// Hot potato item, requirement doubles with every buy
    
    function BecomeSpiderQueen() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(hatcherySnail[msg.sender] >= spiderReq, "not enough snails");

        // Remove sacrificed snails, increase req
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].sub(spiderReq);
        spiderReq = spiderReq.mul(2);
        
        // Lower prodBoost of old spider owner
        prodBoost[currentSpiderOwner] = prodBoost[currentSpiderOwner].sub(1);
        
        // Give ownership to msg.sender, then increases his prodBoost
        currentSpiderOwner = msg.sender;
        prodBoost[currentSpiderOwner] = prodBoost[currentSpiderOwner].add(1);
        
        emit BecameQueen(msg.sender, round, spiderReq, hatcherySnail[msg.sender]);
    }
	
	// BecomeSquirrelDuke
	// Increases playerProdBoost while held, obtained with a red egg sacrifice
    // Hot potato item, requirement doubles with every buy
    
    function BecomeSquirrelDuke() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(redEgg[msg.sender] >= squirrelReq, "not enough red eggs");
        
        // Remove red eggs spent, increase req
        redEgg[msg.sender] = redEgg[msg.sender].sub(squirrelReq);
        squirrelReq = squirrelReq.mul(2);
        
        // Lower prodBoost of old squirrel owner
        prodBoost[currentSquirrelOwner] = prodBoost[currentSquirrelOwner].sub(1);
        
        // Give ownership to msg.sender, then increases his prodBoost
        currentSquirrelOwner = msg.sender;
        prodBoost[currentSquirrelOwner] = prodBoost[currentSquirrelOwner].add(1);
        
        emit BecameDuke(msg.sender, round, squirrelReq, redEgg[msg.sender]);
    }
    
    // BecomeTadpolePrince
    // Increases playerProdBoost while held, obtained with ETH
	
    // Hot potato item, price increases by 20% with every buy
    
    function BecomeTadpolePrince() public payable {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(msg.value >= tadpoleReq, "not enough ETH");
        
        // If player sent more ETH than needed, refund excess to playerBalance
        if (msg.value > tadpoleReq) {
            uint _excess = msg.value.sub(tadpoleReq);
            playerBalance[msg.sender] = playerBalance[msg.sender].add(_excess);
        }  
        
        // Calculate +10% from previous price
        // Give result to the potsplit
        uint _extra = tadpoleReq.div(12); 
        PotSplit(_extra);
        
        // Calculate 110% of previous price
        // Give result to the previous owner
        uint _previousFlip = tadpoleReq.mul(11).div(12);
        playerBalance[currentTadpoleOwner] = playerBalance[currentTadpoleOwner].add(_previousFlip);
        
        // Increase ETH required for next buy by 20%
        tadpoleReq = (tadpoleReq.mul(6)).div(5); 
        
        // Lower prodBoost of old tadpole owner
        prodBoost[currentTadpoleOwner] = prodBoost[currentTadpoleOwner].sub(1);
        
        // Give ownership to msg.sender, then increase his prodBoost
        currentTadpoleOwner = msg.sender;
        prodBoost[currentTadpoleOwner] = prodBoost[currentTadpoleOwner].add(1);
        
        emit BecamePrince(msg.sender, round, tadpoleReq);
    }
    
    // fallback function
    // Feeds the snailPot
    
    function() public payable {
        snailPot = snailPot.add(msg.value);
        
        emit BoostedPot(msg.sender, msg.value);
    }
    
    // ComputeAcornCost
    // Returns acorn cost at the current time
    // Before the game starts, acorns are at half cost
    // After the game is started, cost is multiplied by 10/(10+round)
    
    function ComputeAcornCost() public view returns(uint256) {
        uint256 _acornCost;
        if(round != 0) {
            _acornCost = ACORN_PRICE.mul(ACORN_MULT).div(ACORN_MULT.add(round));
        } else {
            _acornCost = ACORN_PRICE.div(2);
        }
        return _acornCost;
    }
    
    // ComputeAcornBuy
    // Returns acorn amount for a given amount of ETH
    
    function ComputeAcornBuy(uint256 _ether) public view returns(uint256) {
        uint256 _costPerAcorn = ComputeAcornCost();
        return _ether.div(_costPerAcorn);
    }
    
    // ComputeMyShare
    // Returns unclaimed share for the player
    
    function ComputeMyShare() public view returns(uint256) {
        //Calculate share of player
        uint256 _playerShare = divPerAcorn.mul(acorn[msg.sender]);
		
        //Subtract already claimed divs
    	_playerShare = _playerShare.sub(claimedShare[msg.sender]);
        return _playerShare;
    }
    
    // ComputeHarvest
    // Calculates current ETH cost to claim red harvest
    // Dutch auction
    
    function ComputeHarvest() public view returns(uint256) {

        //Time spent since auction start
        uint256 _timeLapsed = now.sub(harvestStartTime);
        
        //Make sure we&#39;re not beyond the end point
        if(_timeLapsed > HARVEST_DURATION) {
            _timeLapsed = HARVEST_DURATION;
        }
        
        //Get the square root of timeLapsed
        _timeLapsed = ComputeSquare(_timeLapsed);
        
        //Price differential between start and end of auction
        uint256 _priceChange = harvestStartCost.sub(HARVEST_MIN_COST);
        
        //Multiply priceChange by timeLapsed root then divide by end root
        uint256 _harvestFactor = _priceChange.mul(_timeLapsed).div(HARVEST_DUR_ROOT);
        
        //Subtract result to starting price to get current price
        return harvestStartCost.sub(_harvestFactor);
    }
    
    // ComputeSquare
    // Approximate square root
    
    function ComputeSquare(uint256 base) public pure returns (uint256 squareRoot) {
        uint256 z = (base + 1) / 2;
        squareRoot = base;
        while (z < squareRoot) {
            squareRoot = z;
            z = (base / z + z) / 2;
        }
    }
    
    // ComputeSell
	// Calculates ether value for a given amount of eggs being sold
	// ETH = (eggs / (eggs + marketeggs)) * eggpot / 2
	// A sale can never give more than half of the eggpot
    
    function ComputeSell(uint256 eggspent) public view returns(uint256) {
        uint256 _eggPool = eggspent.add(marketEgg);
        uint256 _eggFactor = eggspent.mul(eggPot).div(_eggPool);
        return _eggFactor.div(2);
    }
    
    // ComputeBuy
	// Calculates number of eggs bought for a given amount of ether
    // Eggs bought = ETH spent / (ETH spent + eggpot) * marketegg
    // No more than 20% of the supply can be bought at once
    
    function ComputeBuy(uint256 ethspent) public view returns(uint256) {
        uint256 _ethPool = ethspent.add(eggPot);
        uint256 _ethFactor = ethspent.mul(marketEgg).div(_ethPool);
        uint256 _maxBuy = marketEgg.div(5);
        if(_ethFactor > _maxBuy) {
            _ethFactor = _maxBuy;
        }
        return _ethFactor;
    }
    
    // ComputeMyEgg
    // Returns eggs produced since last hatch or sacrifice
	// Egg amount can never be above current snail count
    
    function ComputeMyEgg(address adr) public view returns(uint256) {
        uint256 _eggs = now.sub(lastHatch[adr]);
        _eggs = _eggs.mul(hatcherySnail[adr]).div(TIME_TO_HATCH_1SNAIL);
        if (_eggs > hatcherySnail[adr]) {
            _eggs = hatcherySnail[adr];
        }
        _eggs = _eggs.add(claimedEgg[adr]);
        return _eggs;
    }

    // Gets
    
    function GetSnail(address adr) public view returns(uint256) {
        return hatcherySnail[adr];
    }
    
    function GetAcorn(address adr) public view returns(uint256) {
        return acorn[adr];
    }
	
	function GetProd(address adr) public view returns(uint256) {
		return prodBoost[adr];
	}
    
    function GetMyEgg() public view returns(uint256) {
        return ComputeMyEgg(msg.sender);
    }
	
	function GetMyBalance() public view returns(uint256) {
	    return playerBalance[msg.sender];
	}
	
	function GetRed(address adr) public view returns(uint256) {
	    return redEgg[adr];
	}
	
	function GetLettuce(address adr) public view returns(bool) {
	    return hasLettuce[adr];
	}
	
	function GetCarrot(address adr) public view returns(uint256) {
	    return gotCarrot[adr];
	}
	
	function GetSlug(address adr) public view returns(bool) {
	    return hasSlug[adr];
	}
	
	function GetMyRound() public view returns(uint256) {
	    return playerRound[msg.sender];
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