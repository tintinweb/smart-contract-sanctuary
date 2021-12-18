/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

// Open0x Ownable (by 0xInuarashi)
abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed oldOwner_, address indexed newOwner_);
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Ownable: caller is not the owner"); _; }
    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner; owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_); }
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(newOwner_ != address(0x0), "Ownable: new owner is the zero address!");
        _transferOwnership(newOwner_); }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0)); }
}

// Open0x Security by 0xInuarashi
abstract contract Security {
    // Prevent Smart Contracts
    modifier onlySender {
        require(msg.sender == tx.origin, "No Smart Contracts!"); _; }
}

// Interface
interface iSleepwalkers {
    function ownerMint(address address_, uint256 amount_) external;
    function transferOwnership(address newOwner_) external;
}

// Sleepwalkers Mint Proxy
contract sleepwalkersMintProxy is Ownable, Security {

    // General NFT Variables
    uint256 public mintPrice = 0.0588 ether;
    uint256 public maxMintsPerTx = 20;

    // Interface of Sleepwalkers
    iSleepwalkers public Sleepwalkers = iSleepwalkers(0xf2025A9c5514C1bE17247ab2f2D385De2eAD4f26);

    // Contract Administration
    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_; 
    }
    function transferSleepwalkersOwnership(address newOwner_) external onlyOwner {
        Sleepwalkers.transferOwnership(newOwner_);
    }

    // Wihdraw the Ether from the Contract
    function withdrawEther() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance); 
    }

    // Owner Mint
    function ownerMint(address address_, uint256 amount_) external onlyOwner {
        Sleepwalkers.ownerMint(address_, amount_); 
    }

    // Public Mint Params
    bool public publicMintEnabled = true;
    uint256 public publicMintTime = 1639785600; // Sat Dec 18 2021 00:00:00 GMT+0000

    // Public Mint Administration
    function setPublicMintStatus(bool bool_, uint256 time_) external onlyOwner {
        publicMintEnabled = bool_; publicMintTime = time_; }
    modifier publicMint {
        require(publicMintEnabled && block.timestamp >= publicMintTime, "Public Mint is not open yet!"); _; }
    
    // Public Mint
    function mint(uint256 amount_) external payable onlySender publicMint {
        require(msg.value == amount_ * mintPrice, "Invalid value sent!");
        require(maxMintsPerTx >= amount_, "Over maximum mints per TX!");
        
        Sleepwalkers.ownerMint(msg.sender, amount_);
    }
}