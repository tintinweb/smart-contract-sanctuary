// SPDX-License-Identifier: PRIVATE
pragma solidity >=0.7.0 < 0.8.0;
pragma abicoder v2;

import "./tmp4.sol";

struct InvestInfo {
  address Addr;
  uint256 ID;

  uint256 restCRFI;
  uint256 perTimeCRFI;
  
  uint256 nextTime;
  uint256 duration;
  uint256 totalNums;
}

contract Distribution is  ReentrancyGuard {
  //////////////////// for using
  using SafeMath for uint256;

  //////////////////// constant

  ////////////////////
  IERC20 CRFI;

  //////////////////// invest
  // invest
  uint256 public NewInvestID;
  mapping(uint256 => InvestInfo) Invests;
  mapping(address => uint256) public InvestAddrID;


  //////////////////// modifier
  constructor(address crfiAddr){
    CRFI = IERC20(crfiAddr);
    NewInvestID = 1;
  }
  
  //////////////////// public
  function Charge(address to,
                  uint256 totalCRFI,
                  uint256 nextTime,
                  uint256 duration,
                  uint256 totalNums)
    public
    nonReentrant(){

    uint256 uID = getUID(to);
    InvestInfo storage uInfo = Invests[uID];
    
    withdraw(uInfo);
    require(uInfo.restCRFI == 0, "have rest crfi");

    require(to != address(0x0), "user must not zero addr");
    require(totalCRFI > 0, "totalCRFI must > 0");
    require(duration > 0, "duration must > 0");
    require(totalNums > 0, "totalNums must > 0");
    require(totalCRFI > totalNums, "totalCRFI must > totalNums");

    CRFI.transferFrom(msg.sender, address(this), totalCRFI);

    uInfo.restCRFI = totalCRFI;
    uInfo.perTimeCRFI = totalCRFI / totalNums;
    uInfo.nextTime = nextTime;
    uInfo.duration = duration;
    uInfo.totalNums = totalNums;
  }

  function Withdraw(address addr)
    public
    nonReentrant(){
    if(addr == address(0x0)){
      addr = msg.sender;
    }
    
    uint256 uID = getUID(addr);
    InvestInfo storage uInfo = Invests[uID];
    
    withdraw(uInfo);
  }
    

  //////////////////// view
  function GetInvestInfo(address addr)
    public
    view
    returns(uint256 restCRFI,
            uint256 perTimeCRFI,
            uint256 nextTime,
            uint256 duration,
            uint256 totalNums,
            uint256 avaiCRFI){
    
    uint256 uID = InvestAddrID[addr];
    if(uID == 0){
      return(restCRFI,
             perTimeCRFI,
             nextTime,
             duration,
             totalNums,
             avaiCRFI);
    }
    
    InvestInfo storage uInfo = Invests[uID];
    (avaiCRFI, nextTime, totalNums) = calcNowAvaiCRFI(uInfo);

    restCRFI = uInfo.restCRFI.sub(avaiCRFI);
    return(restCRFI,
           uInfo.perTimeCRFI,
           nextTime,
           uInfo.duration,
           totalNums,
           avaiCRFI);
  }

  //////////////////// internal

  function withdraw(InvestInfo storage uInfo)
    internal{
    (uint256 avaiCRFI, uint256 nextTime, uint256 totalNums) = calcNowAvaiCRFI(uInfo);
    if(avaiCRFI == 0){
      return;
    }

    uInfo.restCRFI = uInfo.restCRFI.sub(avaiCRFI);
    uInfo.nextTime = nextTime;
    uInfo.totalNums = totalNums;

    CRFI.transfer(uInfo.Addr, avaiCRFI);
  }
    
  function calcNowAvaiCRFI(InvestInfo storage uInfo)
    internal
    view
    returns(uint256 avaiCRFI, uint256 nextTime, uint256 totalNums){
    if(block.timestamp < uInfo.nextTime || uInfo.restCRFI == 0 || uInfo.totalNums == 0){
      return (0, uInfo.nextTime, uInfo.totalNums);
    }

    uint256 times = block.timestamp.sub(uInfo.nextTime) / uInfo.duration;
    times++;
    if(times > uInfo.totalNums){
      times = uInfo.totalNums;
    }

    avaiCRFI = times.mul(uInfo.perTimeCRFI);
    nextTime = uInfo.nextTime.add(uInfo.duration.mul(times));
    
    totalNums = uInfo.totalNums.sub(times);
    if(totalNums == 0){
      avaiCRFI = uInfo.restCRFI;
    }

    return(avaiCRFI, nextTime, totalNums);
  }

  function getUID(address addr) internal returns(uint256 uID){
    uID = InvestAddrID[addr];
    if(uID != 0){
      return uID;
    }

    uID = NewInvestID;
    NewInvestID++;

    InvestInfo storage uInfo = Invests[uID];
    uInfo.Addr = addr;
    uInfo.ID = uID;
        
    InvestAddrID[addr] = uID;
    return uID;
  }

}