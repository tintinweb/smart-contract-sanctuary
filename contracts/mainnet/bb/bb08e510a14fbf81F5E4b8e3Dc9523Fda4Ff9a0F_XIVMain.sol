// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./XIVInterface.sol";


contract XIVMain is Ownable{
    
    using SafeMath for uint256;
    address[] tempArray;
    
    address public databaseContractAddress=0x18464e4584759A50CE9FC58eA5997F8B0D1EA1d8;
    
    XIVDatabaseLib.IndexCoin[] tempObjectArray;
    
    function stakeTokens(uint256 amount) external{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        Token tokenObj = Token(dContract.getXIVTokenContractAddress());
        require(amount>=dContract.getMinLPvalue(),"Please enter more amount.");
        //check if user has balance
        require(tokenObj.balanceOf(msg.sender) >= amount, "You don't have enough XIV balance");
        //check if user has provided allowance
        require(tokenObj.allowance(msg.sender,databaseContractAddress) >= amount, 
        "Please allow smart contract to spend on your behalf");
        dContract.transferFromTokens(dContract.getXIVTokenContractAddress(),msg.sender,databaseContractAddress,amount);
        
        uint256 currentTimeStamp=block.timestamp;
        XIVDatabaseLib.StakingInfo memory sInfo= XIVDatabaseLib.StakingInfo({
            investmentId:dContract.getInvestmentId(),
            stakeAmount:amount
        });
        dContract.updateStakingInfoMapping(msg.sender,sInfo);
        dContract.updateInvestmentId(dContract.getInvestmentId().add(1));
        if(!dContract.getIsStakeMapping(msg.sender)){
            dContract.updateUserStakedAddress(msg.sender);
            dContract.updateIsStakeMapping(msg.sender,true);
        }
        dContract.updateTokensStaked(msg.sender,dContract.getTokensStaked(msg.sender).add(amount));
        dContract.updateActualAmountStakedByUser(msg.sender,dContract.getActualAmountStakedByUser(msg.sender).add(amount));
        dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().add(amount));
        dContract.updateTotalTransactions(dContract.getTotalTransactions().add(amount));
        if(dContract.getLockingPeriodForLPMapping(msg.sender).lockedTimeStamp>currentTimeStamp){
            dContract.updateLockingPeriodForLPMapping(msg.sender,(dContract.getLockingPeriodForLPMapping(msg.sender).amountLocked).add(amount),
                                                        dContract.getLockingPeriodForLPMapping(msg.sender).lockedTimeStamp);
        }else{
            dContract.updateLockingPeriodForLPMapping(msg.sender,amount,currentTimeStamp.add(30 days));
        }
        dContract.emitLPEvent(0,msg.sender,amount,currentTimeStamp);
    }
     function unStakeTokens(uint256 amount) external{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 currentTimeStamp=block.timestamp;
        if(dContract.getLockingPeriodForLPMapping(msg.sender).lockedTimeStamp>currentTimeStamp){
            require(dContract.getTokensStaked(msg.sender).sub(dContract.getLockingPeriodForLPMapping(msg.sender).amountLocked) >= amount, "You can not retrive LP token with this amount");
        }else{
            require(dContract.getTokensStaked(msg.sender)>=amount, "You can not retrive LP token with this amount");
        }
        dContract.transferTokens(dContract.getXIVTokenContractAddress(),msg.sender,amount);
        dContract.updateTokensStaked(msg.sender,dContract.getTokensStaked(msg.sender).sub(amount));
        if(amount>dContract.getActualAmountStakedByUser(msg.sender)){
            dContract.updateActualAmountStakedByUser(msg.sender,0);
        }else{
            dContract.updateActualAmountStakedByUser(msg.sender,dContract.getActualAmountStakedByUser(msg.sender).sub(amount));
        }
        dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().sub(amount));
        dContract.emitLPEvent(1,msg.sender,amount,currentTimeStamp);
    }
    
    function updateDatabaseAddress(address _databaseContractAddress) external onlyOwner{
        databaseContractAddress=_databaseContractAddress;
    }
    
}