pragma solidity ^0.4.23;

contract SafeMath {
    function safeToAdd(uint a, uint b) pure internal returns (bool) {
        return (a + b >= a);
    }
    function safeAdd(uint a, uint b) pure internal returns (uint) {
        require(safeToAdd(a, b));
        return a + b;
    }

    function safeToSubtract(uint a, uint b) pure internal returns (bool) {
        return (b <= a);
    }

    function safeSub(uint a, uint b) pure internal returns (uint) {
        require(safeToSubtract(a, b));
        return a - b;
    }
}

contract DiceRoll is SafeMath {

    address public owner;
    uint8 constant public maxNumber = 99;
    uint8 constant public minNumber = 1;

    bool public gamePaused;
    bool public recommendPaused;
    bool public jackpotPaused;

    uint256 public contractBalance;
    uint16 public houseEdge;
    uint256 public maxProfit;
    uint16 public maxProfitAsPercentOfHouse;
    uint256 public minBet;
    uint256 public maxBet;
    uint16 public jackpotOfHouseEdge;
    uint256 public minJackpotBet;
    uint256 public recommendProportion;
    uint256 playerProfit;
    
    uint256 public jackpotBlance;
    address[] public jackpotPlayer;
    uint256 public JackpotPeriods = 1;
    uint64 public nextJackpotTime;
    uint16 public jackpotPersent = 100;
    
    uint256 public totalWeiWon;
    uint256 public totalWeiWagered;

    uint256 public betId;
    uint256 seed;

    modifier betIsValid(uint256 _betSize, uint8 _start, uint8 _end) {
        require(_betSize >= minBet && _betSize <= maxBet && _start >= minNumber && _end <= maxNumber);
        _;
    }
    
    modifier oddEvenBetIsValid(uint256 _betSize, uint8 _oddeven) {
        require(_betSize >= minBet && _betSize <= maxBet && (_oddeven == 1 || _oddeven == 0));
        _;
    }

    modifier gameIsActive {
        require(!gamePaused);
        _;
    }
    
    modifier recommendAreActive {
        require(!recommendPaused);
        _;
    }

    modifier jackpotAreActive {
        require(!jackpotPaused);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    event LogResult(uint256 indexed BetID, address indexed PlayerAddress, uint8 DiceResult, uint256 Value, uint8 Status, uint8 Start, uint8 End, uint8 oddeven, uint256 BetValue);
    event LogJackpot(uint indexed BetID, address indexed PlayerAddress, uint jackpotValue);
    event LogRecommendProfit(uint indexed BetID, address indexed PlayerAddress, uint Profit);
    event LogOwnerTransfer(address SentToAddress, uint AmountTransferred);
    event SendJackpotSuccesss(address indexed winner, uint256 amount, uint256 JackpotPeriods);
    

    function() public payable{
        contractBalance = safeAdd(contractBalance, msg.value);
        setMaxProfit();
    }

    constructor() public {
        owner = msg.sender;
        houseEdge = 20; //2%
        maxProfitAsPercentOfHouse = 100; //10%
        minBet = 0.1 ether;
        maxBet = 1 ether;
        jackpotOfHouseEdge = 500; //50%
        recommendProportion = 100; //10%
        minJackpotBet = 0.1 ether;
        jackpotPersent = 100; //10%
    }

    function playerRoll(uint8 start, uint8 end, address inviter) public payable gameIsActive betIsValid(msg.value, start, end) {
        betId += 1;
        uint8 probability = end - start + 1;
        playerProfit = ((msg.value * (100 - probability) / probability + msg.value) * (1000 - houseEdge) / 1000) - msg.value;
        if(playerProfit > maxProfit) playerProfit = maxProfit;
        uint8 random = uint8(rand() % 100 + 1);
        totalWeiWagered += msg.value;
        if(start <= random && random <= end){
            totalWeiWon = safeAdd(totalWeiWon, playerProfit);
            contractBalance = safeSub(contractBalance, playerProfit);
            uint256 payout = safeAdd(playerProfit, msg.value);
            setMaxProfit();
            emit LogResult(betId, msg.sender, random, playerProfit, 1, start, end, 2, msg.value);

            uint256 houseEdgeFee = getHouseEdgeFee(probability, msg.value);
            increaseJackpot(houseEdgeFee * jackpotOfHouseEdge / 1000, betId);
            
            if(inviter != address(0)){
                emit LogRecommendProfit(betId, msg.sender, playerProfit);
                sendProportion(inviter, houseEdgeFee * recommendProportion / 1000);
            }
            
            msg.sender.transfer(payout);
            return;
        }else{
            emit LogResult(betId, msg.sender, random, 0, 0, start, end, 2, msg.value);    
            contractBalance = safeAdd(contractBalance, (msg.value-1));                                                      
            setMaxProfit();
            msg.sender.transfer(1);
            return;
        }

    }

    function oddEven(uint8 oddeven, address inviter) public payable gameIsActive oddEvenBetIsValid(msg.value, oddeven) {
        betId += 1;
        uint8 probability = 50;
        playerProfit = ((msg.value * (100 - probability) / probability + msg.value) * (1000 - houseEdge) / 1000) - msg.value;
        if(playerProfit > maxProfit) playerProfit = maxProfit;
        uint8 random = uint8(rand() % 100 + 1);
        totalWeiWagered += msg.value;
        if(random % 2 == oddeven){
            totalWeiWon = safeAdd(totalWeiWon, playerProfit);
            contractBalance = safeSub(contractBalance, playerProfit);
            uint256 payout = safeAdd(playerProfit, msg.value);
            setMaxProfit();
            emit LogResult(betId, msg.sender, random, playerProfit, 1, 0, 0, oddeven, msg.value);
            
            uint256 houseEdgeFee = getHouseEdgeFee(probability, msg.value);
            increaseJackpot(houseEdgeFee * jackpotOfHouseEdge / 1000, betId);
            
            if(inviter != address(0)){
                emit LogRecommendProfit(betId, msg.sender, playerProfit);
                sendProportion(inviter, houseEdgeFee * recommendProportion / 1000);
            }
            
            msg.sender.transfer(payout);  
            return;
        }else{
            emit LogResult(betId, msg.sender, random, 0, 0, 0, 0, oddeven, msg.value); 
            contractBalance = safeAdd(contractBalance, (msg.value-1));
            setMaxProfit();
            msg.sender.transfer(1);
            return;
        }
    }

    function sendProportion(address inviter, uint256 amount) internal {
        require(amount < contractBalance);
        contractBalance = safeSub(contractBalance, amount);
        inviter.transfer(amount);
    }


    function increaseJackpot(uint256 increaseAmount, uint256 _betId) internal {
        require(increaseAmount < maxProfit);
        emit LogJackpot(_betId, msg.sender, increaseAmount);
        jackpotBlance = safeAdd(jackpotBlance, increaseAmount);
        contractBalance = safeSub(contractBalance, increaseAmount);
        if(msg.value >= minJackpotBet){
            jackpotPlayer.push(msg.sender);
        }
    }
    
    function createWinner() public onlyOwner jackpotAreActive {
        uint64 tmNow = uint64(block.timestamp);
        require(tmNow >= nextJackpotTime);
        require(jackpotPlayer.length > 0);
        nextJackpotTime = tmNow + 72000;
        JackpotPeriods += 1;
        uint random = rand() % jackpotPlayer.length;
        address winner = jackpotPlayer[random - 1];
        jackpotPlayer.length = 0;
        sendJackpot(winner);
    }
    
    function sendJackpot(address winner) public onlyOwner jackpotAreActive {
        uint256 amount = jackpotBlance * jackpotPersent / 1000;
        require(jackpotBlance > amount);
        emit SendJackpotSuccesss(winner, amount, JackpotPeriods);
        jackpotBlance = safeSub(jackpotBlance, amount);
        winner.transfer(amount);
    }
    
    function sendValueToJackpot() payable public jackpotAreActive {
        jackpotBlance = safeAdd(jackpotBlance, msg.value);
    }
    
    function getHouseEdgeFee(uint256 _probability, uint256 _betValue) view internal returns (uint256){
        return (_betValue * (100 - _probability) / _probability + _betValue) * houseEdge / 1000;
    }


    function rand() internal returns (uint256) {
        seed = uint256(keccak256(msg.sender, blockhash(block.number - 1), block.coinbase, block.difficulty));
        return seed;
    }

    function setMaxProfit() internal {
        maxProfit = contractBalance * maxProfitAsPercentOfHouse / 1000;  
    }

    function ownerSetHouseEdge(uint16 newHouseEdge) public onlyOwner{
        require(newHouseEdge <= 1000);
        houseEdge = newHouseEdge;
    }

    function ownerSetMinJackpoBet(uint256 newVal) public onlyOwner{
        require(newVal <= 1 ether);
        minJackpotBet = newVal;
    }

    function ownerSetMaxProfitAsPercentOfHouse(uint8 newMaxProfitAsPercent) public onlyOwner{
        require(newMaxProfitAsPercent <= 1000);
        maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
        setMaxProfit();
    }

    function ownerSetMinBet(uint256 newMinimumBet) public onlyOwner{
        minBet = newMinimumBet;
    }

    function ownerSetMaxBet(uint256 newMaxBet) public onlyOwner{
        maxBet = newMaxBet;
    }

    function ownerSetJackpotOfHouseEdge(uint16 newProportion) public onlyOwner{
        require(newProportion < 1000);
        jackpotOfHouseEdge = newProportion;
    }

    function ownerSetRecommendProportion(uint16 newRecommendProportion) public onlyOwner{
        require(newRecommendProportion < 1000);
        recommendProportion = newRecommendProportion;
    }

    function ownerPauseGame(bool newStatus) public onlyOwner{
        gamePaused = newStatus;
    }

    function ownerPauseJackpot(bool newStatus) public onlyOwner{
        jackpotPaused = newStatus;
    }

    function ownerPauseRecommend(bool newStatus) public onlyOwner{
        recommendPaused = newStatus;
    }

    function ownerTransferEther(address sendTo, uint256 amount) public onlyOwner{	
        contractBalance = safeSub(contractBalance, amount);
        sendTo.transfer(amount);
        setMaxProfit();
        emit LogOwnerTransfer(sendTo, amount);
    }

    function ownerChangeOwner(address newOwner) public onlyOwner{
        owner = newOwner;
    }

    function ownerkill() public onlyOwner{
        selfdestruct(owner);
    }
}