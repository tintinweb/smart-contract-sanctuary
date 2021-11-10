// SPDX-License-Identifier: MIT

//$YOLK is NOT an investment and has NO economic value. 
//It will be earned by active holding within the Hatchlingz ecosystem. 


pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";


//NOTES NEED TO UPDATE REWARDS AS PART OF TRANSFER FUNCTION IN HATCHLINGZ



interface iHatchlingz {
    //function balanceGenesis(address owner) external view returns(uint256);
    
    
    function _hatchTime(uint256 tokenId) external view returns (uint256);
    
    function _walletBalanceOfPhoenix(address owner) external view returns (uint256);
    
   function _walletBalanceOfDragon(address owner) external view returns (uint256);
   
   
   function _walletBalanceOfChicken(address owner) external view returns (uint256);
}

contract Yolk is ERC20, Ownable {

    iHatchlingz public Hatchlingz;

    uint256 constant public PHOENIX_RATE = 10 ether;
    uint256 constant public DRAGON_RATE = 5 ether;
    uint256 constant public CHICKEN_RATE = 2 ether;
    
   // uint256 public START;
    
    bool rewardPaused = false;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    mapping(address => bool) public allowedAddresses;

    constructor(address HatchlingzAddress) ERC20("Yolk", "YOLK") {
        Hatchlingz = iHatchlingz(HatchlingzAddress);
        //START = block.timestamp;
    }

    function updateReward(address from, address to) public {
        require(msg.sender == address(Hatchlingz));
        if(from != address(0)){
            rewards[from] += getPendingReward(from);
            lastUpdate[from] = block.timestamp;
        }
        if(to != address(0)){
            rewards[to] += getPendingReward(to);
            lastUpdate[to] = block.timestamp;
        }
    }

    function claimReward() external {
        require(!rewardPaused, "Claiming reward has been paused"); 
        _mint(msg.sender, rewards[msg.sender] + getPendingReward(msg.sender));
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    
    function crackEggsRewards(address _address, uint256 _amount) external {
        require(!rewardPaused,                "Claiming reward has been paused"); 
        require(allowedAddresses[msg.sender], "Address does not have permission to distrubute tokens");
        _mint(_address, _amount);
    }

    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(Hatchlingz), "Address does not have permission to burn");
        
   
        if( msg.sender == address(Hatchlingz)){
                if (getTotalClaimable(user)  >= amount){
                    updateReward(user, address(0));
                    rewards[user] = rewards[user] - amount;
                 
                  }
                
                else if (getTotalClaimable(user) < amount) {
                    updateReward(user, address(0));
                    uint256 credit = amount - rewards[user] ;
                    rewards[user] = 0;
                    
                     _burn(user, credit);
             
                }
        }
        
        else {
            _burn(user, amount);
        }
        
    }

    function getTotalClaimable(address user) public view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns(uint256) {
        return (Hatchlingz._walletBalanceOfChicken(user) * CHICKEN_RATE * (block.timestamp - lastUpdate[user]) / 86400) +
        (Hatchlingz._walletBalanceOfDragon(user) * DRAGON_RATE * (block.timestamp - lastUpdate[user]) / 86400) +
        (Hatchlingz._walletBalanceOfPhoenix(user) * PHOENIX_RATE * (block.timestamp - lastUpdate[user]) / 86400);
        
      
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }
}