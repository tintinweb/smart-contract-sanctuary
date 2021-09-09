// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./SafeMath.sol";
import "./Ownable.sol";

import "./CycleSign.sol";
import "./Deposit.sol";
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
contract Staking is Ownable,CycleSign,Deposit,Extract,Withdraw{
    using SafeMath for uint256;
    event GrantProfit(uint _depositId,uint _partId,uint _profit,uint userBalance,uint partBalance);
    
    
    
    function deposit (uint _cycleId,uint _amount,uint _timeLen) external  existTimeLen(_timeLen) existCycle(_cycleId){
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
    function expectSendCount() public view returns(uint){
        uint timeLen;
        uint count = 0;
        for(uint i=0;i<DepositList.length;i++){
            timeLen = DepositList[i].endTime - DepositList[i].startTime;
            timeLen = timeLen/monLen;
            for(uint s=0;s<timeLen;s++){
                count = count.add(DepositList[i].amount*rates[s]*signProfitInfo[DepositList[i].id].multiple/decimals/decimals);
            }
        }
        return count;
    }

    function computStakingProfit(uint _depositId) public view returns(uint){
        uint profit = 0;
        uint curTime;
        if(block.timestamp >= signDeposit[_depositId].endTime){
            curTime = signDeposit[_depositId].endTime;
        }else{
            curTime = block.timestamp;
        }
        uint finishLen = signDeposit[_depositId].lastExtractTime - signDeposit[_depositId].startTime;
        finishLen = finishLen/monLen;

        uint startComputTime = signDeposit[_depositId].lastExtractTime;
        uint monNum;
        uint curMonDays;
        for(uint i=0;i<signProfitInfo[_depositId].rateList.length;i++){
            if(finishLen <= i && i*monLen+monLen+signDeposit[_depositId].startTime <= curTime){
                // 利率 倍数
                // 当月每天都收益
                // signProfitInfo[_depositId].rateList[i]*signProfitInfo[_depositId].multiple*signProfitInfo[_depositId].amount*dayLen/monLen/decimals/decimals;
                monNum = i - finishLen + 1;
                if(curTime >= signDeposit[_depositId].startTime + finishLen*monLen + monNum*monLen){
                    curMonDays = signDeposit[_depositId].startTime + finishLen*monLen + monNum*monLen - startComputTime;
                }else{
                    curMonDays = curTime - startComputTime;
                }
               
                profit = profit.add(computMonProfit(_depositId,i,curMonDays));
                startComputTime = signDeposit[_depositId].startTime + finishLen*monLen + monNum*monLen;
            }
        }
        return profit;
    }
    function computMonProfit(uint _depositId,uint _index,uint _curMonDays) public view returns(uint){
        // signProfitInfo[_depositId].rateList[i]*signProfitInfo[_depositId].multiple*signProfitInfo[_depositId].amount*curMonDays/monLen/decimals/decimals
        uint share = signProfitInfo[_depositId].rateList[_index]*signProfitInfo[_depositId].multiple;
        share = share*signProfitInfo[_depositId].amount*_curMonDays;
        share = share/monLen/decimals/decimals;
        return share;
    }
    function extractionProfit(uint _cycleId,uint _depositId) external isExpire(_depositId) existCycle(_cycleId){
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
        
    }
    function extractionCapital(uint _cycleId,uint _depositId) external checkUser(_depositId) existCycle(_cycleId){
        require(!signDeposit[_depositId].extractStatu);
       /*  signDeposit[_depositId].extractStatu = true;
        DepositList[_depositId].extractStatu = true; */
        if(block.timestamp >= signDeposit[_depositId].endTime){
            _safeExtraction(msg.sender,signCycle[_cycleId].inAddress,signDeposit[_depositId].amount);
            insertExtractRecord(_cycleId,signDeposit[_depositId].amount,signCycle[_cycleId].inAddress);
        }else{
            uint _amount = signDeposit[_depositId].amount*signProfitInfo[_depositId].punish/decimals;
            _safeExtraction(msg.sender,signCycle[_cycleId].inAddress,_amount);
            insertExtractRecord(_cycleId,_amount,signCycle[_cycleId].inAddress);
        }
   /*      // 减少当前用户该理财产品的staking数
        UserStakingCount[msg.sender][_cycleId] = UserStakingCount[msg.sender][_cycleId].sub(signDeposit[_depositId].amount);
        // 减少当前理财产品总staking数
        totalStakingCount[_cycleId] = totalStakingCount[_cycleId].sub(signDeposit[_depositId].amount); */
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