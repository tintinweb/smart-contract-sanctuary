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
    uint256 public totalSilverMinted = 80;
    uint256 public totalGoldMinted = 115;
    uint256 public totalDiamondMinted = 150;
    uint256 public maxSilverChests = 1000;
    uint256 public maxGoldChests = 2000;
    uint256 public maxDiamondChests = 3000;

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

    function setSilverChestPrice(uint256 newSilverChest) public onlyOwner {
        SilverCost = newSilverChest;
    }

    function setGoldChestPrice(uint256 newGoldChest) public onlyOwner {
        GoldCost = newGoldChest;
    }

    function setDiamondChestPrice(uint256 newDiamondChest) public onlyOwner {
        DiamondCost = newDiamondChest;
    }

    function BuySilverChest() external payable shouldPay(SilverCost) {
        require(totalSilverMinted <= maxSilverChests, "Maximum Silver Chests minted!");
        emit boughtChest(msg.sender, SilverCost);
        totalSilverMinted++;
    }

    function BuyGoldChest() external payable shouldPay(GoldCost) {
        require(totalGoldMinted <= maxGoldChests, "Maximum Gold Chests minted!");
        emit boughtChest(msg.sender, GoldCost);
        totalGoldMinted++;
    }

    function BuyDiamondChest() external payable shouldPay(DiamondCost) {
        require(totalDiamondMinted <= maxDiamondChests, "Maximum Diamond Chests minted!");
        emit boughtChest(msg.sender, DiamondCost);
        totalDiamondMinted++;
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