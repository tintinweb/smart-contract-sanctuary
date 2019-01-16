pragma solidity ^0.4.25;

contract Game {
    using SafeMath for *;

    //****************
    // Game settings
    //****************
    string constant public name = "World Creator";
    string constant public symbol = "WCOR";
    uint256 constant private roundInitTime = 1 hours;
    uint256 constant private roundincreaseTime = 32 seconds;
    uint256 constant private roundMaxTime = 1 hours;
    uint256 private platformBalance;
    address private admin;
    
    //****************
    // Player Info
    //****************
    mapping (address => uint256) private playerIDXAddress;
    mapping (address => GameModel.PlayerInfo) private playerInfoXAddress;
    mapping (address => address) inviterAddressXaddress;
    uint256 private totalPlayerNumber;
    
    //****************
    // Round Info
    //****************
    uint256 private totalRoundNumber;
    mapping (uint256 => GameModel.RoundInfo) private roundInfoXRound;

    //****************
    // Distribution Proportion
    //****************
    uint8 constant distributionForInvition = 9;
    uint8 constant distributionForInvition2 = 1;
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
    
    function registerNewAccount(address _inviteAddress) private {
        totalPlayerNumber++;
        playerIDXAddress[msg.sender] = totalPlayerNumber;
        inviterAddressXaddress[msg.sender] = _inviteAddress;
    }
    
    //********************
    // for UI & viewing things on etherscan
    //********************
    function getBuyPrice() public pure returns(uint256) {
        return(0.001 ether);
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
        uint256 ethInPot = getBounsInRound(_roundID);
        uint256 winnerBouns = ethInPot.mul(distributionForWinner).div(100);
        uint256 beginTime = roundInfoXRound[_roundID].startTime;
        uint256 endTime = roundInfoXRound[_roundID].endTime;
        address winnerAddress = roundInfoXRound[_roundID].winnerAddress;
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
        uint256 totalBouns = getBounsInRound(totalRoundNumber);
        uint256 endTime = roundInfoXRound[totalRoundNumber].endTime;
        (uint256 keyCountInRound,uint256 holdEarningInRound,) = getPlayerInfoInRound(totalRoundNumber);
        uint256 totalKeyCount = roundInfoXRound[totalRoundNumber].keysNumber;
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
        uint256 amount = msg.value;
        address sender = msg.sender;
        require(amount >= 0.001 ether,"you need to pay 0.001 eth at least");
        if(playerIDXAddress[sender] > 0) {
            buyCore(sender,inviterAddressXaddress[sender],amount);
        } else {
            registerNewAccount(_inviteAddress);
            buyCore(sender,inviterAddressXaddress[sender],amount);
        }
    }
    
    function joinGameWithBalance(uint256 _amount,address _inviterAddress) public {
        address sender = msg.sender;
        require(_amount >= 0.001 ether,"you need to pay 0.001 ether at least");
        require(balanceOf(sender) >= _amount,"lack of ETH");
        playerInfoXAddress[sender].withdrawAmount = playerInfoXAddress[sender].withdrawAmount.add(_amount);
        buyCore(sender,_inviterAddress,_amount);
    }
   
    function buyCore(address _playerAddress,address _inviteAddress,uint256 _amount) private {
        require(_amount>=0.001 ether,"You need to pay 0.001 ether at least");
        if(now > roundInfoXRound[totalRoundNumber].endTime) {
            calculateResult();
            startNewRound();
        }
        if(_inviteAddress != address(0) && _inviteAddress != _playerAddress) {
             playerInfoXAddress[_inviteAddress].inviteEarnings = playerInfoXAddress[_inviteAddress].inviteEarnings.add(_amount.mul(distributionForInvition).div(100));
             playerInfoXAddress[inviterAddressXaddress[_inviteAddress]].inviteEarnings = playerInfoXAddress[inviterAddressXaddress[_inviteAddress]].inviteEarnings.add(_amount.mul(distributionForInvition2).div(100));
        } else {
            platformBalance = platformBalance.add(_amount.mul(distributionForInvition).div(100));
        }
        
        roundInfoXRound[totalRoundNumber].playerNumber++;
        roundInfoXRound[totalRoundNumber].playerAddressXIndex[roundInfoXRound[totalRoundNumber].playerNumber]=_playerAddress;
        roundInfoXRound[totalRoundNumber].endTime = roundInfoXRound[totalRoundNumber].endTime.add(getIncreaseTime(_amount));
        roundInfoXRound[totalRoundNumber].jackpot = roundInfoXRound[totalRoundNumber].jackpot.add(_amount.mul(distributionForPot).div(100));
        roundInfoXRound[totalRoundNumber].jackpotForHolder = roundInfoXRound[totalRoundNumber].jackpotForHolder.add(_amount.mul(distributionForHolder).div(100));
        uint256 keysExist = roundInfoXRound[totalRoundNumber].keysNumber;
        roundInfoXRound[totalRoundNumber].keysNumber = keysExist.add(_amount.div(getBuyPrice()));
        playerInfoXAddress[_playerAddress].payCountXRound[totalRoundNumber]++;
        uint256 payIndex =  playerInfoXAddress[_playerAddress].payCountXRound[totalRoundNumber];
        playerInfoXAddress[_playerAddress].propertyXRound[totalRoundNumber].buyInfoXIndex[payIndex] = GameModel.BuyInfo(keysExist,_amount.div(getBuyPrice()));
        playerInfoXAddress[_playerAddress].propertyXRound[totalRoundNumber].keyCount = playerInfoXAddress[_playerAddress].propertyXRound[totalRoundNumber].keyCount.add(_amount.div(getBuyPrice()));
    }
    
    function startNewRound() private {
        totalRoundNumber++;
        roundInfoXRound[totalRoundNumber].roundID = totalRoundNumber;
        roundInfoXRound[totalRoundNumber].startTime = now;
        roundInfoXRound[totalRoundNumber].endTime = now.add(roundInitTime);
    }
   
    function getPlayerInfo() private view returns(uint256,uint256,uint256) {
        address sender = msg.sender;
        uint256 inviteEarnings = playerInfoXAddress[sender].inviteEarnings;
        uint256 holdEarnings = getHoldEarnings(sender);
        uint256 jackpotEarings = getBounsEarnings(sender);
        return(
            inviteEarnings,
            holdEarnings,
            jackpotEarings
           );
    }
   
    function getPlayerInfoInRound(uint256 _roundID) private view returns(uint256,uint256,uint256) {
        uint256 keyCountInRound = playerInfoXAddress[msg.sender].propertyXRound[_roundID].keyCount;
        uint256 holdEarningsInRound = getHoldEarningsInRound(msg.sender,_roundID);
        uint256 jackpotEaringsInRound = getBounsEarningsInRound(msg.sender,_roundID);
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
        uint256 earningsLeft = balanceOf(msg.sender);
        (uint256 totalInvite,uint256 totalHold,uint256 totalJackpot,uint256 keycountInRound,uint256 holdEarningsInRound,uint256 jackpotEaringsInRound) = getPlayerInfoWithRoundID(totalRoundNumber);
        return(earningsLeft,totalInvite,totalHold,totalJackpot,keycountInRound,holdEarningsInRound,jackpotEaringsInRound);   
    }
   
    function getHistoryRoundList() public view returns(uint[]){
        uint[] memory history = new uint[](totalRoundNumber.mul(4));
        for(uint i=0;i<totalRoundNumber;i++) {
            history[i.mul(4)] = i+1;
            history[i.mul(4).add(1)] = playerInfoXAddress[msg.sender].propertyXRound[i+1].keyCount;
            history[i.mul(4).add(2)] = getHoldEarningsInRound(msg.sender,i+1);
            history[i.mul(4).add(3)] = getBounsEarningsInRound(msg.sender,i+1);
        }
        return(history);
    }
   
    function calculateResult() private {
        roundInfoXRound[totalRoundNumber].winnerAddress = roundInfoXRound[totalRoundNumber].playerAddressXIndex[roundInfoXRound[totalRoundNumber].playerNumber];
        platformBalance = platformBalance.add(getBounsInRound(totalRoundNumber).mul(distributionForPlatform).div(100));
        roundInfoXRound[totalRoundNumber+1].jackpot = getBounsInRound(totalRoundNumber).mul(distributionForNextPot).div(100);

   }
   
    function playerWithDraw(uint256 _amount) public {
        address sender = msg.sender;
        uint256 userBalance = balanceOf(sender);
        require(userBalance >= _amount,"lack of ETH");
        playerInfoXAddress[sender].withdrawAmount = playerInfoXAddress[sender].withdrawAmount.add(_amount);
        sender.transfer(_amount);
        emit userWithDrawEvent(address(this),sender,_amount);
    }
   
   function getPlatformBalance() public view returns(uint256) {
       require(msg.sender == admin,"have no right to access");
       return(platformBalance);
   }
   
    function withdraw(address _toAddress,uint256 _amount) public {
        require(platformBalance >= _amount,"lack of ETH");
        require(_toAddress == admin, "have no right to access");
        platformBalance = platformBalance.sub(_amount);
        _toAddress.transfer(_amount);
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
    
    //**********************
    // calculate Data
    //**********************
    function getBounsInRound(uint256 _roundID) private view returns(uint256 _bouns) {
        uint256 jackpot = roundInfoXRound[_roundID].jackpot;
        return(jackpot);
    }
    
    function getHoldEarnings(address _userAddress) private view returns(uint256 _holdEarnings) {
        for(uint256 i=1;i<=totalRoundNumber;i++) {
            _holdEarnings = _holdEarnings.add(getHoldEarningsInRound(_userAddress,i));
        }
        return(_holdEarnings);
    }
    
    function getHoldEarningsInRound(address _userAddress,uint256 _roundID) private view returns(uint256 _holdEarnings) {
        // (2Total-2a-b)*b/total/total
        uint256 payCountInRound = playerInfoXAddress[_userAddress].payCountXRound[_roundID];
        uint256 totalKeys = roundInfoXRound[_roundID].keysNumber;
        for(uint256 i=1;i<=payCountInRound;i++) {
            uint256 _from = playerInfoXAddress[_userAddress].propertyXRound[_roundID].buyInfoXIndex[i].keyNumberInRound;  
            uint256 _length = playerInfoXAddress[_userAddress].propertyXRound[_roundID].buyInfoXIndex[i].keyNumberBuy;
            uint256 _value = roundInfoXRound[_roundID].jackpotForHolder.mul(2*totalKeys-2*_from-_length).mul(_length).div(totalKeys*totalKeys);
            _holdEarnings = _holdEarnings.add(_value);
        }
        return(_holdEarnings);
    }
    
    function getBounsEarnings(address _userAddress) private view returns(uint256 _bounsEarnings) {
        for(uint256 i=1;i<=totalRoundNumber;i++) {
            if(roundInfoXRound[i].winnerAddress != address(0) && roundInfoXRound[i].winnerAddress == _userAddress ) {
                _bounsEarnings = _bounsEarnings.add(getBounsInRound(i).mul(distributionForWinner).div(100));
            }
        }
        return(_bounsEarnings);
    }
    
    function getBounsEarningsInRound(address _userAddress,uint256 _roundID) private view returns(uint256 _bounsEarnings) {
        uint256 jackpot = getBounsInRound(_roundID);
        if(roundInfoXRound[_roundID].winnerAddress == _userAddress && roundInfoXRound[_roundID].winnerAddress != address(0)) {
            _bounsEarnings = jackpot.mul(distributionForWinner).div(100);
        }
        return(_bounsEarnings);
    }
    
    function getInviteEarnings(address _userAddress) private view returns(uint256 _inviteEarnings) {
        _inviteEarnings = playerInfoXAddress[_userAddress].inviteEarnings;
        return(_inviteEarnings);
    }
    
    function balanceOf(address _userAddress) private view returns(uint256 _earnings) {
        uint256 _holdEarnings = getHoldEarnings(_userAddress);
        uint256 _jackpotEarnings = getBounsEarnings(_userAddress);
        uint256 _inviteEarnings = playerInfoXAddress[_userAddress].inviteEarnings;
        uint256 _withdrawAmount = playerInfoXAddress[_userAddress].withdrawAmount;
        _earnings = _holdEarnings.add(_jackpotEarnings).add(_inviteEarnings).sub(_withdrawAmount);
        return(_earnings);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }
    
    function add(uint256 a,uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    function sq(uint256 x) internal pure returns (uint256) {
        return (mul(x,x));
    }
    
    function pwr(uint256 x, uint256 y) internal pure returns (uint256) {
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
        mapping (uint256 => BuyInfo) buyInfoXIndex;
    }
    
    struct BuyInfo {
        uint256 keyNumberInRound;
        uint256 keyNumberBuy;
    }
    
    struct PlayerInfo {
        uint256 withdrawAmount;
        uint256 inviteEarnings;
        mapping (uint256 => PlayerProperty) propertyXRound;
        mapping (uint256 => uint256) payCountXRound;
    }
    
    struct RoundInfo {
        uint256 roundID;
        uint256 startTime;
        uint256 endTime;
        uint256 playerNumber;
        mapping (uint256 => address) playerAddressXIndex;
        uint256 jackpot;
        uint256 jackpotForHolder;
        uint256 keysNumber;
        address winnerAddress;
    }
}