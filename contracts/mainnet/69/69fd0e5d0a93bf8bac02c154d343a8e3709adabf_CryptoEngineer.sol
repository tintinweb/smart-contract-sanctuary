pragma solidity ^0.4.24;

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
contract CryptoMiningWarInterface {
    address public sponsor;
    address public administrator;
    mapping(address => PlayerData) public players;
    struct PlayerData {
        uint256 roundNumber;
        mapping(uint256 => uint256) minerCount;
        uint256 hashrate;
        uint256 crystals;
        uint256 lastUpdateTime;
        uint256 referral_count;
        uint256 noQuest;
    }
    function getHashratePerDay(address /*minerAddr*/) public pure returns (uint256 /*personalProduction*/) {}
    function addCrystal( address /*_addr*/, uint256 /*_value*/ ) public pure {}
    function subCrystal( address /*_addr*/, uint256 /*_value*/ ) public pure {}
    function fallback() public payable {}
}
interface MiniGameInterface {
    function isContractMiniGame() external pure returns( bool _isContractMiniGame );
    function fallback() external payable;
}
contract CryptoEngineer is PullPayment{
    // engineer info
	address public administrator;
    uint256 public prizePool = 0;
    uint256 public engineerRoundNumber = 0;
    uint256 public numberOfEngineer;
    uint256 public numberOfBoosts;
    address public gameSponsor;
    uint256 public gameSponsorPrice;
    uint256 private randNonce;
    uint256 constant public VIRUS_MINING_PERIOD = 86400; 
    uint256 constant public VIRUS_NORMAL = 0;
    uint256 constant public HALF_TIME_ATK = 60 * 15;   
    
    // mining war game infomation
    address public miningWarContractAddress;
    address public miningWarAdministrator;
    uint256 constant public CRTSTAL_MINING_PERIOD = 86400;
    uint256 constant public BASE_PRICE = 0.01 ether;

    CryptoMiningWarInterface public MiningWarContract;
    
    // engineer player information
    mapping(address => PlayerData) public players;
    // engineer boost information
    mapping(uint256 => BoostData) public boostData;
    // engineer information
    mapping(uint256 => EngineerData) public engineers;
    // engineer virut information
    mapping(uint256 => VirusData) public virus;
    
    // minigame info
    mapping(address => bool) public miniGames; 
    
    struct PlayerData {
        uint256 engineerRoundNumber;
        mapping(uint256 => uint256) engineersCount;
        uint256 virusNumber;
        uint256 virusDefence;
        uint256 research;
        uint256 lastUpdateTime;
        uint256 nextTimeAtk;
        uint256 endTimeUnequalledDef;
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
    struct VirusData {
        uint256 atk;
        uint256 def;
    }
    event eventEndAttack(
        address playerAtk,
        address playerDef,
        bool isWin,
        uint256 winCrystals,
        uint256 virusPlayerAtkDead,
        uint256 virusPlayerDefDead,
        uint256 timeAtk,
        uint256 engineerRoundNumber,
        uint256 atk,
        uint256 def // def of player 
    );
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

    constructor() public {
        administrator = msg.sender;

        //default game sponsor
        gameSponsor = administrator;
        gameSponsorPrice = 0.32 ether;
        // set interface main contract
        miningWarContractAddress = address(0xf84c61bb982041c030b8580d1634f00fffb89059);
        MiningWarContract = CryptoMiningWarInterface(miningWarContractAddress);
        miningWarAdministrator = MiningWarContract.administrator();
        
        numberOfEngineer = 8;
        numberOfBoosts = 5;
        // setting virusupd
        virus[VIRUS_NORMAL] = VirusData(1,1);

        //                          price crystals    price ETH         research  limit                         
        engineers[0] = EngineerData(10,               BASE_PRICE * 0,   10,       10   );   //lv1 
        engineers[1] = EngineerData(50,               BASE_PRICE * 1,   200,      2    );   //lv2
        engineers[2] = EngineerData(200,              BASE_PRICE * 2,   800,      4    );   //lv3
        engineers[3] = EngineerData(800,              BASE_PRICE * 4,   3200,     8    );   //lv4
        engineers[4] = EngineerData(3200,             BASE_PRICE * 8,   9600,     16   );   //lv5
        engineers[5] = EngineerData(12800,            BASE_PRICE * 16,  38400,    32   );   //lv6
        engineers[6] = EngineerData(102400,           BASE_PRICE * 32,  204800,   64   );   //lv7
        engineers[7] = EngineerData(819200,           BASE_PRICE * 64,  819200,   65536);   //lv8
        initData();
    }
    function () public payable
    {
        addPrizePool(msg.value);
    }
    function initData() private
    {
        //init booster data
        boostData[0] = BoostData(0x0, 150, BASE_PRICE * 1);
        boostData[1] = BoostData(0x0, 175, BASE_PRICE * 2);
        boostData[2] = BoostData(0x0, 200, BASE_PRICE * 4);
        boostData[3] = BoostData(0x0, 225, BASE_PRICE * 8);
        boostData[4] = BoostData(0x0, 250, BASE_PRICE * 16);
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
    function setupMiniGame( uint256 /*_miningWarRoundNumber*/, uint256 /*_miningWarDeadline*/ ) public
    {
    
    }
    //--------------------------------------------------------------------------
    // SETTING CONTRACT MINI GAME 
    //--------------------------------------------------------------------------
    function setContractsMiniGame( address _contractMiniGameAddress ) public isAdministrator 
    {
        MiniGameInterface MiniGame = MiniGameInterface( _contractMiniGameAddress );
        if( MiniGame.isContractMiniGame() == false ) { revert(); }

        miniGames[_contractMiniGameAddress] = true;
    }
    /**
    * @dev remove mini game contract from main contract
    * @param _contractMiniGameAddress mini game contract address
    */
    function removeContractMiniGame(address _contractMiniGameAddress) public isAdministrator
    {
        miniGames[_contractMiniGameAddress] = false;
    }
    //@dev use this function in case of bug
    function upgrade(address addr) public 
    {
        require(msg.sender == administrator);
        selfdestruct(addr);
    }

    //--------------------------------------------------------------------------
    // BOOSTER 
    //--------------------------------------------------------------------------
    function buyBooster(uint256 idx) public payable 
    {
        require(idx < numberOfBoosts);
        BoostData storage b = boostData[idx];
        if (msg.value < b.basePrice || msg.sender == b.owner) {
            revert();
        }
        address beneficiary = b.owner;
        uint256 devFeePrize = devFee(b.basePrice);
        
        distributedToOwner(devFeePrize);
        addMiningWarPrizePool(devFeePrize);
        addPrizePool(SafeMath.sub(msg.value, SafeMath.mul(devFeePrize,3)));
        
        updateVirus(msg.sender);
        if ( beneficiary != 0x0 ) {
            updateVirus(beneficiary);
        }
        // transfer ownership    
        b.owner = msg.sender;
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
        gameSponsor.send(repayPrice);
        
        // add to prize pool
        addPrizePool(SafeMath.sub(msg.value, repayPrice));
        // update game sponsor info
        gameSponsor = msg.sender;
        gameSponsorPrice = gameSponsorPriceFee;
    }
    /**
    * @dev add virus for player
    * @param _addr player address
    * @param _value number of virus
    */
    function addVirus(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        PlayerData storage p = players[_addr];
        uint256 additionalVirus = SafeMath.mul(_value,VIRUS_MINING_PERIOD);
        p.virusNumber = SafeMath.add(p.virusNumber, additionalVirus);
    }
    /**
    * @dev subtract virus of player
    * @param _addr player address 
    * @param _value number virus subtract 
    */
    function subVirus(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        updateVirus(_addr);
        PlayerData storage p = players[_addr];
        uint256 subtractVirus = SafeMath.mul(_value,VIRUS_MINING_PERIOD);
        if ( p.virusNumber < subtractVirus ) { revert(); }

        p.virusNumber = SafeMath.sub(p.virusNumber, subtractVirus);
    }
    /**
    * @dev additional time unequalled defence 
    * @param _addr player address 
    */
    function setAtkNowForPlayer(address _addr) public onlyContractsMiniGame
    {
        PlayerData storage p = players[_addr];
        p.nextTimeAtk = now;
    }
    function addTimeUnequalledDefence(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        PlayerData storage p = players[_addr];
        uint256 currentTimeUnequalled = p.endTimeUnequalledDef;
        if (currentTimeUnequalled < now) {
            currentTimeUnequalled = now;
        }
        p.endTimeUnequalledDef = SafeMath.add(currentTimeUnequalled, _value);
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
    // WARS
    //--------------------------------------------------------------------------
    function setVirusInfo(uint256 _atk, uint256 _def) public isAdministrator
    {
        VirusData storage v = virus[VIRUS_NORMAL];
        v.atk = _atk;
        v.def = _def;
    }
    /**
    * @dev add virus defence 
    * @param _value number of virus defence
    */
    function addVirusDefence(uint256 _value) public disableContract 
    {        
        updateVirus(msg.sender);
        PlayerData storage p = players[msg.sender];
        uint256 _virus = SafeMath.mul(_value,VIRUS_MINING_PERIOD);

        if ( p.virusNumber < _virus ) { revert(); }

        p.virusDefence = SafeMath.add(p.virusDefence, _virus);
        p.virusNumber  = SafeMath.sub(p.virusNumber, _virus);
    }
    /**
    * @dev atk and def ramdom from 50% to 150%
    * @param _defAddress player address to attack
    * @param _value number of virus send to attack
    */
    function attack( address _defAddress, uint256 _value) public disableContract
    {
        require(canAttack(msg.sender, _defAddress) == true);

        updateVirus(msg.sender);

        PlayerData storage pAtk = players[msg.sender];
        PlayerData storage pDef = players[_defAddress];
        uint256 virusAtk = SafeMath.mul(_value,VIRUS_MINING_PERIOD);

        if (pAtk.virusNumber < virusAtk) { revert(); }
        // current crystals of defence geater 5000 crystals
        if (calCurrentCrystals(_defAddress) < 5000) { revert(); }

        // virus normal info
        VirusData memory v = virus[VIRUS_NORMAL];
        // ramdom attack and defence for players from 50% to 150%
        uint256 rateAtk = 50 + randomNumber(msg.sender, 100);
        uint256 rateDef = 50 + randomNumber(_defAddress, 100);
        // calculate attack of player attack and defence of player defence
        uint256 atk = SafeMath.div(SafeMath.mul(SafeMath.mul(virusAtk, v.atk), rateAtk), 100);
        uint256 def = SafeMath.div(SafeMath.mul(SafeMath.mul(pDef.virusDefence, v.def), rateDef), 100);
        bool isWin = false;
        uint256 virusPlayerAtkDead = 0;
        uint256 virusPlayerDefDead = 0;
        /**
        * @dev calculate virus dead in war 
        */
        // if attack > defense, sub virus of player atk and player def.
        // number virus for kin
        if (atk > def) {
            virusPlayerAtkDead = SafeMath.min(virusAtk, SafeMath.div(SafeMath.mul(def, 100), SafeMath.mul(v.atk, rateAtk)));
            virusPlayerDefDead = pDef.virusDefence;
            isWin = true;
        }
        /**
        * @dev update result of war and call end attack
        */
        pAtk.virusNumber = SafeMath.sub(pAtk.virusNumber, virusPlayerAtkDead);
        pDef.virusDefence = SafeMath.sub(pDef.virusDefence, virusPlayerDefDead);
        //update player attack
        pAtk.nextTimeAtk = now + HALF_TIME_ATK;

        endAttack(msg.sender,_defAddress,isWin, virusPlayerAtkDead, virusPlayerDefDead, atk, def);
    }
    /**
    * @dev check player can atk or not
    * @param _atkAddress player address attack
    * @param _defAddress player address defence
    */
    function canAttack(address _atkAddress, address _defAddress) public view returns(bool _canAtk)
    {
        if ( 
            _atkAddress != _defAddress &&
            players[_atkAddress].nextTimeAtk <= now &&
            players[_defAddress].endTimeUnequalledDef < now
        ) 
        {
            _canAtk = true;
        }
    }
    /**
    * @dev result of war
    * @param _atkAddress player address attack
    * @param _defAddress player address defence
    */
    function endAttack(
        address _atkAddress, 
        address _defAddress, 
        bool _isWin, 
        uint256 _virusPlayerAtkDead, 
        uint256 _virusPlayerDefDead, 
        uint256 _atk,
        uint256 _def
    ) private
    {
        uint256 winCrystals;
        if ( _isWin == true ) {
            uint256 pDefCrystals = calCurrentCrystals(_defAddress);
            // subtract random 10% to 50% current crystals of player defence
            uint256 rate =10 + randomNumber(_defAddress, 40);
            winCrystals = SafeMath.div(SafeMath.mul(pDefCrystals,rate),100);

            if (winCrystals > 0) {
                MiningWarContract.subCrystal(_defAddress, winCrystals);    
                MiningWarContract.addCrystal(_atkAddress, winCrystals);
            }
        }
        emit eventEndAttack(_atkAddress, _defAddress, _isWin, winCrystals, _virusPlayerAtkDead, _virusPlayerDefDead, now, engineerRoundNumber, _atk, _def);
    }
    //--------------------------------------------------------------------------
    // PLAYERS
    //--------------------------------------------------------------------------
    /**
    */
    function buyEngineer(uint256[] engineerNumbers) public payable disableContract
    {
        require(engineerNumbers.length == numberOfEngineer);
        
        updateVirus(msg.sender);
        PlayerData storage p = players[msg.sender];
        
        uint256 priceCrystals = 0;
        uint256 priceEth = 0;
        uint256 research = 0;
        for (uint256 engineerIdx = 0; engineerIdx < numberOfEngineer; engineerIdx++) {
            uint256 engineerNumber = engineerNumbers[engineerIdx];
            EngineerData memory e = engineers[engineerIdx];
            // require for engineerNumber 
            if(engineerNumber > e.limit || engineerNumber < 0) {
                revert();
            }
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
        if (priceEth < msg.value) {
            revert();
        }

        uint256 devFeePrize = devFee(priceEth);
        distributedToOwner(devFeePrize);
        addMiningWarPrizePool(devFeePrize);
        addPrizePool(SafeMath.sub(msg.value, SafeMath.mul(devFeePrize,3)));        

        // pay and update
        MiningWarContract.subCrystal(msg.sender, priceCrystals);
        updateResearch(msg.sender, research);
    }
     /**
    * @dev update virus for player 
    * @param _addr player address
    */
    function updateVirus(address _addr) private
    {
        if (players[_addr].engineerRoundNumber != engineerRoundNumber) {
            return resetPlayer(_addr);
        }
        PlayerData storage p = players[_addr]; 
        p.virusNumber = calculateCurrentVirus(_addr);
        p.lastUpdateTime = now;
    }
    function calculateCurrentVirus(address _addr) public view returns(uint256 _currentVirus)
    {
        PlayerData memory p = players[_addr]; 
        uint256 secondsPassed = SafeMath.sub(now, p.lastUpdateTime);
        uint256 researchPerDay = getResearchPerDay(_addr);   
        _currentVirus = p.virusNumber;
        if (researchPerDay > 0) {
            _currentVirus = SafeMath.add(_currentVirus, SafeMath.mul(researchPerDay, secondsPassed));
        }   
    }
    /**
    * @dev reset player data
    * @param _addr player address
    */
    function resetPlayer(address _addr) private
    {
        require(players[_addr].engineerRoundNumber != engineerRoundNumber);

        PlayerData storage p = players[_addr];
        p.engineerRoundNumber = engineerRoundNumber;
        p.virusNumber = 0;
        p.virusDefence = 0;
        p.research = 0;        
        p.lastUpdateTime = now;
        p.nextTimeAtk = now;
        p.endTimeUnequalledDef = now;
        // reset player engineer data
        for ( uint256 idx = 0; idx < numberOfEngineer; idx++ ) {
            p.engineersCount[idx] = 0;
        }   
    }
    /**
    * @dev update research for player
    * @param _addr player address
    * @param _research number research want to add
    */
    function updateResearch(address _addr, uint256 _research) private 
    {
        PlayerData storage p = players[_addr];
        p.research = SafeMath.add(p.research, _research);
    }
    function getResearchPerDay(address _addr) public view returns( uint256 _researchPerDay)
    {
        PlayerData memory p = players[_addr];
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
        uint256 _engineerRoundNumber, 
        uint256 _virusNumber, 
        uint256 _virusDefence, 
        uint256 _research, 
        uint256 _researchPerDay, 
        uint256 _lastUpdateTime, 
        uint256[8] _engineersCount, 
        uint256 _nextTimeAtk,
        uint256 _endTimeUnequalledDef
    )
    {
        PlayerData storage p = players[_addr];
        for ( uint256 idx = 0; idx < numberOfEngineer; idx++ ) {
            _engineersCount[idx] = p.engineersCount[idx];
        }
        _engineerRoundNumber = p.engineerRoundNumber;
        _virusNumber = SafeMath.div(p.virusNumber, VIRUS_MINING_PERIOD);
        _virusDefence = SafeMath.div(p.virusDefence, VIRUS_MINING_PERIOD);
        _nextTimeAtk = p.nextTimeAtk;
        _lastUpdateTime = p.lastUpdateTime;
        _endTimeUnequalledDef = p.endTimeUnequalledDef;
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
        MiningWarContract.fallback.value(_value)();
    }
    /**
    * @dev calculate current crystals of player
    * @param _addr player address
    */
    function calCurrentCrystals(address _addr) public view returns(uint256 _currentCrystals)
    {
        uint256 lastUpdateTime;
        (,, _currentCrystals, lastUpdateTime) = getMiningWarPlayerData(_addr);
        uint256 hashratePerDay = getHashratePerDay(_addr);     
        uint256 secondsPassed = SafeMath.sub(now, lastUpdateTime);      
        if (hashratePerDay > 0) {
            _currentCrystals = SafeMath.add(_currentCrystals, SafeMath.mul(hashratePerDay, secondsPassed));
        }
        _currentCrystals = SafeMath.div(_currentCrystals, CRTSTAL_MINING_PERIOD);
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
        gameSponsor.send(_value);
        miningWarAdministrator.send(_value);
    }
    function randomNumber(address _addr, uint256 _maxNumber) private returns(uint256)
    {
        randNonce = randNonce + 1;
        return uint256(keccak256(abi.encodePacked(now, _addr, randNonce))) % _maxNumber;
    }
    function getMiningWarPlayerData(address _addr) private view returns(uint256 _roundNumber, uint256 _hashrate, uint256 _crytals, uint256 _lastUpdateTime)
    {
        (_roundNumber,_hashrate,_crytals,_lastUpdateTime,,)= MiningWarContract.players(_addr);
    }
    function getHashratePerDay(address _addr) private view returns(uint256)
    {
        return MiningWarContract.getHashratePerDay(_addr);
    }
}