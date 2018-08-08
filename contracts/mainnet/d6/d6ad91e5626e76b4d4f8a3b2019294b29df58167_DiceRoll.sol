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
    uint constant public maxProfitDivisor = 1000000;
    uint constant public houseEdgeDivisor = 1000;
    uint constant public maxNumber = 99;
    uint constant public minNumber = 1;

    bool public gamePaused;
    bool public recommendPaused;
    bool public jackpotPaused;

    uint public contractBalance;
    uint public houseEdge;
    uint public maxProfit;
    uint public maxProfitAsPercentOfHouse;
    uint public minBet;
    uint public maxBet;
    uint public jackpotOfHouseEdge;
    uint public minJackpotBet;
    uint public recommendProportion;
    address public jackpotContract;
    
    uint public jackpot;
    uint public totalWeiWon;
    uint public totalWeiWagered;
    uint public totalBets;

    uint public betId;
    uint public random;
    uint public probability;
    uint public playerProfit;
    uint public playerTempReward;
    uint256 seed;

    modifier betIsValid(uint _betSize, uint _start, uint _end) {
        require(_betSize >= minBet && _betSize <= maxBet && _start >= minNumber && _end <= maxNumber);
        _;
    }
    
    modifier oddEvenBetIsValid(uint _betSize, uint _oddeven) {
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


    event LogResult(uint indexed BetID, address indexed PlayerAddress, uint DiceResult, uint Value, uint Status, uint Start, uint End, uint oddeven, uint BetValue);
    event LogJackpot(uint indexed BetID, address indexed PlayerAddress, uint jackpotValue);
    event LogRecommendProfit(uint indexed BetID, address indexed PlayerAddress, uint Profit);
    event LogOwnerTransfer(address SentToAddress, uint AmountTransferred);
    

    function() public payable{
        contractBalance = safeAdd(contractBalance, msg.value);
        setMaxProfit();
    }

    constructor() public {
        owner = msg.sender;
        ownerSetHouseEdge(20);
        ownerSetMaxProfitAsPercentOfHouse(100000);
        ownerSetMinBet(0.1 ether);
        ownerSetMaxBet(1 ether);
        ownerSetJackpotOfHouseEdge(500);
        ownerSetRecommendProportion(100);
        ownerSetMinJackpoBet(0.1 ether);
    }

    function playerRoll(uint start, uint end, address inviter) public payable gameIsActive betIsValid(msg.value, start, end) {
        betId += 1;
        probability = end - start + 1;
        playerProfit = getDiceWinAmount(msg.value, probability);
        if(playerProfit > maxProfit) playerProfit = maxProfit;
        random = rand() % 100 + 1;
        totalBets += 1;
        totalWeiWagered += msg.value;
        if(start <= random && random <= end){
            contractBalance = safeSub(contractBalance, playerProfit); 
            totalWeiWon = safeAdd(totalWeiWon, playerProfit);
            playerTempReward = safeAdd(playerProfit, msg.value);
            emit LogResult(betId, msg.sender, random, playerProfit, 1, start, end, 0, msg.value);
            setMaxProfit();
            uint playerHouseEdge = getHouseEdgeAmount(msg.value, probability);
            increaseJackpot(getJackpotFee(playerHouseEdge),betId);
            if(inviter != address(0)){
                emit LogRecommendProfit(betId, msg.sender, playerProfit);
                sendProportion(inviter, playerHouseEdge * recommendProportion / 1000);
            }
            msg.sender.transfer(playerTempReward);
            return;
        }else{
            emit LogResult(betId, msg.sender, random, 0, 0, start, end, 0, msg.value);
            contractBalance = safeAdd(contractBalance, (msg.value-1));                                                                      
            setMaxProfit();          
            msg.sender.transfer(1);
            return;
        }

    }

    function oddEven(uint oddeven, address inviter) public payable gameIsActive oddEvenBetIsValid(msg.value, oddeven) {
        betId += 1;
        probability = 50;
        playerProfit = getDiceWinAmount(msg.value, probability);
        if(playerProfit > maxProfit) playerProfit = maxProfit;
        random = rand() % 100 + 1;
        totalBets += 1;
        totalWeiWagered += msg.value;
        if(random % 2 == oddeven){
            contractBalance = safeSub(contractBalance, playerProfit); 
            totalWeiWon = safeAdd(totalWeiWon, playerProfit);
            playerTempReward = safeAdd(playerProfit, msg.value); 
            emit LogResult(betId, msg.sender, random, playerProfit, 1, 0, 0, oddeven, msg.value);
            setMaxProfit();
            uint playerHouseEdge = getHouseEdgeAmount(msg.value, probability);
            increaseJackpot(getJackpotFee(playerHouseEdge),betId);
            if(inviter != address(0)){
                emit LogRecommendProfit(betId, msg.sender, playerProfit);
                sendProportion(inviter, playerHouseEdge * recommendProportion / 1000);
            }
            msg.sender.transfer(playerTempReward);  
            return;
        }else{
            emit LogResult(betId, msg.sender, random, playerProfit, 0, 0, 0, oddeven, msg.value); 
            contractBalance = safeAdd(contractBalance, (msg.value-1));
            setMaxProfit();         
            msg.sender.transfer(1);
            return;
        }
    }

    function sendProportion(address inviter, uint amount) internal {
        require(amount < contractBalance);
        inviter.transfer(amount);
    }


    function increaseJackpot(uint increaseAmount, uint _betId) internal {
        require (increaseAmount <= contractBalance);
        emit LogJackpot(_betId, msg.sender, increaseAmount);
        jackpot += increaseAmount;
        jackpotContract.transfer(increaseAmount);
        if(msg.value >= minJackpotBet){
            bool result = jackpotContract.call(bytes4(keccak256("addPlayer(address)")),msg.sender);
            require(result);
        }
        
    }

    function getDiceWinAmount(uint _amount, uint _probability) view internal returns (uint) {
        require(_probability > 0 && _probability < 100);
        return ((_amount * (100 - _probability) / _probability + _amount) * (houseEdgeDivisor - houseEdge) / houseEdgeDivisor) - _amount;
    }

    function getHouseEdgeAmount(uint _amount, uint _probability) view internal returns (uint) {
        require(_probability > 0 && _probability < 100);
        return (_amount * (100 - _probability) / _probability + _amount) * houseEdge / houseEdgeDivisor;
    }

    function getJackpotFee(uint houseEdgeAmount) view internal returns (uint) {
        return houseEdgeAmount * jackpotOfHouseEdge / 1000;
    }

    function rand() internal returns (uint256) {
        seed = uint256(keccak256(msg.sender, blockhash(block.number - 1), block.coinbase, block.difficulty));
        return seed;
    }

    function OwnerSetPrizePool(address _addr) external onlyOwner {
        require(_addr != address(0));
        jackpotContract = _addr;
    }

    function ownerUpdateContractBalance(uint newContractBalanceInWei) public onlyOwner{
        contractBalance = newContractBalanceInWei;
    }

    function ownerSetHouseEdge(uint newHouseEdge) public onlyOwner{
        require(newHouseEdge <= 1000);
        houseEdge = newHouseEdge;
    }

    function ownerSetMinJackpoBet(uint newVal) public onlyOwner{
        require(newVal <= 10 ether);
        minJackpotBet = newVal;
    }

    function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public onlyOwner{
        require(newMaxProfitAsPercent <= 100000);
        maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
        setMaxProfit();
    }

    function ownerSetMinBet(uint newMinimumBet) public onlyOwner{
        minBet = newMinimumBet;
    }

    function ownerSetMaxBet(uint newMaxBet) public onlyOwner{
        maxBet = newMaxBet;
    }

    function ownerSetJackpotOfHouseEdge(uint newProportion) public onlyOwner{
        require(newProportion <= 1000);
        jackpotOfHouseEdge = newProportion;
    }

    function ownerSetRecommendProportion(uint newRecommendProportion) public onlyOwner{
        require(newRecommendProportion <= 1000);
        recommendProportion = newRecommendProportion;
    }
    
    function setMaxProfit() internal {
        maxProfit = (contractBalance * maxProfitAsPercentOfHouse) / maxProfitDivisor;  
    }
    
    function ownerSetjackpotContract(address newJackpotContract) public onlyOwner{
        jackpotContract = newJackpotContract;
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

    function ownerTransferEther(address sendTo, uint amount) public onlyOwner{        
        contractBalance = safeSub(contractBalance, amount);		
        setMaxProfit();
        sendTo.transfer(amount);
        emit LogOwnerTransfer(sendTo, amount);
    }

    function ownerChangeOwner(address newOwner) public onlyOwner{
        owner = newOwner;
    }

    function ownerkill() public onlyOwner{
        selfdestruct(owner);
    }
}