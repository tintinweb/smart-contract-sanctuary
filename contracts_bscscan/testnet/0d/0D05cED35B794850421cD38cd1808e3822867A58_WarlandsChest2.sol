/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract WarlandsChest2 {
    string public name = "Warlands Presale Chests 2";
    uint256 public SilverCost = 0.1 ether;
    uint256 public GoldCost = 0.3 ether;
    uint256 public DiamondCost = 1.65 ether;
    uint256 public PlatinumCost = 1 ether;
    uint256 public totalSilverMinted = 80;
    uint256 public totalGoldMinted = 115;
    uint256 public totalDiamondMinted = 150;
    uint256 public totalPlatinumMinted = 0;
    uint256 public maxSilverChests = 1000;
    uint256 public maxGoldChests = 2000;
    uint256 public maxDiamondChests = 3000;
    uint256 public maxPlatinumChests = 150;

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

    function setMaxSilverMinted(uint256 maxSilverMintedCount) public onlyOwner {
        maxSilverChests = maxSilverMintedCount;
    }

    function setMaxGoldMinted(uint256 maxGoldMintedCount) public onlyOwner {
        maxGoldChests = maxGoldMintedCount;
    }

    function setMaxDiamondMinted(uint256 maxDiamondMintedCount)
        public
        onlyOwner
    {
        maxDiamondChests = maxDiamondMintedCount;
    }

    function setMaxPlatinumMinted(uint256 maxPlatinumMintedCount)
        public
        onlyOwner
    {
        maxPlatinumChests = maxPlatinumMintedCount;
    }

    function setTotalSilverMinted(uint256 newSilverMintedCount)
        public
        onlyOwner
    {
        totalSilverMinted = newSilverMintedCount;
    }

    function setTotalGoldMinted(uint256 newGoldMintedCount) public onlyOwner {
        totalGoldMinted = newGoldMintedCount;
    }

    function setTotalDiamondMinted(uint256 newDiamondMintedCount)
        public
        onlyOwner
    {
        totalDiamondMinted = newDiamondMintedCount;
    }

    function setTotalPlatinumMinted(uint256 newPlatinumMintedCount)
        public
        onlyOwner
    {
        totalPlatinumMinted = newPlatinumMintedCount;
    }

    function setSilverChestPrice(uint256 newSilverChest) public onlyOwner {
        SilverCost = newSilverChest;
    }

    function setGoldChestPrice(uint256 newGoldChest) public onlyOwner {
        GoldCost = newGoldChest;
    }

    function setDiamondChestPrice(uint256 newDiamondChest) public onlyOwner {
        DiamondCost = newDiamondChest;
    }

    function setPlatinumChestPrice(uint256 newPlatinumChest) public onlyOwner {
        PlatinumCost = newPlatinumChest;
    }

    function BuySilverChest() external payable shouldPay(SilverCost) {
        require(
            totalSilverMinted <= maxSilverChests,
            "Maximum Silver Chests minted!"
        );
        emit boughtChest(msg.sender, SilverCost);
        totalSilverMinted++;
    }

    function BuyGoldChest() external payable shouldPay(GoldCost) {
        require(
            totalGoldMinted <= maxGoldChests,
            "Maximum Gold Chests minted!"
        );
        emit boughtChest(msg.sender, GoldCost);
        totalGoldMinted++;
    }

    function BuyDiamondChest() external payable shouldPay(DiamondCost) {
        require(
            totalDiamondMinted <= maxDiamondChests,
            "Maximum Diamond Chests minted!"
        );
        emit boughtChest(msg.sender, DiamondCost);
        totalDiamondMinted++;
    }

    function BuyPlatinumChest() external payable shouldPay(PlatinumCost) {
        require(
            totalPlatinumMinted <= maxPlatinumChests,
            "Maximum Platinum Chests minted!"
        );
        emit boughtChest(msg.sender, PlatinumCost);
        totalPlatinumMinted++;
    }

    function getFunds() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    address payable private owner;

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