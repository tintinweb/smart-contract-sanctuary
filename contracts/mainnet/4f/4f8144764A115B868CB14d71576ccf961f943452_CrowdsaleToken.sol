pragma solidity ^0.4.15;

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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/*
 * CrowdsaleToken
 *
 * Simple ERC20 Token example, with crowdsale token creation
 */
contract CrowdsaleToken is StandardToken, Ownable {
    
  string public standard = "AfterSchool Token v1.0";
  string public name = "AfterSchool Token";
  string public symbol = "AST";
  uint public decimals = 18;
  address public multisig = 0x8Dab59292A76114776B4933aD6F1246Bf647aB90;
  
  // 1 ETH = 5800 AST tokens (1 AST = 0.05 USD)
  uint PRICE = 5800;
  
  struct ContributorData {
    uint contributionAmount;
    uint tokensIssued;
  }

  mapping(address => ContributorData) public contributorList;
  uint nextContributorIndex;
  mapping(uint => address) contributorIndexes;
  
  state public crowdsaleState = state.pendingStart;
  enum state { pendingStart, crowdsale, crowdsaleEnded }
  
  event CrowdsaleStarted(uint blockNumber);
  event CrowdsaleEnded(uint blockNumber);
  event ErrorSendingETH(address to, uint amount);
  event MinCapReached(uint blockNumber);
  event MaxCapReached(uint blockNumber);
  
  uint public constant BEGIN_TIME = 1506420000;
  
  uint public constant END_TIME = 1509012000;

  uint public minCap = 3500 ether;
  uint public maxCap = 50000 ether;
  uint public ethRaised = 0;
  uint public tokenTotalSupply = 800000000 * 10**decimals;
  
  uint crowdsaleTokenCap =            480000000 * 10**decimals; // 60%
  uint foundersAndTeamTokens =        120000000 * 10**decimals; // 15%
  uint advisorAndAmbassadorTokens =    56000000 * 10**decimals; // 7%
  uint investorTokens =                8000000 * 10**decimals; // 10%
  uint afterschoolContributorTokens = 56000000 * 10**decimals; // 7%
  uint futurePartnerTokens =          64000000 * 10**decimals; // 8%
  
  bool foundersAndTeamTokensClaimed = false;
  bool advisorAndAmbassadorTokensClaimed = false;
  bool investorTokensClaimed = false;
  bool afterschoolContributorTokensClaimed = false;
  bool futurePartnerTokensClaimed = false;
  uint nextContributorToClaim;
  mapping(address => bool) hasClaimedEthWhenFail;

  function() payable {
  require(msg.value != 0);
  require(crowdsaleState != state.crowdsaleEnded);// Check if crowdsale has ended
  
  bool stateChanged = checkCrowdsaleState();      // Check blocks and calibrate crowdsale state
  
  if(crowdsaleState == state.crowdsale) {
      createTokens(msg.sender);             // Process transaction and issue tokens
    } else {
      refundTransaction(stateChanged);              // Set state and return funds or throw
    }
  }
  
  //
  // Check crowdsale state and calibrate it
  //
  function checkCrowdsaleState() internal returns (bool) {
    if (ethRaised >= maxCap && crowdsaleState != state.crowdsaleEnded) { // Check if max cap is reached
      crowdsaleState = state.crowdsaleEnded;
      CrowdsaleEnded(block.number); // Raise event
      return true;
    }
    
    if(now >= END_TIME) {   
      crowdsaleState = state.crowdsaleEnded;
      CrowdsaleEnded(block.number); // Raise event
      return true;
    }

    if(now >= BEGIN_TIME && now < END_TIME) {        // Check if we are in crowdsale state
      if (crowdsaleState != state.crowdsale) {                                                   // Check if state needs to be changed
        crowdsaleState = state.crowdsale;                                                       // Set new state
        CrowdsaleStarted(block.number);                                                         // Raise event
        return true;
      }
    }
    
    return false;
  }
  
  //
  // Decide if throw or only return ether
  //
  function refundTransaction(bool _stateChanged) internal {
    if (_stateChanged) {
      msg.sender.transfer(msg.value);
    } else {
      revert();
    }
  }
  
  function createTokens(address _contributor) payable {
  
    uint _amount = msg.value;
  
    uint contributionAmount = _amount;
    uint returnAmount = 0;
    
    if (_amount > (maxCap - ethRaised)) {                                          // Check if max contribution is lower than _amount sent
      contributionAmount = maxCap - ethRaised;                                     // Set that user contibutes his maximum alowed contribution
      returnAmount = _amount - contributionAmount;                                 // Calculate how much he must get back
    }

    if (ethRaised + contributionAmount > minCap && minCap > ethRaised) {
      MinCapReached(block.number);
    }

    if (ethRaised + contributionAmount == maxCap && ethRaised < maxCap) {
      MaxCapReached(block.number);
    }

    if (contributorList[_contributor].contributionAmount == 0){
        contributorIndexes[nextContributorIndex] = _contributor;
        nextContributorIndex += 1;
    }
  
    contributorList[_contributor].contributionAmount += contributionAmount;
    ethRaised += contributionAmount;                                              // Add to eth raised

    uint tokenAmount = calculateEthToAfterschool(contributionAmount);      // Calculate how much tokens must contributor get
    if (tokenAmount > 0) {
      totalSupply = totalSupply.add(tokenAmount);
      balances[_contributor] = balances[_contributor].add(tokenAmount);
      contributorList[_contributor].tokensIssued += tokenAmount;                  // log token issuance
    }

    if (!multisig.send(msg.value)) {
        revert();
    }
  }
  
  function calculateEthToAfterschool(uint _eth) constant returns(uint) {
  
    uint tokens = _eth.mul(getPrice());
    uint percentage = 0;
    
    if (ethRaised > 0)
    {
        percentage = ethRaised * 100 / maxCap;
    }
    
    return tokens + getStageBonus(percentage, tokens) + getAmountBonus(_eth, tokens);
  }

  function getStageBonus(uint percentage, uint tokens) constant returns (uint) {
    uint stageBonus = 0;
      
    if (percentage <= 10) stageBonus = tokens * 60 / 100; // Stage 1
    else if (percentage <= 50) stageBonus = tokens * 30 / 100;
    else if (percentage <= 70) stageBonus = tokens * 20 / 100;
    else if (percentage <= 90) stageBonus = tokens * 15 / 100;
    else if (percentage <= 100) stageBonus = tokens * 10 / 100;

    return stageBonus;
  }

  function getAmountBonus(uint _eth, uint tokens) constant returns (uint) {
    uint amountBonus = 0;  
      
    if (_eth >= 3000 ether) amountBonus = tokens * 13 / 100;
    else if (_eth >= 2000 ether) amountBonus = tokens * 12 / 100;
    else if (_eth >= 1500 ether) amountBonus = tokens * 11 / 100;
    else if (_eth >= 1000 ether) amountBonus = tokens * 10 / 100;
    else if (_eth >= 750 ether) amountBonus = tokens * 9 / 100;
    else if (_eth >= 500 ether) amountBonus = tokens * 8 / 100;
    else if (_eth >= 300 ether) amountBonus = tokens * 75 / 1000;
    else if (_eth >= 200 ether) amountBonus = tokens * 7 / 100;
    else if (_eth >= 150 ether) amountBonus = tokens * 6 / 100;
    else if (_eth >= 100 ether) amountBonus = tokens * 55 / 1000;
    else if (_eth >= 75 ether) amountBonus = tokens * 5 / 100;
    else if (_eth >= 50 ether) amountBonus = tokens * 45 / 1000;
    else if (_eth >= 30 ether) amountBonus = tokens * 4 / 100;
    else if (_eth >= 20 ether) amountBonus = tokens * 35 / 1000;
    else if (_eth >= 15 ether) amountBonus = tokens * 3 / 100;
    else if (_eth >= 10 ether) amountBonus = tokens * 25 / 1000;
    else if (_eth >= 7 ether) amountBonus = tokens * 2 / 100;
    else if (_eth >= 5 ether) amountBonus = tokens * 15 / 1000;
    else if (_eth >= 3 ether) amountBonus = tokens * 1 / 100;
    else if (_eth >= 2 ether) amountBonus = tokens * 5 / 1000;
    
    return amountBonus;
  }
  
  // replace this with any other price function
  function getPrice() constant returns (uint result) {
    return PRICE;
  }
  
  //
  // Owner can batch return contributors contributions(eth)
  //
  function batchReturnEthIfFailed(uint _numberOfReturns) onlyOwner {
    require(crowdsaleState != state.crowdsaleEnded);                // Check if crowdsale has ended
    require(ethRaised < minCap);                // Check if crowdsale has failed
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
  // Owner can set multisig address for crowdsale
  //
  function setMultisigAddress(address _newAddress) onlyOwner {
    multisig = _newAddress;
  }
  
}