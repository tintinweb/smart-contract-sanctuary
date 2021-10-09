/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

pragma solidity ^0.8.9;

// SPDX-License-Identifier: Apache-2.0
// Isolde Payment Gateway V3.0

contract Isolde {
    
    modifier onlyOwner {
        require(msg.sender == _owner, "caller is not the owner");
        _;
    }
    
    // tier struct
    struct Tier {
        string name;
        uint8 level;
        uint256 price;
    }
    
    // events
    event Subscribed(address wallet, uint8 level, uint256 time);
    event Transfer(uint256 revenueAmount, uint256 sharedAmount);
    event Beacon(uint256 timestamp);
    
    // addresses & allocation
    uint public revenueAllocation = 90;
    uint public sharedAllocation = 10;
    address payable public shared;
    address payable public treasury;
    address private _owner;
    
    // tiers
    Tier[] private _tiers;

    
    constructor (address payable sharedAddress, address payable treasuryAddress) {
        _owner = msg.sender;
        
        shared = sharedAddress;
        treasury = treasuryAddress;
    }
    
    function setTiers(Tier[] memory tiers) external onlyOwner {
        delete _tiers;
        
        for (uint i = 0; i < tiers.length; ++i) {
            Tier memory tier = tiers[i];
            _tiers.push(Tier(tier.name, tier.level, tier.price));
        }
    }

    function getTiers() external view returns (Tier[] memory) {
        return _tiers;
    }
    
    function viewTier(uint level) external view returns (string memory, uint, uint) {
        require(level > 0 && level <= _tiers.length, 'wrong tier');
        Tier memory tier = _tiers[level - 1];
        return (tier.name, tier.level, tier.price);
    }
    
    function subscribe(address who, uint8 level) external payable { // since who isn't msg.sender someone can possibly gift a subscribtion
        require(level > 0 && level <= _tiers.length, 'wrong tier');
        require(msg.value == _tiers[level - 1].price, 'sent ether is different from tier price');

        emit Subscribed(who, level, 30);
    }
    
    function _sendEthTo(address payable wallet, uint256 amount) private {
        wallet.transfer(amount);
    }
    
    function transfer(uint256 ethAmount) external onlyOwner {
        require(address(this).balance >= ethAmount, 'low balance');
        require(shared != address(0), 'shared address not set');
        require(treasury != address(0), 'treasury address not set');

        uint256 treasuryAmount = ethAmount * revenueAllocation / 100;
        uint256 sharedAmount = ethAmount * sharedAllocation / 100;

        _sendEthTo(treasury, treasuryAmount);
        _sendEthTo(shared, sharedAmount);

        emit Transfer(treasuryAmount, sharedAmount);
    }
    
    function sendBeacon() external onlyOwner {
        emit Beacon(block.timestamp);
    }
    
    function setShared(address payable newShared) external onlyOwner {
        shared = newShared;
    }

    function setTreasury(address payable newTreasury) external onlyOwner {
        treasury = newTreasury;
    }
    
    function setAllocations(uint newRevenueAllocation, uint newSharedAllocation) external onlyOwner {
        require(newRevenueAllocation + newSharedAllocation == 100, 'allocation sum must equal 100');
        require(newRevenueAllocation <= 95, 'maximum revenue allocation exceeded');
        revenueAllocation = newRevenueAllocation;
        sharedAllocation = newSharedAllocation;
    }
    
    receive() external payable {}
}