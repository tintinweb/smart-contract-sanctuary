pragma solidity ^0.4.18; // solhint-disable-line

// similar to the original shrimper , with these changes:
// 0. already initialized
// 1. the "free" 1000 YouTubes cost 0.001 eth (in line with the mining fee)
// 2. Coming to http://CraigGrantShrimper.surge.sh
// 3. bots should have a harder time, and whales can compete for the devfee

contract CraigGrantShrimper{
    string public name = "CraigGrantShrimper";
	string public symbol = "CGshrimper";
    //uint256 subscribers_PER_CraigGrant_PER_SECOND=1;
    uint256 public subscribers_TO_HATCH_1CraigGrant=86400;//for final version should be seconds in a day
    uint256 public STARTING_CraigGrant=1000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=true;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryCraigGrant;
    mapping (address => uint256) public claimedsubscribers;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketsubscribers = 1000000000;
    uint256 public YouTubemasterReq=100000;
    
    function CraigGrantShrimper() public{
        ceoAddress=msg.sender;
    }
    modifier onlyCEO(){
		require(msg.sender == ceoAddress );
		_;
	}
    function becomeYouTubemaster() public{
        require(initialized);
        require(hatcheryCraigGrant[msg.sender]>=YouTubemasterReq);
        hatcheryCraigGrant[msg.sender]=SafeMath.sub(hatcheryCraigGrant[msg.sender],YouTubemasterReq);
        YouTubemasterReq=SafeMath.add(YouTubemasterReq,100000);//+100k CraigGrants each time
        ceoAddress=msg.sender;
    }
    function hatchsubscribers(address ref) public{
        require(initialized);
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 subscribersUsed=getMysubscribers();
        uint256 newCraigGrant=SafeMath.div(subscribersUsed,subscribers_TO_HATCH_1CraigGrant);
        hatcheryCraigGrant[msg.sender]=SafeMath.add(hatcheryCraigGrant[msg.sender],newCraigGrant);
        claimedsubscribers[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral subscribers
        claimedsubscribers[referrals[msg.sender]]=SafeMath.add(claimedsubscribers[referrals[msg.sender]],SafeMath.div(subscribersUsed,5));
        
        //boost market to nerf CraigGrant hoarding
        marketsubscribers=SafeMath.add(marketsubscribers,SafeMath.div(subscribersUsed,10));
    }
    function sellsubscribers() public{
        require(initialized);
        uint256 hassubscribers=getMysubscribers();
        uint256 eggValue=calculatesubscribersell(hassubscribers);
        uint256 fee=devFee(eggValue);
        claimedsubscribers[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketsubscribers=SafeMath.add(marketsubscribers,hassubscribers);
        ceoAddress.transfer(fee);
    }
    function buysubscribers() public payable{
        require(initialized);
        uint256 subscribersBought=calculateEggBuy(msg.value,SafeMath.sub(this.balance,msg.value));
        subscribersBought=SafeMath.sub(subscribersBought,devFee(subscribersBought));
        ceoAddress.transfer(devFee(msg.value));
        claimedsubscribers[msg.sender]=SafeMath.add(claimedsubscribers[msg.sender],subscribersBought);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculatesubscribersell(uint256 subscribers) public view returns(uint256){
        return calculateTrade(subscribers,marketsubscribers,this.balance);
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketsubscribers);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,this.balance);
    }
    function devFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,4),100);
    }
    function seedMarket(uint256 subscribers) public payable{
        require(marketsubscribers==0);
        initialized=true;
        marketsubscribers=subscribers;
    }
    function getFreeCraigGrant() public payable{
        require(initialized);
        require(msg.value==0.001 ether); //similar to mining fee, prevents bots
        ceoAddress.transfer(msg.value); //YouTubemaster gets this entrance fee
        require(hatcheryCraigGrant[msg.sender]==0);
        lastHatch[msg.sender]=now;
        hatcheryCraigGrant[msg.sender]=STARTING_CraigGrant;
    }
    function getBalance() public view returns(uint256){
        return this.balance;
    }
    function getMyCraigGrant() public view returns(uint256){
        return hatcheryCraigGrant[msg.sender];
    }
    function getYouTubemasterReq() public view returns(uint256){
        return YouTubemasterReq;
    }
    function getMysubscribers() public view returns(uint256){
        return SafeMath.add(claimedsubscribers[msg.sender],getsubscribersSinceLastHatch(msg.sender));
    }
    function getsubscribersSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(subscribers_TO_HATCH_1CraigGrant,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryCraigGrant[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    function transferOwnership() onlyCEO public {
		uint256 etherBalance = this.balance;
		ceoAddress.transfer(etherBalance);
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