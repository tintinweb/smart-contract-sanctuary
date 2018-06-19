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

contract Owned {
    address public owner;
    address public newOwner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract Lockable is Owned{

  uint256 public lockedUntilBlock;

  event ContractLocked(uint256 _untilBlock, string _reason);

  modifier lockAffected {
      require(block.number > lockedUntilBlock);
      _;
  }

  function lockFromSelf(uint256 _untilBlock, string _reason) internal {
    lockedUntilBlock = _untilBlock;
    ContractLocked(_untilBlock, _reason);
  }


  function lockUntil(uint256 _untilBlock, string _reason) onlyOwner {
    lockedUntilBlock = _untilBlock;
    ContractLocked(_untilBlock, _reason);
  }
}

contract ReentrancyHandlingContract{

    bool locked;

    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}
contract IMintableToken {
  function mintTokens(address _to, uint256 _amount){}
}
contract IERC20Token {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function approve(address _spender, uint256 _value) returns (bool success) {}
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract ItokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}
contract IToken {
  function totalSupply() constant returns (uint256 totalSupply);
  function mintTokens(address _to, uint256 _amount) {}
}






contract Crowdsale is ReentrancyHandlingContract, Owned{

  struct ContributorData{
    uint contributionAmount;
    uint tokensIssued;
  }

  mapping(address => ContributorData) public contributorList;
  uint nextContributorIndex;
  mapping(uint => address) contributorIndexes;

  state public crowdsaleState = state.pendingStart;
  enum state { pendingStart, crowdsale, crowdsaleEnded }

  uint public crowdsaleStartBlock;
  uint public crowdsaleEndedBlock;

  event CrowdsaleStarted(uint blockNumber);
  event CrowdsaleEnded(uint blockNumber);
  event ErrorSendingETH(address to, uint amount);
  event MinCapReached(uint blockNumber);
  event MaxCapReached(uint blockNumber);

  address tokenAddress = 0x0;
  uint decimals = 18;

  uint ethToTokenConversion;

  uint public minCap;
  uint public maxCap;
  uint public ethRaised;
  uint public tokenTotalSupply = 200000000 * 10**decimals;

  address public multisigAddress;
  uint blocksInADay;

  uint nextContributorToClaim;
  mapping(address => bool) hasClaimedEthWhenFail;

  uint crowdsaleTokenCap =          120000000 * 10**decimals;
  uint foundersAndTeamTokens =       32000000 * 10**decimals;
  uint advisorAndAmbassadorTokens =  16000000 * 10**decimals;
  uint investorTokens =               8000000 * 10**decimals;
  uint viberateContributorTokens =   10000000 * 10**decimals;
  uint futurePartnerTokens =         14000000 * 10**decimals;
  bool foundersAndTeamTokensClaimed = false;
  bool advisorAndAmbassadorTokensClaimed = false;
  bool investorTokensClaimed = false;
  bool viberateContributorTokensClaimed = false;
  bool futurePartnerTokensClaimed = false;

  //
  // Unnamed function that runs when eth is sent to the contract
  //
  function() noReentrancy payable{
    require(msg.value != 0);                        // Throw if value is 0
    require(crowdsaleState != state.crowdsaleEnded);// Check if crowdsale has ended

    bool stateChanged = checkCrowdsaleState();      // Check blocks and calibrate crowdsale state

    if(crowdsaleState == state.crowdsale){
      processTransaction(msg.sender, msg.value);    // Process transaction and issue tokens
    }
    else{
      refundTransaction(stateChanged);              // Set state and return funds or throw
    }
  }

  //
  // Check crowdsale state and calibrate it
  //
  function checkCrowdsaleState() internal returns (bool){
    if (ethRaised == maxCap && crowdsaleState != state.crowdsaleEnded){                         // Check if max cap is reached
      crowdsaleState = state.crowdsaleEnded;
      CrowdsaleEnded(block.number);                                                             // Raise event
      return true;
    }

    if(block.number > crowdsaleStartBlock && block.number <= crowdsaleEndedBlock){        // Check if we are in crowdsale state
      if (crowdsaleState != state.crowdsale){                                                   // Check if state needs to be changed
        crowdsaleState = state.crowdsale;                                                       // Set new state
        CrowdsaleStarted(block.number);                                                         // Raise event
        return true;
      }
    }else{
      if (crowdsaleState != state.crowdsaleEnded && block.number > crowdsaleEndedBlock){        // Check if crowdsale is over
        crowdsaleState = state.crowdsaleEnded;                                                  // Set new state
        CrowdsaleEnded(block.number);                                                           // Raise event
        return true;
      }
    }
    return false;
  }

  //
  // Decide if throw or only return ether
  //
  function refundTransaction(bool _stateChanged) internal{
    if (_stateChanged){
      msg.sender.transfer(msg.value);
    }else{
      revert();
    }
  }

  //
  //
  //
  function calculateEthToVibe(uint _eth, uint _blockNumber) constant returns(uint) {
    if (_blockNumber < crowdsaleStartBlock) return _eth * 3158;
    if (_blockNumber >= crowdsaleStartBlock && _blockNumber < crowdsaleStartBlock + blocksInADay * 2) return _eth * 3158;
    if (_blockNumber >= crowdsaleStartBlock + blocksInADay * 2 && _blockNumber < crowdsaleStartBlock + blocksInADay * 7) return _eth * 3074;
    if (_blockNumber >= crowdsaleStartBlock + blocksInADay * 7 && _blockNumber < crowdsaleStartBlock + blocksInADay * 14) return _eth * 2989;
    if (_blockNumber >= crowdsaleStartBlock + blocksInADay * 14 && _blockNumber < crowdsaleStartBlock + blocksInADay * 21) return _eth * 2905;
    if (_blockNumber >= crowdsaleStartBlock + blocksInADay * 21 ) return _eth * 2820;
  }

  //
  // Issue tokens and return if there is overflow
  //
  function processTransaction(address _contributor, uint _amount) internal{
    uint contributionAmount = _amount;
    uint returnAmount = 0;

    if (_amount > (maxCap - ethRaised)){                                           // Check if max contribution is lower than _amount sent
      contributionAmount = maxCap - ethRaised;                                     // Set that user contibutes his maximum alowed contribution
      returnAmount = _amount - contributionAmount;                                 // Calculate howmuch he must get back
    }

    if (ethRaised + contributionAmount > minCap && minCap > ethRaised){
      MinCapReached(block.number);
    }

    if (ethRaised + contributionAmount == maxCap && ethRaised < maxCap){
      MaxCapReached(block.number);
    }

    if (contributorList[_contributor].contributionAmount == 0){
        contributorIndexes[nextContributorIndex] = _contributor;
        nextContributorIndex += 1;
    }

    contributorList[_contributor].contributionAmount += contributionAmount;
    contributorList[_contributor].tokensIssued += contributionAmount;
    ethRaised += contributionAmount;                                              // Add to eth raised

    uint tokenAmount = calculateEthToVibe(contributionAmount, block.number);      // Calculate how much tokens must contributor get
    if (tokenAmount > 0){
      IToken(tokenAddress).mintTokens(_contributor, tokenAmount);                 // Issue new tokens
      contributorList[_contributor].tokensIssued += tokenAmount;                  // log token issuance
    }
    if (returnAmount != 0) _contributor.transfer(returnAmount);
  }

  function pushAngelInvestmentData(address _address, uint _ethContributed) onlyOwner{
      assert(ethRaised + _ethContributed <= maxCap);
      processTransaction(_address, _ethContributed);
  }
  function depositAngelInvestmentEth() payable onlyOwner {}
  

  //
  // Method is needed for recovering tokens accedentaly sent to token address
  //
  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner{
    IERC20Token(_tokenAddress).transfer(_to, _amount);
  }

  //
  // withdrawEth when minimum cap is reached
  //
  function withdrawEth() onlyOwner{
    require(this.balance != 0);
    require(ethRaised >= minCap);

    multisigAddress.transfer(this.balance);
  }

  //
  // Users can claim their contribution if min cap is not raised
  //
  function claimEthIfFailed(){
    require(block.number > crowdsaleEndedBlock && ethRaised < minCap);    // Check if crowdsale has failed
    require(contributorList[msg.sender].contributionAmount > 0);          // Check if contributor has contributed to crowdsaleEndedBlock
    require(!hasClaimedEthWhenFail[msg.sender]);                          // Check if contributor has already claimed his eth

    uint ethContributed = contributorList[msg.sender].contributionAmount; // Get contributors contribution
    hasClaimedEthWhenFail[msg.sender] = true;                             // Set that he has claimed
    if (!msg.sender.send(ethContributed)){                                // Refund eth
      ErrorSendingETH(msg.sender, ethContributed);                        // If there is an issue raise event for manual recovery
    }
  }

  //
  // Owner can batch return contributors contributions(eth)
  //
  function batchReturnEthIfFailed(uint _numberOfReturns) onlyOwner{
    require(block.number > crowdsaleEndedBlock && ethRaised < minCap);                // Check if crowdsale has failed
    address currentParticipantAddress;
    uint contribution;
    for (uint cnt = 0; cnt < _numberOfReturns; cnt++){
      currentParticipantAddress = contributorIndexes[nextContributorToClaim];         // Get next unclaimed participant
      if (currentParticipantAddress == 0x0) return;                                   // Check if all the participants were compensated
      if (!hasClaimedEthWhenFail[currentParticipantAddress]) {                        // Check if participant has already claimed
        contribution = contributorList[currentParticipantAddress].contributionAmount; // Get contribution of participant
        hasClaimedEthWhenFail[currentParticipantAddress] = true;                      // Set that he has claimed
        if (!currentParticipantAddress.send(contribution)){                           // Refund eth
          ErrorSendingETH(currentParticipantAddress, contribution);                   // If there is an issue raise event for manual recovery
        }
      }
      nextContributorToClaim += 1;                                                    // Repeat
    }
  }

  //
  // If there were any issue/attach with refund owner can withraw eth at the end for manual recovery
  //
  function withdrawRemainingBalanceForManualRecovery() onlyOwner{
    require(this.balance != 0);                                  // Check if there are any eth to claim
    require(block.number > crowdsaleEndedBlock);                 // Check if crowdsale is over
    require(contributorIndexes[nextContributorToClaim] == 0x0);  // Check if all the users were refunded
    multisigAddress.transfer(this.balance);                      // Withdraw to multisig
  }

  function claimTeamTokens(address _to, uint _choice) onlyOwner{
    require(crowdsaleState == state.crowdsaleEnded);
    require(ethRaised >= minCap);

    uint mintAmount;
    if(_choice == 1){
      assert(!advisorAndAmbassadorTokensClaimed);
      mintAmount = advisorAndAmbassadorTokens;
      advisorAndAmbassadorTokensClaimed = true;
    }else if(_choice == 2){
      assert(!investorTokensClaimed);
      mintAmount = investorTokens;
      investorTokensClaimed = true;
    }else if(_choice == 3){
      assert(!viberateContributorTokensClaimed);
      mintAmount = viberateContributorTokens;
      viberateContributorTokensClaimed = true;
    }else if(_choice == 4){
      assert(!futurePartnerTokensClaimed);
      mintAmount = futurePartnerTokens;
      futurePartnerTokensClaimed = true;
    }else if(_choice == 5){
      assert(!foundersAndTeamTokensClaimed);
      assert(advisorAndAmbassadorTokensClaimed);
      assert(investorTokensClaimed);
      assert(viberateContributorTokensClaimed);
      assert(futurePartnerTokensClaimed);
      assert(tokenTotalSupply > IERC20Token(tokenAddress).totalSupply());
      mintAmount = tokenTotalSupply - IERC20Token(tokenAddress).totalSupply();
      foundersAndTeamTokensClaimed = true;
    }
    else{
      revert();
    }
    IToken(tokenAddress).mintTokens(_to, mintAmount);
  }


  //
  // Owner can set multisig address for crowdsale
  //
  function setMultisigAddress(address _newAddress) onlyOwner{
    multisigAddress = _newAddress;
  }

  //
  // Owner can set token address where mints will happen
  //
  function setToken(address _newAddress) onlyOwner{
    tokenAddress = _newAddress;
  }

  function getTokenAddress() constant returns(address){
    return tokenAddress;
  }

  function investorCount() constant returns(uint){
    return nextContributorIndex;
  }
}









contract ViberateCrowdsale is Crowdsale {
  function ViberateCrowdsale(){

    crowdsaleStartBlock = 4240935;
    crowdsaleEndedBlock = 4348935;

    minCap = 3546099290780000000000;
    maxCap = 37993920972640000000000;

    blocksInADay = 3600;

  }
}