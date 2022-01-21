// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";
 

interface IWACEO { 
    function mint(address to, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract WACEOAirdrop is Ownable {
    
    struct Info { 
        address recipient;
        uint vesting;  
        uint reward;
        uint claimableReward; 
        bool active; 
    } 
 
    IWACEO private WACEO;
    Info[] public info;
    
    
    constructor(address _tokenAddress ) Ownable() {
        WACEO = IWACEO(_tokenAddress); 
    }  
 
 
    function claim() public { 
        uint index; 
        for(uint i = 0; i<info.length; i++){
            if(info[i].recipient == msg.sender){
                index = i;
            } 
        }
        Info storage senderInfo = info[index]; 
        require(senderInfo.active, "Wrong address!"); 
        require(block.timestamp > senderInfo.vesting, "Rewards are not fully vested!");
        WACEO.mint(msg.sender, senderInfo.reward);
        senderInfo.active = false;
    }  
 

 
 

    function status(address  _address) public view returns(Info memory) {  
        uint index; 
        for(uint i = 0; i<info.length; i++){
            if(info[i].recipient == _address){
                index = i;
            } 
        }
        Info memory senderInfo = info[index];
        return (senderInfo);
    }  


    function setAccounts(Info[] memory _records) public onlyOwner { 
        for(uint i=0; i< _records.length; i++){
           uint timestamp = block.timestamp + _records[i].vesting;
            Info memory newInfo = Info({
                recipient: _records[i].recipient,
                vesting: timestamp,
                reward: _records[i].reward,
                claimableReward: 0,
                active: true
            });
            info.push(newInfo); 
        } 
    }

 
    function setAccount(address _address, uint _vesting, uint _reward) public onlyOwner { 
        uint timestamp = block.timestamp + _vesting;
         Info memory newInfo = Info({
                recipient: _address,
                vesting: timestamp,
                reward: _reward,
                claimableReward: 0,
                active: true
            });
        info.push(newInfo);  
    }
    

    function transfer(uint _amount) public  onlyOwner returns (bool){  
        WACEO.transfer(msg.sender, _amount);
        return true;
    }  
       
}