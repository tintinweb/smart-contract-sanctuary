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
    uint256 MINIMUM_LIMIT_SELL = 5000000;
    uint256 randNonce = 0;
    //miner info
    mapping(uint256 => MinerData) private minerData;
    uint256 private numberOfMiners;
    // plyer info
    mapping(address => PlayerData) private players;
    //booster info
    uint256 private numberOfBoosts;
    mapping(uint256 => BoostData) private boostData;
    //order info
    uint256 private numberOfOrders;
    mapping(uint256 => BuyOrderData) private buyOrderData;
    mapping(uint256 => SellOrderData) private sellOrderData;
    uint256 private numberOfRank;
    address[21] rankList;
    address public sponsor;
    uint256 public sponsorLevel;
    address public administrator;
    /*** DATATYPES ***/
    struct PlayerData {
        uint256 roundNumber;
        mapping(uint256 => uint256) minerCount;
        uint256 hashrate;
        uint256 crystals;
        uint256 lastUpdateTime;
        uint256 referral_count;
        uint256 noQuest;
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
    struct BuyOrderData {
        address owner;
        string title;
        string description;
        uint256 unitPrice;
        uint256 amount;
    }
    struct SellOrderData {
        address owner;
        string title;
        string description;
        uint256 unitPrice;
        uint256 amount;
    }
    event eventDoQuest(
        uint clientNumber,
        uint randomNumber
    );
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
    modifier isCurrentRound() 
    {
        require(players[msg.sender].roundNumber == roundNumber);
        _;
    }
    modifier limitSell() 
    {
        PlayerData storage p = players[msg.sender];
        if(p.hashrate <= MINIMUM_LIMIT_SELL){
            _;
        }else{
            uint256 limit_hashrate = 0;
            if(rankList[9] != 0){
                PlayerData storage rank_player = players[rankList[9]];
                limit_hashrate = SafeMath.mul(rank_player.hashrate, 5);
            }
            require(p.hashrate <= limit_hashrate);
            _;
        }
    }
    constructor() public {
        administrator = msg.sender;
        numberOfMiners = 8;
        numberOfBoosts = 5;
        numberOfOrders = 5;
        numberOfRank = 21;
        //init miner data
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
    function startGame() public
    {
        require(msg.sender == administrator);
        require(!initialized);
        startNewRound();
        initialized = true;
    }

    function startNewRound() private 
    {
        deadline = SafeMath.add(now, ROUND_TIME);
        roundNumber = SafeMath.add(roundNumber, 1);
        initData();
    }
    function initData() private
    {
        sponsor = administrator;
        sponsorLevel = 6;
        //init booster data
        boostData[0] = BoostData(0, 150, 1, now, HALF_TIME);
        boostData[1] = BoostData(0, 175, 1, now, HALF_TIME);
        boostData[2] = BoostData(0, 200, 1, now, HALF_TIME);
        boostData[3] = BoostData(0, 225, 1, now, HALF_TIME);
        boostData[4] = BoostData(msg.sender, 250, 2, now, HALF_TIME);
        //init order data
        uint256 idx;
        for (idx = 0; idx < numberOfOrders; idx++) {
            buyOrderData[idx] = BuyOrderData(0, "title", "description", 0, 0);
            sellOrderData[idx] = SellOrderData(0, "title", "description", 0, 0);
        }
        for (idx = 0; idx < numberOfRank; idx++) {
            rankList[idx] = 0;
        }
    }
    function lottery() public disableContract
    {
        require(now > deadline);
        uint256 balance = SafeMath.div(SafeMath.mul(prizePool, 90), 100);
		uint256 devFee = SafeMath.div(SafeMath.mul(prizePool, 5), 100);
		asyncSend(administrator, devFee);
        uint8[10] memory profit = [30,20,10,8,7,5,5,5,5,5];
		uint256 totalPayment = 0;
		uint256 rankPayment = 0;
        for(uint256 idx = 0; idx < 10; idx++){
            if(rankList[idx] != 0){
				rankPayment = SafeMath.div(SafeMath.mul(balance, profit[idx]),100);
				asyncSend(rankList[idx], rankPayment);
				totalPayment = SafeMath.add(totalPayment, rankPayment);
            }
        }
		prizePool = SafeMath.add(devFee, SafeMath.sub(balance, totalPayment));
        startNewRound();
    }
    function getRankList() public view returns(address[21])
    {
        return rankList;
    }
    //sponser
    function becomeSponsor() public isNotOver payable
    {
        require(msg.value >= getSponsorFee());
		require(msg.sender != sponsor);
		uint256 sponsorPrice = getCurrentPrice(sponsorLevel);
		asyncSend(sponsor, sponsorPrice);
		prizePool = SafeMath.add(prizePool, SafeMath.sub(msg.value, sponsorPrice));
        sponsor = msg.sender;
        sponsorLevel = SafeMath.add(sponsorLevel, 1);
    }
    function getSponsorFee() public view returns(uint256 sponsorFee)
    {
        sponsorFee = getCurrentPrice(SafeMath.add(sponsorLevel, 1));
    }
    //--------------------------------------------------------------------------
    // Miner 
    //--------------------------------------------------------------------------
    function getFreeMiner(address ref) public disableContract isNotOver
    {
        require(players[msg.sender].roundNumber != roundNumber);
        PlayerData storage p = players[msg.sender];
        //reset player data
        if(p.hashrate > 0){
            for (uint idx = 1; idx < numberOfMiners; idx++) {
                p.minerCount[idx] = 0;
            }
        }
        p.crystals = 0;
        p.roundNumber = roundNumber;
        //free miner
        p.lastUpdateTime = now;
        p.referral_count = 0;
        p.noQuest        = 0;
        p.minerCount[0] = 1;
        MinerData storage m0 = minerData[0];
        p.hashrate = m0.baseProduct;
    }
	function doQuest(uint256 clientNumber) disableContract isCurrentRound isNotOver public
	{
		PlayerData storage p = players[msg.sender];
        p.noQuest            = SafeMath.add(p.noQuest, 1);
		uint256 randomNumber = getRandomNumber(msg.sender);
		if(clientNumber == randomNumber) {
            p.referral_count = SafeMath.add(p.referral_count, 1);
		}
		emit eventDoQuest(clientNumber, randomNumber);
	}
    function buyMiner(uint256[] minerNumbers) public isNotOver isCurrentRound
    {   
        require(minerNumbers.length == numberOfMiners);
        uint256 minerIdx = 0;
        MinerData memory m;
        for (; minerIdx < numberOfMiners; minerIdx++) {
            m = minerData[minerIdx];
            if(minerNumbers[minerIdx] > m.limit || minerNumbers[minerIdx] < 0){
                revert();
            }
        }
        updateCrytal(msg.sender);
        PlayerData storage p = players[msg.sender];
        uint256 price = 0;
        uint256 minerNumber = 0;
        for (minerIdx = 0; minerIdx < numberOfMiners; minerIdx++) {
            minerNumber = minerNumbers[minerIdx];
            if (minerNumber > 0) {
                m = minerData[minerIdx];
                price = SafeMath.add(price, SafeMath.mul(m.basePrice, minerNumber));
            }
        }
        price = SafeMath.mul(price, CRTSTAL_MINING_PERIOD);
        if(p.crystals < price){
            revert();
        }
        for (minerIdx = 0; minerIdx < numberOfMiners; minerIdx++) {
            minerNumber = minerNumbers[minerIdx];
            if (minerNumber > 0) {
                m = minerData[minerIdx];
                p.minerCount[minerIdx] = SafeMath.min(m.limit, SafeMath.add(p.minerCount[minerIdx], minerNumber));
            }
        }
        p.crystals = SafeMath.sub(p.crystals, price);
        updateHashrate(msg.sender);
    }
    function getPlayerData(address addr) public view
    returns (uint256 crystals, uint256 lastupdate, uint256 hashratePerDay, uint256[8] miners, uint256 hasBoost, uint256 referral_count, uint256 playerBalance, uint256 noQuest )
    {
        PlayerData storage p = players[addr];
        if(p.roundNumber != roundNumber){
            p = players[0];
        }
        crystals   = SafeMath.div(p.crystals, CRTSTAL_MINING_PERIOD);
        lastupdate = p.lastUpdateTime;
        hashratePerDay = addReferralHashrate(addr, p.hashrate);
        uint256 i = 0;
        for(i = 0; i < numberOfMiners; i++)
        {
            miners[i] = p.minerCount[i];
        }
        hasBoost = hasBooster(addr);
        referral_count = p.referral_count;
        noQuest        = p.noQuest; 
		playerBalance = payments[addr];
    }
    function getHashratePerDay(address minerAddr) public view returns (uint256 personalProduction)
    {
        PlayerData storage p = players[minerAddr];   
        personalProduction = addReferralHashrate(minerAddr, p.hashrate);
        uint256 boosterIdx = hasBooster(minerAddr);
        if (boosterIdx != 999) {
            BoostData storage b = boostData[boosterIdx];
            personalProduction = SafeMath.div(SafeMath.mul(personalProduction, b.boostRate), 100);
        }
    }
    //--------------------------------------------------------------------------
    // BOOSTER 
    //--------------------------------------------------------------------------
    function buyBooster(uint256 idx) public isNotOver isCurrentRound payable 
    {
        require(idx < numberOfBoosts);
        BoostData storage b = boostData[idx];
        if(msg.value < getBoosterPrice(idx) || msg.sender == b.owner){
            revert();
        }
        address beneficiary = b.owner;
		uint256 devFeePrize = devFee(getBoosterPrice(idx));
		asyncSend(sponsor, devFeePrize);
		uint256 refundPrize = 0;
        if(beneficiary != 0){
			refundPrize = SafeMath.div(SafeMath.mul(getBoosterPrice(idx), 55), 100);
			asyncSend(beneficiary, refundPrize);
        }
		prizePool = SafeMath.add(prizePool, SafeMath.sub(msg.value, SafeMath.add(devFeePrize, refundPrize)));
        updateCrytal(msg.sender);
        updateCrytal(beneficiary);
        uint256 level = getCurrentLevel(b.startingLevel, b.startingTime, b.halfLife);
        b.startingLevel = SafeMath.add(level, 1);
        b.startingTime = now;
        // transfer ownership    
        b.owner = msg.sender;
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
    // Market 
    //--------------------------------------------------------------------------
    function buyCrystalDemand(uint256 amount, uint256 unitPrice,string title, string description) public isNotOver isCurrentRound payable 
    {
        require(unitPrice >= 100000000000);
        require(amount >= 1000);
        require(SafeMath.mul(amount, unitPrice) <= msg.value);
        uint256 lowestIdx = getLowestUnitPriceIdxFromBuy();
        BuyOrderData storage o = buyOrderData[lowestIdx];
        if(o.amount > 10 && unitPrice <= o.unitPrice){
            revert();
        }
        uint256 balance = SafeMath.mul(o.amount, o.unitPrice);
        if (o.owner != 0){
			asyncSend(o.owner, balance);
        }
        o.owner = msg.sender;
        o.unitPrice = unitPrice;
        o.title = title;
        o.description = description;
        o.amount = amount;
    }
    function sellCrystal(uint256 amount, uint256 index) public isNotOver isCurrentRound limitSell
    {
        require(index < numberOfOrders);
        require(amount > 0);
        BuyOrderData storage o = buyOrderData[index];
		require(o.owner != msg.sender);
        require(amount <= o.amount);
        updateCrytal(msg.sender);
        PlayerData storage seller = players[msg.sender];
        PlayerData storage buyer = players[o.owner];
        require(seller.crystals >= SafeMath.mul(amount, CRTSTAL_MINING_PERIOD));
        uint256 price = SafeMath.mul(amount, o.unitPrice);
        uint256 fee = devFee(price);
		asyncSend(sponsor, fee);
		asyncSend(administrator, fee);
		prizePool = SafeMath.add(prizePool, SafeMath.div(SafeMath.mul(price, 40), 100));
        buyer.crystals = SafeMath.add(buyer.crystals, SafeMath.mul(amount, CRTSTAL_MINING_PERIOD));
        seller.crystals = SafeMath.sub(seller.crystals, SafeMath.mul(amount, CRTSTAL_MINING_PERIOD));
        o.amount = SafeMath.sub(o.amount, amount);
		asyncSend(msg.sender, SafeMath.div(price, 2));
    }
    function withdrawBuyDemand(uint256 index) public isNotOver isCurrentRound
    {
        require(index < numberOfOrders);
        BuyOrderData storage o = buyOrderData[index];
        require(o.owner == msg.sender);
        if(o.amount > 0){
            uint256 balance = SafeMath.mul(o.amount, o.unitPrice);
			asyncSend(o.owner, balance);
        }
        o.unitPrice = 0;
        o.amount = 0;  
        o.title = "title";
        o.description = "description";
        o.owner = 0;
    }
    function getBuyDemand(uint256 index) public view returns(address owner, string title, string description,
     uint256 amount, uint256 unitPrice)
    {
        require(index < numberOfOrders);
        BuyOrderData storage o = buyOrderData[index];
        owner = o.owner;
        title = o.title;
        description = o.description;
        amount = o.amount;
        unitPrice = o.unitPrice;
    }
    function getLowestUnitPriceIdxFromBuy() public view returns(uint256 lowestIdx)
    {
        uint256 lowestPrice = 2**256 - 1;
        for (uint256 idx = 0; idx < numberOfOrders; idx++) {
            BuyOrderData storage o = buyOrderData[idx];
            //if empty
            if (o.unitPrice == 0 || o.amount < 10) {
                return idx;
            }else if (o.unitPrice < lowestPrice) {
                lowestPrice = o.unitPrice;
                lowestIdx = idx;
            }
        }
    }
    //-------------------------Sell-----------------------------
    function sellCrystalDemand(uint256 amount, uint256 unitPrice, string title, string description) 
    public isNotOver isCurrentRound limitSell
    {
        require(amount >= 1000);
        updateCrytal(msg.sender);
        PlayerData storage seller = players[msg.sender];
        if(seller.crystals < SafeMath.mul(amount, CRTSTAL_MINING_PERIOD)){
            revert();
        }
        uint256 highestIdx = getHighestUnitPriceIdxFromSell();
        SellOrderData storage o = sellOrderData[highestIdx];
        if(o.amount > 10 && unitPrice >= o.unitPrice){
            revert();
        }
        if (o.owner != 0){
            PlayerData storage prev = players[o.owner];
            prev.crystals = SafeMath.add(prev.crystals, SafeMath.mul(o.amount, CRTSTAL_MINING_PERIOD));
        }
        o.owner = msg.sender;
        o.unitPrice = unitPrice;
        o.title = title;
        o.description = description;
        o.amount = amount;
        //sub crystals
        seller.crystals = SafeMath.sub(seller.crystals, SafeMath.mul(amount, CRTSTAL_MINING_PERIOD));
    }
    function buyCrystal(uint256 amount, uint256 index) public isNotOver isCurrentRound payable
    {
        require(index < numberOfOrders);
        require(amount > 0);
        SellOrderData storage o = sellOrderData[index];
		require(o.owner != msg.sender);
        require(amount <= o.amount);
		uint256 price = SafeMath.mul(amount, o.unitPrice);
        require(msg.value >= price);
        PlayerData storage buyer = players[msg.sender];        
        uint256 fee = devFee(price);
		asyncSend(sponsor, fee);
		asyncSend(administrator, fee);
		prizePool = SafeMath.add(prizePool, SafeMath.div(SafeMath.mul(price, 40), 100));
        buyer.crystals = SafeMath.add(buyer.crystals, SafeMath.mul(amount, CRTSTAL_MINING_PERIOD));
        o.amount = SafeMath.sub(o.amount, amount);
		asyncSend(o.owner, SafeMath.div(price, 2));
    }
    function withdrawSellDemand(uint256 index) public isNotOver isCurrentRound
    {
        require(index < numberOfOrders);
        SellOrderData storage o = sellOrderData[index];
        require(o.owner == msg.sender);
        if(o.amount > 0){
            PlayerData storage p = players[o.owner];
            p.crystals = SafeMath.add(p.crystals, SafeMath.mul(o.amount, CRTSTAL_MINING_PERIOD));
        }
        o.unitPrice = 0;
        o.amount = 0; 
        o.title = "title";
        o.description = "description";
        o.owner = 0;
    }
    function getSellDemand(uint256 index) public view returns(address owner, string title, string description,
     uint256 amount, uint256 unitPrice)
    {
        require(index < numberOfOrders);
        SellOrderData storage o = sellOrderData[index];
        owner = o.owner;
        title = o.title;
        description = o.description;
        amount = o.amount;
        unitPrice = o.unitPrice;
    }
    function getHighestUnitPriceIdxFromSell() public view returns(uint256 highestIdx)
    {
        uint256 highestPrice = 0;
        for (uint256 idx = 0; idx < numberOfOrders; idx++) {
            SellOrderData storage o = sellOrderData[idx];
            //if empty
            if (o.unitPrice == 0 || o.amount < 10) {
                return idx;
            }else if (o.unitPrice > highestPrice) {
                highestPrice = o.unitPrice;
                highestIdx = idx;
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
    function upgrade(address addr) public 
    {
        require(msg.sender == administrator);
        selfdestruct(addr);
    }

    //--------------------------------------------------------------------------
    // Private 
    //--------------------------------------------------------------------------
    function updateHashrate(address addr) private
    {
        PlayerData storage p = players[addr];
        uint256 hashrate = 0;
        for (uint idx = 0; idx < numberOfMiners; idx++) {
            MinerData storage m = minerData[idx];
            hashrate = SafeMath.add(hashrate, SafeMath.mul(p.minerCount[idx], m.baseProduct));
        }
        p.hashrate = hashrate;
        if(hashrate > RANK_LIST_LIMIT){
            updateRankList(addr);
        }
    }
    function updateCrytal(address addr) private
    {
        require(now > players[addr].lastUpdateTime);
        if (players[addr].lastUpdateTime != 0) {
            PlayerData storage p = players[addr];
            uint256 secondsPassed = SafeMath.sub(now, p.lastUpdateTime);
            uint256 revenue = getHashratePerDay(addr);
            p.lastUpdateTime = now;
            if (revenue > 0) {
                revenue = SafeMath.mul(revenue, secondsPassed);
                p.crystals = SafeMath.add(p.crystals, revenue);
            }
        }
    }
    function addReferralHashrate(address addr, uint256 hashrate) private view returns(uint256 personalProduction) 
    {
        PlayerData storage p = players[addr];
        if(p.referral_count < 5){
            personalProduction = SafeMath.add(hashrate, SafeMath.mul(p.referral_count, 10));
        }else if(p.referral_count < 10){
            personalProduction = SafeMath.add(hashrate, SafeMath.add(50, SafeMath.mul(p.referral_count, 10)));
        }else{
            personalProduction = SafeMath.add(hashrate, 200);
        }
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
        PlayerData storage insert = players[addr];
        PlayerData storage lastOne = players[rankList[19]];
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
	function getRandomNumber(address playerAddress) internal returns(uint256 randomNumber) {
        randNonce++;
        randomNumber = uint256(keccak256(now, playerAddress, randNonce)) % 3;
    }
    function quickSort(address[21] list, int left, int right) internal
    {
        int i = left;
        int j = right;
        if(i == j) return;
        address addr = list[uint(left + (right - left) / 2)];
        PlayerData storage p = players[addr];
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