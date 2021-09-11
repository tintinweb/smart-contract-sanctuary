// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Datetime.sol";
contract Test is Datetime{
    uint decimals = 10 ** 18;
    uint dayLen = 60*60*24;
    uint[] public tmpID;
    
    mapping(uint => mapping(uint => uint)) public signRatePath;
    struct DepositRecord {
      uint id;
      address Depositer;
      uint amount;
      uint cycleId;
      uint startTime;
      uint endTime;
      uint lastExtractTime;
      bool extractStatu;
    }
    struct ProfitInfo {
      uint id;
      uint multiple;
      uint punish;
      uint amount;
      uint extract;
      uint mountCount;
      uint createTime;
    }
    mapping(address => mapping(uint => uint)) public UserStakingCount;
    mapping(address => mapping(uint => uint)) public UserGainCount;
    mapping(uint => uint) public totalStakingCount;
    mapping(uint => uint) public totalExtractCount;
    mapping(uint => DepositRecord) public signDeposit;
    mapping(uint => ProfitInfo) public signProfitInfo;
    constructor () public {
        signRatePath[180][202109] = 1*10**16;
        signRatePath[180][202110] = 2*10**16;
        signRatePath[180][202111] = 3*10**16;
        DepositRecord memory record = DepositRecord(1,0x55959f0D5e1b7DC57fe4079e596b8BBafFF123B1,10000000000000000000000,1,20210912,20220311,20210912,false);
        signDeposit[1] = record;
        ProfitInfo memory info = ProfitInfo(1,1,900000000000000000,10000000000000000000000,0,180,20210912);
        signProfitInfo[1] = info;
    }


    function extractionProfit(uint _depositId,uint _cycleId,uint _timestamp) external{
        require(!signDeposit[_depositId].extractStatu);
        _aa(_depositId,getYmd(_timestamp));
        /* uint profit = computStakingProfit(_depositId,_timestamp);
        signProfitInfo[_depositId].extract += profit; */
        // 发放收益
        // 记录当前理财产品提取总数
       /*  UserGainCount[msg.sender][_cycleId] += profit;
        totalExtractCount[_cycleId] += profit; */
    }
    function _aa(uint _depositId,uint _date) private {
        signDeposit[_depositId].lastExtractTime = _date;
    }
    function extractionCapital(uint _cycleId,uint _depositId,uint _timestamp) external returns(bool){
        require(!signDeposit[_depositId].extractStatu);
        uint _amount;
        if(getYmd(_timestamp) >= signDeposit[_depositId].endTime){
            _amount = signDeposit[_depositId].amount;
        }else{
            _amount = signDeposit[_depositId].amount*signProfitInfo[_depositId].punish/decimals;
        }
        // 减少当前用户该理财产品的staking数
        UserStakingCount[msg.sender][_cycleId] -= signDeposit[_depositId].amount;
        // 减少当前理财产品总staking数
        totalStakingCount[_cycleId] -= signDeposit[_depositId].amount;
        signDeposit[_depositId].extractStatu = true;
        return signDeposit[_depositId].extractStatu;
    }
    function computStakingProfit(uint _id,uint _time)  public view returns (uint){
        uint profit = 0;
        (uint passMonths,uint curDate) = passMonthCount(_id,_time);
        uint num;
        uint monthSecord;
        uint computEndTime = signDeposit[_id].lastExtractTime;
        for(uint i=1;i<=passMonths;i++){
            num = signProfitInfo[_id].amount*signRatePath[signProfitInfo[_id].mountCount][computEndTime/100]*signProfitInfo[_id].multiple;
            num = num/getDaysInMonth(computEndTime/100%100,computEndTime/10000)/decimals;
            if(i==passMonths){
                monthSecord = curDate%100 - computEndTime%100;
                profit += num*monthSecord;
            }else{
                monthSecord = getDaysInMonth(computEndTime/100%100,computEndTime/10000) - computEndTime%100 + 1;
                profit += num*monthSecord;
            }            
            if(computEndTime/100%100 < 12){
                computEndTime = computEndTime/10000*10000+computEndTime/100%100*100+100+1;
            }else{
                computEndTime = computEndTime/10000*10000+10000+100+1;
            }
        }
        return profit;
    }
    function everyProfit(uint _id,uint computEndTime) public view returns (uint num) {
        num = signProfitInfo[_id].amount*signRatePath[signProfitInfo[_id].mountCount][computEndTime/100]*signProfitInfo[_id].multiple;
        num = num/getDaysInMonth(computEndTime/100%100,computEndTime/10000)/decimals;
    }
    function passMonthCount(uint _id,uint _time) public view returns (uint passMonths,uint curDate) {
        if(getYmd(_time) >= signDeposit[_id].endTime){
            curDate = signDeposit[_id].endTime;
        }else{
            // curDate = getYmd(block.timestamp);
            curDate = getYmd(_time);
            
        }
        require(signDeposit[_id].lastExtractTime<curDate);
        passMonths = curDate/10000 - signDeposit[_id].lastExtractTime/10000;
        if(passMonths>0){
            passMonths = 13 - signDeposit[_id].lastExtractTime/100%100 + curDate/100%100;
        }else{
            passMonths = curDate/100%100 - signDeposit[_id].lastExtractTime/100%100 + 1;
        }
    }

}