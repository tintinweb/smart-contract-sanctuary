pragma solidity ^0.4.25;

/*
* CryptoMiningWar - Blockchain-based strategy game
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
    function isContractMiniGame() public pure returns( bool /*_isContractMiniGame*/) {}
    function isEngineerContract() external pure returns(bool) {}
}
contract CryptoMiningWarInterface {
    uint256 public deadline; 
    function subCrystal( address /*_addr*/, uint256 /*_value*/ ) public {}
    function isMiningWarContract() external pure returns(bool) {}
}
interface MiniGameInterface {
     function isContractMiniGame() external pure returns( bool _isContractMiniGame );
}
contract CrystalDeposit {
	using SafeMath for uint256;

	address public administrator;
	// mini game
    uint256 public HALF_TIME = 48 hours;
    uint256 public MIN_TIME_WITH_DEADLINE = 12 hours;
    uint256 public round = 0;
    CryptoEngineerInterface public Engineer;
    CryptoMiningWarInterface public MiningWar;
    // mining war info
    address miningWarAddress;
    uint256 miningWarDeadline;
    uint256 constant private CRTSTAL_MINING_PERIOD = 86400;
    /** 
    * @dev mini game information
    */
    mapping(uint256 => Game) public games;
    /** 
    * @dev player information
    */
    mapping(address => Player) public players;

    mapping(address => bool)   public miniGames;
   
    struct Game {
        uint256 round;
        uint256 crystals;
        uint256 prizePool;
        uint256 startTime;
        uint256 endTime;
        bool ended; 
    }
    struct Player {
        uint256 currentRound;
        uint256 lastRound;
        uint256 reward;
        uint256 share; // your crystals share in current round 
    }
    event EndRound(uint256 round, uint256 crystals, uint256 prizePool, uint256 startTime, uint256 endTime);
    event Deposit(address player, uint256 currentRound, uint256 deposit, uint256 currentShare);
    modifier isAdministrator()
    {
        require(msg.sender == administrator);
        _;
    }
    modifier disableContract()
    {
        require(tx.origin == msg.sender);
        _;
    }

    constructor() public {
        administrator = msg.sender;
        // set interface contract
        setMiningWarInterface(0x1b002cd1ba79dfad65e8abfbb3a97826e4960fe5);
        setEngineerInterface(0xd7afbf5141a7f1d6b0473175f7a6b0a7954ed3d2);
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
    function isDepositContract() public pure returns(bool)
    {
        return true;
    }
    function upgrade(address addr) public isAdministrator
    {
        selfdestruct(addr);
    }
    function setContractsMiniGame( address _addr ) public isAdministrator 
    {
        MiniGameInterface MiniGame = MiniGameInterface( _addr );
        if( MiniGame.isContractMiniGame() == false ) { revert(); }

        miniGames[_addr] = true;
    }
    /**
    * @dev remove mini game contract from main contract
    * @param _addr mini game contract address
    */
    function removeContractMiniGame(address _addr) public isAdministrator
    {
        miniGames[_addr] = false;
    }
    /** 
    * @dev Main Contract call this function to setup mini game.
    */
    function setupMiniGame( uint256 /*_miningWarRoundNumber*/, uint256 _miningWarDeadline ) public
    {
        require(msg.sender == miningWarAddress);
        miningWarDeadline = _miningWarDeadline;
    }
    function setMiningWarInterface(address _addr) public isAdministrator
    {
        CryptoMiningWarInterface miningWarInterface = CryptoMiningWarInterface(_addr);

        require(miningWarInterface.isMiningWarContract() == true);
        
        miningWarAddress = _addr;
        
        MiningWar = miningWarInterface;
    }
    function setEngineerInterface(address _addr) public isAdministrator
    {
        CryptoEngineerInterface engineerInterface = CryptoEngineerInterface(_addr);
        
        require(engineerInterface.isEngineerContract() == true);

        Engineer = engineerInterface;
    }
    /**
    * @dev start the mini game
    */
     function startGame() public isAdministrator
    {

        miningWarDeadline = MiningWar.deadline();

        games[round].ended = true;
    
        startRound();
    }
    function startRound() private
    {
        require(games[round].ended == true);

        uint256 crystalsLastRound = games[round].crystals;
        uint256 prizePoolLastRound= games[round].prizePool; 

        round = round + 1;

        uint256 startTime = now;

        if (miningWarDeadline < SafeMath.add(startTime, MIN_TIME_WITH_DEADLINE)) startTime = miningWarDeadline;

        uint256 endTime = startTime + HALF_TIME;
        // claim 5% of current prizePool as rewards.
        uint256 engineerPrizePool = getEngineerPrizePool();
        
        uint256 prizePool = SafeMath.div(SafeMath.mul(engineerPrizePool, 5),100);

        Engineer.claimPrizePool(address(this), prizePool);
        
        if (crystalsLastRound == 0) prizePool = SafeMath.add(prizePool, prizePoolLastRound);

        games[round] = Game(round, 0, prizePool, startTime, endTime, false);
    }
    function endRound() private
    {
        require(games[round].ended == false);
        require(games[round].endTime <= now);

        Game storage g = games[round];
        g.ended = true;
        
        startRound();

        emit EndRound(g.round, g.crystals, g.prizePool, g.startTime, g.endTime);
    }
    /**
    * @dev player send crystals to the pot
    */
    function share(uint256 _value) public disableContract
    {
        require(games[round].ended == false);
        require(games[round].startTime <= now);
        require(_value >= 1);

        MiningWar.subCrystal(msg.sender, _value); 

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

        emit Deposit(msg.sender, p.currentRound, _value, p.share); 
    }
    function getCurrentReward(address _addr) public view returns(uint256 _currentReward)
    {
        Player memory p = players[_addr];
        _currentReward = p.reward;
        _currentReward += calculateReward(_addr, p.currentRound);
    }
    function withdrawReward(address _addr) public 
    {
        // require(miniGames[msg.sender] == true);

        if (games[round].endTime <= now) endRound();
        
        updateReward(_addr);
        Player storage p = players[_addr];
        uint256 balance  = p.reward; 
        if (address(this).balance >= balance && balance > 0) {
             _addr.transfer(balance);
            // update player
            p.reward = 0;     
        }
    }
    function updateReward(address _addr) private
    {
        Player storage p = players[_addr];
        
        if ( 
            games[p.currentRound].ended == true &&
            p.lastRound < p.currentRound
            ) {
            p.reward = SafeMath.add(p.reward, calculateReward(msg.sender, p.currentRound));
            p.lastRound = p.currentRound;
        }
    }
    function getData(address _addr) 
    public
    view
    returns(
        // current game
        uint256 _prizePool,
        uint256 _crystals,
        uint256 _startTime,
        uint256 _endTime,
        // player info
        uint256 _reward,
        uint256 _share
    ) {
         (_prizePool, _crystals, _startTime, _endTime) = getCurrentGame();
         (_reward, _share)                 = getPlayerData(_addr);         
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
        if (p.lastRound >= _round) return 0; 
        return SafeMath.div(SafeMath.mul(g.prizePool, p.share), g.crystals);
    }
    function getCurrentGame() private view returns(uint256 _prizePool, uint256 _crystals, uint256 _startTime, uint256 _endTime)
    {
        Game memory g = games[round];
        _prizePool = g.prizePool;
        _crystals  = g.crystals;
        _startTime = g.startTime;
        _endTime   = g.endTime;
    }
    function getPlayerData(address _addr) private view returns(uint256 _reward, uint256 _share)
    {
        Player memory p = players[_addr];
        _reward           = p.reward;
        if (p.currentRound == round) _share = players[_addr].share; 
        if (p.currentRound != p.lastRound) _reward += calculateReward(_addr, p.currentRound);
    }
    function getEngineerPrizePool() private view returns(uint256)
    {
        return Engineer.prizePool();
    }
}