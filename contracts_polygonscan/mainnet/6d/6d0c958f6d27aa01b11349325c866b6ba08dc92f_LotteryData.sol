pragma solidity ^0.4.24;

import "../SafeMath.sol";
import "../Ownable.sol";

interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function decimals() external view returns (uint8);
}

contract LotteryData is Ownable {
  using SafeMath for uint;
  

  enum LotteryMode {
    Sum,     
    Time,    
    Address  
  }
  

  enum LotteryStatus {
    Initial,  
    Started,  
    ToOpen,   
    Opened,   
    Refund    
  }


  struct LotteryConfig {
    uint startTime;         
    uint endTime;          
    bool dayLimit;           
    uint dayStartTime;      
    uint dayEndTime;        
    int timesPerItem;      
    uint amountPerAction;  
    uint openCondition;     
    uint copies;            
   
    uint totalAward;        
    uint awardPerCopy;     
    uint seed;   
  }


  struct JoinerInfo {
    mapping(address => uint) joinerAction; 
    address[] uniqueJoiners;              

    mapping(uint => address) indexJoiner;   
    address[] indexs;                
  }


  struct LotteryResult {
    address[] winnerAddrs;                   
    mapping(address => WinnerResult)  winners; 
    uint    drawCount;                      
    uint    totalDrawAmount;                  
    uint    totalRefundAmount;             
    address[]    drawedUsers;                
    address[]    refundUsers;              
    mapping(address => bool) refunded;        
    uint[] ownerDrawRecord;                  
  }

  struct WinnerResult {
    uint    award;        
    bool    drawed;        
    bool    exist;      
  }
  struct Lottery {
    string name;        
    LotteryMode mode;    
    LotteryStatus status;
    LotteryConfig config; 
    JoinerInfo joiner;  
    LotteryResult result;
  } 
  address public lotteryControl_;


  Lottery[] private lotteries_;

  event NewLotteryControl(address lotterControl);
  event JoinLottery(uint lotteryID);
  event OpenLottery(uint lotteryID);

  IERC20 usdtToken;
  constructor(address owner,IERC20 _usdt)  Ownable(owner) public {
      usdtToken = _usdt;
  }

  modifier onlyControl() {
    require(msg.sender == lotteryControl_, "only for control contract");
    _;
  }

  function setLotteryControl(address lotteryControl)
  onlyOwner public {
    lotteryControl_ = lotteryControl;
    emit NewLotteryControl(lotteryControl);
  }

  function newLottery(string name, 
    uint mode,
    uint startTime, uint endTime,
    bool dayLimit, uint dayStartTime, uint dayEndTime,
    int timesPerItem, uint amountPerAction,
    uint openCondition, uint copies)
    onlyControl public
    returns(uint)
  {
    lotteries_.length++;
    Lottery storage lottery = lotteries_[lotteries_.length - 1];
    lottery.name = name;
    lottery.status = LotteryStatus.Initial;
    lottery.mode = LotteryMode(mode);
    
    require(startTime < endTime, "startTime or endTime error");
    require (lottery.status == LotteryStatus.Initial, "lottery status error");
    if (dayLimit) {
      require(dayStartTime < dayEndTime, "dayStartTime or dayEndTime error" );
    }
    require(amountPerAction <= 10, "amountPerAction error");  
    require(copies > 0 && copies <= 100, "copies error");

    if (lottery.mode == LotteryMode.Time) {
      require(openCondition >= endTime, "openCondition error in Time Mode");
    }
    lottery.status = LotteryStatus.Started;
    lottery.config = LotteryConfig({
      startTime: startTime,
      endTime: endTime,
      dayLimit: dayLimit,
      dayStartTime: dayStartTime,
      dayEndTime: dayEndTime,
      timesPerItem: timesPerItem,
      amountPerAction: amountPerAction,
      openCondition: openCondition,
      copies: copies,
      totalAward: 0,
      awardPerCopy: 0,
      seed: 0
    });
    return lotteries_.length - 1;
  }
  function handRefundLottery(uint lotteryID)  onlyControl public {
    require(lotteryID < lotteries_.length);
    Lottery storage lottery = lotteries_[lotteryID];
    _refundLottery(lottery);
  }

  function _refundLottery(Lottery storage lottery)  internal {
    JoinerInfo storage joiner = lottery.joiner;
    LotteryResult storage result = lottery.result;

    for(uint i = 0; i < joiner.uniqueJoiners.length; i++) {
      address joinerAddr = joiner.uniqueJoiners[i];
      if (result.refunded[joinerAddr]) {
        continue;
      }

      uint action = joiner.joinerAction[joinerAddr];
      if (action == 0) {
        continue;
      }
      uint amount = action.mul(lottery.config.amountPerAction).mul(1e18);
      
      result.refunded[joinerAddr] = true;
        
      uint256 realAward = amount.mul(4).div(5);
      usdtToken.transfer(joinerAddr,realAward);
      


     
    //   if (!joinerAddr.send(amount)) {
    //     result.refunded[joinerAddr] = false;
    //     continue;
    //   }
      result.refundUsers.push(joinerAddr);
      result.totalRefundAmount = result.totalRefundAmount.add(amount);
    }

    lottery.status = LotteryStatus.Refund;
  }

  function queryLottery(uint lotteryID) view onlyControl public
    returns(
      string,
      uint,
      uint,          
      uint,                  
      address[],
      uint[],          
      uint,                        
      uint[]      
    )
  {
    require(lotteryID < lotteries_.length);

    Lottery storage lottery = lotteries_[lotteryID];
    LotteryConfig storage config = lottery.config;
    JoinerInfo storage joiner = lottery.joiner;

    //uint awardPerCopy = config.awardPerCopy.div(1e18); // uint: ether
    uint[] memory joinAction = new uint[](joiner.uniqueJoiners.length);
    for (uint i = 0; i < joiner.uniqueJoiners.length; i++) {
      joinAction[i] = joiner.joinerAction[joiner.uniqueJoiners[i]];
    }
    
    return(
      lottery.name, 
      uint(lottery.mode), 
      uint(lottery.status),
      config.totalAward.div(1e18), 
      //awardPerCopy,
      joiner.uniqueJoiners, 
      joinAction,
      joiner.indexs.length,
      lottery.result.ownerDrawRecord
    );
  }


  function queryLotteryResult(uint lotteryID)
    view onlyControl public 
    returns (
      uint,
      address[],
      uint[],           
      uint, 
      uint,                  
      uint, 
      address[],                  
      address[]
    )
  {
    require(lotteryID < lotteries_.length);

    Lottery storage lottery = lotteries_[lotteryID];
    LotteryResult storage result = lottery.result; 
 
    uint[] memory winnerAwards = new uint[](result.winnerAddrs.length);
    for (uint i = 0; i < result.winnerAddrs.length; i++) {
      //winnerAwards[i] = result.winners[result.winnerAddrs[i]].award.div(1e18);
      winnerAwards[i] = result.winners[result.winnerAddrs[i]].award;
    }
    
    //uint totalDrawAmount = result.totalDrawAmount.div(1e18);
    //uint totalRefundAmount = result.totalRefundAmount.div(1e18);

    return(
      uint(lottery.status),
      result.winnerAddrs,
      winnerAwards,
      result.drawCount, 
      result.totalDrawAmount,
      result.totalRefundAmount, 
      result.drawedUsers,
      result.refundUsers
    );
  }


  function joinLottery(uint lotteryID, address msgSender, uint msgValue)
    onlyControl public
  {
    require(lotteryID < lotteries_.length, "lotteryID error");
    Lottery storage lottery = lotteries_[lotteryID];

    bool checkRet = false;
    string memory errMsg = "";
    (checkRet, errMsg) = _checkJoinLottery(lottery, msgSender, msgValue);
    require(checkRet, errMsg);

    JoinerInfo storage joiner = lottery.joiner;
    uint index = joiner.indexs.push(msgSender) - 1;
    joiner.indexJoiner[index] = msgSender;
    if (joiner.joinerAction[msgSender] == 0) {
      joiner.uniqueJoiners.push(msgSender);
    }
    joiner.joinerAction[msgSender]++;
    lottery.config.totalAward += msgValue;


    _updateJoinLottery(lotteryID, lottery);

    emit JoinLottery(lotteryID);

  }

  function _updateJoinLottery(uint lotteryID, Lottery storage lottery) internal {

    LotteryConfig storage config = lottery.config;
    bool toOpen = false;

    if (lottery.mode == LotteryMode.Sum) {
      if (config.totalAward >= config.openCondition.mul(1e18)) {
        toOpen = true;
      }
    } else if (lottery.mode == LotteryMode.Time) {
      if (now >= config.openCondition) {
        toOpen = true;
      }
    } else if (lottery.mode == LotteryMode.Address) {
      if (lottery.joiner.uniqueJoiners.length >= config.openCondition) {
        toOpen = true;
      }
    }

    if (toOpen) {
      lottery.status = LotteryStatus.ToOpen;
      //openLottery(lotteryID);
      emit OpenLottery(lotteryID);  
    }
  }


  function checkOpenLottery(uint lotteryID) 
    view onlyControl public
    returns(bool)
  {
    require(lotteryID < lotteries_.length, "lotteryID error");
    Lottery storage lottery = lotteries_[lotteryID];
    require(lottery.status != LotteryStatus.Initial, "openLottery status error"); 
 
    LotteryConfig storage config = lottery.config;

    bool refund = false;
    bool toOpen = false;
    if (lottery.status == LotteryStatus.Started) {
      if (lottery.mode == LotteryMode.Sum || lottery.mode == LotteryMode.Address) {
        if (now >= config.endTime) {
          refund = true;
        }
      } else if (lottery.mode == LotteryMode.Time) {
        if (now >= config.openCondition) {
          toOpen = true;
        }
      }
    } else if (lottery.status == LotteryStatus.ToOpen) {
      return true;
    } else {
      return true;
    }
 
    if (refund || toOpen) {
      return true;
    }
    return false;
  }


 
  function openLottery(uint lotteryID) 
    onlyControl public
    returns(bool)
  {
    require(lotteryID < lotteries_.length, "lotteryID error");
    Lottery storage lottery = lotteries_[lotteryID];
    require(lottery.status != LotteryStatus.Initial, "openLottery status error");

    LotteryConfig storage config = lottery.config;

    if (lottery.status == LotteryStatus.Opened) {
      if (lottery.result.drawCount >= lottery.result.winnerAddrs.length) {

        return true;
      } else {
        _drawLottery(lottery);
        return true;
      }
    } 
 
    if (lottery.status == LotteryStatus.Refund) {
      return true; 
    }


    bool refund = false;
    if (lottery.status == LotteryStatus.Started) {
      if (lottery.mode == LotteryMode.Sum || lottery.mode == LotteryMode.Address) {
        if (now >= config.endTime) {
          refund = true;
        }
      } else if (lottery.mode == LotteryMode.Time) {
        if (now >= config.openCondition) {
          lottery.status = LotteryStatus.ToOpen;
        }
      }
    }

    if (refund) {
      _refundLottery(lottery);
      return true;
    }

    if (lottery.status == LotteryStatus.ToOpen) {
      _openLottery(lottery);
      return true;
    }
    return false;
  }


  function _drawLottery(Lottery storage lottery)  internal {
    require(lottery.status == LotteryStatus.Opened, "_drawLottery status error");
    
    LotteryResult storage result = lottery.result;

    for(uint i = 0; i < result.winnerAddrs.length; i++) {
      address winnerAddr = result.winnerAddrs[i];
      WinnerResult storage winner = result.winners[winnerAddr];
      if (!winner.exist || winner.drawed) {
        continue;
      }

      winner.drawed = true;
      require(result.totalDrawAmount <= lottery.config.totalAward, "_drawLottery totalDrawAmount error");
      

    uint256 realAward = winner.award.mul(4).div(5);

    usdtToken.transfer(winnerAddr,realAward);
    
    //   if (!winnerAddr.send(winner.award)) {
    //     winner.drawed = false;
    //     continue;
    //   } 
      result.drawedUsers.push(winnerAddr);
      result.drawCount++;
      result.totalDrawAmount = result.totalDrawAmount.add(winner.award);
    }
  }


  function _openLottery(Lottery storage lottery) internal {
    require(lottery.status == LotteryStatus.ToOpen, "_openLottery status error");

    LotteryConfig storage config = lottery.config;
    LotteryResult storage result = lottery.result;

    config.awardPerCopy = config.totalAward.div(config.copies);


    for(uint i = 0; i < config.copies; i++) {
      uint randNum = _getRandomNum(lottery);
      uint index = randNum % lottery.joiner.indexs.length;
      address winnerAddr = lottery.joiner.indexJoiner[index];
      if (!result.winners[winnerAddr].exist) {
        result.winnerAddrs.push(winnerAddr);
        result.winners[winnerAddr].exist = true;
      }
      result.winners[winnerAddr].award  += config.awardPerCopy;
    }

    lottery.status = LotteryStatus.Opened;
    _drawLottery(lottery);
  } 


 
  function _getRandomNum(Lottery storage lottery) internal returns(uint) {
    uint timeNow = now;
    uint seedTmp = uint(blockhash(block.number-1));
    uint randNum = uint(keccak256(abi.encodePacked(timeNow.add(lottery.config.seed).add(seedTmp))));
    lottery.config.seed++;
    return randNum;
  }

  function _checkJoinLottery(Lottery storage lottery, address msgSender, uint msgValue)
  internal view
  returns(bool, string)
  {

    if (lottery.status != LotteryStatus.Started) {
      return (false, "status error");
    }

    LotteryConfig storage config = lottery.config;
    uint timeNow = now;
    if (timeNow < config.startTime || timeNow > config.endTime) {
      return (false, "join time limit");
    }

    uint timeHour = (((now / 3600) % 24) + 8) % 24;
    if (config.dayLimit) {
      if (timeHour < config.dayStartTime || timeHour >= config.dayEndTime) {
        return (false, "join day time limit");
      }
    }

    if (config.timesPerItem != -1 && lottery.joiner.joinerAction[msgSender] >= uint(config.timesPerItem)) {
      return (false, "join timesPerItem limit");
    }

    //uint amountWeiPerAction = config.amountPerAction.mul(1e18);
    if (config.amountPerAction != msgValue.div(1e18 wei)) {
      return (false, "join value error");
    }
    return (true, "");
  }


  function getWithDrawAmount(uint lotteryID)
    view onlyControl public
    returns(uint) 
  {
    require(lotteryID < lotteries_.length);
    Lottery storage lottery = lotteries_[lotteryID];
    return lottery.config.totalAward;
  }

  function setLotteryConfig(
    uint lotteryID,
    uint startTime, uint endTime,
    bool dayLimit, uint dayStartTime, uint dayEndTime,
    int timesPerItem, uint amountPerAction,
    uint openCondition, uint copies
  )
     public
  {
    require(lotteryID < lotteries_.length, "lotteryID error");
    require(startTime < endTime, "startTime or endTime error");

    Lottery storage lottery = lotteries_[lotteryID];
    require (lottery.status == LotteryStatus.Initial, "lottery status error");

    if (dayLimit) {
      require(dayStartTime < dayEndTime, "dayStartTime or dayEndTime error" );
    }
    require(amountPerAction <= 10, "amountPerAction error"); 
    require(copies > 0 && copies <= 100, "copies error"); 


    if (lottery.mode == LotteryMode.Time) {
      require(openCondition >= endTime, "openCondition error in Time Mode");
    }
    
    lottery.status = LotteryStatus.Started;

    lottery.config = LotteryConfig({
      startTime: startTime,
      endTime: endTime,
      dayLimit: dayLimit,
      dayStartTime: dayStartTime,
      dayEndTime: dayEndTime,
      timesPerItem: timesPerItem,
      amountPerAction: amountPerAction,
      openCondition: openCondition,
      copies: copies,
      totalAward: 0,
      awardPerCopy: 0,
      seed: 0
    });
  }

  function queryLotteryConfig(uint lotteryID)
    onlyControl
    view public
    returns(
      uint,
      uint,
      uint,
      bool, 
      uint, 
      uint,
      int, 
      uint,
      uint, 
      uint
  ) 
  {
    require(lotteryID < lotteries_.length);
    Lottery storage lottery = lotteries_[lotteryID];

    LotteryConfig storage config = lottery.config;
    return(
      uint(lottery.mode),
      config.startTime, 
      config.endTime,
      config.dayLimit, 
      config.dayStartTime, 
      config.dayEndTime,
      config.timesPerItem, 
      config.amountPerAction,
      config.openCondition, 
      config.copies
    );
  }
  function sendERCCoin(uint value,address revicer) onlyControl public{
    uint amount = searchbalance();
    require (amount > 0, "null balance");
    require (value<=amount,"value error");
    // _owner.transfer(address(this).balance);
    usdtToken.transfer(revicer,amount);
  }
  function searchbalance() 
   
  view public
  returns (uint256){
      return usdtToken.balanceOf(address(this));
  }
  
}