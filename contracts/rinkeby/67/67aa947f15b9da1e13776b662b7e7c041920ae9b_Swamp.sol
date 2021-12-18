// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

interface iCrocZ {
    function balanceGenesis(address owner) external view returns(uint256);
}

interface iBaby {
    function balanceBaby(address owner) external view returns(uint256);
}

contract Swamp is ERC20, Ownable {

    iCrocZ public CrocZ;
    iBaby public BabyCrocZ;

    uint256 public BASE_RATE = 10 ether;
    uint256 public BABY_RATE = 5 ether;
    uint256 public START;
    bool rewardPaused = false;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;
    mapping(address => bool) public allowedAddresses;

    constructor(address babyCroczAddress, address croczAddress) ERC20("Swamp", "SWAMP") {
        BabyCrocZ = iBaby(babyCroczAddress);
        CrocZ = iCrocZ(croczAddress);
        START = block.timestamp + 604800;
    }

    function updateCroczReward(address from, address to) external {
        require(msg.sender == address(CrocZ));
        if(from != address(0)){
            rewards[from] += getPendingCroczReward(from);
            lastUpdate[from] = block.timestamp;
        }
        if(to != address(0)){
            rewards[to] += getPendingCroczReward(to);
            lastUpdate[to] = block.timestamp;
        }
    }

    function updateBabyCroczReward(address from, address to) external {
        require(msg.sender == address(BabyCrocZ));
        if(from != address(0)){
            rewards[from] += getPendingBabyReward(from);
            lastUpdate[from] = block.timestamp;
        }
        if(to != address(0)){
            rewards[to] += getPendingBabyReward(to);
            lastUpdate[to] = block.timestamp;
        }
    }

    function claimReward() external {
        require(!rewardPaused, "Claiming reward has been paused"); 
        _mint(msg.sender, rewards[msg.sender] + getPendingRewards(msg.sender));
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(CrocZ), "Address does not have permission to burn");
        _burn(user, amount);
    }

    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingRewards(user);
    }

    function getPendingCroczReward(address user) internal view returns(uint256) {
        return CrocZ.balanceGenesis(user) * BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) / 86400;
    }

    function getPendingBabyReward(address user) internal view returns(uint256) {
        return BabyCrocZ.balanceBaby(user) * BABY_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) / 86400;
    }

    function getPendingRewards(address user) internal view returns(uint256) {
        return getPendingBabyReward(user) + getPendingCroczReward(user);
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}