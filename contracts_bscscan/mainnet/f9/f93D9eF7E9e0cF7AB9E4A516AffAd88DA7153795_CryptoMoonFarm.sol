/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT
// @file CMF_BUSD.sol
// @CA: 0xf93D9eF7E9e0cF7AB9E4A516AffAd88DA7153795
/* 
 *
 *   https://busd.cryptomoon.farm/
 *   https://t.me/CryptoMoonFarm
 *   The newest high-yield experimental crypto farm game!
 *
 *   [USAGE INSTRUCTION]
 *   1) Connect any BSC(token) supported wallet
 *   2) Approve token and buy Farmers
 *   3) Wait for Farmers to farm CMF
 *   4) Compound or Collect your BUSD!
 *
 *   [REFERRALS]
 *   - 10% Direct Referral Commission
 *
 */

pragma solidity ^0.4.26;

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract CryptoMoonFarm {

    using SafeMath for uint256;
    
    bool public initialized = false;
    ERC20 token = ERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // BUSD
    uint256 public EGGS_TO_HATCH_1MINERS = 15 days;
    address public ceoAddress;
    address public partner1;
    address public partner2;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    constructor() public{
        ceoAddress = msg.sender;
        partner1 = 0x86372cbD95f15C23809604193C5472eB5A52ac81;
        partner2 = 0x9b97F10E328F8c40470eCF8EF95547076FAa1879;
    }
    function hatchEggs(address ref) public {
        require(initialized);
        if(referrals[msg.sender] == address(0) && ref != msg.sender && ref != address(0)){
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newMiners = eggsUsed.div(EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender] = hatcheryMiners[msg.sender].add(newMiners);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        
        //send referral eggs | avoid null address
        if(referrals[msg.sender] != address(0)) {
            claimedEggs[referrals[msg.sender]] = claimedEggs[referrals[msg.sender]].add(eggsUsed.div(10));
        }
        
        //boost market to nerf miners hoarding
        marketEggs = marketEggs.add(eggsUsed.div(5));
    }
    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        uint256 fee1 = fee.mul(10).div(100); // partnership
        uint256 fee2 = fee.mul(25).div(100); // partnership
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketEggs = marketEggs.add(hasEggs);
        token.transfer(ceoAddress, fee.sub(fee1).sub(fee2));
        token.transfer(partner1, fee1);
        token.transfer(partner2, fee2);
        token.transfer(address(msg.sender), eggValue.sub(fee));
    }
    function buyEggs(address ref, uint256 amount) public payable {
        require(initialized);
        token.transferFrom(address(msg.sender), address(this), amount);
        uint256 balance = getBalance();
        uint256 eggsBought = calculateEggBuy(amount, balance.sub(amount));
        eggsBought = eggsBought.sub(devFee(eggsBought));
        uint256 fee = devFee(amount);
        uint256 fee1 = fee.mul(10).div(100); // partnership
        uint256 fee2 = fee.mul(25).div(100); // partnership
        token.transfer(ceoAddress, fee.sub(fee1).sub(fee2));
        token.transfer(partner1, fee1);
        token.transfer(partner2, fee2);
        // @dev fix compound bug
        // temporarily collect current eggs as we will not compound them
        uint256 unclaimed = getMyEggs();
        // hatch only bought eggs
        lastHatch[msg.sender] = block.timestamp;
        claimedEggs[msg.sender] = eggsBought;
        hatchEggs(ref);
        // return collected eggs
        claimedEggs[msg.sender] = unclaimed;
    }
    // magic trade balancing algorithm
    // @dev simplify equation
    // @src https://cryptozoa.com/crypto-idle-games-the-high-risk-high-return-ponzi-like-fringe-of-crypto-gaming-fe48046b971c
    function calculateTrade(uint256 a, uint256 b, uint256 c) public pure returns (uint256) {
        return a.mul(c).div(a.add(b));
    }
    function calculateEggSell(uint256 eggs) public view returns (uint256) {
        return calculateTrade(eggs, marketEggs, getBalance());
    }
    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns (uint256) {
        return calculateEggBuy(eth, getBalance());
    }
    function devFee(uint256 amount) public pure returns (uint256) {
        return amount.mul(5).div(100);
    }
    function seedMarket() public payable {
        require(marketEggs == 0 && msg.sender == ceoAddress);
        initialized = true;
        marketEggs = 129600000000;
    }
    function getBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    function getMyMiners() public view returns (uint256) {
        return hatcheryMiners[msg.sender];
    }
    function getMyEggs() public view returns (uint256) {
        return claimedEggs[msg.sender].add(getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address addr) public view returns (uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1MINERS, block.timestamp.sub(lastHatch[addr]));
        return secondsPassed.mul(hatcheryMiners[addr]);
    }
    function getLastHatch(address addr) public view returns (uint256) {
        return lastHatch[addr];
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}