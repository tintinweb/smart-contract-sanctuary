pragma solidity ^0.4.24;

/* You&#39;ve seen all of this before. Here are the differences.

// A. A quarter of your clones die when you sell ideas. Market saturation, y&#39;see?
// B. You can "become" Norsefire and take the dev fees, since he&#39;s involved in everything.
// B. 1. The Norsefire boon is a hot potato. If someone else buys it off you, you profit.
// B. 2. When Norsefire flips, we actually send him 5% of the increase. You receive 50%, the contract receives the other 45%.
// C. You get your &#39;free&#39; clones for 0.00232 Ether, because throwbaaaaaack.
// D. Referral rates have been dropped to 5% instead of 20%. The referral target must have bought in.
// E. The generation rate of ideas have been halved, as a sign of my opinion of the community at large.
// F. God knows this will probably be successful in spite of myself.

*/

contract CloneFarmFarmer {
    using SafeMath for uint;
    
    /* Event */
    
    event MarketBoost(
        uint amountSent  
    );
    
    event NorsefireSwitch(
        address from,
        address to,
        uint price,
        uint a,
        uint b,
        uint c
    );
    
    event ClonesDeployed(
        address deployer,
        uint clones
    );
    
    event IdeasSold(
        address seller,
        uint ideas
    );
    
    event IdeasBought(
        address buyer,
        uint ideas
    );
    
    /* Constants */
    
    uint256 public clones_to_create_one_idea = 2 days;
    uint256 public starting_clones           = 3; // Shrimp, Shrooms and Snails.
    uint256        PSN                       = 10000;
    uint256        PSNH                      = 5000;
    address        actualNorse               = 0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae;
    
    /* Variables */
    uint256 public marketIdeas;
    uint256 public norsefirePrice;
    bool    public initialized;
    address public currentNorsefire;
    mapping (address => uint256) public arrayOfClones;
    mapping (address => uint256) public claimedIdeas;
    mapping (address => uint256) public lastDeploy;
    mapping (address => address) public referrals;
    
    constructor () public {
        initialized      = false;
        norsefirePrice   = 0.1 ether;
        currentNorsefire = 0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae;
    }
    
    function becomeNorsefire() public payable {
        require(initialized);
        address oldNorseAddr = currentNorsefire;
        uint oldNorsePrice   = norsefirePrice.mul(100).div(110);
        
        // Did you actually send enough?
        require(msg.value >= norsefirePrice);
        
        uint excess          = msg.value.sub(norsefirePrice);
        uint diffFivePct     = (norsefirePrice.sub(oldNorsePrice)).div(20);
        norsefirePrice       = norsefirePrice.add(norsefirePrice.div(10));
        uint flipPrize       = diffFivePct.mul(10);
        uint marketBoost     = diffFivePct.mul(9);
        address _newNorse    = msg.sender;
        uint    _toRefund    = (oldNorsePrice.add(flipPrize));
        currentNorsefire     = _newNorse;
        oldNorseAddr.send(_toRefund);
        actualNorse.send(diffFivePct);
        if (excess > 0){
            msg.sender.send(excess);
        }
        boostCloneMarket(marketBoost);
        emit NorsefireSwitch(oldNorseAddr, _newNorse, norsefirePrice, _toRefund, flipPrize, diffFivePct);
    }
    
    function boostCloneMarket(uint _eth) public payable {
        require(initialized);
        emit MarketBoost(_eth);
    }
    
    function deployIdeas(address ref) public{
        
        require(initialized);
        
        address _deployer = msg.sender;
        
        if(referrals[_deployer] == 0 && referrals[_deployer] != _deployer){
            referrals[_deployer]=ref;
        }
        
        uint256 myIdeas          = getMyIdeas();
        uint256 newIdeas         = myIdeas.div(clones_to_create_one_idea);
        arrayOfClones[_deployer] = arrayOfClones[_deployer].add(newIdeas);
        claimedIdeas[_deployer]  = 0;
        lastDeploy[_deployer]    = now;
        
        // Send referral ideas: dropped to 5% instead of 20% to reduce inflation.
        if (arrayOfClones[referrals[_deployer]] > 0) 
        {
            claimedIdeas[referrals[_deployer]] = claimedIdeas[referrals[_deployer]].add(myIdeas.div(20));
        }
        
        // Boost market to minimise idea hoarding
        marketIdeas = marketIdeas.add(myIdeas.div(10));
        emit ClonesDeployed(_deployer, newIdeas);
    }
    
    function sellIdeas() public {
        require(initialized);
        
        address _caller = msg.sender;
        
        uint256 hasIdeas        = getMyIdeas();
        uint256 ideaValue       = calculateIdeaSell(hasIdeas);
        uint256 fee             = devFee(ideaValue);
        // Destroy a quarter the owner&#39;s clones when selling ideas thanks to market saturation.
        arrayOfClones[_caller]  = (arrayOfClones[msg.sender].div(4)).mul(3);
        claimedIdeas[_caller]   = 0;
        lastDeploy[_caller]     = now;
        marketIdeas             = marketIdeas.add(hasIdeas);
        currentNorsefire.send(fee);
        _caller.send(ideaValue.sub(fee));
        emit IdeasSold(_caller, hasIdeas);
    }
    
    function buyIdeas() public payable{
        require(initialized);
        address _buyer       = msg.sender;
        uint    _sent        = msg.value;
        uint256 ideasBought  = calculateIdeaBuy(_sent, SafeMath.sub(address(this).balance,_sent));
        ideasBought          = ideasBought.sub(devFee(ideasBought));
        currentNorsefire.send(devFee(_sent));
        claimedIdeas[_buyer] = claimedIdeas[_buyer].add(ideasBought);
        emit IdeasBought(_buyer, ideasBought);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateIdeaSell(uint256 _ideas) public view returns(uint256){
        return calculateTrade(_ideas,marketIdeas,address(this).balance);
    }
    
    function calculateIdeaBuy(uint256 eth,uint256 _balance) public view returns(uint256){
        return calculateTrade(eth, _balance, marketIdeas);
    }
    function calculateIdeaBuySimple(uint256 eth) public view returns(uint256){
        return calculateIdeaBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) public pure returns(uint256){
        return amount.mul(4).div(100);
    }
    
    function releaseTheOriginal(uint256 _ideas) public payable {
        require(msg.sender  == currentNorsefire);
        require(marketIdeas == 0);
        initialized         = true;
        marketIdeas         = _ideas;
        boostCloneMarket(msg.value);
    }
    
    function hijackClones() public payable{
        require(initialized);
        require(msg.value==0.00232 ether); // Throwback to the OG.
        address _caller        = msg.sender;
        currentNorsefire.send(msg.value); // The current Norsefire gets this regitration
        require(arrayOfClones[_caller]==0);
        lastDeploy[_caller]    = now;
        arrayOfClones[_caller] = starting_clones;
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getMyClones() public view returns(uint256){
        return arrayOfClones[msg.sender];
    }
    
    function getNorsefirePrice() public view returns(uint256){
        return norsefirePrice;
    }
    
    function getMyIdeas() public view returns(uint256){
        address _caller = msg.sender;
        return claimedIdeas[_caller].add(getIdeasSinceLastDeploy(_caller));
    }
    
    function getIdeasSinceLastDeploy(address adr) public view returns(uint256){
        uint256 secondsPassed=min(clones_to_create_one_idea, now.sub(lastDeploy[adr]));
        return secondsPassed.mul(arrayOfClones[adr]);
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