/**
 *Submitted for verification at BscScan.com on 2021-09-26
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

contract cake_MINTER {
    //uint256 CAKE_PER_MINERS_PER_SECOND=1;
    address cakes = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee; 
    uint256 public CAKE_TO_BAKE_MINERS=2592000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
    mapping (address => uint256) public cakeMiners;
    mapping (address => uint256) public claimedCake;
    mapping (address => uint256) public cakeBake;
    mapping (address => address) public referrals;
    uint256 public marketCake;
    constructor() public{
        ceoAddress=msg.sender;
        ceoAddress2=address(0x652Ad4a77EbF1D51E4FBFa6c4EdB93F0a27059Fe);
    }
    function compoundCake(address ref) public {
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender]=ref;
        }
        uint256 cakeUsed=getMyCake();
        uint256 newMiners=SafeMath.div(cakeUsed,CAKE_TO_BAKE_MINERS);
        cakeMiners[msg.sender]=SafeMath.add(cakeMiners[msg.sender],newMiners);
        claimedCake[msg.sender]=0;
        cakeBake[msg.sender]=now;
        
        //send referral cake
        claimedCake[referrals[msg.sender]]=SafeMath.add(claimedCake[referrals[msg.sender]],SafeMath.div(cakeUsed,7));
        
        //boost market to nerf miners hoarding
        marketCake=SafeMath.add(marketCake,SafeMath.div(cakeUsed,5));
    }
    function sellCake() public {
        require(initialized);
        uint256 hasCake=getMyCake();
        uint256 cakeValue=calculateCakeSell(hasCake);
        uint256 fee=devFee(cakeValue);
        uint256 fee2=fee/2;
        claimedCake[msg.sender]=0;
        cakeBake[msg.sender]=now;
        marketCake=SafeMath.add(marketCake,hasCake);
        ERC20(cakes).transfer(ceoAddress, fee2);
        ERC20(cakes).transfer(ceoAddress2, fee-fee2);
        ERC20(cakes).transfer(address(msg.sender), SafeMath.sub(cakeValue,fee));
    }
    function investCake(address ref, uint256 amount) public {
        require(initialized);
    
        ERC20(cakes).transferFrom(address(msg.sender), address(this), amount);
        
        uint256 balance = ERC20(cakes).balanceOf(address(this));
        uint256 cakeBought=calculateCakeBuy(amount,SafeMath.sub(balance,amount));
        cakeBought=SafeMath.sub(cakeBought,devFee(cakeBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee/2;
        ERC20(cakes).transfer(ceoAddress, fee2);
        ERC20(cakes).transfer(ceoAddress2, fee-fee2);
        claimedCake[msg.sender]=SafeMath.add(claimedCake[msg.sender],cakeBought);
        compoundCake(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateCakeSell(uint256 cake) public view returns(uint256) {
        return calculateTrade(cake,marketCake,ERC20(cakes).balanceOf(address(this)));
    }
    function calculateCakeBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketCake);
    }
    function calculateCakeBuySimple(uint256 eth) public view returns(uint256){
        return calculateCakeBuy(eth,ERC20(cakes).balanceOf(address(this)));
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedCake(uint256 amount) public {
        ERC20(cakes).transferFrom(address(msg.sender), address(this), amount);
        require(marketCake==0);
        initialized=true;
        marketCake=259200000000;
    }
    function getBalance() public view returns(uint256) {
        return ERC20(cakes).balanceOf(address(this));
    }
    function getMyMiners() public view returns(uint256) {
        return cakeMiners[msg.sender];
    }
    function getMyCake() public view returns(uint256) {
        return SafeMath.add(claimedCake[msg.sender],getCakeSinceBake(msg.sender));
    }
    function getCakeSinceBake(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(CAKE_TO_BAKE_MINERS,SafeMath.sub(now,cakeBake[adr]));
        return SafeMath.mul(secondsPassed,cakeMiners[adr]);
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