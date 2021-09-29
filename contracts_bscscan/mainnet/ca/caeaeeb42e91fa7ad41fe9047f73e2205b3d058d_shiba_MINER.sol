/**
 *Submitted for verification at BscScan.com on 2021-09-29
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

contract shiba_MINER {
    //uint256 SHIBA_PER_MINERS_PER_SECOND=1;
    address shiba = 0x7f986afC963F57eb4b618C889A03930Fe6C2414A; 
    uint256 public SHIBA_TO_HATCH_1MINERS=2592000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedShiba;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketShiba;
    constructor() public{
        ceoAddress=msg.sender;
        ceoAddress2=address(0x810aDB02A1e16E8940A5e4632aCd9AaFAc140f8c);
    }
    function hatchShiba(address ref) public {
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender]=ref;
        }
        uint256 shibaUsed=getMyShiba();
        uint256 newMiners=SafeMath.div(shibaUsed,SHIBA_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedShiba[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral shiba
        claimedShiba[referrals[msg.sender]]=SafeMath.add(claimedShiba[referrals[msg.sender]],SafeMath.div(shibaUsed,7));
        
        //boost market to nerf miners hoarding
        marketShiba=SafeMath.add(marketShiba,SafeMath.div(shibaUsed,5));
    }
    function sellShiba() public {
        require(initialized);
        uint256 hasShiba=getMyShiba();
        uint256 shibValue=calculateShibSell(hasShiba);
        uint256 fee=devFee(shibValue);
        uint256 fee2=fee/2;
        claimedShiba[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketShiba=SafeMath.add(marketShiba,hasShiba);
        ERC20(shiba).transfer(ceoAddress, fee2);
        ERC20(shiba).transfer(ceoAddress2, fee-fee2);
        ERC20(shiba).transfer(address(msg.sender), SafeMath.sub(shibValue,fee));
    }
    function buyShiba(address ref, uint256 amount) public {
        require(initialized);
    
        ERC20(shiba).transferFrom(address(msg.sender), address(this), amount);
        
        uint256 balance = ERC20(shiba).balanceOf(address(this));
        uint256 shibaBought=calculateShibBuy(amount,SafeMath.sub(balance,amount));
        shibaBought=SafeMath.sub(shibaBought,devFee(shibaBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee/2;
        ERC20(shiba).transfer(ceoAddress, fee2);
        ERC20(shiba).transfer(ceoAddress2, fee-fee2);
        claimedShiba[msg.sender]=SafeMath.add(claimedShiba[msg.sender],shibaBought);
        hatchShiba(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateShibSell(uint256 shiba) public view returns(uint256) {
        return calculateTrade(shiba,marketShiba,ERC20(shiba).balanceOf(address(this)));
    }
    function calculateShibBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketShiba);
    }
    function calculateShibBuySimple(uint256 eth) public view returns(uint256){
        return calculateShibBuy(eth,ERC20(shiba).balanceOf(address(this)));
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket(uint256 amount) public {
        ERC20(shiba).transferFrom(address(msg.sender), address(this), amount);
        require(marketShiba==0);
        initialized=true;
        marketShiba=259200000000;
    }
    function getBalance() public view returns(uint256) {
        return ERC20(shiba).balanceOf(address(this));
    }
    function getMyMiners() public view returns(uint256) {
        return hatcheryMiners[msg.sender];
    }
    function getMyShiba() public view returns(uint256) {
        return SafeMath.add(claimedShiba[msg.sender],getShibaSinceLastHatch(msg.sender));
    }
    function getShibaSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(SHIBA_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
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