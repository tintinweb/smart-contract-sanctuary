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

/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send or transfer.
 */
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
interface MiniGameInterface {
     function setupMiniGame(uint256 _miningWarRoundNumber, uint256 _miningWarDeadline) external;
     function isContractMiniGame() external pure returns( bool _isContractMiniGame );
}
contract CryptoEngineerInterface {
    address public gameSponsor;
    function isEngineerContract() external pure returns(bool) {}
    function isContractMiniGame() external pure returns( bool /*_isContractMiniGame*/ ) {}
}


contract CryptoMiningWar is PullPayment {
    bool public initialized = false;
    uint256 public roundNumber = 0;
    uint256 public deadline;
    uint256 public CRTSTAL_MINING_PERIOD = 86400; 
    uint256 public HALF_TIME = 8 hours;
    uint256 public ROUND_TIME = 86400 * 7;
	uint256 public prizePool = 0;
    uint256 BASE_PRICE = 0.005 ether;
    uint256 RANK_LIST_LIMIT = 10000;
    uint256 public totalMiniGame = 0;

    uint256 private numberOfMiners = 8;
    uint256 private numberOfBoosts = 5;
    uint256 private numberOfRank   = 21;
    
    CryptoEngineerInterface  public Engineer;
    
    mapping(uint256 => address) public miniGameAddress;
    //miner info
    mapping(uint256 => MinerData) private minerData;
    
    // plyer info
    mapping(address => Player) public players;
    mapping(address => uint256) public boosterReward;
    //booster info
    mapping(uint256 => BoostData) private boostData;
    //mini game contract info
    mapping(address => bool) public miniGames;   
    
    
    address[21] rankList;
    address public administrator;
    /*** DATATYPES ***/
    struct Player {
        uint256 roundNumber;
        mapping(uint256 => uint256) minerCount;
        uint256 hashrate;
        uint256 crystals;
        uint256 lastUpdateTime;
    }
    struct MinerData {
        uint256 basePrice;
        uint256 baseProduct;
        uint256 limit;
    }
    struct BoostData {
        address owner;
        uint256 boostRate;
        uint256 startingLevel;
        uint256 startingTime;
        uint256 halfLife;
    }
    modifier isNotOver() 
    {
        require(now <= deadline);
        _;
    }
    modifier disableContract()
    {
        require(tx.origin == msg.sender);
        _;
    }
    modifier isCurrentRound(address _addr) 
    {
        require(players[_addr].roundNumber == roundNumber);
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
    event GetFreeMiner(address _addr, uint256 _miningWarRound, uint256 _deadline);
    event BuyMiner(address _addr, uint256[8] minerNumbers, uint256 _crystalsPrice, uint256 _hashrateBuy, uint256 _miningWarRound);
    event ChangeHasrate(address _addr, uint256 _hashrate, uint256 _miningWarRound);
    event ChangeCrystal(address _addr, uint256 _crystal, uint256 _type, uint256 _miningWarRound); //_type: 1 add crystal , 2: sub crystal
    event BuyBooster(address _addr, uint256 _miningWarRound, uint256 _boosterId, uint256 _price, address beneficiary, uint256 refundPrize);
    event Lottery(address[10] _topAddr, uint256[10] _reward, uint256 _miningWarRound);
    event WithdrawReward(address _addr, uint256 _reward);
    constructor() public {
        administrator = msg.sender;
        initMinerData();
    }
    function initMinerData() private 
    {
         //                      price,          prod.     limit
        minerData[0] = MinerData(10,            10,         10);   //lv1
        minerData[1] = MinerData(100,           200,        2);    //lv2
        minerData[2] = MinerData(400,           800,        4);    //lv3
        minerData[3] = MinerData(1600,          3200,       8);    //lv4 
        minerData[4] = MinerData(6400,          9600,       16);   //lv5 
        minerData[5] = MinerData(25600,         38400,      32);   //lv6 
        minerData[6] = MinerData(204800,        204800,     64);   //lv7 
        minerData[7] = MinerData(1638400,       819200,     65536); //lv8   
    }
    function () public payable
    {
		prizePool = SafeMath.add(prizePool, msg.value);
    }

    function isMiningWarContract() public pure returns(bool)
    {
        return true;
    }

    function startGame() public isAdministrator
    {
        require(!initialized);
        
        startNewRound();
        initialized = true;
    }
    function addMiner(address _addr, uint256 idx, uint256 _value) public isNotOver isCurrentRound(_addr) isAdministrator
    {
        require(idx < numberOfMiners);
        require(_value != 0);

        Player storage p = players[_addr];
        MinerData memory m = minerData[idx];

        if (SafeMath.add(p.minerCount[idx], _value) > m.limit) revert();

        updateCrystal( _addr );

        p.minerCount[idx] = SafeMath.add(p.minerCount[idx], _value);

        updateHashrate(_addr, SafeMath.mul(_value, m.baseProduct));
    }
    /**
    * @dev add crystals to a player
    * msg.sender should be in the list of mini game
    * @param _addr player address 
    */
    function addCrystal( address _addr, uint256 _value ) public onlyContractsMiniGame isNotOver isCurrentRound(_addr)
    {
        uint256 crystals = SafeMath.mul(_value, CRTSTAL_MINING_PERIOD);
        Player storage p = players[_addr];
        p.crystals =  SafeMath.add( p.crystals, crystals ); 

        emit ChangeCrystal(_addr, _value, 1, roundNumber);
    }
    /**
    * @dev sub player&#39;s crystals
    * msg.sender should be in the list of mini game
    * @param _addr player address
    */
    function subCrystal( address _addr, uint256 _value ) public onlyContractsMiniGame isNotOver isCurrentRound(_addr)
    {
        updateCrystal( _addr );
        uint256 crystals = SafeMath.mul(_value,CRTSTAL_MINING_PERIOD);
        require(crystals <= players[_addr].crystals);

        Player storage p = players[_addr];
        p.crystals =  SafeMath.sub( p.crystals, crystals ); 

         emit ChangeCrystal(_addr, _value, 2, roundNumber);
    }
    /**
    * @dev add hashrate to a player.
    * msg.sender should be in the list of mini game
    */
    function addHashrate( address _addr, uint256 _value ) public onlyContractsMiniGame isNotOver isCurrentRound(_addr)
    {
        Player storage p = players[_addr];
        p.hashrate =  SafeMath.add( p.hashrate, _value );

        emit ChangeHasrate(_addr, p.hashrate, roundNumber); 
    }
    /**
    * @dev sub player&#39;s hashrate
    * msg.sender should be in the list of mini game
    */
    function subHashrate( address _addr, uint256 _value ) public onlyContractsMiniGame isNotOver isCurrentRound(_addr)
    {
        require(players[_addr].hashrate >= _value);

        Player storage p = players[_addr];
        
        p.hashrate = SafeMath.sub( p.hashrate, _value ); 

        emit ChangeHasrate(_addr, p.hashrate, roundNumber);
    }
    function setEngineerInterface(address _addr) public isAdministrator
    {
        CryptoEngineerInterface engineerInterface = CryptoEngineerInterface(_addr);
        
        require(engineerInterface.isEngineerContract() == true);

        Engineer = engineerInterface;
    }   
    function setRoundNumber(uint256 _value) public isAdministrator
    {
        roundNumber = _value;
    } 
    function setContractsMiniGame( address _addr ) public  isAdministrator
    {
        require(miniGames[_addr] == false);
        MiniGameInterface MiniGame = MiniGameInterface( _addr );
        require(MiniGame.isContractMiniGame() == true );

        miniGames[_addr] = true;
        miniGameAddress[totalMiniGame] = _addr;
        totalMiniGame = totalMiniGame + 1;
    }
    /**
    * @dev remove mini game contract from main contract
    * @param _addr mini game contract address
    */
    function removeContractMiniGame(address _addr) public isAdministrator
    {
        miniGames[_addr] = false;
    }

    function startNewRound() private 
    {
        deadline = SafeMath.add(now, ROUND_TIME);
        roundNumber = SafeMath.add(roundNumber, 1);
        initBoostData();
        setupMiniGame();
    }
    function setupMiniGame() private 
    {
        for ( uint256 index = 0; index < totalMiniGame; index++ ) {
            if (miniGames[miniGameAddress[index]] == true) {
                MiniGameInterface MiniGame = MiniGameInterface( miniGameAddress[index] );
                MiniGame.setupMiniGame(roundNumber,deadline);
            }   
        }
    }
    function initBoostData() private
    {
        //init booster data
        boostData[0] = BoostData(0, 150, 1, now, HALF_TIME);
        boostData[1] = BoostData(0, 175, 1, now, HALF_TIME);
        boostData[2] = BoostData(0, 200, 1, now, HALF_TIME);
        boostData[3] = BoostData(0, 225, 1, now, HALF_TIME);
        boostData[4] = BoostData(msg.sender, 250, 2, now, HALF_TIME);
        for (uint256 idx = 0; idx < numberOfRank; idx++) {
            rankList[idx] = 0;
        }
    }
    function lottery() public disableContract
    {
        require(now > deadline);
        uint256 balance = SafeMath.div(SafeMath.mul(prizePool, 90), 100);
		uint256 devFee = SafeMath.div(SafeMath.mul(prizePool, 5), 100);
        administrator.transfer(devFee);
        uint8[10] memory profit = [30,20,10,8,7,5,5,5,5,5];
		uint256 totalPayment = 0;
		uint256 rankPayment = 0;
        address[10] memory _topAddr;
        uint256[10] memory _reward;
        for(uint256 idx = 0; idx < 10; idx++){
            if(rankList[idx] != 0){

				rankPayment = SafeMath.div(SafeMath.mul(balance, profit[idx]),100);
				asyncSend(rankList[idx], rankPayment);
				totalPayment = SafeMath.add(totalPayment, rankPayment);

                _topAddr[idx] = rankList[idx];
                _reward[idx] = rankPayment;
            }
        }
		prizePool = SafeMath.add(devFee, SafeMath.sub(balance, totalPayment));
        
        emit Lottery(_topAddr, _reward, roundNumber);

        startNewRound();
    }
    function getRankList() public view returns(address[21])
    {
        return rankList;
    }
    //--------------------------------------------------------------------------
    // Miner 
    //--------------------------------------------------------------------------
    /**
    * @dev get a free miner
    */
    function getFreeMiner(address _addr) public isNotOver disableContract
    {
        require(msg.sender == _addr);
        require(players[_addr].roundNumber != roundNumber);
        Player storage p = players[_addr];
        //reset player data
        if(p.hashrate > 0){
            for (uint idx = 1; idx < numberOfMiners; idx++) {
                p.minerCount[idx] = 0;
            }
        }
        MinerData storage m0 = minerData[0];
        p.crystals = 0;
        p.roundNumber = roundNumber;
        //free miner
        p.lastUpdateTime = now;
        p.minerCount[0] = 1;
        p.hashrate = m0.baseProduct;

        emit GetFreeMiner(_addr, roundNumber, deadline);
    }
    function getFreeMinerForMiniGame(address _addr) public isNotOver onlyContractsMiniGame
    {
        require(players[_addr].roundNumber != roundNumber);
        Player storage p = players[_addr];
        //reset player data
        if(p.hashrate > 0){
            for (uint idx = 1; idx < numberOfMiners; idx++) {
                p.minerCount[idx] = 0;
            }
        }
        MinerData storage m0 = minerData[0];
        p.crystals = 0;
        p.roundNumber = roundNumber;
        //free miner
        p.lastUpdateTime = now;
        p.minerCount[0] = 1;
        p.hashrate = m0.baseProduct;

        emit GetFreeMiner(_addr, roundNumber, deadline);
    }
    function buyMiner(uint256[8] minerNumbers) public isNotOver isCurrentRound(msg.sender)
    {           
        updateCrystal(msg.sender);

        Player storage p = players[msg.sender];
        uint256 price = 0;
        uint256 hashrate = 0;

        for (uint256 minerIdx = 0; minerIdx < numberOfMiners; minerIdx++) {
            MinerData memory m = minerData[minerIdx];
            uint256 minerNumber = minerNumbers[minerIdx];
           
            if(minerNumbers[minerIdx] > m.limit || minerNumbers[minerIdx] < 0) revert();
           
            if (minerNumber > 0) {
                price = SafeMath.add(price, SafeMath.mul(m.basePrice, minerNumber));

                uint256 currentMinerCount = p.minerCount[minerIdx];
                p.minerCount[minerIdx] = SafeMath.min(m.limit, SafeMath.add(p.minerCount[minerIdx], minerNumber));
                // calculate no hashrate you want buy
                hashrate = SafeMath.add(hashrate, SafeMath.mul(SafeMath.sub(p.minerCount[minerIdx],currentMinerCount), m.baseProduct));
            }
        }
        
        price = SafeMath.mul(price, CRTSTAL_MINING_PERIOD);
        if(p.crystals < price) revert();
        
        p.crystals = SafeMath.sub(p.crystals, price);

        updateHashrate(msg.sender, hashrate);

        emit BuyMiner(msg.sender, minerNumbers, SafeMath.div(price, CRTSTAL_MINING_PERIOD), hashrate, roundNumber);
    }
    function getPlayerData(address addr) public view
    returns (uint256 crystals, uint256 lastupdate, uint256 hashratePerDay, uint256[8] miners, uint256 hasBoost, uint256 playerBalance )
    {
        Player storage p = players[addr];

        if(p.roundNumber != roundNumber) p = players[0x0];
        
        crystals   = SafeMath.div(p.crystals, CRTSTAL_MINING_PERIOD);
        lastupdate = p.lastUpdateTime;
        hashratePerDay = p.hashrate;
        uint256 i = 0;
        for(i = 0; i < numberOfMiners; i++)
        {
            miners[i] = p.minerCount[i];
        }
        hasBoost = hasBooster(addr);
		playerBalance = payments[addr];
    }
    function getData(address _addr) 
    public 
    view 
    returns (
        uint256 crystals, 
        uint256 lastupdate, 
        uint256 hashratePerDay, 
        uint256[8] miners, 
        uint256 hasBoost, 
        uint256 playerBalance, 

        uint256 _miningWarRound,
        uint256 _miningWarDeadline,
        uint256 _miningWarPrizePool 
    ){
        (, lastupdate, hashratePerDay, miners, hasBoost, playerBalance) = getPlayerData(_addr);
        crystals = SafeMath.div(calCurrentCrystals(_addr), CRTSTAL_MINING_PERIOD);
        _miningWarRound     = roundNumber;
        _miningWarDeadline  = deadline;
        _miningWarPrizePool = prizePool;
    }
    function getHashratePerDay(address _addr) public view returns (uint256 personalProduction)
    {
        Player memory p = players[_addr];
        personalProduction =  p.hashrate;
        uint256 boosterIdx = hasBooster(_addr);
        if (boosterIdx != 999) {
            BoostData memory b = boostData[boosterIdx];
            personalProduction = SafeMath.div(SafeMath.mul(personalProduction, b.boostRate), 100);
        } 
    }
    function getCurrentReward(address _addr) public view returns(uint256)
    {
        return payments[_addr];
    }
    function withdrawReward(address _addr) public 
    {
        uint256 currentReward = payments[_addr];
        if (address(this).balance >= currentReward && currentReward > 0) {
            _addr.transfer(currentReward);
            payments[_addr]      = 0;
            boosterReward[_addr] = 0;
            emit WithdrawReward(_addr, currentReward);
        }
    } 
    //--------------------------------------------------------------------------
    // BOOSTER 
    //--------------------------------------------------------------------------
    function buyBooster(uint256 idx) public isNotOver isCurrentRound(msg.sender) payable 
    {
        require(idx < numberOfBoosts);
        BoostData storage b = boostData[idx];
        if(msg.value < getBoosterPrice(idx) || msg.sender == b.owner){
            revert();
        }
        address beneficiary = b.owner;
		uint256 devFeePrize = devFee(getBoosterPrice(idx));
        address gameSponsor = Engineer.gameSponsor();
        gameSponsor.transfer(devFeePrize);
		uint256 refundPrize = 0;
        if(beneficiary != 0){
			refundPrize = SafeMath.div(SafeMath.mul(getBoosterPrice(idx), 55), 100);
			asyncSend(beneficiary, refundPrize);
            boosterReward[beneficiary] = SafeMath.add(boosterReward[beneficiary], refundPrize);
        }
		prizePool = SafeMath.add(prizePool, SafeMath.sub(msg.value, SafeMath.add(devFeePrize, refundPrize)));
        updateCrystal(msg.sender);
        updateCrystal(beneficiary);
        uint256 level   = getCurrentLevel(b.startingLevel, b.startingTime, b.halfLife);
        b.startingLevel = SafeMath.add(level, 1);
        b.startingTime = now;
        // transfer ownership    
        b.owner = msg.sender;

        emit BuyBooster(msg.sender, roundNumber, idx, msg.value, beneficiary, refundPrize);
    }
    function getBoosterData(uint256 idx) public view returns (address owner,uint256 boostRate, uint256 startingLevel, 
        uint256 startingTime, uint256 currentPrice, uint256 halfLife)
    {
        require(idx < numberOfBoosts);
        owner            = boostData[idx].owner;
        boostRate        = boostData[idx].boostRate; 
        startingLevel    = boostData[idx].startingLevel;
        startingTime     = boostData[idx].startingTime;
        currentPrice     = getBoosterPrice(idx);
        halfLife         = boostData[idx].halfLife;
    }
    function getBoosterPrice(uint256 index) public view returns (uint256)
    {
        BoostData storage booster = boostData[index];
        return getCurrentPrice(getCurrentLevel(booster.startingLevel, booster.startingTime, booster.halfLife));
    }
    function hasBooster(address addr) public view returns (uint256 boostIdx)
    {         
        boostIdx = 999;
        for(uint256 i = 0; i < numberOfBoosts; i++){
            uint256 revert_i = numberOfBoosts - i - 1;
            if(boostData[revert_i].owner == addr){
                boostIdx = revert_i;
                break;
            }
        }
    }
    //--------------------------------------------------------------------------
    // Other 
    //--------------------------------------------------------------------------
    function devFee(uint256 amount) public pure returns(uint256)
    {
        return SafeMath.div(SafeMath.mul(amount, 5), 100);
    }
    function getBalance() public view returns(uint256)
    {
        return address(this).balance;
    }
	//@dev use this function in case of bug
    function upgrade(address addr) public isAdministrator
    {
        selfdestruct(addr);
    }

    //--------------------------------------------------------------------------
    // Private 
    //--------------------------------------------------------------------------
    /**
    * @param addr is player address you want add hash rate
    * @param _hashrate is no hashrate you want add for this player
    */
    function updateHashrate(address addr, uint256 _hashrate) private
    {
        Player storage p = players[addr];
       
        p.hashrate = SafeMath.add(p.hashrate, _hashrate);
       
        if(p.hashrate > RANK_LIST_LIMIT) updateRankList(addr);
        
        emit ChangeHasrate(addr, p.hashrate, roundNumber);
    }
    function updateCrystal(address _addr) private
    {
        require(now > players[_addr].lastUpdateTime);

        Player storage p = players[_addr]; 
        p.crystals = calCurrentCrystals(_addr);
        p.lastUpdateTime = now;
    }
     /**
    * @dev calculate current crystals of player
    * @param _addr player address
    */
    function calCurrentCrystals(address _addr) public view returns(uint256 _currentCrystals)
    {
        Player memory p = players[_addr];

        if(p.roundNumber != roundNumber) p = players[0x0];

        uint256 hashratePerDay = getHashratePerDay(_addr);     
        uint256 secondsPassed = SafeMath.sub(now, p.lastUpdateTime);      
        
        if (hashratePerDay > 0) _currentCrystals = SafeMath.add(p.crystals, SafeMath.mul(hashratePerDay, secondsPassed));
    }
    function getCurrentLevel(uint256 startingLevel, uint256 startingTime, uint256 halfLife) private view returns(uint256) 
    {
        uint256 timePassed=SafeMath.sub(now, startingTime);
        uint256 levelsPassed=SafeMath.div(timePassed, halfLife);
        if (startingLevel < levelsPassed) {
            return 0;
        }
        return SafeMath.sub(startingLevel, levelsPassed);
    }
    function getCurrentPrice(uint256 currentLevel) private view returns(uint256) 
    {
        return SafeMath.mul(BASE_PRICE, 2**currentLevel);
    }
    function updateRankList(address addr) private returns(bool)
    {
        uint256 idx = 0;
        Player storage insert = players[addr];
        Player storage lastOne = players[rankList[19]];
        if(insert.hashrate < lastOne.hashrate) {
            return false;
        }
        address[21] memory tempList = rankList;
        if(!inRankList(addr)){
            tempList[20] = addr;
            quickSort(tempList, 0, 20);
        }else{
            quickSort(tempList, 0, 19);
        }
        for(idx = 0;idx < 21; idx++){
            if(tempList[idx] != rankList[idx]){
                rankList[idx] = tempList[idx];
            }
        }
        
        return true;
    }
    function inRankList(address addr) internal view returns(bool)
    {
        for(uint256 idx = 0;idx < 20; idx++){
            if(addr == rankList[idx]){
                return true;
            }
        }
        return false;
    }
    function quickSort(address[21] list, int left, int right) internal
    {
        int i = left;
        int j = right;
        if(i == j) return;
        address addr = list[uint(left + (right - left) / 2)];
        Player storage p = players[addr];
        while (i <= j) {
            while (players[list[uint(i)]].hashrate > p.hashrate) i++;
            while (p.hashrate > players[list[uint(j)]].hashrate) j--;
            if (i <= j) {
                (list[uint(i)], list[uint(j)]) = (list[uint(j)], list[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(list, left, j);
        if (i < right)
            quickSort(list, i, right);
    }
}