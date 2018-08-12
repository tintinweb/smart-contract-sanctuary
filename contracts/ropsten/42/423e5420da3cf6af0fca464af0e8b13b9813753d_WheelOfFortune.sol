pragma solidity ^0.4.17;

contract WheelOfFortune {
    address owner; //创建者
    mapping(uint => address[]) playersOfWheel; //当前转盘每一格对应的玩家
    uint betPool; //当前奖金池
    uint pieceCount; //转盘块数
    uint nextPieceCount; //下一次更新转盘块数
    uint roundIdx;
    address[] lastRoundWinners;
    uint lastRoundPieceIdx;
    uint lastRoundBetPool;
    
    function WheelOfFortune(uint initPieceCount) public payable{
        owner = msg.sender;
        pieceCount = initPieceCount;
        nextPieceCount = initPieceCount;
        roundIdx = 0;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier validPieceIndex(uint pieceIdx) {
        require(pieceIdx >= 0 && pieceIdx < pieceCount);
        _;
    }

    // 每次下注收取千分之一的小费
    modifier validTips(uint tips) {
        require(tips >= (msg.value - tips) / 1000);
        _;
    }

    modifier validLastRoundIdx(uint lastRid) {
        require(lastRid == roundIdx - 1);
        _;
    }

    // 匿名函数，当外部调用找不到时调用该函数
	event FallbackTrigged(bytes data);
    function() public payable {
        FallbackTrigged(msg.data);
    }

    event MakeBetEvent(address player, uint pieceIdx, uint totalBet, uint tips);
    function makeBet(uint pieceIdx, uint betCount, uint tips) public payable validPieceIndex(pieceIdx) validTips(tips) {
        // 同一块用户可以重复下注，不做限制
        for (uint idx = 0; idx < betCount; idx++) {
            playersOfWheel[pieceIdx].push(msg.sender);
        }
        betPool = betPool + msg.value - tips;
        MakeBetEvent(msg.sender, pieceIdx, msg.value - tips, tips);
    }

    function finishRound(uint pieceIdx) public payable validPieceIndex(pieceIdx) onlyOwner {
        // 清理上一轮获奖情况
        delete lastRoundWinners;
        lastRoundPieceIdx = 0;
        lastRoundBetPool = 0;
        // 将奖金池所有奖金平均分配给各个获奖者
        uint winnerCount = playersOfWheel[pieceIdx].length;
        if (winnerCount > 0) {
            uint prize = betPool / winnerCount;
            for (uint idx = 0; idx < winnerCount; idx++) {
                playersOfWheel[pieceIdx][idx].transfer(prize);
            }
            lastRoundWinners = playersOfWheel[pieceIdx];
            lastRoundPieceIdx = pieceIdx;
            lastRoundBetPool = betPool;
        }
        // 重新初始化奖金池
        betPool = 0;
        for (idx = 0; idx < pieceCount; idx++) {
            delete playersOfWheel[idx];
        }
        // 判断是否需要更新转盘块数
        if (nextPieceCount != pieceCount) {
            pieceCount = nextPieceCount;
        }
        roundIdx += 1;
    }

    event IncreasePieceCountEvent(uint count);
    function increasePieceCount(uint newPieceCount) public payable onlyOwner {
        nextPieceCount = newPieceCount;
    }

    // 提取小费
    function withDrawTips() public payable onlyOwner {
        if (this.balance - betPool - 10 > 0) {
            // 让合约保留10wei周转
            owner.transfer(this.balance - betPool - 10);
        }
    }

    function getLastRoundInfo(uint rid) public constant validLastRoundIdx(rid) returns (address[] winners, uint pieceIdx, uint winnerBetPool) {
        winners = lastRoundWinners;
        pieceIdx = lastRoundPieceIdx;
        winnerBetPool = lastRoundBetPool;
    }

}