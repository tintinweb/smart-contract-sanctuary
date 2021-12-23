/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

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

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev Withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(address(this).balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    payee.transfer(payment);
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}
interface CryptoMiningWarInterface {
    function calCurrentCrystals(address /*_addr*/) external view returns(uint256 /*_currentCrystals*/);
    function subCrystal( address /*_addr*/, uint256 /*_value*/ ) external pure;
    function fallback() external payable;
    function isMiningWarContract() external pure returns(bool);
}
interface MiniGameInterface {
    function isContractMiniGame() external pure returns( bool _isContractMiniGame );
    function fallback() external payable;
}
contract CryptoEngineer is PullPayment{
    // engineer info
	address public administrator;
    uint256 public prizePool = 0;
    uint256 public numberOfEngineer = 8;
    uint256 public numberOfBoosts = 5;
    address public gameSponsor;
    uint256 public gameSponsorPrice = 0.32 ether;
    uint256 public VIRUS_MINING_PERIOD = 86400; 
    
    // mining war game infomation
    uint256 public CRTSTAL_MINING_PERIOD = 86400;
    uint256 public BASE_PRICE = 0.01 ether;

    address public miningWarAddress; 
    CryptoMiningWarInterface   public MiningWar;
    
    // engineer player information
    mapping(address => Player) public players;
    // engineer boost information
    mapping(uint256 => BoostData) public boostData;
    // engineer information
    mapping(uint256 => EngineerData) public engineers;
    
    // minigame info
    mapping(address => bool) public miniGames; 
    
    struct Player {
        mapping(uint256 => uint256) engineersCount;
        uint256 virusNumber;
        uint256 research;
        uint256 lastUpdateTime;
        bool endLoadOldData;
    }
    struct BoostData {
        address owner;
        uint256 boostRate;
        uint256 basePrice;
    }
    struct EngineerData {
        uint256 basePrice;
        uint256 baseETH;
        uint256 baseResearch;
        uint256 limit;
    }
    modifier disableContract()
    {
        require(tx.origin == msg.sender);
        _;
    }
    modifier isAdministrator()
    {
        require(msg.sender == administrator);
        _;
    }
    modifier onlyContractsMiniGame() 
    {
        require(miniGames[msg.sender] == true);
        _;
    }

    event BuyEngineer(address _addr, uint256[8] engineerNumbers, uint256 _crytalsPrice, uint256 _ethPrice, uint256 _researchBuy);
    event BuyBooster(address _addr, uint256 _boostIdx, address beneficiary);
    event ChangeVirus(address _addr, uint256 _virus, uint256 _type); // 1: add, 2: sub
    event BecomeGameSponsor(address _addr, uint256 _price);
    event UpdateResearch(address _addr, uint256 _currentResearch);

    //--------------------------------------------------------------------------
    // INIT CONTRACT 
    //--------------------------------------------------------------------------
    constructor() public {
        administrator = msg.sender;

        initBoostData();
        initEngineer();
        // set interface main contract
        setMiningWarInterface(0xE0760338A6a06E96Cf7848b6DC4E0aBc9373f9e2);        
    }
    function initEngineer() private
    {
        //                          price crystals    price ETH         research  limit                         
        engineers[0] = EngineerData(10,               BASE_PRICE * 0,   10,       10   );   //lv1 
        engineers[1] = EngineerData(50,               BASE_PRICE * 1,   3356,     2    );   //lv2
        engineers[2] = EngineerData(200,              BASE_PRICE * 2,   8390,     4    );   //lv3
        engineers[3] = EngineerData(800,              BASE_PRICE * 4,   20972,    8    );   //lv4
        engineers[4] = EngineerData(3200,             BASE_PRICE * 8,   52430,    16   );   //lv5
        engineers[5] = EngineerData(12800,            BASE_PRICE * 16,  131072,   32   );   //lv6
        engineers[6] = EngineerData(102400,           BASE_PRICE * 32,  327680,   64   );   //lv7
        engineers[7] = EngineerData(819200,           BASE_PRICE * 64,  819200,   65536);   //lv8
    }
    function initBoostData() private 
    {
        boostData[0] = BoostData(0x0, 150, BASE_PRICE * 1);
        boostData[1] = BoostData(0x0, 175, BASE_PRICE * 2);
        boostData[2] = BoostData(0x0, 200, BASE_PRICE * 4);
        boostData[3] = BoostData(0x0, 225, BASE_PRICE * 8);
        boostData[4] = BoostData(0x0, 250, BASE_PRICE * 16);
    }
    /** 
    * @dev MainContract used this function to verify game's contract
    */
    function isContractMiniGame() public pure returns(bool _isContractMiniGame)
    {
    	_isContractMiniGame = true;
    }
    function isEngineerContract() public pure returns(bool)
    {
        return true;
    }
    function () public payable
    {
        addPrizePool(msg.value);
    }
    /** 
    * @dev Main Contract call this function to setup mini game.
    */
    function setupMiniGame( uint256 /*_miningWarRoundNumber*/, uint256 /*_miningWarDeadline*/ ) public
    {
        require(msg.sender == miningWarAddress);
        MiningWar.fallback.value(SafeMath.div(SafeMath.mul(prizePool, 5), 100))();
        prizePool = SafeMath.sub(prizePool, SafeMath.div(SafeMath.mul(prizePool, 5), 100));
    }
    //--------------------------------------------------------------------------
    // SETTING CONTRACT MINI GAME 
    //--------------------------------------------------------------------------
    function setMiningWarInterface(address _addr) public isAdministrator
    {
        CryptoMiningWarInterface miningWarInterface = CryptoMiningWarInterface(_addr);

        require(miningWarInterface.isMiningWarContract() == true);
        
        miningWarAddress = _addr;
        
        MiningWar = miningWarInterface;
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
    //@dev use this function in case of bug
    function upgrade(address addr) public isAdministrator
    {
        selfdestruct(addr);
    }
    //--------------------------------------------------------------------------
    // BOOSTER 
    //--------------------------------------------------------------------------
    function buyBooster(uint256 idx) public payable 
    {
        require(idx < numberOfBoosts);
        BoostData storage b = boostData[idx];

        if (msg.value < b.basePrice || msg.sender == b.owner) revert();
        
        address beneficiary = b.owner;
        uint256 devFeePrize = devFee(b.basePrice);
        
        distributedToOwner(devFeePrize);
        addMiningWarPrizePool(devFeePrize);
        addPrizePool(SafeMath.sub(msg.value, SafeMath.mul(devFeePrize,3)));
        
        updateVirus(msg.sender);

        if ( beneficiary != 0x0 ) updateVirus(beneficiary);
        
        // transfer ownership    
        b.owner = msg.sender;

        emit BuyBooster(msg.sender, idx, beneficiary );
    }
    function getBoosterData(uint256 idx) public view returns (address _owner,uint256 _boostRate, uint256 _basePrice)
    {
        require(idx < numberOfBoosts);
        BoostData memory b = boostData[idx];
        _owner = b.owner;
        _boostRate = b.boostRate; 
        _basePrice = b.basePrice;
    }
    function hasBooster(address addr) public view returns (uint256 _boostIdx)
    {         
        _boostIdx = 999;
        for(uint256 i = 0; i < numberOfBoosts; i++){
            uint256 revert_i = numberOfBoosts - i - 1;
            if(boostData[revert_i].owner == addr){
                _boostIdx = revert_i;
                break;
            }
        }
    }
    //--------------------------------------------------------------------------
    // GAME SPONSOR
    //--------------------------------------------------------------------------
    /**
    */
    function becomeGameSponsor() public payable disableContract
    {
        uint256 gameSponsorPriceFee = SafeMath.div(SafeMath.mul(gameSponsorPrice, 150), 100);
        require(msg.value >= gameSponsorPriceFee);
        require(msg.sender != gameSponsor);
        // 
        uint256 repayPrice = SafeMath.div(SafeMath.mul(gameSponsorPrice, 110), 100);
        gameSponsor.transfer(repayPrice);
        
        // add to prize pool
        addPrizePool(SafeMath.sub(msg.value, repayPrice));
        // update game sponsor info
        gameSponsor = msg.sender;
        gameSponsorPrice = gameSponsorPriceFee;

        emit BecomeGameSponsor(msg.sender, msg.value);
    }


    function addEngineer(address _addr, uint256 idx, uint256 _value) public isAdministrator
    {
        require(idx < numberOfEngineer);
        require(_value != 0);

        Player storage p = players[_addr];
        EngineerData memory e = engineers[idx];

        if (SafeMath.add(p.engineersCount[idx], _value) > e.limit) revert();

        updateVirus(_addr);

        p.engineersCount[idx] = SafeMath.add(p.engineersCount[idx], _value);

        updateResearch(_addr, SafeMath.mul(_value, e.baseResearch));
    }

    // ----------------------------------------------------------------------------------------
    // USING FOR MINI GAME CONTRACT
    // ---------------------------------------------------------------------------------------
    function setBoostData(uint256 idx, address owner, uint256 boostRate, uint256 basePrice)  public onlyContractsMiniGame
    {
        require(owner != 0x0);
        BoostData storage b = boostData[idx];
        b.owner     = owner;
        b.boostRate = boostRate;
        b.basePrice = basePrice;
    }
    function setGameSponsorInfo(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        gameSponsor      = _addr;
        gameSponsorPrice = _value;
    }
    function setPlayerLastUpdateTime(address _addr) public onlyContractsMiniGame
    {
        require(players[_addr].endLoadOldData == false);
        players[_addr].lastUpdateTime = now;
        players[_addr].endLoadOldData = true;
    }
    function setPlayerEngineersCount( address _addr, uint256 idx, uint256 _value) public onlyContractsMiniGame
    {
         players[_addr].engineersCount[idx] = _value;
    }
    function setPlayerResearch(address _addr, uint256 _value) public onlyContractsMiniGame
    {        
        players[_addr].research = _value;
    }
    function setPlayerVirusNumber(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        players[_addr].virusNumber = _value;
    }
    function addResearch(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        updateVirus(_addr);

        Player storage p = players[_addr];

        p.research = SafeMath.add(p.research, _value);

        emit UpdateResearch(_addr, p.research);
    }
    function subResearch(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        updateVirus(_addr);

        Player storage p = players[_addr];
        
        if (p.research < _value) revert();
        
        p.research = SafeMath.sub(p.research, _value);

        emit UpdateResearch(_addr, p.research);
    }
    /**
    * @dev add virus for player
    * @param _addr player address
    * @param _value number of virus
    */
    function addVirus(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        Player storage p = players[_addr];

        uint256 additionalVirus = SafeMath.mul(_value,VIRUS_MINING_PERIOD);
        
        p.virusNumber = SafeMath.add(p.virusNumber, additionalVirus);

        emit ChangeVirus(_addr, _value, 1);
    }
    /**
    * @dev subtract virus of player
    * @param _addr player address 
    * @param _value number virus subtract 
    */
    function subVirus(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        updateVirus(_addr);

        Player storage p = players[_addr];
        
        uint256 subtractVirus = SafeMath.mul(_value,VIRUS_MINING_PERIOD);
        
        if ( p.virusNumber < subtractVirus ) { revert(); }

        p.virusNumber = SafeMath.sub(p.virusNumber, subtractVirus);

        emit ChangeVirus(_addr, _value, 2);
    }
    /**
    * @dev claim price pool to next new game
    * @param _addr mini game contract address
    * @param _value eth claim;
    */
    function claimPrizePool(address _addr, uint256 _value) public onlyContractsMiniGame 
    {
        require(prizePool > _value);

        prizePool = SafeMath.sub(prizePool, _value);

        MiniGameInterface MiniGame = MiniGameInterface( _addr );
        
        MiniGame.fallback.value(_value)();
    }
    //--------------------------------------------------------------------------
    // PLAYERS
    //--------------------------------------------------------------------------
    /**
    */
    function buyEngineer(uint256[8] engineerNumbers) public payable disableContract
    {        
        updateVirus(msg.sender);

        Player storage p = players[msg.sender];
        
        uint256 priceCrystals = 0;
        uint256 priceEth = 0;
        uint256 research = 0;
        for (uint256 engineerIdx = 0; engineerIdx < numberOfEngineer; engineerIdx++) {
            uint256 engineerNumber = engineerNumbers[engineerIdx];
            EngineerData memory e = engineers[engineerIdx];
            // require for engineerNumber 
            if(engineerNumber > e.limit || engineerNumber < 0) revert();
            
            // engineer you want buy
            if (engineerNumber > 0) {
                uint256 currentEngineerCount = p.engineersCount[engineerIdx];
                // update player data
                p.engineersCount[engineerIdx] = SafeMath.min(e.limit, SafeMath.add(p.engineersCount[engineerIdx], engineerNumber));
                // calculate no research you want buy
                research = SafeMath.add(research, SafeMath.mul(SafeMath.sub(p.engineersCount[engineerIdx],currentEngineerCount), e.baseResearch));
                // calculate price crystals and eth you will pay
                priceCrystals = SafeMath.add(priceCrystals, SafeMath.mul(e.basePrice, engineerNumber));
                priceEth = SafeMath.add(priceEth, SafeMath.mul(e.baseETH, engineerNumber));
            }
        }
        // check price eth
        if (priceEth < msg.value) revert();

        uint256 devFeePrize = devFee(priceEth);
        distributedToOwner(devFeePrize);
        addMiningWarPrizePool(devFeePrize);
        addPrizePool(SafeMath.sub(msg.value, SafeMath.mul(devFeePrize,3)));        

        // pay and update
        MiningWar.subCrystal(msg.sender, priceCrystals);
        updateResearch(msg.sender, research);

        emit BuyEngineer(msg.sender, engineerNumbers, priceCrystals, priceEth, research);
    }
     /**
    * @dev update virus for player 
    * @param _addr player address
    */
    function updateVirus(address _addr) private
    {
        Player storage p = players[_addr]; 
        p.virusNumber = calCurrentVirus(_addr);
        p.lastUpdateTime = now;
    }
    function calCurrentVirus(address _addr) public view returns(uint256 _currentVirus)
    {
        Player memory p = players[_addr]; 
        uint256 secondsPassed = SafeMath.sub(now, p.lastUpdateTime);
        uint256 researchPerDay = getResearchPerDay(_addr);   
        _currentVirus = p.virusNumber;
        if (researchPerDay > 0) {
            _currentVirus = SafeMath.add(_currentVirus, SafeMath.mul(researchPerDay, secondsPassed));
        }   
    }
    /**
    * @dev update research for player
    * @param _addr player address
    * @param _research number research want to add
    */
    function updateResearch(address _addr, uint256 _research) private 
    {
        Player storage p = players[_addr];
        p.research = SafeMath.add(p.research, _research);

        emit UpdateResearch(_addr, p.research);
    }
    function getResearchPerDay(address _addr) public view returns( uint256 _researchPerDay)
    {
        Player memory p = players[_addr];
        _researchPerDay =  p.research;
        uint256 boosterIdx = hasBooster(_addr);
        if (boosterIdx != 999) {
            BoostData memory b = boostData[boosterIdx];
            _researchPerDay = SafeMath.div(SafeMath.mul(_researchPerDay, b.boostRate), 100);
        } 
    }
    /**
    * @dev get player data
    * @param _addr player address
    */
    function getPlayerData(address _addr) 
    public 
    view 
    returns(
        uint256 _virusNumber, 
        uint256 _currentVirus,
        uint256 _research, 
        uint256 _researchPerDay, 
        uint256 _lastUpdateTime, 
        uint256[8] _engineersCount
    )
    {
        Player storage p = players[_addr];
        for ( uint256 idx = 0; idx < numberOfEngineer; idx++ ) {
            _engineersCount[idx] = p.engineersCount[idx];
        }
        _currentVirus= SafeMath.div(calCurrentVirus(_addr), VIRUS_MINING_PERIOD);
        _virusNumber = SafeMath.div(p.virusNumber, VIRUS_MINING_PERIOD);
        _lastUpdateTime = p.lastUpdateTime;
        _research = p.research;
        _researchPerDay = getResearchPerDay(_addr);
    }
    //--------------------------------------------------------------------------
    // INTERNAL 
    //--------------------------------------------------------------------------
    function addPrizePool(uint256 _value) private 
    {
        prizePool = SafeMath.add(prizePool, _value);
    }
    /**
    * @dev add 5% value of transaction payable
    */
    function addMiningWarPrizePool(uint256 _value) private
    {
        MiningWar.fallback.value(_value)();
    }
    /**
    * @dev calculate current crystals of player
    * @param _addr player address
    */
    function calCurrentCrystals(address _addr) public view returns(uint256 _currentCrystals)
    {
        _currentCrystals = SafeMath.div(MiningWar.calCurrentCrystals(_addr), CRTSTAL_MINING_PERIOD);
    }
    function devFee(uint256 _amount) private pure returns(uint256)
    {
        return SafeMath.div(SafeMath.mul(_amount, 5), 100);
    }
    /**
    * @dev with transaction payable send 5% value for admin and sponsor
    * @param _value fee 
    */
    function distributedToOwner(uint256 _value) private
    {
        gameSponsor.transfer(_value);
        administrator.transfer(_value);
    }
}