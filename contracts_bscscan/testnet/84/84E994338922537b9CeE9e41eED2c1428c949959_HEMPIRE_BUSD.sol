/**
 *Website: https://Thehempiregame.com
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

contract HEMPIRE_BUSD {
    // address busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address busd = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
    uint256 public EGGS_TO_HATCH_1MINERS=864000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
    address public ceoAddress3;
    address public ceoAddress4;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    constructor() public{
        ceoAddress=msg.sender;
        ceoAddress2=address(0x6eA7126f89ccc1567b0a9508de6D0Fae379ac337);
        ceoAddress3=address(0x9c294aEdE77095c9974B0353559734cC64A9a097);
        ceoAddress4=address(0x70302cDc3498E5021cD0EE722064dc278E46001b);
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
        uint256 fee=devFee(eggValue);
        uint256 devfee=SafeMath.div(SafeMath.mul(fee, 1),5);
        uint256 ceofee=SafeMath.div(SafeMath.mul(fee, 2),5);
        uint256 ceofee1=SafeMath.div(SafeMath.mul(fee, 1),5);
        uint256 ceofee2=SafeMath.div(SafeMath.mul(fee, 1),5);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        ERC20(busd).transfer(ceoAddress, devfee);
        ERC20(busd).transfer(ceoAddress2, ceofee);
        ERC20(busd).transfer(ceoAddress3, ceofee1);
        ERC20(busd).transfer(ceoAddress4, ceofee2);
        ERC20(busd).transfer(address(msg.sender), SafeMath.sub(eggValue,fee));
    }
    function hire(address ref, uint256 amount) public {
        require(initialized);
        require(amount >= 2000, "Max limit is 2000");
        require(amount <= 25, "Min limit is 25");
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        
        uint256 balance = ERC20(busd).balanceOf(address(this));
        uint256 eggsBought=calculateEggBuy(amount,SafeMath.sub(balance,amount));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(amount);
        uint256 devfee=SafeMath.div(SafeMath.mul(fee, 1),5);
        uint256 ceofee=SafeMath.div(SafeMath.mul(fee, 2),5);
        uint256 ceofee1=SafeMath.div(SafeMath.mul(fee, 1),5);
        uint256 ceofee2=SafeMath.div(SafeMath.mul(fee, 1),5);
        ERC20(busd).transfer(ceoAddress, devfee);
        ERC20(busd).transfer(ceoAddress2, ceofee);
        ERC20(busd).transfer(ceoAddress3, ceofee1);
        ERC20(busd).transfer(ceoAddress4, ceofee2);
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
        compound(ref);
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
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket(uint256 amount) public {
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        require(marketEggs==0);
        initialized=true;
        marketEggs=86400000000;
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
    function setCEOAddress2(address _ceo2) public {
        require(msg.sender == ceoAddress, "Ownable: caller is not the owner");
        ceoAddress2 = _ceo2;
    }
    function setCEOAddress3(address _ceo3) public {
        require(msg.sender == ceoAddress, "Ownable: caller is not the owner");
        ceoAddress3 = _ceo3;
    }
    function setCEOAddress4(address _ceo4) public {
        require(msg.sender == ceoAddress, "Ownable: caller is not the owner");
        ceoAddress4 = _ceo4;
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