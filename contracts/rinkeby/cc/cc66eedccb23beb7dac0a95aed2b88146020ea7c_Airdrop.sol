// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";

interface IREKT { 
    function mint(address to, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Airdrop is Ownable { 
    using SafeMath for uint256;

    IREKT private REKT;
    Info[] public info;

    struct Info { 
        address userAddress;
        uint256 vesting;  
        uint256 rewardAmount;
        uint256 claimableReward; 
        bool rewardDistributed;
        bool active; 
    }  

    uint256 public rebaseIndex;
    uint256 public rebaseRate;
    uint256 public lastEpoch; 
    uint256 public epochLength; 
 
    
    constructor(address _tokenAddress, uint256 _rebaseIndex, uint256 _rebaseRate,  uint256 _epochLength ) Ownable() {
        REKT = IREKT(_tokenAddress);
        rebaseIndex =  _rebaseIndex;
        rebaseRate =  _rebaseRate ; 
        epochLength = _epochLength; 
    }  
 
 
    function claim() public { 
        uint256 index; 
        for(uint256 i = 0; i<info.length; i++){
            if(info[i].userAddress == msg.sender){
                index = i;
            } 
        }
        Info storage senderInfo = info[index]; 
        require(senderInfo.active, "Address is not active!");  
        uint256 claimableReward = senderInfo.claimableReward;
        REKT.mint(msg.sender, claimableReward); 
        senderInfo.claimableReward = 0;
        if(senderInfo.rewardDistributed == true){
            senderInfo.active = false;
        }
    }  


    function distribute () internal  {
        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].active == true && info[i].rewardDistributed == false) {
                uint256 r = info[i].rewardAmount.div(rebaseRate);
                uint256 d = r.div(rebaseIndex);
                info[i].claimableReward = info[i].claimableReward.add(d); 
                if(block.timestamp >= info[i].vesting){
                    info[i].claimableReward = info[i].claimableReward.add(info[i].rewardAmount);
                    info[i].rewardDistributed = true;
                }
            }
        }
    }


    function rebase() external onlyOwner  returns (bool){
        uint256 epoch = lastEpoch + epochLength;
        require(block.timestamp >= epoch, "Last epoch is active!");
        lastEpoch = block.timestamp; 
        distribute();
        return true; 
    }
 
 

    function status(address  _address) external view returns(Info memory) {  
        uint256 index; 
        for(uint256 i = 0; i<info.length; i++){
            if(info[i].userAddress == _address){
                index = i;
            } 
        }
        Info memory senderInfo = info[index];
        return (senderInfo);
    }  


    function setAccounts(Info[] memory _records) external onlyOwner { 
        for(uint256 i=0; i< _records.length; i++){
           uint256 timestamp = block.timestamp + _records[i].vesting;
            Info memory newInfo = Info({
                userAddress: _records[i].userAddress,
                vesting: timestamp,
                rewardAmount: _records[i].rewardAmount,
                claimableReward: 0,
                rewardDistributed: false,
                active: true
            });
            info.push(newInfo); 
        } 
    }

 
    function setRebaseIndex(uint256 _index) external  onlyOwner returns (bool){  
        rebaseIndex = _index;
        return true;
    }  

    function setRebaseRate(uint256 _rate) external  onlyOwner returns (bool){  
        rebaseRate = _rate;
        return true;
    }  

    function setEpochLength(uint256 _epochLength) external  onlyOwner returns (bool){  
        epochLength = _epochLength;
        return true;
    } 

    function transfer(uint256 _amount) external  onlyOwner returns (bool){  
        REKT.transfer(msg.sender, _amount);
        return true;
    }  
       
}