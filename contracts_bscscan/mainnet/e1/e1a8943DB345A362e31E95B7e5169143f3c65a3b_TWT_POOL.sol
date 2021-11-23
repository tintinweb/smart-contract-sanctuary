/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

/**
 
 *Website: https://BscPools.Finance
 * Idle Game Crypto - TWT +3% Daily 
 Short Desc :  Just play idle game with some token , Player can get income every second .

 [ Game Play ] 
 1. Approve Token
 2. Hire Miner
 3. COMPOUND VS CLAIM 
 4. WIN AS YOU CAN! 

 [ PVP MODE based on Blockchain ]
  ** The mining efficiency rate rises and falls as you and other players hire miners, compound earnigs and claiming
  ** The object of the game is hiring more miners, sooner and more often than other players.
  ** WINNER is everyone who make a good position when Compound & Claim
 
 [ Strategy & Risk ]
based on the market's behavior and your strategy ~ your miner's value can be higher, so you earn more, but the opposite also can happen and your miner's value and your daily return will go down.
Remember that the contract works at its own, based on the market behavior, so we don't have any power to increase or lower the rewards.
Never invest more than you can afford to lose and do your research before risking your assets on this or any other dapp.


 [ Contract % ] 
 * 77% ALL REWARDS POOLS  ( Player Pool Rewards can be higher or lower )
 * 3% Player Rewards  ( Pays a modest 3% daily, allowing investors to rest easy knowing that their investments have unlimited growth potential and a maximum, improbable risk of less than 3%. )
 * 10% Affiliate Rewards ( Saved in contract ! not directly - Allowed to withdraw & Compound from UI web)
 * 2% Developers team ( Developer next feature )
 * 3% Marketing Fee ( Ads Network & Bounty Rewards to all player )
 * 5% Pool Token Buy Back  ~  BSCPOOLS ( POOL ) TOKEN Contract : 0x12B994876FE6b700AeB39Eb988e84eD2AD6C35CD 
 
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

contract TWT_POOL {
    address busd = 0x4b0f1812e5df2a09796481ff14017e6005508003; 
    uint256 public EGGS_TO_HATCH_1MINERS=2592000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    constructor() public{
        ceoAddress=msg.sender;
        ceoAddress2=address(0xe29cAb81Ab59803a80e2eD23084d5e841dD5E3A0);
    }
    function hatchEggs(address ref) public {
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMyEggs();
        uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral eggs
        claimedEggs[referrals[msg.sender]]=SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,10));
        
        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,5));
    }
    function sellEggs() public {
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        uint256 fee2=fee/2;
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        ERC20(busd).transfer(ceoAddress, fee2);
        ERC20(busd).transfer(ceoAddress2, fee-fee2);
        ERC20(busd).transfer(address(msg.sender), SafeMath.sub(eggValue,fee));
    }
    function buyEggs(address ref, uint256 amount) public {
        require(initialized);
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        uint256 balance = ERC20(busd).balanceOf(address(this));
        uint256 eggsBought=calculateEggBuy(amount,SafeMath.sub(balance,amount));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee/2;
        ERC20(busd).transfer(ceoAddress, fee2);
        ERC20(busd).transfer(ceoAddress2, fee-fee2);
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
        hatchEggs(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketEggs,ERC20(busd).balanceOf(address(this)));
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,ERC20(busd).balanceOf(address(this)));
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,20),100);
    }
    function seedMarket(uint256 amount) public {
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        require(marketEggs==0);
        initialized=true;
        marketEggs=259200000000;
    }
    function getBalance() public view returns(uint256) {
        return ERC20(busd).balanceOf(address(this));
    }
    function getMyMiners() public view returns(uint256) {
        return hatcheryMiners[msg.sender];
    }
    function getMyEggs() public view returns(uint256) {
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}