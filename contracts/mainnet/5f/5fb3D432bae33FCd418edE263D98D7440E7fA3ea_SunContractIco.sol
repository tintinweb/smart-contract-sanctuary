contract owned {

  address public owner;

  function owned() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    if (msg.sender != owner) throw;
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    owner = newOwner;
  }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract ISncToken {
  function mintTokens(address _to, uint256 _amount);
  function totalSupply() constant returns (uint256 totalSupply);
}

contract SunContractIco is owned{

  uint256 public startBlock;
  uint256 public endBlock;
  uint256 public minEthToRaise;
  uint256 public maxEthToRaise;
  uint256 public totalEthRaised;
  address public multisigAddress;


  ISncToken sncTokenContract; 
  mapping (address => bool) presaleContributorAllowance;
  uint256 nextFreeParticipantIndex;
  mapping (uint => address) participantIndex;
  mapping (address => uint256) participantContribution;

  bool icoHasStarted;
  bool minTresholdReached;
  bool icoHasSucessfulyEnded;
  uint256 blocksInWeek;
    bool ownerHasClaimedTokens;

  uint256 lastEthReturnIndex;
  mapping (address => bool) hasClaimedEthWhenFail;

  event ICOStarted(uint256 _blockNumber);
  event ICOMinTresholdReached(uint256 _blockNumber);
  event ICOEndedSuccessfuly(uint256 _blockNumber, uint256 _amountRaised);
  event ICOFailed(uint256 _blockNumber, uint256 _ammountRaised);
  event ErrorSendingETH(address _from, uint256 _amount);

  function SunContractIco(uint256 _startBlock, address _multisigAddress) {
    blocksInWeek = 4 * 60 * 24 * 7;
    startBlock = _startBlock;
    endBlock = _startBlock + blocksInWeek * 4;
    minEthToRaise = 5000 * 10**18;
    maxEthToRaise = 100000 * 10**18;
    multisigAddress = _multisigAddress;
  }

  //  
  /* User accessible methods */   
  //  

  /* Users send ETH and enter the token sale*/  
  function () payable {
    if (msg.value == 0) throw;                                          // Throw if the value is 0  
    if (icoHasSucessfulyEnded || block.number > endBlock) throw;        // Throw if the ICO has ended     
    if (!icoHasStarted){                                                // Check if this is the first ICO transaction       
      if (block.number >= startBlock){                                  // Check if the ICO should start        
        icoHasStarted = true;                                           // Set that the ICO has started         
        ICOStarted(block.number);                                       // Raise ICOStarted event     
      } else{
        throw;
      }
    }     
    if (participantContribution[msg.sender] == 0){                     // Check if the sender is a new user       
      participantIndex[nextFreeParticipantIndex] = msg.sender;         // Add a new user to the participant index       
      nextFreeParticipantIndex += 1;
    }     
    if (maxEthToRaise > (totalEthRaised + msg.value)){                 // Check if the user sent too much ETH       
      participantContribution[msg.sender] += msg.value;                // Add contribution      
      totalEthRaised += msg.value;// Add to total eth Raised
      sncTokenContract.mintTokens(msg.sender, getSncTokenIssuance(block.number, msg.value));
      if (!minTresholdReached && totalEthRaised >= minEthToRaise){      // Check if the min treshold has been reached one time        
        ICOMinTresholdReached(block.number);                            // Raise ICOMinTresholdReached event        
        minTresholdReached = true;                                      // Set that the min treshold has been reached       
      }     
    }else{                                                              // If user sent to much eth       
      uint maxContribution = maxEthToRaise - totalEthRaised;            // Calculate maximum contribution       
      participantContribution[msg.sender] += maxContribution;           // Add maximum contribution to account      
      totalEthRaised += maxContribution;  
      sncTokenContract.mintTokens(msg.sender, getSncTokenIssuance(block.number, maxContribution));
      uint toReturn = msg.value - maxContribution;                       // Calculate how much should be returned       
      icoHasSucessfulyEnded = true;                                      // Set that ICO has successfully ended       
      ICOEndedSuccessfuly(block.number, totalEthRaised);      
      if(!msg.sender.send(toReturn)){                                    // Refund the balance that is over the cap         
        ErrorSendingETH(msg.sender, toReturn);                           // Raise event for manual return if transaction throws       
      }     
    }
  }   

  /* Users can claim ETH by themselves if they want to in case of ETH failure*/   
  function claimEthIfFailed(){    
    if (block.number <= endBlock || totalEthRaised >= minEthToRaise) throw; // Check if ICO has failed    
    if (participantContribution[msg.sender] == 0) throw;                    // Check if user has participated     
    if (hasClaimedEthWhenFail[msg.sender]) throw;                           // Check if this account has already claimed ETH    
    uint256 ethContributed = participantContribution[msg.sender];           // Get participant ETH Contribution     
    hasClaimedEthWhenFail[msg.sender] = true;     
    if (!msg.sender.send(ethContributed)){      
      ErrorSendingETH(msg.sender, ethContributed);                          // Raise event if send failed, solve manually     
    }   
  }   

  //  
  /* Only owner methods */  
  //  

  /* Adds addresses that are allowed to take part in presale */   
  function addPresaleContributors(address[] _presaleContributors) onlyOwner {     
    for (uint cnt = 0; cnt < _presaleContributors.length; cnt++){       
      presaleContributorAllowance[_presaleContributors[cnt]] = true;    
    }   
  }   

  /* Owner can return eth for multiple users in one call*/  
  function batchReturnEthIfFailed(uint256 _numberOfReturns) onlyOwner{    
    if (block.number < endBlock || totalEthRaised >= minEthToRaise) throw;    // Check if ICO failed  
    address currentParticipantAddress;    
    uint256 contribution;
    for (uint cnt = 0; cnt < _numberOfReturns; cnt++){      
      currentParticipantAddress = participantIndex[lastEthReturnIndex];       // Get next account       
      if (currentParticipantAddress == 0x0) return;                           // Check if participants were reimbursed      
      if (!hasClaimedEthWhenFail[currentParticipantAddress]) {                // Check if user has manually recovered ETH         
        contribution = participantContribution[currentParticipantAddress];    // Get accounts contribution        
        hasClaimedEthWhenFail[msg.sender] = true;                             // Set that user got his ETH back         
        if (!currentParticipantAddress.send(contribution)){                   // Send fund back to account          
          ErrorSendingETH(currentParticipantAddress, contribution);           // Raise event if send failed, resolve manually         
        }       
      }       
      lastEthReturnIndex += 1;    
    }   
  }   

  /* Owner sets new address of SunContractToken */
  function changeMultisigAddress(address _newAddress) onlyOwner {     
    multisigAddress = _newAddress;
  }   

  /* Owner can claim reserved tokens on the end of crowsale */  
  function claimCoreTeamsTokens(address _to) onlyOwner{     
    if (!icoHasSucessfulyEnded) throw; 
    if (ownerHasClaimedTokens) throw;
    
    sncTokenContract.mintTokens(_to, sncTokenContract.totalSupply() * 25 / 100);
    ownerHasClaimedTokens = true;
  }   

  /* Owner can remove allowance of designated presale contributor */  
  function removePresaleContributor(address _presaleContributor) onlyOwner {    
    presaleContributorAllowance[_presaleContributor] = false;   
  }   

  /* Set token contract where mints will be done (tokens will be issued)*/  
  function setTokenContract(address _sncTokenContractAddress) onlyOwner {     
    sncTokenContract = ISncToken(_sncTokenContractAddress);   
  }   

  /* Withdraw funds from contract */  
  function withdrawEth() onlyOwner{     
    if (this.balance == 0) throw;                                            // Check if there is balance on the contract     
    if (totalEthRaised < minEthToRaise) throw;                               // Check if minEthToRaise treshold is exceeded     
      
    if(multisigAddress.send(this.balance)){}                                 // Send the contract&#39;s balance to multisig address   
  }
  
  function endIco() onlyOwner {
      if (totalEthRaised < minEthToRaise) throw;
      if (block.number < endBlock) throw;
  
    icoHasSucessfulyEnded = true;
    ICOEndedSuccessfuly(block.number, totalEthRaised);
  }

  /* Withdraw remaining balance to manually return where contract send has failed */  
  function withdrawRemainingBalanceForManualRecovery() onlyOwner{     
    if (this.balance == 0) throw;                                         // Check if there is balance on the contract    
    if (block.number < endBlock) throw;                                   // Check if ICO failed    
    if (participantIndex[lastEthReturnIndex] != 0x0) throw;               // Check if all the participants have been reimbursed     
    if (multisigAddress.send(this.balance)){}                             // Send remainder so it can be manually processed   
  }

  //  
  /* Getters */   
  //  

  function getSncTokenAddress() constant returns(address _tokenAddress){    
    return address(sncTokenContract);   
  }   

  function icoInProgress() constant returns (bool answer){    
    return icoHasStarted && !icoHasSucessfulyEnded;   
  }   

  function isAddressAllowedInPresale(address _querryAddress) constant returns (bool answer){    
    return presaleContributorAllowance[_querryAddress];   
  }   

  function participantContributionInEth(address _querryAddress) constant returns (uint256 answer){    
    return participantContribution[_querryAddress];   
  }
  
  function getSncTokenIssuance(uint256 _blockNumber, uint256 _ethSent) constant returns(uint){
        if (_blockNumber >= startBlock && _blockNumber < blocksInWeek + startBlock) {
          if (presaleContributorAllowance[msg.sender]) return _ethSent * 11600;
          else return _ethSent * 11500;
        }
        if (_blockNumber >= blocksInWeek + startBlock && _blockNumber < blocksInWeek * 2 + startBlock) return _ethSent * 11000;
        if (_blockNumber >= blocksInWeek * 2 + startBlock && _blockNumber < blocksInWeek * 3 + startBlock) return _ethSent * 10500;
        if (_blockNumber >= blocksInWeek * 3 + startBlock && _blockNumber <= blocksInWeek * 4 + startBlock) return _ethSent * 10000;
    }

  //
  /* This part is here only for testing and will not be included into final version */
  //
  //function killContract() onlyOwner{
  //  selfdestruct(msg.sender);
  //}
}