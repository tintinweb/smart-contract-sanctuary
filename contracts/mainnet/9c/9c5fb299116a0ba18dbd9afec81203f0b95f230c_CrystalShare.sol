pragma solidity ^0.4.25;

/*
* CryptoMiningWar - Mining Contest Game
* Author: InspiGames
* Website: https://cryptominingwar.github.io/
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

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
contract CryptoEngineerInterface {
    uint256 public prizePool = 0;

    function subVirus(address /*_addr*/, uint256 /*_value*/) public {}
    function claimPrizePool(address /*_addr*/, uint256 /*_value*/) public {} 
}
contract CryptoMiningWarInterface {
    uint256 public deadline; 
    function subCrystal( address /*_addr*/, uint256 /*_value*/ ) public {}
}
contract CrystalShare {
	using SafeMath for uint256;

    bool init = false;
	address public administrator;
	// mini game
    uint256 public HALF_TIME = 60 * 5;
    uint256 public round = 0;
    CryptoEngineerInterface public EngineerContract;
    CryptoMiningWarInterface public MiningWarContract;
    // mining war info
    uint256 public miningWarDeadline;
    uint256 constant public CRTSTAL_MINING_PERIOD = 86400;
    /** 
    * @dev mini game information
    */
    mapping(uint256 => Game) public games;
    /** 
    * @dev player information
    */
    mapping(address => Player) public players;
   
    struct Game {
        uint256 round;
        uint256 crystals;
        uint256 prizePool;
        uint256 endTime;
        bool ended; 
    }
    struct Player {
        uint256 currentRound;
        uint256 lastRound;
        uint256 reward;
        uint256 share; // your crystals share in current round 
    }
    event EndRound(uint256 round, uint256 crystals, uint256 prizePool, uint256 endTime);
    modifier disableContract()
    {
        require(tx.origin == msg.sender);
        _;
    }

    constructor() public {
        administrator = msg.sender;
        // set interface contract
        MiningWarContract = CryptoMiningWarInterface(0xf84c61bb982041c030b8580d1634f00fffb89059);
        EngineerContract = CryptoEngineerInterface(0x69fd0e5d0a93bf8bac02c154d343a8e3709adabf);
    }
    function () public payable
    {
        
    }
    /** 
    * @dev MainContract used this function to verify game&#39;s contract
    */
    function isContractMiniGame() public pure returns( bool _isContractMiniGame )
    {
    	_isContractMiniGame = true;
    }

    /** 
    * @dev Main Contract call this function to setup mini game.
    */
    function setupMiniGame( uint256 /*_miningWarRoundNumber*/, uint256 _miningWarDeadline ) public
    {
        miningWarDeadline = _miningWarDeadline;
    }
    /**
    * @dev start the mini game
    */
     function startGame() public 
    {
        require(msg.sender == administrator);
        require(init == false);
        init = true;
        miningWarDeadline = getMiningWarDealine();

        games[round].ended = true;
    
        startRound();
    }
    function startRound() private
    {
        require(games[round].ended == true);

        uint256 crystalsLastRound = games[round].crystals;
        uint256 prizePoolLastRound= games[round].prizePool; 

        round = round + 1;

        uint256 endTime = now + HALF_TIME;
        // claim 5% of current prizePool as rewards.
        uint256 engineerPrizePool = getEngineerPrizePool();
        uint256 prizePool = SafeMath.div(SafeMath.mul(engineerPrizePool, 5),100);
        if (crystalsLastRound <= 0) {
            prizePool = SafeMath.add(prizePool, prizePoolLastRound);
        } 

        EngineerContract.claimPrizePool(address(this), prizePool);
        games[round] = Game(round, 0, prizePool, endTime, false);
    }
    function endRound() private
    {
        require(games[round].ended == false);
        require(games[round].endTime <= now);

        Game storage g = games[round];
        g.ended = true;
        
        startRound();

        emit EndRound(g.round, g.crystals, g.prizePool, g.endTime);
    }
    /**
    * @dev player send crystals to the pot
    */
    function share(uint256 _value) public disableContract
    {
        require(miningWarDeadline > now);
        require(games[round].ended == false);
        require(_value >= 10000);

        MiningWarContract.subCrystal(msg.sender, _value); 

        if (games[round].endTime <= now) endRound();
        
        updateReward(msg.sender);
        
        Game storage g = games[round];
        uint256 _share = SafeMath.mul(_value, CRTSTAL_MINING_PERIOD);
        g.crystals = SafeMath.add(g.crystals, _share);
        Player storage p = players[msg.sender];
        if (p.currentRound == round) {
            p.share = SafeMath.add(p.share, _share);
        } else {
            p.share = _share;
            p.currentRound = round;
        } 
    }
    function withdrawReward() public disableContract
    {
        if (games[round].endTime <= now) endRound();
        
        updateReward(msg.sender);
        Player storage p = players[msg.sender];
        
        msg.sender.send(p.reward);
        // update player
        p.reward = 0;
    }
    function updateReward(address _addr) private
    {
        Player storage p = players[_addr];
        
        if ( 
            games[p.currentRound].ended == true &&
            p.lastRound < p.currentRound
            ) {
            p.reward = SafeMath.add(p.share, calculateReward(msg.sender, p.currentRound));
            p.lastRound = p.currentRound;
        }
    }
      /**
    * @dev calculate reward
    */
    function calculateReward(address _addr, uint256 _round) public view returns(uint256)
    {
        Player memory p = players[_addr];
        Game memory g = games[_round];
        if (g.endTime > now) return 0;
        if (g.crystals == 0) return 0; 
        return SafeMath.div(SafeMath.mul(g.prizePool, p.share), g.crystals);
    }
    function getEngineerPrizePool() private view returns(uint256)
    {
        return EngineerContract.prizePool();
    }
    function getMiningWarDealine () private view returns(uint256)
    {
        return MiningWarContract.deadline();
    }
}