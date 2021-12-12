/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: MIT
// Author : spikeyrock - nftit
// Contact : [email protected]


pragma solidity =0.8.9;

contract WarlandsChest {

    uint256 public SilverCost = 0.1 ether;
    uint256 public totalSilverMinted = 0;
    uint256 public GoldCost = 0.3 ether;
    uint256 public totalGoldMinted = 0;
    uint256 public DiamondCost = 0.75 ether;
    uint256 public totalDiamondMinted = 0;
    

  
    event boughtChest(address indexed _from, uint256 cost); 
    
    modifier shouldPay(uint256 _cost) {
        require(msg.value >= _cost, "The chests cost more!");
        _;
    }

    function BuySilverChest() payable public shouldPay(SilverCost) {
        emit boughtChest(msg.sender, SilverCost);
        totalSilverMinted = totalSilverMinted + 1;
        
    }

    function BuyGoldChest() payable public shouldPay(GoldCost) {
        emit boughtChest(msg.sender, GoldCost);
        totalGoldMinted = totalGoldMinted + 1;
    }

    function BuyDiamondChest() payable public shouldPay(DiamondCost) {
        emit boughtChest(msg.sender, DiamondCost);
        totalDiamondMinted = totalDiamondMinted + 1;
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