// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

interface iCrocZ {
    function balanceGenesis(address owner) external view returns(uint256);
}

contract Swamp is ERC20, Ownable {

    iCrocZ public CrocZ;

    uint256 public BASE_RATE = 10 ether;
    uint256 public START;
    bool rewardPaused = false;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    mapping(address => bool) public allowedAddresses;

    constructor(address croczAddress) ERC20("Swamp", "SWAMP") {
        CrocZ = iCrocZ(croczAddress);
        START = block.timestamp;
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(CrocZ));
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
        require(allowedAddresses[msg.sender] || msg.sender == address(CrocZ), "Address does not have permission to burn");
        _burn(user, amount);
    }

    function setRate(uint256 newRate) public onlyOwner {
        BASE_RATE = newRate;
    }

    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns(uint256) {
        return CrocZ.balanceGenesis(user) * BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) / 86400;
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }
}