pragma solidity ^0.4.25;

contract Game {
    using SafeMath for *;
    using GameKeysCalculate for uint256;
    
    //****************
    // Game settings
    //****************
    string constant public name = "World Creator";
    string constant public symbol = "WCOR";
    uint256 constant private roundInitTime = 24 hours;
    // uint256 constant private roundInitTime = 30 seconds;
    uint256 constant private roundincreaseTime = 32 seconds;
    uint256 constant private roundMaxTime = 24 hours;
    // uint256 constant private roundMaxTime = 30 seconds;
    uint256 private platformBalance;
    address private admin;
    
    //****************
    // Player Info
    //****************
    mapping (address => uint256) private playerIDXAddress;
    mapping (address => GameModel.PlayerInfo) private playerInfoXAddress;
    uint256 private totalPlayerNumber;
    
    //****************
    // Round Info
    //****************
    uint256 private totalRoundNumber;
    mapping (uint256 => GameModel.RoundInfo) private roundInfoXRound;
    mapping (uint256 => GameModel.RoundResultInfo) private roundResultXRound;
    
    //****************
    // Distribution Proportion
    //****************
    uint8 constant distributionForInvition = 10;
    uint8 constant distributionForHolder = 40;
    uint8 constant distributionForPot = 50;
    uint8 constant distributionForWinner = 60;
    uint8 constant distributionForPlatform = 5;
    uint8 constant distributionForNextPot = 35;
    //****************
    //Events
    //****************
    event attendGameEvent(uint256 indexed playerId,uint256 indexed keyCount);
    event userWithDrawEvent(address indexed fromAddress,address indexed toAddress, uint256 indexed amount);
    
    constructor() public {
        admin = msg.sender;
        totalRoundNumber = 0;
    }
    
    function registerNewAccount() private {
        totalPlayerNumber++;
        playerIDXAddress[msg.sender] = totalPlayerNumber;
    }
    
    //********************
    // for UI & viewing things on etherscan
    //********************
    
    function getBuyPrice() public pure returns(uint256) {
        return(100000000000000);
    }
    
    function getGameEndTime() public view returns(uint256 _endTime) {
        return(roundInfoXRound[totalRoundNumber].endTime);
    }
    
    
    function getTimeLeft() private view returns(uint256) {
        uint256 nowTime = now;
        if (nowTime < roundInfoXRound[totalRoundNumber].endTime) {
            return(roundInfoXRound[totalRoundNumber].endTime - nowTime);
        } else {
            return(0);
        }
    }
    
    function getRoundResultInfoWithRoundID(uint256 _roundID) public view returns(uint256,uint256,address,uint256,uint256,uint256) {
        uint256 ethInPot = roundInfoXRound[_roundID].ethCount;
        uint256 winnerBouns = roundResultXRound[_roundID].winnerBonus;
        uint256 beginTime = roundInfoXRound[_roundID].startTime;
        uint256 endTime = roundInfoXRound[_roundID].endTime;
        address winnerAddress = roundResultXRound[_roundID].winnerAddress;
        return(
            _roundID,
            ethInPot,
            winnerAddress,
            winnerBouns,
            beginTime,
            endTime
            );
    }
    
    function getCurrentRoundInfo() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256){
        uint256 id = totalRoundNumber;
        uint256 totalBouns = roundInfoXRound[totalRoundNumber].ethCount;
        uint256 endTime = roundInfoXRound[totalRoundNumber].endTime;
        (uint256 keyCountInRound,uint256 holdEarningInRound,) = getPlayerInfoInRound(totalRoundNumber);
        uint256 totalKeyCount = roundInfoXRound[totalRoundNumber].keyCount;
        uint256 playerCount = roundInfoXRound[totalRoundNumber].playerNumber;
        return(
            id,
            totalBouns,
            endTime,
            keyCountInRound,
            holdEarningInRound,
            playerCount,
            totalKeyCount
            );
    }
    
    function getContractBalance() private view returns(uint256) {
        return(address(this).balance);
    }
    
    function joinGame(address _inviteAddress) public payable {
        require(msg.value >= 1000000000000000,"you need to pay 0.001 eth at least");
        if(playerIDXAddress[msg.sender] > 0) {
            buyCore(msg.sender,_inviteAddress);
        } else {
            registerNewAccount();
            buyCore(msg.sender,_inviteAddress);
        }
    }
    
    function joinGameWithBalance(uint256 _amount,address _inviterAddress) public {
        require(_amount >= 1000000000000000,"you need to pay 0.001 eth at least");
        require(playerInfoXAddress[msg.sender].earningsLeft >= _amount,"lack of ETH");
        buyCoreWithBalance(msg.sender,_inviterAddress,_amount);
    }
   
    function buyCore(address _playerAddress,address _inviteAddress) private {
        require(msg.value>=1000000000000000,"You need to pay 0.001 eth at least");
        if(now > roundInfoXRound[totalRoundNumber].endTime) {
            calculateResult();
            startNewRound();
        }
        
        if(roundInfoXRound[totalRoundNumber].playerNumber<1) {
            platformBalance = platformBalance.add(msg.value.mul(distributionForHolder).div(100));
        } else {
            for(uint256 i=1;i<=roundInfoXRound[totalRoundNumber].playerNumber;i++) {
                bool settled = false;
                for (uint256 j=1;j<i;j++) {
                    if (roundInfoXRound[totalRoundNumber].playerAddressXIndex[i] == roundInfoXRound[totalRoundNumber].playerAddressXIndex[j]) {
                        settled = true;
                        break;
                    }
                }
                
                if (!settled) {
                    playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].holdEarnings = playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].holdEarnings.add(playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].propertyXRound[totalRoundNumber].keyCount.mul(msg.value).mul(distributionForHolder).div(100).div(roundInfoXRound[totalRoundNumber].keyCount));
                    playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].propertyXRound[totalRoundNumber].holdEarnings =playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].propertyXRound[totalRoundNumber].holdEarnings.add(playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].propertyXRound[totalRoundNumber].keyCount.mul(msg.value).mul(distributionForHolder).div(roundInfoXRound[totalRoundNumber].keyCount).div(100));
                    playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].earningsLeft = playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].earningsLeft.add(playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].propertyXRound[totalRoundNumber].keyCount.mul(msg.value).mul(distributionForHolder).div(100).div(roundInfoXRound[totalRoundNumber].keyCount));
                }
            }   
        }
        roundInfoXRound[totalRoundNumber].endTime = roundInfoXRound[totalRoundNumber].endTime.add(getIncreaseTime(msg.value));
        roundInfoXRound[totalRoundNumber].keyCount = roundInfoXRound[totalRoundNumber].keyCount.add(msg.value.div(getBuyPrice()).mul(1 ether));
        playerInfoXAddress[_playerAddress].propertyXRound[totalRoundNumber].keyCount = playerInfoXAddress[_playerAddress].propertyXRound[totalRoundNumber].keyCount.add(msg.value.div(getBuyPrice()).mul(1 ether));
        if(_inviteAddress != 0x0000000000000000000000000000000000000000 && msg.sender != _inviteAddress) {
            playerInfoXAddress[_inviteAddress].inviteEarnings = playerInfoXAddress[_inviteAddress].inviteEarnings.add(msg.value.mul(distributionForInvition).div(100));
            playerInfoXAddress[_inviteAddress].earningsLeft = playerInfoXAddress[_inviteAddress].earningsLeft.add(msg.value.mul(distributionForInvition).div(100));
        } else {
            platformBalance = platformBalance.add(msg.value.mul(distributionForInvition).div(100));
        }
        roundInfoXRound[totalRoundNumber].playerNumber++;
        roundInfoXRound[totalRoundNumber].playerAddressXIndex[roundInfoXRound[totalRoundNumber].playerNumber]=_playerAddress;
        roundInfoXRound[totalRoundNumber].ethCount = roundInfoXRound[totalRoundNumber].ethCount.add(msg.value.div(100).mul(distributionForPot));
    }
    
    function buyCoreWithBalance(address _playerAddress,address _inviteAddress,uint256 _amount) private {
        if(now > roundInfoXRound[totalRoundNumber].endTime) {
            calculateResult();
            startNewRound();
        }
        
        roundInfoXRound[totalRoundNumber].playerNumber++;
        roundInfoXRound[totalRoundNumber].playerAddressXIndex[roundInfoXRound[totalRoundNumber].playerNumber]=_playerAddress;
        if(roundInfoXRound[totalRoundNumber].playerNumber<=1) {
            platformBalance = platformBalance.add(_amount.mul(distributionForHolder).div(100));
        } else {
            for(uint256 i=1;i<roundInfoXRound[totalRoundNumber].playerNumber;i++) {
                bool settled = false;
                for (uint256 j=1;j<i;j++) {
                    if (roundInfoXRound[totalRoundNumber].playerAddressXIndex[i] == roundInfoXRound[totalRoundNumber].playerAddressXIndex[j]) {
                        settled = true;
                        break;
                    }
                }
                
                if (!settled) {
                    playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].holdEarnings = playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].holdEarnings.add(playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].propertyXRound[totalRoundNumber].keyCount.mul(_amount).mul(distributionForHolder).div(100).div(roundInfoXRound[totalRoundNumber].keyCount));
                    playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].propertyXRound[totalRoundNumber].holdEarnings =playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].propertyXRound[totalRoundNumber].holdEarnings.add(playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].propertyXRound[totalRoundNumber].keyCount.mul(_amount).mul(distributionForHolder).div(roundInfoXRound[totalRoundNumber].keyCount).div(100));
                    playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].earningsLeft = playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].earningsLeft.add(playerInfoXAddress[roundInfoXRound[totalRoundNumber].playerAddressXIndex[i]].propertyXRound[totalRoundNumber].keyCount.mul(_amount).mul(distributionForHolder).div(100).div(roundInfoXRound[totalRoundNumber].keyCount));
                }
            }   
        }
        roundInfoXRound[totalRoundNumber].endTime = roundInfoXRound[totalRoundNumber].endTime.add(getIncreaseTime(_amount));
        roundInfoXRound[totalRoundNumber].keyCount = roundInfoXRound[totalRoundNumber].keyCount.add(_amount).div(getBuyPrice()).mul(1 ether);
        playerInfoXAddress[_playerAddress].propertyXRound[totalRoundNumber].keyCount = playerInfoXAddress[_playerAddress].propertyXRound[totalRoundNumber].keyCount.add(_amount);
        if(_inviteAddress != 0x0000000000000000000000000000000000000000 && _playerAddress != _inviteAddress) {
            playerInfoXAddress[_inviteAddress].inviteEarnings = playerInfoXAddress[_inviteAddress].inviteEarnings.add(_amount.mul(distributionForInvition).div(100));
            playerInfoXAddress[_inviteAddress].earningsLeft = playerInfoXAddress[_inviteAddress].earningsLeft.add(_amount.mul(distributionForInvition).div(100));
        } else {
            platformBalance = platformBalance.add(_amount.mul(distributionForInvition).div(100));
        }
        roundInfoXRound[totalRoundNumber].ethCount = roundInfoXRound[totalRoundNumber].ethCount.add(_amount.div(100).mul(distributionForPot));
        playerInfoXAddress[_playerAddress].earningsLeft =  playerInfoXAddress[_playerAddress].earningsLeft.sub(_amount);
    }    
    
    function startNewRound() private {
        totalRoundNumber++;
        roundInfoXRound[totalRoundNumber].roundID = totalRoundNumber;
        roundInfoXRound[totalRoundNumber].startTime = now;
        roundInfoXRound[totalRoundNumber].endTime = now.add(roundInitTime);
    }
   
    function getPlayerInfo() private view returns(uint256,uint256,uint256) {
        uint256 inviteEarnings = playerInfoXAddress[msg.sender].inviteEarnings;
        uint256 holdEarnings = playerInfoXAddress[msg.sender].holdEarnings;
        uint256 jackpotEarings = playerInfoXAddress[msg.sender].jackpotEarings;
        return(
            inviteEarnings,
            holdEarnings,
            jackpotEarings
           );
    }
   
    function getPlayerInfoInRound(uint256 _roundID) private view returns(uint256,uint256,uint256) {
        uint256 keyCountInRound = playerInfoXAddress[msg.sender].propertyXRound[_roundID].keyCount;
        uint256 holdEarningsInRound = playerInfoXAddress[msg.sender].propertyXRound[_roundID].holdEarnings;
        uint256 jackpotEaringsInRound = playerInfoXAddress[msg.sender].propertyXRound[_roundID].jackpotEarings;
        return(
            keyCountInRound,
            holdEarningsInRound,
            jackpotEaringsInRound
            );
    }
    
    function getPlayerInfoWithRoundID(uint256 _roundID) private view returns(uint256,uint256,uint256,uint256,uint256,uint256) {
        (uint256 totalInvite,uint256 totalHold,uint256 totalJackpot) = getPlayerInfo();
        (uint256 keycountInRound,uint256 holdEarningsInRound,uint256 jackpotEaringsInRound) = getPlayerInfoInRound(_roundID);
        return(
            totalInvite,
            totalHold,
            totalJackpot,
            keycountInRound,
            holdEarningsInRound,
            jackpotEaringsInRound
            );
    }
    
    function getUserEarningsInfo() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
        uint256 earningsLeft = playerInfoXAddress[msg.sender].earningsLeft;
        (uint256 totalInvite,uint256 totalHold,uint256 totalJackpot,uint256 keycountInRound,uint256 holdEarningsInRound,uint256 jackpotEaringsInRound) = getPlayerInfoWithRoundID(totalRoundNumber);
        return(earningsLeft,totalInvite,totalHold,totalJackpot,keycountInRound,holdEarningsInRound,jackpotEaringsInRound);   
    }
   
    function getHistoryRoundList() public view returns(uint[]){
        uint[] memory history = new uint[](totalRoundNumber.mul(4));
        for(uint i=0;i<totalRoundNumber;i++) {
            history[i.mul(4)] = i+1;
            history[i.mul(4).add(1)] = playerInfoXAddress[msg.sender].propertyXRound[i+1].keyCount;
            history[i.mul(4).add(2)] = playerInfoXAddress[msg.sender].propertyXRound[i+1].holdEarnings;
            history[i.mul(4).add(3)] = playerInfoXAddress[msg.sender].propertyXRound[i+1].jackpotEarings;
        }
        return(history);
    }
   
    function calculateResult() private {
        roundResultXRound[totalRoundNumber].winnerAddress = roundInfoXRound[totalRoundNumber].playerAddressXIndex[roundInfoXRound[totalRoundNumber].playerNumber];
        roundResultXRound[totalRoundNumber].winnerBonus = roundInfoXRound[totalRoundNumber].ethCount.mul(distributionForWinner).div(100);
        roundResultXRound[totalRoundNumber].newPotAmount = roundInfoXRound[totalRoundNumber].ethCount.mul(distributionForNextPot).div(100);
        roundResultXRound[totalRoundNumber].platformAmount = roundInfoXRound[totalRoundNumber].ethCount.mul(distributionForPlatform).div(100);
        roundInfoXRound[totalRoundNumber+1].ethCount = roundResultXRound[totalRoundNumber].newPotAmount;
        playerInfoXAddress[roundResultXRound[totalRoundNumber].winnerAddress].jackpotEarings = playerInfoXAddress[roundResultXRound[totalRoundNumber].winnerAddress].jackpotEarings.add(roundResultXRound[totalRoundNumber].winnerBonus);
        playerInfoXAddress[roundResultXRound[totalRoundNumber].winnerAddress].propertyXRound[totalRoundNumber].jackpotEarings = playerInfoXAddress[roundResultXRound[totalRoundNumber].winnerAddress].propertyXRound[totalRoundNumber].jackpotEarings.add(roundResultXRound[totalRoundNumber].winnerBonus);
        platformBalance = platformBalance.add(roundInfoXRound[totalRoundNumber].ethCount.mul(distributionForPlatform).div(100));
        playerInfoXAddress[roundResultXRound[totalRoundNumber].winnerAddress].earningsLeft = playerInfoXAddress[roundResultXRound[totalRoundNumber].winnerAddress].earningsLeft.add(roundInfoXRound[totalRoundNumber].ethCount.mul(distributionForWinner).div(100));
   }
   
    function playerWithDraw(uint256 _amount) public {
        uint256 userBalance = playerInfoXAddress[msg.sender].earningsLeft;
        require(userBalance > _amount,"lack of ETH");
        msg.sender.transfer(_amount);
        playerInfoXAddress[msg.sender].earningsLeft = playerInfoXAddress[msg.sender].earningsLeft.sub(_amount);
        emit userWithDrawEvent(address(this),msg.sender,_amount);
    }
   
   function getPlatformBalance() public view returns(uint256) {
       require(msg.sender == admin,"have no right to access");
       return(platformBalance);
   }
   
    function withdraw(address _toAddress,uint256 _amount) public {
        require(platformBalance > _amount,"lack of ETH");
        require(_toAddress == admin, "have no right to access");
        _toAddress.transfer(_amount);
        platformBalance = platformBalance.sub(_amount);
        emit userWithDrawEvent(address(this),_toAddress,_amount);
    }
   
    function getIncreaseTime(uint256 _ethValue) private view returns(uint256) {
        uint256 keyCount = _ethValue.div(getBuyPrice());
        if(getTimeLeft() >= roundMaxTime) {
            return(0);
        } else {
          uint256 increaseTime = roundincreaseTime;
          if (now > roundInfoXRound[totalRoundNumber].startTime) {
            uint256 rate = SafeMath.pwr(2,(now - roundInfoXRound[totalRoundNumber].startTime).div(86400));
            increaseTime = keyCount.mul(roundincreaseTime.div(rate));
          } else {
            increaseTime = keyCount.mul(roundincreaseTime);   
          }
          if (getTimeLeft().add(increaseTime) >= roundMaxTime) {
              return(roundMaxTime.sub(getTimeLeft()));
          } else {
              return(increaseTime);
          }
        }
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }    
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }
    
    function add(uint256 a,uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    function sqrt(uint256 x) internal pure returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    function sq(uint256 x) internal pure returns (uint256)
    {
        return (mul(x,x));
    }
    
    function pwr(uint256 x, uint256 y) internal pure returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}

library GameModel {
    struct PlayerProperty {
        uint256 keyCount;
        uint256 holdEarnings;
        uint256 jackpotEarings;
    }
    
    struct PlayerInfo {
        uint256 earningsLeft;
        uint256 inviteEarnings;
        uint256 holdEarnings;
        uint256 jackpotEarings;
        mapping (uint256 => PlayerProperty) propertyXRound;
    }
    
    struct RoundInfo {
        uint256 roundID;
        uint256 startTime;
        uint256 endTime;
        uint256 ethCount;
        uint256 keyCount;
        uint256 playerNumber;
        mapping (uint256 => address) playerAddressXIndex;
    }

    struct RoundResultInfo {
        address winnerAddress;
        uint256 winnerBonus;
        uint256 newPotAmount;
        uint256 platformAmount;
    }

}


library GameKeysCalculate {
    using SafeMath for *;
    
    /*
    calculate how many keys would exist with given amount of eth
    @_eth   amount of eth you wish to sell
    */
    function keys(uint256 _eth) internal pure returns(uint256) {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }
    
    /*
    calculate how much eth would be in contract given a number of keys  
    @_keys amount keys you wish to sell
    */
    function eth(uint256 _keys) internal pure returns(uint256) {
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
    
    /*
    calculate number of keys received given XXX eth 
    @_curEth    how much eth exist in contract
    @_newEth    how much eth did player given
    */
    function keysRec(uint256 _curEth, uint256 _newEth) internal pure returns(uint256) {
        return (keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }
    
    /*
    calculate amount of eth you could get when XXX keys sold
    @_curKeys   current amount keys that exist in contract
    @_sellKeys  amount of keys you wish to sell 
    */
    function ethRec(uint256 _curKeys, uint256 _sellKeys) internal pure returns(uint256) {
        return ((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }
}