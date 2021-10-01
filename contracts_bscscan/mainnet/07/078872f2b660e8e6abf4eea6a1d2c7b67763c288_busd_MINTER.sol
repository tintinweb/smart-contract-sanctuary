/**
 *Submitted for verification at BscScan.com on 2021-10-01
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

contract busd_MINTER {
    //uint256 BUSD_PER_MINERS_PER_SECOND=1;
    address busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; 
    uint256 public BUSD_TO_HATCH_1MINERS=2592000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
    mapping (address => uint256) public busdMiners;
    mapping (address => uint256) public claimedBusd;
    mapping (address => uint256) public busdBake;
    mapping (address => address) public referrals;
    uint256 public marketBusd;
    constructor() public{
        ceoAddress=msg.sender;
        ceoAddress2=address(0x652Ad4a77EbF1D51E4FBFa6c4EdB93F0a27059Fe);
    }
    function hatchBusd(address ref) public {
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender]=ref;
        }
        uint256 usedBusd=getMyBusd();
        uint256 newMiners=SafeMath.div(usedBusd,BUSD_TO_HATCH_1MINERS);
        busdMiners[msg.sender]=SafeMath.add(busdMiners[msg.sender],newMiners);
        claimedBusd[msg.sender]=0;
        busdBake[msg.sender]=now;
        
        //send referral busd
        claimedBusd[referrals[msg.sender]]=SafeMath.add(claimedBusd[referrals[msg.sender]],SafeMath.div(usedBusd,7));
        
        //boost market to nerf miners hoarding
        marketBusd=SafeMath.add(marketBusd,SafeMath.div(usedBusd,5));
    }
    function sellBusd() public {
        require(initialized);
        uint256 hasBusd=getMyBusd();
        uint256 busdValue=calculateBusdSell(hasBusd);
        uint256 fee=devFee(busdValue);
        uint256 fee2=fee/2;
        claimedBusd[msg.sender]=0;
        busdBake[msg.sender]=now;
        marketBusd=SafeMath.add(marketBusd,hasBusd);
        ERC20(busd).transfer(ceoAddress, fee2);
        ERC20(busd).transfer(ceoAddress2, fee-fee2);
        ERC20(busd).transfer(address(msg.sender), SafeMath.sub(busdValue,fee));
    }
    function buyBusd(address ref, uint256 amount) public {
        require(initialized);
    
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        
        uint256 balance = ERC20(busd).balanceOf(address(this));
        uint256 busdBought=calculateBusdBuy(amount,SafeMath.sub(balance,amount));
        busdBought=SafeMath.sub(busdBought,devFee(busdBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee/2;
        ERC20(busd).transfer(ceoAddress, fee2);
        ERC20(busd).transfer(ceoAddress2, fee-fee2);
        claimedBusd[msg.sender]=SafeMath.add(claimedBusd[msg.sender],busdBought);
        hatchBusd(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateBusdSell(uint256 busds) public view returns(uint256) {
        return calculateTrade(busds,marketBusd,ERC20(busd).balanceOf(address(this)));
    }
    function calculateBusdBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketBusd);
    }
    function calculateBusdBuySimple(uint256 eth) public view returns(uint256){
        return calculateBusdBuy(eth,ERC20(busd).balanceOf(address(this)));
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket(uint256 amount) public {
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        require(marketBusd==0);
        initialized=true;
        marketBusd=259200000000;
    }
    function getBalance() public view returns(uint256) {
        return ERC20(busd).balanceOf(address(this));
    }
    function getMyMiners() public view returns(uint256) {
        return busdMiners[msg.sender];
    }
    function getMyBusd() public view returns(uint256) {
        return SafeMath.add(claimedBusd[msg.sender],getBusdSinceBake(msg.sender));
    }
    function getBusdSinceBake(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(BUSD_TO_HATCH_1MINERS,SafeMath.sub(now,busdBake[adr]));
        return SafeMath.mul(secondsPassed,busdMiners[adr]);
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