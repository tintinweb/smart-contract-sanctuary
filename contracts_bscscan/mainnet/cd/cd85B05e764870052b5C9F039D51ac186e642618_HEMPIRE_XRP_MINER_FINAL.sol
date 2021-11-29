/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

/**
 *Website: https://thehempireminegame.live/
*/

pragma solidity ^0.4.26; // solhint-disable-line

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

contract HEMPIRE_XRP_MINER_FINAL {

    address xrp = 0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE;

    uint256 public EGGS_TO_HATCH_1MINERS=1200000;// 7% daily rate
    uint256 TWO_DAYS=172800;// Two days in seconds
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress1;
    address public ceoAddress2;
    address public assocAddress;
    mapping (address => uint256) public invested;// Record how much each user has invested, for the 2000XRP max investment
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    constructor() public{
        ceoAddress1=address(0x29C59636D14a3e3183de005FAB2Ec31716Fc2EA9);
        ceoAddress2=address(0x9c294aEdE77095c9974B0353559734cC64A9a097);
        assocAddress=address(0x9b97F10E328F8c40470eCF8EF95547076FAa1879);
    }
    function compound(address ref) public {
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
    function collect() public {
        require(initialized);

        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        // 5% total fee
        uint256 totalFee=devFee(eggValue);
        // 1% for assoc
        uint256 assocFee=SafeMath.div(totalFee, 5);
        // 2% for each ceo
        uint256 ceofee1=SafeMath.div(SafeMath.mul(totalFee, 2), 5);
        uint256 ceofee2=SafeMath.sub(SafeMath.sub(totalFee, assocFee), ceofee1);

        // 5% buyback fee
        uint256 buyback=buybackFee(eggValue);

        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs, hasEggs);
        ERC20(xrp).transfer(ceoAddress1, ceofee1);
        ERC20(xrp).transfer(ceoAddress2, ceofee2);
        ERC20(xrp).transfer(assocAddress, assocFee);
        // Send amount minus dev and buyback fees
        ERC20(xrp).transfer(address(msg.sender), SafeMath.sub(SafeMath.sub(eggValue,totalFee), buyback));
    }
    function hire(address ref, uint256 amount) public {
        require(initialized);
        require(amount > 24 * (10**18), "Min limit is 25 XRP");

        // Check if the user can invest that much without reaching the 2000 limit
        uint256 totalAmount = SafeMath.add(amount, invested[msg.sender]);
        require(totalAmount < 2001 * (10**18), "Max limit is 2000 XRP");

        ERC20(xrp).transferFrom(address(msg.sender), address(this), amount);
        invested[msg.sender]=SafeMath.add(invested[msg.sender], amount);

        uint256 balance = ERC20(xrp).balanceOf(address(this));
        uint256 eggsBought=calculateEggBuy(amount,SafeMath.sub(balance,amount));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));

        // 5% total fee
        uint256 totalFee=devFee(amount);
        // 1% for assoc
        uint256 assocFee=SafeMath.div(totalFee, 5);
        // 2% for each ceo
        uint256 ceofee1=SafeMath.div(SafeMath.mul(totalFee, 2), 5);
        uint256 ceofee2=SafeMath.sub(SafeMath.sub(totalFee, assocFee), ceofee1);

        ERC20(xrp).transfer(ceoAddress1, ceofee1);
        ERC20(xrp).transfer(ceoAddress2, ceofee2);
        ERC20(xrp).transfer(assocAddress, assocFee);
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
        compound(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketEggs,ERC20(xrp).balanceOf(address(this)));
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,ERC20(xrp).balanceOf(address(this)));
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function buybackFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket(uint256 amount) public {
        ERC20(xrp).transferFrom(address(msg.sender), address(this), amount);
        require(marketEggs==0);
        initialized=true;
        marketEggs=120000000000;
    }
    function getBalance() public view returns(uint256) {
        return ERC20(xrp).balanceOf(address(this));
    }
    function getMyMiners() public view returns(uint256) {
        return hatcheryMiners[msg.sender];
    }
    function getMyEggs() public view returns(uint256) {
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsSinceLastHatch=SafeMath.sub(now, lastHatch[adr]);
        //Miners stop working after two days
        uint256 secondsUpToTwoDays=min(secondsSinceLastHatch, TWO_DAYS);
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,secondsUpToTwoDays);
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