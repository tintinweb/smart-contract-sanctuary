/**
 *Submitted for verification at BscScan.com on 2021-09-30
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

contract pots_MINTER {
    //uint256 pots_PER_MINERS_PER_SECOND=1;
    address pots = 0x3Fcca8648651E5b974DD6d3e50F61567779772A8; 
    uint256 public POTS_TO_BAKE_MINERS=2592000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
    mapping (address => uint256) public potsMiners;
    mapping (address => uint256) public claimedPots;
    mapping (address => uint256) public potsBake;
    mapping (address => address) public referrals;
    uint256 public marketPots;
    constructor() public{
        ceoAddress=msg.sender;
        ceoAddress2=address(0x652Ad4a77EbF1D51E4FBFa6c4EdB93F0a27059Fe);
    }
    function compoundPots(address ref) public {
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender]=ref;
        }
        uint256 PotsUsed=getMyPots();
        uint256 newMiners=SafeMath.div(PotsUsed,POTS_TO_BAKE_MINERS);
        potsMiners[msg.sender]=SafeMath.add(potsMiners[msg.sender],newMiners);
        claimedPots[msg.sender]=0;
        potsBake[msg.sender]=now;
        
        //send referral pot
        claimedPots[referrals[msg.sender]]=SafeMath.add(claimedPots[referrals[msg.sender]],SafeMath.div(PotsUsed,7));
        
        //boost market to nerf miners hoarding
        marketPots=SafeMath.add(marketPots,SafeMath.div(PotsUsed,5));
    }
    function sellPots() public {
        require(initialized);
        uint256 hasPots=getMyPots();
        uint256 potsValue=calculatePotsSell(hasPots);
        uint256 fee=devFee(potsValue);
        uint256 fee2=fee/2;
        claimedPots[msg.sender]=0;
        potsBake[msg.sender]=now;
        marketPots=SafeMath.add(marketPots,hasPots);
        ERC20(pots).transfer(ceoAddress, fee2);
        ERC20(pots).transfer(ceoAddress2, fee-fee2);
        ERC20(pots).transfer(address(msg.sender), SafeMath.sub(potsValue,fee));
    }
    function investPots(address ref, uint256 amount) public {
        require(initialized);
    
        ERC20(pots).transferFrom(address(msg.sender), address(this), amount);
        
        uint256 balance = ERC20(pots).balanceOf(address(this));
        uint256 otsBought=calculatePotsBuy(amount,SafeMath.sub(balance,amount));
        otsBought=SafeMath.sub(otsBought,devFee(otsBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee/2;
        ERC20(pots).transfer(ceoAddress, fee2);
        ERC20(pots).transfer(ceoAddress2, fee-fee2);
        claimedPots[msg.sender]=SafeMath.add(claimedPots[msg.sender],otsBought);
        compoundPots(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculatePotsSell(uint256 pot) public view returns(uint256) {
        return calculateTrade(pot,marketPots,ERC20(pots).balanceOf(address(this)));
    }
    function calculatePotsBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketPots);
    }
    function calculatePotsBuySimple(uint256 eth) public view returns(uint256){
        return calculatePotsBuy(eth,ERC20(pots).balanceOf(address(this)));
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedBlizzard(uint256 amount) public {
        ERC20(pots).transferFrom(address(msg.sender), address(this), amount);
        require(marketPots==0);
        initialized=true;
        marketPots=259200000000;
    }
    function getBalance() public view returns(uint256) {
        return ERC20(pots).balanceOf(address(this));
    }
    function getMyMiners() public view returns(uint256) {
        return potsMiners[msg.sender];
    }
    function getMyPots() public view returns(uint256) {
        return SafeMath.add(claimedPots[msg.sender],etPotsSinceBake(msg.sender));
    }
    function etPotsSinceBake(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(POTS_TO_BAKE_MINERS,SafeMath.sub(now,potsBake[adr]));
        return SafeMath.mul(secondsPassed,potsMiners[adr]);
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