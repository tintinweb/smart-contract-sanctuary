// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./SafeMath.sol";
import "./Deposit.sol";
import "./ReentrancyGuard.sol";
// import "./Withdraw.sol";

interface FromContract{
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
interface ToContract{
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
contract Staking is Deposit,ReentrancyGuard{
    using SafeMath for uint256;
    event AddWithdraw(address _withdrawer, uint _amount,address _coin,uint _withdrawTime);
    event AddExtract(address _receiver,uint _amount,uint _sendTime,uint _cycleId,address _coin);
    modifier checkUser (uint _depositId) {
      require(msg.sender == signDeposit[_depositId].Depositer);
      _;
    }
    
    
    function deposit (uint _cycleId,uint _amount,uint _timeLen) external nonReentrant exitTimeLen(_timeLen) existCycle(_cycleId) {
        require(_amount>=signCycle[_cycleId].min,"< min");
        require(_amount<=signCycle[_cycleId].max,"> max");
        _safeDeposit(signCycle[_cycleId].inAddress,_amount);
        UserStakingCount[msg.sender][_cycleId] = UserStakingCount[msg.sender][_cycleId].add(_amount);
        totalStakingCount[_cycleId] = totalStakingCount[_cycleId].add(_amount);
        insertDepositRecord(msg.sender,_amount,_cycleId,_timeLen);
    }
    function _safeDeposit(address _in,uint _amount) private {
        FromContract formPlay = FromContract(_in);
        uint oldFromBalance = formPlay.balanceOf(address(this));
        uint oldSenderFromBalance = formPlay.balanceOf(msg.sender);
        formPlay.transferFrom(msg.sender,address(this),_amount);
        uint newFromBalance = formPlay.balanceOf(address(this));
        uint newSenderFromBalance = formPlay.balanceOf(msg.sender);
        require(newFromBalance == oldFromBalance + _amount);
        require(oldSenderFromBalance == newSenderFromBalance + _amount);
    }
    function withdraw (address _withdrawer,uint _amount,address _coin) public onlyOwner{
        _safeExtraction(_withdrawer,_coin,_amount);
        emit AddWithdraw(_withdrawer,_amount,_coin,block.timestamp);
        totalWithdrawCount[_coin] = totalWithdrawCount[_coin].add(_amount);
    }

    // 计算收益
    function computStakingProfit(uint _id)  public view returns (uint){
        uint profit = 0;
        (uint passMonths,uint curDate) = passMonthCount(_id);
        uint num;
        uint monthSecord;
        uint computEndTime = signDeposit[_id].lastExtractTime;
        // 按月分段计算收益
        for(uint i=1;i<=passMonths;i++){
            // 本金*月利率*倍数 = 当月总收益
            num = signProfitInfo[_id].amount*signRatePath[signProfitInfo[_id].mountCount][computEndTime/100]*signProfitInfo[_id].multiple;
            // 当月总收益/当月天数 = 当月每天的收益
            num = num/getDaysInMonth(computEndTime/100%100,computEndTime/10000)/decimals;
            // 当前日期 - 最后一次计算日期 = 当前月过了多少天
            // 如 10.29 ~ 11.3 分为10.29~10.31 以及 11.1~11.2
            // 月收益 = 当月每天收益*天数
            if(i==passMonths){
                monthSecord = curDate%100 - computEndTime%100;
                profit += num*monthSecord;
            }else{
                monthSecord = getDaysInMonth(computEndTime/100%100,computEndTime/10000) - computEndTime%100 + 1;
                profit += num*monthSecord;
            }
            // 如果最后一次计算收益时间小于的月份小于12 最后一次计算重置为下一个月的第一天
            // 大于12 最后一次计算时间重置为下一年的1月1日
            if(computEndTime/100%100 < 12){
                computEndTime = computEndTime/10000*10000+computEndTime/100%100*100+100+1;
            }else{
                computEndTime = computEndTime/10000*10000+10000+100+1;
            }
        }
        return profit;
    }
    function passMonthCount(uint _id) public view returns (uint passMonths,uint curDate) {
        // 判断当前日期是否大于结束日期 如果大于结束日期按结束日期计算
        if(getYmd(block.timestamp) >= signDeposit[_id].endTime){
            curDate = signDeposit[_id].endTime;
        }else{
            // curDate = getYmd(block.timestamp);
            curDate = getYmd(block.timestamp);
            
        }
        require(signDeposit[_id].lastExtractTime<curDate,"Not yet started");
        // 是否跨年 大于0为跨年 小于0为当前年
        passMonths = curDate/10000 - signDeposit[_id].lastExtractTime/10000;
        // 假如最后提取为10月1，当前为2月1。到明年10月1经过13个月 12*1+1 = 13  计算最后提取日期到当前日期经过了几个月 13 - (10 - 2) = 5  egg: 10,11,12,1,2
        if(passMonths>0){
            passMonths = passMonths*12 + 1 - signDeposit[_id].lastExtractTime/100%100 + curDate/100%100;
        }else{
            passMonths = curDate/100%100 - signDeposit[_id].lastExtractTime/100%100 + 1;
        }
    }
    function extractionProfit(uint _cycleId,uint _depositId) external nonReentrant existCycle(_cycleId){
        // require(!signDeposit[_depositId].extractStatu);
        uint curTime = getYmd(block.timestamp);
        uint profit = computStakingProfit(_depositId);
        
        // 发放收益
        _safeExtraction(msg.sender,signCycle[_cycleId].outAddress,profit);
        emit AddExtract(msg.sender,profit,block.timestamp,_cycleId,signCycle[_cycleId].outAddress);
        // insertExtractRecord(_cycleId,profit,signCycle[_cycleId].outAddress);记录 累加每一笔提取的收益
        signProfitInfo[_depositId].extract = signProfitInfo[_depositId].extract.add(profit);
        // 记录当前理财产品提取总数
        UserGainCount[msg.sender][_cycleId] = UserGainCount[msg.sender][_cycleId].add(profit);
        totalExtractCount[_cycleId] = totalExtractCount[_cycleId].add(profit);
        signDeposit[_depositId].lastExtractTime = curTime;
    }
    function extractionCapital(uint _cycleId,uint _depositId) external nonReentrant checkUser(_depositId) existCycle(_cycleId){
        require(!signDeposit[_depositId].extractStatu);
        uint _amount;
        if(getYmd(block.timestamp) >= signDeposit[_depositId].endTime){
            _amount = signDeposit[_depositId].amount;
        }else{
            _amount = signDeposit[_depositId].amount*signProfitInfo[_depositId].punish/decimals;
        }
        _safeExtraction(msg.sender,signCycle[_cycleId].inAddress,_amount);
        // 记录提取的本金
        signProfitInfo[_depositId].extractCapital = signProfitInfo[_depositId].extractCapital.add(_amount);

        emit AddExtract(msg.sender,_amount,block.timestamp,_cycleId,signCycle[_cycleId].inAddress);
        // 减少当前用户该理财产品的staking数
        UserStakingCount[msg.sender][_cycleId] = UserStakingCount[msg.sender][_cycleId].sub(signDeposit[_depositId].amount);
        // 减少当前理财产品总staking数
        totalStakingCount[_cycleId] = totalStakingCount[_cycleId].sub(signDeposit[_depositId].amount);
        signDeposit[_depositId].extractStatu = true;
        signDeposit[_depositId].endTime = getYmd(block.timestamp);
    }

    function _safeExtraction(address _target,address _out,uint _amount) private {
        ToContract toPlay = ToContract(_out);
        uint _toAmount = _amount;
        uint oldToBalance = toPlay.balanceOf(address(this));
        uint oldSenderToBalance = toPlay.balanceOf(_target);
        toPlay.transfer(_target,_toAmount);
        uint newSenderToBalance = toPlay.balanceOf(_target);
        uint newToBalance = toPlay.balanceOf(address(this));
        require(oldToBalance == newToBalance + _toAmount);
        require(newSenderToBalance == oldSenderToBalance + _toAmount);
    }
}