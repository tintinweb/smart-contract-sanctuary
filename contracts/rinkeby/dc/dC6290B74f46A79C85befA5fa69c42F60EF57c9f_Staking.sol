// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./SafeMath.sol";
import "./Extract.sol";
import "./Withdraw.sol";

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
contract Staking is Extract,Withdraw{
    using SafeMath for uint256;
    event GrantProfit(uint _depositId,uint _partId,uint _profit,uint userBalance,uint partBalance);
    
    
    
    function deposit (uint _cycleId,uint _amount,uint _timeLen) external existCycle(_cycleId){
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
        insertWithdrawRecord(_withdrawer,_amount,_coin);
        totalWithdrawCount[_coin] = totalWithdrawCount[_coin].add(_amount);
    }


    function computStakingProfit(uint _id,uint _time)  public view returns (uint profit){
        uint passMonths = passMonthCount(_id,_time);
        uint computYear = signDeposit[_id].lastExtractTime/10000;
        uint computMonth = signDeposit[_id].lastExtractTime/100;
        uint num;
        uint monthSecord;
        uint computEndTime = signDeposit[_id].lastExtractTime;
        for(uint8 i=0;i<=passMonths;i++){
            if(computMonth >12){
                computYear  = computYear + 1;
                computMonth = 1;
            }
            num = signProfitInfo[_id].amount*signRatePath[signProfitInfo[_id].mountCount][computYear*100+computMonth]*signProfitInfo[_id].multiple;
            num = num/decimals/decimals;
            num = num*dayLen/getDaysInMonth(computMonth,computYear)*60*60*24;
            monthSecord = getDaysInMonth(computMonth,computYear) - computEndTime%100;
            monthSecord = monthSecord*60*60*24/dayLen;

            profit += num*monthSecord;
            if(computMonth < 12){
                computEndTime = computYear*10000+computMonth*100+100;
            }else{
                computEndTime = computYear*10000+10000+100;
            }
            
        }


    }
    function passMonthCount(uint _id,uint _time) public view returns (uint passMonths) {
        uint curDate;
        if(getYmd(_time) >= signDeposit[_id].endTime){
            curDate = signDeposit[_id].endTime;
        }else{
            // curDate = getYmd(block.timestamp);
            curDate = getYmd(_time);
            
        }
        uint passTime = curDate - signDeposit[_id].lastExtractTime;
        passMonths = passTime/100%100+passTime*12/10000;
    }
    /* function test() public view returns (uint) {

    } */
    /* function extractionProfit(uint _cycleId,uint _depositId) external isExpire(_depositId) existCycle(_cycleId){
        uint passTime;
        if(block.timestamp >= signDeposit[_depositId].endTime){
            signDeposit[_depositId].lastExtractTime = signDeposit[_depositId].endTime;
            DepositList[_depositId].lastExtractTime = signDeposit[_depositId].endTime;
        }else{
            passTime = block.timestamp - signDeposit[_depositId].startTime;
            passTime = passTime/dayLen*dayLen + signDeposit[_depositId].startTime;
            signDeposit[_depositId].lastExtractTime = passTime;
            DepositList[_depositId].lastExtractTime = passTime;
        }
        signProfitInfo[_depositId].extract = signProfitInfo[_depositId].extract.add(computStakingProfit(_depositId));
        // 发放收益
        _safeExtraction(msg.sender,signCycle[_cycleId].outAddress,computStakingProfit(_depositId));
        insertExtractRecord(_cycleId,computStakingProfit(_depositId),signCycle[_cycleId].outAddress);
        // 记录当前理财产品提取总数
        UserGainCount[msg.sender][_cycleId] = UserGainCount[msg.sender][_cycleId].add(computStakingProfit(_depositId));
        totalExtractCount[_cycleId] = totalExtractCount[_cycleId].add(computStakingProfit(_depositId));
        
    } */
    /* function extractionCapital(uint _cycleId,uint _depositId) external checkUser(_depositId) existCycle(_cycleId){
        require(!signDeposit[_depositId].extractStatu);
        signDeposit[_depositId].extractStatu = true;
        DepositList[_depositId].extractStatu = true;
        if(block.timestamp >= signDeposit[_depositId].endTime){
            _safeExtraction(msg.sender,signCycle[_cycleId].inAddress,signDeposit[_depositId].amount);
            insertExtractRecord(_cycleId,signDeposit[_depositId].amount,signCycle[_cycleId].inAddress);
        }else{
            uint _amount = signDeposit[_depositId].amount*signProfitInfo[_depositId].punish/decimals;
            _safeExtraction(msg.sender,signCycle[_cycleId].inAddress,_amount);
            insertExtractRecord(_cycleId,_amount,signCycle[_cycleId].inAddress);
        }
        // 减少当前用户该理财产品的staking数
        UserStakingCount[msg.sender][_cycleId] = UserStakingCount[msg.sender][_cycleId].sub(signDeposit[_depositId].amount);
        // 减少当前理财产品总staking数
        totalStakingCount[_cycleId] = totalStakingCount[_cycleId].sub(signDeposit[_depositId].amount);
    } */

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