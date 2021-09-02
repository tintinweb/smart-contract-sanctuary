// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

/*

    the minter contract for complex minter core.
    this is a payable contract and used with primary functions : mint (payable), withdraw/distribute (payable)

*/

interface IComplexMinterCore {
    function minterMint(address to_) external;
    function availableTokensRemaining() external returns (uint);
}

contract ComplexMinterMinter is Ownable {
    
    IComplexMinterCore minterCore;
    address public minterCoreAddress;
    
    uint public mintingCost = 0.1 ether;
    bool public mintingEnabled = false;
    uint public ownerMintManyMax = 20;
    
    bool public mintManyOption = false;
    uint public mintManyMax = 0;
    
    address public ownerAddress;
    address public partnerAddress;
    address public artistAddress;
    
    uint public ownerRate;
    uint public partnerRate;
    uint public artistRate;
    
    constructor() {}
    
    // modifiers
    modifier onlyPartner() {
        require(msg.sender == partnerAddress, "You are not the partner!");
        _;
    }
    modifier onlySender() {
        require(msg.sender == tx.origin, "Sender must be origin");
        _;
    }
    modifier publicMinting() {
        require(mintingEnabled == true, "Public Minting is not enabled!");
        _;
    }
    modifier mintManyEnabled() {
        require(mintManyOption == true," Mint Many is not enabled!");
        _;
    }
    modifier isCompleteDistribution() {
        require((ownerRate + partnerRate + artistRate) == 100, "Incorrect distribution rates");
        require((ownerAddress   != address(0)), "Owner address not set.");
        require((partnerAddress != address(0)), "Partner address not set.");
        require((artistAddress  != address(0)), "Artist address not set.");
        _;
    }
    
    // funds withdrawals
    function withdrawEtherAsOwner() external onlyOwner isCompleteDistribution {
        uint _balance = address(this).balance;
        uint _ownerPayout = ((_balance / 100) * ownerRate);
        uint _partnerPayout = ((_balance / 100) * partnerRate);
        uint _artistPayout = ((_balance / 100) * artistRate);
        
        payable(ownerAddress).transfer(_ownerPayout);
        payable(partnerAddress).transfer(_partnerPayout);
        payable(artistAddress).transfer(_artistPayout);
    }
    function withdrawEtherAsPartner() external onlyPartner isCompleteDistribution {
        uint _balance = address(this).balance;
        uint _ownerPayout = ((_balance / 100) * ownerRate);
        uint _partnerPayout = ((_balance / 100) * partnerRate);
        uint _artistPayout = ((_balance / 100) * artistRate);
        
        payable(ownerAddress).transfer(_ownerPayout);
        payable(partnerAddress).transfer(_partnerPayout);
        payable(artistAddress).transfer(_artistPayout);
    }
    
    // settings
    function initMinterCore(address address_) external onlyOwner {
        minterCoreAddress = address_;
        minterCore = IComplexMinterCore(minterCoreAddress);
    }
    function setMintingCost(uint price_) external onlyOwner {
        mintingCost = price_;
    }
    
    // owner Mint
    function ownerMint(address to_, uint amount_) external onlyOwner {
        require(amount_ <= ownerMintManyMax, "Over max amount of mints per transaction!");
        require(minterCore.availableTokensRemaining() >= amount_, "Not enough tokens remaining!");
        for (uint i = 0; i < amount_; i++) {
            minterCore.minterMint(to_);
        }
    }
    
    // normal Mint
    function normalMint() payable external publicMinting {
        require(msg.value == mintingCost, "Incorrect value!");
        require(minterCore.availableTokensRemaining() >= 1, "Not enough tokens remaining!");
        minterCore.minterMint(msg.sender);
    }
    
    function normalMintMany(uint amount_) payable external mintManyEnabled publicMinting {
        require(msg.value == (mintingCost * amount_), "Incorrect value!");
        require(minterCore.availableTokensRemaining() >= amount_, "Not enough tokens remaining!");
        for (uint i = 0; i < amount_; i++) {
            minterCore.minterMint(msg.sender);
        }
    }
    
}