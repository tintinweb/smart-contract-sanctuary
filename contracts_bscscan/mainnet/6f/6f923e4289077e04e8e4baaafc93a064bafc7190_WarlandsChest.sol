/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract WarlandsChest {
    string public name = "Warlands Presale Chests";
    uint256 public SilverChestCost = 0.1 ether;
    uint256 public GoldChestCost = 0.3 ether;
    uint256 public DiamondChestCost = 1.65 ether;
    uint256 public PlatinumChestCost = 1 ether;
    uint256 public totalSilverChestMinted = 219;
    uint256 public totalGoldChestMinted = 250;
    uint256 public totalDiamondChestMinted = 44;
    uint256 public totalPlatinumChestMinted = 0;
    uint256 public maxSilverChestSupply = 525;
    uint256 public maxGoldChestSupply = 325;
    uint256 public maxDiamondChestSupply = 2500;
    uint256 public maxPlatinumChestSupply = 150;

    event boughtChest(address indexed _from, uint256 cost);
    event withdrawing(
        address indexed _from,
        address indexed _to,
        uint256 withdrawAmount
    );

    modifier shouldPay(uint256 _cost) {
        require(msg.value >= _cost, "The chest costs more!");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can access this!");
        _;
    }

    function setMaxSilverSupply(uint256 newMaxSilverChestSupply)
        public
        onlyOwner
    {
        maxSilverChestSupply = newMaxSilverChestSupply;
    }

    function setMaxGoldSupply(uint256 newMaxGoldChestSupply) public onlyOwner {
        maxGoldChestSupply = newMaxGoldChestSupply;
    }

    function setMaxDiamondSupply(uint256 newMaxDiamondChestSupply)
        public
        onlyOwner
    {
        maxDiamondChestSupply = newMaxDiamondChestSupply;
    }

    function setMaxPlatinumSupply(uint256 newMaxPlatinumChestSupply)
        public
        onlyOwner
    {
        maxPlatinumChestSupply = newMaxPlatinumChestSupply;
    }

    function setTotalSilverChestMinted(uint256 newSilverChestMintedCount)
        public
        onlyOwner
    {
        totalSilverChestMinted = newSilverChestMintedCount;
    }

    function setTotalGoldChestMinted(uint256 newGoldChestMintedCount)
        public
        onlyOwner
    {
        totalGoldChestMinted = newGoldChestMintedCount;
    }

    function setTotalDiamondChestMinted(uint256 newDiamondChestMintedCount)
        public
        onlyOwner
    {
        totalDiamondChestMinted = newDiamondChestMintedCount;
    }

    function setTotalPlatinumChestMinted(uint256 newPlatinumChestMintedCount)
        public
        onlyOwner
    {
        totalPlatinumChestMinted = newPlatinumChestMintedCount;
    }

    function setSilverChestCost(uint256 newSilverChestCost) public onlyOwner {
        SilverChestCost = newSilverChestCost;
    }

    function setGoldChestCost(uint256 newGoldChestCost) public onlyOwner {
        GoldChestCost = newGoldChestCost;
    }

    function setDiamondChestCost(uint256 newDiamondChestCost) public onlyOwner {
        DiamondChestCost = newDiamondChestCost;
    }

    function setPlatinumChestCost(uint256 newPlatinumChestCost)
        public
        onlyOwner
    {
        PlatinumChestCost = newPlatinumChestCost;
    }

    function BuySilverChest() external payable shouldPay(SilverChestCost) {
        require(
            totalSilverChestMinted <= maxSilverChestSupply - 1,
            "Maximum Silver Chests minted!"
        );
        emit boughtChest(msg.sender, SilverChestCost);
        totalSilverChestMinted++;
    }

    function BuyGoldChest() external payable shouldPay(GoldChestCost) {
        require(
            totalGoldChestMinted <= maxGoldChestSupply - 1,
            "Maximum Gold Chests minted!"
        );
        emit boughtChest(msg.sender, GoldChestCost);
        totalGoldChestMinted++;
    }

    function BuyDiamondChest() external payable shouldPay(DiamondChestCost) {
        require(
            totalDiamondChestMinted <= maxDiamondChestSupply - 1,
            "Maximum Diamond Chests minted!"
        );
        emit boughtChest(msg.sender, DiamondChestCost);
        totalDiamondChestMinted++;
    }

    function BuyPlatinumChest() external payable shouldPay(PlatinumChestCost) {
        require(
            totalPlatinumChestMinted <= maxPlatinumChestSupply - 1,
            "Maximum Platinum Chests minted!"
        );
        emit boughtChest(msg.sender, PlatinumChestCost);
        totalPlatinumChestMinted++;
    }

    function getFunds() public view returns (uint256) {
        return address(this).balance;
    }

    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    function Withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send BNB");
        emit withdrawing(msg.sender, owner, amount);
    }
}