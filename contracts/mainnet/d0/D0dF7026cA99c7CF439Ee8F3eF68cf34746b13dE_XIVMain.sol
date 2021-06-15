// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./XIVInterface.sol";


contract XIVMain is Ownable,ReentrancyGuard{
    
    using SafeMath for uint256;
    
    address public databaseContractAddress=0x09eD6f016178cF5Aed0bda43A7131B775042a3c6;
    
    function stakeTokens(uint256 amount) external nonReentrant{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        require(amount>=dContract.getMinLPvalue(),"Please enter more amount.");
        require((dContract.getTokenStakedAmount().add(amount))<=dContract.getMaxLPLimit(),"Max limit has reached.");
        
        dContract.transferFromTokens(dContract.getXIVTokenContractAddress(),msg.sender,databaseContractAddress,amount);
        
        uint256 currentTimeStamp=block.timestamp;
        
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
     function unStakeTokens(uint256 amount) external nonReentrant{
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