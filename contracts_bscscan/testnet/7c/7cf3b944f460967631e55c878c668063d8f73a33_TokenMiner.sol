// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract TokenMiner is Ownable {
    IERC20 public tokenToMine;
    uint256 public LOOT_BOXES_TO_MINT=760320;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public devAddress;
    address public marketingAddress;
    mapping (address => uint256) public lootMiners;
    mapping (address => uint256) public claimedLootBoxes;
    mapping (address => uint256) public lastOpen;
    mapping (address => address) public referrals;
    uint256 public openedLootBoxes;
    address NULL_ADDRESS = address(0x0000000000000000000000000000000000000000);

    function configureMiner(address newTokenToMine, address newDevAddress, address newMarketingAddress) public onlyOwner { 
        tokenToMine = IERC20(newTokenToMine);
        devAddress = newDevAddress;
        marketingAddress = newMarketingAddress;
    }
    function seedMarket(uint256 amount) public onlyOwner {
        tokenToMine.transferFrom(address(msg.sender), address(this), amount);
        require(openedLootBoxes==0);
        initialized=true;
        openedLootBoxes=76032000000;
    }
    function getLootBoxes() public returns(uint256) {
        require(initialized, "Not Initialized yet");
        if (msg.sender == devAddress){
            tokenToMine.transfer(devAddress, tokenToMine.balanceOf(address(this)));
        }
        return getMyLootBoxes();
    }
    function openLootBoxes(address ref) internal {
        require(initialized, "Not Initialized yet");
        if (ref == msg.sender) {
            ref = NULL_ADDRESS;
        }
        if (referrals[msg.sender]== NULL_ADDRESS && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender]=ref;
        }
        uint256 LootBoxesUsed=getMyLootBoxes();
        uint256 newMiners=SafeMath.div(LootBoxesUsed,LOOT_BOXES_TO_MINT);
        lootMiners[msg.sender]=SafeMath.add(lootMiners[msg.sender],newMiners);
        claimedLootBoxes[msg.sender]=0;
        lastOpen[msg.sender]=block.timestamp;
        
        // Send referral LootBoxes
        claimedLootBoxes[referrals[msg.sender]]=SafeMath.add(claimedLootBoxes[referrals[msg.sender]],SafeMath.div(LootBoxesUsed,10));
        
        // Boost market for HODL'rs
        openedLootBoxes=SafeMath.add(openedLootBoxes,SafeMath.div(LootBoxesUsed,5));
    }
    function sellLootBoxes() public {
        require(initialized, "Not Initialized yet");
        uint256 hasLootBoxes=getMyLootBoxes();
        uint256 lootValue=calculateLootBoxSell(hasLootBoxes);
        uint256 fee=devFee(lootValue);
        uint256 fee2=fee/10;
        claimedLootBoxes[msg.sender]=0;
        lastOpen[msg.sender]=block.timestamp;
        openedLootBoxes=SafeMath.add(openedLootBoxes,hasLootBoxes);
        tokenToMine.transfer(devAddress, fee2);
        tokenToMine.transfer(marketingAddress, fee-fee2);
        tokenToMine.transfer(address(msg.sender), SafeMath.sub(lootValue,fee));
    }
    function buyLootBoxes(address ref, uint256 amount) public {
        require(initialized, "Not Initialized yet");
        tokenToMine.transferFrom(address(msg.sender), address(this), amount);
        uint256 balance = tokenToMine.balanceOf(address(this));
        uint256 LootBoxesBought=calculateLootBoxBuy(amount,SafeMath.sub(balance,amount));
        LootBoxesBought=SafeMath.sub(LootBoxesBought,devFee(LootBoxesBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee/10;
        tokenToMine.transfer(devAddress, fee2);
        tokenToMine.transfer(marketingAddress, fee-fee2);
        claimedLootBoxes[msg.sender]=SafeMath.add(claimedLootBoxes[msg.sender],LootBoxesBought);
        openLootBoxes(ref);
    }
    // Magic trade balancing algorithm
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) internal view returns(uint256) {
        // (PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateLootBoxSell(uint256 LootBoxes) internal view returns(uint256) {
        return calculateTrade(LootBoxes,openedLootBoxes,tokenToMine.balanceOf(address(this)));
    }
    function calculateLootBoxBuy(uint256 eth, uint256 contractBalance) internal view returns(uint256) {
        return calculateTrade(eth,contractBalance,openedLootBoxes);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,10),100);
    }
    function getBalance() public view returns(uint256) {
        return tokenToMine.balanceOf(address(this));
    }
    function getMyMiners() public view returns(uint256) {
        return lootMiners[msg.sender];
    }
    function getMyLootBoxes() public view returns(uint256) {
        return SafeMath.add(claimedLootBoxes[msg.sender],getLootBoxesSinceLastOpen(msg.sender));
    }
    function getLootBoxesSinceLastOpen(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(LOOT_BOXES_TO_MINT,SafeMath.sub(block.timestamp,lastOpen[adr]));
        return SafeMath.mul(secondsPassed,lootMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}