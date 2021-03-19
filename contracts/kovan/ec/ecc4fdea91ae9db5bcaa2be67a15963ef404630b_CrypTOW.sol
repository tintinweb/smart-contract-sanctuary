/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.5.0;
contract CrypTOW {
    
    address payable public owner;
    address payable developer;
    
    uint256 public minBet;
    uint256 public maxBet;
    uint256 public totalHundingBets;
    uint256 public totalWulfingBets;
    uint256 public currentRound;
    uint256 public roundStartTime;
    uint256 public roundDuringTime;
    uint256 public maxFee;
    
    struct PlayerInfo {
        uint256 round;
        address payable addr;
        uint256 amount;
        uint16 team;
        uint256 fee;
    }
    
    PlayerInfo[] public playerInfos;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        developer = msg.sender;
        minBet = 0.01 * (10 ** 18);
        maxBet = 10 * (10 ** 18);
        currentRound = 0;
        maxFee = 50;
    }
    
    function startFirstRound() public onlyOwner {
        startRound();
    }
    
    function setOwner(address payable addr) public onlyOwner {
        owner = addr;
    }
    
    function setMaxFee(uint256 percent) public onlyOwner {
        maxFee = percent;
    }
    
    function setRoundDuringTime(uint256 hour, uint256 min, uint256 sec) public onlyOwner {
        require(hour > 0,  "Hour is wrong value");
        require(min >= 0 && min < 60,  "Minute is wrong value");
        require(sec >= 0 && sec < 60,  "Second is wrong value");
        roundDuringTime = (((hour * 60) + min) * 60) + sec;
    }
    
    function startRound() private {
        require(roundDuringTime > 0, "During time was not set.");
        roundStartTime = block.timestamp;
        totalHundingBets = 0;
        totalWulfingBets = 0;
        currentRound++;
    }

    function checkPlayerExists(address player) public view returns(bool) {
        for (uint256 i = 0; i < playerInfos.length; i++) {
            if (playerInfos[i].addr == player) return true;
        }
        return false;
    }
    
    function betWithTeam(uint16 team) public payable {  // 1: Hunding, 2: Wulfing
        require(!checkPlayerExists(msg.sender), "Nonallow");
        require(msg.value >= minBet && msg.value <= maxBet, "Invalid amount");
        uint256 value = msg.value;
        uint256 percent = getFeePercent();
        uint256 fee = value * percent / 100;
        owner.transfer(fee);
        
        PlayerInfo memory info;
        info.round = currentRound;
        info.addr = msg.sender;
        info.amount = value - fee;
        info.team = team;
        info.fee = percent;
        
        playerInfos.push(info);
        if (team == 1) {
            totalHundingBets += msg.value;
        } else {
            totalWulfingBets += msg.value;
        }
    }
    
    // Generates a number between 1 and 10 that will be the winner
    function distribute(uint16 teamWinner) public {
        address payable[10000] memory winners;
    
        uint256 count = 0; // This is the count for the array of winners
        uint256 LoserBet = 0; //This will take the value of all losers bet
        uint256 WinnerBet = 0; //This will take the value of all winners bet
        uint256 bet;
    
        for (uint256 j = 0; j < playerInfos.length; j++) {
            if (playerInfos[j].team == teamWinner && playerInfos[j].round == currentRound) {
                winners[count] = playerInfos[j].addr;
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
            for (uint256 j = 0; j < playerInfos.length; j++) {
                if (playerInfos[j].addr == winners[i] && playerInfos[j].round == currentRound) {
                    bet = playerInfos[j].amount;
                    winners[i].transfer((bet * (10000 + (LoserBet * 10000 / WinnerBet))) / 10000);
                }
            }
        }

        LoserBet = 0; // reinitialize the bets
        WinnerBet = 0;
        totalHundingBets = 0;
        totalWulfingBets = 0;
    }
    
    function getFeePercent() public view returns (uint256) {
        require(roundStartTime > 0, "Round does not started.");
        require(roundDuringTime > 0, "During time was not set.");
        uint256 currentTime = block.timestamp;
        uint256 percent = (currentTime - roundStartTime) / roundDuringTime * maxFee;
        return percent;
    }
    
    function getRoundRemainTime() public view returns (uint256) {
        require(roundStartTime > 0, "Round does not started.");
        require(roundDuringTime > 0, "During time was not set.");
        uint256 currentTime = block.timestamp;
        uint256 remain = roundDuringTime - (currentTime - roundStartTime);
        return remain;
    }
}