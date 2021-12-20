// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC20.sol";
import "./RandomNumberConsumer.sol";
import "./ReentrancyGuard.sol";
import "./NotContract.sol";
import "./IRandomCaller.sol";

interface ILottery{
    function startNewRound(uint256 betPrice,uint256 endTime) external;
    function lottery() external;
    function settlementLottery() external;
    function buyLottery(address user,uint256[6][]memory values) external;
    function claimThePrize(uint256 roundNumber) external;
    function calculateBonus(address user,uint256 roundNumber) external view returns(uint256 amount,bool claimed);
    function getWinningNumber(uint256 roundNumber)external view returns(uint256[] memory expandedValues);

    event LotteryEvent(uint256 indexed roundNumber);
    event SettlementLottery(uint256 indexed roundNumber,uint256 prizePool,uint256 prizePoolRemainder);
    event StartNewRound(uint256 indexed roundNumber);

    event BuyLottery(uint256 ticketsMoney);
    event ClaimThePrize(uint256 amount);

    event NotEnoughPayBonuses(); 
}

contract LabsLottery is ILottery,IRandomCaller,Ownable,ReentrancyGuard,NotContract{
    RandomNumberConsumer public Randomer;
    IERC20 public LabsToken;

    uint256 private CurrentRound;
    uint256 private SettlementRound;

    mapping(uint256 => Lottery) private Lotteries;

    mapping(address => mapping (uint256 => uint256[6][])) private TicketsOfUser;
    mapping(address => History[]) private UserHistories;

    enum lotterystatus{
        Close,
        Claimable,
        Open
    }

    struct Lottery{
        uint256 TicketPrice;
        uint256 TicketCount;
        uint256 EndTime;
        uint256 PrizePool;                  // total prize pool
        uint256 PrizePoolRemainder;
        lotterystatus Status;
        mapping(uint256 => uint256) CountOfTicket;   // count of ticket values
        mapping(uint256 => uint256) WinnersCount;       // Number of winners of each award
        mapping(address => bool) Claimed;           // claimed users
        mapping(address => uint8) NumberOfPurchases;
    }

    struct History{
        uint256 TimeStamp;
        uint256 RoundNumber;
        uint256 TotalTickets;
    }

    constructor (address randomer,address token)  {
        Randomer = RandomNumberConsumer(randomer);
        LabsToken = IERC20(token);
        Lotteries[CurrentRound].Status = lotterystatus.Close;
    }

    function startNewRound(uint256 ticketPrice,uint256 endTime) public onlyOwner override {
        require(Lotteries[CurrentRound].Status != lotterystatus.Open,"Current round has not yet opened!");
        
        CurrentRound++;
        Lotteries[CurrentRound].Status = lotterystatus.Open;
        Lotteries[CurrentRound].TicketPrice = ticketPrice;
        Lotteries[CurrentRound].EndTime = endTime;

        emit StartNewRound(CurrentRound);
    }

    function lottery() public onlyOwner override {
        require(block.timestamp > Lotteries[CurrentRound].EndTime,"Not a lottery time!");
        require(Lotteries[CurrentRound].Status == lotterystatus.Open,"The current round is not started or has ended!");

        Lotteries[CurrentRound].Status = lotterystatus.Close;
        Randomer.getRandomNumber(CurrentRound);

        SettlementRound = CurrentRound;

        emit LotteryEvent(CurrentRound);
    }

    function setRandomer(address randomer) public onlyOwner{
        Randomer = RandomNumberConsumer(randomer);
    }

    function settlementLottery() public override onlyOwner{
        Randomer.genarateLotteryNumber(SettlementRound);
        _settlementLottery(SettlementRound);
    }
    
    function _settlementLottery(uint256 roundNumber) internal  {
        require(Lotteries[roundNumber].Status == lotterystatus.Close,"Current round has not yet opened!");

        uint256[] memory winningNumber = getWinningNumber(roundNumber);
        uint256 amount = 0;

        uint256 number6 = (winningNumber[0] * (10 ** 10)) + (winningNumber[1] * (10 ** 8)) + (winningNumber[2] * (10 ** 6)) + (winningNumber[3] * (10 ** 4))+ (winningNumber[4] * (10 ** 2)) + winningNumber[5];
        Lotteries[roundNumber].WinnersCount[6] = Lotteries[roundNumber].CountOfTicket[number6];
        amount += ((Lotteries[roundNumber].PrizePool) * 40 / 100) * Lotteries[roundNumber].WinnersCount[6];

        uint256 number5 = (winningNumber[0] * (10 ** 8)) + (winningNumber[1] * (10 ** 6)) + (winningNumber[2] * (10 ** 4))  + (winningNumber[3] * (10 ** 2))+ winningNumber[4];
        Lotteries[roundNumber].WinnersCount[5] = (Lotteries[roundNumber].CountOfTicket[number5]) - (Lotteries[roundNumber].CountOfTicket[number6]);
        amount += ((Lotteries[roundNumber].PrizePool) * 26 / 100) * Lotteries[roundNumber].WinnersCount[5];

        uint256 number4 = (winningNumber[0] * (10 ** 6)) + (winningNumber[1] * (10 ** 4)) + (winningNumber[2] * (10 ** 2)) + winningNumber[3];
        Lotteries[roundNumber].WinnersCount[4] = (Lotteries[roundNumber].CountOfTicket[number4]) - (Lotteries[roundNumber].CountOfTicket[number5]);
        amount += ((Lotteries[roundNumber].PrizePool) * 15 / 100) * Lotteries[roundNumber].WinnersCount[4];

        uint256 number3 = (winningNumber[0] * (10 ** 4)) + (winningNumber[1] * (10 ** 2)) + winningNumber[2];
        Lotteries[roundNumber].WinnersCount[3] = (Lotteries[roundNumber].CountOfTicket[number3]) - (Lotteries[roundNumber].CountOfTicket[number4]);
        amount += ((Lotteries[roundNumber].PrizePool) * 10 / 100) * Lotteries[roundNumber].WinnersCount[3];
        
        uint256 number2 = (winningNumber[0] * (10 ** 2)) + winningNumber[1];
        Lotteries[roundNumber].WinnersCount[2] = (Lotteries[roundNumber].CountOfTicket[number2]) - (Lotteries[roundNumber].CountOfTicket[number3]);
        amount += ((Lotteries[roundNumber].PrizePool) * 6 / 100) * Lotteries[roundNumber].WinnersCount[2];

        uint256 number1 = winningNumber[0];
        Lotteries[roundNumber].WinnersCount[1] = Lotteries[roundNumber].CountOfTicket[number1]- (Lotteries[roundNumber].CountOfTicket[number2]);
        amount += ((Lotteries[roundNumber].PrizePool) * 3 / 100) * Lotteries[roundNumber].WinnersCount[1];

        // 计算上轮游戏结果，获得奖池结余
        if(amount > Lotteries[roundNumber].PrizePool){
            Lotteries[roundNumber].PrizePoolRemainder = 0;

            emit NotEnoughPayBonuses();
        }else{       
            Lotteries[roundNumber].PrizePoolRemainder = Lotteries[roundNumber].PrizePool - amount;
        }

        Lotteries[roundNumber].Status = lotterystatus.Claimable;

        emit SettlementLottery(roundNumber,Lotteries[roundNumber].PrizePool, Lotteries[roundNumber].PrizePoolRemainder);
    }
    
    function buyLottery(address user,uint256[6][] memory numbers) public notContract nonReentrant override {
        require(Lotteries[CurrentRound].Status == lotterystatus.Open,"The current round is not started or has ended!");
        require(Lotteries[CurrentRound].EndTime > block.timestamp,"This wheel activity has ended, and the beginning of the next round of games!");
        
        require(numbers.length <= 20,"Single purchase limit 20");
        require((Lotteries[CurrentRound].NumberOfPurchases[user] + numbers.length) <= 100,"Purchase limit 100 per round");

        Lotteries[CurrentRound].NumberOfPurchases[user] += uint8(numbers.length);

        History memory history = History(block.timestamp,CurrentRound,numbers.length);
        UserHistories[user].push(history);

        for(uint8 i = 0; i < numbers.length; i++){
            uint256 index0 = numbers[i][0];
            Lotteries[CurrentRound].CountOfTicket[index0]++;

            uint256 index1 = (numbers[i][0] * (10 ** 2)) + numbers[i][1];
            Lotteries[CurrentRound].CountOfTicket[index1]++;

            uint256 index2 = (numbers[i][0] * (10 ** 4)) + (numbers[i][1] * (10 ** 2)) + numbers[i][2];
            Lotteries[CurrentRound].CountOfTicket[index2]++;

            uint256 index3 = (numbers[i][0] * (10 ** 6)) + (numbers[i][1] * (10 ** 4)) + (numbers[i][2] * (10 ** 2)) + numbers[i][3];
            Lotteries[CurrentRound].CountOfTicket[index3]++;

            uint256 index4 = (numbers[i][0] * (10 ** 8)) + (numbers[i][1] * (10 ** 6)) + (numbers[i][2] * (10 ** 4)) + (numbers[i][3] * (10 ** 2)) + numbers[i][4];
            Lotteries[CurrentRound].CountOfTicket[index4]++;

            uint256 index5 = (numbers[i][0] * (10 ** 10)) + (numbers[i][1] * (10 ** 8)) + (numbers[i][2] * (10 ** 6)) + (numbers[i][3] * (10 ** 4)) + (numbers[i][4] * (10 ** 2)) + numbers[i][5];
            Lotteries[CurrentRound].CountOfTicket[index5]++;

            TicketsOfUser[user][CurrentRound].push(numbers[i]);
        }

        uint256 amount = Lotteries[CurrentRound].TicketPrice * numbers.length;
        LabsToken.transferFrom(msg.sender, address(this), amount);

        Lotteries[CurrentRound].TicketCount += numbers.length;
        Lotteries[CurrentRound].PrizePool += amount;

        emit BuyLottery(amount);
    }

    function claimThePrize(uint256 roundNumber) public notContract nonReentrant override{
        require(Lotteries[roundNumber].Status == lotterystatus.Claimable,"The current wheel has not arrived at the settlement phase!");

        uint256 amount;
        bool claimed;

        (amount,claimed) = calculateBonus(msg.sender,roundNumber);

        require(!claimed,"You have received this round of bonuses");
        require(amount > 0,"This wheel activity has not been award");

        LabsToken.transfer(msg.sender, amount);
        Lotteries[roundNumber].Claimed[msg.sender] =  true;

        emit ClaimThePrize(amount);
    }

    function calculateBonus(address user,uint256 roundNumber) public override view returns(uint256 amount,bool claimed){
        if (Lotteries[roundNumber].Status != lotterystatus.Claimable){
            return (0,false);
        }

        uint256[] memory winningNumber = getWinningNumber(roundNumber);

        uint256[6][] memory tickets = TicketsOfUser[user][roundNumber];
        for(uint8 i = 0; i < tickets.length; i++){
            if (winningNumber[0] != tickets[i][0]){
                continue;
            }            

            if (winningNumber[1] != tickets[i][1]){
                // 中1位
                amount += (Lotteries[roundNumber].PrizePool) * 3 / 100;
                continue;
            }

            if (winningNumber[2] != tickets[i][2]){
                // 中2位 
                amount += (Lotteries[roundNumber].PrizePool) * 6 / 100;
                continue;
            }

            if (winningNumber[3] != tickets[i][3]){
                // 中3位
                amount += (Lotteries[roundNumber].PrizePool) * 10 / 100;
                continue;
            }

            if (winningNumber[4] != tickets[i][4]){
                // 中4位
                amount += (Lotteries[roundNumber].PrizePool) * 15 / 100;
                continue;
            }    

            if (winningNumber[5] != tickets[i][5]){
                // 中5位
                amount += (Lotteries[roundNumber].PrizePool) * 26 / 100;
                continue;
            }
            
            // 中6位   
            amount += (Lotteries[roundNumber].PrizePool) * 40 / 100;
            continue;
        }

        return (amount,Lotteries[roundNumber].Claimed[user]);
    }

    function getWinningNumber(uint256 roundNumber) public override view returns(uint256[] memory expandedValues){
        require(Randomer.randomNumbers(roundNumber) > 0,"This round has not lottery");
        return Randomer.getWinningNumber(roundNumber);
    }
    
    function getWinnersCount(uint256 roundNumber) public view returns(uint256[6] memory count){
        count[0] = Lotteries[roundNumber].WinnersCount[1];
        count[1] = Lotteries[roundNumber].WinnersCount[2];
        count[2] = Lotteries[roundNumber].WinnersCount[3];
        count[3] = Lotteries[roundNumber].WinnersCount[4];
        count[4] = Lotteries[roundNumber].WinnersCount[5];
        count[5] = Lotteries[roundNumber].WinnersCount[6];
    }
    
    function getUserClaimed(address user,uint256 roundNumber) public view returns(bool){
        return Lotteries[roundNumber].Claimed[user];
    }

    function boughtTickets(address user,uint256 roundNumber) public view returns(uint256[6][] memory tickets){
        tickets = TicketsOfUser[user][roundNumber];
    }

    function randomCallback(uint256 roundNumber) public override{
        require(msg.sender == address(Randomer), "Only Randomer Call");

        emit CallBack(msg.sender,roundNumber);
    }

    struct DisplayHistory{
        uint256 TimeStamp;
        uint256 RoundNumber;
        uint256 TotalTickets;
        bool Claimed;
        uint256 Bonus;
    }
    // Get the buy tickets history of users
    function getUserBuyHistoriesWithPage(address user,uint256 page,uint256 rows,bool desc) public view returns(DisplayHistory[] memory histories,uint256 totalHistories,uint256 totalPage){
        History[] memory _histories = UserHistories[user];

        totalHistories = _histories.length;

        if (totalHistories == 0) {
            return (histories,0,0);
        }

        totalPage =  (totalHistories + rows - 1) / rows;
        if (page > totalPage){
            return (histories,0,0);
        }
        
        if (desc == false){
            uint256 startIndex = (page-1)*rows;
            uint256 endIndex = page * rows;
            if (endIndex > totalHistories){
                endIndex = totalHistories;
            }

            histories = new DisplayHistory[](endIndex - startIndex);
            for(uint i = startIndex ;i < endIndex; i++){
                DisplayHistory memory history;

                history.TimeStamp = _histories[i].TimeStamp;
                history.RoundNumber = _histories[i].RoundNumber;
                history.TotalTickets = _histories[i].TotalTickets;
                (history.Bonus,history.Claimed) = calculateBonus(user,history.RoundNumber);
                
                histories[i-startIndex] = history;
            }
        }else
        {   
            uint256 startIndex = totalHistories + (rows - 1) - (rows * page);
            uint256 endIndex = 0;
            if(startIndex > rows){
                endIndex = startIndex + 1 - rows;
            }

            histories = new DisplayHistory[](startIndex - endIndex + 1);
            uint256 j = 0;
            for(uint i = startIndex; i >= endIndex; i--){
                DisplayHistory memory history;

                history.TimeStamp = _histories[i].TimeStamp;
                history.RoundNumber = _histories[i].RoundNumber;
                history.TotalTickets = _histories[i].TotalTickets;
                (history.Bonus,history.Claimed) = calculateBonus(user,history.RoundNumber);

                histories[j] = history;
                
                j++;
                if (i == 0){
                    break;
                }
            }
        }        
        return (histories,totalHistories,totalPage);
    }

    function currentRound() public view returns(uint256 roundNumber,uint8 status){
        return (CurrentRound,uint8(Lotteries[CurrentRound].Status));
    }

    function lotteries(uint256 roundNumber) public view returns(
        uint256 ticketPrice,     
        uint256 ticketCount,      
        uint256 endTime,
        uint256 prizePool,        
        uint256 prizePoolRemainder,   
        lotterystatus status
    ){
        ticketPrice = Lotteries[roundNumber].TicketPrice;
        ticketCount = Lotteries[roundNumber].TicketCount;
        endTime = Lotteries[roundNumber].EndTime;
        prizePool = Lotteries[roundNumber].PrizePool;
        prizePoolRemainder = Lotteries[roundNumber].PrizePoolRemainder;
        status = Lotteries[roundNumber].Status;
    }

    function numberOfPurchases(address user,uint256 roundNumber) public view returns(uint256){
        return Lotteries[roundNumber].NumberOfPurchases[user];
    }

    // 拒绝ETH转入
    fallback() external{
        revert("Refuse to receive MATIC TOKEN");
    }
}