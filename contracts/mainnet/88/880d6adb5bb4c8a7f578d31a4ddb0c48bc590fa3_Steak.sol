pragma solidity ^0.4.15;


/**
 *
 *  STEAK TOKEN (BOV)
 *
 *  Make bank by eating flank. See https://steaktoken.com.
 *
 */


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
 library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
 contract Ownable {
  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}




contract SteakToken is Ownable {

  using SafeMath for uint256;

  string public name = "Steak Token";
  string public symbol = "BOV";
  uint public decimals = 18;
  uint public totalSupply;      // Total BOV in circulation.

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed ownerAddress, address indexed spenderAddress, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MineFinished();

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) returns (bool) {
    if(msg.data.length < (2 * 32) + 4) { revert(); } // protect against short address attack
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }


  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
   function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
   function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

    /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
   function mint(address _to, uint256 _amount) internal returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }


}








/**
 * @title AuctionCrowdsale 
 * @dev The owner starts and ends the crowdsale manually.
 * Players can make token purchases during the crowdsale
 * and their tokens can be claimed after the sale ends.
 * Players receive an amount proportional to their investment.
 */
 contract AuctionCrowdsale is SteakToken {
  using SafeMath for uint;

  uint public initialSale;                  // Amount of BOV tokens being sold during crowdsale.

  bool public saleStarted;
  bool public saleEnded;

  uint public absoluteEndBlock;             // Anybody can end the crowdsale and trigger token distribution if beyond this block number.

  uint256 public weiRaised;                 // Total amount raised in crowdsale.

  address[] public investors;               // Investor addresses
  uint public numberOfInvestors;
  mapping(address => uint256) public investments; // How much each address has invested.

  mapping(address => bool) public claimed;      // Keep track of whether each investor has been awarded their BOV tokens.


  bool public bovBatchDistributed;              // TODO: this can be removed with manual crowdsale end-time

  uint public initialPrizeWeiValue;             // The first steaks mined will be awarded BOV equivalent to this ETH value. Set in Steak() initializer.
  uint public initialPrizeBov;                  // Initial mining prize in BOV units. Set in endCrowdsale() or endCrowdsalePublic().

  uint public dailyHashExpires;        // When the dailyHash expires. Will be roughly around 3am EST.





  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   */ 
   event TokenInvestment(address indexed purchaser, address indexed beneficiary, uint256 value);



   // Sending ETH to this contract&#39;s address registers the investment.
   function () payable {
    invest(msg.sender);
  }


  // Participate in the crowdsale.
  // Records how much each address has invested.
  function invest(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validInvestment());

    uint256 weiAmount = msg.value;

    uint investedAmount = investments[beneficiary];

    forwardFunds();

    if (investedAmount > 0) { // If they&#39;ve already invested, increase their balance.
      investments[beneficiary] = investedAmount + weiAmount; // investedAmount.add(weiAmount);
    } else { // If new investor
      investors.push(beneficiary);
      numberOfInvestors += 1;
      investments[beneficiary] = weiAmount;
    }
    weiRaised = weiRaised.add(weiAmount);
    TokenInvestment(msg.sender, beneficiary, weiAmount);
  }



  // @return true if the transaction can invest
  function validInvestment() internal constant returns (bool) {
    bool withinPeriod = saleStarted && !saleEnded;
    bool nonZeroPurchase = (msg.value > 0);
    return withinPeriod && nonZeroPurchase;
  }




  // Distribute 10M tokens proportionally amongst all investors. Can be called by anyone after the crowdsale ends.
  // ClaimTokens() can be run by individuals to claim their tokens.
  function distributeAllTokens() public {

    require(!bovBatchDistributed);
    require(crowdsaleHasEnded());

    // Allocate BOV proportionally to each investor.

    for (uint i=0; i < numberOfInvestors; i++) {
      address investorAddr = investors[i];
      if (!claimed[investorAddr]) { // If the investor hasn&#39;t already claimed their BOV.
        claimed[investorAddr] = true;
        uint amountInvested = investments[investorAddr];
        uint bovEarned = amountInvested.mul(initialSale).div(weiRaised);
        mint(investorAddr, bovEarned);
      }
    }

    bovBatchDistributed = true;
  }


  // Claim your BOV; allocates BOV proportionally to this investor.
  // Can be called by investors to claim their BOV after the crowdsale ends.
  // distributeAllTokens() is a batch alternative to this.
  function claimTokens(address origAddress) public {
    require(crowdsaleHasEnded());
    require(claimed[origAddress] == false);
    uint amountInvested = investments[origAddress];
    uint bovEarned = amountInvested.mul(initialSale).div(weiRaised);
    claimed[origAddress] = true;
    mint(origAddress, bovEarned);
  }


  // Investors: see how many BOV you are currently entitled to (before the end of the crowdsale and distribution of tokens).
  function getCurrentShare(address addr) public constant returns (uint) {
    require(!bovBatchDistributed && !claimed[addr]); // Tokens cannot have already been distributed.
    uint amountInvested = investments[addr];
    uint currentBovShare = amountInvested.mul(initialSale).div(weiRaised);
    return currentBovShare;
  }



  // send ether to the fund collection wallet
  function forwardFunds() internal {
    owner.transfer(msg.value);
  }


  // The owner manually starts the crowdsale at a pre-determined time.
  function startCrowdsale() onlyOwner {
    require(!saleStarted && !saleEnded);
    saleStarted = true;
  }

  // endCrowdsale() and endCrowdsalePublic() moved to Steak contract
    // Normally, the owner will end the crowdsale at the pre-determined time.
  function endCrowdsale() onlyOwner {
    require(saleStarted && !saleEnded);
    dailyHashExpires = now; // Will end crowdsale at 3am EST, so expiration time will roughly be around 3am.
    saleEnded = true;
    setInitialPrize();
  }

  // Normally, Madame BOV ends the crowdsale at the pre-determined time, but if Madame BOV fails to do so, anybody can trigger endCrowdsalePublic() after absoluteEndBlock.
  function endCrowdsalePublic() public {
    require(block.number > absoluteEndBlock);
    require(saleStarted && !saleEnded);
    dailyHashExpires = now;
    saleEnded = true;
    setInitialPrize();
  }


  // Calculate initial mining prize (0.0357 ether&#39;s worth of BOV). This is called in endCrowdsale().
  function setInitialPrize() internal returns (uint) {
    require(crowdsaleHasEnded());
    require(initialPrizeBov == 0); // Can only be set once
    uint tokenUnitsPerWei = initialSale.div(weiRaised);
    initialPrizeBov = tokenUnitsPerWei.mul(initialPrizeWeiValue);
    return initialPrizeBov;
  }


  // @return true if crowdsale event has ended
  function crowdsaleHasEnded() public constant returns (bool) {
    return saleStarted && saleEnded;
  }

  function getInvestors() public returns (address[]) {
    return investors;
  }


}







contract Steak is AuctionCrowdsale {
  // using SafeMath for uint;

  bytes32 public dailyHash;            // The last five digits of the dailyHash must be included in steak pictures.


  Submission[] public submissions;          // All steak pics
  uint public numSubmissions;

  Submission[] public approvedSubmissions;
  mapping (address => uint) public memberId;    // Get member ID from address.
  Member[] public members;                      // Index is memberId

  uint public halvingInterval;                  // BOV award is halved every x steaks
  uint public numberOfHalvings;                 // How many times the BOV reward per steak is halved before it returns 0. 



  uint public lastMiningBlock;                  // No mining after this block. Set in initializer.

  bool public ownerCredited;    // Has the owner been credited BOV yet?

  event PicAdded(address msgSender, uint submissionID, address recipient, bytes32 propUrl); // Need msgSender so we can watch for this event.
  event Judged(uint submissionID, bool position, address voter, bytes32 justification);
  event MembershipChanged(address member, bool isMember);

  struct Submission {
    address recipient;    // Would-be BOV recipient
    bytes32 url;           // IMGUR url; 32-char max
    bool judged;          // Has an admin voted?
    bool submissionApproved;// Has it been approved?
    address judgedBy;     // Admin who judged this steak
    bytes32 adminComments; // Admin should leave feedback on non-approved steaks. 32-char max.
    bytes32 todaysHash;   // The hash in the image should match this hash.
    uint awarded;         // Amount awarded
  }

  // Members can vote on steak
  struct Member {
    address member;
    bytes32 name;
    uint memberSince;
  }


  modifier onlyMembers {
    require(memberId[msg.sender] != 0); // member id must be in the mapping
    _;
  }


  function Steak() {

    owner = msg.sender;
    initialSale = 10000000 * 1000000000000000000; // 10M BOV units are awarded in the crowdsale.

    // Normally, the owner both starts and ends the crowdsale.
    // To guarantee that the crowdsale ends at some maximum point (at that tokens are distributed),
    // we calculate the absoluteEndBlock, the block beyond which anybody can end the crowdsale and distribute tokens.
    uint blocksPerHour = 212;
    uint maxCrowdsaleLifeFromLaunchDays = 40; // After about this many days from launch, anybody can end the crowdsale and distribute / claim their tokens. 
    absoluteEndBlock = block.number + (blocksPerHour * 24 * maxCrowdsaleLifeFromLaunchDays);

    uint miningDays = 365; // Approximately how many days BOV can be mined from the launch of the contract.
    lastMiningBlock = block.number + (blocksPerHour * 24 * miningDays);

    dailyHashExpires = now;

    halvingInterval = 500;    // How many steaks get awarded the given getSteakPrize() amount before the reward is halved.
    numberOfHalvings = 8;      // How many times the steak prize gets halved before no more prize is awarded.

    // initialPrizeWeiValue = 50 finney; // 0.05 ether == 50 finney == 2.80 USD * 5 == 14 USD
    initialPrizeWeiValue = (357 finney / 10); // 0.0357 ether == 35.7 finney == 2.80 USD * 3.57 == 9.996 USD

    // To finish initializing, owner calls initMembers() and creditOwner() after launch.
  }


  // Add Madame BOV as a beef judge.
  function initMembers() onlyOwner {
    addMember(0, &#39;&#39;);                        // Must add an empty first member
    addMember(msg.sender, &#39;Madame BOV&#39;);
  }



  // Send 1M BOV to Madame BOV. 
  function creditOwner() onlyOwner {
    require(!ownerCredited);
    uint ownerAward = initialSale / 10;  // 10% of the crowdsale amount.
    ownerCredited = true;   // Can only be run once.
    mint(owner, ownerAward);
  }






  /* Add beef judge */
  function addMember(address targetMember, bytes32 memberName) onlyOwner {
    uint id;
    if (memberId[targetMember] == 0) {
      memberId[targetMember] = members.length;
      id = members.length++;
      members[id] = Member({member: targetMember, memberSince: now, name: memberName});
    } else {
      id = memberId[targetMember];
      // Member m = members[id];
    }
    MembershipChanged(targetMember, true);
  }

  function removeMember(address targetMember) onlyOwner {
    if (memberId[targetMember] == 0) revert();

    memberId[targetMember] = 0;

    for (uint i = memberId[targetMember]; i<members.length-1; i++){
      members[i] = members[i+1];
    }
    delete members[members.length-1];
    members.length--;
  }



  /* Submit a steak picture. (After crowdsale has ended.)
  *  WARNING: Before taking the picture, call getDailyHash() and  minutesToPost()
  *  so you can be sure that you have the correct dailyHash and that it won&#39;t expire before you post it.
  */
  function submitSteak(address addressToAward, bytes32 steakPicUrl)  returns (uint submissionID) {
    require(crowdsaleHasEnded());
    require(block.number <= lastMiningBlock); // Cannot submit beyond this block.
    submissionID = submissions.length++; // Increase length of array
    Submission storage s = submissions[submissionID];
    s.recipient = addressToAward;
    s.url = steakPicUrl;
    s.judged = false;
    s.submissionApproved = false;
    s.todaysHash = getDailyHash(); // Each submission saves the hash code the user should take picture of in steak picture.

    PicAdded(msg.sender, submissionID, addressToAward, steakPicUrl);
    numSubmissions = submissionID+1;

    return submissionID;
  }

  // Retrieving any Submission must be done via this function, not `submissions()`
  function getSubmission(uint submissionID) public constant returns (address recipient, bytes32 url, bool judged, bool submissionApproved, address judgedBy, bytes32 adminComments, bytes32 todaysHash, uint awarded) {
    Submission storage s = submissions[submissionID];
    recipient = s.recipient;
    url = s.url;                 // IMGUR url
    judged = s.judged;           // Has an admin voted?
    submissionApproved = s.submissionApproved;  // Has it been approved?
    judgedBy = s.judgedBy;           // Admin who judged this steak
    adminComments = s.adminComments; // Admin should leave feedback on non-approved steaks
    todaysHash = s.todaysHash;       // The hash in the image should match this hash.
    awarded = s.awarded;         // Amount awarded   // return (users[index].salaryId, users[index].name, users[index].userAddress, users[index].salary);
    // return (recipient, url, judged, submissionApproved, judgedBy, adminComments, todaysHash, awarded);
  }



  // Members judge steak pics, providing justification if necessary.
  function judge(uint submissionNumber, bool supportsSubmission, bytes32 justificationText) onlyMembers {
    Submission storage s = submissions[submissionNumber];         // Get the submission.
    require(!s.judged);                                     // Musn&#39;t be judged.

    s.judged = true;
    s.judgedBy = msg.sender;
    s.submissionApproved = supportsSubmission;
    s.adminComments = justificationText;    // Admin can add comments whether approved or not

    if (supportsSubmission) { // If it passed muster, credit the user and admin.
      uint prizeAmount = getSteakPrize(); // Calculate BOV prize
      s.awarded = prizeAmount;            // Record amount in the Submission
      mint(s.recipient, prizeAmount);     // Credit the user&#39;s account

      // Credit the member one-third of the prize amount.
      uint adminAward = prizeAmount.div(3);
      mint(msg.sender, adminAward);

      approvedSubmissions.push(s);
    }

    Judged(submissionNumber, supportsSubmission, msg.sender, justificationText);
  }


  // Calculate how many BOV are rewarded per approved steak pic.
  function getSteakPrize() public constant returns (uint) {
    require(initialPrizeBov > 0); // crowdsale must be over (endCrowdsale() calls setInitialPrize())
    uint halvings = numberOfApprovedSteaks().div(halvingInterval);
    if (halvings > numberOfHalvings) {  // After 8 halvings, no more BOV is awarded.
      return 0;
    }

    uint prize = initialPrizeBov;

    prize = prize >> halvings; // Halve the initial prize "halvings"-number of times.
    return prize;
  }


  function numberOfApprovedSteaks() public constant returns (uint) {
    return approvedSubmissions.length;
  }


  // Always call this before calling dailyHash and submitting a steak.
  // If expired, the new hash is set to the last block&#39;s hash.
  function getDailyHash() public returns (bytes32) {
    if (dailyHashExpires > now) { // If the hash hasn&#39;t expired yet, return it.
      return dailyHash;
    } else { // Udderwise, set the new dailyHash and dailyHashExpiration.

      // Get hash from the last block.
      bytes32 newHash = block.blockhash(block.number-1);
      dailyHash = newHash;

      // Set the new expiration, jumping ahead in 24-hour increments so the expiration time remains roughly constant from day to day (e.g. 3am).
      uint nextExpiration = dailyHashExpires + 24 hours; // It will already be expired, so set it to next possible date.
      while (nextExpiration < now) { // if it&#39;s still in the past, advance by 24 hours.
        nextExpiration += 24 hours;
      }
      dailyHashExpires = nextExpiration;
      return newHash;
    }
  }

  // Returns the amount of minutes to post with the current dailyHash
  function minutesToPost() public constant returns (uint) {
    if (dailyHashExpires > now) {
      return (dailyHashExpires - now) / 60; // returns minutes
    } else {
      return 0;
    }
  }

  function currentBlock() public constant returns (uint) {
    return block.number;
  }
}