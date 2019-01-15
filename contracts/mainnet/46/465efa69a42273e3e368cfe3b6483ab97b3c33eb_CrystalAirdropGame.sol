pragma solidity ^0.4.25;

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
    function addCrystal( address /*_addr*/, uint256 /*_value*/ ) public pure {}
    function isMiningWarContract() external pure returns(bool) {}
}
contract CrystalAirdropGame {
	using SafeMath for uint256;

	address public administrator;
	// mini game
    uint256 private ROUND_TIME_MINING_WAR = 86400 * 7;
    uint256 private BONUS_CRYSTAL = 5000000;
    uint256 public TIME_DAY = 24 hours;

    address public miningWarAddress;
    CryptoMiningWarInterface public MiningWar;
    /** 
    * @dev player information
    */
    mapping(address => Player) public players;
    mapping(uint256 => Airdrop) public airdrops;
   
    struct Player {
        uint256 miningWarRound;
        uint256 noJoinAirdrop; 
        uint256 lastDayJoin;
    }
    struct Airdrop {
        uint256 day;
        uint256 prizeCrystal;
    }
    event AirdropPrize(
        address playerJoin,
        uint256 crystalBonus,
        uint256 noJoinAirdrop,
        uint256 noDayStartMiningWar
    );

    constructor() public {
        administrator = msg.sender;
        // set interface main contract
        setMiningWarInterface(0x1b002cd1ba79dfad65e8abfbb3a97826e4960fe5);

        initAirdrop();
    }
    function initAirdrop() private {
        //                    day       prize crystals
        airdrops[0] = Airdrop(1,            5000);   
        airdrops[1] = Airdrop(2,            10000);   
        airdrops[2] = Airdrop(3,            20000);   
        airdrops[3] = Airdrop(4,            40000);   
        airdrops[4] = Airdrop(5,            60000);   
        airdrops[5] = Airdrop(6,            100000);   
        airdrops[6] = Airdrop(7,            200000);   
    }
    /** 
    * @dev MainContract used this function to verify game&#39;s contract
    */
    function isContractMiniGame() public pure returns( bool _isContractMiniGame )
    {
    	_isContractMiniGame = true;
    }
    function isAirdropContract() public pure returns(bool)
    {
        return true;
    }
    function setAirdropPrize(uint256 idx, uint256 value) public 
    {
       require( administrator == msg.sender );
       airdrops[idx].prizeCrystal = value; 
    }
     function setMiningWarInterface(address _addr) public 
    {
        require( administrator == msg.sender );
        
        CryptoMiningWarInterface miningWarInterface = CryptoMiningWarInterface(_addr);

        require(miningWarInterface.isMiningWarContract() == true);
        
        miningWarAddress = _addr;
        
        MiningWar = miningWarInterface;
    }

    function setupMiniGame(uint256 /*_miningWarRoundNumber*/, uint256 /*_miningWarDeadline*/ ) public pure
    {

    }

    function joinAirdrop() public 
    {   
        require(tx.origin == msg.sender);
        require(MiningWar.deadline() > now);

        Player storage p = players[msg.sender];
        
        uint256 miningWarRound      = MiningWar.roundNumber();
        uint256 timeEndMiningWar    = MiningWar.deadline() - now;
        uint256 noDayEndMiningWar   = SafeMath.div(timeEndMiningWar, TIME_DAY);

        if (noDayEndMiningWar > 7) revert();

        uint256 noDayStartMiningWar = SafeMath.sub(7, noDayEndMiningWar);
 
        if (p.miningWarRound != miningWarRound) {
            p.noJoinAirdrop = 1;
            p.miningWarRound= miningWarRound;
        } else if (p.lastDayJoin >= noDayStartMiningWar) {
            revert();
        } else {
            p.noJoinAirdrop += 1;
        }
        p.lastDayJoin = noDayStartMiningWar;

        airdropPrize(msg.sender);
    }

    function airdropPrize(address _addr) private
    {
       Player memory p = players[_addr];
       
       uint256 prizeCrystal = 0;
       if (p.lastDayJoin > 0 && p.lastDayJoin <= 7)
           prizeCrystal = airdrops[p.lastDayJoin - 1].prizeCrystal;
       if (p.noJoinAirdrop >= 7) 
           prizeCrystal = SafeMath.add(prizeCrystal, BONUS_CRYSTAL);  
       if (prizeCrystal != 0)
           MiningWar.addCrystal(_addr, prizeCrystal);

       emit AirdropPrize(_addr, prizeCrystal, p.noJoinAirdrop, p.lastDayJoin);
    }
    function getData(address _addr) public view returns(uint256 miningWarRound, uint256 noJoinAirdrop, uint256 lastDayJoin, uint256 nextTimeAirdropJoin)
    {
         Player memory p = players[_addr];

         miningWarRound = p.miningWarRound;
         noJoinAirdrop  = p.noJoinAirdrop;
         lastDayJoin    = p.lastDayJoin;
         nextTimeAirdropJoin = getNextTimeAirdropJoin(_addr);

        if (miningWarRound != MiningWar.roundNumber()) {
            noJoinAirdrop = 0;
            lastDayJoin   = 0;
        }   
    }
    function getNextCrystalReward(address _addr) public view returns(uint256)
    {
        Player memory p = players[_addr];
        uint256 miningWarRound      = MiningWar.roundNumber();
        uint256 timeStartMiningWar  = SafeMath.sub(MiningWar.deadline(), ROUND_TIME_MINING_WAR); 
        uint256 timeEndMiningWar    = MiningWar.deadline() - now;
        uint256 noDayEndMiningWar   = SafeMath.div(timeEndMiningWar, TIME_DAY);
        uint256 noDayStartMiningWar = SafeMath.sub(7, noDayEndMiningWar);

        if (noDayStartMiningWar > 7) return 0;
        if (p.lastDayJoin < noDayStartMiningWar) return airdrops[noDayStartMiningWar - 1].prizeCrystal; 
        return airdrops[noDayStartMiningWar].prizeCrystal;
    }
    function getNextTimeAirdropJoin(address _addr) public view returns(uint256)
    {
        Player memory p = players[_addr];

        uint256 miningWarRound      = MiningWar.roundNumber();
        uint256 timeStartMiningWar  = SafeMath.sub(MiningWar.deadline(), ROUND_TIME_MINING_WAR); 
        uint256 timeEndMiningWar    = MiningWar.deadline() - now;
        uint256 noDayEndMiningWar   = SafeMath.div(timeEndMiningWar, TIME_DAY);

        uint256 noDayStartMiningWar = SafeMath.sub(7, noDayEndMiningWar);

        if (p.miningWarRound != miningWarRound) return 0;

        if (p.lastDayJoin < noDayStartMiningWar) return 0;

        return SafeMath.add(SafeMath.mul(noDayStartMiningWar, TIME_DAY), timeStartMiningWar);
    }
}