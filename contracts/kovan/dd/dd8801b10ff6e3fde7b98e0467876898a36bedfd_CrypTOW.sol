/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

pragma solidity ^0.5.0;
contract CrypTOW {
    
    address payable public owner;
    address payable developer;
    
    uint256 public totalHundingBets;
    uint256 public totalWulfingBets;
    uint256 public roundStartTime;
    uint256 public maxFee;
    uint256 private currentRound;
    uint256 private totalRound;
    
    struct BetInfo {
        uint256 round;
        address payable addr;
        uint256 amount;
        uint16 team;
        uint256 fee;
    }
    
    BetInfo[] public betInfos;
    
    mapping (uint256 => uint256) private roundDatas;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        developer = msg.sender;
        currentRound = 0;
        maxFee = 50;
        totalRound = 100;
        for (uint256 i = 1; i <= totalRound; i++) {
            roundDatas[i] = 8;
        }
    }
    
    function startFirstRound() public onlyOwner {
        startRound();
    }
    
    function setOwner(address payable addr) public onlyOwner {
        require(owner != address(0), 'Invalid Address');
        owner = addr;
    }
    
    function setMaxFee(uint256 percent) public onlyOwner {
        maxFee = percent;
    }
    
    function setRoundTime(uint256 round, uint256 hour) public onlyOwner {
        roundDatas[round] = hour;
    }
    
    function startRound() private {
        require(roundDatas[currentRound] > 0, "During time was not set.");
        roundStartTime = block.timestamp;
        totalHundingBets = 0;
        totalWulfingBets = 0;
        currentRound++;
        totalRound++;
        roundDatas[totalRound] = 8;
    }

    function checkPlayerExists(address player) public view returns(bool) {
        for (uint256 i = 0; i < betInfos.length; i++) {
            if (betInfos[i].addr == player) return true;
        }
        return false;
    }
    
    function betWithTeam(uint16 team) public payable {  // 1: Hunding, 2: Wulfing
        uint256 value = msg.value;
        uint256 percent = getFeePercent();
        uint256 fee = value * percent / 100;
        owner.transfer(fee);
        
        BetInfo memory info;
        info.round = currentRound;
        info.addr = msg.sender;
        info.amount = value - fee;
        info.team = team;
        info.fee = percent;
        
        betInfos.push(info);
        if (team == 1) {
            totalHundingBets += value - fee;
        } else {
            totalWulfingBets += value - fee;
        }
    }
    
    // Generates a number between 1 and 10 that will be the winner
    function distribute(uint16 teamWinner) public {
        require(teamWinner == 1 || teamWinner == 2, "Invalid team");
        
        address payable[10000] memory winners;
    
        uint256 count = 0; // This is the count for the array of winners
        uint256 LoserBet = 0; //This will take the value of all losers bet
        uint256 WinnerBet = 0; //This will take the value of all winners bet
        uint256 bet;
    
        for (uint256 j = 0; j < betInfos.length; j++) {
            if (betInfos[j].team == teamWinner && betInfos[j].round == currentRound) {
                winners[count] = betInfos[j].addr;
                count++;
            }
        }
        
        if (teamWinner == 1) {
            LoserBet = totalWulfingBets;
            WinnerBet = totalHundingBets;
        } else {
            LoserBet = totalHundingBets;
            WinnerBet = totalWulfingBets;
        }
        
        for (uint256 i = 0; i < count; i++) {
            for (uint256 j = 0; j < betInfos.length; j++) {
                if (betInfos[j].addr == winners[i] && betInfos[j].round == currentRound) {
                    bet = betInfos[j].amount;
                    winners[i].transfer((bet * (10000 + (LoserBet * 10000 / WinnerBet))) / 10000);
                }
            }
        }

        LoserBet = 0; // reinitialize the bets
        WinnerBet = 0;
        totalHundingBets = 0;
        totalWulfingBets = 0;
        startRound();
    }
    
    function getCurrentRound() public view returns (uint256) {
        return currentRound;
    }
    
    function getFeePercent() public view returns (uint256) {
        require(roundStartTime > 0, "Round does not started.");
        require(roundDatas[currentRound] > 0, "During time was not set.");
        uint256 currentTime = block.timestamp;
        uint256 percent = (currentTime - roundStartTime) * maxFee / (roundDatas[currentRound] * 3600);
        if (percent > maxFee)
            percent = maxFee;
        return percent;
    }
    
    function getRoundRemainTime() public view returns (uint256 remainTime) {
        require(roundStartTime > 0, "Round does not started.");
        require(roundDatas[currentRound] > 0, "During time was not set.");
        uint256 currentTime = block.timestamp;
        uint256 remain = roundDatas[currentRound] * 3600 - (currentTime - roundStartTime);
        if (remain < 0)
            remain = 0;
        return remain;
    }
    
    function getRoundDatas() public view returns (uint256[] memory datas) {
        datas = new uint256[](100);
        for (uint256 i = 0; i < 100; i++) {
            datas[i] = roundDatas[i + currentRound + 1];
        }
        return datas;
    }
    
    function getHistory(address addr) public view returns (uint256[] memory rounds, uint256[] memory amounts, uint16[] memory teams, uint256[] memory fees) {
        require(addr != address(0), 'Invalid Address');
        uint256 count = 0;
        for (uint256 i = 0; i < betInfos.length; i++) {
            if (betInfos[i].addr == addr) {
                count++;
            }
        }
        
        rounds = new uint256[](count);
        amounts = new uint256[](count);
        teams = new uint16[](count);
        fees = new uint256[](count);
        
        uint256 index = 0;
        for (uint256 i = 0; i < betInfos.length; i++) {
            if (betInfos[i].addr == addr) {
                rounds[index] = betInfos[i].round;
                amounts[index] = betInfos[i].amount;
                teams[index] = betInfos[i].team;
                fees[index] = betInfos[i].fee;
                index++;
            }
        }
        
        return (rounds, amounts, teams, fees);
    }
}