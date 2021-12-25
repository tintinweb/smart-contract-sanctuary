// SPDX-License-Identifier: MIT
                               
//             ████████            
//           ██        ██          
//         ██▒▒░░        ██        
//       ██▒▒░░░░        ▒▒██      
//       ██▒▒░░░░      ░░▒▒██      
//     ██  ░░░░        ░░░░▒▒██    
//     ██                ░░▒▒██    
//   ██          ░░░░          ██  
//   ██      ░░░░░░░░░░        ██  
//   ██      ░░░░░░░░░░    ░░▒▒██  
//   ██▒▒░░    ░░░░░░░░  ░░░░▒▒██  
//     ██░░░░  ░░░░░░    ░░▒▒██    
//     ██▒▒░░            ░░▒▒██    
//       ██▒▒              ██      
//         ████        ████        
//             ████████            
//  ______     __     __         __         ______        ______     ______     ______    
// /\___  \   /\ \   /\ \       /\ \       /\  __ \      /\  ___\   /\  ___\   /\  ___\   
// \/_/  /__  \ \ \  \ \ \____  \ \ \____  \ \  __ \     \ \  __\   \ \ \__ \  \ \ \__ \  
//   /\_____\  \ \_\  \ \_____\  \ \_____\  \ \_\ \_\     \ \_____\  \ \_____\  \ \_____\ 
//   \/_____/   \/_/   \/_____/   \/_____/   \/_/\/_/      \/_____/   \/_____/   \/_____/ 
                                                                                       
//$ZEGG IS A UTILITY TOKEN FOR THE CHILLAZILLA ECOSYSTEM.
//$ZEGG is NOT an investment and has NO economic value. 
//It will be earned by holding within the ChillaZilla ecosystem. Each Genesis Chilla Zilla will be eligible to claim tokens at a rate of 10 $ZEGG per day.


pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

interface iChillaZilla {
    function balanceGenesis(address owner) external view returns(uint256);
}

contract ZillaEgg is ERC20, Ownable {

    iChillaZilla public ChillaZilla;

    uint256 constant public BASE_RATE = 10 ether;
    uint256 public START;
    bool rewardPaused = false;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    mapping(address => bool) public allowedAddresses;

    constructor(address zillaAddress) ERC20("ZillaEgg", "ZEGG") {
        ChillaZilla = iChillaZilla(zillaAddress);
        START = block.timestamp;
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(ChillaZilla));
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
    
    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(ChillaZilla), "Address does not have permission to burn");
        _burn(user, amount);
    }

    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns(uint256) {
        return ChillaZilla.balanceGenesis(user) * BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) 
        // / 86400; //seconds
        / 1; 
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }

     function setChillaZilla(address zillaAddress) external onlyOwner {
        ChillaZilla = iChillaZilla(zillaAddress);
    }
}