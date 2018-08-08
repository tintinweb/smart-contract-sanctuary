pragma solidity ^0.4.24; 

// similar as shrimpfarmer, with two changes:
// A. half of your plumbers leave when you sell pooh
// B. the "free" 100 plumber cost 0.001 eth (in line with the mining fee)

// bots should have a harder time

contract PlumberCollector{
    uint256 public POOH_TO_CALL_1PLUMBER=86400;//for final version should be seconds in a day
    uint256 public STARTING_POOH=100;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryPlumber;
    mapping (address => uint256) public claimedPoohs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketPoohs;
   

    constructor() public
    {
        ceoAddress=msg.sender;
    }

    function hatchPoohs(address ref) public
    {
        require(initialized);
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender)
        {
            referrals[msg.sender]=ref;
        }
        uint256 poohsUsed=getMyPoohs();
        uint256 newPlumber=SafeMath.div(poohsUsed,POOH_TO_CALL_1PLUMBER);
        hatcheryPlumber[msg.sender]=SafeMath.add(hatcheryPlumber[msg.sender],newPlumber);
        claimedPoohs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral poohs
        claimedPoohs[referrals[msg.sender]]=SafeMath.add(claimedPoohs[referrals[msg.sender]],SafeMath.div(poohsUsed,5));
        
        //boost market to nerf pooh hoarding
        marketPoohs=SafeMath.add(marketPoohs,SafeMath.div(poohsUsed,10));
    }

    function sellPoohs() public{
        require(initialized);
        uint256 hasPoohs=getMyPoohs();
        uint256 poohValue=calculatePoohSell(hasPoohs);
        uint256 fee=devFee(poohValue);
        // kill one half of the owner&#39;s snails on egg sale
        hatcheryPlumber[msg.sender] = SafeMath.div(hatcheryPlumber[msg.sender],2);
        claimedPoohs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketPoohs=SafeMath.add(marketPoohs,hasPoohs);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(poohValue,fee));
    }

    function buyPoohs() public payable
    {
        require(initialized);
        uint256 poohsBought=calculatePoohBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        poohsBought=SafeMath.sub(poohsBought,devFee(poohsBought));
        ceoAddress.transfer(devFee(msg.value));
        claimedPoohs[msg.sender]=SafeMath.add(claimedPoohs[msg.sender],poohsBought);
    }

    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256)
    {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    function calculatePoohSell(uint256 poohs) public view returns(uint256)
    {
        return calculateTrade(poohs,marketPoohs,address(this).balance);
    }

    function calculatePoohBuy(uint256 eth,uint256 contractBalance) public view returns(uint256)
    {
        return calculateTrade(eth,contractBalance,marketPoohs);
    }

    function calculatePoohBuySimple(uint256 eth) public view returns(uint256)
    {
        return calculatePoohBuy(eth, address(this).balance);
    }

    function devFee(uint256 amount) public pure returns(uint256)
    {
        // 5% devFee
        return SafeMath.div(amount,20);
    }

    function seedMarket(uint256 poohs) public payable
    {
        require(marketPoohs==0);
        initialized=true;
        marketPoohs=poohs;
    }

    function getFreePlumber() public payable
    {
        require(initialized);
        require(msg.value==0.001 ether); //similar to mining fee, prevents bots
        ceoAddress.transfer(msg.value); //ceo gets this entrance fee
        require(hatcheryPlumber[msg.sender]==0);
        lastHatch[msg.sender]=now;
        hatcheryPlumber[msg.sender]=STARTING_POOH;
    }

    function getBalance() public view returns(uint256)
    {
        return address(this).balance;
    }

    function getMyPlumbers() public view returns(uint256)
    {
        return hatcheryPlumber[msg.sender];
    }

    

    function getMyPoohs() public view returns(uint256)
    {
        return SafeMath.add(claimedPoohs[msg.sender],getPoohsSinceLastHatch(msg.sender));
    }

    function getPoohsSinceLastHatch(address adr) public view returns(uint256)
    {
        uint256 secondsPassed=min(POOH_TO_CALL_1PLUMBER,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryPlumber[adr]);
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