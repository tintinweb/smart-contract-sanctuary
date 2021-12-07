/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

contract MysteryChests {

    uint256 public SilverCost = 0.1 ether;
    uint256 public totalSilverSupply = 525;
    uint256 public GoldCost = 0.3 ether;
    uint256 public totalGoldSupply = 325;
    uint256 public DiamondCost = 0.75 ether;
    uint256 public totalDiamondSupply = 150;

    event boughtChest(address indexed _from, uint256 cost); 
    
    modifier shouldPay(uint256 _cost) {
        require(msg.value >= _cost, "The chests cost more!");
        _;
    }

    function BuySilverChest() payable public shouldPay(SilverCost) {
        require(totalSilverSupply !=0, "This chest supply ran out!"); 
        emit boughtChest(msg.sender, SilverCost);
        totalSilverSupply = totalSilverSupply - 1;
    }

    function BuyGoldChest() payable public shouldPay(GoldCost) {
        require(totalGoldSupply !=0, "This chest supply ran out!"); 
        emit boughtChest(msg.sender, GoldCost);
        totalGoldSupply = totalGoldSupply - 1;
    }

    function BuyDiamondChest() payable public shouldPay(DiamondCost) {
        require(totalDiamondSupply !=0, "This chest supply ran out!"); 
        emit boughtChest(msg.sender, DiamondCost);
        totalDiamondSupply = totalDiamondSupply - 1;
    }

    function getFunds() public view returns(uint256) {
        return address(this).balance;
    }

}