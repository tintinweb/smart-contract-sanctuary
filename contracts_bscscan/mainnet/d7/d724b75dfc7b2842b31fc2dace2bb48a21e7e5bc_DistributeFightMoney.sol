/**
 *Submitted for verification at BscScan.com on 2021-09-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract DistributeFightMoney{
    
     struct userData {
        address FightAddress;
        uint256 BNBbalance;
        uint256 index;
        bool isActive;
    }
    
    mapping(address => userData) private userByAddress;
    mapping(uint256 => userData) private userByIndex;
    
    
    address private manager = 0xc6CBDd49a933faC2188e9d5d1bEAE4f78C78c4f5;
    uint256 public totalFighters = 0;



    function insertUser(uint256 UserIndex, address NewFighterAddress) external {
        require(msg.sender == manager, "not allowed");
        
        uint256 BNB_balance = address(NewFighterAddress).balance;
        
        userByIndex[UserIndex] = userData(NewFighterAddress, BNB_balance, UserIndex, true);
        totalFighters++;
        
    }
    
    function deactivateUser(uint256 UserIndex) external {
        require(msg.sender == manager, "not allowed");
        
      userByIndex[UserIndex].isActive = false;

}


    function SendBNBtoAll() payable external{

            uint256 activeUsers = 0;
            for(uint256 i = 1; i <= totalFighters; i++){
                if(userByIndex[i].isActive){
                    activeUsers++;
                }
            }
            address payable wallet;
            for(uint256 i = 1; i <= totalFighters; i++){
                if(userByIndex[i].isActive){
                    wallet = payable(userByIndex[i].FightAddress);
                    wallet.transfer(msg.value/activeUsers);
                }
            }
    }


    function SendBNBtoPoorFighters() payable external{

            uint256 poorUsers = 0;
            for(uint256 i = 1; i <= totalFighters; i++){
                if(address(userByIndex[i].FightAddress).balance <= 20000000000000000){
                    poorUsers++;
                }
            }
            
            address payable wallet;
            for(uint256 i = 1; i <= totalFighters; i++){
                if(address(userByIndex[i].FightAddress).balance <= 20000000000000000){
                    wallet = payable(userByIndex[i].FightAddress);
                    wallet.transfer(msg.value/poorUsers);
                }
            }
    }


    
    function ZTakeBackMoney() external{
        require(msg.sender == manager, "you're not the owner");
        address payable owner =  payable(msg.sender);
            owner.transfer(address(this).balance);
    }
    
    
        receive() external payable {}
        
    
    
}