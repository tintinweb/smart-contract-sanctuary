pragma solidity ^0.4.13;

contract ReentrnacyHandlingContract{

    bool locked;

    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
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

contract IToken {
  function totalSupply() constant returns (uint256 totalSupply);
  function mintTokens(address _to, uint256 _amount) {}
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

contract MusiconomiCrowdsale is ReentrnacyHandlingContract, Owned{

  struct ContributorData{
    uint priorityPassAllowance;
    uint communityAllowance;
    bool isActive;
    uint contributionAmount;
    uint tokensIssued;
  }

  mapping(address => ContributorData) public contributorList;
  uint nextContributorIndex;
  mapping(uint => address) contributorIndexes;

  state public crowdsaleState = state.pendingStart;
  enum state { pendingStart, priorityPass, openedPriorityPass, crowdsale, crowdsaleEnded }

  uint public presaleStartBlock = 4216670;
  uint public presaleUnlimitedStartBlock = 4220000;
  uint public crowdsaleStartBlock = 4223470;
  uint public crowdsaleEndedBlock = 4318560;

  event PresaleStarted(uint blockNumber);
  event PresaleUnlimitedStarted(uint blockNumber);
  event CrowdsaleStarted(uint blockNumber);
  event CrowdsaleEnded(uint blockNumber);
  event ErrorSendingETH(address to, uint amount);
  event MinCapReached(uint blockNumber);
  event MaxCapReached(uint blockNumber);

  IToken token = IToken(0x0);
  uint ethToMusicConversion = 1416;

  uint minCap = 8824000000000000000000;
  uint maxCap = 17648000000000000000000;
  uint ethRaised;

  address public multisigAddress;

  uint nextContributorToClaim;
  mapping(address => bool) hasClaimedEthWhenFail;

  uint maxTokenSupply = 100000000000000000000000000;
  bool ownerHasClaimedTokens;
  uint cofounditReward = 2700000000000000000000000;
  address cofounditAddress = 0x8C0DB695de876a42cE2e133ca00fdF59A9166708;
  bool cofounditHasClaimedTokens;

  //
  // Unnamed function that runs when eth is sent to the contract
  //
  function() noReentrancy payable{
    require(msg.value != 0);                        // Throw if value is 0

    bool stateChanged = checkCrowdsaleState();      // Check blocks and calibrate crowdsale state

    if (crowdsaleState == state.priorityPass){
      if (contributorList[msg.sender].isActive){    // Check if contributor is in priorityPass
        processTransaction(msg.sender, msg.value);  // Process transaction and issue tokens
      }else{
        refundTransaction(stateChanged);            // Set state and return funds or throw
      }
    }
    else if(crowdsaleState == state.openedPriorityPass){
      if (contributorList[msg.sender].isActive){    // Check if contributor is in priorityPass
        processTransaction(msg.sender, msg.value);  // Process transaction and issue tokens
      }else{
        refundTransaction(stateChanged);            // Set state and return funds or throw
      }
    }
    else if(crowdsaleState == state.crowdsale){
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
      MaxCapReached(block.number);                                                              // Close the crowdsale
      CrowdsaleEnded(block.number);                                                             // Raise event
      return true;
    }

    if (block.number > presaleStartBlock && block.number <= presaleUnlimitedStartBlock){  // Check if we are in presale phase
      if (crowdsaleState != state.priorityPass){                                          // Check if state needs to be changed
        crowdsaleState = state.priorityPass;                                              // Set new state
        PresaleStarted(block.number);                                                     // Raise event
        return true;
      }
    }else if(block.number > presaleUnlimitedStartBlock && block.number <= crowdsaleStartBlock){ // Check if we are in presale unlimited phase
      if (crowdsaleState != state.openedPriorityPass){                                          // Check if state needs to be changed
        crowdsaleState = state.openedPriorityPass;                                              // Set new state
        PresaleUnlimitedStarted(block.number);                                                  // Raise event
        return true;
      }
    }else if(block.number > crowdsaleStartBlock && block.number <= crowdsaleEndedBlock){        // Check if we are in crowdsale state
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
  // Calculate how much user can contribute
  //
  function calculateMaxContribution(address _contributor) constant returns (uint maxContribution){
    uint maxContrib;
    if (crowdsaleState == state.priorityPass){   // Check if we are in priority pass
      maxContrib = contributorList[_contributor].priorityPassAllowance + contributorList[_contributor].communityAllowance - contributorList[_contributor].contributionAmount;
      if (maxContrib > (maxCap - ethRaised)){   // Check if max contribution is more that max cap
        maxContrib = maxCap - ethRaised;        // Alter max cap
      }
    }
    else{
      maxContrib = maxCap - ethRaised;          // Alter max cap
    }
    return maxContrib;
  }

  //
  // Issue tokens and return if there is overflow
  //
  function processTransaction(address _contributor, uint _amount) internal{
    uint maxContribution = calculateMaxContribution(_contributor);              // Calculate max users contribution
    uint contributionAmount = _amount;
    uint returnAmount = 0;
    if (maxContribution < _amount){                                             // Check if max contribution is lower than _amount sent
      contributionAmount = maxContribution;                                     // Set that user contibutes his maximum alowed contribution
      returnAmount = _amount - maxContribution;                                 // Calculate howmuch he must get back
    }

    if (ethRaised + contributionAmount > minCap && minCap < ethRaised) MinCapReached(block.number);

    if (contributorList[_contributor].isActive == false){                       // Check if contributor has already contributed
      contributorList[_contributor].isActive = true;                            // Set his activity to true
      contributorList[_contributor].contributionAmount = contributionAmount;    // Set his contribution
      contributorIndexes[nextContributorIndex] = _contributor;                  // Set contributors index
      nextContributorIndex++;
    }
    else{
      contributorList[_contributor].contributionAmount += contributionAmount;   // Add contribution amount to existing contributor
    }
    ethRaised += contributionAmount;                                            // Add to eth raised

    uint tokenAmount = contributionAmount * ethToMusicConversion;               // Calculate how much tokens must contributor get
    token.mintTokens(_contributor, tokenAmount);                                // Issue new tokens
    contributorList[_contributor].tokensIssued += tokenAmount;                  // log token issuance

    if (returnAmount != 0) _contributor.transfer(returnAmount);                 // Return overflow of ether
  }

  //
  // Push contributor data to the contract before the crowdsale so that they are eligible for priorit pass
  //
  function editContributors(address[] _contributorAddresses, uint[] _contributorPPAllowances, uint[] _contributorCommunityAllowance) onlyOwner{
    require(crowdsaleState == state.pendingStart);                                                        // Check if crowdsale has started
    require(_contributorAddresses.length == _contributorPPAllowances.length && _contributorAddresses.length == _contributorCommunityAllowance.length); // Check if input data is correct

    for(uint cnt = 0; cnt < _contributorAddresses.length; cnt++){
      contributorList[_contributorAddresses[cnt]].isActive = true;                                        // Activate contributor
      contributorList[_contributorAddresses[cnt]].priorityPassAllowance = _contributorPPAllowances[cnt];  // Set PP allowance
      contributorList[_contributorAddresses[cnt]].communityAllowance = _contributorCommunityAllowance[cnt];// Set community whitelist allowance
      contributorIndexes[nextContributorIndex] = _contributorAddresses[cnt];                              // Set users index
      nextContributorIndex++;
    }
  }

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
    token = IToken(_newAddress);
  }

  //
  // Owner can claim teams tokens when crowdsale has successfully ended
  //
  function claimCoreTeamsTokens(address _to) onlyOwner{
    require(crowdsaleState == state.crowdsaleEnded);              // Check if crowdsale has ended
    require(!ownerHasClaimedTokens);                              // Check if owner has allready claimed tokens

    uint devReward = maxTokenSupply - token.totalSupply();
    if (!cofounditHasClaimedTokens) devReward -= cofounditReward; // If cofoundit has claimed tokens its ok if not set aside cofounditReward
    token.mintTokens(_to, devReward);                             // Issue Teams tokens
    ownerHasClaimedTokens = true;                                 // Block further mints from this function
  }

  //
  // Cofoundit can claim their tokens
  //
  function claimCofounditTokens(){
    require(msg.sender == cofounditAddress);            // Check if sender is cofoundit
    require(crowdsaleState == state.crowdsaleEnded);    // Check if crowdsale has ended
    require(!cofounditHasClaimedTokens);                // Check if cofoundit has allready claimed tokens

    token.mintTokens(cofounditAddress, cofounditReward);// Issue cofoundit tokens
    cofounditHasClaimedTokens = true;                   // Block further mints from this function
  }

  function getTokenAddress() constant returns(address){
    return address(token);
  }
}