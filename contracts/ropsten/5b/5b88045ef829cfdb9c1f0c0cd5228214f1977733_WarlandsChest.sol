/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
contract WarlandsChest  {
    string public name = "Warlands Presale Chests";
    uint256 public SilverCost = 0.1 ether;
    uint256 public totalSilverMinted = 80;
    uint256 public GoldCost = 0.3 ether;
    uint256 public totalGoldMinted = 115;
    uint256 public DiamondCost = 1.65 ether;
    uint256 public totalDiamondMinted = 150;
    
    event boughtChest(address indexed _from, uint256 cost); 
    modifier shouldPay(uint256 _cost) {
        require(msg.value >= _cost, "The chests cost more!");
        _;
    }
    function BuySilverChest() payable external shouldPay(SilverCost) {
        emit boughtChest(msg.sender, SilverCost);
        totalSilverMinted++;
    }
    function BuyGoldChest() payable external shouldPay(GoldCost) {
        emit boughtChest(msg.sender, GoldCost);
        totalGoldMinted++;
    }
    function BuyDiamondChest() payable external shouldPay(DiamondCost) {
        emit boughtChest(msg.sender, DiamondCost);
        totalDiamondMinted++;
    }
    function getFunds() public view returns(uint256) {
        return address(this).balance;
    }
    address payable public owner;
    constructor() payable {
        owner = payable(msg.sender);
    }
    function withdraw() public {
        uint amount = address(this).balance;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}