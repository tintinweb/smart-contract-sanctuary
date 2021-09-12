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

constructor() {

    insertUser(1,0xB725D4190C5DA1a601DA7F8585C6dbf44B4742Ab);
    insertUser(2,0x9C4901adBEC3cEfC9f2112fA9Eb3B726133e3167);
    insertUser(3,0xBD7c6A659711a31aDa6F3bFD83ba17F3421a277D);
    insertUser(4,0x2b985Ad4913BDaFC0EF6aA699646334206FFF45b);
    insertUser(5,0x1354140DA9AA65a342c94f8Ca7bBb2940D8CBC6e);
    insertUser(6,0xB061b99B8065bc7b2a3D711b3ce77c1D1c96D30f);
    insertUser(7,0x8fc1543DFE58817fa06d7B0e7198777BF131E6d9);
    insertUser(8,0x808981D0fE3108574E18CB4c5cAb03Cb121e1f74);
    insertUser(9,0x4fa2e87AA256a328C4ce583bC7DcDE683c2Fafc3);
    insertUser(10,0xF13fc2a5cDf152d8bF71f042dE8BBdee85e33C15);
    insertUser(11,0xB93Fc8eEcCB78451686935253708cc15508cf53F);
    insertUser(12,0xE2c6A0Dbcae088a41e17195AB528a9A75A9Dc920);

}


    function insertUser(uint256 UserIndex, address NewFighterAddress) public {
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