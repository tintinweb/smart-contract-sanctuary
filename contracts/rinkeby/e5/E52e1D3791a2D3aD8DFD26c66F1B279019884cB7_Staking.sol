// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./SafeMath.sol";
import "./Ownable.sol";

import "./CycleSign.sol";
import "./Deposit.sol";
import "./Send.sol";
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
contract Staking is Ownable,CycleSign,Deposit,Send,Withdraw{
    using SafeMath for uint256;
    event GrantProfit(uint _depositId,uint _partId,uint _profit,uint userBalance,uint partBalance);
    
    function grant() public onlyOwner{
        for(uint i = 0; i < DepositList.length; i++){
            passDays(DepositList[i].id);
        }
    }
    function passDays(uint _depositId) private{
        // uint partId = getCurPart(block.timestamp);
        uint passTimeLen = block.timestamp - signDeposit[_depositId].lastGrantTime;
        uint grantNum = passTimeLen / dayLen;
        for(uint i=1;i <= grantNum;i++){
            uint partDayCount;
            partDayCount = signCyclePart[getCurPart(signDeposit[_depositId].lastGrantTime + dayLen)].endTime - signDeposit[_depositId].lastGrantTime - dayLen;
            partDayCount = partDayCount/dayLen+1;
            uint avgAmount;
            // 这一次发放在该阶段这一天要发的总量
            avgAmount = signCyclePart[getCurPart(signDeposit[_depositId].lastGrantTime + dayLen)].balance/partDayCount;
            
            // 该阶段这一天开始时间
            uint dayStartTime;
            dayStartTime = signDeposit[_depositId].lastGrantTime + dayLen - signCyclePart[getCurPart(signDeposit[_depositId].lastGrantTime + dayLen)].startTime;
            dayStartTime = dayStartTime / dayLen;
            dayStartTime = dayStartTime*dayLen + signCyclePart[getCurPart(signDeposit[_depositId].lastGrantTime + dayLen)].startTime;
            uint profit;
            profit = avgAmount*daySendAmount(dayStartTime)/dayGainProfit(_depositId,dayStartTime);
            grantProfit(_depositId,getCurPart(signDeposit[_depositId].lastGrantTime + dayLen),profit,signDeposit[_depositId].lastGrantTime + dayLen);
        }   
    }
    function grantProfit(uint _depositId,uint _partId,uint _profit,uint _grantTime) private {
        uint profit;
        if(_grantTime == signDeposit[_depositId].createTime + signCycleShare[signDeposit[_depositId].shareId].timeLen){
            profit = signDeposit[_depositId].amount + _profit;
            UserStakingCount[signDeposit[_depositId].Depositer][signDeposit[_depositId].cycleId] = UserStakingCount[signDeposit[_depositId].Depositer][signDeposit[_depositId].cycleId].sub(signDeposit[_depositId].amount);
            totalStakingCount[signDeposit[_depositId].cycleId] = totalStakingCount[signDeposit[_depositId].cycleId].sub(signDeposit[_depositId].amount);
            signDeposit[_depositId].SendFinash = true;
            signDeposit[_depositId].extractLastTime = _grantTime;
        }else{
            profit = _profit;
        }
        UserBelongCount[signDeposit[_depositId].Depositer][signDeposit[_depositId].cycleId] = UserBelongCount[signDeposit[_depositId].Depositer][signDeposit[_depositId].cycleId].add(profit);
        signCyclePart[_partId].balance = signCyclePart[_partId].balance.sub(_profit);
        signDeposit[_depositId].lastGrantTime = _grantTime;
        emit GrantProfit(_depositId,_partId,_profit,UserBelongCount[signDeposit[_depositId].Depositer][signDeposit[_depositId].cycleId],signCyclePart[_partId].balance);
    }
    function deposit (uint _cycleId,uint _shareId,uint _amount) external existCycle(_cycleId) returns (uint){
        
        // FromContract formPlay = FromContract(signCycle[_cycleId].inAddress);
        // formPlay.transferFrom(msg.sender,address(this),_amount);
        safeDeposit(signCycle[_cycleId].inAddress,_amount);
        UserStakingCount[msg.sender][_cycleId] = UserStakingCount[msg.sender][_cycleId].add(_amount);
        totalStakingCount[_cycleId] = totalStakingCount[_cycleId].add(_amount);
        insertDepositRecord(msg.sender,_amount,_cycleId,_shareId);

        // ToContract toPlay = ToContract(signExchangePair[_pairid].to);
    }
    function safeDeposit(address _in,uint _amount) private {
        FromContract formPlay = FromContract(_in);
        uint oldFromBalance = formPlay.balanceOf(address(this));
        uint oldSenderFromBalance = formPlay.balanceOf(msg.sender);
        formPlay.transferFrom(msg.sender,address(this),_amount);
        uint newFromBalance = formPlay.balanceOf(address(this));
        uint newSenderFromBalance = formPlay.balanceOf(msg.sender);
        require(newFromBalance == oldFromBalance + _amount);
        require(oldSenderFromBalance == newSenderFromBalance + _amount);
    }
    /* function withdraw (address _withdrawer,uint _amount,uint _cycleId) external onlyOwner existCycle(_cycleId) returns (uint){

    } */

    function extraction(uint _cycleId) external returns (uint){
        safeExtraction(signCycle[_cycleId].outAddress,UserBelongCount[msg.sender][_cycleId]);
        UserBelongCount[msg.sender][_cycleId] = 0;
        insertSendRecord(_cycleId,UserBelongCount[msg.sender][_cycleId]);
    }
    function safeExtraction(address _out,uint _amount) private {
        ToContract toPlay = ToContract(_out);
        uint _toAmount = _amount;
        uint oldToBalance = toPlay.balanceOf(address(this));
        uint oldSenderToBalance = toPlay.balanceOf(msg.sender);
        toPlay.transfer(msg.sender,_toAmount);
        uint newSenderToBalance = toPlay.balanceOf(msg.sender);
        uint newToBalance = toPlay.balanceOf(address(this));
        require(oldToBalance == newToBalance + _toAmount);
        require(newSenderToBalance == oldSenderToBalance + _toAmount);
    }
    /* function computeProfit(uint _cycleId) external view returns (uint){
        uint profit = 0;
        if(UserGainCount[msg.sender][_cycleId] == 0){
            for(uint i = 0; i < DepositList.length; i++){
                
            }
        }else{

        }
        uint result = profit + UserStakingCount[msg.sender][_cycleId];
        return result;
    } */
    
    
    /* function passDepositComputProfit(uint _depositId,uint _cycleId,uint _shareId) public view returns (uint){
        // signCycleShare[_shareId]
        // signCycle[_cycleId]
        // signDeposit[_depositId]
        // CyclePartList
        

    } */
}