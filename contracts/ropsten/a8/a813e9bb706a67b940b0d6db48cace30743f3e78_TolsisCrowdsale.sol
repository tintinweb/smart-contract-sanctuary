/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// File: gist-93cc6447162a8ffd1a88992ba6170fd6/contracts/Interfaces/IERC20Token.sol

pragma solidity ^0.4.13;

contract IERC20Token {
    
  function totalSupply() constant returns (uint256) {this;}
  function balanceOf(address _owner) constant returns (uint256) {_owner; this;}
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256) {_owner; _spender; this;}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  
}

// File: gist-93cc6447162a8ffd1a88992ba6170fd6/contracts/Interfaces/IToken.sol

pragma solidity ^0.4.13;

contract IToken {
  
  function totalSupply() constant returns (uint256) {this;}
  function mintTokens(address _to, uint256 _amount) constant returns (uint256) {_to; _amount; this;}

}

// File: gist-93cc6447162a8ffd1a88992ba6170fd6/contracts/Utils/SafeMath.sol

pragma solidity ^0.4.13;

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: gist-93cc6447162a8ffd1a88992ba6170fd6/contracts/Utils/Owned.sol

pragma solidity ^0.4.13;

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

// File: gist-93cc6447162a8ffd1a88992ba6170fd6/contracts/Utils/ReentrancyHandling.sol

pragma solidity ^0.4.13;

contract ReentrancyHandling {

    bool locked;

    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}

// File: gist-93cc6447162a8ffd1a88992ba6170fd6/contracts/Crowdsale.sol

pragma solidity ^0.4.13;






contract Crowdsale is ReentrancyHandling, Owned {

  using SafeMath for uint256;
  
  struct ContributorData {
    bool isWhiteListed;
    bool isCommunityRoundApproved;
    uint256 contributionAmount;
    uint256 tokensIssued;
  }

  mapping(address => ContributorData) public contributorList;

  enum state { pendingStart, communityRound, crowdsaleStarted, crowdsaleEnded }
  state crowdsaleState;

  uint public communityRoundStartDate;
  uint public crowdsaleStartDate;
  uint public crowdsaleEndDate;

  event CommunityRoundStarted(uint timestamp);
  event CrowdsaleStarted(uint timestamp);
  event CrowdsaleEnded(uint timestamp);

  IToken token = IToken(0x0);
  uint ethToTokenConversion;

  uint256 maxCrowdsaleCap;
  uint256 maxCommunityCap;
  uint256 maxCommunityWithoutBonusCap;
  uint256 maxContribution;


  uint256 tokenSold = 0;
  uint256 communityTokenSold = 0;
  uint256 communityTokenWithoutBonusSold = 0;
  uint256 crowdsaleTokenSold = 0;
  uint256 public ethRaisedWithoutCompany = 0;

  address companyAddress;   // company wallet address in cold/hardware storage 

  uint maxTokenSupply;
  uint companyTokens;
  bool treasuryLocked = false;
  bool ownerHasClaimedTokens = false;
  bool ownerHasClaimedCompanyTokens = false;


  // validates sender is whitelisted
  modifier onlyWhiteListUser {
    require(contributorList[msg.sender].isWhiteListed == true);
    _;
  }

  // limit gas price to 50 Gwei (about 5-10x the normal amount)
  modifier onlyLowGasPrice {
	  require(tx.gasprice <= 50*10**9 wei);
	  _;
  }

  //
  // Unnamed function that runs when eth is sent to the contract
  //
  function() public noReentrancy onlyWhiteListUser onlyLowGasPrice payable {
    require(msg.value != 0);                                         // Throw if value is 0
    require(companyAddress != 0x0);
    require(token != IToken(0x0));

    checkCrowdsaleState();                                           // Calibrate crowdsale state

    assert((crowdsaleState == state.communityRound && contributorList[msg.sender].isCommunityRoundApproved) ||
            crowdsaleState == state.crowdsaleStarted);
    
    processTransaction(msg.sender, msg.value);                       // Process transaction and issue tokens

    checkCrowdsaleState();                                           // Calibrate crowdsale state
  }

  // 
  // return state of smart contract
  //
  
  function getState() public constant returns (uint256, uint256, uint) {
    uint currentState = 0;

    if (crowdsaleState == state.pendingStart) {
      currentState = 1;
    }
    else if (crowdsaleState == state.communityRound) {
      currentState = 2;
    }
    else if (crowdsaleState == state.crowdsaleStarted) {
      currentState = 3;
    }
    else if (crowdsaleState == state.crowdsaleEnded) {
      currentState = 4;
    }

    return (tokenSold, communityTokenSold, currentState);
  }

  //
  // Check crowdsale state and calibrate it
  //

  function checkCrowdsaleState() internal {
    if (now > crowdsaleEndDate || tokenSold >= maxTokenSupply) {  // end crowdsale once all tokens are sold or run out of time
      if (crowdsaleState != state.crowdsaleEnded) {
        crowdsaleState = state.crowdsaleEnded;
        CrowdsaleEnded(now);
      }
    }
    else if (now > crowdsaleStartDate) { // move into crowdsale round
      if (crowdsaleState != state.crowdsaleStarted) {
        uint256 communityTokenRemaining = maxCommunityCap.sub(communityTokenSold);  // apply any remaining tokens from community round to crowdsale round
        maxCrowdsaleCap = maxCrowdsaleCap.add(communityTokenRemaining);
        crowdsaleState = state.crowdsaleStarted;  // change state
        CrowdsaleStarted(now);
      }
    }
    else if (now > communityRoundStartDate) {
      if (communityTokenSold < maxCommunityCap) {
        if (crowdsaleState != state.communityRound) {
          crowdsaleState = state.communityRound;
          CommunityRoundStarted(now);
        }
      }
      else {  // automatically start crowdsale when all community round tokens are sold out 
        if (crowdsaleState != state.crowdsaleStarted) {
          crowdsaleState = state.crowdsaleStarted;
          CrowdsaleStarted(now);
        }
      }
    }
  }

  //
  // Issue tokens and return if there is overflow
  //
  
  function calculateCommunity(address _contributor, uint256 _newContribution) internal returns (uint256, uint256) {
    uint256 communityEthAmount = 0;
    uint256 communityTokenAmount = 0;

    uint previousContribution = contributorList[_contributor].contributionAmount;  // retrieve previous contributions

    // community round ONLY
    if (crowdsaleState == state.communityRound && 
        contributorList[_contributor].isCommunityRoundApproved && 
        previousContribution < maxContribution) {
        communityEthAmount = _newContribution;

        uint256 availableEthAmount = maxContribution.sub(previousContribution);                 
        // limit the contribution ETH amount to the maximum allowed for the community round
        if (communityEthAmount > availableEthAmount) {
          communityEthAmount = availableEthAmount;
        }

        // compute community tokens without bonus
        communityTokenAmount = communityEthAmount.mul(ethToTokenConversion);

        uint256 availableTokenAmount = maxCommunityWithoutBonusCap.sub(communityTokenWithoutBonusSold);

        // verify community tokens do not go over the max cap for community round
        if (communityTokenAmount > availableTokenAmount) {
          // cap the tokens to the max allowed for the community round
          communityTokenAmount = availableTokenAmount;
          // recalculate the corresponding ETH amount
          communityEthAmount = communityTokenAmount.div(ethToTokenConversion);
        }

        // track tokens sold during community round
        communityTokenWithoutBonusSold = communityTokenWithoutBonusSold.add(communityTokenAmount);

        // compute bonus tokens
        uint256 bonusTokenAmount = communityTokenAmount.mul(15);
        bonusTokenAmount = bonusTokenAmount.div(100);

        // add bonus to community tokens
        communityTokenAmount = communityTokenAmount.add(bonusTokenAmount);

        // track tokens sold during community round
        communityTokenSold = communityTokenSold.add(communityTokenAmount);
    }

    return (communityTokenAmount, communityEthAmount);
  }

  //
  // Issue tokens and return if there is overflow
  //
  
  function calculateCrowdsale(uint256 _remainingContribution) internal returns (uint256, uint256) {
    uint256 crowdsaleEthAmount = _remainingContribution;

    // compute crowdsale tokens
    uint256 crowdsaleTokenAmount = crowdsaleEthAmount.mul(ethToTokenConversion);

    // determine crowdsale tokens remaining
    uint256 availableTokenAmount = maxCrowdsaleCap.sub(crowdsaleTokenSold);

    // verify crowdsale tokens do not go over the max cap for crowdsale round
    if (crowdsaleTokenAmount > availableTokenAmount) {
      // cap the tokens to the max allowed for the crowdsale round
      crowdsaleTokenAmount = availableTokenAmount;

      // recalculate the corresponding ETH amount
      crowdsaleEthAmount = crowdsaleTokenAmount.div(ethToTokenConversion);
    }
    // track tokens sold during crowdsale round
    crowdsaleTokenSold = crowdsaleTokenSold.add(crowdsaleTokenAmount);

    return (crowdsaleTokenAmount, crowdsaleEthAmount);
  }

  //
  // Issue tokens and return if there is overflow
  //
  
  function processTransaction(address _contributor, uint256 _amount) internal {
    uint256 newContribution = _amount;

    var (communityTokenAmount, communityEthAmount) = calculateCommunity(_contributor, newContribution);

    // compute remaining ETH amount available for purchasing crowdsale tokens
    var (crowdsaleTokenAmount, crowdsaleEthAmount) = calculateCrowdsale(newContribution.sub(communityEthAmount));

    // add up crowdsale + community tokens
    uint256 tokenAmount = crowdsaleTokenAmount.add(communityTokenAmount);

    assert(tokenAmount > 0);

    // Issue new tokens
    token.mintTokens(_contributor, tokenAmount);                              

    // log token issuance
    contributorList[_contributor].tokensIssued = contributorList[_contributor].tokensIssued.add(tokenAmount);                

    // Add contribution amount to existing contributor
    newContribution = crowdsaleEthAmount.add(communityEthAmount);
    contributorList[_contributor].contributionAmount = contributorList[_contributor].contributionAmount.add(newContribution);

    ethRaisedWithoutCompany = ethRaisedWithoutCompany.add(newContribution);                              // Add contribution amount to ETH raised
    tokenSold = tokenSold.add(tokenAmount);                                  // track how many tokens are sold

    // compute any refund if applicable
    uint256 refundAmount = _amount.sub(newContribution);

    if (refundAmount > 0) {
      _contributor.transfer(refundAmount);                                   // refund contributor amount behind the maximum ETH cap
    }

    companyAddress.transfer(newContribution);                                // send ETH to company
  }

  //
  // whitelist validated participants.
  //
  
  function WhiteListContributors(address[] _contributorAddresses, bool[] _contributorCommunityRoundApproved) public onlyOwner {
    require(_contributorAddresses.length == _contributorCommunityRoundApproved.length); // Check if input data is correct

    for (uint cnt = 0; cnt < _contributorAddresses.length; cnt++) {
      contributorList[_contributorAddresses[cnt]].isWhiteListed = true;
      contributorList[_contributorAddresses[cnt]].isCommunityRoundApproved = _contributorCommunityRoundApproved[cnt];
    }
  }

  //
  // Method is needed for recovering tokens accidentally sent to token address
  //
  
  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) public onlyOwner {
    IERC20Token(_tokenAddress).transfer(_to, _amount);
  }

  //
  // Owner can set multisig address for crowdsale
  //
  
  function setCompanyAddress(address _newAddress) public onlyOwner {
    require(!treasuryLocked);                              // Check if owner has already claimed tokens
    companyAddress = _newAddress;
    treasuryLocked = true;
  }

  //
  // Owner can set token address where mints will happen
  //
  function setToken(address _newAddress) public onlyOwner {
    token = IToken(_newAddress);
  }

  function getToken() public constant returns (address) {
    return address(token);
  }

  //
  // Claims company tokens
  //
  function claimCompanyTokens() public onlyOwner {
    require(!ownerHasClaimedCompanyTokens);                     // Check if owner has already claimed tokens
    require(companyAddress != 0x0);
    
    tokenSold = tokenSold.add(companyTokens); 
    token.mintTokens(companyAddress, companyTokens);            // Issue company tokens 
    ownerHasClaimedCompanyTokens = true;                        // Block further mints from this method
  }

  //
  // Claim remaining tokens when crowdsale ends
  //
  
  function claimRemainingTokens() public onlyOwner {
    checkCrowdsaleState();                                        // Calibrate crowdsale state
    require(crowdsaleState == state.crowdsaleEnded);              // Check crowdsale has ended
    require(!ownerHasClaimedTokens);                              // Check if owner has already claimed tokens
    require(companyAddress != 0x0);

    uint256 remainingTokens = maxTokenSupply.sub(token.totalSupply());
    token.mintTokens(companyAddress, remainingTokens);            // Issue tokens to company
    ownerHasClaimedTokens = true;                                 // Block further mints from this method
  }
}

// File: gist-93cc6447162a8ffd1a88992ba6170fd6/contracts/MyTokenCrowdsale.sol

pragma solidity ^0.4.13;


contract TolsisCrowdsale is Crowdsale {
    string public officialWebsite;
    string public officialFacebook;
    string public officialTelegram;
    string public officialEmail;

  function MyTokenCrowdsale() public {
    officialWebsite = "https://www.tolsistoken.com";
    officialFacebook = "https://www.facebook.com/tolsistoken/";
    officialTelegram = "";
    officialEmail = "[email protected]";
    communityRoundStartDate =1510063200;                       // DEGISTIR
    crowdsaleStartDate = communityRoundStartDate + 24 hours;    // 24 hours later
    crowdsaleEndDate = communityRoundStartDate + 30 days + 12 hours; // 30 days + 12 hours later
    crowdsaleState = state.pendingStart;
    ethToTokenConversion = 26950;                 // 1 ETH == 26,950 TOLSIS tokens
    maxTokenSupply = 10000000000 ether;           // 10,000,000,000
    companyTokens = 8124766171 ether;             // allocation for company pool, private presale, user pool 
    maxCommunityWithoutBonusCap = 945000000 ether;
    maxCommunityCap = 1086750000 ether;           // 945,000,000 with 15% bonus of 141,750,000
    maxCrowdsaleCap = 788483829 ether;            // tokens allocated to crowdsale 
    maxContribution = 100 ether;                  // maximum contribution during community round
  }
}