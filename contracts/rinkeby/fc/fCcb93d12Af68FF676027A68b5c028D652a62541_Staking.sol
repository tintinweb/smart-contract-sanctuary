// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./SafeMath.sol";
import "./Deposit.sol";
// import "./Withdraw.sol";

interface FromContract{
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function decimals() external pure returns (uint8);
    function approve(address spender, uint value) external returns (bool);
}
interface ToContract{
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function decimals() external pure returns (uint8);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}
contract Staking is Deposit{
    using SafeMath for uint256;
    event AddWithdraw(address _withdrawer, uint _amount,address _coin,uint _withdrawTime);
    event AddExtract(address _receiver,uint _amount,uint _sendTime,uint _cycleId,address _coin);
    modifier checkUser (uint _depositId) {
      require(msg.sender == signDeposit[_depositId].Depositer);
      _;
    }
    
    
    function deposit (uint _cycleId,uint _amount,uint _timeLen) external exitTimeLen(_timeLen) existCycle(_cycleId){
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


    function computStakingProfit(uint _id,uint _time)  public view returns (uint,uint){
        uint profit = 0;
        uint passMonths = passMonthCount(_id,_time);
        uint test;
        uint num;
        uint monthSecord;
        uint computEndTime = signDeposit[_id].lastExtractTime;
        for(uint i=1;i<=passMonths;i++){
            num = signProfitInfo[_id].amount*signRatePath[signProfitInfo[_id].mountCount][computEndTime/100]*signProfitInfo[_id].multiple;
            num = num/getDaysInMonth(computEndTime/100%100,computEndTime/10000)/decimals;
            if(i==passMonths){
                monthSecord = getYmd(_time) - computEndTime%100;

                test = getYmd(_time)*10**10+computEndTime%100*10**10;
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
        return (profit,test);
    }
    function passMonthCount(uint _id,uint _time) public view returns (uint passMonths) {
        uint curDate;
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
    function extractionProfit(uint _cycleId,uint _depositId,uint _timestamp) external existCycle(_cycleId){
        require(!signDeposit[_depositId].extractStatu);
        uint curTime = getYmd(_timestamp);
        if(curTime >= signDeposit[_depositId].endTime){
            signDeposit[_depositId].lastExtractTime = signDeposit[_depositId].endTime;
            DepositList[_depositId].lastExtractTime = signDeposit[_depositId].endTime;
        }else{
            if(curTime%100 < 2 && curTime/100%100 < 2){
                curTime = curTime - 10000;
                curTime = curTime/10000*10000+1200;
                curTime = curTime + getDaysInMonth(12,curTime/10000);
            }else if(curTime%100 < 2){
                curTime = curTime - 100;
                curTime = curTime/100 + getDaysInMonth(curTime/100%100,curTime/10000);
            }
            signDeposit[_depositId].lastExtractTime = curTime;
            DepositList[_depositId].lastExtractTime = curTime;
        }
        // uint profit = computStakingProfit(_depositId,_timestamp);
        uint profit = 0;
        signProfitInfo[_depositId].extract = signProfitInfo[_depositId].extract.add(profit);
        // 发放收益
        _safeExtraction(msg.sender,signCycle[_cycleId].outAddress,profit);
        emit AddExtract(msg.sender,profit,block.timestamp,_cycleId,signCycle[_cycleId].outAddress);
        // insertExtractRecord(_cycleId,profit,signCycle[_cycleId].outAddress);
        // 记录当前理财产品提取总数
        UserGainCount[msg.sender][_cycleId] = UserGainCount[msg.sender][_cycleId].add(profit);
        totalExtractCount[_cycleId] = totalExtractCount[_cycleId].add(profit);
        
    }
    function extractionCapital(uint _cycleId,uint _depositId,uint _timestamp) external checkUser(_depositId) existCycle(_cycleId){
        require(!signDeposit[_depositId].extractStatu);
        uint _amount;
        if(getYmd(_timestamp) >= signDeposit[_depositId].endTime){
            _amount = signDeposit[_depositId].amount;
        }else{
            _amount = signDeposit[_depositId].amount*signProfitInfo[_depositId].punish/decimals;
        }
        _safeExtraction(msg.sender,signCycle[_cycleId].inAddress,_amount);
        emit AddExtract(msg.sender,_amount,block.timestamp,_cycleId,signCycle[_cycleId].inAddress);
        // 减少当前用户该理财产品的staking数
        UserStakingCount[msg.sender][_cycleId] = UserStakingCount[msg.sender][_cycleId].sub(signDeposit[_depositId].amount);
        // 减少当前理财产品总staking数
        totalStakingCount[_cycleId] = totalStakingCount[_cycleId].sub(signDeposit[_depositId].amount);
        signDeposit[_depositId].extractStatu = true;
        DepositList[_depositId].extractStatu = true;
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