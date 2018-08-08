pragma solidity ^0.4.18; 

// similar as other games, with two changes:
// A. half of your kebabs expiry date is over when you sell them so they are thrown away
// B. the "free" 150 initial cost 0.001 eth (in line with the mining fee)

// bots should have a harder time

contract EtherKebab{
    uint256 public KEBABER_TO_MAKE_1KEBAB=86400;//for final version should be seconds in a day
    uint256 public STARTING_KEBAB=150;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress = 0xdf4703369ecE603a01e049e34e438ff74Cd96D66;
    uint public ceoEtherBalance;
    mapping (address => uint256) public workingKebaber;
    mapping (address => uint256) public claimedKebabs;
    mapping (address => uint256) public lastKebab;
    mapping (address => address) public referrals;
    uint256 public marketKebabs;
   
    function makeKebabs(address ref) public
    {
        require(initialized);
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender)
        {
            referrals[msg.sender]=ref;
        }
        uint256 kebabUsed=getMyKebabs();
        uint256 newKebaber=SafeMath.div(kebabUsed,KEBABER_TO_MAKE_1KEBAB);
        workingKebaber[msg.sender]=SafeMath.add(workingKebaber[msg.sender],newKebaber);
        claimedKebabs[msg.sender]=0;
        lastKebab[msg.sender]=now;
        
        //send referral kebab
        claimedKebabs[referrals[msg.sender]]=SafeMath.add(claimedKebabs[referrals[msg.sender]],SafeMath.div(kebabUsed,5));
        
        //boost market to nerf shrimp hoarding
        marketKebabs=SafeMath.add(marketKebabs,SafeMath.div(kebabUsed,10));
    }

    function sellKebabs() public{
        require(initialized);
        uint256 hasKebabs=getMyKebabs();
        uint256 kebabValue=calculateKebabSell(hasKebabs);
        uint256 fee=calculatePercentage(kebabValue,10);
        // kill one half of the owner&#39;s snails on egg sale
        workingKebaber[msg.sender] = SafeMath.div(workingKebaber[msg.sender],2);
        claimedKebabs[msg.sender]=0;
        lastKebab[msg.sender]=now;
        marketKebabs=SafeMath.add(marketKebabs,hasKebabs);
        ceoEtherBalance+=fee;
        msg.sender.transfer(SafeMath.sub(kebabValue,fee));
    }

    function buyKebabs() public payable
    {
        require(initialized);
        uint256 kebabBought=calculateKebabBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        kebabBought=SafeMath.sub(kebabBought,calculatePercentage(kebabBought,10));
        ceoEtherBalance+=calculatePercentage(msg.value, 10);
        claimedKebabs[msg.sender]=SafeMath.add(claimedKebabs[msg.sender],kebabBought);
    }

    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256)
    {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    function calculateKebabSell(uint256 kebab) public view returns(uint256)
    {
        return calculateTrade(kebab,marketKebabs,address(this).balance);
    }

    function calculateKebabBuy(uint256 eth,uint256 contractBalance) public view returns(uint256)
    {
        return calculateTrade(eth,contractBalance,marketKebabs);
    }

    function calculateKebabBuySimple(uint256 eth) public view returns(uint256)
    {
        return calculateKebabBuy(eth, address(this).balance);
    }

    function calculatePercentage(uint256 amount, uint percentage) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,percentage),100);
    }

    function seedMarket(uint256 kebab) public payable
    {
        require(marketKebabs==0);
        initialized=true;
        marketKebabs=kebab;
    }

    function getFreeKebaber() public payable
    {
        require(initialized);
        require(msg.value==0.001 ether); //similar to mining fee, prevents bots
        ceoEtherBalance+=msg.value; //ceo gets this entrance fee
        require(workingKebaber[msg.sender]==0);
        lastKebab[msg.sender]=now;
        workingKebaber[msg.sender]=STARTING_KEBAB;
    }

    function getBalance() public view returns(uint256)
    {
        return address(this).balance;
    }

    function getMyKebabers() public view returns(uint256)
    {
        return workingKebaber[msg.sender];
    }

    function withDrawMoney() public { //to prevent fee to get fee
        require(msg.sender == ceoAddress);
        uint256 myBalance = ceoEtherBalance;
        ceoEtherBalance = ceoEtherBalance - myBalance;
        ceoAddress.transfer(myBalance);
    }

    function getMyKebabs() public view returns(uint256)
    {
        return SafeMath.add(claimedKebabs[msg.sender],getKebabsSincelastKebab(msg.sender));
    }

    function getKebabsSincelastKebab(address adr) public view returns(uint256)
    {
        uint256 secondsPassed=min(KEBABER_TO_MAKE_1KEBAB,SafeMath.sub(now,lastKebab[adr]));
        return SafeMath.mul(secondsPassed,workingKebaber[adr]);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) 
    {
        return a < b ? a : b;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    if (a == 0) 
    {
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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