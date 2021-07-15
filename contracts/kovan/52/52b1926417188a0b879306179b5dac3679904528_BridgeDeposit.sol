/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BridgeDeposit {

    address private owner;
    uint256 private maxAmount;
    bool private canReceive;
        
    constructor(uint256 _maxAmount, bool _canReceive) {
        owner = msg.sender;
        maxAmount = _maxAmount;
        canReceive = _canReceive;
        emit OwnerSet(address(0), owner);
        emit CanReceiveSet(_canReceive);
    }
    
    // Send the contract's balance to the owner
    function rug() public isOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit Rugged(owner, balance);
    }
    
    function destroy() public isOwner {
        emit Destructed(owner, address(this).balance);
        selfdestruct(payable(owner));
        
    }
    
    // Receive function which reverts if amount > maxAmount and canReceive = false
    receive() external payable isLowerThanMaxAmount isReceiving{
        emit EtherReceived(msg.sender, msg.value);
    }
    
    // Setters    
    function setMaxAmount(uint256 _maxAmount) public isOwner {
        emit MaxAmountSet(maxAmount, _maxAmount);
        maxAmount = _maxAmount;
    }
    function setOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    function setCanReceive(bool _canReceive) public isOwner {
        emit CanReceiveSet(_canReceive);
        canReceive = _canReceive;
    }
    
    // Getters
    function getMaxAmount() external view returns (uint256) {
        return maxAmount;
    }
    function getOwner() external view returns (address) {
        return owner;
    }
    function getCanReceive() external view returns (bool) {
        return canReceive;
    }
    
    // Modifiers
    modifier isLowerThanMaxAmount() {
        require(msg.value <= maxAmount, "Amount is too big");
        _;
    }
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    modifier isReceiving() {
        require(canReceive == true, "Contract is not allowed to receive ether");
        _;
    }
    
    // Events
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event MaxAmountSet(uint256 previousAmount, uint256 newAmount);
    event CanReceiveSet(bool canReceive);
    event Rugged(address indexed owner, uint256 balance);
    event EtherReceived(address indexed emitter, uint256 amount);
    event Destructed(address indexed owner, uint256 amount);
    
}