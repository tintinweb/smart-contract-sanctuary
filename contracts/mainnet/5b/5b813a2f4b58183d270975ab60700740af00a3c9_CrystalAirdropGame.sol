pragma solidity ^0.4.24;

/*
* CrystalAirdropGame
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
contract CryptoMiningWarInterface {
	uint256 public roundNumber;
    uint256 public deadline; 
    function addCrystal( address _addr, uint256 _value ) public {}
}
contract CrystalAirdropGame {
	using SafeMath for uint256;

	address public administrator;
	// mini game
    uint256 public MINI_GAME_TIME_DEFAULT = 60 * 5;
    uint256 public MINI_GAME_PRIZE_CRYSTAL = 100;
    uint256 public MINI_GAME_BETWEEN_TIME = 8 hours;
    uint256 public MINI_GAME_ADD_TIME_DEFAULT = 15;
    address public miningWarContractAddress;
    uint256 public miniGameId = 0;
    uint256 public noRoundMiniGame;
    CryptoMiningWarInterface public MiningWarContract;
    /** 
    * Admin can set the bonus of game&#39;s reward
    */
    uint256 public MINI_GAME_BONUS = 100;
    /** 
    * @dev mini game information
    */
    mapping(uint256 => MiniGame) public minigames;
    /** 
    * @dev player information
    */
    mapping(address => PlayerData) public players;
   
    struct MiniGame {
        uint256 miningWarRoundNumber;
        bool ended; 
        uint256 prizeCrystal;
        uint256 startTime;
        uint256 endTime;
        address playerWin;
        uint256 totalPlayer;
    }
    struct PlayerData {
        uint256 currentMiniGameId;
        uint256 lastMiniGameId; 
        uint256 win;
        uint256 share;
        uint256 totalJoin;
        uint256 miningWarRoundNumber;
    }
    event eventEndMiniGame(
        address playerWin,
        uint256 crystalBonus
    );
    event eventJoinMiniGame(
        uint256 totalJoin
    );
    modifier disableContract()
    {
        require(tx.origin == msg.sender);
        _;
    }

    constructor() public {
        administrator = msg.sender;
        // set interface main contract
        miningWarContractAddress = address(0xf84c61bb982041c030b8580d1634f00fffb89059);
        MiningWarContract = CryptoMiningWarInterface(miningWarContractAddress);
    }

    /** 
    * @dev MainContract used this function to verify game&#39;s contract
    */
    function isContractMiniGame() public pure returns( bool _isContractMiniGame )
    {
    	_isContractMiniGame = true;
    }

    /** 
    * @dev set discount bonus for game 
    * require is administrator
    */
    function setDiscountBonus( uint256 _discountBonus ) public 
    {
        require( administrator == msg.sender );
        MINI_GAME_BONUS = _discountBonus;
    }

    /** 
    * @dev Main Contract call this function to setup mini game.
    * @param _miningWarRoundNumber is current main game round number
    * @param _miningWarDeadline Main game&#39;s end time
    */
    function setupMiniGame( uint256 _miningWarRoundNumber, uint256 _miningWarDeadline ) public
    {
        require(minigames[ miniGameId ].miningWarRoundNumber < _miningWarRoundNumber && msg.sender == miningWarContractAddress);
        // rerest current mini game to default
        minigames[ miniGameId ] = MiniGame(0, true, 0, 0, 0, 0x0, 0);
        noRoundMiniGame = 0;         
        startMiniGame();	
    }

    /**
    * @dev start the mini game
    */
    function startMiniGame() private 
    {      
        uint256 miningWarRoundNumber = getMiningWarRoundNumber();

        require(minigames[ miniGameId ].ended == true);
        // caculate information for next mini game
        uint256 currentPrizeCrystal;
        if ( noRoundMiniGame == 0 ) {
            currentPrizeCrystal = SafeMath.div(SafeMath.mul(MINI_GAME_PRIZE_CRYSTAL, MINI_GAME_BONUS),100);
        } else {
            uint256 rate = 168 * MINI_GAME_BONUS;

            currentPrizeCrystal = SafeMath.div(SafeMath.mul(minigames[miniGameId].prizeCrystal, rate), 10000); // price * 168 / 100 * MINI_GAME_BONUS / 100 
        }

        uint256 startTime = now + MINI_GAME_BETWEEN_TIME;
        uint256 endTime = startTime + MINI_GAME_TIME_DEFAULT;
        noRoundMiniGame = noRoundMiniGame + 1;
        // start new round mini game
        miniGameId = miniGameId + 1;
        minigames[ miniGameId ] = MiniGame(miningWarRoundNumber, false, currentPrizeCrystal, startTime, endTime, 0x0, 0);
    }

    /**
    * @dev end Mini Game&#39;s round
    */
    function endMiniGame() private  
    {  
        require(minigames[ miniGameId ].ended == false && (minigames[ miniGameId ].endTime <= now ));
        
        uint256 crystalBonus = SafeMath.div( SafeMath.mul(minigames[ miniGameId ].prizeCrystal, 50), 100 );
        // update crystal bonus for player win
        if (minigames[ miniGameId ].playerWin != 0x0) {
            PlayerData storage p = players[minigames[ miniGameId ].playerWin];
            p.win =  p.win + crystalBonus;
        }
        // end current mini game
        minigames[ miniGameId ].ended = true;
        emit eventEndMiniGame(minigames[ miniGameId ].playerWin, crystalBonus);
        // start new mini game
        startMiniGame();
    }

    /**
    * @dev player join this round
    */
    function joinMiniGame() public disableContract
    {        
        require(now >= minigames[ miniGameId ].startTime && minigames[ miniGameId ].ended == false);
        
        PlayerData storage p = players[msg.sender];
        if (now <= minigames[ miniGameId ].endTime) {
            // update player data in current mini game
            if (p.currentMiniGameId == miniGameId) {
                p.totalJoin = p.totalJoin + 1;
            } else {
                // if player join an new mini game then update share of last mini game for this player 
                updateShareCrystal();
                p.currentMiniGameId = miniGameId;
                p.totalJoin = 1;
                p.miningWarRoundNumber = minigames[ miniGameId ].miningWarRoundNumber;
            }
            // update information for current mini game 
            if ( p.totalJoin <= 1 ) { // this player into the current mini game for the first time 
                minigames[ miniGameId ].totalPlayer = minigames[ miniGameId ].totalPlayer + 1;
            }
            minigames[ miniGameId ].playerWin = msg.sender;
            minigames[ miniGameId ].endTime = minigames[ miniGameId ].endTime + MINI_GAME_ADD_TIME_DEFAULT;
            emit eventJoinMiniGame(p.totalJoin);
        } else {
            // need run end round
            if (minigames[ miniGameId ].playerWin == 0x0) {
                updateShareCrystal();
                p.currentMiniGameId = miniGameId;
                p.lastMiniGameId = miniGameId;
                p.totalJoin = 1;
                p.miningWarRoundNumber = minigames[ miniGameId ].miningWarRoundNumber;

                minigames[ miniGameId ].playerWin = msg.sender;
            }
            endMiniGame();
        }
    }

    /**
    * @dev update share bonus for player who join the game
    */
    function updateShareCrystal() private
    {
        uint256 miningWarRoundNumber = getMiningWarRoundNumber();
        PlayerData storage p = players[msg.sender];
        // check current mini game of player join. if mining war start new round then reset player data 
        if ( p.miningWarRoundNumber != miningWarRoundNumber) {
            p.share = 0;
            p.win = 0;
        } else if (minigames[ p.currentMiniGameId ].ended == true && p.lastMiniGameId < p.currentMiniGameId && minigames[ p.currentMiniGameId ].miningWarRoundNumber == miningWarRoundNumber) {
            // check current mini game of player join, last update mini game and current mining war round id
            // require this mini game is children of mining war game( is current mining war round id ) 
            p.share = SafeMath.add(p.share, calculateShareCrystal(p.currentMiniGameId));
            p.lastMiniGameId = p.currentMiniGameId;
        }
    }

    /**
    * @dev claim crystals
    */
    function claimCrystal() public
    {
        // should run end round
        if ( minigames[miniGameId].endTime < now ) {
            endMiniGame();
        }
        updateShareCrystal(); 
        // update crystal for this player to main game
        uint256 crystalBonus = players[msg.sender].win + players[msg.sender].share;
        MiningWarContract.addCrystal(msg.sender,crystalBonus); 
        // update player data. reset value win and share of player
        PlayerData storage p = players[msg.sender];
        p.win = 0;
        p.share = 0;
    	
    }

    /**
    * @dev calculate share crystal of player
    */
    function calculateShareCrystal(uint256 _miniGameId) public view returns(uint256 _share)
    {
        PlayerData memory p = players[msg.sender];
        if ( p.lastMiniGameId >= p.currentMiniGameId && p.currentMiniGameId != 0) {
            _share = 0;
        } else {
            _share = SafeMath.div( SafeMath.div( SafeMath.mul(minigames[ _miniGameId ].prizeCrystal, 50), 100 ), minigames[ _miniGameId ].totalPlayer );
        }
    }

    function getMiningWarDealine () private view returns( uint256 _dealine )
    {
        _dealine = MiningWarContract.deadline();
    }

    function getMiningWarRoundNumber () private view returns( uint256 _roundNumber )
    {
        _roundNumber = MiningWarContract.roundNumber();
    }
}